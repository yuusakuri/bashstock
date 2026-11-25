#!/usr/bin/env bash
# @file screen
# @brief GNU Screen sessions.
# @description Sessions are opened, attached to serial devices, and ended.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Open a GNU Screen session.
#
# @arg $1 string Optional session name. Defaults to default.
# @exitcode 0 The session ended successfully.
# @exitcode 64 More than one argument was given.
# @exitcode 69 screen is unavailable.
# @exitcode other The status of screen.
# @example
#   screen__open build
screen__open() { if [[ "$#" -gt 1 ]]; then return 64; fi; command -v screen >/dev/null 2>&1 || return 69; screen "${1:-default}"; }

# @description Open a serial device in GNU Screen through administrator execution and log the session.
#
# @arg $1 string Serial device path.
# @arg $2 integer Optional baud rate. Defaults to 115200.
# @arg $3 string Optional log file. Defaults to a file named with the date and time in ${TTY_LOG_DIR:-.}.
# @exitcode 0 The session ended successfully.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 screen is unavailable.
# @exitcode 74 The log directory could not be created.
# @exitcode other The status of screen.
# @example
#   TTY_LOG_DIR="${HOME}/logs" screen__open-serial /dev/ttyUSB0
screen__open-serial() {
  [[ "$#" -ge 1 && "$#" -le 3 && -e "$1" ]] || return 64
  local device="$1" baud="${2:-115200}" log="${3:-}" stamp=''
  ( [[ "${baud}" =~ ^[1-9][0-9]*$ ]] ) || return 64
  command__require screen || return "$?"
  if [[ -z "${log}" ]]; then
    stamp="$(time__local-date-time-seconds-basic)" || return "$?"
    log="${TTY_LOG_DIR:-.}/${stamp}-screen.log"
  fi
  mkdir -p -- "$(path__directory-name "${log}")" || return 74
  command__run-as-root screen -L -Logfile "${log}" "${device}" "${baud}"
}

# @description End every GNU Screen process of every user through administrator execution.
#
# Having no Screen process is a success.
#
# @noargs
# @exitcode 0 No Screen process remains.
# @exitcode 64 An argument was given.
# @exitcode 69 pkill is unavailable.
# @exitcode other The status of pkill.
# @example
#   screen__kill-all
screen__kill-all() {
  [[ "$#" -eq 0 ]] || return 64
  command__require pkill || return "$?"
  local status=0
  command__run-as-root pkill screen || status="$?"
  # pkill returns 1 when no process matched.
  [[ "${status}" -eq 1 ]] && return 0
  return "${status}"
}
