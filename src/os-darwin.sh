#!/usr/bin/env bash
# @file os-darwin
# @brief macOS implementations of the platform operations.
# @description The module defines only internal functions called by the os module.

# shellcheck disable=SC2119,SC2120,SC2234

# @description Create a non-login macOS role account.
# @internal
platform::_create-system-user() {
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

# @description Write the sysadminctl options that give a new login account the invoking user's settings.
#
# The invoking user is SUDO_USER. The new account gets that user's login
# shell, administrator membership, and, when that user is an administrator
# with a Secure Token, a Secure Token granted with that user's password.
# Without an invoking user other than root, the account is a standard user
# with the default /bin/zsh shell.
# @internal
# @stdout One option per line.
platform::_login-user-options() {
  [[ "$#" -eq 0 ]] || return 64
  local reference="${SUDO_USER:-}" shell='' token_status=''
  [[ "${reference}" != 'root' ]] || reference=''
  if [[ -n "${reference}" ]]; then
    shell="$(dscl . -read "/Users/${reference}" UserShell 2>/dev/null)" || shell=''
    shell="${shell#UserShell: }"
  fi
  [[ "${shell}" == /* && -x "${shell}" ]] || shell='/bin/zsh'
  printf '%s\n' -shell "${shell}"
  [[ -n "${reference}" ]] || return 0
  dseditgroup -o checkmember -m "${reference}" admin >/dev/null 2>&1 || return 0
  printf '%s\n' -admin
  token_status="$(sysadminctl -secureTokenStatus "${reference}" 2>&1)" || return 0
  [[ "${token_status}" == *'ENABLED'* ]] || return 0
  printf '%s\n' -adminUser "${reference}" -adminPassword -
}

# @description Create a macOS login account and roll it back after password failure.
#
# The account takes the invoking user's shell, administrator membership, and
# Secure Token as written by platform::_login-user-options. sysadminctl asks
# for the new password and, for a Secure Token, the invoking user's password.
# @internal
platform::_create-login-user() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  command -v sysadminctl >/dev/null 2>&1 || return 69
  command -v dscl >/dev/null 2>&1 || return 69
  command -v dseditgroup >/dev/null 2>&1 || return 69

  local option='' output='' token_status=''
  local options=()
  output="$(platform::_login-user-options)" || return 74
  while IFS= read -r option; do
    options+=("${option}")
  done <<<"${output}"

  if sysadminctl -addUser "$1" -fullName "$2" -home "/Users/$1" \
    "${options[@]}" -password - </dev/tty >/dev/tty 2>/dev/tty; then
    if [[ " ${options[*]} " == *' -adminUser '* ]]; then
      # sysadminctl can exit 0 without granting the token, so the status is read back.
      token_status="$(sysadminctl -secureTokenStatus "$1" 2>&1)" || token_status=''
      [[ "${token_status}" == *'ENABLED'* ]] ||
        console::_write-error "The account was created without a Secure Token: $1"
    fi
    return 0
  fi

  if id -u "$1" >/dev/null 2>&1; then
    if ! sysadminctl -deleteUser "$1" -secure </dev/tty >/dev/tty 2>/dev/tty; then
      console::_write-error \
        "Failed to restore the account after password setup: $1, /Users/$1"
      return 74
    fi
  fi
  return 73
}

# @description Change ownership recursively without crossing macOS mount points.
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
  find -x "$1" -exec chown -h "${2}:${group}" {} + || return 74
}

# @description Write a path's permission mode with BSD stat.
# @internal
platform::_path-mode() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi
  command -v stat >/dev/null 2>&1 || return 69
  stat -f '%Lp' -- "$1" 2>/dev/null || return 74
}
