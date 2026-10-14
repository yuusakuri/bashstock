#!/usr/bin/env bash
# @file os
# @brief Dispatch of platform operations to the supported operating systems.
# @description Each platform operation is implemented by os-darwin, os-ubuntu, or os-fedora.

# @description Write the identifier of the supported operating-system provider.
# @internal
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

# @description Write one value from /etc/os-release without evaluating the file.
# @internal
platform::_os-release-value() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Z_]+$ ]] || return 64
  [[ -r /etc/os-release ]] || return 66
  local key='' value=''
  while IFS='=' read -r key value; do
    [[ "${key}" == "$1" ]] || continue
    value="${value#\"}"
    value="${value%\"}"
    printf '%s\n' "${value}"
    return 0
  done </etc/os-release
  return 1
}

# @description Return unavailable until an operating-system provider defines user creation.
# @internal
platform::_create-system-user() {
  return 69
}

# @description Return unavailable until an operating-system provider defines login creation.
# @internal
platform::_create-login-user() {
  return 69
}

# @description Return unavailable until an operating-system provider defines ownership changes.
# @internal
platform::_change-owner-recursively() {
  return 69
}
