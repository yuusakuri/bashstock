#!/usr/bin/env bash

json::require-present() {
  if [[ "$#" -ne 2 ]] || ! string::__require-non-empty-line "$1"; then
    return 64
  fi

  if [[ -n "$2" && "$2" != 'null' ]]; then
    return 0
  fi

  console::__write-error "$1 must be present."
  return 64
}
