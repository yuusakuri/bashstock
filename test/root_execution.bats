#!/usr/bin/env bats

load test_helper

@test "file operation names preserve argument boundaries and literal values" {
  file__append-text() { printf '<%s>' "$@"; }
  file__replace-text() { printf '<%s>' "$@"; }
  file__replace-text-in-files() { printf '<%s>' "$@"; }
  file__replace-or-append-text() { printf '<%s>' "$@"; }

  run _bashstock__dispatch-root append-text '/protected file' $'text\nvalue'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'</protected file><text\nvalue>' ]

  run _bashstock__dispatch-root replace-text '/protected file' '^name=' ''
  [ "${status}" -eq 0 ]
  [ "${output}" = '</protected file><^name=><>' ]

  run _bashstock__dispatch-root replace-text-in-files '^name=' '$(false); *' '/first file' '/second file'
  [ "${status}" -eq 0 ]
  [ "${output}" = '<^name=><$(false); *></first file></second file>' ]

  run _bashstock__dispatch-root replace-or-append-text '/protected file' '^name=' 'name=value'
  [ "${status}" -eq 0 ]
  [ "${output}" = '</protected file><^name=><name=value>' ]
}

@test "account and ownership operations validate inputs before reaching the provider" {
  user__exists() { return 1; }
  terminal__is-available() { return 0; }
  _platform__create-system-user() { printf '<%s>' "$@"; }
  _platform__create-login-user() { printf '<%s>' "$@"; }
  _platform__change-owner-recursively() { printf '<%s>' "$@"; }

  run _bashstock__dispatch-root create-system-user _service
  [ "${status}" -eq 0 ]
  [ "${output}" = '<_service>' ]

  run _bashstock__dispatch-root create-login-user developer 'Developer Name'
  [ "${status}" -eq 0 ]
  [ "${output}" = '<developer><Developer Name>' ]

  run _bashstock__dispatch-root change-owner-recursively "${BATS_TEST_TMPDIR}" developer staff
  [ "${status}" -eq 0 ]
  [ "${output}" = "<${BATS_TEST_TMPDIR}><developer><staff>" ]

  run _bashstock__dispatch-root create-system-user invalid
  [ "${status}" -eq 64 ]
  [ "${output}" = '' ]

  run _bashstock__dispatch-root create-login-user developer 'Bad:Name'
  [ "${status}" -eq 64 ]
  [ "${output}" = '' ]

  run _bashstock__dispatch-root change-owner-recursively "${BATS_TEST_TMPDIR}/missing" developer
  [ "${status}" -eq 66 ]
  [ "${output}" = '' ]
}

@test "the operation dispatcher rejects unknown names and missing arguments" {
  run _bashstock__dispatch-root unknown-operation
  [ "${status}" -eq 64 ]
  run _bashstock__dispatch-root file__append-text '/protected file' text
  [ "${status}" -eq 64 ]
  run _bashstock__dispatch-root
  [ "${status}" -eq 64 ]
  run _bashstock__dispatch-root create-system-user
  [ "${status}" -eq 64 ]
  run _bashstock__dispatch-root create-login-user
  [ "${status}" -eq 64 ]
}

@test "direct execution rejects missing or unknown modes and operations" {
  run bash "${PROJECT_ROOT}/dist/bashstock.sh"
  [ "${status}" -eq 64 ]
  run bash "${PROJECT_ROOT}/dist/bashstock.sh" append-text "${BATS_TEST_TMPDIR}/file" text
  [ "${status}" -eq 64 ]
  run bash "${PROJECT_ROOT}/dist/bashstock.sh" --internal-root
  [ "${status}" -eq 64 ]
  run bash "${PROJECT_ROOT}/dist/bashstock.sh" --internal-root unknown-operation
  [ "${status}" -eq 64 ]
  [ ! -e "${BATS_TEST_TMPDIR}/file" ]
}

@test "direct execution enforces root privileges and ignores inherited loader state" {
  local file="${BATS_TEST_TMPDIR}/standalone file.sh"
  local target="${BATS_TEST_TMPDIR}/target file"
  cp "${PROJECT_ROOT}/dist/bashstock.sh" "${file}"
  chmod 644 "${file}"

  run env BASHSTOCK_ROOT=/missing _BASHSTOCK_FILE=/missing _BASHSTOCK_LOADED=1 \
    bash "${file}" --internal-root append-text "${target}" $'first\nsecond'
  if [[ "${EUID}" -eq 0 ]]; then
    [ "${status}" -eq 0 ]
    [ "$(<"${target}")" = $'first\nsecond' ]
  else
    [ "${status}" -eq 77 ]
    [ ! -e "${target}" ]
  fi
  [ "${output}" = '' ]
}

@test "root callers can perform file operations using only the standalone file" {
  [[ "${EUID}" -eq 0 ]] || skip 'requires a root test process'
  local file="${BATS_TEST_TMPDIR}/standalone file.sh"
  local target="${BATS_TEST_TMPDIR}/target file"
  cp "${PROJECT_ROOT}/dist/bashstock.sh" "${file}"
  chmod 644 "${file}"

  run bash -euo pipefail -c '
    source "$1"
    file__append-text-as-root "$2" "name=old"
    file__replace-text-as-root "$2" "old" "new"
    file__replace-or-append-text-as-root "$2" "^other=" "other=value"
    file__replace-text-in-files-as-root "value" "updated" "$2"
  ' _ "${file}" "${target}"
  [ "${status}" -eq 0 ]
  [ "$(<"${target}")" = $'name=new\nother=updated' ]
}

@test "noninteractive privilege escalation never requests password input" {
  [[ "${EUID}" -ne 0 ]] || skip 'requires an unprivileged test process'
  sudo() { printf '<%s>' "$@" >>"${BATS_TEST_TMPDIR}/sudo-args"; }

  command__run-as-root printf '%s' value
  [ "$(<"${BATS_TEST_TMPDIR}/sudo-args")" = '<-n><--><true><-n><--><printf><%s><value>' ]

  sudo() { return 1; }
  run command__run-as-root printf '%s' value
  [ "${status}" -eq 77 ]
}
