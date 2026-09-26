#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if bashstock::_main "$@"; then
    exit 0
  else
    exit "$?"
  fi
fi

if [[ "$-" == *i* ]]; then
  arg::completion::register-all || return "$?"
fi

# Mark the library as loaded only after initialization succeeds.
_BASHSTOCK_LOADED=1
return 0
