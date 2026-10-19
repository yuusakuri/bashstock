#!/usr/bin/env bash
# @file option
# @brief Checks for groups of named options.
# @description option::require-single reports an error unless exactly one option of a group has a value.

# @description Require exactly one named option value to be non-empty.
#
# Use it when mutually exclusive options were parsed into separate variables.
#
# @arg $@ string Pairs of option name and value; at least two pairs.
# @stderr A message listing the options when none or more than one is set.
# @exitcode 0 Exactly one value is non-empty.
# @exitcode 64 None or several values are set, or the pairs are invalid.
# @example
#   option::require-single --file "${file}" --url "${url}" || return "$?"
option::require-single() {
  if [[ "$#" -lt 4 ]] || (($# % 2 != 0)); then
    return 64
  fi

  local count='0'
  local names=''
  local name=''
  local value=''

  while [[ "$#" -gt 0 ]]; do
    name="$1"
    value="$2"
    shift 2

    if ! string::_require-non-empty-line "${name}"; then
      return 64
    fi
    if [[ -n "${names}" ]]; then
      names+=', '
    fi
    names+="${name}"
    if [[ -n "${value}" ]]; then
      count=$((count + 1))
    fi
  done

  if [[ "${count}" -eq 1 ]]; then
    return 0
  fi
  console::_write-error "Exactly one option must be set: ${names}"
  return 64
}
