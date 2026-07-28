#!/usr/bin/env bash
# shellcheck disable=SC2234

user::name() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  id -un 2>/dev/null || return 74
}

user::primary-group() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  id -gn 2>/dev/null || return 74
}

user::is-root() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  [[ "${EUID}" -eq 0 ]]
}

user::exists() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! string::__require-one-line "$1"; then
    return 64
  fi
  id -u "$1" >/dev/null 2>&1
}

user::create-system-as-root() {
  if [[ "$#" -ne 1 ]] || ! ( [[ "$1" =~ ^_[a-z][a-z0-9_-]*$ ]] ); then
    return 64
  fi
  if user::exists "$1"; then
    return 73
  fi
  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    create-system-user "$1"
}

user::create-login-as-root() {
  if [[ "$#" -ne 2 ]] ||
    ! ( [[ "$1" =~ ^[a-z][a-z0-9_-]*$ ]] ) ||
    [[ -z "$2" || "$2" == *:* || "$2" == *[[:cntrl:]]* ]]; then
    return 64
  fi
  if user::exists "$1"; then
    return 73
  fi
  if ! terminal::is-available; then
    console::__write-error 'A controlling terminal is required to set the password.'
    return 66
  fi
  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    create-login-user "$1" "$2"
}
