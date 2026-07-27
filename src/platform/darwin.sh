#!/usr/bin/env bash
# shellcheck disable=SC2234

platform::__create-system-user() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  command -v sysadminctl >/dev/null 2>&1 || return 69
  command -v dscl >/dev/null 2>&1 || return 69

  local used=''
  local uid=''
  used="$(dscl . -list /Users UniqueID 2>/dev/null)" || return 74
  for ((uid = 450; uid <= 499; uid++)); do
    if ! ( [[ "${used}" =~ [[:space:]]${uid}([[:space:]]|$) ]] ); then
      sysadminctl -addUser "$1" -UID "${uid}" -home /var/empty \
        -shell /usr/bin/false -roleAccount >/dev/null || return 73
      return 0
    fi
  done
  return 73
}

platform::__create-login-user() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  command -v sysadminctl >/dev/null 2>&1 || return 69

  if sysadminctl -addUser "$1" -fullName "$2" -home "/Users/$1" \
    -shell /bin/bash -password - </dev/tty >/dev/tty 2>/dev/tty; then
    return 0
  fi

  if id -u "$1" >/dev/null 2>&1; then
    if ! sysadminctl -deleteUser "$1" -secure </dev/tty >/dev/tty 2>/dev/tty; then
      core::__error "Failed to restore the account after password setup: $1, /Users/$1"
      return 74
    fi
  fi
  return 73
}

platform::__change-owner-recursively() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    return 64
  fi
  command -v find >/dev/null 2>&1 || return 69
  command -v chown >/dev/null 2>&1 || return 69

  local group="${3-}"
  if [[ -z "${group}" ]]; then
    group="$(id -gn "$2" 2>/dev/null)" || return 66
  fi
  find -x "$1" -exec chown -h "${2}:${group}" {} + || return 74
}
