#!/usr/bin/env bash

shell::is-function-defined() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! string::__require-one-line "$1"; then
    return 64
  fi

  declare -F "$1" >/dev/null 2>&1
}
