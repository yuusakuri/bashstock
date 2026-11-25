#!/usr/bin/env bash
# @file thunderbird
# @brief Thunderbird installation.
# @description Thunderbird is installed with Homebrew on macOS and from the system package on Ubuntu and Fedora.

# shellcheck disable=SC2119,SC2120

# @description Write Thunderbird versions available to the current platform.
#
# @noargs
# @stdout Thunderbird versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   thunderbird__versions | tail -n 1
thunderbird__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    _package__cask-versions thunderbird
  else
    _package__versions thunderbird
  fi
}

# @description Install the Thunderbird email client.
#
# macOS installs the Homebrew cask thunderbird, which updates itself. Ubuntu
# and Fedora install the thunderbird package of the system; on Ubuntu 24.04
# and later that package installs the Snap.
#
# @arg $1 string Optional version from thunderbird__versions; on macOS only the current version. Defaults to the newest one.
# @exitcode 0 Thunderbird is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   thunderbird__install
thunderbird__install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    _package__install-cask thunderbird "${1:-}"
    return
  fi
  _package__install-version thunderbird "${1:-}"
}
