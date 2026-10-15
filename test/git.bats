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
  local status=0
  git::commit::edit-via-rebase "${revision}" "${directory}" || status="$?"
  if [[ "${status}" -ne 0 ]]; then
    printf 'edit-via-rebase returned %s\n' "${status}"
    git -C "${directory}" status
    return "${status}"
  fi

  [[ "${PWD}" == "${directory_before}" ]] || { printf 'PWD changed\n'; return 1; }
  [[ "${IFS}" == "${ifs_before}" ]] || { printf 'IFS changed\n'; return 1; }
  [[ "$(set +o)" == "${options_before}" ]] || { printf 'set options changed\n'; return 1; }
  [[ "$(shopt -p)" == "${shell_options_before}" ]] || { printf 'shopt changed\n'; return 1; }
  [[ "${BASH_REMATCH[0]}" == 'caller-value' ]] || { printf 'BASH_REMATCH changed\n'; return 1; }
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
    bash "${PROJECT_ROOT}/dist/bashstock.sh" --internal-git-sequence-editor "${todo}"

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
    bash "${PROJECT_ROOT}/dist/bashstock.sh" --internal-git-sequence-editor "${todo}"
  [ "${status}" -eq 65 ]
  cmp "${original}" "${todo}"

  printf 'pick aaaaaaa first\npick aaaaaaaa second\n' >"${todo}"
  cp "${todo}" "${original}"
  run env \
    BASHSTOCK_GIT_EDIT_COMMIT="${target}" \
    bash "${PROJECT_ROOT}/dist/bashstock.sh" --internal-git-sequence-editor "${todo}"
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
  git -C "${repository}" switch --quiet -c side
  side="$(git_test::commit "${repository}" side side)"
  git -C "${repository}" switch --quiet "${initial_branch}"
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

# @description Create a bare remote with one commit on main and a clone that tracks it.
git_test::create-remote-and-clone() {
  local remote="$1" clone="$2" seed="${BATS_TEST_TMPDIR}/seed"
  # Settings of the machine, such as commit signing, must not change the results.
  export GIT_CONFIG_GLOBAL="${BATS_TEST_TMPDIR}/gitconfig"
  : >"${GIT_CONFIG_GLOBAL}"
  git init --quiet --bare "${remote}"
  git_test::create-repository "${seed}"
  git -C "${seed}" checkout --quiet -b main
  git_test::commit "${seed}" first first >/dev/null
  git -C "${seed}" push --quiet "${remote}" main
  git -C "${remote}" symbolic-ref HEAD refs/heads/main
  git clone --quiet "${remote}" "${clone}"
  git -C "${clone}" config user.name 'BashStock Test'
  git -C "${clone}" config user.email 'bashstock@example.invalid'
}

@test "stash push keeps untracked files and the message" {
  local repository="${BATS_TEST_TMPDIR}/repository"
  git_test::create-repository "${repository}"
  git_test::commit "${repository}" first first >/dev/null
  printf 'changed\n' >"${repository}/value"
  printf 'new\n' >"${repository}/untracked"
  run git::stash::push 'work in progress' "${repository}"
  [ "${status}" -eq 0 ]
  [ ! -e "${repository}/untracked" ]
  [ -z "$(git -C "${repository}" status --porcelain)" ]
  [[ "$(git -C "${repository}" stash list)" == *'work in progress'* ]]
  git -C "${repository}" stash pop --quiet
  [ "$(<"${repository}/untracked")" = new ]
}

@test "commit patches and cherry-picks fetch a missing commit and verify it" {
  local remote="${BATS_TEST_TMPDIR}/remote.git" clone="${BATS_TEST_TMPDIR}/clone" other="${BATS_TEST_TMPDIR}/other" root='' second=''
  git_test::create-remote-and-clone "${remote}" "${clone}"
  git clone --quiet "${remote}" "${other}"
  git -C "${other}" config user.name 'BashStock Test'
  git -C "${other}" config user.email 'bashstock@example.invalid'
  git -C "${other}" checkout --quiet -b topic
  second="$(git_test::commit "${other}" second second)"
  git -C "${other}" push --quiet origin topic
  root="$(git -C "${clone}" rev-list --max-parents=0 HEAD)"

  run git::commit::patch "${root}" origin "${clone}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'+first'* ]]
  run git::commit::patch "${second}" origin "${clone}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'-first'*'+second'* ]]
  run git::cherry-pick "${second}" origin "${clone}"
  [ "${status}" -eq 0 ]
  [ "$(<"${clone}/value")" = second ]
  run git::cherry-pick 0123456789abcdef0123456789abcdef01234567 origin "${clone}"
  [ "${status}" -ne 0 ]
}

@test "pull, reset, delete, and Gerrit pushes default to the current branch and origin" {
  local remote="${BATS_TEST_TMPDIR}/remote.git" clone="${BATS_TEST_TMPDIR}/clone" other="${BATS_TEST_TMPDIR}/other"
  git_test::create-remote-and-clone "${remote}" "${clone}"
  git clone --quiet "${remote}" "${other}"
  git -C "${other}" config user.name 'BashStock Test'
  git -C "${other}" config user.email 'bashstock@example.invalid'
  git_test::commit "${other}" remote remote >/dev/null
  git -C "${other}" push --quiet origin main

  printf 'local\n' >"${clone}/local"
  git -C "${clone}" add local
  git -C "${clone}" commit --quiet -m local
  run git::pull-rebase '' '' "${clone}"
  [ "${status}" -eq 0 ]
  [ "$(git -C "${clone}" log --format=%s -n 3 | tr '\n' ' ')" = 'local remote first ' ]

  printf 'dirty\n' >"${clone}/value"
  run git::reset-remote '' "${clone}"
  [ "${status}" -eq 0 ]
  [ "$(git -C "${clone}" rev-parse HEAD)" = "$(git -C "${remote}" rev-parse main)" ]

  git -C "${clone}" checkout --quiet -b topic
  git -C "${clone}" push --quiet origin topic
  run git::remote::delete-branch '' '' "${clone}"
  [ "${status}" -eq 0 ]
  ! git -C "${remote}" rev-parse --verify --quiet refs/heads/topic

  git -C "${clone}" checkout --quiet main
  run gerrit::push-review '' '' "${clone}"
  [ "${status}" -eq 0 ]
  git -C "${remote}" rev-parse --verify --quiet refs/for/main
  git_test::commit "${clone}" wip wip >/dev/null
  run gerrit::push-review-wip stable '' "${clone}"
  [ "${status}" -eq 0 ]
  git -C "${remote}" rev-parse --verify --quiet 'refs/for/stable%wip'
}

@test "base branch rebase and unshallow fetch use every remote by default" {
  local upstream="${BATS_TEST_TMPDIR}/upstream.git" clone="${BATS_TEST_TMPDIR}/clone" other="${BATS_TEST_TMPDIR}/other" shallow="${BATS_TEST_TMPDIR}/shallow"
  git_test::create-remote-and-clone "${upstream}" "${clone}"
  git -C "${clone}" remote rename origin upstream
  git clone --quiet "${upstream}" "${other}"
  git -C "${other}" config user.name 'BashStock Test'
  git -C "${other}" config user.email 'bashstock@example.invalid'
  git_test::commit "${other}" second second >/dev/null
  git_test::commit "${other}" third third >/dev/null
  git -C "${other}" push --quiet origin main
  git -C "${clone}" checkout --quiet -b feature
  run git::rebase-base-branch '' '' "${clone}"
  [ "${status}" -eq 0 ]
  [ "$(git -C "${clone}" branch --show-current)" = main ]
  [ "$(git -C "${clone}" rev-parse HEAD)" = "$(git -C "${upstream}" rev-parse main)" ]

  git clone --quiet --depth 1 "file://${upstream}" "${shallow}"
  [ "$(git -C "${shallow}" rev-parse --is-shallow-repository)" = true ]
  git -C "${shallow}" remote add mirror "file://${upstream}"
  run git::fetch-unshallow '' "${shallow}"
  [ "${status}" -eq 0 ]
  [ "$(git -C "${shallow}" rev-parse --is-shallow-repository)" = false ]
  [ "$(git -C "${shallow}" rev-list --count HEAD)" -eq 3 ]
  git -C "${shallow}" rev-parse --verify --quiet refs/remotes/mirror/main
}
