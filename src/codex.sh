#!/usr/bin/env bash
# @file codex
# @brief OpenAI Codex CLI installation.
# @description macOS uses the Homebrew cask and Linux uses OpenAI's standalone installer.

# shellcheck disable=SC2119,SC2120

# @description Install the newest OpenAI Codex CLI.
#
# macOS installs the Homebrew cask codex. Linux runs OpenAI's standalone
# installer, which verifies the release checksum, installs the static musl
# build into $HOME/.local, and keeps it updated. $HOME/.local/bin is added
# to PATH through env::add-path, so the installer leaves the shell startup
# files alone. Signing in is left to the first run of codex.
#
# @noargs
# @stdout The installer's progress and the installed version.
# @exitcode 0 Codex is installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform or CPU is unsupported, or tar is missing.
# @exitcode 74 The installer could not be downloaded or $HOME/.local/bin could not be created.
# @exitcode other The status of the installer or of Homebrew.
# @example
#   codex::install && codex --version
codex::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' directory='' status=0
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask codex
    return
  fi
  case "$(uname -m)" in
    x86_64 | amd64 | aarch64 | arm64) ;;
    *)
      console::_write-error 'Codex provides Linux builds only for x86_64 and arm64.'
      return 69
      ;;
  esac
  # The installer unpacks the release with tar.
  command::require tar || return "$?"
  mkdir -p -- "${HOME}/.local/bin" || return 74
  env::add-path "${HOME}/.local/bin" || return "$?"
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://chatgpt.com/codex/install.sh "${directory}/install.sh" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    CODEX_NON_INTERACTIVE=1 sh "${directory}/install.sh" </dev/null || status="$?"
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  "${HOME}/.local/bin/codex" --version
}
