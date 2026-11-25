#!/usr/bin/env bash
# @file chatgpt
# @brief ChatGPT desktop application installation.
# @description The application is installed on macOS.

# shellcheck disable=SC2119,SC2120

# @description Write the package architecture for the ChatGPT desktop app on Linux after checking the release.
# @internal
chatgpt::_architecture() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_require-release ubuntu 24 'The ChatGPT desktop app' || return "$?"
      architecture="$(package::_deb-architecture)" || return "$?"
      [[ "${architecture}" == amd64 || "${architecture}" == arm64 ]] || architecture=''
      ;;
    fedora)
      package::_require-release fedora 43 'The ChatGPT desktop app' || return "$?"
      architecture="$(package::_rpm-architecture)" || return "$?"
      [[ "${architecture}" == x86_64 || "${architecture}" == aarch64 ]] || architecture=''
      ;;
    *) return 64 ;;
  esac
  if [[ -z "${architecture}" ]]; then
    console::_write-error 'The ChatGPT desktop app provides Linux packages only for x86_64 and arm64.'
    return 69
  fi
  printf '%s\n' "${architecture}"
}

# @description Configure the ChatGPT desktop launchers to use native Wayland in the current Wayland session.
# @internal
chatgpt::_configure-wayland-launchers() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "${XDG_SESSION_TYPE:-}" == 'wayland' && -n "${WAYLAND_DISPLAY:-}" ]] || return 0

  local system_entry='/usr/share/applications/chatgpt.desktop'
  local user_entry="${HOME}/.local/share/applications/chatgpt.desktop"
  local autostart_entry="${HOME}/.config/autostart/chatgpt.desktop"
  if [[ ! -e "${user_entry}" && ! -L "${user_entry}" ]]; then
    [[ -f "${system_entry}" ]] || return 74
    mkdir -p "${HOME}/.local/share/applications" || return 74
    cp -p -- "${system_entry}" "${user_entry}" || return 74
  fi
  [[ -f "${user_entry}" && ! -L "${user_entry}" ]] || return 66
  file::replace-text "${user_entry}" '^Exec=(/usr/bin/)?chatgpt([[:space:]].*)?$' \
    'Exec=chatgpt --ozone-platform=wayland %U' || return 74

  if [[ -e "${autostart_entry}" || -L "${autostart_entry}" ]]; then
    [[ -f "${autostart_entry}" && ! -L "${autostart_entry}" ]] || return 66
    file::replace-text "${autostart_entry}" '^Exec=(/usr/bin/)?chatgpt([[:space:]].*)?$' \
      'Exec=chatgpt --ozone-platform=wayland' || return 74
  fi
}

# @description Install the newest ChatGPT desktop app, which also runs Codex.
#
# macOS installs the Homebrew cask chatgpt. Ubuntu 24.04 or later and
# Fedora 43 or later install OpenAI's newest package, which registers
# OpenAI's signed repository so later releases arrive with the system's
# package upgrades. In a Wayland session, Linux also configures the app's
# desktop launcher and existing autostart entry to start with native Wayland.
#
# @noargs
# @exitcode 0 The ChatGPT desktop app is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded package is for another CPU or is not a valid package.
# @exitcode 69 The platform, release, or CPU is unsupported.
# @exitcode 66 A ChatGPT launcher exists but is not a regular file.
# @exitcode 74 The package could not be downloaded or the Wayland launcher could not be configured.
# @exitcode other The status of the package manager.
# @example
#   chatgpt::install
chatgpt::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture='' directory='' file='' status=0
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask chatgpt
    return
  fi
  architecture="$(chatgpt::_architecture)" || return "$?"
  if [[ "${platform}" == 'ubuntu' ]]; then
    apt::deb::install-from-url \
      "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_${architecture}.deb" "${architecture}" ||
      return "$?"
    chatgpt::_configure-wayland-launchers
    return "$?"
  fi
  command::require dnf || return "$?"
  directory="$(package::_temporary-directory)" || return "$?"
  file="${directory}/chatgpt.${architecture}.rpm"
  package::_download "https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.${architecture}.rpm" \
    "${file}" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root dnf install -y "${file}" || status="$?"
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  chatgpt::_configure-wayland-launchers
}
