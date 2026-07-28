#!/usr/bin/env bash

### Test whether the controlling terminal is readable and writable.
terminal::is-available() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  [[ -c /dev/tty && -r /dev/tty && -w /dev/tty ]]
}
