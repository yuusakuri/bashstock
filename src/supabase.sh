#!/usr/bin/env bash
# @file supabase
# @brief Supabase CLI installation.
# @description The CLI is installed from its official releases.

# shellcheck disable=SC2119,SC2120

# @description Write Supabase CLI versions available to the current platform.
#
# @noargs
# @stdout Supabase CLI versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or Python 3 is missing.
# @exitcode 74 The release list could not be downloaded.
# @example
#   supabase::versions | tail -n 1
supabase::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_versions supabase/tap/supabase
  else
    package::_github-release-versions supabase/cli
  fi
}

# @description Install the Supabase CLI from its Homebrew tap or release packages.
#
# @arg $1 string Optional version from supabase::versions; on macOS only the current tap version. Defaults to the newest one.
# @exitcode 0 The Supabase CLI is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or CPU is unsupported, or the version is unavailable.
# @exitcode 74 The release package could not be downloaded.
# @exitcode other The status of brew or the package manager.
# @example
#   supabase::install
#   supabase --version
supabase::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' architecture='' url=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    if [[ -n "${version}" ]]; then
      local current=''
      current="$(package::_brew-formula-stable-version supabase/tap/supabase)" || return "$?"
      if [[ "${version}" != "${current}" ]]; then
        console::_write-error "The Supabase tap provides only version ${current}."
        return 69
      fi
    fi
    brew install supabase/tap/supabase
    return
  fi
  if [[ -z "${version}" ]]; then
    version="$(supabase::versions | package::_latest-stable-version)" || return "$?"
  fi
  if [[ "${platform}" == 'ubuntu' ]]; then
    architecture="$(package::_deb-architecture)" || return "$?"
    url="$(package::_github-release-asset-url supabase/cli "${version}" "_linux_${architecture}\\.deb\$")" || return "$?"
    apt::deb::install-from-url "${url}"
  else
    architecture="$(package::_rpm-architecture)" || return "$?"
    case "${architecture}" in
      x86_64) architecture='amd64' ;;
      aarch64) architecture='arm64' ;;
    esac
    url="$(package::_github-release-asset-url supabase/cli "${version}" "_linux_${architecture}\\.rpm\$")" || return "$?"
    command::run-as-root dnf install -y "${url}"
  fi
}
