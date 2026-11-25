#!/usr/bin/env bash
# @file claude-desktop
# @brief Claude desktop application installation.
# @description The application is installed from Anthropic's signed packages.

# shellcheck disable=SC2119,SC2120

# @description Require an Ubuntu release that Claude Desktop supports.
# @internal
_claude-desktop__require-release() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" != 'ubuntu' ]]; then
    _console__write-error "Claude Desktop does not support ${platform}; it runs on macOS and Ubuntu 22.04 or later."
    return 69
  fi
  _package__require-release ubuntu 22 'Claude Desktop'
}

# @description Require a CPU that Claude Desktop publishes Debian packages for.
# @internal
_claude-desktop__require-architecture() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture=''
  architecture="$(_package__deb-architecture)" || return "$?"
  case "${architecture}" in
    amd64 | arm64) ;;
    *)
      _console__write-error "Claude Desktop does not provide packages for ${architecture}."
      return 69
      ;;
  esac
}

# @description Register Anthropic's APT repository as the Claude Desktop documentation describes.
#
# The signing key must have the published fingerprint. The key and source
# paths match the ones the claude-desktop package uses, so the package keeps
# this source file instead of adding a second entry with another key path.
# @internal
_claude-desktop__register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  local keyring='/usr/share/keyrings/claude-desktop-archive-keyring.asc'
  local directory='' status=0
  directory="$(_package__temporary-directory)" || return "$?"
  _anthropic__download-signing-key https://downloads.claude.ai/claude-desktop/key.asc "${directory}/key.asc" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -d -m 0755 /usr/share/keyrings || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -m 0644 "${directory}/key.asc" "${keyring}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  file__write-text /etc/apt/sources.list.d/claude-desktop.list \
    "deb [arch=amd64,arm64 signed-by=${keyring}] https://downloads.claude.ai/claude-desktop/apt/stable stable main"$'\n' ||
    return "$?"
  _package__refresh
}

# @description Install the newest Claude Desktop, the app that also runs Claude Code sessions.
#
# macOS installs the Homebrew cask claude, which updates itself. Ubuntu 22.04
# or later installs from Anthropic's APT repository, and later releases
# arrive through the system's regular APT upgrades. Anthropic does not
# publish Claude Desktop for Fedora; use claude-code__install there.
#
# @noargs
# @exitcode 0 Claude Desktop is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key is not Anthropic's published key.
# @exitcode 69 The system is neither macOS nor Ubuntu 22.04 or later, or the CPU is unsupported.
# @exitcode 74 The repository key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   claude-desktop__install
claude-desktop__install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    _package__install-cask claude
    return
  fi
  _claude-desktop__require-release || return "$?"
  _claude-desktop__require-architecture || return "$?"
  _package__refresh || return "$?"
  _package__install ca-certificates curl gnupg || return "$?"
  _claude-desktop__register-repository || return "$?"
  _package__install claude-desktop
}
