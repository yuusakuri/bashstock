#!/usr/bin/env bash
# @file regex
# @brief Bash extended regular expression matching and capture groups.
# @description Expressions use the POSIX extended syntax of the Bash =~ operator.

# @description Test a value against a Bash POSIX extended regular expression.
#
# @arg $1 string Value to test.
# @arg $2 string Extended regular expression, as used by [[ =~ ]].
# @exitcode 0 The value matches.
# @exitcode 1 The value does not match.
# @exitcode 64 The expression is invalid, or the argument count is not two.
# @example
#   regex::is-match "${version}" '^[0-9]+\.[0-9]+\.[0-9]+$'
regex::is-match() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local value="$1"
  local expression="$2"
  local status=''

  # shellcheck disable=SC2233
  if ( [[ "${value}" =~ ${expression} ]] ); then
    return 0
  else
    status="$?"
  fi

  if [[ "${status}" -eq 2 ]]; then
    return 64
  fi
  return 1
}

# @description Write one capture group from a Bash POSIX extended regular expression.
#
# @arg $1 string Value to match.
# @arg $2 string Extended regular expression with capture groups.
# @arg $3 integer Group number; 0 is the whole match.
# @stdout The captured text.
# @exitcode 0 The value matches and the group was written.
# @exitcode 1 The value does not match.
# @exitcode 64 The expression or group is invalid, or the captured text contains a newline.
# @example
#   regex::capture-group 'v1.22.3' '^v([0-9]+)\.([0-9]+)' 2
#   # 22
regex::capture-group() {
  if [[ "$#" -ne 3 ]] ||
    ! number::_is-non-negative-integer-at-most "$3" 2147483647; then
    return 64
  fi

  local value="$1"
  local expression="$2"
  local group="$((10#$3))"

  (
    local status=''
    if [[ "${value}" =~ ${expression} ]]; then
      if ((group >= ${#BASH_REMATCH[@]})); then
        return 64
      fi
      if ! string::_require-one-line "${BASH_REMATCH[group]}"; then
        return 64
      fi
      printf '%s\n' "${BASH_REMATCH[group]}"
      return 0
    else
      # shellcheck disable=SC2319
      status="$?"
    fi
    if [[ "${status}" -eq 2 ]]; then
      return 64
    fi
    return 1
  )
}

# @description Write all capture groups from a Bash POSIX extended regular expression.
#
# @arg $1 string Value to match.
# @arg $2 string Extended regular expression with capture groups.
# @stdout Each capture group from the first, one per line.
# @exitcode 0 The value matches and the groups were written.
# @exitcode 1 The value does not match.
# @exitcode 64 The expression is invalid, or a captured text contains a newline.
# @example
#   regex::capture-groups 'user@example.com' '^([^@]+)@(.+)$'
#   # user
#   # example.com
regex::capture-groups() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local value="$1"
  local expression="$2"

  (
    local status=''
    local index=''
    if [[ "${value}" =~ ${expression} ]]; then
      for ((index = 1; index < ${#BASH_REMATCH[@]}; index++)); do
        if ! string::_require-one-line "${BASH_REMATCH[index]}"; then
          return 64
        fi
        printf '%s\n' "${BASH_REMATCH[index]}"
      done
      return 0
    else
      # shellcheck disable=SC2319
      status="$?"
    fi
    if [[ "${status}" -eq 2 ]]; then
      return 64
    fi
    return 1
  )
}
