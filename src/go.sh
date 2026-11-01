#!/usr/bin/env bash
# @file go
# @brief Go installation and versions.
# @description Go is installed from the official package source of the platform.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the stable Go versions the platform package source offers, oldest first.
#
# Ubuntu lists the versioned golang-X.Y packages, Fedora the golang package,
# and macOS the Homebrew go formulae. Each value is accepted by go::install.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 1 No version was found.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform or its package tool is unsupported or unavailable.
# @exitcode other The status of the package query that failed.
# @example
#   go::version::list
go::version::list() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' versions=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      command::require apt-cache || return "$?"
      versions="$(apt-cache pkgnames golang- 2>/dev/null | sed -n 's/^golang-\([0-9][0-9]*\.[0-9][0-9]*\)$/\1/p')"
      ;;
    fedora)
      versions="$(package::_versions golang)" || return "$?"
      versions="$(printf '%s\n' "${versions}" | sed -n 's/^\([0-9][0-9]*\.[0-9][0-9.]*\)-.*$/\1/p')"
      ;;
    darwin)
      versions="$(package::_brew-formula-versions go)" || return "$?"
      ;;
  esac
  versions="$(printf '%s\n' "${versions}" | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | package::_sort-versions)"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}

# @description Write the newest stable Go version from go::version::list.
#
# @noargs
# @stdout The newest version, such as 1.23.
# @exitcode 0 The version was written.
# @exitcode 1 No version was found.
# @exitcode 64 An argument was given.
# @exitcode other The status of go::version::list.
# @example
#   go::install "$(go::version::latest)"
go::version::latest() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(go::version::list)" || return "$?"
  printf '%s\n' "${versions##*$'\n'}"
}

# @description Register the official Go package source for the current platform.
#
# Go comes from the distribution or Homebrew, so this only checks that the package tool is available.
#
# @noargs
# @exitcode 0 The package source is available.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported or its package tool is unavailable.
# @example
#   go::repository::register
go::repository::register() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(package::_platform)" in
    darwin) command::require brew ;;
    ubuntu) command::require apt-get ;;
    fedora) command::require dnf ;;
    *) return 69 ;;
  esac
}

# @description Install Go from the platform package source.
#
# @arg $1 string Optional version from go::version::list. Defaults to the package source default.
# @exitcode 0 Go was installed.
# @exitcode 64 More than one argument was given.
# @exitcode 69 The platform is unsupported or the version is not offered.
# @exitcode other The status of the package installation.
# @example
#   go::install "$(go::version::latest)"
go::install() {
  [[ "$#" -le 1 ]] || return 64
  go::repository::register || return "$?"
  local platform='' version="${1:-}"
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) package::_install-version go "${version}" ;;
    ubuntu)
      if [[ -n "${version}" ]]; then
        package::_install "golang-${version}"
      else
        package::_install golang
      fi
      ;;
    fedora) package::_install-version golang "${version}" ;;
  esac
}
