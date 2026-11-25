#!/usr/bin/env bash
# @file ltrace
# @brief Library call tracing.
# @description Processes are traced with ltrace on Linux.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Attach ltrace to a process on Linux.
#
# Administrator execution is used only when the process cannot be traced
# with the current permissions.
#
# @arg $1 integer Process ID.
# @stderr The library calls that ltrace reports.
# @exitcode 0 ltrace ended successfully.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 The system is not Linux or ltrace is unavailable.
# @exitcode other The status of ltrace.
# @example
#   ltrace__attach-pid 4242
ltrace__attach-pid() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  [[ "$(system__operating-system)" == linux ]] || return 69
  command__require ltrace || return "$?"
  if _process__trace-needs-root "$1"; then
    command__run-as-root ltrace -p "$1"
  else
    ltrace -p "$1"
  fi
}

# @description Attach ltrace to the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stderr The library calls that ltrace reports.
# @exitcode 0 ltrace ended successfully.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of ltrace__attach-pid.
# @example
#   ltrace__attach-name myapp
ltrace__attach-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(_process__first-id-by-name "$1")" || return "$?"
  ltrace__attach-pid "${id}"
}
