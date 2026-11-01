#!/usr/bin/env bash
# @file vlc
# @brief VLC installation.
# @description VLC is installed from the platform package source.

# shellcheck disable=SC2119,SC2120

# @description Set VLC as the default application for every MIME type it declares.
#
# @noargs
# @exitcode 0 VLC opens every MIME type it declares.
# @exitcode 64 An argument was given.
# @exitcode 66 VLC's desktop file was not found or declares no MIME type.
# @exitcode 69 xdg-mime is unavailable.
# @exitcode other The status of xdg-mime.
# @example
#   vlc::set-default-app
#   xdg-mime query default video/mp4
vlc::set-default-app() {
  [[ "$#" -eq 0 ]] || return 64
  command::require xdg-mime || return "$?"
  local desktop='' candidate='' declared='' mime_type=''
  local mime_types=()
  for candidate in /usr/share/applications/vlc.desktop /usr/share/applications/org.videolan.VLC.desktop; do
    [[ -f "${candidate}" ]] && desktop="${candidate}" && break
  done
  [[ -n "${desktop}" ]] || return 66
  declared="$(awk -F= '$1 == "MimeType" {print $2; exit}' "${desktop}")"
  [[ -n "${declared}" ]] || return 66
  IFS=';' read -r -a mime_types <<<"${declared}"
  for mime_type in "${mime_types[@]}"; do
    [[ -n "${mime_type}" ]] || continue
    xdg-mime default "$(path::base-name "${desktop}")" "${mime_type}" || return "$?"
  done
}
