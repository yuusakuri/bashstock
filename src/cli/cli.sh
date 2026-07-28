#!/usr/bin/env bash

### Write command help to standard output.
###
### Arguments
###
### This function takes no arguments.
cli::write-help() {
  local content="Usage: ${BASHSTOCK_NAME} [options]"

  content+=$'\n'
  content+=$'\n''Options:'
  content+=$'\n''  -v, --version  Show the version.'
  content+=$'\n''  -h, --help     Show this help.'
  printf '%s\n' "${content}"
}

### Provide the callback required by shFlags.
###
### Arguments
###
### This function takes no arguments.
flags_help() {
  cli::write-help
}

### Define all command flags.
###
### Arguments
###
### This function takes no arguments.
cli::define-flags() {
  FLAGS_PARENT="${BASHSTOCK_NAME}"
  DEFINE_boolean 'version' 'false' 'Show the version.' 'v'
}

### Validate the parsed command values.
###
### Arguments
###
### This function takes no arguments.
cli::validate() {
  if [[ -n "${FLAGS_ARGV}" ]]; then
    console::__write-error 'Positional arguments are not accepted.'
    return 64
  fi
}

### Run the command.
###
### Arguments
###
### * arguments - The command arguments.
cli::run() {
  local parse_status='0'

  cli::define-flags
  FLAGS "$@" || parse_status="$?"

  if [[ "${FLAGS_help:-${FLAGS_FALSE}}" -eq "${FLAGS_TRUE}" ]]; then
    return 0
  fi

  if [[ "${parse_status}" -ne "${FLAGS_TRUE}" ]]; then
    return "${parse_status}"
  fi

  cli::validate

  if [[ "${FLAGS_version}" -eq "${FLAGS_TRUE}" ]]; then
    printf '%s %s\n' "${BASHSTOCK_NAME}" "${BASHSTOCK_VERSION}"
    return 0
  fi

  cli::write-help
}
