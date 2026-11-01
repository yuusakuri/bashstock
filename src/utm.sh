#!/usr/bin/env bash
# @file utm
# @brief UTM installation.
# @description UTM is installed from its release disk image on macOS.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Open the UTM application on macOS.
#
# @noargs
# @exitcode 0 UTM was opened.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of open.
# @example
#   utm::open
utm::open() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == darwin ]] || return 69
  open -a UTM
}

# @description Write UTM release versions.
#
# @noargs
# @stdout Stable UTM release versions, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 Perl is unavailable.
# @exitcode 74 The GitHub release list could not be downloaded or read.
# @example
#   utm::versions | tail -n 1
utm::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_github-release-versions utmapp/UTM
}

# @description Install UTM from its release disk image on macOS.
#
# @arg $1 string Optional UTM release version. Defaults to the newest stable release.
# @arg $2 string Optional destination directory. Defaults to /Applications.
# @exitcode 0 UTM.app was copied to the destination.
# @exitcode 64 The argument count is wrong.
# @exitcode 66 The destination directory does not exist.
# @exitcode 69 The system is not macOS, or hdiutil is unavailable.
# @exitcode 74 The disk image could not be downloaded, mounted, or copied.
# @example
#   utm::install 4.6.4
utm::install() {
  [[ "$#" -le 2 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require hdiutil || return "$?"
  local version="${1:-}" applications="${2:-/Applications}" directory='' mount='' status=0
  [[ -d "${applications}" ]] || return 66
  if [[ -z "${version}" ]]; then
    version="$(utm::versions | package::_latest-stable-version)" || return "$?"
  fi
  directory="$(package::_temporary-directory)" || return "$?"
  mount="${directory}/mount"
  package::_download "https://github.com/utmapp/UTM/releases/download/v${version}/UTM.dmg" \
    "${directory}/UTM.dmg" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    mkdir -p -- "${mount}" && hdiutil attach -nobrowse -readonly -mountpoint "${mount}" \
      "${directory}/UTM.dmg" >/dev/null || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    utm::_copy-application "${mount}/UTM.app" "${applications}" || status="$?"
    hdiutil detach "${mount}" >/dev/null 2>&1 || status=74
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

# @description Replace an application bundle in a destination directory.
#
# The new bundle is copied beside the old one first, and the old bundle is
# removed only after the new one is in place; on failure the old one stays.
#
# @internal
utm::_copy-application() {
  [[ "$#" -eq 2 && -d "$1" && -d "$2" ]] || return 64
  local runner=() name='' target='' staged='' previous=''
  name="$(path::base-name "$1")" || return 64
  target="$2/${name}"
  staged="$2/.${name}.bashstock-new"
  previous="$2/.${name}.bashstock-old"
  [[ -w "$2" ]] || runner=(command::run-as-root)
  ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}" "${previous}" || return 74
  if ! ${runner[@]+"${runner[@]}"} cp -R -- "$1" "${staged}"; then
    ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}"
    return 74
  fi
  if [[ -e "${target}" ]] && ! ${runner[@]+"${runner[@]}"} mv -- "${target}" "${previous}"; then
    ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}"
    return 74
  fi
  if ! ${runner[@]+"${runner[@]}"} mv -- "${staged}" "${target}"; then
    [[ ! -e "${previous}" ]] || ${runner[@]+"${runner[@]}"} mv -- "${previous}" "${target}"
    ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}"
    return 74
  fi
  ${runner[@]+"${runner[@]}"} rm -rf -- "${previous}" || return 74
}
