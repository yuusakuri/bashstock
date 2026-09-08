#!/usr/bin/env bash

### Require a value to follow the current named argument.
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

### Require a named argument to have a non-empty value.
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

### Require a named argument value to be a decimal integer.
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

### Require a named argument value to match one candidate.
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

### Report a named argument that no case branch recognized.
arg::unknown() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  console::_write-error "Unknown option: $1"
  return 64
}
