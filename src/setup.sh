#!/usr/bin/env bash
# @file setup
# @brief Shared steps of the desktop setup functions.
# @description The module defines internal functions that mac::setup and ubuntu::setup share.

# shellcheck disable=SC2119,SC2120

# @description Run one setup step, report a failure, and return its status.
# @internal
setup::_run-step() {
  [[ "$#" -ge 1 ]] || return 64
  "$@"
  local status="$?"
  [[ "${status}" -eq 0 ]] || console::_write-error "Setup step failed with status ${status}: $*"
  return "${status}"
}

# @description Create an empty file when it does not exist.
# @internal
setup::_ensure-file() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  [[ -e "$1" ]] || : >"$1" || return 74
  [[ -f "$1" ]] || return 66
}
