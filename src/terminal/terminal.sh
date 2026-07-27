#!/usr/bin/env bash

terminal::is-available() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  [[ -c /dev/tty && -r /dev/tty && -w /dev/tty ]]
}
