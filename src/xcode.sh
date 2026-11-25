#!/usr/bin/env bash
# @file xcode
# @brief Xcode Command Line Tools.
# @description The tools are installed and upgraded with softwareupdate.

# shellcheck disable=SC2119,SC2120

# @description Write the newest Command Line Tools label offered by softwareupdate.
# @internal
_xcode.command-line-tools.latest-label() {
  [[ "$#" -eq 0 ]] || return 64
  command.require softwareupdate || return "$?"
  local listing='' labels=''
  # The listing is read on its own so that its failure is not taken for "no update".
  listing="$(softwareupdate --list 2>&1)" || return 74
  labels="$(printf '%s\n' "${listing}" |
    sed -n 's/^[[:space:]]*\*[[:space:]]*Label:[[:space:]]*\(Command Line Tools.*\)$/\1/p')" || return 74
  [[ -n "${labels}" ]] || return 1
  printf '%s\n' "${labels}" | awk '{print $NF "\t" $0}' | _package.sort-by-first-field | tail -n 1
}

# @description Update Xcode Command Line Tools without removing the installed tools.
#
# When softwareupdate offers no Command Line Tools update, nothing changes.
#
# @noargs
# @stdout The package information of the updated tools.
# @stderr A message when no update is available.
# @exitcode 0 The tools were updated, or no update is available.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS, or softwareupdate or xcode-select is unavailable.
# @exitcode 74 softwareupdate could not list updates, or xcode-select finds no tools after the update.
# @exitcode other The status of softwareupdate or pkgutil.
# @example
#   xcode.command-line-tools.upgrade
#   clang --version
xcode.command-line-tools.upgrade() {
  [[ "$#" -eq 0 ]] || return 64
  _package.require-platform darwin || return "$?"
  command.require xcode-select || return "$?"
  local label='' status=0
  label="$(_xcode.command-line-tools.latest-label)" || status="$?"
  if [[ "${status}" -eq 1 ]]; then
    _console.write-error 'No Command Line Tools update is available.'
    return 0
  fi
  [[ "${status}" -eq 0 ]] || return "${status}"
  command.run-as-root softwareupdate --install "${label}" || return "$?"
  xcode-select -p >/dev/null || return 74
  pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
}
