#!/usr/bin/env bash

platform::__identifier() {
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

platform::__create-system-user() {
  return 69
}

platform::__create-login-user() {
  return 69
}

platform::__change-owner-recursively() {
  return 69
}
