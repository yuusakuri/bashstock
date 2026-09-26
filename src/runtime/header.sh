#!/usr/bin/env bash

# Only a completed load in this shell can bypass library initialization.
if [[ "${BASH_SOURCE[0]}" != "${0}" && "${_BASHSTOCK_LOADED:-}" == '1' ]] &&
  declare -F bashstock::_run-as-root >/dev/null; then
  return 0
fi

# Resolve this file before defining functions, without changing the caller's PWD.
# An inherited path never selects a different library or privileged executable.
if _BASHSTOCK_FILE="$(
  CDPATH='' builtin cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    builtin printf '%s/%s\n' "${PWD%/}" "${BASH_SOURCE[0]##*/}"
)"; then
  :
else
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 66
  fi
  exit 66
fi
