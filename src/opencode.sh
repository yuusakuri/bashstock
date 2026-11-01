#!/usr/bin/env bash
# @file opencode
# @brief OpenCode installation.
# @description OpenCode is installed with its official installer.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Install the newest OpenCode command-line application.
#
# macOS uses the Homebrew tap. Linux installs the official opencode-ai npm
# package into $HOME/.local; its installer picks the build for the CPU and C
# library, and the glibc builds run on Ubuntu 18.04 and later. Linux needs
# npm: the Ubuntu nodejs package does not provide it, so install Node.js with
# `node::install VERSION official` first there.
#
# @noargs
# @stdout The installed version.
# @exitcode 0 OpenCode was installed.
# @exitcode 64 An argument was given.
# @exitcode 69 npm is unavailable.
# @exitcode 74 $HOME/.local could not be created.
# @exitcode other The status of the installation.
# @example
#   opencode::install
opencode::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == darwin ]]; then
    package::_install anomalyco/tap/opencode || return "$?"
    opencode --version
  else
    command::require npm || return "$?"
    mkdir -p -- "${HOME}/.local" || return 74
    npm install --global --prefix "${HOME}/.local" opencode-ai || return "$?"
    env::add-path "${HOME}/.local/bin" || return "$?"
    "${HOME}/.local/bin/opencode" --version
  fi
}
