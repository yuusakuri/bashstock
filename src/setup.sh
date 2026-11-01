#!/usr/bin/env bash
# @file setup
# @brief Shared steps of the desktop setup functions.
# @description The module defines internal functions that mac::setup and ubuntu::setup share.

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

# @description Create an empty file when it does not exist.
#
# The new file gets the given mode whatever the caller's umask is.
# @internal
# @arg $1 string File path.
# @arg $2 string Optional octal mode of a new file. Defaults to 0644.
setup::_ensure-file() {
  [[ ( "$#" -eq 1 || "$#" -eq 2 ) && -n "$1" ]] || return 64
  ( [[ "${2:-0644}" =~ ^0[0-7]{3}$ ]] ) || return 64
  if [[ ! -e "$1" ]]; then
    (umask 077 && : >>"$1") && chmod "${2:-0644}" "$1" || return 74
  fi
  [[ -f "$1" ]] || return 66
}

# @description Install curl, Git, and the Perl modules that bashstock uses when they are missing.
#
# Ubuntu's perl package carries JSON::PP and Time::HiRes, which a minimal
# system with only perl-base lacks. Fedora packages each Perl module
# separately, and Fedora Workstation lacks perl-JSON-PP, and on 34 also
# perl-Time-HiRes.
# @internal
setup::_install-prerequisites() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' module=''
  local packages=()
  platform="$(package::_platform)" || return "$?"
  command::exists curl || packages+=(curl)
  command::exists git || packages+=(git)
  case "${platform}" in
    ubuntu)
      perl -MJSON::PP -MTime::HiRes -MPOSIX -e 1 >/dev/null 2>&1 || packages+=(perl)
      ;;
    fedora)
      command::exists perl || packages+=(perl-interpreter)
      for module in JSON::PP Time::HiRes POSIX; do
        perl -M"${module}" -e 1 >/dev/null 2>&1 || packages+=("perl-${module//::/-}")
      done
      ;;
    *) return 69 ;;
  esac
  [[ "${#packages[@]}" -eq 0 ]] || setup::_run-step package::_install "${packages[@]}"
}

# @description Apply the user configuration that Ubuntu and Fedora share, stopping at the first failure.
# @internal
setup::_apply-linux-user-configuration() {
  [[ "$#" -eq 0 ]] || return 64
  setup::_install-prerequisites || return "$?"
  # ~/.env holds secrets, so only the user may read a new one.
  setup::_ensure-file "${HOME}/.env" 0600 || return "$?"
  setup::_run-step env::dotenv::register "${HOME}/.env" || return "$?"
  setup::_run-step shell::editor::set-default 'code --wait' bash,zsh || return "$?"
  setup::_run-step shell::completion::enable-ignore-case || return "$?"
  setup::_run-step user::directory::create-english-links || return "$?"
  setup::_run-step user::add-to-group dialout || return "$?"
  setup::_run-step git::config::setup || return "$?"
  setup::_run-step git::config::use-credential-manager || return "$?"
  setup::_run-step ssh::setup-directory
}

# @description Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available.
#
# The setup makes Git use Git Credential Manager, so it is installed here
# instead of leaving Git with a helper that does not exist.
# @internal
# @arg $1 string GnuPG package name of the platform.
setup::_install-external() {
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
}

# @description Install Mozc for IBus and VLC on Ubuntu when they are missing.
#
# The desktop setup selects Mozc as an input source and VLC as the video
# application, and a desktop installed in another language has neither.
# @internal
setup::_install-ubuntu-desktop-applications() {
  [[ "$#" -eq 0 ]] || return 64
  if [[ "$(dpkg-query -W -f='${Status}' ibus-mozc 2>/dev/null)" != 'install ok installed' ]]; then
    setup::_run-step mozc::ibus::install || return "$?"
  fi
  if [[ ! -f /usr/share/applications/vlc.desktop && ! -f /usr/share/applications/org.videolan.VLC.desktop ]]; then
    setup::_run-step package::_install vlc || return "$?"
  fi
}
