#!/usr/bin/env bash
# @file json
# @brief Checks for values read from JSON.
# @description Values read from a JSON document are checked for emptiness and null before use.

# @description Require a named JSON-derived value to be neither empty nor null.
#
# @arg $1 string Name of the value for the message, such as .tag_name.
# @arg $2 string Value read from the JSON document.
# @stderr A message naming the value when it is missing.
# @exitcode 0 The value is present.
# @exitcode 64 The value is empty or null, or the name is invalid.
# @example
#   json::require-present .tag_name "${tag}" || return "$?"
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
