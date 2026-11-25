#!/usr/bin/env bash
# @file microsoft-edge
# @brief Microsoft Edge installation.
# @description Edge is installed from Microsoft's package source.

# shellcheck disable=SC2119,SC2120

# @description Write the Microsoft Edge Debian package index URL for the current architecture.
# @internal
_microsoft-edge.index-url() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture=''
  architecture="$(_package.deb-architecture)" || return "$?"
  printf 'https://packages.microsoft.com/repos/edge/dists/stable/main/binary-%s/Packages.gz\n' "${architecture}"
}

# @description Write the Microsoft Edge package URL for a version from the vendor package metadata.
# @internal
# @arg $1 string VERSION Package version. Defaults to the newest stable version.
_microsoft-edge.artifact-url() {
  [[ "$#" -le 1 ]] || return 64
  _package.require-platform ubuntu || return "$?"
  local version="${1:-}" index='' index_entries='' entry=''
  index="$(_microsoft-edge.index-url)" || return "$?"
  index_entries="$(_package.deb-index-entries "${index}" microsoft-edge-stable)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(printf '%s\n' "${index_entries}" | cut -f 1 | _package.latest-stable-version)" || return "$?"
  fi
  while IFS=$'\t' read -r entry index; do
    if [[ "${entry}" == "${version}" ]]; then
      printf 'https://packages.microsoft.com/repos/edge/%s\n' "${index}"
      return 0
    fi
  done <<<"${index_entries}"
  return 1
}

# @description Write Microsoft Edge versions available to the current platform.
#
# @noargs
# @stdout Microsoft Edge versions, one per line; on Linux only builds for this CPU, and on Ubuntu only builds the C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform or CPU is unsupported.
# @exitcode 74 The vendor metadata could not be downloaded.
# @example
#   microsoft-edge.versions | tail -n 1
microsoft-edge.versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' index=''
  platform="$(_package.platform)" || return "$?"
  case "${platform}" in
    darwin)
      _package.cask-versions microsoft-edge
      ;;
    ubuntu)
      index="$(_microsoft-edge.index-url)" || return "$?"
      _package.deb-runnable-versions "${index}" microsoft-edge-stable
      ;;
    fedora)
      _package.rpm-repository-versions https://packages.microsoft.com/yumrepos/edge microsoft-edge-stable
      ;;
  esac
}

# @description Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew.
#
# On Linux, a version is accepted only when Microsoft publishes it for the
# running CPU, and on Ubuntu only when the installed C library can run it.
# Microsoft builds Edge for Linux on amd64 only, so arm64 returns 69.
#
# @arg $1 string Optional version from microsoft-edge.versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 Microsoft Edge is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or CPU is unsupported, or the version is unavailable.
# @exitcode 74 The package or repository could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   microsoft-edge.install
microsoft-edge.install() {
  [[ "$#" -le 1 ]] || return 64
  local platform='' url='' versions='' version="${1:-}"
  platform="$(_package.platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    _package.install-cask microsoft-edge "${version}"
    return
  fi
  versions="$(microsoft-edge.versions)" || return "$?"
  version="$(_package.select-listed-version "${versions}" "${version}" 'Microsoft Edge')" || return "$?"
  case "${platform}" in
    ubuntu)
      url="$(_microsoft-edge.artifact-url "${version}")" || return "$?"
      apt.deb.install-from-url "${url}"
      ;;
    fedora)
      _package.dnf-register-repository microsoft-edge "[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
" || return "$?"
      _package.install-version microsoft-edge-stable "${version}"
      ;;
  esac
}
