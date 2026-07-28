#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120,SC2233,SC2234

string::__require-utf8-locale() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  if ! command -v locale >/dev/null 2>&1; then
    core::__error 'A UTF-8 locale is required.'
    return 69
  fi

  local character_map=''
  character_map="$(locale charmap 2>/dev/null)" || {
    core::__error 'A UTF-8 locale is required.'
    return 69
  }
  case "${character_map}" in
    UTF-8 | UTF8 | utf-8 | utf8)
      return 0
      ;;
    *)
      core::__error 'A UTF-8 locale is required.'
      return 69
      ;;
  esac
}

string::trim() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local first=''
  local last=''

  while [[ -n "${value}" ]]; do
    first="${value:0:1}"
    if [[ "${first}" != [[:space:]] ]]; then
      break
    fi
    value="${value:1}"
  done

  while [[ -n "${value}" ]]; do
    last="${value:$((${#value} - 1)):1}"
    if [[ "${last}" != [[:space:]] ]]; then
      break
    fi
    value="${value:0:$((${#value} - 1))}"
  done

  printf '%s\n' "${value}"
}

string::collapse-whitespace() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local result=''
  local character=''
  local whitespace='1'
  local index=''

  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    if [[ "${character}" == [[:space:]] ]]; then
      whitespace='1'
    else
      if [[ "${whitespace}" -eq 1 && -n "${result}" ]]; then
        result+=' '
      fi
      result+="${character}"
      whitespace='0'
    fi
  done

  printf '%s\n' "${result}"
}

string::is-match() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local value="$1"
  local expression="$2"
  local status=''

  # shellcheck disable=SC2233
  if ( [[ "${value}" =~ ${expression} ]] ); then
    return 0
  else
    status="$?"
  fi

  if [[ "${status}" -eq 2 ]]; then
    return 64
  fi
  return 1
}

string::split() {
  if [[ "$#" -ne 2 || -z "$2" ]] || core::__has-newline "$1" || core::__has-newline "$2"; then
    return 64
  fi

  local value="$1"
  local delimiter="$2"
  local part=''

  while [[ "${value}" == *"${delimiter}"* ]]; do
    part="${value%%"${delimiter}"*}"
    printf '%s\n' "${part}"
    value="${value#*"${delimiter}"}"
  done
  printf '%s\n' "${value}"
}

string::__translate-ascii() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local value="$1"
  local mode="$2"
  local upper='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local lower='abcdefghijklmnopqrstuvwxyz'
  local character=''
  local prefix=''
  local index=''
  local result=''
  local position=''
  local LC_ALL=C

  for ((position = 0; position < ${#value}; position++)); do
    character="${value:position:1}"
    case "${mode}:${character}" in
      lower:[A-Z])
        prefix="${upper%%"${character}"*}"
        index="${#prefix}"
        result+="${lower:index:1}"
        ;;
      upper:[a-z])
        prefix="${lower%%"${character}"*}"
        index="${#prefix}"
        result+="${upper:index:1}"
        ;;
      swap:[A-Z])
        prefix="${upper%%"${character}"*}"
        index="${#prefix}"
        result+="${lower:index:1}"
        ;;
      swap:[a-z])
        prefix="${lower%%"${character}"*}"
        index="${#prefix}"
        result+="${upper:index:1}"
        ;;
      *)
        result+="${character}"
        ;;
    esac
  done

  printf '%s\n' "${result}"
}

string::lower() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::__translate-ascii "$1" lower
}

string::upper() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::__translate-ascii "$1" upper
}

string::swap-case() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::__translate-ascii "$1" swap
}

string::lower-first() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  if [[ -z "$1" ]]; then
    printf '\n'
    return 0
  fi

  local first=''
  first="$(string::lower "${1:0:1}")" || return "$?"
  printf '%s%s\n' "${first}" "${1:1}"
}

string::upper-first() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  if [[ -z "$1" ]]; then
    printf '\n'
    return 0
  fi

  local first=''
  first="$(string::upper "${1:0:1}")" || return "$?"
  printf '%s%s\n' "${first}" "${1:1}"
}

string::strip-surrounding-quotes() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  if [[ "${#value}" -ge 2 ]]; then
    if [[ "${value:0:1}" == "'" && "${value:$((${#value} - 1)):1}" == "'" ]] ||
      [[ "${value:0:1}" == '"' && "${value:$((${#value} - 1)):1}" == '"' ]]; then
      value="${value:1:$((${#value} - 2))}"
    fi
  fi
  printf '%s\n' "${value}"
}

string::remove-all-matches() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1//$2/}"
}

string::remove-first-match() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1/$2/}"
}

string::remove-prefix() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1##$2}"
}

string::remove-suffix() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1%%$2}"
}

string::encode-url() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local character=''
  local encoded=''
  local hex=''
  local code=''
  local index=''
  local LC_ALL=C

  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    case "${character}" in
      [a-zA-Z0-9.~_-])
        encoded+="${character}"
        ;;
      *)
        printf -v code '%d' "'${character}"
        code="$((code & 255))"
        printf -v hex '%02X' "${code}"
        encoded+="%${hex}"
        ;;
    esac
  done

  printf '%s\n' "${encoded}"
}

string::decode-url() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local decoded=''
  local byte=''
  local hex=''
  local index='0'
  local LC_ALL=C

  while ((index < ${#value})); do
    if [[ "${value:index:1}" == '%' ]]; then
      if ((index + 2 >= ${#value})); then
        return 64
      fi
      hex="${value:index+1:2}"
      if ! ( [[ "${hex}" =~ ^[0-9A-Fa-f]{2}$ ]] ) || [[ "${hex}" == '00' ]]; then
        return 64
      fi
      printf -v byte '%b' "\\x${hex}"
      decoded+="${byte}"
      index=$((index + 3))
    else
      decoded+="${value:index:1}"
      index=$((index + 1))
    fi
  done

  printf '%s\n' "${decoded}"
}

string::contains() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  [[ "$1" == *"$2"* ]]
}

string::starts-with() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  [[ "${1:0:${#2}}" == "$2" ]]
}

string::ends-with() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  if [[ -z "$2" ]]; then
    return 0
  fi
  if [[ "${#2}" -gt "${#1}" ]]; then
    return 1
  fi
  [[ "${1:$((${#1} - ${#2}))}" == "$2" ]]
}

string::join() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi

  local delimiter="$1"
  local value=''
  local first='1'
  shift

  for value in "$@"; do
    if [[ "${first}" -eq 0 ]]; then
      printf '%s' "${delimiter}"
    fi
    printf '%s' "${value}"
    first='0'
  done
  printf '\n'
}

string::capture-group() {
  if [[ "$#" -ne 3 ]] ||
    ! core::__is-safe-non-negative-integer "$3" 2147483647; then
    return 64
  fi

  local value="$1"
  local expression="$2"
  local group="$3"

  (
    local status=''
    if [[ "${value}" =~ ${expression} ]]; then
      if ((group >= ${#BASH_REMATCH[@]})); then
        return 64
      fi
      if core::__has-newline "${BASH_REMATCH[group]}"; then
        return 64
      fi
      printf '%s\n' "${BASH_REMATCH[group]}"
      return 0
    else
      # shellcheck disable=SC2319
      status="$?"
    fi
    if [[ "${status}" -eq 2 ]]; then
      return 64
    fi
    return 1
  )
}

string::capture-groups() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local value="$1"
  local expression="$2"

  (
    local status=''
    local index=''
    if [[ "${value}" =~ ${expression} ]]; then
      for ((index = 1; index < ${#BASH_REMATCH[@]}; index++)); do
        if core::__has-newline "${BASH_REMATCH[index]}"; then
          return 64
        fi
        printf '%s\n' "${BASH_REMATCH[index]}"
      done
      return 0
    else
      # shellcheck disable=SC2319
      status="$?"
    fi
    if [[ "${status}" -eq 2 ]]; then
      return 64
    fi
    return 1
  )
}

string::byte-length() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  local LC_ALL=C
  printf '%s\n' "${#1}"
}

string::length() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::__require-utf8-locale || return "$?"
  printf '%s\n' "${#1}"
}

string::replace-first() {
  if [[ "$#" -ne 3 || -z "$2" ]]; then
    return 64
  fi
  local value="$1"
  local pattern="$2"
  local replacement="$3"
  if shopt -q patsub_replacement 2>/dev/null; then
    replacement="${replacement//\\/\\\\}"
    replacement="${replacement//&/\\&}"
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${value/$pattern/$replacement}"
}

string::replace-all() {
  if [[ "$#" -ne 3 || -z "$2" ]]; then
    return 64
  fi
  local value="$1"
  local pattern="$2"
  local replacement="$3"
  if shopt -q patsub_replacement 2>/dev/null; then
    replacement="${replacement//\\/\\\\}"
    replacement="${replacement//&/\\&}"
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${value//$pattern/$replacement}"
}

string::replace-last() {
  if [[ "$#" -ne 3 || -z "$2" ]]; then
    return 64
  fi

  local value="$1"
  local pattern="$2"
  local replacement="$3"
  local candidate=''
  local matched=''
  local start=''
  local length=''

  for ((start = ${#value} - 1; start >= 0; start--)); do
    candidate="${value:start}"
    for ((length = ${#candidate}; length >= 1; length--)); do
      matched="${candidate:0:length}"
      # shellcheck disable=SC2053
      if [[ "${matched}" == ${pattern} ]]; then
        printf '%s%s%s\n' \
          "${value:0:start}" \
          "${replacement}" \
          "${candidate:length}"
        return 0
      fi
    done
  done

  printf '%s\n' "${value}"
}

string::require-non-empty() {
  if [[ "$#" -ne 2 ]] || ! core::__require-display-name "$1"; then
    return 64
  fi
  if [[ -n "$2" ]]; then
    return 0
  fi
  core::__error "$1 must not be empty."
  return 64
}

string::require-empty() {
  if [[ "$#" -ne 2 ]] || ! core::__require-display-name "$1"; then
    return 64
  fi
  if [[ -z "$2" ]]; then
    return 0
  fi
  core::__error "$1 must be empty."
  return 64
}

string::require-allowed() {
  if [[ "$#" -lt 3 ]] || ! core::__require-display-name "$1"; then
    return 64
  fi

  local name="$1"
  local value="$2"
  shift 2
  if array::contains "${value}" "$@"; then
    return 0
  fi
  core::__error "${name} has an unsupported value."
  return 64
}

string::slice() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]] ||
    ! core::__is-safe-non-negative-integer "$2" 2147483647; then
    return 64
  fi
  string::__require-utf8-locale || return "$?"

  local value="$1"
  local start="$2"
  local end="${3-${#1}}"
  local length="${#value}"

  if ! core::__is-safe-non-negative-integer "${end}" 2147483647; then
    return 64
  fi
  if ((10#${start} > 10#${end} || 10#${end} > length)); then
    return 64
  fi
  printf '%s\n' "${value:10#${start}:10#${end}-10#${start}}"
}
