#!/usr/bin/env bash

log::__write() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local level="$1"
  local remaining="$2"
  local line=''
  local timestamp=''

  while [[ "${remaining}" == *$'\n'* ]]; do
    line="${remaining%%$'\n'*}"
    timestamp="$(time::local-date-time-milliseconds)" || return "$?"
    printf '%s [%s] [%s] %s\n' \
      "${timestamp}" "${level}" "${MYTOOL_NAME:-modern-bash-cli}" "${line}" >&2
    remaining="${remaining#*$'\n'}"
  done

  timestamp="$(time::local-date-time-milliseconds)" || return "$?"
  printf '%s [%s] [%s] %s\n' \
    "${timestamp}" "${level}" "${MYTOOL_NAME:-modern-bash-cli}" "${remaining}" >&2
}

log::info() {
  [[ "$#" -eq 1 ]] || return 64
  log::__write INFO "$1"
}

log::warn() {
  [[ "$#" -eq 1 ]] || return 64
  log::__write WARN "$1"
}

log::error() {
  [[ "$#" -eq 1 ]] || return 64
  log::__write ERROR "$1"
}
