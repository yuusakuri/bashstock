#!/usr/bin/env bash
# @file prompt
# @brief Interactive questions on the controlling terminal.
# @description Questions read from the controlling terminal and write the answer to standard output.

# shellcheck disable=SC2119,SC2120

# @description Read one line from standard input and preserve a final partial line.
# @internal
prompt::_read-line() {
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

# @description Read and normalize a yes-or-no answer.
#
# The question goes to standard error and the answer is read from standard input.
# y and n are accepted as abbreviations, without regard to case.
#
# @arg $1 string Question without newlines.
# @arg $2 string Optional default for an empty answer: yes or no. Without it an empty answer is invalid.
# @stdout yes or no.
# @stderr The question followed by [yes/no].
# @exitcode 0 An answer was written.
# @exitcode 64 The answer or the default is invalid.
# @exitcode 66 Standard input ended before an answer.
# @example
#   if [[ "$(prompt::confirm 'Remove the cache?' no)" == yes ]]; then
#     rm -rf -- "${cache}"
#   fi
prompt::confirm() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! string::_require-one-line "$1"; then
    return 64
  fi

  local message="$1"
  local default="${2-}"
  local value=''

  if [[ -n "${default}" && "${default}" != 'yes' && "${default}" != 'no' ]]; then
    return 64
  fi

  printf '%s [yes/no]: ' "${message}" >&2
  value="$(prompt::_read-line)" || return "$?"
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

# @description Read one line and substitute a default only for empty input.
#
# @arg $1 string Prompt without newlines.
# @arg $2 string Value to use when the line is empty.
# @stdout The line that was read, or the default.
# @stderr The prompt followed by a colon.
# @exitcode 0 A value was written.
# @exitcode 64 The prompt contains a newline, or the argument count is not two.
# @exitcode 66 Standard input ended before a line.
# @example
#   name="$(prompt::read-line-with-default 'Branch' main)"
prompt::read-line-with-default() {
  if [[ "$#" -ne 2 ]] || ! string::_require-one-line "$1"; then
    return 64
  fi

  local value=''
  printf '%s: ' "$1" >&2
  value="$(prompt::_read-line)" || return "$?"
  if [[ -z "${value}" ]]; then
    value="$2"
  fi
  printf '%s\n' "${value}"
}

# @description Read and normalize a yes, no, or cancel answer.
#
# y, n, and c are accepted as abbreviations, without regard to case.
#
# @arg $1 string Question without newlines.
# @arg $2 string Optional default for an empty answer: yes, no, or cancel.
# @stdout yes, no, or cancel.
# @stderr The question followed by [yes/no/cancel].
# @exitcode 0 An answer was written.
# @exitcode 64 The answer or the default is invalid.
# @exitcode 66 Standard input ended before an answer.
# @example
#   case "$(prompt::confirm-or-cancel 'Overwrite settings.json?' cancel)" in
#     yes) cp new.json settings.json ;;
#     cancel) return 1 ;;
#   esac
prompt::confirm-or-cancel() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! string::_require-one-line "$1"; then
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
  value="$(prompt::_read-line)" || return "$?"
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

# @description Display indexed choices and write the selected value.
#
# @arg $1 string Message shown above the choices.
# @arg $@ string Choices without newlines; at least one.
# @stdout The chosen value.
# @stderr The message, the numbered choices, and a Selection: prompt.
# @exitcode 0 A choice was written.
# @exitcode 64 The selection is not a listed number, or an argument is invalid.
# @exitcode 66 Standard input ended before a selection.
# @example
#   version="$(prompt::select-one 'Node.js version' 20.18.0 22.11.0)"
prompt::select-one() {
  if [[ "$#" -lt 2 ]] || ! string::_require-one-line "$1"; then
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
    if ! string::_require-one-line "${item}"; then
      return 64
    fi
  done

  printf '%s\n' "${message}" >&2
  for ((index = 0; index < ${#items[@]}; index++)); do
    printf '%s) %s\n' "$((index + 1))" "${items[index]}" >&2
  done
  printf 'Selection: ' >&2

  selected="$(prompt::_read-line)" || return "$?"
  if ! number::_is-positive-integer-at-most "${selected}" 2147483647; then
    return 64
  fi
  if ((10#${selected} > ${#items[@]})); then
    return 64
  fi
  printf '%s\n' "${items[10#${selected}-1]}"
}
