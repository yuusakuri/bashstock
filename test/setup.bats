#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

# These tests replace only external boundaries: external commands, the
# platform provider, administrator execution, and system file writes.

### Select the operating-system provider and release seen by the library.
use_platform() {
  PLATFORM="$1"
  OS_VERSION="${2:-}"
  OS_CODENAME="${3:-}"
  # shellcheck disable=SC2317
  platform::_identifier() { printf '%s\n' "${PLATFORM}"; }
  # shellcheck disable=SC2317
  platform::_os-release-value() {
    case "$1" in
      VERSION_ID) [[ -n "${OS_VERSION}" ]] && printf '%s\n' "${OS_VERSION}" ;;
      UBUNTU_CODENAME | VERSION_CODENAME) [[ -n "${OS_CODENAME}" ]] && printf '%s\n' "${OS_CODENAME}" ;;
      *) return 1 ;;
    esac
  }
  # shellcheck disable=SC2317
  system::operating-system() {
    if [[ "${PLATFORM}" == 'darwin' ]]; then printf 'darwin\n'; else printf 'linux\n'; fi
  }
}

### Record administrator commands instead of running them.
record_root_commands() {
  ROOT_LOG="${BATS_TEST_TMPDIR}/root.log"
  : >"${ROOT_LOG}"
  # shellcheck disable=SC2317
  command::run-as-root() { printf '%s\n' "$*" >>"${ROOT_LOG}"; }
}

### Redirect system file writes below a temporary root directory.
use_fake_root() {
  FAKE_ROOT="${BATS_TEST_TMPDIR}/root"
  mkdir -p "${FAKE_ROOT}"
  # shellcheck disable=SC2317
  file::write-text() {
    mkdir -p "${FAKE_ROOT}$(dirname "$1")"
    printf '%s' "$2" >"${FAKE_ROOT}$1"
  }
}

### Serve downloads with curl: -o writes CURL_BODY, and -I succeeds unless the URL contains CURL_MISSING.
use_fake_curl() {
  CURL_BODY="${CURL_BODY:-body}"
  CURL_MISSING="${CURL_MISSING:-}"
  # shellcheck disable=SC2317
  curl() {
    local output='' url='' argument=''
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -o) output="$2"; shift 2 ;;
        *) argument="$1"; shift; [[ "${argument}" != https://* ]] || url="${argument}" ;;
      esac
    done
    if [[ -n "${CURL_MISSING}" && "${url}" == *"${CURL_MISSING}"* ]]; then return 22; fi
    if [[ -n "${output}" ]]; then
      if [[ -n "${CURL_FILE:-}" ]]; then cp -- "${CURL_FILE}" "${output}"; else printf '%s' "${CURL_BODY}" >"${output}"; fi
    fi
  }
}

@test "Mozc installers choose the newest version the running release provides" {
  use_platform ubuntu 22.04 jammy
  record_root_commands
  apt-get() { :; }
  apt-cache() {
    [[ "$1" == 'madison' ]] || return 1
    printf ' %s | 2.26.4220.100+dfsg-5.2 | http://archive.ubuntu.com jammy/universe amd64 Packages\n' "$2"
    printf ' %s | 2.28.4715.102+dfsg-2.2~bpo22.04.1 | http://archive.ubuntu.com jammy-backports/universe amd64 Packages\n' "$2"
    printf ' %s | 2.26.4220.100+dfsg-5.2 | http://archive.ubuntu.com jammy/universe Sources\n' "$2"
  }
  run mozc::server::install
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y mozc-server=2.28.4715.102+dfsg-2.2~bpo22.04.1' ]

  : >"${ROOT_LOG}"
  run mozc::ibus::install 2.26.4220.100+dfsg-5.2
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y ibus-mozc=2.26.4220.100+dfsg-5.2 mozc-server=2.26.4220.100+dfsg-5.2' ]
}

@test "package installers use the package manager of each platform" {
  use_platform fedora 44
  record_root_commands
  dnf() { :; }
  run pass::install 1.7.4
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'dnf install -y pass-1.7.4' ]

  use_platform darwin
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  brew() { printf '%s\n' "$*" >>"${BREW_LOG}"; }
  run pass::install
  [ "${status}" -eq 0 ]
  [ "$(<"${BREW_LOG}")" = 'install pass' ]
}

@test "Debian packages install with dependencies only when the architecture matches" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-get() { :; }
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'amd64\n'; }
  dpkg-deb() { printf '%s\n' "${DEB_ARCHITECTURE}"; }

  DEB_ARCHITECTURE='arm64'
  run --separate-stderr deb::install-from-url https://example.invalid/tool.deb
  [ "${status}" -eq 65 ]
  [ ! -s "${ROOT_LOG}" ]

  DEB_ARCHITECTURE='amd64'
  run deb::install-from-url https://example.invalid/tool.deb
  [ "${status}" -eq 0 ]
  [ "$(sed -n 1p "${ROOT_LOG}")" = 'apt-get update' ]
  local install='' package=''
  install="$(sed -n 2p "${ROOT_LOG}")"
  [[ "${install}" == 'env DEBIAN_FRONTEND=noninteractive apt-get install -y /'*'/package.deb' ]]
  package="${install##* }"
  [ ! -e "${package}" ]

  : >"${ROOT_LOG}"
  DEB_ARCHITECTURE='all'
  run deb::install-from-url https://example.invalid/tool.deb
  [ "${status}" -eq 0 ]

  use_platform fedora 44
  run --separate-stderr deb::install-from-url https://example.invalid/tool.deb
  [ "${status}" -eq 69 ]
}

@test "Docker on Ubuntu registers the official repository and starts the service" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-get() { :; }
  use_fake_root
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'arm64\n'; }
  run docker::install '5:29.8.1-1~ubuntu.24.04~noble'
  [ "${status}" -eq 0 ]
  [ "$(<"${FAKE_ROOT}/etc/apt/sources.list.d/docker.sources")" = "$(printf '%s\n' \
    'Types: deb' \
    'URIs: https://download.docker.com/linux/ubuntu' \
    'Suites: noble' \
    'Components: stable' \
    'Architectures: arm64' \
    'Signed-By: /etc/apt/keyrings/docker.asc')" ]
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce=5:29.8.1-1~ubuntu.24.04~noble docker-ce-cli=5:29.8.1-1~ubuntu.24.04~noble containerd.io docker-buildx-plugin docker-compose-plugin' "${ROOT_LOG}"
  grep -Eq '^install -m 0644 .*/docker\.asc /etc/apt/keyrings/docker\.asc$' "${ROOT_LOG}"
  grep -Fqx 'systemctl enable --now docker' "${ROOT_LOG}"
  grep -Fqx "usermod -a -G docker $(id -un)" "${ROOT_LOG}"
}

@test "Docker on Ubuntu changes nothing when the repository lacks the release" {
  use_platform ubuntu 18.04 bionic
  record_root_commands
  use_fake_root
  CURL_MISSING='/dists/bionic/'
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'amd64\n'; }
  run --separate-stderr docker::install
  [ "${status}" -eq 69 ]
  [ ! -s "${ROOT_LOG}" ]
  [ ! -e "${FAKE_ROOT}/etc/apt/sources.list.d/docker.sources" ]
}

@test "Docker on macOS requires Colima or Rancher Desktop to be running" {
  use_platform darwin
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  brew() { printf '%s\n' "$*" >>"${BREW_LOG}"; }
  colima() { return 1; }
  pgrep() { return 1; }
  run --separate-stderr docker::install
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'Colima or Rancher Desktop'* ]]
  [ ! -e "${BREW_LOG}" ]
}

@test "Colima installation starts Colima only when it is not running" {
  use_platform darwin
  COLIMA_LOG="${BATS_TEST_TMPDIR}/colima.log"
  brew() { :; }
  colima() {
    case "$1" in
      status) return "${COLIMA_STATUS}" ;;
      start) printf 'start\n' >>"${COLIMA_LOG}" ;;
    esac
  }
  COLIMA_STATUS=0
  run colima::install
  [ "${status}" -eq 0 ]
  [ ! -e "${COLIMA_LOG}" ]
  COLIMA_STATUS=1
  run colima::install
  [ "${status}" -eq 0 ]
  [ "$(<"${COLIMA_LOG}")" = 'start' ]
}

@test "Homebrew casks accept only the current version and start Rancher Desktop" {
  use_platform darwin
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  OPEN_LOG="${BATS_TEST_TMPDIR}/open.log"
  brew() {
    if [[ "$1" == 'info' ]]; then
      printf '{"casks":[{"version":"1.20.0"}]}'
      return 0
    fi
    printf '%s\n' "$*" >>"${BREW_LOG}"
  }
  open() { printf '%s\n' "$*" >>"${OPEN_LOG}"; }
  run --separate-stderr rancher-desktop::install 1.19.0
  [ "${status}" -eq 69 ]
  [ ! -e "${BREW_LOG}" ]
  run rancher-desktop::install
  [ "${status}" -eq 0 ]
  [ "$(<"${BREW_LOG}")" = 'install --cask rancher' ]
  [ "$(<"${OPEN_LOG}")" = '-a Rancher Desktop' ]
}

@test "Node.js on Ubuntu rejects a major version the distribution does not provide" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-cache() {
    printf ' nodejs | 18.19.1+dfsg-6ubuntu5 | http://archive.ubuntu.com noble/universe amd64 Packages\n'
  }
  run --separate-stderr node::install 22
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'Node.js 18, not 22'* ]]
  [ ! -s "${ROOT_LOG}" ]
}

@test "Microsoft Edge on Ubuntu installs the newest package from vendor metadata" {
  use_platform ubuntu 24.04 noble
  CURL_FILE="${BATS_TEST_TMPDIR}/Packages.gz"
  printf '%s\n' \
    'Package: microsoft-edge-stable' 'Version: 153.0.1-1' 'Filename: pool/main/m/edge_153.0.1-1_amd64.deb' '' \
    'Package: microsoft-edge-stable' 'Version: 154.0.2-1' 'Filename: pool/main/m/edge_154.0.2-1_amd64.deb' '' \
    'Package: microsoft-edge-beta' 'Version: 155.0.1-1' 'Filename: pool/main/m/beta_155.0.1-1_amd64.deb' |
    gzip -c >"${CURL_FILE}"
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'amd64\n'; }
  deb::install-from-url() { printf '%s\n' "$*"; }
  run microsoft-edge::install
  [ "${status}" -eq 0 ]
  [ "${output}" = 'https://packages.microsoft.com/repos/edge/pool/main/m/edge_154.0.2-1_amd64.deb' ]
  run microsoft-edge::install 153.0.1-1
  [ "${output}" = 'https://packages.microsoft.com/repos/edge/pool/main/m/edge_153.0.1-1_amd64.deb' ]
}

@test "APT package search selects the package with the newest version suffix" {
  use_platform ubuntu 24.04 noble
  apt-cache() {
    case "$1" in
      pkgnames) printf '%s\n' openjdk-21-jdk openjdk-8-jdk openjdk-17-jdk openjdk-lts ;;
      policy)
        shift
        local name=''
        for name in "$@"; do printf '%s:\n  Installed: (none)\n  Candidate: 1.0-%s\n' "${name}" "${name}"; done
        ;;
    esac
  }
  run apt::package::latest openjdk-
  [ "${status}" -eq 0 ]
  [ "${output}" = 'openjdk-21-jdk' ]
}

@test "keyboard IME keys map Convert and Nonconvert for the selected USB keyboards" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  use_fake_root
  systemd-hwdb() { :; }
  udevadm() { :; }
  local hwdb="${BATS_TEST_TMPDIR}/root/etc/udev/hwdb.d/90-bashstock-ime-keys.hwdb"

  run keyboard::setup-ime-keys
  [ "${status}" -eq 0 ]
  [ "$(sed -n 2p "${hwdb}")" = 'evdev:input:b0003v*p*' ]
  grep -Fqx ' KEYBOARD_KEY_7008a=henkan' "${hwdb}"
  grep -Fqx ' KEYBOARD_KEY_7008b=muhenkan' "${hwdb}"
  [ "$(<"${ROOT_LOG}")" = $'systemd-hwdb update\nudevadm trigger --subsystem-match=input --action=change' ]

  run keyboard::setup-ime-keys 046d c52b
  [ "${status}" -eq 0 ]
  [ "$(sed -n 2p "${hwdb}")" = 'evdev:input:b0003v046DpC52B*' ]

  run keyboard::setup-ime-keys 46d c52b
  [ "${status}" -eq 64 ]
  run keyboard::setup-ime-keys 046d0 c52b
  [ "${status}" -eq 64 ]
  run keyboard::setup-ime-keys 046d
  [ "${status}" -eq 64 ]
}

### Keep GSettings values in files below GSETTINGS_STORE.
use_fake_gsettings() {
  GSETTINGS_STORE="${BATS_TEST_TMPDIR}/gsettings"
  mkdir -p "${GSETTINGS_STORE}"
  # shellcheck disable=SC2317
  gsettings() {
    local file="${GSETTINGS_STORE}/$(printf '%s %s' "$2" "$3" | tr '/: ' '___')"
    case "$1" in
      range) printf 'type as\n' ;;
      get) if [[ -f "${file}" ]]; then cat "${file}"; printf '\n'; else printf "''\n"; fi ;;
      set) printf '%s' "$4" >"${file}" ;;
    esac
  }
}

### Write one stored GSettings value.
gsettings_value() {
  gsettings get "$1" "$2"
}

@test "custom shortcuts replace conflicting shortcuts and keep the others" {
  use_fake_gsettings
  local schema='org.gnome.settings-daemon.plugins.media-keys'
  local item="${schema}.custom-keybinding"
  local base='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings'
  gsettings set "${schema}" custom-keybindings "['${base}/old/', '${base}/terminal/']"
  gsettings set "${item}:${base}/old/" name "'Enable IME (Mozc)'"
  gsettings set "${item}:${base}/terminal/" name "'Terminal'"
  gsettings set "${item}:${base}/terminal/" command "'gnome-terminal'"
  gsettings set "${item}:${base}/terminal/" binding "'<Ctrl><Alt>t'"

  run gnome::keybinding::set-custom custom101 'Enable IME (Mozc)' "ibus engine 'mozc-jp'" '<Alt>a'
  [ "${status}" -eq 0 ]
  [ "$(gsettings_value "${schema}" custom-keybindings)" = "['${base}/terminal/', '${base}/custom101/']" ]
  [ "$(gsettings_value "${item}:${base}/custom101/" command)" = "'ibus engine \\'mozc-jp\\''" ]
  [ "$(gsettings_value "${item}:${base}/custom101/" binding)" = "'<Alt>a'" ]

  run gnome::keybinding::set-custom custom101 'Enable IME (Mozc)' "ibus engine 'mozc-jp'" '<Alt>a'
  [ "$(gsettings_value "${schema}" custom-keybindings)" = "['${base}/terminal/', '${base}/custom101/']" ]
}

@test "Mozc becomes the first input source while the keyboard layout is kept" {
  use_fake_gsettings
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'jp'), ('ibus', 'mozc-jp')]"
  run gnome::input-source::set-mozc-first
  [ "${status}" -eq 0 ]
  [ "$(gsettings_value org.gnome.desktop.input-sources sources)" = "[('ibus', 'mozc-jp'), ('xkb', 'jp')]" ]

  gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'mozc-jp')]"
  run gnome::input-source::set-mozc-first
  [ "${status}" -eq 1 ]
  [ "$(gsettings_value org.gnome.desktop.input-sources sources)" = "[('ibus', 'mozc-jp')]" ]
}

@test "Flutter installation replaces an SDK but keeps other directories" {
  use_platform darwin
  GIT_LOG="${BATS_TEST_TMPDIR}/git.log"
  git() {
    local argument='' last=''
    for argument in "$@"; do last="${argument}"; done
    printf '%s\n' "$*" >"${GIT_LOG}"
    mkdir -p "${last}"
  }
  local directory="${BATS_TEST_TMPDIR}/flutter"
  mkdir -p "${directory}"
  printf 'keep' >"${directory}/notes.txt"
  run --separate-stderr flutter::install 3.35.0 "${directory}"
  [ "${status}" -eq 73 ]
  [ "$(<"${directory}/notes.txt")" = 'keep' ]
  [ ! -e "${GIT_LOG}" ]

  rm -rf "${directory}"
  mkdir -p "${directory}/bin" "${directory}/.git"
  printf '#!/bin/sh\n' >"${directory}/bin/flutter"
  chmod +x "${directory}/bin/flutter"
  run flutter::install 3.35.0 "${directory}"
  [ "${status}" -eq 0 ]
  [ ! -e "${directory}/bin/flutter" ]
  [ "$(<"${GIT_LOG}")" = "clone --branch 3.35.0 https://github.com/flutter/flutter.git ${directory}" ]
}

@test "GPG key generation keeps passphrases out of arguments and rejects invalid options" {
  PARAMETERS="${BATS_TEST_TMPDIR}/parameters"
  gpg() {
    local argument='' last=''
    for argument in "$@"; do last="${argument}"; done
    cp -- "${last}" "${PARAMETERS}"
    printf '%s\n' "$*" >"${PARAMETERS}.args"
  }
  run gpg::key::generate -UserId 'Test User <test@example.invalid>' -Expires 1y
  [ "${status}" -eq 0 ]
  grep -Fqx 'Key-Type: eddsa' "${PARAMETERS}"
  grep -Fqx 'Subkey-Curve: cv25519' "${PARAMETERS}"
  grep -Fqx 'Name-Real: Test User' "${PARAMETERS}"
  grep -Fqx 'Name-Email: test@example.invalid' "${PARAMETERS}"
  grep -Fqx 'Expire-Date: 1y' "${PARAMETERS}"
  grep -Fqx '%no-protection' "${PARAMETERS}"

  run gpg::key::generate -UserId 'Test User <test@example.invalid>' -PassphraseFd 3
  [ "${status}" -eq 0 ]
  ! grep -Fq '%no-protection' "${PARAMETERS}"
  [[ "$(<"${PARAMETERS}.args")" == '--batch --pinentry-mode loopback --passphrase-fd 3 --generate-key '* ]]

  run gpg::key::generate -Algorithm dsa -UserId 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate -Pinentry -PassphraseFd 3 -UserId 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate -UserId 'no email'
  [ "${status}" -eq 64 ]
}

@test "Mozc starts in Hiragana mode by updating the IBus textproto setting" {
  HOME="${BATS_TEST_TMPDIR}/home"
  local file="${HOME}/.config/mozc/ibus_config.textproto"
  mkdir -p "$(dirname "${file}")"
  printf 'active_on_launch: False\nother: 1\n' >"${file}"
  ibus-daemon() { :; }
  run mozc::ibus::set-hiragana-as-default
  [ "${status}" -eq 0 ]
  [ "$(<"${file}")" = $'active_on_launch: True\nother: 1' ]

  rm -f "${file}"
  run mozc::ibus::set-hiragana-as-default
  [ "${status}" -eq 0 ]
  [ "$(<"${file}")" = 'active_on_launch: True' ]
}

@test "AWS VPN Client log functions select and remove log files" {
  local directory="${BATS_TEST_TMPDIR}/logs"
  mkdir -p "${directory}/nested"
  : >"${directory}/aws_vpn_client_1.log"
  : >"${directory}/nested/aws_vpn_client_2.log"
  : >"${directory}/ovpn_aws_vpn_client_3.log"
  aws-vpn-client::log::files "${directory}" >"${BATS_TEST_TMPDIR}/files"
  [ "$(tr '\0' '\n' <"${BATS_TEST_TMPDIR}/files" | sort)" = "$(printf '%s\n%s' "${directory}/aws_vpn_client_1.log" "${directory}/nested/aws_vpn_client_2.log")" ]
  run aws-vpn-client::log::clear "${directory}"
  [ "${status}" -eq 0 ]
  [ -d "${directory}/nested" ]
  [ -z "$(find "${directory}" -type f)" ]
  run aws-vpn-client::log::files "${BATS_TEST_TMPDIR}/missing"
  [ "${status}" -eq 66 ]
}

@test "Chrome user data export copies each matching profile" {
  CHROME_PROFILE="${BATS_TEST_TMPDIR}/Chrome/Profile 1"
  local destination="${BATS_TEST_TMPDIR}/out"
  mkdir -p "${CHROME_PROFILE}"
  printf '{}' >"${CHROME_PROFILE}/Preferences"
  printf '{"roots":{}}' >"${CHROME_PROFILE}/Bookmarks"
  chrome::profile::find-by-email() { printf '%s\n' "${CHROME_PROFILE}"; }
  run chrome::profile::export-user-data-by-email user@example.invalid "${destination}"
  [ "${status}" -eq 0 ]
  [ "$(<"${destination}/Profile 1_preferences.json")" = '{}' ]
  [ "$(<"${destination}/Profile 1_bookmarks.json")" = '{"roots":{}}' ]
  chrome::profile::find-by-email() { :; }
  run chrome::profile::export-user-data-by-email user@example.invalid "${destination}"
  [ "${status}" -eq 1 ]
}

@test "Command Line Tools upgrade installs the newest offered label" {
  use_platform darwin
  record_root_commands
  softwareupdate() {
    printf '%s\n' 'Software Update Tool' \
      '* Label: Command Line Tools for Xcode-16.2' \
      '* Label: Command Line Tools for Xcode-16.10'
  }
  xcode-select() { :; }
  pkgutil() { :; }
  run xcode::command-line-tools::upgrade
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'softwareupdate --install Command Line Tools for Xcode-16.10' ]

  softwareupdate() { printf 'No new software available.\n'; }
  : >"${ROOT_LOG}"
  run --separate-stderr xcode::command-line-tools::upgrade
  [ "${status}" -eq 0 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "Ubuntu setup stops at the first failed step" {
  use_platform ubuntu 24.04 noble
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  env::dotenv::register() { :; }
  shell::editor::set-default() { return 74; }
  shell::completion::enable-ignore-case() { printf 'unexpected\n'; }
  run --separate-stderr ubuntu::setup
  [ "${status}" -eq 74 ]
  [ -f "${HOME}/.env" ]
  [ -z "${output}" ]
  [[ "${stderr}" == *'shell::editor::set-default'* ]]

  run --separate-stderr ubuntu::setup-desktop-22
  [ "${status}" -eq 69 ]
}

@test "the default ADB device applies to later calls in the same shell" {
  run adb::device::set-default 'bad serial'
  [ "${status}" -eq 64 ]
  adb::device::set-default emulator-5554
  [ "${ANDROID_SERIAL}" = 'emulator-5554' ]
  unset ANDROID_SERIAL
}
