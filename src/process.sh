#!/usr/bin/env bash
# @file process
# @brief Process and thread lookup.
# @description Processes are matched by executable name or command line.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the IDs of the processes whose executable name is exactly NAME, one per line.
#
# @arg $1 string Executable name.
# @stdout One process ID per line.
# @exitcode 0 At least one process matches.
# @exitcode 1 No process matches.
# @exitcode 64 The argument count is not one.
# @exitcode 69 pgrep is unavailable.
# @example
#   process::ids-by-name sshd
process::ids-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; docker::_run-command pgrep -x "$1"; }

# @description Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f.
#
# @arg $1 string Extended regular expression matched against the full command line.
# @stdout One process ID per line.
# @exitcode 0 At least one process matches.
# @exitcode 1 No process matches.
# @exitcode 64 The argument count is not one.
# @exitcode 69 pgrep is unavailable.
# @example
#   process::ids-by-name-regex 'python3 .*manage\.py runserver'
process::ids-by-name-regex() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; docker::_run-command pgrep -f "$1"; }

# @description Write the threads of one process.
#
# Linux uses ps -T and macOS ps -M.
#
# @arg $1 integer Process ID.
# @stdout The ps listing of the threads.
# @exitcode 0 The threads were written.
# @exitcode 1 No process has the ID.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 ps is unavailable or the operating system is unsupported.
# @example
#   process::threads-by-pid "$$"
process::threads-by-pid() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  command::require ps || return "$?"
  case "$(system::operating-system)" in
    darwin) ps -M -p "$1" ;;
    linux) ps -T -p "$1" ;;
    *) return 69 ;;
  esac
}

# @description Write the first process ID whose executable name is NAME.
# @internal
process::_first-id-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local process_ids=''
  process_ids="$(process::ids-by-name "$1")" || return 1
  [[ -n "${process_ids}" ]] || return 1
  printf '%s\n' "${process_ids%%$'\n'*}"
}

# @description Write the threads of the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stdout The ps listing of the threads.
# @exitcode 0 The threads were written.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of process::threads-by-pid.
# @example
#   process::threads-by-name java
process::threads-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  process::threads-by-pid "${id}"
}

# @description Test whether tracing a process needs administrator execution.
#
# Tracing needs it when another user owns the process, or when Yama allows
# tracing only of descendants.
# @internal
process::_trace-needs-root() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  local owner='' scope=0
  [[ "${EUID}" -eq 0 ]] && return 1
  owner="$(ps -o uid= -p "$1" 2>/dev/null | tr -d ' ')"
  [[ -n "${owner}" && "${owner}" != "${EUID}" ]] && return 0
  [[ -r /proc/sys/kernel/yama/ptrace_scope ]] && scope="$(</proc/sys/kernel/yama/ptrace_scope)"
  [[ "${scope}" != 0 ]]
}
