#!/usr/bin/env bash
# @file terminal
# @brief Availability of the controlling terminal.
# @description terminal::is-available lets interactive functions fail instead of blocking when no terminal is available.

# @description Test whether the controlling terminal is readable and writable.
#
# @noargs
# @exitcode 0 /dev/tty can be read and written.
# @exitcode 1 There is no usable controlling terminal, as in CI or cron.
# @exitcode 64 An argument was given.
# @example
#   terminal::is-available && prompt::confirm 'Continue?'
terminal::is-available() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  [[ -c /dev/tty && -r /dev/tty && -w /dev/tty ]]
}
