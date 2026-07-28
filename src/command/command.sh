#!/usr/bin/env bash

### Test whether a command name resolves in the current environment.
command::exists() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! string::__require-one-line "$1"; then
    return 64
  fi

  command -v "$1" >/dev/null 2>&1
}

### Require a command name to resolve in the current environment.
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

  console::__write-error "Required command is unavailable: $1"
  return 69
}

### Run a command directly as root or through validated sudo access.
command::run-as-root() {
  if [[ "$#" -lt 1 || -z "$1" ]]; then
    return 64
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    command "$@"
    return "$?"
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    console::__write-error 'sudo is required for this operation.'
    return 69
  fi

  if ! sudo -v; then
    return 77
  fi
  sudo -- "$@"
}
