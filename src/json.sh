#!/usr/bin/env bash

### Require a named JSON-derived value to be neither empty nor null.
json::require-present() {
  if [[ "$#" -ne 2 ]] || ! string::_require-non-empty-line "$1"; then
    return 64
  fi

  if [[ -n "$2" && "$2" != 'null' ]]; then
    return 0
  fi

  console::_write-error "$1 must be present."
  return 64
}
