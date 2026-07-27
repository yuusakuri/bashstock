#!/usr/bin/env bash

aws::__require-value() {
  if [[ "$#" -ne 1 || -z "$1" ]] || core::__has-newline "$1"; then
    return 64
  fi
}

aws::__cli() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi
  command -v aws >/dev/null 2>&1 || return 69
  command -v mktemp >/dev/null 2>&1 || return 69

  local output=''
  local error=''
  local status=''
  output="$(mktemp "${TMPDIR:-/tmp}/modern-bash-cli-aws-output.XXXXXX")" || return 74
  error="$(mktemp "${TMPDIR:-/tmp}/modern-bash-cli-aws-error.XXXXXX")" || {
    rm -f -- "${output}"
    return 74
  }

  if command aws "$@" >"${output}" 2>"${error}"; then
    cat "${output}"
    rm -f -- "${output}" "${error}"
    return 0
  else
    status="$?"
  fi

  if grep -Eiq \
    'AccessDenied|Unauthorized|ExpiredToken|InvalidClientTokenId|Unable to locate credentials|NoCredentialProviders' \
    "${error}"; then
    status='77'
  else
    status='75'
  fi
  rm -f -- "${output}" "${error}"
  return "${status}"
}
