#!/usr/bin/env bash
# @file claude-code
# @brief Claude Code installation.
# @description Claude Code is installed with Anthropic's native installer.

# shellcheck disable=SC2119,SC2120

# @description Require a Linux release and CPU that Claude Code publishes packages for.
# @internal
_claude-code__require-system() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      _package__require-release ubuntu 20 'Claude Code' || return "$?"
      architecture="$(_package__deb-architecture)" || return "$?"
      [[ "${architecture}" == amd64 || "${architecture}" == arm64 ]] || architecture=''
      ;;
    fedora)
      architecture="$(_package__rpm-architecture)" || return "$?"
      [[ "${architecture}" == x86_64 || "${architecture}" == aarch64 ]] || architecture=''
      ;;
    *) return 64 ;;
  esac
  if [[ -z "${architecture}" ]]; then
    _console__write-error 'Claude Code provides Linux packages only for x86_64 and arm64.'
    return 69
  fi
}

# @description Register Anthropic's Claude Code repository on the stable channel.
#
# The signing key must have the published fingerprint. On Fedora the
# verified key is stored locally, so DNF imports it without downloading
# another copy.
# @internal
_claude-code__register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' directory='' status=0 keyring=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    ubuntu) keyring='/etc/apt/keyrings/claude-code.asc' ;;
    fedora) keyring='/etc/pki/rpm-gpg/RPM-GPG-KEY-claude-code' ;;
    *) return 64 ;;
  esac
  directory="$(_package__temporary-directory)" || return "$?"
  _anthropic__download-signing-key https://downloads.claude.ai/keys/claude-code.asc "${directory}/claude-code.asc" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -d -m 0755 "${keyring%/*}" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -m 0644 "${directory}/claude-code.asc" "${keyring}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  if [[ "${platform}" == 'ubuntu' ]]; then
    file__write-text /etc/apt/sources.list.d/claude-code.list \
      "deb [signed-by=${keyring}] https://downloads.claude.ai/claude-code/apt/stable stable main"$'\n' || return "$?"
    _package__refresh
  else
    _package__dnf-register-repository claude-code "[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/stable
enabled=1
gpgcheck=1
gpgkey=file://${keyring}
"
  fi
}

# @description Install the newest Claude Code CLI.
#
# macOS installs the Homebrew cask claude-code. Ubuntu 20.04 or later and
# Fedora install from Anthropic's signed stable repository, so later
# releases arrive with the system's package upgrades. Signing in is left to
# the first run of claude.
#
# @noargs
# @exitcode 0 Claude Code is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key is not Anthropic's published key.
# @exitcode 69 The platform is unsupported, Ubuntu is older than 20.04, or the CPU is unsupported.
# @exitcode 74 The repository key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   claude-code__install && claude --version
claude-code__install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    darwin)
      _package__install-cask claude-code
      return
      ;;
    ubuntu)
      _claude-code__require-system || return "$?"
      _package__refresh || return "$?"
      _package__install ca-certificates curl gnupg || return "$?"
      ;;
    fedora)
      _claude-code__require-system || return "$?"
      _package__install ca-certificates curl gnupg2 || return "$?"
      ;;
  esac
  _claude-code__register-repository || return "$?"
  _package__install claude-code
}
