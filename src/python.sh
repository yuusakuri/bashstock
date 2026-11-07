#!/usr/bin/env bash
# @file python
# @brief Python interpreter selection.
# @description Python scripts use the installed Python 3 minor-version command when available.

# shellcheck disable=SC2119,SC2120

# @description Write the command for the active Python 3 interpreter.
# @internal
python::_command() {
  [[ "$#" -eq 0 ]] || return 64
  command -v python3 >/dev/null 2>&1 || return 69
  local versioned='' executable=''
  versioned="$(python3 -c 'import sys; print(f"python{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)" || return 69
  if [[ "${versioned}" =~ ^python3\.[0-9]+$ ]] && command -v "${versioned}" >/dev/null 2>&1; then
    printf '%s\n' "${versioned}"
    return 0
  fi
  executable="$(python3 -c 'import sys; print(sys.executable)' 2>/dev/null)" || return 69
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
