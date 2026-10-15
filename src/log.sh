#!/usr/bin/env bash
# @file log
# @brief Timestamped log messages on standard error.
# @description Each line is written as TIMESTAMP [LEVEL] [COMMAND] MESSAGE.

# @description Write every message line with a timestamp, level, and command name.
# @internal
log::_write() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local level="$1"
  local remaining="$2"
  local line=''
  local timestamp=''

  while [[ "${remaining}" == *$'\n'* ]]; do
    line="${remaining%%$'\n'*}"
    timestamp="$(time::local-date-time-milliseconds-extended)" || return "$?"
    printf '%s [%s] [%s] %s\n' \
      "${timestamp}" "${level}" "${BASHSTOCK_NAME:-bashstock}" "${line}" >&2
    remaining="${remaining#*$'\n'}"
  done

  timestamp="$(time::local-date-time-milliseconds-extended)" || return "$?"
  printf '%s [%s] [%s] %s\n' \
    "${timestamp}" "${level}" "${BASHSTOCK_NAME:-bashstock}" "${remaining}" >&2
}

# @description Write an informational log message.
#
# Each line of the message becomes one standard-error line with the local time,
# the level, and BASHSTOCK_NAME.
#
# @arg $1 string Message; a multiline message is written line by line.
# @stderr Lines such as 2026-10-14T12:04:05.678+09:00 [INFO] [bashstock] message.
# @exitcode 0 The message was written.
# @exitcode 64 The argument count is not one.
# @exitcode 69 The clock provider for the timestamp is unavailable.
# @example
#   BASHSTOCK_NAME=deploy log::info 'Uploading the release.'
log::info() {
  [[ "$#" -eq 1 ]] || return 64
  log::_write INFO "$1"
}

# @description Write a warning log message.
#
# @arg $1 string Message; a multiline message is written line by line.
# @stderr Lines such as 2026-10-14T12:04:05.678+09:00 [WARN] [bashstock] message.
# @exitcode 0 The message was written.
# @exitcode 64 The argument count is not one.
# @exitcode 69 The clock provider for the timestamp is unavailable.
# @example
#   log::warn 'The cache is older than one day.'
log::warn() {
  [[ "$#" -eq 1 ]] || return 64
  log::_write WARN "$1"
}

# @description Write an error log message without exiting.
#
# @arg $1 string Message; a multiline message is written line by line.
# @stderr Lines such as 2026-10-14T12:04:05.678+09:00 [ERROR] [bashstock] message.
# @exitcode 0 The message was written.
# @exitcode 64 The argument count is not one.
# @exitcode 69 The clock provider for the timestamp is unavailable.
# @example
#   docker::install || log::error 'Docker could not be installed.'
log::error() {
  [[ "$#" -eq 1 ]] || return 64
  log::_write ERROR "$1"
}
