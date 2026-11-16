#!/usr/bin/env bash
# @file setup
# @brief Linux setup and shared setup steps.
# @description The module defines common Linux configuration and internal setup helpers.

# shellcheck disable=SC2119,SC2120

# @description Run one setup step, report a failure, and return its status.
# @internal
setup::_run-step() {
  [[ "$#" -ge 1 ]] || return 64
  "$@"
  local status="$?"
  [[ "${status}" -eq 0 ]] || console::_write-error "Setup step failed with status ${status}: $*"
  return "${status}"
}

# @description Install curl, Git, and Python 3 when they are missing.
#
# @internal
setup::_ensure-linux-setup-tools() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  local packages=()
  platform="$(package::_platform)" || return "$?"
  command::exists curl || packages+=(curl)
  command::exists git || packages+=(git)
  command::exists python3 || packages+=(python3)
  case "${platform}" in
    ubuntu | fedora) ;;
    *) return 69 ;;
  esac
  [[ "${#packages[@]}" -eq 0 ]] || setup::_run-step package::_install "${packages[@]}"
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
#   setup::linux-config
setup::linux-config() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu fedora || return "$?"
  setup::_ensure-linux-setup-tools || return "$?"
  setup::_run-step electron::wayland::enable || return "$?"
  # ~/.env holds secrets, so only the user may read a new one.
  file::ensure-exists "${HOME}/.env" 0600 || return "$?"
  setup::_run-step env::dotenv::register "${HOME}/.env" || return "$?"
  setup::_run-step shell::editor::set-default 'code --wait' bash,zsh || return "$?"
  setup::_run-step shell::completion::enable-ignore-case || return "$?"
  setup::_run-step user::directory::create-english-links || return "$?"
  setup::_run-step user::add-to-group dialout || return "$?"
  setup::_run-step git::config::setup || return "$?"
  setup::_run-step ssh::setup-directory
}

# @description Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available.
#
# Git Credential Manager is configured as Git's credential helper after it is
# installed.
# @internal
# @arg $1 string GnuPG package name of the platform.
setup::_setup-external() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  if ! command::exists gpg; then
    setup::_run-step package::_install "$1" || return "$?"
  fi
  if ! command::exists gh; then
    setup::_run-step gh::install || return "$?"
  fi
  if ! command::exists git-credential-manager; then
    setup::_run-step git-credential-manager::install || return "$?"
  fi
  setup::_run-step git::config::use-credential-manager
}

# @description Install IBus Mozc on Ubuntu, or upgrade it when the repository offers a newer version.
#
# A newer installed version is kept. The same-version Mozc server is installed
# when the Ubuntu repository offers it.
# @internal
setup::_upgrade-ubuntu-mozc() {
  [[ "$#" -eq 0 ]] || return 64
  local record='' installed='' versions='' latest=''
  record="$(dpkg-query -W -f='${Status}\t${Version}' ibus-mozc 2>/dev/null)" || record=''
  if [[ "${record}" == 'install ok installed'* ]]; then
    installed="${record#*$'\t'}"
  fi
  versions="$(mozc::ibus::versions)" || return "$?"
  latest="${versions##*$'\n'}"
  [[ -n "${latest}" ]] || return 69
  if [[ -n "${installed}" ]] && dpkg --compare-versions "${installed}" ge "${latest}"; then
    return 0
  fi
  setup::_run-step mozc::ibus::install "${latest}"
}
