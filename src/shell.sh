#!/usr/bin/env bash
# @file shell
# @brief Inspection of the current shell.
# @description Tests return 0 or 1 without output.

# @description Test whether a shell function is defined.
#
# @arg $1 string Function name.
# @exitcode 0 The function is defined.
# @exitcode 1 No function has that name.
# @exitcode 64 The name is empty, starts with a dash, or contains a newline.
# @example
#   shell::is-function-defined node::install && node::install
shell::is-function-defined() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! string::_require-one-line "$1"; then
    return 64
  fi

  declare -F "$1" >/dev/null 2>&1
}
