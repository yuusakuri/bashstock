#!/usr/bin/env bats

load test_helper

git_test::create-repository() {
  local directory="$1"

  mkdir "${directory}"
  git -C "${directory}" init --quiet
  git -C "${directory}" config user.name 'BashStock Test'
  git -C "${directory}" config user.email 'bashstock@example.invalid'
}

git_test::commit() {
  local directory="$1"
  local content="$2"
  local message="$3"

  printf '%s\n' "${content}" >"${directory}/value"
  git -C "${directory}" add value
  git -C "${directory}" commit --quiet -m "${message}"
  git -C "${directory}" rev-parse HEAD
}

git_test::edit-via-rebase-preserves-state() {
  local revision="$1"
  local directory="$2"
  local directory_before="${PWD}"
  local ifs_before="${IFS}"
  local options_before=''
  local shell_options_before=''

  options_before="$(set +o)"
  shell_options_before="$(shopt -p)"
  BASH_REMATCH=('caller-value')
  git::commit::edit-via-rebase "${revision}" "${directory}" || return "$?"

  [[ "${PWD}" == "${directory_before}" ]] &&
    [[ "${IFS}" == "${ifs_before}" ]] &&
    [[ "$(set +o)" == "${options_before}" ]] &&
    [[ "$(shopt -p)" == "${shell_options_before}" ]] &&
    [[ "${BASH_REMATCH[0]}" == 'caller-value' ]]
}

git_test::edit-via-rebase-in-directory() {
  local revision="$1"
  local directory="$2"

  cd "${directory}" || return 74
  git::commit::edit-via-rebase "${revision}"
}

@test "the sequence editor marks exactly one target with file replacement" {
  local repository="${BATS_TEST_TMPDIR}/repository"
  local todo="${BATS_TEST_TMPDIR}/git-rebase-todo"
  local first=''
  local second=''
  local third=''

  git_test::create-repository "${repository}"
  first="$(git_test::commit "${repository}" one first)"
  second="$(git_test::commit "${repository}" two second)"
  third="$(git_test::commit "${repository}" three third)"
  printf 'pick %.12s first\np %.12s second\npick %.12s third\n' \
    "${first}" "${second}" "${third}" >"${todo}"

  run env \
    BASHSTOCK_GIT_EDIT_COMMIT="${second}" \
    "${PROJECT_ROOT}/dist/bashstock/libexec/bashstock-git-sequence-editor" "${todo}"

  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  [ "$(<"${todo}")" = "$(printf \
    'pick %.12s first\nedit %.12s second\npick %.12s third' \
    "${first}" "${second}" "${third}")" ]
}

@test "the sequence editor rejects absent and ambiguous targets without updates" {
  local todo="${BATS_TEST_TMPDIR}/git-rebase-todo"
  local original="${BATS_TEST_TMPDIR}/original"
  local target='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  printf 'pick bbbbbbbbbbbb first\npick cccccccccccc second\n' >"${todo}"
  cp "${todo}" "${original}"

  run env \
    BASHSTOCK_GIT_EDIT_COMMIT="${target}" \
    "${PROJECT_ROOT}/dist/bashstock/libexec/bashstock-git-sequence-editor" "${todo}"
  [ "${status}" -eq 65 ]
  cmp "${original}" "${todo}"

  printf 'pick aaaaaaa first\npick aaaaaaaa second\n' >"${todo}"
  cp "${todo}" "${original}"
  run env \
    BASHSTOCK_GIT_EDIT_COMMIT="${target}" \
    "${PROJECT_ROOT}/dist/bashstock/libexec/bashstock-git-sequence-editor" "${todo}"
  [ "${status}" -eq 65 ]
  cmp "${original}" "${todo}"
}

@test "edit-via-rebase stops at a requested single-parent commit" {
  local repository="${BATS_TEST_TMPDIR}/repository with spaces"
  local first=''
  local second=''
  local third=''

  git_test::create-repository "${repository}"
  first="$(git_test::commit "${repository}" one first)"
  second="$(git_test::commit "${repository}" two second)"
  third="$(git_test::commit "${repository}" three third)"

  run git_test::edit-via-rebase-preserves-state "${second}" "${repository}"

  [ "${status}" -eq 0 ]
  [ "$(git -C "${repository}" rev-parse REBASE_HEAD)" = "${second}" ]
  [ "$(git -C "${repository}" rev-parse HEAD)" = "${second}" ]
  git -C "${repository}" rebase --abort
  [ "$(git -C "${repository}" rev-parse HEAD)" = "${third}" ]
  [ "$(git -C "${repository}" rev-parse "${first}^{commit}")" = "${first}" ]
}

@test "edit-via-rebase stops at a requested root commit" {
  local repository="${BATS_TEST_TMPDIR}/repository"
  local root=''
  local head=''

  git_test::create-repository "${repository}"
  root="$(git_test::commit "${repository}" one root)"
  head="$(git_test::commit "${repository}" two second)"

  run git_test::edit-via-rebase-in-directory 'HEAD~1' "${repository}"

  [ "${status}" -eq 0 ]
  [ "$(git -C "${repository}" rev-parse REBASE_HEAD)" = "${root}" ]
  [ "$(git -C "${repository}" rev-parse HEAD)" = "${root}" ]
  git -C "${repository}" rebase --abort
  [ "$(git -C "${repository}" rev-parse HEAD)" = "${head}" ]
}

@test "edit-via-rebase validates arguments repository ancestry and merge commits" {
  local repository="${BATS_TEST_TMPDIR}/repository"
  local initial_branch=''
  local root=''
  local main=''
  local side=''
  local merge=''

  run git::commit::edit-via-rebase
  [ "${status}" -eq 64 ]
  run git::commit::edit-via-rebase ''
  [ "${status}" -eq 64 ]
  run git::commit::edit-via-rebase --help
  [ "${status}" -eq 64 ]
  run git::commit::edit-via-rebase $'HEAD\nmain'
  [ "${status}" -eq 64 ]
  run git::commit::edit-via-rebase HEAD . excess
  [ "${status}" -eq 64 ]
  run git::commit::edit-via-rebase HEAD "${BATS_TEST_TMPDIR}/missing"
  [ "${status}" -eq 66 ]

  git_test::create-repository "${repository}"
  root="$(git_test::commit "${repository}" root root)"
  initial_branch="$(git -C "${repository}" symbolic-ref --short HEAD)"
  git -C "${repository}" checkout --quiet -b side
  side="$(git_test::commit "${repository}" side side)"
  git -C "${repository}" checkout --quiet "${initial_branch}"
  main="$(git_test::commit "${repository}" main main)"

  run git::commit::edit-via-rebase missing "${repository}"
  [ "${status}" -eq 65 ]
  run git::commit::edit-via-rebase "${side}" "${repository}"
  [ "${status}" -eq 65 ]

  git -C "${repository}" merge --quiet --no-ff --strategy=ours side -m merge
  merge="$(git -C "${repository}" rev-parse HEAD)"
  run git::commit::edit-via-rebase "${merge}" "${repository}"
  [ "${status}" -eq 65 ]
  [ "$(git -C "${repository}" rev-parse "${root}^{commit}")" = "${root}" ]
  [ "$(git -C "${repository}" rev-parse "${main}^{commit}")" = "${main}" ]
  [ ! -d "${repository}/.git/rebase-merge" ]
}
