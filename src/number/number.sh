#!/usr/bin/env bash
# shellcheck disable=SC2234

### Test whether a value is an unsigned decimal integer.
number::__is-non-negative-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[0-9]+$ ]] )
}

### Test whether a value is a positive unsigned decimal integer.
number::__is-positive-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[1-9][0-9]*$ ]] )
}

### Test whether an unsigned decimal integer does not exceed a maximum.
number::__is-non-negative-integer-at-most() {
  if [[ "$#" -ne 2 ]] ||
    ! number::__is-non-negative-integer "$1" ||
    ! number::__is-positive-integer "$2"; then
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

### Test whether a positive decimal integer does not exceed a maximum.
number::__is-positive-integer-at-most() {
  if [[ "$#" -ne 2 ]] || ! number::__is-positive-integer "$1"; then
    return 64
  fi

  number::__is-non-negative-integer-at-most "$1" "$2"
}

### Test whether a value is a signed or unsigned decimal integer.
number::is-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?[0-9]+$ ]] )
}

### Test whether a value is a signed or unsigned decimal fraction.
number::is-decimal() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?([0-9]+\.[0-9]*|\.[0-9]+)$ ]] )
}

### Test whether a value is a decimal integer or fraction.
number::is-number() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?([0-9]+|[0-9]+\.[0-9]*|\.[0-9]+)$ ]] )
}
