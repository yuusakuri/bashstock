#!/usr/bin/env bash

### Write every message line with a timestamp, level, and command name.
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

### Write an informational log message.
log::info() {
  [[ "$#" -eq 1 ]] || return 64
  log::_write INFO "$1"
}

### Write a warning log message.
log::warn() {
  [[ "$#" -eq 1 ]] || return 64
  log::_write WARN "$1"
}

### Write an error log message without exiting.
log::error() {
  [[ "$#" -eq 1 ]] || return 64
  log::_write ERROR "$1"
}
