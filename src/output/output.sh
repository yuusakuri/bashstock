#!/usr/bin/env bash

### Write one command error to standard error.
###
### Arguments
###
### * message - The error message.
###
### Examples
###
### ```bash
### output::error 'The name is empty.'
### ```
###
### The function writes `mytool: The name is empty.` to standard error.
output::error() {
  local message="${1-}"

  printf '%s: %s\n' "${MYTOOL_NAME}" "${message}" >&2
}
