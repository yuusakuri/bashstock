#!/usr/bin/env bash
# @file discord
# @brief Discord desktop application installation.
# @description The application is installed from Discord's official downloads.

# shellcheck disable=SC2119,SC2120

# @description Install the newest Discord desktop app.
#
# macOS installs the Homebrew cask discord. Ubuntu installs Discord's Debian
# package, and Fedora installs its RPM package.
#
# @noargs
# @exitcode 0 Discord is installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or a required command is missing.
# @exitcode 74 The package could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   discord__install
discord__install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' directory='' file='' status=0
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    darwin)
      _package__install-cask discord
      ;;
    ubuntu)
      apt__deb__install-from-url \
        'https://discord.com/api/download?platform=linux&format=deb'
      ;;
    fedora)
      command__require dnf || return "$?"
      directory="$(_package__temporary-directory)" || return "$?"
      file="${directory}/discord.rpm"
      _package__download 'https://discord.com/api/download?platform=linux&format=rpm' \
        "${file}" || status="$?"
      if [[ "${status}" -eq 0 ]]; then
        command__run-as-root dnf install -y "${file}" || status="$?"
      fi
      rm -rf -- "${directory}"
      return "${status}"
      ;;
  esac
}
