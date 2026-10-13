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
  [ "$(<"${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades mozc-server=2.28.4715.102+dfsg-2.2~bpo22.04.1' ]

  : >"${ROOT_LOG}"
  run mozc::ibus::install 2.26.4220.100+dfsg-5.2
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades ibus-mozc=2.26.4220.100+dfsg-5.2 mozc-server=2.26.4220.100+dfsg-5.2' ]
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
  systemctl() { :; }
  usermod() { :; }
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
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades docker-ce=5:29.8.1-1~ubuntu.24.04~noble docker-ce-cli=5:29.8.1-1~ubuntu.24.04~noble containerd.io docker-buildx-plugin docker-compose-plugin' "${ROOT_LOG}"
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

@test "Docker installation propagates repository write failures before installing Docker" {
  record_root_commands
  use_fake_curl
  apt-get() { :; }
  dnf() { :; }
  file::write-text() { return 77; }
  dpkg() { printf 'arm64\n'; }
  use_platform ubuntu 18.04 bionic
  run docker::install
  [ "${status}" -eq 77 ]
  ! grep -q 'install -y.*docker-ce' "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  use_platform fedora 34
  run docker::install
  [ "${status}" -eq 77 ]
  ! grep -q '^dnf install ' "${ROOT_LOG}"
}

@test "Claude Desktop installs from Anthropic's repository only with the published signing key" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-get() { :; }
  use_fake_root
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'arm64\n'; }
  gpg() {
    printf 'pub:-:4096:1:BAA929FF1A7ECACE:1774907248:::-:::scESC::::::23::0:\n'
    printf 'fpr:::::::::%s:\n' "${KEY_FINGERPRINT}"
    printf 'sub:-:4096:1:0123456789ABCDEF:1774907248::::::s::::::23:\n'
    printf 'fpr:::::::::0000000000000000000000000123456789ABCDEF:\n'
  }

  KEY_FINGERPRINT='0000000000000000000000000000000000000000'
  run --separate-stderr claude-desktop::install
  [ "${status}" -eq 65 ]
  [ ! -e "${FAKE_ROOT}/etc/apt/sources.list.d/claude-desktop.list" ]
  ! grep -q 'claude-desktop' "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  KEY_FINGERPRINT='31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE'
  run claude-desktop::install 2.31226.1
  [ "${status}" -eq 0 ]
  [ "$(<"${FAKE_ROOT}/etc/apt/sources.list.d/claude-desktop.list")" = 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main' ]
  grep -Eq '^install -m 0644 .*/key\.asc /usr/share/keyrings/claude-desktop-archive-keyring\.asc$' "${ROOT_LOG}"
  [ "$(tail -n 1 "${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades claude-desktop=2.31226.1' ]
}

@test "Claude Desktop changes nothing on unsupported releases and CPUs" {
  record_root_commands
  use_fake_root
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf '%s\n' "${ARCHITECTURE}"; }

  ARCHITECTURE='amd64'
  use_platform ubuntu 20.04 focal
  run --separate-stderr claude-desktop::install
  [ "${status}" -eq 69 ]

  use_platform fedora 44
  run --separate-stderr claude-desktop::install
  [ "${status}" -eq 69 ]

  ARCHITECTURE='armhf'
  use_platform ubuntu 24.04 noble
  run --separate-stderr claude-desktop::install
  [ "${status}" -eq 69 ]

  [ ! -s "${ROOT_LOG}" ]
  [ ! -e "${FAKE_ROOT}/etc/apt/sources.list.d/claude-desktop.list" ]
}

@test "Docker on Fedora accepts the engine epoch without imposing it on the CLI" {
  use_platform fedora 43
  record_root_commands
  use_fake_root
  CURL_BODY=$'[docker-ce-stable]\nname=Docker CE Stable\n'
  use_fake_curl
  dnf() { :; }
  systemctl() { :; }
  usermod() { :; }
  run docker::install '3:29.8.0-1.fc43'
  [ "${status}" -eq 0 ]
  grep -Fqx 'dnf install -y docker-ce-3:29.8.0-1.fc43 docker-ce-cli-29.8.0-1.fc43 containerd.io docker-buildx-plugin docker-compose-plugin' "${ROOT_LOG}"
  grep -Fqx 'systemctl enable --now docker' "${ROOT_LOG}"
  grep -Fqx "usermod -a -G docker $(id -un)" "${ROOT_LOG}"
}

@test "Docker on Fedora removes only legacy packages installed under their own names" {
  use_platform fedora 43
  record_root_commands
  use_fake_root
  CURL_BODY=$'[docker-ce-stable]\nname=Docker CE Stable\n'
  use_fake_curl
  dnf() { :; }
  systemctl() { :; }
  usermod() { :; }
  # docker-ce provides docker-engine; only the legacy docker package is installed by its name.
  rpm() { [[ "$1" == -q && "$2" == docker ]]; }
  run docker::install
  [ "${status}" -eq 0 ]
  grep -Fqx 'dnf remove -y docker' "${ROOT_LOG}"
  [ "$(grep -c '^dnf remove' "${ROOT_LOG}")" -eq 1 ]
}

@test "Docker on Fedora installs the official Buildx plugin when no RPM is available" {
  use_platform fedora 34
  record_root_commands
  use_fake_root
  use_fake_curl
  dnf() {
    if [[ "$1" == 'list' && "$2" == '--available' ]]; then return 1; fi
  }
  uname() { [[ "$1" == '-m' ]] && printf 'aarch64\n'; }
  systemctl() { :; }
  usermod() { :; }
  run docker::install
  [ "${status}" -eq 0 ]
  grep -Fqx 'dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin' "${ROOT_LOG}"
  grep -Fqx 'dnf upgrade -y docker-ce docker-ce-cli containerd.io docker-compose-plugin' "${ROOT_LOG}"
  grep -Eq '^install -m 0755 .*/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx$' "${ROOT_LOG}"
}

@test "VS Code versions on Fedora list only builds for the running CPU" {
  use_platform fedora 44
  uname() { [[ "$1" == '-m' ]] && printf 'aarch64\n'; }
  dnf() {
    [[ " $* " == *' --arch=aarch64,noarch '* ]] || return 1
    printf '1.141.0-1791276900\n'
  }
  run vscode::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = '1.141.0-1791276900' ]
}

@test "Docker versions order epoch releases after legacy releases" {
  use_platform ubuntu 18.04 bionic
  dpkg() { printf 'arm64\n'; }
  CURL_BODY=$'Package: docker-ce\nVersion: 5:24.0.2-1~ubuntu.18.04~bionic\nFilename: newest.deb\n\nPackage: docker-ce\nVersion: 18.06.3~ce~3-0~ubuntu\nFilename: legacy.deb\n\nPackage: docker-ce\nVersion: 5:24.0.1-1~ubuntu.18.04~bionic\nFilename: previous.deb\n'
  use_fake_curl
  run docker::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = $'18.06.3~ce~3-0~ubuntu\n5:24.0.1-1~ubuntu.18.04~bionic\n5:24.0.2-1~ubuntu.18.04~bionic' ]
}

@test "Docker on Fedora upgrades installed packages only when no version is requested" {
  use_platform fedora 43
  record_root_commands
  use_fake_root
  use_fake_curl
  dnf() { :; }
  systemctl() { :; }
  usermod() { :; }
  run docker::install
  [ "${status}" -eq 0 ]
  grep -Fqx 'dnf upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin' "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  run docker::install '3:29.8.0-1.fc43'
  [ "${status}" -eq 0 ]
  ! grep -q '^dnf upgrade ' "${ROOT_LOG}"
}

@test "Docker on Ubuntu permits downgrades only for explicit versions" {
  use_platform ubuntu 22.04 jammy
  record_root_commands
  use_fake_root
  use_fake_curl
  apt-get() { :; }
  systemctl() { :; }
  usermod() { :; }
  dpkg() { printf 'arm64\n'; }
  run docker::install
  [ "${status}" -eq 0 ]
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin' "${ROOT_LOG}"
  ! grep -q -- '--allow-downgrades' "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  run docker::install '5:29.8.0-1~ubuntu.22.04~jammy'
  [ "${status}" -eq 0 ]
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades docker-ce=5:29.8.0-1~ubuntu.22.04~jammy docker-ce-cli=5:29.8.0-1~ubuntu.22.04~jammy containerd.io docker-buildx-plugin docker-compose-plugin' "${ROOT_LOG}"
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

@test "Node.js on Ubuntu lists complete OS versions and rejects unavailable versions" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-cache() {
    printf ' nodejs | 18.19.1+dfsg-6ubuntu5 | http://archive.ubuntu.com noble/universe amd64 Packages\n'
  }
  run node::versions os
  [ "${status}" -eq 0 ]
  [ "${output}" = '18.19.1' ]
  run --separate-stderr node::install 22.0.0 os
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'Node.js 22.0.0 is unavailable from os.'* ]]
  [ ! -s "${ROOT_LOG}" ]
}

@test "Node.js official versions include complete stable releases for the CPU" {
  use_platform ubuntu 18.04 bionic
  CURL_BODY='[{"version":"v16.20.2","files":["linux-arm64"]},{"version":"v18.19.1","files":["linux-x64"]},{"version":"v17.0.0-rc1","files":["linux-arm64"]}]'
  curl() { printf '%s' "$CURL_BODY"; }
  uname() { [[ "$1" == '-m' ]] && printf 'aarch64\n'; }
  run node::versions official
  [ "${status}" -eq 0 ]
  [ "${output}" = '16.20.2' ]
}

@test "Go installs from the Fedora package source" {
  use_platform fedora 44
  record_root_commands
  dnf() { :; }
  run go::install
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'dnf install -y golang' ]
}

@test "Microsoft Edge on Ubuntu installs the newest package the C library can run" {
  use_platform ubuntu 24.04 noble
  CURL_FILE="${BATS_TEST_TMPDIR}/Packages.gz"
  printf '%s\n' \
    'Package: microsoft-edge-stable' 'Version: 153.0.1-1' 'Depends: libc6 (>= 2.17)' 'Filename: pool/main/m/edge_153.0.1-1_amd64.deb' '' \
    'Package: microsoft-edge-stable' 'Version: 154.0.2-1' 'Depends: libc6 (>= 2.17)' 'Filename: pool/main/m/edge_154.0.2-1_amd64.deb' '' \
    'Package: microsoft-edge-stable' 'Version: 155.0.1-1' 'Depends: libc6 (>= 2.42)' 'Filename: pool/main/m/edge_155.0.1-1_amd64.deb' '' \
    'Package: microsoft-edge-beta' 'Version: 156.0.1-1' 'Filename: pool/main/m/beta_156.0.1-1_amd64.deb' |
    gzip -c >"${CURL_FILE}"
  use_fake_curl
  dpkg() {
    case "$1" in
      --print-architecture) printf 'amd64\n' ;;
      --compare-versions) [[ "$(printf '%s\n%s\n' "$2" "$4" | sort -V | tail -n 1)" == "$2" ]] ;;
    esac
  }
  dpkg-query() { printf '2.39-0ubuntu8'; }
  deb::install-from-url() { printf '%s\n' "$*"; }
  run microsoft-edge::versions
  [ "${output}" = $'153.0.1-1\n154.0.2-1' ]
  run microsoft-edge::install
  [ "${status}" -eq 0 ]
  [ "${output}" = 'https://packages.microsoft.com/repos/edge/pool/main/m/edge_154.0.2-1_amd64.deb' ]
  run microsoft-edge::install 153.0.1-1
  [ "${output}" = 'https://packages.microsoft.com/repos/edge/pool/main/m/edge_153.0.1-1_amd64.deb' ]
  run --separate-stderr microsoft-edge::install 155.0.1-1
  [ "${status}" -eq 69 ]
}

@test "Microsoft Edge refuses a CPU without published Linux packages" {
  use_platform fedora 44
  record_root_commands
  uname() { [[ "$1" == '-m' ]] && printf 'aarch64\n'; }
  dnf() { :; }
  run --separate-stderr microsoft-edge::install
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'No Microsoft Edge version can run on this system.'* ]]
  [ ! -s "${ROOT_LOG}" ]
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

@test "Flutter installation preserves existing SDK changes in a retrievable stash" {
  use_platform darwin
  flutter::dependencies::install() { :; }
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  local directory="${BATS_TEST_TMPDIR}/flutter"
  mkdir -p "${directory}"
  printf 'keep' >"${directory}/notes.txt"
  run --separate-stderr flutter::install 3.35.0 "${directory}"
  [ "${status}" -eq 73 ]
  [ "$(<"${directory}/notes.txt")" = 'keep' ]

  rm -rf "${directory}"
  git init -q "${directory}"
  git -C "${directory}" config user.name test
  git -C "${directory}" config user.email test@example.invalid
  mkdir -p "${directory}/bin"
  printf '#!/bin/sh\n' >"${directory}/bin/flutter"
  chmod +x "${directory}/bin/flutter"
  git -C "${directory}" add bin/flutter
  git -C "${directory}" commit -qm initial
  git -C "${directory}" tag 3.35.0
  git clone -q --bare "${directory}" "${BATS_TEST_TMPDIR}/remote.git"
  git -C "${directory}" remote add origin "${BATS_TEST_TMPDIR}/remote.git"
  printf 'change\n' >>"${directory}/bin/flutter"
  printf 'untracked\n' >"${directory}/untracked.txt"
  run flutter::install 3.35.0 "${directory}"
  [ "${status}" -eq 0 ]
  [ -x "${directory}/bin/flutter" ]
  [ ! -e "${directory}/untracked.txt" ]
  [ -n "$(git -C "${directory}" stash list)" ]
}

@test "Flutter dependencies select the C++ development package provided by Ubuntu" {
  use_platform ubuntu 18.04 bionic
  record_root_commands
  apt-get() { :; }
  apt-cache() {
    [[ "$1" == pkgnames ]] || return 1
    printf 'libstdc++-7-dev\nlibstdc++-6-dev\n'
  }
  run flutter::dependencies::install
  [ "${status}" -eq 0 ]
  grep -Fq 'libstdc++-7-dev' "${ROOT_LOG}"
  ! grep -Fq 'libstdc++-12-dev' "${ROOT_LOG}"
}

@test "JDK latest ignores unrelated package names with pipefail enabled" {
  platform::_identifier() { printf 'ubuntu\n'; }
  apt-cache() {
    [[ "$*" == 'pkgnames openjdk-' ]] || return 64
    printf 'openjdk-17-jdk\nopenjdk-21-jdk\nopenjdk-21-source\n'
  }
  set -o pipefail
  run jdk::version::latest
  [ "$status" -eq 0 ]
  [ "$output" = 21 ]
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

@test "VS Code default app skips only extensions without a declared file type" {
  use_platform darwin
  DUTI_LOG="${BATS_TEST_TMPDIR}/duti.log"
  killall() { :; }
  duti() {
    printf '%s\n' "$3" >>"${DUTI_LOG}"
    case "$3" in
      .gitignore) printf 'failed to set %s as handler for dyn.ah62d4qmxhk2x45per7506 (error -50)\n' "$2" >&2; return 1 ;;
      "${DUTI_BROKEN:-}") printf 'failed to set %s as handler for public.json (error -54)\n' "$2" >&2; return 2 ;;
    esac
  }
  run --separate-stderr vscode::set-default-app
  [ "${status}" -eq 0 ]
  [[ "${stderr}" == *'Skipped .gitignore'* ]]
  [ "$(tail -n 1 "${DUTI_LOG}")" = 'public.source-code' ]

  DUTI_BROKEN=.json
  : >"${DUTI_LOG}"
  run --separate-stderr vscode::set-default-app
  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *'public.json (error -54)'* ]]
  [ "$(tail -n 1 "${DUTI_LOG}")" = '.json' ]
}

@test "macOS setup runs every step and returns the first failed status" {
  use_platform darwin
  record_root_commands
  HOME="${BATS_TEST_TMPDIR}/home"
  STEP_LOG="${BATS_TEST_TMPDIR}/steps.log"
  mkdir -p "${HOME}"
  sudo::start-keep-alive() { :; }
  killall() { :; }
  sleep() { :; }
  open() { :; }
  setup::_run-step() {
    printf '%s\n' "$*" >>"${STEP_LOG}"
    case "$1" in
      colima::install) return 75 ;;
      docker::install) return 69 ;;
    esac
  }
  run --separate-stderr mac::setup
  [ "${status}" -eq 75 ]
  [ -f "${HOME}/.env" ] && [ -f "${HOME}/.zshrc" ] && [ -d "${HOME}/.local/bin" ]
  grep -Fqx "shell::editor::set-default code --wait bash,zsh" "${STEP_LOG}"
  grep -Fqx 'brew install --cask antigravity-ide' "${STEP_LOG}"
  [ "$(tail -n 1 "${STEP_LOG}")" = 'iina::set-default-app' ]
  grep -Fqx 'command::run-as-root spctl --master-disable' "${STEP_LOG}"
  grep -Fqx 'xattr -r -d com.apple.quarantine /Applications' "${ROOT_LOG}"
}

@test "the default ADB device applies to later calls in the same shell" {
  run adb::device::set-default 'bad serial'
  [ "${status}" -eq 64 ]
  adb::device::set-default emulator-5554
  [ "${ANDROID_SERIAL}" = 'emulator-5554' ]
  unset ANDROID_SERIAL
}

### Run administrator commands below FAKE_ROOT and record them; sudo reports SUDO_RESULT.
use_fake_sudoers() {
  FAKE_ROOT="${BATS_TEST_TMPDIR}/root"
  ROOT_LOG="${BATS_TEST_TMPDIR}/root.log"
  SUDO_RESULT="${SUDO_RESULT:-0}"
  mkdir -p "${FAKE_ROOT}"
  : >"${ROOT_LOG}"
  user::exists() { [[ "$1" != 'missing' ]]; }
  # shellcheck disable=SC2317
  command::run-as-root() {
    printf '%s\n' "$*" >>"${ROOT_LOG}"
    case "$1" in
      visudo) return 0 ;;
      sudo) return "${SUDO_RESULT}" ;;
      install)
        if [[ "$2" == '-d' ]]; then mkdir -p "${FAKE_ROOT}$5"; else cp -- "$4" "${FAKE_ROOT}$5"; fi
        ;;
      rm) rm -f -- "${FAKE_ROOT}${*: -1}" ;;
    esac
  }
}

@test "passwordless sudo is granted through a checked drop-in file without an editor" {
  use_fake_sudoers
  run sudo::passwordless::enable first.last
  [ "${status}" -eq 0 ]
  [ "$(<"${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first_last")" = 'first.last ALL=(ALL) NOPASSWD: ALL' ]
  grep -Eq '^visudo -c -q -f .*/rule$' "${ROOT_LOG}"
  grep -Fqx 'install -m 0440 '"$(sed -n 's/^visudo -c -q -f //p' "${ROOT_LOG}")"' /etc/sudoers.d/zz-bashstock-passwordless-first_last' "${ROOT_LOG}"
  grep -Fqx 'sudo -n -u first.last -- sudo -n -k true' "${ROOT_LOG}"

  SUDO_USER='invoker'
  run sudo::passwordless::enable
  [ "${status}" -eq 0 ]
  [ "$(<"${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-invoker")" = 'invoker ALL=(ALL) NOPASSWD: ALL' ]
}

@test "passwordless sudo leaves no rule when sudo still asks for a password" {
  SUDO_RESULT=1
  use_fake_sudoers
  run --separate-stderr sudo::passwordless::enable alice
  [ "${status}" -eq 69 ]
  [ ! -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-alice" ]

  : >"${ROOT_LOG}"
  run --separate-stderr sudo::passwordless::enable missing
  [ "${status}" -eq 64 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "passwordless sudo can be revoked again, also when the rule is already gone" {
  use_fake_sudoers
  run sudo::passwordless::enable first.last
  [ "${status}" -eq 0 ]
  [ -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first_last" ]

  run sudo::passwordless::disable first.last
  [ "${status}" -eq 0 ]
  [ ! -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first_last" ]

  run sudo::passwordless::disable first.last
  [ "${status}" -eq 0 ]

  : >"${ROOT_LOG}"
  run sudo::passwordless::disable 'a b'
  [ "${status}" -eq 64 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "Supabase ignores release tags of other components when it selects the newest CLI" {
  use_platform ubuntu 24.04 noble
  curl() {
    printf '%s' '[{"tag_name":"config-v0.10.0","draft":false,"prerelease":false},
      {"tag_name":"v2.119.1","draft":false,"prerelease":false},
      {"tag_name":"v2.118.0","draft":false,"prerelease":false}]'
  }
  run supabase::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = $'2.118.0\n2.119.1' ]
}

@test "VS Code on an old Ubuntu installs the newest build its C library can run" {
  use_platform ubuntu 18.04 bionic
  record_root_commands
  use_fake_root
  apt-get() { :; }
  INDEX="${BATS_TEST_TMPDIR}/Packages"
  printf '%s\n' \
    'Package: code' 'Version: 1.85.2-1705561292' 'Depends: libc6 (>= 2.14), libc6 (>= 2.17), libgtk-3-0' '' \
    'Package: code' 'Version: 1.86.0-1706698139' 'Depends: libc6 (>= 2.17), libc6 (>= 2.28)' '' \
    'Package: code-insiders' 'Version: 1.90.0-1' 'Depends: libc6 (>= 2.14)' >"${INDEX}"
  gzip -c "${INDEX}" >"${INDEX}.gz"
  CURL_FILE="${INDEX}.gz"
  use_fake_curl
  dpkg() {
    case "$1" in
      --print-architecture) printf 'amd64\n' ;;
      # The installed version is at least the requirement when it sorts last.
      --compare-versions) [[ "$(printf '%s\n%s\n' "$2" "$4" | sort -V | tail -n 1)" == "$2" ]] ;;
    esac
  }
  dpkg-query() { printf '2.27-3ubuntu1.6'; }

  run vscode::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = '1.85.2-1705561292' ]

  run vscode::install
  [ "${status}" -eq 0 ]
  [ "$(tail -n 1 "${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades code=1.85.2-1705561292' ]
  # The 1.85 package skips its own repository definition only when vscode.list exists.
  [ -e "${FAKE_ROOT}/etc/apt/sources.list.d/vscode.list" ]
  ! grep -Eq '^[[:space:]]*deb[[:space:]]' "${FAKE_ROOT}/etc/apt/sources.list.d/vscode.list"

  : >"${ROOT_LOG}"
  run --separate-stderr vscode::install 1.86.0-1706698139
  [ "${status}" -eq 69 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "pipx installs from PyPI the newest release the local Python can run" {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  use_platform ubuntu 18.04 bionic
  record_root_commands
  apt-get() { :; }
  apt-cache() { :; }
  PIP_LOG="${BATS_TEST_TMPDIR}/pip.log"
  python3() {
    if [[ "$1" == '-c' ]]; then printf '3.6.9\n'; return; fi
    printf '%s\n' "$*" >>"${PIP_LOG}"
    mkdir -p "${HOME}/.local/bin"
    printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "${5#pipx==}" >"${HOME}/.local/bin/pipx"
    chmod +x "${HOME}/.local/bin/pipx"
  }
  curl() {
    printf '%s' '{"releases":{
      "0.17.0":[{"requires_python":">=3.6","yanked":false}],
      "1.0.0":[{"requires_python":">=3.6","yanked":false}],
      "1.1.0":[{"requires_python":">=3.7","yanked":false}],
      "1.2.0b1":[{"requires_python":">=3.6","yanked":false}],
      "1.0.1":[{"requires_python":">=3.6","yanked":true}]}}'
  }

  run --separate-stderr pipx::install
  [ "${status}" -eq 69 ]
  [ ! -e "${PIP_LOG}" ]

  run pipx::versions official
  [ "${status}" -eq 0 ]
  [ "${output}" = $'0.17.0\n1.0.0' ]

  run pipx::install '' official
  [ "${status}" -eq 0 ]
  [ "$(<"${PIP_LOG}")" = '-m pip install --user pipx==1.0.0' ]
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip python3-venv' "${ROOT_LOG}"

  run --separate-stderr pipx::install 1.1.0 official
  [ "${status}" -eq 69 ]
}

@test "pipx from Ubuntu packages also installs venv for its applications" {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  use_platform ubuntu 20.04 focal
  record_root_commands
  apt-get() { :; }
  apt-cache() {
    [[ "$1" == madison ]] || return 0
    printf ' %s | 0.12.3.1-2ubuntu1 | http://archive.ubuntu.com focal/universe amd64 Packages\n' "$2"
  }
  run pipx::install
  [ "${status}" -eq 0 ]
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv' "${ROOT_LOG}"
}

@test "Ubuntu Server ISOs come from published checksums and never replace a file with a bad download" {
  ISO_BODY='iso image'
  ISO_SUM="$(printf '%s' "${ISO_BODY}" | { sha256sum 2>/dev/null || shasum -a 256; } | cut -d ' ' -f 1)"
  curl() {
    local output='' url='' argument=''
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -o) output="$2"; shift 2 ;;
        *) argument="$1"; shift; [[ "${argument}" != https://* ]] || url="${argument}" ;;
      esac
    done
    case "${url}" in
      */meta-release-lts) printf 'Dist: noble\nVersion: 24.04.5 LTS\n\nDist: jammy\nVersion: 22.04.5 LTS\n' ;;
      https://releases.ubuntu.com/24.04/SHA256SUMS)
        printf '%s *ubuntu-24.04.5-live-server-amd64.iso\n' "${ISO_SUM}"
        printf '%s *ubuntu-24.04.5-desktop-amd64.iso\n' "${ISO_SUM}"
        ;;
      https://releases.ubuntu.com/22.04/SHA256SUMS) return 22 ;;
      https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso) printf '%s' "${ISO_BODY}" >"${output}" ;;
      *) return 22 ;;
    esac
  }
  cd "${BATS_TEST_TMPDIR}"

  run ubuntu::server-iso-versions amd64
  [ "${status}" -eq 0 ]
  [ "${output}" = '24.04.5' ]

  run ubuntu::download-server-iso '' amd64 image.iso
  [ "${status}" -eq 0 ]
  [ "$(<image.iso)" = "${ISO_BODY}" ]

  printf 'previous image' >image.iso
  ISO_BODY='corrupted image'
  run --separate-stderr ubuntu::download-server-iso 24.04.5 amd64 image.iso
  [ "${status}" -eq 65 ]
  [ "$(<image.iso)" = 'previous image' ]
  [ "$(find . -name 'image.iso.*' | wc -l)" -eq 0 ]

  run --separate-stderr ubuntu::download-server-iso 22.04.5 amd64 image.iso
  [ "${status}" -eq 69 ]
}

@test "Git Credential Manager installs the newest release that starts on this system" {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  use_platform ubuntu 20.04 focal
  uname() { printf 'x86_64\n'; }
  ldconfig() { printf '\tlibicuuc.so.66 (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libicuuc.so.66\n'; }
  git() { printf '%s\n' "$*" >>"${BATS_TEST_TMPDIR}/git.log"; }
  ARCHIVES="${BATS_TEST_TMPDIR}/archives"
  mkdir -p "${ARCHIVES}"
  # 3.0.1 stands for a build that needs a newer C library than this system has.
  for release in 2.9.1 3.0.1; do
    mkdir -p "${ARCHIVES}/${release}"
    if [[ "${release}" == 3.0.1 ]]; then
      printf '#!/bin/sh\nexit 1\n' >"${ARCHIVES}/${release}/git-credential-manager"
    else
      printf '#!/bin/sh\n[ "$1" = --version ] && printf "%s+abc\\n" || true\n' "${release}" >"${ARCHIVES}/${release}/git-credential-manager"
    fi
    chmod +x "${ARCHIVES}/${release}/git-credential-manager"
    tar -czf "${ARCHIVES}/gcm-linux-x64-${release}.tar.gz" -C "${ARCHIVES}/${release}" git-credential-manager
  done
  curl() {
    local output='' url='' argument=''
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -o) output="$2"; shift 2 ;;
        *) argument="$1"; shift; [[ "${argument}" != https://* ]] || url="${argument}" ;;
      esac
    done
    case "${url}" in
      https://api.github.com/*) printf '%s' '[{"tag_name":"v3.0.1"},{"tag_name":"v2.9.1"},{"tag_name":"v2.9.0-rc1"}]' ;;
      */download/v*/gcm-linux-x64-*.tar.gz) cp -- "${ARCHIVES}/${url##*/}" "${output}" 2>/dev/null ;;
      *) return 22 ;;
    esac
  }

  run git-credential-manager::install
  [ "${status}" -eq 0 ]
  [ "$("${HOME}/.local/bin/git-credential-manager" --version)" = '2.9.1+abc' ]
  [ ! -e "${HOME}/.local/lib/git-credential-manager/3.0.1" ]

  run --separate-stderr git-credential-manager::install 3.0.1
  [ "${status}" -eq 69 ]
  [ ! -e "${HOME}/.local/lib/git-credential-manager/3.0.1" ]
}

@test "G'MIC uses the official package only when that source is requested" {
  use_platform ubuntu 26.04 resolute
  record_root_commands
  apt-get() { :; }
  apt-cache() { :; }
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'amd64\n'; }
  dpkg-deb() { printf 'amd64\n'; }
  curl() {
    local output=''
    while [[ "$#" -gt 0 ]]; do
      if [[ "$1" == -o ]]; then output="$2"; shift 2; else shift; fi
    done
    if [[ -n "${output}" ]]; then printf 'package' >"${output}"; return; fi
    printf '<a href="gmic_4.0.4_ubuntu26-04_resolute_amd64.deb">'
    printf '<a href="gmic_4.0.5_ubuntu26-04_resolute_amd64.deb">'
    printf '<a href="gmic_4.0.5_ubuntu24-04_noble_amd64.deb">'
  }

  run --separate-stderr gimp::gmic::install
  [ "${status}" -eq 69 ]
  [ ! -s "${ROOT_LOG}" ]

  run gimp::gmic::versions official
  [ "${status}" -eq 0 ]
  [ "${output}" = $'4.0.4\n4.0.5' ]

  run gimp::gmic::install '' official
  [ "${status}" -eq 0 ]
  grep -Eq '^env DEBIAN_FRONTEND=noninteractive apt-get install -y /.*/package\.deb$' "${ROOT_LOG}"
}

@test "G'MIC official source refuses a CPU without a published package" {
  use_platform ubuntu 26.04 resolute
  record_root_commands
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'arm64\n'; }
  curl() { printf '<a href="gmic_4.0.5_ubuntu26-04_resolute_amd64.deb">'; }

  run gimp::gmic::versions official
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]

  run --separate-stderr gimp::gmic::install '' official
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'no package for this Ubuntu release and CPU'* ]]
  [ ! -s "${ROOT_LOG}" ]
}

@test "GitHub API requests carry GITHUB_TOKEN on standard input, never in arguments" {
  use_platform ubuntu 24.04 noble
  CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  curl() {
    printf 'args: %s\n' "$*" >>"${CURL_LOG}"
    if [[ " $* " == *' --config - '* ]]; then printf 'stdin: %s\n' "$(cat)" >>"${CURL_LOG}"; fi
    printf '%s' '[{"tag_name":"v1.2.3"}]'
  }

  GITHUB_TOKEN='secret-token' run supabase::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = '1.2.3' ]
  grep -Fqx 'stdin: header = "Authorization: Bearer secret-token"' "${CURL_LOG}"
  ! grep '^args:' "${CURL_LOG}" | grep -q secret-token

  : >"${CURL_LOG}"
  GITHUB_TOKEN='' run supabase::versions
  [ "${status}" -eq 0 ]
  ! grep -q 'stdin:' "${CURL_LOG}"
}

@test "rbenv startup lines stay valid when the shell is configured again" {
  HOME="${BATS_TEST_TMPDIR}/home"
  unset RBENV_ROOT
  mkdir -p "$HOME/.rbenv/bin"
  ruby::_configure-shell
  ruby::_configure-shell
  [ "$(grep -c 'rbenv/bin' "$HOME/.bashrc")" -eq 1 ]
  [ "$(grep -c 'rbenv init' "$HOME/.bashrc")" -eq 1 ]
  grep -Fqx "export PATH=\"$HOME/.rbenv/bin:\${PATH}\"" "$HOME/.bashrc"
  bash -n "$HOME/.bashrc"
}
