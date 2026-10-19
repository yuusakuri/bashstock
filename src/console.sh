#!/usr/bin/env bash
# @file console
# @brief Diagnostic output to standard error.
# @description Every message is prefixed with the command name, so a caller can tell which function wrote it.

# @description Write one command-prefixed diagnostic to standard error.
# @internal
console::_write-error() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  printf '%s: %s\n' "${BASHSTOCK_NAME:-bashstock}" "$1" >&2
}
