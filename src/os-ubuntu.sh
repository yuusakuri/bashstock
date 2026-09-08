#!/usr/bin/env bash

### Create a non-login Ubuntu system account.
platform::_create-system-user() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  command -v useradd >/dev/null 2>&1 || return 69
  useradd --system --no-create-home --home-dir /nonexistent \
    --shell /usr/sbin/nologin "$1" || return 73
}

### Create an Ubuntu login account and roll it back after password failure.
platform::_create-login-user() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  command -v useradd >/dev/null 2>&1 || return 69
  command -v passwd >/dev/null 2>&1 || return 69

  useradd --create-home --home-dir "/home/$1" --shell /bin/bash \
    --comment "$2" "$1" || return 73
  if passwd "$1" </dev/tty >/dev/tty 2>/dev/tty; then
    return 0
  fi

  if ! userdel --remove "$1" >/dev/null 2>&1; then
    console::_write-error \
      "Failed to restore the account after password setup: $1, /home/$1"
    return 74
  fi
  return 73
}

### Change ownership recursively without crossing Ubuntu mount points.
platform::_change-owner-recursively() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    return 64
  fi
  command -v find >/dev/null 2>&1 || return 69
  command -v chown >/dev/null 2>&1 || return 69

  local group="${3-}"
  if [[ -z "${group}" ]]; then
    group="$(id -gn "$2" 2>/dev/null)" || return 66
  fi
  find "$1" -xdev -exec chown --no-dereference "${2}:${group}" {} + || return 74
}
