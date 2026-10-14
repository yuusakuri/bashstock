#!/usr/bin/env bash
# @file command
# @brief Command lookup and administrator execution.
# @description Administrator execution uses sudo only when the current user is not root.

# @description Test whether a command name resolves in the current environment.
#
# Functions, aliases, builtins, and executables on PATH all count.
#
# @arg $1 string Command name; it must not start with a dash.
# @exitcode 0 The command resolves.
# @exitcode 1 The command does not resolve.
# @exitcode 64 The name is empty, starts with a dash, or contains a newline.
# @example
#   command::exists docker && docker version
command::exists() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! string::_require-one-line "$1"; then
    return 64
  fi

  command -v "$1" >/dev/null 2>&1
}

# @description Require a command name to resolve in the current environment.
#
# @arg $1 string Command name.
# @stderr A message naming the command when it is unavailable.
# @exitcode 0 The command resolves.
# @exitcode 64 The name is invalid.
# @exitcode 69 The command is unavailable.
# @example
#   command::require curl || return "$?"
command::require() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  if command::exists "$1"; then
    return 0
  fi

  local status="$?"
  if [[ "${status}" -eq 64 ]]; then
    return 64
  fi

  console::_write-error "Required command is unavailable: $1"
  return 69
}

# @description Run a command directly as root or through validated sudo access.
#
# The command runs as is when the process is already root. Otherwise sudo
# validates the credentials first; noninteractive shells never wait for sudo
# password input.
#
# @arg $1 string Command to run.
# @arg $@ string Arguments of the command.
# @stderr A message when sudo is missing.
# @exitcode 0 The command succeeded.
# @exitcode 64 No command was given.
# @exitcode 69 sudo is unavailable.
# @exitcode 77 sudo refused the credentials or would need a password in a noninteractive shell.
# @exitcode other The status of the command.
# @example
#   command::run-as-root install -m 0644 ./rule /etc/udev/rules.d/90-device.rules
command::run-as-root() {
  if [[ "$#" -lt 1 || -z "$1" ]]; then
    return 64
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    command "$@"
    return "$?"
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    console::_write-error 'sudo is required for this operation.'
    return 69
  fi

  if [[ "$-" == *i* ]]; then
    sudo -v || return 77
    sudo -- "$@"
  else
    sudo -n -v || return 77
    sudo -n -- "$@"
  fi
}
