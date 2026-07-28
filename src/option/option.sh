#!/usr/bin/env bash

### Require exactly one named option value to be non-empty.
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

    if ! string::__require-non-empty-line "${name}"; then
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
  console::__write-error "Exactly one option must be set: ${names}"
  return 64
}
