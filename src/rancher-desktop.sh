#!/usr/bin/env bash
# @file rancher-desktop
# @brief Rancher Desktop installation.
# @description Rancher Desktop is installed from its official releases.

# shellcheck disable=SC2119,SC2120

# @description Write Rancher Desktop versions available to the current platform.
#
# @noargs
# @stdout Rancher Desktop versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   rancher-desktop::versions
rancher-desktop::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' index_entries=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions rancher
      ;;
    ubuntu)
      index_entries="$(package::_deb-index-entries \
        https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Packages rancher-desktop)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | package::_sort-versions
      ;;
    fedora)
      # The rpm repository is built for openSUSE; the fedora one is built for Fedora.
      package::_rpm-repository-versions \
        https://download.opensuse.org/repositories/isv:/Rancher:/stable/fedora/ rancher-desktop
      ;;
  esac
}

# @description Install Rancher Desktop and start it.
#
# Rosetta and Colima are installed separately with rosetta::install and colima::install.
# Ubuntu 22.04 or later and Fedora 35 or later install from Rancher's
# repository; Fedora uses the packages that Rancher builds for Fedora.
#
# @arg $1 string Optional version from rancher-desktop::versions; on macOS only the current version.
# @stderr On Linux, a reminder to log in again when the user was added to the kvm group.
# @exitcode 0 Rancher Desktop is installed and was started.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, Ubuntu is older than 22.04, Fedora is older than 35, or the version is unavailable.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   rancher-desktop::install
rancher-desktop::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_install-cask rancher "${version}" || return "$?"
      rancher-desktop::_start-darwin
      ;;
    ubuntu | fedora)
      rancher-desktop::_install-linux "${platform}" "${version}" || return "$?"
      rancher-desktop::_start-linux
      ;;
  esac
}

# @description Register the Rancher Desktop repository and install the package on Linux.
# @internal
rancher-desktop::_install-linux() {
  [[ "$#" -eq 2 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    # The packages depend on libgdk-pixbuf-2.0-0, which Ubuntu 20.04 and older name differently.
    package::_require-release ubuntu 22 'Rancher Desktop' || return "$?"
    package::_apt-register-repository isv-rancher-stable \
      https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key \
      https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./ '' || return "$?"
  else
    # The bundled rdctl needs glibc 2.34, which Fedora 35 introduced.
    package::_require-release fedora 35 'Rancher Desktop' || return "$?"
    # Rancher builds the rpm repository for openSUSE, whose package names Fedora
    # lacks, so dnf fell back to version 1.2.1; the fedora repository is built for Fedora.
    package::_dnf-register-repository isv-rancher-stable \
      "[isv-rancher-stable]
name=Rancher Desktop
baseurl=https://download.opensuse.org/repositories/isv:/Rancher:/stable/fedora/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/Rancher:/stable/fedora/repodata/repomd.xml.key
" || return "$?"
  fi
  local version="$2" versions=''
  if [[ "$1" == fedora && -z "${version}" ]]; then
    # dnf install keeps an installed older package, so the newest version is named explicitly.
    versions="$(rancher-desktop::versions)" || return "$?"
    version="$(package::_select-listed-version "${versions}" '' 'Rancher Desktop')" || return "$?"
  fi
  package::_install-version rancher-desktop "${version}" || return "$?"
  if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    package::_add-current-user-to-group kvm || return "$?"
    console::_write-error 'Log in again so that the kvm group membership takes effect.'
  fi
}

# @description Start Rancher Desktop in the background on macOS.
#
# The path works before LaunchServices has registered the new application.
# open waits while macOS shows a first-launch confirmation, so it runs in the
# background and the setup continues, as on Linux.
# @internal
rancher-desktop::_start-darwin() {
  [[ "$#" -eq 0 ]] || return 64
  local application='/Applications/Rancher Desktop.app'
  if [[ -d "${application}" ]]; then
    (open "${application}" >/dev/null 2>&1 &)
  else
    (open -a 'Rancher Desktop' >/dev/null 2>&1 &)
  fi
}

# @description Start Rancher Desktop in the background on Linux.
# @internal
rancher-desktop::_start-linux() {
  [[ "$#" -eq 0 ]] || return 64
  command::require rancher-desktop || return "$?"
  (rancher-desktop >/dev/null 2>&1 &)
}
