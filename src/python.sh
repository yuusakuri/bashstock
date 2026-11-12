#!/usr/bin/env bash
# @file python
# @brief Python script execution.
# @description Python scripts run once with the python3 found in PATH, reading and writing UTF-8.

# shellcheck disable=SC2119,SC2120

# @description Run a script once with the python3 found in PATH.
#
# The interpreter is resolved through PATH, so a shell function named python3
# does not replace it. Standard input, standard output, and the script's
# arguments are read as UTF-8 whatever the locale is, and bytes that are not
# UTF-8 pass through unchanged. Python 3.6 would otherwise read them as ASCII
# in the C or POSIX locale, so text read from a UTF-8 file would neither print
# nor match the arguments.
# @internal
# @arg $1 string -c.
# @arg $2 string Python script.
# @arg $@ string Arguments of the script.
python::run() {
  [[ "$#" -ge 2 && "$1" == '-c' ]] || return 64
  local interpreter=''
  interpreter="$(type -P python3)" || return 69
  [[ -n "${interpreter}" ]] || return 69
  PYTHONIOENCODING='utf-8:surrogateescape' "${interpreter}" -c 'import os, sys
sys.argv[1:] = [os.fsencode(argument).decode("utf-8", "surrogateescape") for argument in sys.argv[1:]]
'"$2" "${@:3}"
}
