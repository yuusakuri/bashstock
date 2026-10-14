#!/usr/bin/env bash
# @file array
# @brief Operations on the elements of a Bash array passed as arguments.
# @description Bash 3.2 cannot pass arrays by reference, so the elements are passed as separate arguments.

# @description Test whether the remaining arguments contain the expected value.
#
# @arg $1 string Value to look for.
# @arg $@ string Values to search.
# @exitcode 0 One of the values equals the expected value.
# @exitcode 1 No value equals the expected value.
# @exitcode 64 No expected value was given.
# @example
#   array::contains main "${branches[@]}" && printf 'main exists\n'
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

# @description Write the arguments in reverse order, one value per line.
#
# @arg $@ string Values without newlines.
# @stdout The values from last to first, one per line.
# @exitcode 0 The values were written.
# @exitcode 64 A value contains a newline.
# @example
#   array::reverse a b c
#   # c
#   # b
#   # a
array::reverse() {
  local values=("$@")
  local index=''

  for ((index = ${#values[@]} - 1; index >= 0; index--)); do
    if ! string::_require-one-line "${values[index]}"; then
      return 64
    fi
    printf '%s\n' "${values[index]}"
  done
}

# @description Write the number of arguments.
#
# @arg $@ string Values to count.
# @stdout The number of values.
# @exitcode 0 Always.
# @example
#   array::length "${files[@]}"
array::length() {
  printf '%s\n' "$#"
}

# @description Write the first argument when one is available.
#
# @arg $@ string Values; the first one must not contain a newline.
# @stdout The first value.
# @exitcode 0 The first value was written.
# @exitcode 1 No value was given.
# @exitcode 64 The first value contains a newline.
# @example
#   array::first "${hosts[@]}"
array::first() {
  if [[ "$#" -eq 0 ]]; then
    return 1
  fi
  if ! string::_require-one-line "$1"; then
    return 64
  fi

  printf '%s\n' "$1"
}

# @description Write the last argument when one is available.
#
# @arg $@ string Values; the last one must not contain a newline.
# @stdout The last value.
# @exitcode 0 The last value was written.
# @exitcode 1 No value was given.
# @exitcode 64 The last value contains a newline.
# @example
#   array::last "${versions[@]}"
array::last() {
  if [[ "$#" -eq 0 ]]; then
    return 1
  fi

  local value=''
  for value in "$@"; do
    :
  done

  if ! string::_require-one-line "${value}"; then
    return 64
  fi
  printf '%s\n' "${value}"
}

# @description Write each distinct argument once in its original order.
#
# @arg $@ string Values without newlines.
# @stdout Each distinct value once, one per line, in the order it first appeared.
# @exitcode 0 The values were written.
# @exitcode 64 A value contains a newline.
# @example
#   array::unique b a b c a
#   # b
#   # a
#   # c
array::unique() {
  local seen=()
  local value=''
  local previous=''
  local duplicate='0'

  for value in "$@"; do
    if ! string::_require-one-line "${value}"; then
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

# @description Prefix every value and write one result per line.
#
# @arg $1 string Prefix without newlines.
# @arg $@ string Values without newlines.
# @stdout Each value with the prefix, one per line.
# @exitcode 0 The values were written.
# @exitcode 64 No prefix was given, or a value contains a newline.
# @example
#   array::prepend-to-each --exclude= .git node_modules
#   # --exclude=.git
#   # --exclude=node_modules
array::prepend-to-each() {
  if [[ "$#" -lt 1 ]] || ! string::_require-one-line "$1"; then
    return 64
  fi

  local prefix="$1"
  local value=''
  shift

  for value in "$@"; do
    if ! string::_require-one-line "${value}"; then
      return 64
    fi
    printf '%s%s\n' "${prefix}" "${value}"
  done
}
