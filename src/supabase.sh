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
# @exitcode 74 The release list could not be downloaded or read.
# @example
#   supabase__versions | tail -n 1
supabase__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    _package__versions supabase/tap/supabase
  else
    _package__github-release-versions supabase/cli
  fi
}

# @description Install the Supabase CLI from its Homebrew tap or release packages.
#
# @arg $1 string Optional version from supabase__versions; on macOS only the current tap version. Defaults to the newest one.
# @exitcode 0 The Supabase CLI is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or CPU is unsupported, or the version is unavailable.
# @exitcode 74 The release list or package could not be downloaded or read.
# @exitcode other The status of brew or the package manager.
# @example
#   supabase__install
#   supabase --version
supabase__install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' architecture='' url=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    if [[ -n "${version}" ]]; then
      local current=''
      current="$(_package__brew-formula-stable-version supabase/tap/supabase)" || return "$?"
      if [[ "${version}" != "${current}" ]]; then
        _console__write-error "The Supabase tap provides only version ${current}."
        return 69
      fi
    fi
    brew install supabase/tap/supabase
    return
  fi
  if [[ -z "${version}" ]]; then
    version="$(supabase__versions | _package__latest-stable-version)" || return "$?"
  fi
  if [[ "${platform}" == 'ubuntu' ]]; then
    architecture="$(_package__deb-architecture)" || return "$?"
    url="$(_package__github-release-asset-url supabase/cli "${version}" "_linux_${architecture}\\.deb\$")" || return "$?"
    apt__deb__install-from-url "${url}"
  else
    architecture="$(_package__rpm-architecture)" || return "$?"
    case "${architecture}" in
      x86_64) architecture='amd64' ;;
      aarch64) architecture='arm64' ;;
    esac
    url="$(_package__github-release-asset-url supabase/cli "${version}" "_linux_${architecture}\\.rpm\$")" || return "$?"
    command__run-as-root dnf install -y "${url}"
  fi
}
