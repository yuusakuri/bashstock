#!/usr/bin/env bash

### Trim ASCII whitespace from both ends of a string.
###
### Arguments
###
### * value - The string to trim.
###
### Examples
###
### ```bash
### text::trim $'  Alice \t'
### ```
###
### The function writes `Alice`.
text::trim() {
  local value="${1-}"

  while [[ "${value}" == ' '* || "${value}" == $'\t'* || "${value}" == $'\r'* || "${value}" == $'\n'* ]]; do
    value="${value#?}"
  done

  while [[ "${value}" == *' ' || "${value}" == *$'\t' || "${value}" == *$'\r' || "${value}" == *$'\n' ]]; do
    value="${value%?}"
  done

  printf '%s\n' "${value}"
}
