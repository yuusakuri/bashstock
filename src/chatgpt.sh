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

# @description Add the native Wayland flag to the ChatGPT command on every Exec line of a launcher.
#
# The command's own arguments are kept, so desktop actions and autostart
# flags such as --hidden keep working. A line that already has
# --ozone-platform is left alone.
# @internal
chatgpt::_add-wayland-flag() {
  [[ "$#" -eq 1 ]] || return 64
  local status=0
  file::replace-matches "$1" \
    '^(Exec=\S*[Cc]hat[Gg][Pp][Tt]"?)(?=\s|$)(?!.*\s--ozone-platform=)(.*)$' \
    '\1 --ozone-platform=wayland\2' || status="$?"
  [[ "${status}" -eq 1 ]] || return "${status}"
  file::contains-match "$1" '^Exec=\S*[Cc]hat[Gg][Pp][Tt]"?\s.*--ozone-platform=' && return 0
  console::_write-error \
    "No ChatGPT Exec= line was found in ${1}. Add --ozone-platform=wayland to its command to start it with native Wayland."
}

# @description Configure the ChatGPT desktop launchers to use native Wayland in the current Wayland session.
#
# The package's launcher is copied to the user's applications directory and
# marked as BashStock's, so each install refreshes the copy from the package.
# A user's own launcher there and existing autostart entries are edited in
# place. A missing package launcher is reported and does not fail the install.
# @internal
# @arg $1 string Optional directory of the package's launchers. Defaults to /usr/share/applications.
chatgpt::_configure-wayland-launchers() {
  [[ "$#" -le 1 ]] || return 64
  [[ "${XDG_SESSION_TYPE:-}" == 'wayland' && -n "${WAYLAND_DISPLAY:-}" ]] || return 0

  local applications="${1:-/usr/share/applications}"
  local system_entry='' candidate='' name='' user_entry='' entry='' status=0
  for candidate in "${applications}/chatgpt.desktop" "${applications}/"*[Cc]hat[Gg][Pp][Tt]*.desktop; do
    if [[ -f "${candidate}" ]]; then
      system_entry="${candidate}"
      break
    fi
  done
  if [[ -z "${system_entry}" ]]; then
    console::_write-error \
      "The ChatGPT launcher was not found in ${applications}, so ChatGPT still starts with XWayland. Add --ozone-platform=wayland to its Exec= line."
    return 0
  fi

  name="${system_entry##*/}"
  user_entry="${HOME}/.local/share/applications/${name}"
  if [[ -e "${user_entry}" || -L "${user_entry}" ]]; then
    [[ -f "${user_entry}" && ! -L "${user_entry}" ]] || return 66
  fi
  if [[ ! -e "${user_entry}" ]] || file::contains-match "${user_entry}" '^X-BashStock-Managed=true$'; then
    mkdir -p "${user_entry%/*}" || return 74
    cp -- "${system_entry}" "${user_entry}" || return 74
    file::replace-matches "${user_entry}" '^\[Desktop Entry\]$' '[Desktop Entry]\nX-BashStock-Managed=true' ||
      status="$?"
    [[ "${status}" -eq 0 || "${status}" -eq 1 ]] || return "${status}"
  fi

  for entry in "${user_entry}" "${HOME}/.config/autostart/chatgpt.desktop" "${HOME}/.config/autostart/${name}"; do
    [[ -e "${entry}" || -L "${entry}" ]] || continue
    [[ -f "${entry}" && ! -L "${entry}" ]] || return 66
    chatgpt::_add-wayland-flag "${entry}" || return "$?"
  done
}

# @description Install the newest ChatGPT desktop app, which also runs Codex.
#
# macOS installs the Homebrew cask chatgpt. Ubuntu 24.04 or later and
# Fedora 43 or later install OpenAI's newest package, which registers
# OpenAI's signed repository so later releases arrive with the system's
# package upgrades. In a Wayland session, Linux also configures the app's
# desktop launcher and existing autostart entry to start with native Wayland,
# keeping their arguments. A launcher that cannot be found or changed is
# reported on stderr without failing the install.
#
# @noargs
# @exitcode 0 The ChatGPT desktop app is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded package is for another CPU or is not a valid package.
# @exitcode 69 The platform, release, or CPU is unsupported.
# @exitcode 66 A ChatGPT launcher exists but is not a regular file.
# @exitcode 74 The package could not be downloaded or a ChatGPT launcher could not be written.
# @stderr Each ChatGPT launcher that could not be set to native Wayland.
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
