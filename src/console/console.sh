#!/usr/bin/env bash

console::__write-error() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  printf '%s: %s\n' "${BASHSTOCK_NAME:-bashstock}" "$1" >&2
}
