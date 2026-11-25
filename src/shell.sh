#!/usr/bin/env bash
# @file shell
# @brief Inspection, startup settings, and interactive prompts of the current shell.
# @description Tests return 0 or 1 without output; prompts read from the controlling terminal and write the answer to standard output.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Test whether a shell function is defined.
#
# @arg $1 string Function name.
# @exitcode 0 The function is defined.
# @exitcode 1 No function has that name.
# @exitcode 64 The name is empty, starts with a dash, or contains a newline.
# @example
#   shell__is-function-defined node__install && node__install
shell__is-function-defined() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! _string__require-one-line "$1"; then
    return 64
  fi

  declare -F "$1" >/dev/null 2>&1
}

# @description Set the default editor of new Bash and Zsh sessions and the current process.
#
# @arg $1 string Optional editor command. Defaults to code --wait.
# @arg $2 string Optional comma-separated shells, bash and zsh. Defaults to bash.
# @set EDITOR is exported in the current process.
# @exitcode 0 The editor was set.
# @exitcode 64 More than two arguments were given or the shell list is invalid.
# @exitcode other The status of env__set-variable.
# @example
#   shell__editor__set-default vim bash,zsh
shell__editor__set-default() {
  [[ "$#" -le 2 ]] || return 64
  env__set-variable EDITOR "${1:-code --wait}" "${2:-bash}"
}

# @description Make Bash and Zsh completion ignore letter case.
#
# Bash reads the setting from $HOME/.inputrc. A new .inputrc first includes
# /etc/inputrc, because Readline stops reading the system file once a
# personal one exists. Zsh receives a matcher-list zstyle in $HOME/.zshrc.
#
# @arg $1 string Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.
# @exitcode 0 The setting was written.
# @exitcode 64 More than one argument was given or the shell list is invalid.
# @exitcode other The status of the file operation that failed.
# @example
#   shell__completion__enable-ignore-case bash
shell__completion__enable-ignore-case() {
  [[ "$#" -le 1 ]] || return 64
  local shells="${1:-bash,zsh}" shell='' line=''
  ( [[ "${shells}" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] ) || return 64
  local _util_shells=()
  IFS=',' read -r -a _util_shells <<<"${shells}"
  for shell in "${_util_shells[@]}"; do
    case "${shell}" in
      bash)
        if [[ ! -e "${HOME}/.inputrc" ]]; then
          if [[ -r /etc/inputrc ]]; then line=$'$include /etc/inputrc\n'; else line=''; fi
          file__write-text "${HOME}/.inputrc" "${line}" || return "$?"
        fi
        file__replace-text-or-append "${HOME}/.inputrc" '^set[[:space:]]+completion-ignore-case[[:space:]].*$' \
          'set completion-ignore-case on' || return "$?"
        ;;
      zsh)
        line="zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'"
        if [[ ! -f "${HOME}/.zshrc" ]] || ! grep -Fqx -- "${line}" "${HOME}/.zshrc"; then
          file__append-text "${HOME}/.zshrc" "${line}"$'\n' || return "$?"
        fi
        ;;
    esac
  done
}

# @description Allow comments that start with # in interactive Zsh sessions.
#
# setopt interactivecomments is written to ~/.zshrc once.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 74 ~/.zshrc could not be written.
# @example
#   shell__zsh__enable-interactive-comments
shell__zsh__enable-interactive-comments() {
  [[ "$#" -eq 0 ]] || return 64
  file__ensure-exists "${HOME}/.zshrc" || return "$?"
  file__replace-text-or-append "${HOME}/.zshrc" '^setopt interactivecomments.*$' 'setopt interactivecomments'
}

# @description Read one line from standard input and preserve a final partial line.
# @internal
_shell__read-answer() {
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
#   if [[ "$(shell__confirm 'Remove the cache?' no)" == yes ]]; then
#     rm -rf -- "${cache}"
#   fi
shell__confirm() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! _string__require-one-line "$1"; then
    return 64
  fi

  local message="$1"
  local default="${2-}"
  local value=''

  if [[ -n "${default}" && "${default}" != 'yes' && "${default}" != 'no' ]]; then
    return 64
  fi

  printf '%s [yes/no]: ' "${message}" >&2
  value="$(_shell__read-answer)" || return "$?"
  value="$(string__lower "${value}")" || return "$?"
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
#   name="$(shell__read-line 'Branch' main)"
shell__read-line() {
  if [[ "$#" -ne 2 ]] || ! _string__require-one-line "$1"; then
    return 64
  fi

  local value=''
  printf '%s: ' "$1" >&2
  value="$(_shell__read-answer)" || return "$?"
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
#   case "$(shell__confirm-or-cancel 'Overwrite settings.json?' cancel)" in
#     yes) cp new.json settings.json ;;
#     cancel) return 1 ;;
#   esac
shell__confirm-or-cancel() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! _string__require-one-line "$1"; then
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
  value="$(_shell__read-answer)" || return "$?"
  value="$(string__lower "${value}")" || return "$?"
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
#   version="$(shell__choose-one 'Node.js version' 20.18.0 22.11.0)"
shell__choose-one() {
  if [[ "$#" -lt 2 ]] || ! _string__require-one-line "$1"; then
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
    if ! _string__require-one-line "${item}"; then
      return 64
    fi
  done

  printf '%s\n' "${message}" >&2
  for ((index = 0; index < ${#items[@]}; index++)); do
    printf '%s) %s\n' "$((index + 1))" "${items[index]}" >&2
  done
  printf 'Selection: ' >&2

  selected="$(_shell__read-answer)" || return "$?"
  if ! _number__is-positive-integer-at-most "${selected}" 2147483647; then
    return 64
  fi
  if ((10#${selected} > ${#items[@]})); then
    return 64
  fi
  printf '%s\n' "${items[10#${selected}-1]}"
}

# @description Wait for one line from the controlling terminal.
#
# @arg $1 string Optional message. Defaults to "Press Enter to continue.".
# @exitcode 0 A line was read.
# @exitcode 64 More than one argument was given.
# @exitcode 69 No controlling terminal is available.
# @exitcode 74 The terminal could not be read.
# @example
#   shell__pause 'Connect the device, then press Enter.'
shell__pause() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local message="${1:-Press Enter to continue.}"
  terminal__is-available || return 69
  local line=''
  IFS= read -r -p "${message}" line </dev/tty || return 74
}
