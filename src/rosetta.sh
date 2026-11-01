#!/usr/bin/env bash
# @file rosetta
# @brief Rosetta installation.
# @description Rosetta is installed on Apple silicon when it is missing.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Install Rosetta on Apple silicon when it is missing, accepting its license.
#
# Intel Macs and Macs that already run x86_64 code succeed without changes.
#
# @noargs
# @exitcode 0 Rosetta is installed or not needed.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS or softwareupdate is unavailable.
# @exitcode other The status of softwareupdate.
# @example
#   rosetta::install
rosetta::install() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == darwin ]] || return 69
  [[ "$(uname -m)" == arm64 ]] || return 0
  if /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
    return 0
  fi
  docker::_run-command softwareupdate --install-rosetta --agree-to-license
}
