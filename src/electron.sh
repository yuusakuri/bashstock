#!/usr/bin/env bash
# @file electron
# @brief Electron desktop settings.
# @description Configure the rendering platform used by Electron applications.

# shellcheck disable=SC2119,SC2120

# @description Prefer native Wayland rendering for Electron applications in a Wayland session.
#
# The legacy ELECTRON_OZONE_PLATFORM_HINT is stored in systemd's per-user
# environment directory and imported into the running systemd user manager.
# Electron 38 and later ignore it and already select Wayland from the
# XDG_SESSION_TYPE that a Wayland login sets, so an app that still uses
# XWayland forces it itself and needs --ozone-platform=wayland in its
# launcher. Applications that are already running must be restarted. The
# function is a no-op outside a supported Linux Wayland session.
#
# @noargs
# @exitcode 0 The setting was written, the session is not Wayland, or systemd cannot persist it.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is not Linux or mkdir is unavailable.
# @exitcode 74 The setting could not be written.
# @stderr How to force Wayland for an application that overrides the shared preference.
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
  if [[ -z "${systemd_version}" ]]; then
    console::_write-error \
      'systemd is not available, so a shared Electron Wayland setting cannot be persisted. Add --ozone-platform=wayland to the user-level .desktop Exec= line and autostart entry for each affected app, then fully restart it.'
    return 0
  fi
  if ! ( [[ "${systemd_version}" =~ ^[0-9]+$ ]] ) || ((systemd_version < 246)); then
    console::_write-error \
      'This systemd version cannot persist a shared Electron Wayland setting. Add --ozone-platform=wayland to the user-level .desktop Exec= line and autostart entry for each affected app, then fully restart it.'
    return 0
  fi

  mkdir -p "${directory}" || return 74
  file::write-text "${directory}/90-bashstock-electron-wayland.conf" \
    $'ELECTRON_OZONE_PLATFORM_HINT=wayland\n' || return "$?"

  if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user set-environment ELECTRON_OZONE_PLATFORM_HINT=wayland \
      >/dev/null 2>&1 || :
  fi
  console::_write-error \
    'Some Electron apps force XWayland and ignore the shared setting. For one that stays blurry, add --ozone-platform=wayland to its user-level .desktop Exec= line and matching autostart entry, then fully quit and restart it.'
}

# @description Remove BashStock's native Wayland preference for Electron applications.
#
# The BashStock-owned environment file is removed and the variable is unset in
# the running systemd user manager when available. Already-running
# applications are unchanged; start them again to use their default backend.
#
# @noargs
# @exitcode 0 The setting was removed, or there was no setting to remove.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is not Linux.
# @exitcode 66 The setting path exists but is not a regular file or a symlink.
# @exitcode 74 The setting could not be removed.
# @example
#   electron::wayland::disable
electron::wayland::disable() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == 'linux' ]] || return 69

  local file="${HOME}/.config/environment.d/90-bashstock-electron-wayland.conf"
  if [[ -e "${file}" || -L "${file}" ]]; then
    [[ -f "${file}" || -L "${file}" ]] || return 66
    command -v rm >/dev/null 2>&1 || return 69
    rm -f -- "${file}" || return 74
  fi

  if command -v systemctl >/dev/null 2>&1 &&
    systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user unset-environment ELECTRON_OZONE_PLATFORM_HINT \
      >/dev/null 2>&1 || :
  fi
}
