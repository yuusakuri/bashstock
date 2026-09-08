#!/usr/bin/env bash

### Write one command-prefixed diagnostic to standard error.
console::_write-error() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  printf '%s: %s\n' "${BASHSTOCK_NAME:-bashstock}" "$1" >&2
}
