#!/usr/bin/env bash
# @file python
# @brief Python interpreter selection.
# @description Python scripts use the installed Python 3 minor-version command when available.

# shellcheck disable=SC2119,SC2120

# @description Write the command for the active Python 3 interpreter.
#
# The executable is resolved through PATH, so a shell function named python3
# does not replace the interpreter.
# @internal
python::_command() {
  [[ "$#" -eq 0 ]] || return 64
  local python3='' versioned='' executable=''
  python3="$(type -P python3)" || return 69
  [[ -n "${python3}" ]] || return 69
  versioned="$("${python3}" -c 'import sys; print("python%d.%d" % sys.version_info[:2])' 2>/dev/null)" || return 69
  if ( [[ "${versioned}" =~ ^python3\.[0-9]+$ ]] ) && type -P "${versioned}" >/dev/null 2>&1; then
    type -P "${versioned}"
    return 0
  fi
  executable="$("${python3}" -c 'import sys; print(sys.executable)' 2>/dev/null)" || return 69
  [[ -x "${executable}" ]] || return 69
  printf '%s\n' "${executable}"
}

# @description Run a script with the active Python 3 interpreter.
# @internal
python::run() {
  [[ "$#" -ge 1 ]] || return 64
  local interpreter=''
  interpreter="$(python::_command)" || return "$?"
  "${interpreter}" "$@"
}
