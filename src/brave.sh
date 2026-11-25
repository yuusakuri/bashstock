#!/usr/bin/env bash
# @file brave
# @brief Brave browser installation.
# @description Brave is installed from its official package source.

# shellcheck disable=SC2119,SC2120

# @description Register Brave's official repository for the current Linux platform.
# @internal
_brave.register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local directory='' status=0
    directory="$(_package.temporary-directory)" || return "$?"
    _package.download \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
      "${directory}/brave-browser-archive-keyring.gpg" || status="$?"
    if [[ "${status}" -eq 0 ]]; then
      command.run-as-root install -d -m 0755 /usr/share/keyrings || status=74
    fi
    if [[ "${status}" -eq 0 ]]; then
      command.run-as-root install -m 0644 "${directory}/brave-browser-archive-keyring.gpg" \
        /usr/share/keyrings/brave-browser-archive-keyring.gpg || status=74
    fi
    rm -rf -- "${directory}"
    [[ "${status}" -eq 0 ]] || return "${status}"
    file.write-text /etc/apt/sources.list.d/brave-browser-release.sources \
      $'Types: deb\nURIs: https://brave-browser-apt-release.s3.brave.com\nSuites: stable\nComponents: main\nArchitectures: amd64 arm64\nSigned-By: /usr/share/keyrings/brave-browser-archive-keyring.gpg\n' || return "$?"
    _package.refresh
  else
    _package.dnf-register-repository brave-browser \
      $'[brave-browser]\nname=Brave Browser\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/$basearch\n'
  fi
}

# @description Write Brave versions available to the current platform.
#
# @noargs
# @stdout Brave versions, one per line; on Ubuntu only builds that the installed C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   brave.versions | tail -n 1
brave.versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(_package.platform)" || return "$?"
  case "${platform}" in
    darwin)
      _package.cask-versions brave-browser
      ;;
    ubuntu)
      architecture="$(_package.deb-architecture)" || return "$?"
      _package.deb-runnable-versions \
        "https://brave-browser-apt-release.s3.brave.com/dists/stable/main/binary-${architecture}/Packages" \
        brave-browser
      ;;
    fedora)
      architecture="$(_package.rpm-architecture)" || return "$?"
      _package.rpm-repository-versions \
        "https://brave-browser-rpm-release.s3.brave.com/${architecture}" brave-browser
      ;;
  esac
}

# @description Install Brave from its official repository or Homebrew.
#
# On Ubuntu, a version is accepted only when the installed C library can run it,
# and an omitted version selects the newest such build.
#
# @arg $1 string Optional version from brave.versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 Brave is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable or cannot run here.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   brave.install
brave.install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(_package.platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    _package.install-cask brave-browser "${1:-}"
    return
  fi
  local version="${1:-}" versions=''
  if [[ "${platform}" == 'ubuntu' ]]; then
    versions="$(brave.versions)" || return "$?"
    version="$(_package.select-listed-version "${versions}" "${version}" 'Brave')" || return "$?"
  fi
  _brave.register-repository "${platform}" || return "$?"
  _package.install-version brave-browser "${version}"
}
