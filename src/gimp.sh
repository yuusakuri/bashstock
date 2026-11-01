#!/usr/bin/env bash
# @file gimp
# @brief GIMP and G'MIC installation.
# @description GIMP is installed from the platform package source or the official disk image.

# shellcheck disable=SC2119,SC2120

# @description Write GIMP versions available to the current platform.
#
# @noargs
# @stdout GIMP versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   gimp::versions
gimp::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_cask-versions gimp
  else
    package::_versions gimp
  fi
}

# @description Install GIMP, and on Linux the G'MIC plugin from the selected source.
#
# @arg $1 string Optional GIMP version from gimp::versions; on macOS only the current version.
# @arg $2 string Optional G'MIC source on Linux: os (default) or official; see gimp::gmic::install.
# @exitcode 0 GIMP, and on Linux the G'MIC plugin, are installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, the version is unavailable, or the G'MIC source cannot provide the plugin.
# @exitcode other The status of the package manager.
# @example
#   gimp::install '' official
gimp::install() {
  [[ "$#" -le 2 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask gimp "${1:-}"
    return
  fi
  package::_install-version gimp "${1:-}" || return "$?"
  gimp::gmic::install '' "${2:-os}"
}

# @description Write the G'MIC GIMP plugin package name for the current platform.
# @internal
gimp::gmic::_package-name() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu) printf 'gimp-gmic\n' ;;
    fedora) printf 'gmic-gimp\n' ;;
    *)
      console::_write-error "The G'MIC GIMP plugin package is unavailable on ${platform}."
      return 69
      ;;
  esac
}

# @description Write version and URL pairs of the official G'MIC packages for this Ubuntu release and CPU.
# @internal
gimp::gmic::_official-entries() {
  [[ "$#" -eq 0 ]] || return 64
  local release='' codename='' architecture='' listing=''
  package::_require-platform ubuntu || return "$?"
  release="$(platform::_os-release-value VERSION_ID)" || return 69
  codename="$(platform::_os-release-value UBUNTU_CODENAME 2>/dev/null ||
    platform::_os-release-value VERSION_CODENAME)" || return 69
  architecture="$(package::_deb-architecture)" || return "$?"
  # The project serves packages only through the download page's get_file.php links.
  listing="$(package::_fetch https://gmic.eu/download.html)" || return "$?"
  # A release or CPU without a package leaves the list empty.
  { printf '%s\n' "${listing}" |
    grep -oE "get_file\.php\?file=linux/gmic_[0-9.]+_ubuntu${release//./-}_${codename}_${architecture}\.deb" || true; } |
    sort -u |
    sed -E 's|^.*/gmic_([0-9.]+)_.*$|\1\thttps://gmic.eu/&|'
}

# @description Write G'MIC GIMP plugin versions available from the selected source.
#
# @arg $1 string Optional source: os (default) or official.
# @stdout G'MIC plugin versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The platform or CPU is unsupported by the source.
# @exitcode 74 The official package list could not be downloaded.
# @example
#   gimp::gmic::versions official
gimp::gmic::versions() {
  [[ "$#" -le 1 ]] || return 64
  local source="${1:-os}" package='' official_entries=''
  case "${source}" in
    os)
      package="$(gimp::gmic::_package-name)" || return "$?"
      package::_versions "${package}"
      ;;
    official)
      official_entries="$(gimp::gmic::_official-entries)" || return "$?"
      printf '%s\n' "${official_entries}" | cut -f 1 | package::_sort-versions
      ;;
    *) return 64 ;;
  esac
}

# @description Install the G'MIC GIMP plugin.
#
# The os source installs the plugin package of the system package manager.
# Ubuntu 26.04 ships GIMP 3 without one, so the official source installs the
# G'MIC project's package for the running Ubuntu release, which contains the
# GIMP 3 plugin. A source that cannot provide the plugin returns 69 instead
# of switching to the other source.
#
# @arg $1 string Optional version from gimp::gmic::versions for the same source.
# @arg $2 string Optional source: os (default) or official. The official source supports Ubuntu on amd64, the only CPU the G'MIC project builds packages for.
# @stderr A message when the source cannot provide the plugin.
# @exitcode 0 The G'MIC plugin is installed.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The source cannot provide the plugin for this system, or the version is unavailable.
# @exitcode 74 The official package could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   gimp::gmic::install '' official
gimp::gmic::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" source="${2:-os}" package='' versions='' official_entries='' url=''
  case "${source}" in
    os)
      package="$(gimp::gmic::_package-name)" || return "$?"
      versions="$(package::_versions "${package}")" || return "$?"
      if [[ -z "${versions}" ]]; then
        console::_write-error "The system packages do not provide the G'MIC GIMP plugin; use the official source."
        return 69
      fi
      package::_install-version "${package}" "${version}"
      ;;
    official)
      official_entries="$(gimp::gmic::_official-entries)" || return "$?"
      if [[ -z "${official_entries}" ]]; then
        console::_write-error "The G'MIC project publishes no package for this Ubuntu release and CPU."
        return 69
      fi
      versions="$(printf '%s\n' "${official_entries}" | cut -f 1)"
      version="$(package::_select-listed-version "${versions}" "${version}" "G'MIC")" || return "$?"
      url="$(printf '%s\n' "${official_entries}" | awk -F '\t' -v version="${version}" '$1 == version {print $2; exit}')"
      apt::deb::install-from-url "${url}"
      ;;
    *) return 64 ;;
  esac
}
