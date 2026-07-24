#!/usr/bin/env bash

### Write command help to standard output.
###
### Arguments
###
### This function takes no arguments.
cli::write-help() {
  local content='Usage: mytool [options]'

  content+=$'\n'
  content+=$'\n''Options:'
  content+=$'\n''  -n, --name NAME    Set the name in the greeting. Default: World.'
  content+=$'\n''  -t, --times COUNT  Set the line count from 1 through 100. Default: 1.'
  content+=$'\n''  -v, --version      Show the version.'
  content+=$'\n''  -h, --help         Show this help.'
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
  FLAGS_PARENT="${MYTOOL_NAME}"
  DEFINE_string 'name' "${MYTOOL_DEFAULT_NAME}" 'Set the greeting name.' 'n'
  DEFINE_integer 'times' "${MYTOOL_DEFAULT_TIMES}" 'Set the line count.' 't'
  DEFINE_boolean 'version' 'false' 'Show the version.' 'v'
}

### Validate the parsed command values.
###
### Arguments
###
### * name - The trimmed greeting name.
cli::validate() {
  local name="${1}"

  if [[ -z "${name}" ]]; then
    output::error 'The name must contain a visible character.'
    return 64
  fi

  if [[ "${name}" == *[[:cntrl:]]* ]]; then
    output::error 'The name must not contain control characters.'
    return 64
  fi

  if ((FLAGS_times < 1 || FLAGS_times > MYTOOL_MAX_TIMES)); then
    output::error "The times value must be from 1 through ${MYTOOL_MAX_TIMES}."
    return 64
  fi

  if [[ -n "${FLAGS_ARGV}" ]]; then
    output::error 'Positional arguments are not accepted.'
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
  local name=''

  cli::define-flags
  FLAGS "$@" || parse_status="$?"

  if [[ "${FLAGS_help:-${FLAGS_FALSE}}" -eq "${FLAGS_TRUE}" ]]; then
    return 0
  fi

  if [[ "${parse_status}" -ne "${FLAGS_TRUE}" ]]; then
    return "${parse_status}"
  fi

  if [[ "${FLAGS_version}" -eq "${FLAGS_TRUE}" ]]; then
    printf '%s %s\n' "${MYTOOL_NAME}" "${MYTOOL_VERSION}"
    return 0
  fi

  name="$(text::trim "${FLAGS_name}")"
  cli::validate "${name}"
  greeting::write "${name}" "${FLAGS_times}"
}
