#!/usr/bin/env bash
# @file arg
# @brief Validation and Tab completion of named function arguments.
# @description Functions that take --kebab-case named arguments use these helpers to report missing or invalid values with status 64 and to complete names with Tab.

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

# @description Write the completion helper name that corresponds to a public function.
# @internal
arg::completion::_helper-name() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi

  local target="$1"
  local namespace="${target%::*}"
  local action="${target##*::}"

  if [[ "${namespace}" == "${target}" || -z "${action}" ]]; then
    return 64
  fi
  printf '%s::_%s-args\n' "${namespace}" "${action}"
}

# @description Write the public function name that corresponds to a completion helper.
# @internal
arg::completion::_target-name() {
  if [[ "$#" -ne 1 || "$1" != *'::_'*'-args' ]]; then
    return 64
  fi

  local helper="${1%-args}"
  local namespace="${helper%::_*}"
  local action="${helper##*::_}"

  printf '%s::%s\n' "${namespace}" "${action}"
}

# @description Dispatch Tab completion to the target function's completion helper.
#
# Registered with `complete -F` for every function that has a matching
# `::_<action>-args` helper. Bash calls this with no arguments and reads
# COMP_WORDS and COMP_CWORD. When the previous word is a named argument, the
# helper receives it and writes the values for that argument; otherwise it
# writes the argument names.
#
# @noargs
# @set COMPREPLY The candidates that start with the current word.
# @exitcode 0 Always, also when the function has no helper.
# @example
#   example::run() { :; }
#   example::_run-args() {
#     case "${1:-}" in
#       --mode) printf '%s\n' fast safe ;;
#       *) printf '%s\n' --mode ;;
#     esac
#   }
#   complete -F arg::completion::dispatch example::run
arg::completion::dispatch() {
  local target="${COMP_WORDS[0]}"
  local current="${COMP_WORDS[COMP_CWORD]}"
  local previous=''
  local helper=''
  local candidates=''

  helper="$(arg::completion::_helper-name "${target}")" || return 0
  declare -F "${helper}" >/dev/null 2>&1 || return 0

  if [[ "${COMP_CWORD}" -gt 0 ]]; then
    previous="${COMP_WORDS[COMP_CWORD - 1]}"
  fi

  if [[ "${previous}" == -* ]]; then
    candidates="$("${helper}" "${previous}")"
  else
    candidates="$("${helper}")"
  fi

  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "${candidates}" -- "${current}"))
}

# @description Register Tab completion for every function that has a completion helper.
#
# Registered automatically when the library is sourced in an interactive shell.
# Call again after defining additional completion helpers.
#
# @noargs
# @exitcode 0 The completions were registered, or complete is unavailable.
# @exitcode 64 An argument was given.
# @example
#   source my-functions.sh
#   arg::completion::register-all
arg::completion::register-all() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  type complete >/dev/null 2>&1 || return 0

  local name=''
  local target=''

  while IFS= read -r name; do
    target="$(arg::completion::_target-name "${name}")" || continue
    declare -F "${target}" >/dev/null 2>&1 || continue
    complete -F arg::completion::dispatch "${target}"
  done < <(declare -F | awk '{print $3}' | grep -E '::_[a-z][a-z0-9-]*-args$')
}
