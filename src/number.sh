#!/usr/bin/env bash
# @file number
# @brief Tests for integer, decimal, and numeric values.
# @description Each test reads one argument and returns 0 or 1 without output.

# shellcheck disable=SC2234

# @description Test whether a value is an unsigned decimal integer.
# @internal
number::_is-non-negative-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[0-9]+$ ]] )
}

# @description Test whether a value is a positive unsigned decimal integer.
# @internal
number::_is-positive-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[1-9][0-9]*$ ]] )
}

# @description Test whether an unsigned decimal integer does not exceed a maximum.
# @internal
number::_is-non-negative-integer-at-most() {
  if [[ "$#" -ne 2 ]] ||
    ! number::_is-non-negative-integer "$1" ||
    ! number::_is-positive-integer "$2"; then
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

# @description Test whether a positive decimal integer does not exceed a maximum.
# @internal
number::_is-positive-integer-at-most() {
  if [[ "$#" -ne 2 ]] || ! number::_is-positive-integer "$1"; then
    return 64
  fi

  number::_is-non-negative-integer-at-most "$1" "$2"
}

# @description Test whether a value is a signed or unsigned decimal integer.
#
# @arg $1 string Value to test.
# @exitcode 0 The value is an integer such as 42, -7, or +3.
# @exitcode 1 The value is not an integer.
# @exitcode 64 The argument count is not one.
# @example
#   number::is-integer -7 && printf 'integer\n'
#   # integer
number::is-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?[0-9]+$ ]] )
}

# @description Test whether a value is a signed or unsigned decimal fraction.
#
# @arg $1 string Value to test.
# @exitcode 0 The value has a decimal point, such as 1.5, -0.25, or .5.
# @exitcode 1 The value is not a decimal fraction.
# @exitcode 64 The argument count is not one.
# @example
#   number::is-decimal 1.5 && printf 'decimal\n'
#   # decimal
#   number::is-decimal 15 || printf 'not a fraction\n'
#   # not a fraction
number::is-decimal() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?([0-9]+\.[0-9]*|\.[0-9]+)$ ]] )
}

# @description Test whether a value is a decimal integer or fraction.
#
# @arg $1 string Value to test.
# @exitcode 0 The value is an integer or a decimal fraction.
# @exitcode 1 The value is not a number.
# @exitcode 64 The argument count is not one.
# @example
#   number::is-number abc || printf 'not a number\n'
#   # not a number
number::is-number() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?([0-9]+|[0-9]+\.[0-9]*|\.[0-9]+)$ ]] )
}
