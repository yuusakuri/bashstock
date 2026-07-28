#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### Read one line from standard input and preserve a final partial line.
prompt::__read-line() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  local value=''
  if IFS= read -r value; then
    printf '%s\n' "${value}"
    return 0
  fi
  if [[ -n "${value}" ]]; then
    printf '%s\n' "${value}"
    return 0
  fi
  return 66
}

### Read and normalize a yes-or-no answer.
prompt::confirm() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! string::__require-one-line "$1"; then
    return 64
  fi

  local message="$1"
  local default="${2-}"
  local value=''

  if [[ -n "${default}" && "${default}" != 'yes' && "${default}" != 'no' ]]; then
    return 64
  fi

  printf '%s [yes/no]: ' "${message}" >&2
  value="$(prompt::__read-line)" || return "$?"
  value="$(string::lower "${value}")" || return "$?"
  case "${value}" in
    y | yes)
      printf 'yes\n'
      ;;
    n | no)
      printf 'no\n'
      ;;
    '')
      if [[ -z "${default}" ]]; then
        return 64
      fi
      printf '%s\n' "${default}"
      ;;
    *)
      return 64
      ;;
  esac
}

### Read one line and substitute a default only for empty input.
prompt::read-line-with-default() {
  if [[ "$#" -ne 2 ]] || ! string::__require-one-line "$1"; then
    return 64
  fi

  local value=''
  printf '%s: ' "$1" >&2
  value="$(prompt::__read-line)" || return "$?"
  if [[ -z "${value}" ]]; then
    value="$2"
  fi
  printf '%s\n' "${value}"
}

### Read and normalize a yes, no, or cancel answer.
prompt::confirm-or-cancel() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! string::__require-one-line "$1"; then
    return 64
  fi

  local message="$1"
  local default="${2-}"
  local value=''

  case "${default}" in
    '' | yes | no | cancel)
      ;;
    *)
      return 64
      ;;
  esac

  printf '%s [yes/no/cancel]: ' "${message}" >&2
  value="$(prompt::__read-line)" || return "$?"
  value="$(string::lower "${value}")" || return "$?"
  case "${value}" in
    y | yes)
      printf 'yes\n'
      ;;
    n | no)
      printf 'no\n'
      ;;
    c | cancel)
      printf 'cancel\n'
      ;;
    '')
      if [[ -z "${default}" ]]; then
        return 64
      fi
      printf '%s\n' "${default}"
      ;;
    *)
      return 64
      ;;
  esac
}

### Display indexed choices and write the selected value.
prompt::select-one() {
  if [[ "$#" -lt 2 ]] || ! string::__require-one-line "$1"; then
    return 64
  fi

  local message="$1"
  local items=()
  local item=''
  local index=''
  local selected=''
  shift
  items=("$@")

  for item in "${items[@]}"; do
    if ! string::__require-one-line "${item}"; then
      return 64
    fi
  done

  printf '%s\n' "${message}" >&2
  for ((index = 0; index < ${#items[@]}; index++)); do
    printf '%s) %s\n' "$((index + 1))" "${items[index]}" >&2
  done
  printf 'Selection: ' >&2

  selected="$(prompt::__read-line)" || return "$?"
  if ! number::__is-positive-integer-at-most "${selected}" 2147483647; then
    return 64
  fi
  if ((10#${selected} > ${#items[@]})); then
    return 64
  fi
  printf '%s\n' "${items[10#${selected}-1]}"
}
