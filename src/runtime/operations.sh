#!/usr/bin/env bash

# @description Execute this library in a separate Bash process with root privileges.
#
# Arguments are an operation name followed by its literal argument values.
# @internal
_bashstock__run-as-root() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi
  if [[ ! -f "${_BASHSTOCK_FILE}" || ! -r "${_BASHSTOCK_FILE}" ]]; then
    return 66
  fi
  command__run-as-root "${BASH}" -- "${_BASHSTOCK_FILE}" --internal-root "$@"
}

# @description Dispatch a fixed operation name and validate inputs in the executing process.
# @internal
_bashstock__dispatch-root() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi

  local operation="$1"
  shift
  case "${operation}" in
    append-text)
      file__append-text "$@"
      ;;
    write-text)
      file__write-text "$@"
      ;;
    replace-text)
      file__replace-text "$@"
      ;;
    replace-text-in-files)
      file__replace-text-in-files "$@"
      ;;
    replace-all-text)
      file__replace-all-text "$@"
      ;;
    replace-all-text-in-files)
      file__replace-all-text-in-files "$@"
      ;;
    replace-or-append-text)
      file__replace-or-append-text "$@"
      ;;
    create-system-user)
      _user__validate-system-creation "$@" || return "$?"
      _platform__create-system-user "$@"
      ;;
    create-login-user)
      _user__validate-login-creation "$@" || return "$?"
      _platform__create-login-user "$@"
      ;;
    change-owner-recursively)
      _path__validate-ownership "$@" || return "$?"
      _platform__change-owner-recursively "$@"
      ;;
    *)
      return 64
      ;;
  esac
}

# @description Accept only the internal execution mode and require root privileges.
# @internal
_bashstock__main() {
  if [[ "$#" -ge 1 && "$1" == '--internal-git-sequence-editor' ]]; then
    shift
    _git__sequence-editor "$@"
    return "$?"
  fi
  if [[ "$#" -lt 2 || "$1" != '--internal-root' ]]; then
    return 64
  fi
  case "$2" in
    append-text | write-text | replace-text | replace-all-text | \
      replace-text-in-files | replace-all-text-in-files | replace-or-append-text | \
      create-system-user | create-login-user | change-owner-recursively) ;;
    *) return 64 ;;
  esac
  if [[ "${EUID}" -ne 0 ]]; then
    return 77
  fi
  shift
  _bashstock__dispatch-root "$@"
}
