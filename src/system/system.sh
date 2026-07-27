#!/usr/bin/env bash

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
