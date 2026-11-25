#!/usr/bin/env bash
# @file linux
# @brief Common Linux setup.
# @description The module defines the setup steps that Ubuntu and Fedora share.

# shellcheck disable=SC2119,SC2120

# @description Install curl, Git, and Python 3 when they are missing.
#
# @internal
_linux__setup-prerequisites() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  local packages=()
  platform="$(_package__platform)" || return "$?"
  command__exists curl || packages+=(curl)
  command__exists git || packages+=(git)
  command__exists python3 || packages+=(python3)
  case "${platform}" in
    ubuntu | fedora) ;;
    *) return 69 ;;
  esac
  [[ "${#packages[@]}" -eq 0 ]] || _command__run-step _package__install "${packages[@]}"
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
#   linux__setup
linux__setup() {
  [[ "$#" -eq 0 ]] || return 64
  _package__require-platform ubuntu fedora || return "$?"
  _linux__setup-prerequisites || return "$?"
  _command__run-step electron__wayland__enable || return "$?"
  # ~/.env holds secrets, so only the user may read a new one.
  file__ensure-exists "${HOME}/.env" 0600 || return "$?"
  _command__run-step env__dotenv__register "${HOME}/.env" || return "$?"
  _command__run-step shell__editor__set-default 'code --wait' bash,zsh || return "$?"
  _command__run-step shell__completion__enable-ignore-case || return "$?"
  _command__run-step user__directory__create-english-links || return "$?"
  _command__run-step user__add-to-group dialout || return "$?"
  _command__run-step git__config__setup || return "$?"
  _command__run-step ssh__setup-directory
}

# @description Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available.
#
# Git Credential Manager is configured as Git's credential helper after it is
# installed.
# @internal
# @arg $1 string GnuPG package name of the platform.
_linux__setup-external() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  if ! command__exists gpg; then
    _command__run-step _package__install "$1" || return "$?"
  fi
  if ! command__exists gh; then
    _command__run-step gh__install || return "$?"
  fi
  if ! command__exists git-credential-manager; then
    _command__run-step git-credential-manager__install || return "$?"
  fi
  _command__run-step git__config__use-credential-manager
}
