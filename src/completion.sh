#!/usr/bin/env bash

### Write the completion helper name that corresponds to a public function.
arg::completion::_helper-name() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi

  local target="$1"
  local namespace="${target%::*}"
  local action="${target##*::}"

  if [[ "${namespace}" == "${target}" || -z "${action}" ]]; then
    return 64
  fi
  printf '%s::_%s-args\n' "${namespace}" "${action}"
}

### Write the public function name that corresponds to a completion helper.
arg::completion::_target-name() {
  if [[ "$#" -ne 1 || "$1" != *'::_'*'-args' ]]; then
    return 64
  fi

  local helper="${1%-args}"
  local namespace="${helper%::_*}"
  local action="${helper##*::_}"

  printf '%s::%s\n' "${namespace}" "${action}"
}

### Dispatch Tab completion to the target function's completion helper.
###
### Registered with `complete -F` for every function that has a matching
### `::_<action>-args` helper. Bash calls this with no arguments and reads
### COMP_WORDS, COMP_CWORD, and COMPREPLY.
arg::completion::dispatch() {
  local target="${COMP_WORDS[0]}"
  local current="${COMP_WORDS[COMP_CWORD]}"
  local previous=''
  local helper=''
  local candidates=''

  helper="$(arg::completion::_helper-name "${target}")" || return 0
  declare -F "${helper}" >/dev/null 2>&1 || return 0

  if [[ "${COMP_CWORD}" -gt 0 ]]; then
    previous="${COMP_WORDS[COMP_CWORD - 1]}"
  fi

  if [[ "${previous}" == -* ]]; then
    candidates="$("${helper}" "${previous}")"
  else
    candidates="$("${helper}")"
  fi

  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "${candidates}" -- "${current}"))
}

### Register Tab completion for every function that has a completion helper.
###
### Called once after every module has been loaded, so that functions
### defined later in the load order are still discovered.
arg::completion::register-all() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  type complete >/dev/null 2>&1 || return 0

  local name=''
  local target=''

  while IFS= read -r name; do
    target="$(arg::completion::_target-name "${name}")" || continue
    declare -F "${target}" >/dev/null 2>&1 || continue
    complete -F arg::completion::dispatch "${target}"
  done < <(declare -F | awk '{print $3}' | grep -E '::_[a-z][a-z0-9-]*-args$')
}
