#!/usr/bin/env bash
# @file system
# @brief Operating-system family and host identity.
# @description Values are normalized so that callers can branch on them without parsing uname output.

# @description Write the normalized operating-system family.
#
# @noargs
# @stdout darwin, linux, or unknown.
# @exitcode 0 The family was written.
# @exitcode 64 An argument was given.
# @example
#   [[ "$(system::operating-system)" == darwin ]] && brew --version
system::operating-system() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  case "${OSTYPE:-}" in
    darwin*)
      printf 'darwin\n'
      ;;
    linux*)
      printf 'linux\n'
      ;;
    *)
      printf 'unknown\n'
      ;;
  esac
}

# @description Write the current host name.
#
# HOSTNAME is used when set; otherwise the hostname command is asked.
#
# @noargs
# @stdout The host name.
# @exitcode 0 The host name was written.
# @exitcode 1 The host name cannot be determined.
# @exitcode 64 An argument was given.
# @example
#   printf 'Running on %s\n' "$(system::host-name)"
system::host-name() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  if [[ -n "${HOSTNAME:-}" ]]; then
    printf '%s\n' "${HOSTNAME}"
    return 0
  fi

  local value=''
  if ! command -v hostname >/dev/null 2>&1; then
    return 1
  fi
  if ! value="$(hostname 2>/dev/null)" || [[ -z "${value}" ]]; then
    return 1
  fi
  printf '%s\n' "${value}"
}
