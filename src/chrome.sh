#!/usr/bin/env bash
# @file chrome
# @brief Google Chrome installation and profiles.
# @description Chrome is installed from Google's package source; profiles live in the Chrome user data directory.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Export a Chrome profile's Bookmarks file.
#
# @arg $1 string Chrome profile directory.
# @arg $2 string Optional output file. Defaults to ./bookmarks.json.
# @exitcode 0 The file was copied.
# @exitcode 64 The arguments are invalid or the profile is not a directory.
# @exitcode 66 The profile has no Bookmarks file.
# @exitcode other The status of cp.
# @example
#   chrome::profile::export-bookmarks "${HOME}/.config/google-chrome/Default" backup/bookmarks.json
chrome::profile::export-bookmarks() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" && ! -L "$1" ]] || return 64
  local output=''
  if [[ "$#" -eq 2 ]]; then output="$2"; else output='./bookmarks.json'; fi
  [[ -f "$1/Bookmarks" && ! -L "$1/Bookmarks" ]] || return 66
  cp -- "$1/Bookmarks" "$output"
}

# @description Export a Chrome profile's Preferences file.
#
# @arg $1 string Chrome profile directory.
# @arg $2 string Optional output file. Defaults to ./preferences.json.
# @exitcode 0 The file was copied.
# @exitcode 64 The arguments are invalid or the profile is not a directory.
# @exitcode 66 The profile has no Preferences file.
# @exitcode other The status of cp.
# @example
#   chrome::profile::export-preferences "${HOME}/.config/google-chrome/Profile 1"
chrome::profile::export-preferences() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" && ! -L "$1" ]] || return 64
  local output=''
  if [[ "$#" -eq 2 ]]; then output="$2"; else output='./preferences.json'; fi
  [[ -f "$1/Preferences" && ! -L "$1/Preferences" ]] || return 66
  cp -- "$1/Preferences" "$output"
}

# @description Write the first known email address from a Chrome profile.
#
# @arg $1 string Chrome profile directory.
# @stdout The email address.
# @exitcode 0 The address was written.
# @exitcode 1 The profile has no email address.
# @exitcode 64 The argument is not a profile with a Preferences file.
# @exitcode 69 jq is unavailable.
# @exitcode 74 Preferences could not be read.
# @example
#   chrome::profile::email "${HOME}/.config/google-chrome/Default"
chrome::profile::email() {
  [[ "$#" -eq 1 && -d "$1" && -f "$1/Preferences" && ! -L "$1/Preferences" ]] || return 64
  command -v jq >/dev/null 2>&1 || return 69
  local email=''
  email="$(jq -r '.. | objects | (.email? // .user_name? // empty) | select(type == "string")' "$1/Preferences" 2>/dev/null | head -n 1)" || return 74
  [[ "$email" == *@*.* ]] || return 1
  printf '%s\n' "$email"
}

# @description Find Chrome profiles whose known email matches literally.
#
# @arg $1 string Email address.
# @arg $2 string Optional Chrome user data directory. Defaults to the standard directory of the platform.
# @stdout One matching profile directory per line.
# @exitcode 0 At least one profile matches.
# @exitcode 1 No profile matches.
# @exitcode 64 The arguments are invalid.
# @exitcode 66 The user data directory does not exist.
# @example
#   chrome::profile::find-by-email developer@example.com
chrome::profile::find-by-email() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  local email="$1" root='' path=''
  if [[ "$#" -eq 2 ]]; then root="$2"; elif [[ "$(system::operating-system)" == darwin ]]; then root="$HOME/Library/Application Support/Google/Chrome"; else root="$HOME/.config/google-chrome"; fi
  [[ -d "$root" ]] || return 66
  (
    shopt -s nullglob
    found=1
    for path in "$root"/Default "$root"/Profile\ *; do
      [[ -d "$path" ]] || continue
      if [[ "$(chrome::profile::email "$path" 2>/dev/null)" == "$email" ]]; then
        printf '%s\n' "$path"
        found=0
      fi
    done
    # Succeed when any profile matched, not only when the last one did.
    exit "$found"
  )
}

# @description Export Chrome Preferences and Bookmarks for profiles whose email matches literally.
#
# @arg $1 string Email address of the Chrome profile, compared literally.
# @arg $2 string Optional destination directory. Defaults to the current directory.
# @exitcode 0 Preferences and Bookmarks of every matching profile were copied as PROFILE_preferences.json and PROFILE_bookmarks.json.
# @exitcode 1 No profile has that email address.
# @exitcode 64 The email address is empty, or the argument count is wrong.
# @exitcode 66 Chrome's user data directory does not exist.
# @exitcode 74 The destination could not be created or a file could not be copied.
# @example
#   chrome::profile::export-user-data-by-email alice@example.com "${HOME}/chrome-backup"
chrome::profile::export-user-data-by-email() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  local output="${2:-.}" profiles='' profile='' name='' status=0
  profiles="$(chrome::profile::find-by-email "$1")" || return "$?"
  [[ -n "${profiles}" ]] || return 1
  mkdir -p -- "${output}" || return 74
  while IFS= read -r profile; do
    name="$(path::base-name "${profile}")" || return "$?"
    chrome::profile::export-preferences "${profile}" "${output}/${name}_preferences.json" || status="$?"
    chrome::profile::export-bookmarks "${profile}" "${output}/${name}_bookmarks.json" || status="$?"
  done <<<"${profiles}"
  return "${status}"
}

# @description Register the Google Chrome repository for the current Linux platform.
# @internal
chrome::_register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local architecture=''
    architecture="$(package::_deb-architecture)" || return "$?"
    package::_apt-register-repository google-chrome https://dl.google.com/linux/linux_signing_key.pub \
      https://dl.google.com/linux/chrome/deb/ stable main "${architecture}"
  else
    local architecture=''
    architecture="$(package::_rpm-architecture)" || return "$?"
    package::_dnf-register-repository google-chrome "[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/${architecture}
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
"
  fi
}

# @description Write Google Chrome versions available to the current platform.
#
# @noargs
# @stdout Google Chrome versions, one per line; on Ubuntu only builds that the installed C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   chrome::versions | tail -n 1
chrome::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions google-chrome
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      package::_deb-runnable-versions \
        "https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-${architecture}/Packages" \
        google-chrome-stable
      ;;
    fedora)
      architecture="$(package::_rpm-architecture)" || return "$?"
      package::_rpm-repository-versions \
        "https://dl.google.com/linux/chrome/rpm/stable/${architecture}" google-chrome-stable
      ;;
  esac
}

# @description Install Google Chrome from the Google repository or Homebrew.
#
# On Ubuntu, a version is accepted only when the installed C library can run it,
# and an omitted version selects the newest such build.
#
# @arg $1 string Optional version from chrome::versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 Google Chrome is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable or cannot run here.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   chrome::install
chrome::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask google-chrome "${1:-}"
    return
  fi
  local version="${1:-}" versions=''
  if [[ "${platform}" == 'ubuntu' ]]; then
    # APT would pick the newest build even when the installed C library cannot run it.
    versions="$(chrome::versions)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" 'Google Chrome')" || return "$?"
  fi
  chrome::_register-repository "${platform}" || return "$?"
  package::_install-version google-chrome-stable "${version}"
}
