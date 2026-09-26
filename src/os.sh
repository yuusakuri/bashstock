#!/usr/bin/env bash

### Write the identifier of the supported operating-system provider.
platform::_identifier() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  local operating_system=''
  local key=''
  local value=''
  operating_system="$(system::operating-system)" || return "$?"
  if [[ "${operating_system}" == 'darwin' ]]; then
    printf 'darwin\n'
    return 0
  fi
  if [[ "${operating_system}" != 'linux' || ! -r /etc/os-release ]]; then
    printf 'unknown\n'
    return 0
  fi

  while IFS='=' read -r key value; do
    if [[ "${key}" == 'ID' ]]; then
      value="${value#\"}"
      value="${value%\"}"
      case "${value}" in
        ubuntu | fedora)
          printf '%s\n' "${value}"
          ;;
        *)
          printf 'unknown\n'
          ;;
      esac
      return 0
    fi
  done </etc/os-release

  printf 'unknown\n'
}

### Return unavailable until an operating-system provider defines user creation.
platform::_create-system-user() {
  return 69
}

### Return unavailable until an operating-system provider defines login creation.
platform::_create-login-user() {
  return 69
}

### Return unavailable until an operating-system provider defines ownership changes.
platform::_change-owner-recursively() {
  return 69
}
