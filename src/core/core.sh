#!/usr/bin/env bash
# shellcheck disable=SC2234

core::__error() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  printf '%s: %s\n' "${BASHSTOCK_NAME:-bashstock}" "$1" >&2
}

core::__has-newline() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  [[ "$1" == *$'\n'* ]]
}

core::__is-non-negative-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[0-9]+$ ]] )
}

core::__is-positive-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[1-9][0-9]*$ ]] )
}

core::__is-safe-non-negative-integer() {
  if [[ "$#" -ne 2 ]] ||
    ! core::__is-non-negative-integer "$1" ||
    ! core::__is-positive-integer "$2"; then
    return 64
  fi

  local value="$1"
  local maximum="$2"
  local LC_ALL=C
  while [[ "${#value}" -gt 1 && "${value:0:1}" == '0' ]]; do
    value="${value:1}"
  done
  if [[ "${#value}" -lt "${#maximum}" ]]; then
    return 0
  fi
  if [[ "${#value}" -gt "${#maximum}" || "${value}" > "${maximum}" ]]; then
    return 1
  fi
  return 0
}

core::__is-safe-positive-integer() {
  if [[ "$#" -ne 2 ]] || ! core::__is-positive-integer "$1"; then
    return 64
  fi
  core::__is-safe-non-negative-integer "$1" "$2"
}

core::__require-display-name() {
  if [[ "$#" -ne 1 || -z "$1" ]] || core::__has-newline "$1"; then
    return 64
  fi
}

core::__require-one-line-value() {
  if [[ "$#" -ne 1 ]] || core::__has-newline "$1"; then
    return 64
  fi
}

core::__require-non-empty-line() {
  if [[ "$#" -ne 1 || -z "$1" ]] || core::__has-newline "$1"; then
    return 64
  fi
}
