#!/usr/bin/env bash

### Execute this library in a separate Bash process with root privileges.
### Arguments are an operation name followed by its literal argument values.
bashstock::_run-as-root() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi
  if [[ ! -f "${_BASHSTOCK_FILE}" || ! -r "${_BASHSTOCK_FILE}" ]]; then
    return 66
  fi
  command::run-as-root "${BASH}" -- "${_BASHSTOCK_FILE}" --internal-root "$@"
}

### Dispatch a fixed operation name and validate inputs in the executing process.
bashstock::_dispatch-root() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi

  local operation="$1"
  shift
  case "${operation}" in
    append-text)
      file::append-text "$@"
      ;;
    write-text)
      [[ "$#" -eq 3 && "$3" =~ ^0?[0-7]{3}$ ]] || return 64
      (umask "$3" && file::write-text "$1" "$2")
      ;;
    replace-text)
      file::replace-text "$@"
      ;;
    replace-text-in-files)
      file::replace-text-in-files "$@"
      ;;
    replace-all-text)
      file::replace-all-text "$@"
      ;;
    replace-all-text-in-files)
      file::replace-all-text-in-files "$@"
      ;;
    replace-or-append-text)
      file::replace-or-append-text "$@"
      ;;
    create-system-user)
      user::_validate-system-creation "$@" || return "$?"
      platform::_create-system-user "$@"
      ;;
    create-login-user)
      user::_validate-login-creation "$@" || return "$?"
      platform::_create-login-user "$@"
      ;;
    change-owner-recursively)
      path::_validate-ownership "$@" || return "$?"
      platform::_change-owner-recursively "$@"
      ;;
    *)
      return 64
      ;;
  esac
}

### Accept only the internal execution mode and require root privileges.
bashstock::_main() {
  if [[ "$#" -ge 1 && "$1" == '--internal-git-sequence-editor' ]]; then
    shift
    git::_sequence-editor "$@"
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
  bashstock::_dispatch-root "$@"
}
