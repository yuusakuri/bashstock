#!/usr/bin/env bash
# @file storage
# @brief Disk usage and trash.
# @description Sizes are written in human-readable units.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Show human-readable filesystem usage for a path.
#
# @arg $1 string Optional path. Defaults to the current directory.
# @stdout The df -h report for the file system that holds the path.
# @exitcode 0 The report was written.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The path does not exist.
# @exitcode 69 df is unavailable.
# @example
#   storage::usage "${HOME}"
storage::usage() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local path="${1:-.}"
  [[ -e "$path" || -d "$path" ]] || return 66
  command -v df >/dev/null 2>&1 || return 69
  df -h "$path"
}

# @description Write the largest entries of a directory, including the directory itself, in human-readable sizes.
#
# Directory sizes include everything below them.
#
# @arg $1 string Optional directory to inspect. Defaults to the current directory.
# @arg $2 integer Optional number of entries to write. Defaults to 10.
# @stdout Lines of size and path, largest first.
# @exitcode 0 The entries were written.
# @exitcode 64 The directory does not exist or the count is not a positive integer.
# @exitcode 69 du or sort is unavailable.
# @example
#   storage::largest-entries "${HOME}/Library/Caches" 5
storage::largest-entries() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${1:-.}" max="${2:-10}"
  ( [[ -d "${directory}" && "${max}" =~ ^[1-9][0-9]*$ ]] ) || return 64
  command::require du || return "$?"
  command::require sort || return "$?"
  du -h -a -d 1 -- "${directory}" 2>/dev/null | sort -hr | head -n "${max}"
}

# @description Empty the Linux desktop trash of the current user through administrator execution.
#
# The entries directly under Trash/files and Trash/info are removed.
#
# @noargs
# @exitcode 0 The trash is empty.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Linux.
# @exitcode 74 An entry could not be removed.
# @example
#   storage::clear-trash
storage::clear-trash() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  local trash="${XDG_DATA_HOME:-${HOME}/.local/share}/Trash" part=''
  for part in files info; do
    [[ -d "${trash}/${part}" ]] || continue
    command::run-as-root find "${trash}/${part}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + || return 74
  done
}
