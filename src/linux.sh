#!/usr/bin/env bash
# @file linux
# @brief Common Linux setup.
# @description The module defines the setup steps that Ubuntu and Fedora share.

# shellcheck disable=SC2119,SC2120

# @description Install curl, Git, and Python 3 when they are missing.
#
# @internal
_linux.setup-prerequisites() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  local packages=()
  platform="$(_package.platform)" || return "$?"
  command.exists curl || packages+=(curl)
  command.exists git || packages+=(git)
  command.exists python3 || packages+=(python3)
  case "${platform}" in
    ubuntu | fedora) ;;
    *) return 69 ;;
  esac
  [[ "${#packages[@]}" -eq 0 ]] || _command.run-step _package.install "${packages[@]}"
}

# @description Apply the common Linux user configuration, stopping at the first failure.
#
# This function supports Ubuntu and Fedora. It ensures the setup tools are
# installed, then configures Wayland, the user's environment, shell, Git, and SSH.
#
# @noargs
# @stderr The step that failed.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is not Ubuntu or Fedora.
# @exitcode other The status of the first step that failed.
# @example
#   linux.setup
linux.setup() {
  [[ "$#" -eq 0 ]] || return 64
  _package.require-platform ubuntu fedora || return "$?"
  _linux.setup-prerequisites || return "$?"
  _command.run-step electron.wayland.enable || return "$?"
  # ~/.env holds secrets, so only the user may read a new one.
  file.ensure-exists "${HOME}/.env" 0600 || return "$?"
  _command.run-step env.dotenv.register "${HOME}/.env" || return "$?"
  _command.run-step shell.editor.set-default 'code --wait' bash,zsh || return "$?"
  _command.run-step shell.completion.enable-ignore-case || return "$?"
  _command.run-step user.directory.create-english-links || return "$?"
  _command.run-step user.add-to-group dialout || return "$?"
  _command.run-step git.config.setup || return "$?"
  _command.run-step ssh.setup-directory
}

# @description Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available.
#
# Git Credential Manager is configured as Git's credential helper after it is
# installed.
# @internal
# @arg $1 string GnuPG package name of the platform.
_linux.setup-external() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  if ! command.exists gpg; then
    _command.run-step _package.install "$1" || return "$?"
  fi
  if ! command.exists gh; then
    _command.run-step gh.install || return "$?"
  fi
  if ! command.exists git-credential-manager; then
    _command.run-step git-credential-manager.install || return "$?"
  fi
  _command.run-step git.config.use-credential-manager
}
