#!/usr/bin/env bash
# @file electron
# @brief Electron desktop settings.
# @description Configure the rendering platform used by Electron applications.

# shellcheck disable=SC2119,SC2120

# @description Prefer native Wayland rendering for Electron applications in a Wayland session.
#
# The setting is stored in systemd's per-user environment directory and
# imported into the running user session when its activation tools are
# available. Applications that are already running must be restarted. The
# function is a no-op outside a supported Linux Wayland session.
#
# @noargs
# @exitcode 0 The setting was written, or the current session is not Wayland.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is not Linux or mkdir is unavailable.
# @exitcode 74 The setting could not be written.
# @example
#   electron::wayland::enable
electron::wayland::enable() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == 'linux' ]] || return 69
  [[ "${XDG_SESSION_TYPE:-}" == 'wayland' && -n "${WAYLAND_DISPLAY:-}" ]] || return 0
  command -v mkdir >/dev/null 2>&1 || return 69

  local systemd_version='' directory="${HOME}/.config/environment.d"
  if command -v systemctl >/dev/null 2>&1; then
    systemd_version="$(systemctl --version 2>/dev/null)"
    systemd_version="${systemd_version#systemd }"
    systemd_version="${systemd_version%% *}"
  fi
  ( [[ "${systemd_version}" =~ ^[0-9]+$ ]] ) || return 0
  ((systemd_version >= 246)) || return 0

  mkdir -p "${directory}" || return 74
  file::write-text "${directory}/90-bashstock-electron-wayland.conf" \
    $'ELECTRON_OZONE_PLATFORM_HINT=wayland\n' || return "$?"

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    if ! dbus-update-activation-environment --systemd ELECTRON_OZONE_PLATFORM_HINT=wayland \
      >/dev/null 2>&1; then
      systemctl --user set-environment ELECTRON_OZONE_PLATFORM_HINT=wayland \
        >/dev/null 2>&1 || :
    fi
  elif systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user set-environment ELECTRON_OZONE_PLATFORM_HINT=wayland \
      >/dev/null 2>&1 || :
  fi
}
