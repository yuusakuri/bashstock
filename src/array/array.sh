#!/usr/bin/env bash

array::contains() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi

  local expected="$1"
  local value=''
  shift

  for value in "$@"; do
    if [[ "${value}" == "${expected}" ]]; then
      return 0
    fi
  done

  return 1
}

array::reverse() {
  local values=("$@")
  local index=''

  for ((index = ${#values[@]} - 1; index >= 0; index--)); do
    if ! string::__require-one-line "${values[index]}"; then
      return 64
    fi
    printf '%s\n' "${values[index]}"
  done
}

array::length() {
  printf '%s\n' "$#"
}

array::first() {
  if [[ "$#" -eq 0 ]]; then
    return 1
  fi
  if ! string::__require-one-line "$1"; then
    return 64
  fi

  printf '%s\n' "$1"
}

array::last() {
  if [[ "$#" -eq 0 ]]; then
    return 1
  fi

  local value=''
  for value in "$@"; do
    :
  done

  if ! string::__require-one-line "${value}"; then
    return 64
  fi
  printf '%s\n' "${value}"
}

array::unique() {
  local seen=()
  local value=''
  local previous=''
  local duplicate='0'

  for value in "$@"; do
    if ! string::__require-one-line "${value}"; then
      return 64
    fi

    duplicate='0'
    for previous in "${seen[@]}"; do
      if [[ "${previous}" == "${value}" ]]; then
        duplicate='1'
        break
      fi
    done

    if [[ "${duplicate}" -eq 0 ]]; then
      seen[${#seen[@]}]="${value}"
      printf '%s\n' "${value}"
    fi
  done
}

array::prepend-to-each() {
  if [[ "$#" -lt 1 ]] || ! string::__require-one-line "$1"; then
    return 64
  fi

  local prefix="$1"
  local value=''
  shift

  for value in "$@"; do
    if ! string::__require-one-line "${value}"; then
      return 64
    fi
    printf '%s%s\n' "${prefix}" "${value}"
  done
}
