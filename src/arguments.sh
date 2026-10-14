#!/usr/bin/env bash
# @file arguments
# @brief Validation of named and positional function arguments.
# @description Functions that take --kebab-case named arguments use these helpers to report missing or invalid values with status 64.

# @description Require a value to follow the current named argument.
#
# Call it in a case branch of a named argument that takes a value, before
# reading $2.
#
# @arg $1 integer Number of arguments that remain, usually "$#".
# @arg $2 string Name of the current argument, such as --name.
# @stderr A message naming the argument when its value is missing.
# @exitcode 0 A value follows the argument.
# @exitcode 64 No value follows the argument, or the arguments are invalid.
# @example
#   case "$1" in
#     --name)
#       arg::require-next "$#" "$1" || return "$?"
#       name="$2"
#       shift 2
#       ;;
#   esac
arg::require-next() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local remaining="$1"
  local option="$2"

  if [[ "${remaining}" -lt 2 ]]; then
    console::_write-error "Option ${option} requires a value."
    return 64
  fi
}

# @description Require a named argument to have a non-empty value.
#
# @arg $1 string Name of the argument for the message, such as --name.
# @arg $2 string Value that was given.
# @stderr A message naming the argument when the value is empty.
# @exitcode 0 The value is not empty.
# @exitcode 64 The value is empty, or the arguments are invalid.
# @example
#   arg::require --name "${name}" || return "$?"
arg::require() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local name="$1"
  local value="$2"

  if [[ -z "${value}" ]]; then
    console::_write-error "Option ${name} is required."
    return 64
  fi
}

# @description Require a named argument value to be a decimal integer.
#
# @arg $1 string Name of the argument for the message, such as --count.
# @arg $2 string Value that was given.
# @stderr A message naming the argument and the value when it is not an integer.
# @exitcode 0 The value is a decimal integer.
# @exitcode 64 The value is not an integer, or the arguments are invalid.
# @example
#   arg::integer --count "${count}" || return "$?"
arg::integer() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local name="$1"
  local value="$2"

  if ! number::is-integer "${value}"; then
    console::_write-error "Option ${name} must be an integer: ${value}"
    return 64
  fi
}

# @description Require a named argument value to match one candidate.
#
# @arg $1 string Name of the argument for the message, such as --mode.
# @arg $2 string Value that was given.
# @arg $@ string Accepted values; at least one is required.
# @stderr A message listing the accepted values when the value is not one of them.
# @exitcode 0 The value equals one candidate.
# @exitcode 64 The value matches no candidate, or the arguments are invalid.
# @example
#   arg::one-of --algorithm "${algorithm}" ed25519 rsa3072 rsa4096 || return "$?"
arg::one-of() {
  if [[ "$#" -lt 3 ]]; then
    return 64
  fi

  local name="$1"
  local value="$2"
  local candidate=''
  shift 2

  for candidate in "$@"; do
    if [[ "${value}" == "${candidate}" ]]; then
      return 0
    fi
  done

  console::_write-error "Option ${name} must be one of: $*. Got: ${value}"
  return 64
}

# @description Report a named argument that no case branch recognized.
#
# Use it in the default branch of the case statement that parses named arguments.
#
# @arg $1 string The unrecognized argument.
# @stderr A message naming the argument.
# @exitcode 64 Always, so the caller can return the status.
# @example
#   case "$1" in
#     *) arg::unknown "$1" || return "$?" ;;
#   esac
arg::unknown() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  console::_write-error "Unknown option: $1"
  return 64
}
