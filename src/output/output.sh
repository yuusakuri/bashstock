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
### The function writes `bashstock: The name is empty.` to standard error.
output::error() {
  local message="${1-}"

  printf '%s: %s\n' "${BASHSTOCK_NAME}" "${message}" >&2
}
