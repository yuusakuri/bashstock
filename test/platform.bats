#!/usr/bin/env bats

load test_helper

@test "the selected platform provider defines every internal operation" {
  declare -F platform::_create-system-user >/dev/null
  declare -F platform::_create-login-user >/dev/null
  declare -F platform::_change-owner-recursively >/dev/null
}

@test "the Ubuntu provider creates a non-login system account" {
  source "${PROJECT_ROOT}/src/platform/ubuntu.sh"
  useradd() {
    printf '%s\n' "$*"
  }

  run platform::_create-system-user _service
  [ "${status}" -eq 0 ]
  [ "${output}" = '--system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin _service' ]
}

@test "the Fedora provider creates a non-login system account" {
  source "${PROJECT_ROOT}/src/platform/fedora.sh"
  useradd() {
    printf '%s\n' "$*"
  }

  run platform::_create-system-user _service
  [ "${status}" -eq 0 ]
  [ "${output}" = '--system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin _service' ]
}

@test "the macOS provider creates a role account in the reserved UID range" {
  source "${PROJECT_ROOT}/src/platform/darwin.sh"
  dscl() {
    printf '_existing 451\n'
  }
  sysadminctl() {
    printf '%s\n' "$*" >"${BATS_TEST_TMPDIR}/sysadminctl-arguments"
  }

  run platform::_create-system-user _service
  [ "${status}" -eq 0 ]
  run command cat "${BATS_TEST_TMPDIR}/sysadminctl-arguments"
  [[ "${output}" == *'-addUser _service -UID 450'* ]]
  [[ "${output}" == *'-roleAccount'* ]]
}
