#!/usr/bin/env bats

load test_helper

@test "the selected platform provider defines every internal operation" {
  declare -F platform::_create-system-user >/dev/null
  declare -F platform::_create-login-user >/dev/null
  declare -F platform::_change-owner-recursively >/dev/null
}

@test "the Ubuntu provider creates a non-login system account" {
  source "${PROJECT_ROOT}/src/os-ubuntu.sh"
  useradd() {
    printf '%s\n' "$*"
  }

  run platform::_create-system-user _service
  [ "${status}" -eq 0 ]
  [ "${output}" = '--system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin _service' ]
}

@test "the Fedora provider creates a non-login system account" {
  source "${PROJECT_ROOT}/src/os-fedora.sh"
  useradd() {
    printf '%s\n' "$*"
  }

  run platform::_create-system-user _service
  [ "${status}" -eq 0 ]
  [ "${output}" = '--system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin _service' ]
}

@test "the macOS provider creates a role account in the reserved UID range" {
  source "${PROJECT_ROOT}/src/os-darwin.sh"
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

@test "a macOS login account takes the invoking user's shell, administrator group, and Secure Token" {
  source "${PROJECT_ROOT}/src/os-darwin.sh"
  local fake_shell="${BATS_TEST_TMPDIR}/zsh"
  printf '#!/bin/sh\n' >"${fake_shell}"
  chmod +x "${fake_shell}"
  dscl() { [[ "$3" == '/Users/alice' && "$4" == 'UserShell' ]] && printf 'UserShell: %s\n' "${fake_shell}"; }
  dseditgroup() { [[ "$4" == 'alice' ]]; }
  sysadminctl() { printf 'Secure token is %s for user %s\n' "${TOKEN:-ENABLED}" "$2" >&2; }

  SUDO_USER=alice run platform::_login-user-options
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%s\n' -shell "${fake_shell}" -admin -adminUser alice -adminPassword -)" ]

  # An administrator without a Secure Token cannot grant one.
  TOKEN=DISABLED SUDO_USER=alice run platform::_login-user-options
  [ "${output}" = "$(printf '%s\n' -shell "${fake_shell}" -admin)" ]

  # A standard user passes on only the shell; an unusable shell falls back to zsh.
  SUDO_USER=bob run platform::_login-user-options
  [ "${output}" = $'-shell\n/bin/zsh' ]

  # Without an invoking user, or when it is root, the account is a standard zsh user.
  SUDO_USER='' run platform::_login-user-options
  [ "${output}" = $'-shell\n/bin/zsh' ]
  SUDO_USER=root run platform::_login-user-options
  [ "${output}" = $'-shell\n/bin/zsh' ]
}
