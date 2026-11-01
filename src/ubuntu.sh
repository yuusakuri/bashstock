#!/usr/bin/env bash
# @file ubuntu
# @brief Ubuntu setup and server images.
# @description Setup functions configure a fresh Ubuntu installation.

# shellcheck disable=SC2119,SC2120

# @description Write supported Ubuntu LTS versions from the Ubuntu release metadata.
#
# Releases newer than the last upgrade-supported release are included because
# Write the Ubuntu Server ISO architecture for the current machine, or validate one.
# @internal
ubuntu::_server-iso-architecture() {
  [[ "$#" -le 1 ]] || return 64
  local architecture="${1:-}"
  if [[ -z "${architecture}" ]]; then
    case "$(uname -m)" in
      x86_64 | amd64) architecture='amd64' ;;
      arm64 | aarch64) architecture='arm64' ;;
      *) return 69 ;;
    esac
  fi
  [[ "${architecture}" == amd64 || "${architecture}" == arm64 ]] || return 64
  printf '%s\n' "${architecture}"
}

# @description Write the directory URL that publishes Ubuntu Server ISOs of one LTS series.
# @internal
ubuntu::_server-iso-directory() {
  ( [[ "$#" -eq 2 && "$1" =~ ^[0-9]+\.[0-9]+$ ]] ) || return 64
  case "$2" in
    amd64) printf 'https://releases.ubuntu.com/%s/\n' "$1" ;;
    arm64) printf 'https://cdimage.ubuntu.com/releases/%s/release/\n' "$1" ;;
    *) return 64 ;;
  esac
}

# @description Write SHA-256 and file name pairs of the live server ISOs that one LTS series publishes.
# @internal
ubuntu::_server-iso-checksums() {
  [[ "$#" -eq 2 ]] || return 64
  local directory='' sums=''
  directory="$(ubuntu::_server-iso-directory "$1" "$2")" || return "$?"
  sums="$(package::_fetch "${directory}SHA256SUMS" 2>/dev/null)" || return 0
  printf '%s\n' "${sums}" |
    awk -v arch="$2" '$2 ~ ("^\\*?ubuntu-[0-9.]+-live-server-" arch "\\.iso$") { sub(/^\*/, "", $2); print $1 "\t" $2 }'
}

# @description Write the Ubuntu Server LTS versions whose live server ISO is published for an architecture.
#
# The LTS series come from the Ubuntu release metadata, and each version is
# taken from the official SHA256SUMS of its series, so every listed version
# can be downloaded.
#
# @arg $1 string Optional architecture: amd64 or arm64. Defaults to the current machine.
# @stdout Ubuntu Server versions such as 24.04.3, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 The architecture is not amd64 or arm64.
# @exitcode 69 No image is published for the architecture.
# @exitcode 74 The release metadata could not be downloaded.
# @example
#   ubuntu::server-iso-versions arm64
ubuntu::server-iso-versions() {
  [[ "$#" -le 1 ]] || return 64
  local architecture='' metadata='' series='' versions=''
  architecture="$(ubuntu::_server-iso-architecture "${1:-}")" || return "$?"
  metadata="$(package::_fetch https://changelogs.ubuntu.com/meta-release-lts)" || return "$?"
  while IFS= read -r series; do
    [[ -n "${series}" ]] || continue
    versions+="$(ubuntu::_server-iso-checksums "${series}" "${architecture}" |
      sed -E 's/^[^\t]*\tubuntu-([0-9.]+)-live-server-.*/\1/')"$'\n'
  done < <(printf '%s\n' "${metadata}" | sed -nE 's/^Version:[[:space:]]*([0-9]+\.[0-9]+).*/\1/p' | sort -u)
  versions="$(printf '%s' "${versions}" | package::_sort-versions)"
  [[ -n "${versions}" ]] || return 69
  printf '%s\n' "${versions}"
}

# @description Download an Ubuntu Server live ISO and check it against the official SHA256SUMS.
#
# The image is written to a temporary file next to OUTPUT_PATH and moved into
# place only after its checksum matches, so a failed download or a corrupted
# image leaves an existing file unchanged.
#
# @arg $1 string Optional version from ubuntu::server-iso-versions. Defaults to the newest one.
# @arg $2 string Optional architecture: amd64 or arm64. Defaults to the current machine.
# @arg $3 string Optional destination file. Defaults to the official file name in the current directory.
# @exitcode 0 The verified image is at the destination.
# @exitcode 64 The architecture is invalid, or the argument count is wrong.
# @exitcode 69 The version is not published for the architecture.
# @exitcode 74 The download failed, the checksum does not match, or the file could not be moved.
# @example
#   ubuntu::download-server-iso 24.04.3 amd64 "${HOME}/iso/ubuntu.iso"
ubuntu::download-server-iso() {
  [[ "$#" -le 3 ]] || return 64
  local version="${1:-}" architecture='' output="${3:-}" versions='' series='' name='' directory=''
  local checksum='' temporary='' status=0
  architecture="$(ubuntu::_server-iso-architecture "${2:-}")" || return "$?"
  versions="$(ubuntu::server-iso-versions "${architecture}")" || return "$?"
  version="$(package::_select-listed-version "${versions}" "${version}" 'Ubuntu Server ISO')" || return "$?"
  series="$(printf '%s' "${version}" | cut -d . -f 1-2)"
  name="ubuntu-${version}-live-server-${architecture}.iso"
  checksum="$(ubuntu::_server-iso-checksums "${series}" "${architecture}" | awk -F '\t' -v name="${name}" '$2 == name {print $1}')"
  ( [[ "${checksum}" =~ ^[0-9a-f]{64}$ ]] ) || return 74
  directory="$(ubuntu::_server-iso-directory "${series}" "${architecture}")" || return "$?"
  [[ -n "${output}" ]] || output="./${name}"
  temporary="$(mktemp "${output}.XXXXXX")" || return 74
  package::_download "${directory}${name}" "${temporary}" || status="$?"
  if [[ "${status}" -eq 0 ]] && ! file::verify-sha256 "${temporary}" "${checksum}"; then
    console::_write-error "The downloaded ${name} does not match the official SHA256SUMS."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    mv -f -- "${temporary}" "${output}" || status=74
  fi
  rm -f -- "${temporary}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  printf '%s\n' "${output}"
}

# @description Apply the common Ubuntu user configuration, stopping at the first failure.
#
# Missing curl and Git are installed first. The steps then register ~/.env, set
# the editor to code --wait, ignore case in completion, link English names to
# localized user directories, add the user to dialout, configure Git with Git
# Credential Manager, fix ~/.ssh permissions, and install external tools.
#
# @noargs
# @stderr The step that failed.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of the first step that failed.
# @example
#   GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' ubuntu::setup
ubuntu::setup() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local missing_packages=()
  command::exists curl || missing_packages+=(curl)
  command::exists git || missing_packages+=(git)
  if [[ "${#missing_packages[@]}" -gt 0 ]]; then
    setup::_run-step package::_install "${missing_packages[@]}" || return "$?"
  fi
  setup::_ensure-file "${HOME}/.env" || return "$?"
  setup::_run-step env::dotenv::register "${HOME}/.env" || return "$?"
  setup::_run-step shell::editor::set-default 'code --wait' || return "$?"
  setup::_run-step shell::completion::enable-ignore-case || return "$?"
  setup::_run-step user::directory::create-english-links || return "$?"
  setup::_run-step user::add-to-group dialout || return "$?"
  setup::_run-step git::config::setup || return "$?"
  setup::_run-step git::config::use-credential-manager || return "$?"
  setup::_run-step ssh::setup-directory || return "$?"
  ubuntu::setup-external
}

# @description Install GnuPG and GitHub CLI when they are not already available.
#
# GitHub CLI is installed from its official Ubuntu APT repository after checking
# the repository key against GitHub's published fingerprints.
#
# @noargs
# @exitcode 0 The missing tools were installed or were already available.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu, or a required command is missing.
# @exitcode 77 sudo refused the credentials.
# @exitcode other A package installation or repository setup failed.
# @example
#   ubuntu::setup-external
ubuntu::setup-external() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  if ! command::exists gpg; then
    setup::_run-step package::_install gnupg || return "$?"
  fi
  if ! command::exists gh; then
    setup::_run-step gh::install || return "$?"
  fi
}

# @description Apply the Ubuntu user configuration and desktop settings, stopping at the first failure.
#
# After ubuntu::setup, the IME keys, Mozc and US input sources, Hiragana
# start, and VLC as the video application are set.
#
# @noargs
# @stderr The step that failed.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu.
# @exitcode other The status of the first step that failed.
# @example
#   ubuntu::setup-desktop
ubuntu::setup-desktop() {
  [[ "$#" -eq 0 ]] || return 64
  ubuntu::setup || return "$?"
  setup::_run-step keyboard::setup-ime-keys || return "$?"
  setup::_run-step gnome::input-source::set-mozc-first || return "$?"
  setup::_run-step gnome::keyboard-layout::set-us || return "$?"
  setup::_run-step mozc::ibus::set-hiragana-as-default || return "$?"
  setup::_run-step vlc::set-default-app
}

# @description Install the newest Mozc for Ubuntu 22.04 and apply the desktop settings.
#
# The window button layout is also set as on Ubuntu 22.04's reference setup.
#
# @noargs
# @stderr The step that failed, or a message on other releases.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu 22.04.
# @exitcode other The status of the first step that failed.
# @example
#   ubuntu::setup-desktop-22
ubuntu::setup-desktop-22() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local version=''
  version="$(platform::_os-release-value VERSION_ID)" || return "$?"
  if [[ "${version}" != '22.04' ]]; then
    console::_write-error 'This setup supports only Ubuntu 22.04.'
    return 69
  fi
  setup::_run-step mozc::server::install || return "$?"
  setup::_run-step mozc::ibus::install || return "$?"
  ubuntu::setup-desktop || return "$?"
  setup::_run-step gnome::window::set-button-layout
}
