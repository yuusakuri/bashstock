#!/usr/bin/env bash
# @file os-fedora
# @brief Fedora implementations of the platform operations.
# @description The module defines only internal functions called by the os module.

# @description Create a non-login Fedora system account.
# @internal
platform::_create-system-user() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  command -v useradd >/dev/null 2>&1 || return 69
  useradd --system --no-create-home --home-dir /nonexistent \
    --shell /usr/sbin/nologin "$1" || return 73
}

# @description Create a Fedora login account and roll it back after password failure.
# @internal
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

# @description Change ownership recursively without crossing Fedora mount points.
# @internal
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

# @description Write a path's permission mode with GNU stat.
# @internal
platform::_path-mode() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi
  command -v stat >/dev/null 2>&1 || return 69
  stat -c '%a' -- "$1" 2>/dev/null || return 74
}
