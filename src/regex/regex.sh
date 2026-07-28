#!/usr/bin/env bash

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

regex::capture-group() {
  if [[ "$#" -ne 3 ]] ||
    ! number::__is-non-negative-integer-at-most "$3" 2147483647; then
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
      if ! string::__require-one-line "${BASH_REMATCH[group]}"; then
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
        if ! string::__require-one-line "${BASH_REMATCH[index]}"; then
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
