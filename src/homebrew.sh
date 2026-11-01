#!/usr/bin/env bash
# @file homebrew
# @brief Homebrew installation and casks.
# @description Homebrew is installed with its official installer on macOS.

# shellcheck disable=SC2119,SC2120

# @description Install Homebrew with the official installer when it is missing.
#
# The new Zsh sessions read brew shellenv from .zshrc, and the current
# process finds brew on PATH afterwards. The prefix is /opt/homebrew on Apple
# silicon and /usr/local on Intel Macs.
#
# @noargs
# @exitcode 0 Homebrew is installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode 74 The installer could not be downloaded.
# @exitcode other The status of the official installer.
# @example
#   homebrew::install
#   brew --version
homebrew::install() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command -v brew >/dev/null 2>&1 && return 0
  local directory='' status=0
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
    "${directory}/install.sh" || status="$?"
  [[ "${status}" -ne 0 ]] || /bin/bash "${directory}/install.sh" || status="$?"
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  local prefix=/opt/homebrew
  [[ -x "${prefix}/bin/brew" ]] || prefix=/usr/local
  setup::_ensure-file "${HOME}/.zshrc" || return "$?"
  file::replace-text-or-append "${HOME}/.zshrc" '^.*brew shellenv.*$' \
    "eval \"\$(${prefix}/bin/brew shellenv)\"" || return "$?"
  PATH="${prefix}/bin:${prefix}/sbin:${PATH}"
  export PATH
}

# @description Install Homebrew casks without the quarantine attribute from now on.
#
# HOMEBREW_CASK_OPTS=--no-quarantine is written to the Bash and Zsh startup files
# and exported to the current process.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 74 A startup file could not be written.
# @example
#   homebrew::cask::disable-quarantine
homebrew::cask::disable-quarantine() {
  [[ "$#" -eq 0 ]] || return 64
  env::set-variable HOMEBREW_CASK_OPTS --no-quarantine
}
