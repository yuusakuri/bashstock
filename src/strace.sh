#!/usr/bin/env bash
# @file strace
# @brief System call tracing.
# @description Processes are traced with strace on Linux.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Attach strace to a process on Linux.
#
# Administrator execution is used only when the process cannot be traced
# with the current permissions.
#
# @arg $1 integer Process ID.
# @stderr The system calls that strace reports.
# @exitcode 0 strace ended successfully.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 The system is not Linux or strace is unavailable.
# @exitcode other The status of strace.
# @example
#   strace::attach-pid "$(pgrep -x nginx | head -n 1)"
strace::attach-pid() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require strace || return "$?"
  if process::_trace-needs-root "$1"; then
    command::run-as-root strace -p "$1"
  else
    strace -p "$1"
  fi
}

# @description Attach strace to the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stderr The system calls that strace reports.
# @exitcode 0 strace ended successfully.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of strace::attach-pid.
# @example
#   strace::attach-name nginx
strace::attach-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  strace::attach-pid "${id}"
}
