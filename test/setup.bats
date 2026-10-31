#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

# These tests replace only external boundaries: external commands, the
# platform provider, administrator execution, and system file writes.

# @description Select the operating-system provider and release seen by the library.
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

# @description Record administrator commands instead of running them.
record_root_commands() {
  ROOT_LOG="${BATS_TEST_TMPDIR}/root.log"
  : >"${ROOT_LOG}"
  # shellcheck disable=SC2317
  command::run-as-root() { printf '%s\n' "$*" >>"${ROOT_LOG}"; }
}

# @description Redirect system file writes below a temporary root directory.
use_fake_root() {
  FAKE_ROOT="${BATS_TEST_TMPDIR}/root"
  mkdir -p "${FAKE_ROOT}"
  # shellcheck disable=SC2317
  file::write-text() {
    mkdir -p "${FAKE_ROOT}$(dirname "$1")"
    printf '%s' "$2" >"${FAKE_ROOT}$1"
  }
}

# @description Serve downloads with curl: -o writes CURL_BODY, and -I succeeds unless the URL contains CURL_MISSING.
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
  apt-cache() { :; }
  dpkg-query() { return 1; }
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

@test "Docker on Ubuntu keeps docker.io until the replacement can be installed" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-get() { :; }
  use_fake_root
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'arm64\n'; }
  dpkg-query() { [[ "${*: -1}" == docker.io ]] && printf 'install ok installed'; }

  # The requested version is missing, so nothing is removed.
  apt-cache() { return 100; }
  run --separate-stderr docker::install '5:1.0.0-1~ubuntu.24.04~noble'
  [ "${status}" -eq 69 ]
  ! grep -q 'apt-get remove' "${ROOT_LOG}"

  # The installation fails after docker.io was removed, so docker.io returns.
  apt-cache() { :; }
  : >"${ROOT_LOG}"
  command::run-as-root() {
    printf '%s\n' "$*" >>"${ROOT_LOG}"
    [[ "$*" != *'install -y'*docker-ce* ]]
  }
  run docker::install
  [ "${status}" -ne 0 ]
  grep -Fqx 'env DEBIAN_FRONTEND=noninteractive apt-get remove -y docker.io' "${ROOT_LOG}"
  [ "$(tail -n 1 "${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io' ]
  ! grep -q 'systemctl enable' "${ROOT_LOG}"
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
  [ "${status}" -eq 64 ]
  run claude-desktop::install
  [ "${status}" -eq 0 ]
  [ "$(<"${FAKE_ROOT}/etc/apt/sources.list.d/claude-desktop.list")" = 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main' ]
  grep -Eq '^install -m 0644 .*/key\.asc /usr/share/keyrings/claude-desktop-archive-keyring\.asc$' "${ROOT_LOG}"
  [ "$(tail -n 1 "${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y claude-desktop' ]
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

@test "Claude Desktop and the AI command-line and desktop apps use Homebrew casks on macOS" {
  use_platform darwin
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  brew() { printf '%s\n' "$*" >>"${BREW_LOG}"; }
  run claude-desktop::install
  [ "${status}" -eq 0 ]
  run claude-code::install
  [ "${status}" -eq 0 ]
  run codex::install
  [ "${status}" -eq 0 ]
  run chatgpt::install
  [ "${status}" -eq 0 ]
  [ "$(<"${BREW_LOG}")" = $'install --cask claude\ninstall --cask claude-code\ninstall --cask codex\ninstall --cask chatgpt' ]
}

@test "Claude Code installs from Anthropic's signed repository on Ubuntu and Fedora" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-get() { :; }
  use_fake_root
  use_fake_curl
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'arm64\n'; }
  gpg() {
    printf 'pub:-:4096:1:BAA929FF1A7ECACE:1774907248:::-:::scESC::::::23::0:\n'
    printf 'fpr:::::::::%s:\n' "${KEY_FINGERPRINT}"
  }

  KEY_FINGERPRINT='0000000000000000000000000000000000000000'
  run --separate-stderr claude-code::install
  [ "${status}" -eq 65 ]
  [ ! -e "${FAKE_ROOT}/etc/apt/sources.list.d/claude-code.list" ]
  ! grep -q 'claude-code' "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  KEY_FINGERPRINT='31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE'
  run claude-code::install 2.1.287-1
  [ "${status}" -eq 64 ]
  run claude-code::install
  [ "${status}" -eq 0 ]
  [ "$(<"${FAKE_ROOT}/etc/apt/sources.list.d/claude-code.list")" = 'deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main' ]
  grep -Eq '^install -m 0644 .*/claude-code\.asc /etc/apt/keyrings/claude-code\.asc$' "${ROOT_LOG}"
  [ "$(tail -n 1 "${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y claude-code' ]

  use_platform fedora 44
  : >"${ROOT_LOG}"
  dnf() { :; }
  uname() { [[ "$1" == '-m' ]] && printf 'x86_64\n'; }
  run claude-code::install
  [ "${status}" -eq 0 ]
  grep -Fxq 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-claude-code' "${FAKE_ROOT}/etc/yum.repos.d/claude-code.repo"
  grep -Fxq 'baseurl=https://downloads.claude.ai/claude-code/rpm/stable' "${FAKE_ROOT}/etc/yum.repos.d/claude-code.repo"
  grep -Fxq 'gpgcheck=1' "${FAKE_ROOT}/etc/yum.repos.d/claude-code.repo"
  [ "$(tail -n 1 "${ROOT_LOG}")" = 'dnf install -y claude-code' ]

  use_platform ubuntu 18.04 bionic
  : >"${ROOT_LOG}"
  run --separate-stderr claude-code::install
  [ "${status}" -eq 69 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "Codex on Linux runs OpenAI's installer without prompts" {
  use_platform ubuntu 22.04 jammy
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  uname() { [[ "$1" == '-m' ]] && printf '%s\n' "${MACHINE}"; }
  CURL_BODY='printf "%s|%s|%s\n" "${CODEX_NON_INTERACTIVE}" "$#" "${PATH}" >"${HOME}/installer.log"
mkdir -p "${HOME}/.local/bin"
printf "#!/bin/sh\necho codex-cli 0.162.1\n" >"${HOME}/.local/bin/codex"
chmod +x "${HOME}/.local/bin/codex"'
  use_fake_curl

  MACHINE='x86_64'
  run codex::install
  [ "${status}" -eq 0 ]
  [ "${lines[${#lines[@]} - 1]}" = 'codex-cli 0.162.1' ]
  IFS='|' read -r interactive count path <"${HOME}/installer.log"
  [ "${interactive}" = 1 ]
  [ "${count}" = 0 ]
  [[ ":${path}:" == *":${HOME}/.local/bin:"* ]]
  grep -Fq "${HOME}/.local/bin" "${HOME}/.bashrc"

  run codex::install 0.162.1
  [ "${status}" -eq 64 ]
  MACHINE='armv7l'
  rm -f "${HOME}/installer.log"
  run --separate-stderr codex::install
  [ "${status}" -eq 69 ]
  [ ! -e "${HOME}/installer.log" ]
}

@test "ChatGPT installs OpenAI's newest package and refuses unsupported releases" {
  record_root_commands
  apt-get() { :; }
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'amd64\n'; }
  dpkg-deb() { printf 'amd64\n'; }
  use_fake_curl
  CURL_URLS="${BATS_TEST_TMPDIR}/curl-urls.log"
  eval "original_$(declare -f curl)"
  curl() { printf '%s\n' "${@: -1}" >>"${CURL_URLS}"; original_curl "$@"; }

  use_platform ubuntu 22.04 jammy
  run --separate-stderr chatgpt::install
  [ "${status}" -eq 69 ]
  [ ! -s "${ROOT_LOG}" ]

  use_platform ubuntu 24.04 noble
  run chatgpt::install 26.1007.71326
  [ "${status}" -eq 64 ]
  run chatgpt::install
  [ "${status}" -eq 0 ]
  grep -Fxq 'https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb' "${CURL_URLS}"
  [[ "$(tail -n 1 "${ROOT_LOG}")" == 'env DEBIAN_FRONTEND=noninteractive apt-get install -y '*'/package.deb' ]]

  use_platform fedora 44
  : >"${ROOT_LOG}"
  uname() { [[ "$1" == '-m' ]] && printf 'x86_64\n'; }
  dnf() { :; }
  run chatgpt::install
  [ "${status}" -eq 0 ]
  [[ "$(<"${ROOT_LOG}")" == 'dnf install -y '*'/chatgpt.x86_64.rpm' ]]
  grep -Fxq 'https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm' "${CURL_URLS}"

  use_platform fedora 42
  : >"${ROOT_LOG}"
  run --separate-stderr chatgpt::install
  [ "${status}" -eq 69 ]
  [ ! -s "${ROOT_LOG}" ]
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
  apt-cache() { :; }
  dpkg-query() { return 1; }
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
  sysctl() { printf '1\n'; }
  run colima::install
  [ "${status}" -eq 0 ]
  [ "$(<"${COLIMA_LOG}")" = 'start' ]

  # Without Hypervisor.framework the VM cannot boot, so Colima is not started.
  : >"${COLIMA_LOG}"
  sysctl() { printf '0\n'; }
  run --separate-stderr colima::install
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'Hypervisor.framework'* ]]
  [ ! -s "${COLIMA_LOG}" ]
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
  # open runs in the background, so wait briefly for its record.
  for _ in $(seq 50); do [ -s "${OPEN_LOG}" ] && break; sleep 0.1; done
  # An installed application is opened by its path, otherwise by its name.
  if [[ -d '/Applications/Rancher Desktop.app' ]]; then
    [ "$(<"${OPEN_LOG}")" = '/Applications/Rancher Desktop.app' ]
  else
    [ "$(<"${OPEN_LOG}")" = '-a Rancher Desktop' ]
  fi

  # An open that waits for a first-launch confirmation does not block the install.
  open() { sleep 30; }
  SECONDS=0
  run rancher-desktop::install
  [ "${status}" -eq 0 ]
  [ "${SECONDS}" -lt 10 ]
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

@test "Go installs from the Fedora package source and returns to the newest version" {
  use_platform fedora 44
  record_root_commands
  dnf() { :; }
  package::_versions() { printf '1.26.1-1.fc44\n1.26.10-1.fc44\n'; }
  run go::install 1.26.1
  [ "${status}" -eq 0 ]
  # dnf install keeps an installed older golang, so an omitted version names the newest.
  run go::install
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = $'dnf install -y golang-1.26.1\ndnf install -y golang-1.26.10' ]
}

@test "Go on Ubuntu selects a versioned package through /usr/local/bin and removes only its own links" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  package::_install() { printf 'install %s\n' "$*" >>"${ROOT_LOG}"; }
  readlink() { printf '/usr/lib/go-1.25/bin/%s\n' "${1##*/}"; }

  run go::install 1.25
  [ "${status}" -eq 69 ]
  [[ "${output}" == *'golang-1.25 did not install /usr/lib/go-1.25/bin/go.'* ]]

  : >"${ROOT_LOG}"
  run go::install
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = $'install golang\nrm -f -- /usr/local/bin/go\nrm -f -- /usr/local/bin/gofmt' ]

  : >"${ROOT_LOG}"
  readlink() { printf '/opt/custom/bin/%s\n' "${1##*/}"; }
  run go::install
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'install golang' ]
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

# @description Keep GSettings values in files below GSETTINGS_STORE.
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

# @description Write one stored GSettings value.
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

@test "automatic screen lock is disabled for Linux GNOME and macOS users" {
  local operating_system='linux'
  system::operating-system() { printf '%s\n' "${operating_system}"; }
  use_fake_gsettings

  run system::disable-auto-lock
  [ "${status}" -eq 0 ]
  [ "$(gsettings_value org.gnome.desktop.screensaver lock-enabled)" = 'false' ]

  local defaults_log="${BATS_TEST_TMPDIR}/defaults.log"
  defaults() { printf '%s\n' "$*" >>"${defaults_log}"; }
  command::require() { [[ "$1" == gsettings || "$1" == defaults ]]; }
  operating_system='darwin'
  run system::disable-auto-lock
  [ "${status}" -eq 0 ]
  [ "$(<"${defaults_log}")" = 'write com.apple.screensaver askForPassword -bool false' ]

  operating_system='fedora'
  run system::disable-auto-lock
  [ "${status}" -eq 69 ]
  run system::disable-auto-lock unexpected
  [ "${status}" -eq 64 ]
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
  run gpg::key::generate --user-id 'Test User <test@example.invalid>' --expires 1y
  [ "${status}" -eq 0 ]
  grep -Fqx 'Key-Type: eddsa' "${PARAMETERS}"
  grep -Fqx 'Subkey-Curve: cv25519' "${PARAMETERS}"
  grep -Fqx 'Name-Real: Test User' "${PARAMETERS}"
  grep -Fqx 'Name-Email: test@example.invalid' "${PARAMETERS}"
  grep -Fqx 'Expire-Date: 1y' "${PARAMETERS}"
  grep -Fqx '%no-protection' "${PARAMETERS}"

  run gpg::key::generate --user-id 'Test User <test@example.invalid>' --passphrase-fd 3
  [ "${status}" -eq 0 ]
  ! grep -Fq '%no-protection' "${PARAMETERS}"
  [[ "$(<"${PARAMETERS}.args")" == '--batch --pinentry-mode loopback --passphrase-fd 3 --generate-key '* ]]

  run gpg::key::generate --algorithm dsa --user-id 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate --pinentry --passphrase-fd 3 --user-id 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate --user-id 'no email'
  [ "${status}" -eq 64 ]
  # A newline would add a directive such as %no-protection to the parameters.
  rm -f "${PARAMETERS}"
  run gpg::key::generate --user-id $'Test\n%no-protection <test@example.invalid>' --passphrase-fd 3
  [ "${status}" -eq 64 ]
  [ ! -e "${PARAMETERS}" ]
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
  # A catalog that cannot be read is an error, not "no update".
  softwareupdate() { printf 'Cannot reach the catalog.\n'; return 1; }
  run --separate-stderr xcode::command-line-tools::upgrade
  [ "${status}" -eq 74 ]
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
  # ~/.env holds secrets, so a new one is private whatever the umask is.
  case "$(uname -s)" in
    Darwin) [ "$(stat -f '%Lp' "${HOME}/.env")" = 600 ] ;;
    *) [ "$(stat -c '%a' "${HOME}/.env")" = 600 ] ;;
  esac
  [ -z "${output}" ]
  [[ "${stderr}" == *'shell::editor::set-default'* ]]

  run --separate-stderr ubuntu::setup-desktop-22
  [ "${status}" -eq 69 ]
}

@test "Ubuntu setup installs only missing common and external prerequisites" {
  use_platform ubuntu 24.04 noble
  HOME="${BATS_TEST_TMPDIR}/home"
  STEP_LOG="${BATS_TEST_TMPDIR}/steps.log"
  local installed=''
  mkdir -p "${HOME}"
  command::exists() { [[ " ${installed} " == *" $1 "* ]]; }
  setup::_run-step() {
    printf '%s\n' "$*" >>"${STEP_LOG}"
    if [[ "$1" == package::_install ]]; then
      shift
      package::_install "$@"
    fi
  }
  package::_install() {
    printf 'package::_install %s\n' "$*" >>"${STEP_LOG}"
    local package=''
    for package in "$@"; do installed+=" ${package}"; done
  }
  gh::install() {
    printf 'gh::install\n' >>"${STEP_LOG}"
    installed+=' gh'
  }
  git-credential-manager::install() { installed+=' git-credential-manager'; }

  run ubuntu::setup
  [ "${status}" -eq 0 ]
  [ "$(sed -n '1p' "${STEP_LOG}")" = 'package::_install curl git' ]
  [ "$(sed -n '2p' "${STEP_LOG}")" = 'package::_install curl git' ]
  grep -Fqx 'package::_install gnupg' "${STEP_LOG}"
  grep -Fqx 'gh::install' "${STEP_LOG}"
  # Git is configured to use Git Credential Manager, so the setup installs it last.
  [ "$(tail -n 1 "${STEP_LOG}")" = 'git-credential-manager::install' ]
}

@test "Fedora setup installs missing Perl modules and runs the shared steps with Fedora's GnuPG" {
  use_platform fedora 34
  HOME="${BATS_TEST_TMPDIR}/home"
  STEP_LOG="${BATS_TEST_TMPDIR}/steps.log"
  local installed='curl git perl'
  mkdir -p "${HOME}"
  command::exists() { [[ " ${installed} " == *" $1 "* ]]; }
  # Fedora Workstation 34 has POSIX but neither JSON::PP nor Time::HiRes.
  perl() { [[ "$1" == -MPOSIX ]]; }
  setup::_run-step() { printf '%s\n' "$*" >>"${STEP_LOG}"; }
  gh::install() { printf 'gh::install\n' >>"${STEP_LOG}"; }

  run fedora::setup
  [ "${status}" -eq 0 ]
  [ "$(sed -n '1p' "${STEP_LOG}")" = 'package::_install perl-JSON-PP perl-Time-HiRes' ]
  grep -Fqx 'git::config::use-credential-manager' "${STEP_LOG}"
  grep -Fqx 'package::_install gnupg2' "${STEP_LOG}"
  [ "$(sed -n '$p' "${STEP_LOG}")" = 'git-credential-manager::install' ]
  case "$(uname -s)" in
    Darwin) [ "$(stat -f '%Lp' "${HOME}/.env")" = 600 ] ;;
    *) [ "$(stat -c '%a' "${HOME}/.env")" = 600 ] ;;
  esac

  use_platform ubuntu 24.04 noble
  run --separate-stderr fedora::setup
  [ "${status}" -eq 69 ]
  run --separate-stderr fedora::setup-external
  [ "${status}" -eq 69 ]
}

@test "Ubuntu setup installs perl only when its modules are missing" {
  use_platform ubuntu 24.04 noble
  STEP_LOG="${BATS_TEST_TMPDIR}/steps.log"
  command::exists() { :; }
  setup::_run-step() { printf '%s\n' "$*" >>"${STEP_LOG}"; }

  perl() { :; }
  run setup::_install-prerequisites
  [ "${status}" -eq 0 ]
  [ ! -e "${STEP_LOG}" ]

  # perl-base alone, as in a minimal Ubuntu image, lacks JSON::PP and Time::HiRes.
  perl() { return 2; }
  run setup::_install-prerequisites
  [ "${status}" -eq 0 ]
  [ "$(<"${STEP_LOG}")" = 'package::_install perl' ]
}

@test "GitHub CLI repository setup checks both published key fingerprints" {
  use_platform ubuntu 24.04 noble
  record_root_commands
  local gpg_fingerprints='' write_log="${BATS_TEST_TMPDIR}/writes.log"
  package::_download() { printf 'keyring' >"$2"; }
  package::_deb-architecture() { printf 'amd64\n'; }
  package::_refresh() { printf 'refresh\n' >>"${write_log}"; }
  package::_install() { printf 'install %s\n' "$*" >>"${write_log}"; }
  file::write-text() { printf '%s\n%s' "$1" "$2" >"${write_log}.source"; }
  gpg() {
    printf 'pub:u:4096:1:old::::::\nfpr:::::::::%s:\npub:u:4096:1:new::::::\nfpr:::::::::%s:\n' \
      "${gpg_fingerprints%% *}" "${gpg_fingerprints##* }"
  }
  command::require() { [[ "$1" == gpg || "$1" == mktemp ]]; }

  gpg_fingerprints='2C6106201985B60E6C7AC87323F3D4EA75716059 7F38BBB59D064DBCB3D84D725612B36462313325'
  run gh::install
  [ "${status}" -eq 0 ]
  grep -Fqx 'install -d -m 0755 /etc/apt/keyrings' "${ROOT_LOG}"
  [ "$(wc -l <"${ROOT_LOG}")" -eq 2 ]
  grep -F '/etc/apt/keyrings/githubcli-archive-keyring.gpg' "${ROOT_LOG}"
  grep -Fqx 'URIs: https://cli.github.com/packages' "${write_log}.source"
  grep -Fqx 'Architectures: amd64' "${write_log}.source"
  [ "$(<"${write_log}")" = $'refresh\ninstall gh' ]

  : >"${ROOT_LOG}"
  gpg_fingerprints='0000000000000000000000000000000000000000 7F38BBB59D064DBCB3D84D725612B36462313325'
  run gh::_register-repository
  [ "${status}" -eq 65 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "GitHub CLI on Fedora uses the official DNF repository with the checked key" {
  use_platform fedora 44
  record_root_commands
  local write_log="${BATS_TEST_TMPDIR}/writes.log"
  package::_download() { printf '%s\n' "$1" >>"${write_log}.urls"; printf 'key' >"$2"; }
  package::_dnf-register-repository() { printf '%s\n%s' "$1" "$2" >"${write_log}.repo"; }
  package::_install() { printf 'install %s\n' "$*" >>"${write_log}"; }
  gpg() {
    printf 'pub:u:4096:1:old::::::\nfpr:::::::::2C6106201985B60E6C7AC87323F3D4EA75716059:\n'
    printf 'pub:u:4096:1:new::::::\nfpr:::::::::7F38BBB59D064DBCB3D84D725612B36462313325:\n'
  }
  command::require() { [[ "$1" == gpg || "$1" == mktemp ]]; }

  run gh::install
  [ "${status}" -eq 0 ]
  [ "$(<"${write_log}.urls")" = https://cli.github.com/packages/githubcli-archive-keyring.asc ]
  grep -Fqx 'install -d -m 0755 /etc/pki/rpm-gpg' "${ROOT_LOG}"
  grep -Eq '^install -m 0644 .+ /etc/pki/rpm-gpg/RPM-GPG-KEY-gh-cli$' "${ROOT_LOG}"
  [ "$(sed -n 1p "${write_log}.repo")" = gh-cli ]
  grep -Fqx 'baseurl=https://cli.github.com/packages/rpm' "${write_log}.repo"
  grep -Fqx 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-gh-cli' "${write_log}.repo"
  [ "$(<"${write_log}")" = 'install gh' ]
}

@test "VS Code default app skips only extensions without a declared file type" {
  use_platform darwin
  DUTI_LOG="${BATS_TEST_TMPDIR}/duti.log"
  killall() { :; }
  duti() {
    printf '%s\n' "$3" >>"${DUTI_LOG}"
    case "$3" in
      .gitignore) printf 'failed to set %s as handler for dyn.ah62d4qmxhk2x45per7506 (error -50)\n' "$2" >&2; return 1 ;;
      public.javascript) printf '%s does not conform to any UTI hierarchy\n' "$3" >&2; return 1 ;;
      "${DUTI_BROKEN:-}") printf 'failed to set %s as handler for public.json (error -54)\n' "$2" >&2; return 2 ;;
    esac
  }
  run --separate-stderr vscode::set-default-app
  [ "${status}" -eq 0 ]
  [[ "${stderr}" == *'Skipped .gitignore'* ]]
  [[ "${stderr}" == *'Skipped public.javascript'* ]]
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
  HOME="${BATS_TEST_TMPDIR}/home"
  STEP_LOG="${BATS_TEST_TMPDIR}/steps.log"
  mkdir -p "${HOME}"
  setup::_run-step() {
    printf '%s\n' "$*" >>"${STEP_LOG}"
    case "$1" in
      colima::install) return 75 ;;
      docker::install) return 69 ;;
    esac
  }
  run --separate-stderr mac::setup
  [ "${status}" -eq 75 ]
  [ -f "${HOME}/.env" ] && [ -d "${HOME}/.local/bin" ]
  # sudo becomes passwordless before any step that needs it.
  [ "$(head -n 1 "${STEP_LOG}")" = 'sudo::passwordless::enable' ]
  grep -Fqx "shell::editor::set-default code --wait bash,zsh" "${STEP_LOG}"
  grep -Fqx 'mac::dock::set-position' "${STEP_LOG}"
  grep -Fqx 'brew install --cask antigravity-ide' "${STEP_LOG}"
  grep -Fqx 'mac::gatekeeper::disable' "${STEP_LOG}"
  [ "$(tail -n 1 "${STEP_LOG}")" = 'iina::set-default-app' ]
}

@test "macOS preference functions write the expected defaults and restart the Dock" {
  use_platform darwin
  record_root_commands
  command::require() { [ "$1" = 'pmset' ]; }
  DEFAULTS_LOG="${BATS_TEST_TMPDIR}/defaults.log"
  KILLALL_LOG="${BATS_TEST_TMPDIR}/killall.log"
  defaults() { printf '%s\n' "$*" >>"${DEFAULTS_LOG}"; }
  killall() { printf '%s\n' "$*" >>"${KILLALL_LOG}"; }

  run mac::keyboard::use-function-keys
  [ "${status}" -eq 0 ]
  run mac::keyboard::set-repeat
  [ "${status}" -eq 0 ]
  run mac::keyboard::set-repeat 15 2
  [ "${status}" -eq 0 ]
  run mac::keyboard::set-repeat fast
  [ "${status}" -eq 64 ]
  run mac::trackpad::disable-smart-zoom
  [ "${status}" -eq 0 ]
  run mac::dock::set-autohide-instant
  [ "${status}" -eq 0 ]
  run mac::dock::hide-recent-applications
  [ "${status}" -eq 0 ]
  run mac::dock::set-minimize-effect
  [ "${status}" -eq 0 ]
  run mac::dock::set-minimize-effect fade
  [ "${status}" -eq 64 ]
  run mac::dock::set-position bottom
  [ "${status}" -eq 0 ]
  run mac::dock::set-position top
  [ "${status}" -eq 64 ]
  run mac::wake-on-lan::enable
  [ "${status}" -eq 0 ]
  run mac::sleep::disable-automatic
  [ "${status}" -eq 0 ]
  run mac::sleep::enable-automatic
  [ "${status}" -eq 0 ]
  run mac::software-update::enable-automatic-install
  [ "${status}" -eq 0 ]
  run mac::software-update::enable-automatic-install unexpected
  [ "${status}" -eq 64 ]
  run mac::software-update::disable-automatic-install
  [ "${status}" -eq 0 ]
  run mac::software-update::disable-automatic-install unexpected
  [ "${status}" -eq 64 ]

  [ "$(<"${DEFAULTS_LOG}")" = "write NSGlobalDomain com.apple.keyboard.fnState -bool true
write NSGlobalDomain InitialKeyRepeat -int 30
write NSGlobalDomain KeyRepeat -int 1
write NSGlobalDomain InitialKeyRepeat -int 15
write NSGlobalDomain KeyRepeat -int 2
write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 0
write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 0
write NSGlobalDomain com.apple.trackpad.twoFingerDoubleTapGesture -int 0
write com.apple.dock autohide-time-modifier -float 0
write com.apple.dock autohide-delay -float 0
write com.apple.dock show-recents -bool false
write com.apple.dock mineffect -string scale
write com.apple.dock orientation -string bottom" ]
  [ "$(grep -c '^Dock$' "${KILLALL_LOG}")" -eq 4 ]
  [ "$(<"${ROOT_LOG}")" = 'pmset -a womp 1
pmset -a sleep 0
pmset -a sleep 10
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false' ]

  use_platform ubuntu 24.04 noble
  run mac::dock::set-position
  [ "${status}" -eq 69 ]
  run mac::sleep::disable-automatic
  [ "${status}" -eq 69 ]
  run mac::sleep::enable-automatic
  [ "${status}" -eq 69 ]
  run mac::software-update::enable-automatic-install
  [ "${status}" -eq 69 ]
  run mac::software-update::disable-automatic-install
  [ "${status}" -eq 69 ]
}

@test "macOS cleanup functions remove bundled applications and ask before disabling Gatekeeper" {
  use_platform darwin
  record_root_commands
  OPEN_LOG="${BATS_TEST_TMPDIR}/open.log"
  killall() { :; }
  sleep() { :; }
  open() { printf '%s\n' "$*" >>"${OPEN_LOG}"; }

  run mac::applications::remove-bundled
  [ "${status}" -eq 0 ]
  grep -Fq '/Applications/GarageBand.app' "${ROOT_LOG}"
  run mac::quarantine::remove-applications
  [ "${status}" -eq 0 ]
  grep -Fqx 'xattr -r -d com.apple.quarantine /Applications' "${ROOT_LOG}"

  # spctl refuses until the user confirms in System Settings, which is then opened.
  command::run-as-root() { printf '%s\n' "$*" >>"${ROOT_LOG}"; [[ "$1" != spctl ]]; }
  run --separate-stderr mac::gatekeeper::disable
  [ "${status}" -eq 0 ]
  grep -Fqx 'spctl --master-disable' "${ROOT_LOG}"
  [[ "${stderr}" == *'Allow applications from anywhere'* ]]
  [ "$(<"${OPEN_LOG}")" = 'x-apple.systempreferences:com.apple.settings.PrivacySecurity' ]
}

@test "Full Disk Access targets resolve commands, bundles, and Python frameworks" {
  local root=''
  root="$(CDPATH='' cd -P -- "${BATS_TEST_TMPDIR}" && pwd -P)"
  mkdir -p "${root}/bin" "${root}/Tool.app/Contents/MacOS" "${root}/home/Applications/BashstockSample.app" \
    "${root}/Python.framework/Versions/3.12/bin" \
    "${root}/Python.framework/Versions/3.12/Resources/Python.app/Contents/MacOS"
  printf '#!/bin/sh\n' >"${root}/Tool.app/Contents/MacOS/tool"
  printf '#!/bin/sh\n' >"${root}/Python.framework/Versions/3.12/bin/python3.12"
  chmod +x "${root}/Tool.app/Contents/MacOS/tool" "${root}/Python.framework/Versions/3.12/bin/python3.12"
  ln -s ../Tool.app/Contents/MacOS/tool "${root}/bin/tool"
  ln -s ../Python.framework/Versions/3.12/bin/python3.12 "${root}/bin/python3.12"
  PATH="${root}/bin:${PATH}"
  HOME="${root}/home"

  run mac::full-disk-access::target-paths tool
  [ "${status}" -eq 0 ]
  [ "${output}" = "${root}/Tool.app" ]
  run mac::full-disk-access::target-paths python3.12
  [ "${status}" -eq 0 ]
  [ "${output}" = "${root}/Python.framework/Versions/3.12/bin/python3.12
${root}/Python.framework/Versions/3.12/Resources/Python.app" ]
  run mac::full-disk-access::target-paths BashstockSample
  [ "${status}" -eq 0 ]
  [ "${output}" = "${root}/home/Applications/BashstockSample.app" ]

  run mac::full-disk-access::target-paths bashstock-missing-application
  [ "${status}" -eq 1 ]
  run mac::full-disk-access::target-paths "${root}/missing"
  [ "${status}" -eq 66 ]
  run mac::full-disk-access::target-paths ''
  [ "${status}" -eq 64 ]
  run mac::full-disk-access::target-paths tool BashstockSample
  [ "${status}" -eq 64 ]
}

@test "Full Disk Access opens System Settings and reveals ad hoc signed programs" {
  use_platform darwin
  local root=''
  root="$(CDPATH='' cd -P -- "${BATS_TEST_TMPDIR}" && pwd -P)"
  mkdir -p "${root}/Tool.app"
  OPEN_LOG="${BATS_TEST_TMPDIR}/open.log"
  open() { printf '%s\n' "$*" >>"${OPEN_LOG}"; }
  codesign() { printf 'Identifier=tool\nSignature=adhoc\n' >&2; }

  run --separate-stderr mac::full-disk-access::open "${root}/Tool.app"
  [ "${status}" -eq 0 ]
  [ "$(<"${OPEN_LOG}")" = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles
-R ${root}/Tool.app" ]
  [[ "${stderr}" == *"Add to Full Disk Access: ${root}/Tool.app"* ]]
  [[ "${stderr}" == *'Ad hoc signed'* ]]

  # A name that cannot be resolved stops before System Settings opens.
  : >"${OPEN_LOG}"
  run mac::full-disk-access::open "${root}/missing"
  [ "${status}" -eq 66 ]
  [ ! -s "${OPEN_LOG}" ]

  use_platform ubuntu 24.04 noble
  run mac::full-disk-access::open
  [ "${status}" -eq 69 ]
}

@test "Full Disk Access is reported by whether the privacy database opens" {
  use_platform darwin
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}/Library/Application Support/com.apple.TCC"

  run mac::full-disk-access::is-granted
  [ "${status}" -eq 1 ]
  : >"${HOME}/Library/Application Support/com.apple.TCC/TCC.db"
  run mac::full-disk-access::is-granted
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  run mac::full-disk-access::is-granted extra
  [ "${status}" -eq 64 ]

  use_platform ubuntu 24.04 noble
  run mac::full-disk-access::is-granted
  [ "${status}" -eq 69 ]
}

@test "shell startup helpers for Zsh and Homebrew casks write one line each" {
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  shell::zsh::enable-interactive-comments
  shell::zsh::enable-interactive-comments
  homebrew::cask::disable-quarantine
  homebrew::cask::disable-quarantine
  [ "$(grep -c '^setopt interactivecomments$' "${HOME}/.zshrc")" -eq 1 ]
  [ "$(grep -c '^export HOMEBREW_CASK_OPTS=--no-quarantine$' "${HOME}/.zshrc")" -eq 1 ]
  [ "$(grep -c '^export HOMEBREW_CASK_OPTS=--no-quarantine$' "${HOME}/.bashrc")" -eq 1 ]
  [ "${HOMEBREW_CASK_OPTS}" = '--no-quarantine' ]
}

@test "the default ADB device applies to later calls in the same shell" {
  run adb::device::set-default 'bad serial'
  [ "${status}" -eq 64 ]
  adb::device::set-default emulator-5554
  [ "${ANDROID_SERIAL}" = 'emulator-5554' ]
  unset ANDROID_SERIAL
}

# @description Run administrator commands below FAKE_ROOT and record them; sudo reports SUDO_RESULT.
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
  [ "$(<"${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first_-last")" = 'first.last ALL=(ALL) NOPASSWD: ALL' ]
  grep -Eq '^visudo -c -q -f .*/rule$' "${ROOT_LOG}"
  grep -Fqx 'install -m 0440 '"$(sed -n 's/^visudo -c -q -f //p' "${ROOT_LOG}")"' /etc/sudoers.d/zz-bashstock-passwordless-first_-last' "${ROOT_LOG}"
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
  [ -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first_-last" ]

  run sudo::passwordless::enable first_last
  [ "${status}" -eq 0 ]
  [ -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first__last" ]

  run sudo::passwordless::disable first.last
  [ "${status}" -eq 0 ]
  [ ! -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first_-last" ]
  # Another user whose name differs only by . and _ keeps the rule.
  [ -e "${FAKE_ROOT}/etc/sudoers.d/zz-bashstock-passwordless-first__last" ]

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
  CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  curl() {
    local output=''
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -o) output="$2"; shift 2 ;;
        https://*) printf '%s\n' "$1" >>"${CURL_LOG}"; shift ;;
        *) shift ;;
      esac
    done
    if [[ -n "${output}" ]]; then printf 'package' >"${output}"; return; fi
    printf '<a href="get_file.php?file=linux/gmic_4.0.4_ubuntu26-04_resolute_amd64.deb">'
    printf '<a href="get_file.php?file=linux/gmic_4.0.5_ubuntu26-04_resolute_amd64.deb">'
    printf '<a href="get_file.php?file=linux/gmic_4.0.5_gimp3.0_ubuntu26-04_resolute_amd64.zip">'
    printf '<a href="get_file.php?file=linux/gmic_4.0.5_ubuntu24-04_noble_amd64.deb">'
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
  grep -qxF 'https://gmic.eu/get_file.php?file=linux/gmic_4.0.5_ubuntu26-04_resolute_amd64.deb' "${CURL_LOG}"
}

@test "G'MIC official source refuses a CPU without a published package" {
  use_platform ubuntu 26.04 resolute
  record_root_commands
  dpkg() { [[ "$1" == '--print-architecture' ]] && printf 'arm64\n'; }
  curl() { printf '<a href="get_file.php?file=linux/gmic_4.0.5_ubuntu26-04_resolute_amd64.deb">'; }

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

@test "downloads retry network failures but not HTTP errors, and abort stalled transfers" {
  CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  : >"${CURL_LOG}"
  sleep() { :; }
  curl() {
    printf '%s\n' "$*" >>"${CURL_LOG}"
    # The first two attempts drop the connection after part of the body.
    if [[ "$(grep -c . "${CURL_LOG}")" -le 2 ]]; then printf 'partial'; return 92; fi
    printf 'complete'
  }
  run package::_fetch https://example.invalid/index.json
  [ "${status}" -eq 0 ]
  [ "${output}" = 'complete' ]
  [ "$(grep -c . "${CURL_LOG}")" -eq 3 ]
  grep -q -- '--retry 3 --connect-timeout 30 --speed-limit 1024 --speed-time 60' "${CURL_LOG}"

  : >"${CURL_LOG}"
  curl() { printf '%s\n' "$*" >>"${CURL_LOG}"; return 22; }
  run package::_download https://example.invalid/missing "${BATS_TEST_TMPDIR}/missing"
  [ "${status}" -eq 74 ]
  [ "$(grep -c . "${CURL_LOG}")" -eq 1 ]

  : >"${CURL_LOG}"
  curl() { printf '%s\n' "$*" >>"${CURL_LOG}"; return 28; }
  run package::_download https://example.invalid/stalled "${BATS_TEST_TMPDIR}/stalled"
  [ "${status}" -eq 74 ]
  [ "$(grep -c . "${CURL_LOG}")" -eq 3 ]
}

@test "Ruby versions survive pipefail when rbenv lists other implementations last" {
  rbenv_stub="${BATS_TEST_TMPDIR}/bin/rbenv"
  mkdir -p "${rbenv_stub%/*}"
  printf '#!/bin/sh\nprintf "3.3.9\\n3.4.7\\ntruffleruby+graalvm-25.0.0\\n"\n' >"${rbenv_stub}"
  chmod +x "${rbenv_stub}"
  PATH="${rbenv_stub%/*}:${PATH}"
  set -o pipefail
  run ruby::version::latest
  set +o pipefail
  [ "${status}" -eq 0 ]
  [ "${output}" = '3.4.7' ]
}

@test "Chrome profile search succeeds when a profile other than the last one matches" {
  local root="${BATS_TEST_TMPDIR}/Chrome"
  mkdir -p "${root}/Default" "${root}/Profile 1"
  chrome::profile::email() { [[ "$1" == */Default ]] && printf 'user@example.invalid\n'; }
  run chrome::profile::find-by-email user@example.invalid "${root}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${root}/Default" ]
  run chrome::profile::find-by-email other@example.invalid "${root}"
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "rbenv on macOS upgrades only formulae that Homebrew reports as outdated" {
  use_platform darwin
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  brew() {
    printf '%s\n' "$*" >>"${BREW_LOG}"
    if [[ "$1" == outdated ]]; then printf '%s' "${BREW_OUTDATED}"; fi
    # Homebrew fails when it is asked to upgrade a current formula.
    if [[ "$1" == upgrade && " ${BREW_OUTDATED} " != *" $2 "* ]]; then return 1; fi
  }
  BREW_OUTDATED=''
  run ruby::_install-rbenv
  [ "${status}" -eq 0 ]
  ! grep -q '^upgrade' "${BREW_LOG}"

  : >"${BREW_LOG}"
  BREW_OUTDATED='ruby-build'
  run ruby::_install-rbenv
  [ "${status}" -eq 0 ]
  [ "$(grep '^upgrade' "${BREW_LOG}")" = 'upgrade ruby-build' ]
}

@test "Corepack from npm may replace Homebrew's pnpm link only on macOS" {
  NPM_LOG="${BATS_TEST_TMPDIR}/npm.log"
  PATH="${BATS_TEST_TMPDIR}/empty:/usr/bin:/bin"
  npm() { printf '%s\n' "$*" >>"${NPM_LOG}"; }
  corepack() { :; }
  command() { if [[ "$1" == -v && "$2" == corepack ]]; then return 1; fi; builtin command "$@"; }
  command::run-as-root() { "$@"; }
  run node::_enable-corepack darwin os
  [ "${status}" -eq 0 ]
  [ "$(<"${NPM_LOG}")" = 'install --global --force corepack@0.20.0' ]

  : >"${NPM_LOG}"
  run node::_enable-corepack ubuntu os
  [ "${status}" -eq 0 ]
  [ "$(<"${NPM_LOG}")" = 'install --global corepack@0.20.0' ]
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

@test "UTM bundle replacement keeps the old bundle until the copy succeeds" {
  local source="${BATS_TEST_TMPDIR}/mount/UTM.app" applications="${BATS_TEST_TMPDIR}/Applications"
  mkdir -p "${source}/Contents" "${applications}/UTM.app/Contents"
  printf 'new\n' >"${source}/Contents/version"
  printf 'old\n' >"${applications}/UTM.app/Contents/version"

  cp() { return 1; }
  run utm::_copy-application "${source}" "${applications}"
  [ "${status}" -eq 74 ]
  [ "$(<"${applications}/UTM.app/Contents/version")" = old ]
  [ -z "$(find "${applications}" -mindepth 1 -maxdepth 1 -name '.*')" ]

  unset -f cp
  run utm::_copy-application "${source}" "${applications}"
  [ "${status}" -eq 0 ]
  [ "$(<"${applications}/UTM.app/Contents/version")" = new ]
  [ -z "$(find "${applications}" -mindepth 1 -maxdepth 1 -name '.*')" ]
}

@test "official Node.js replaces a version directory left without a working node" {
  export HOME="${BATS_TEST_TMPDIR}/home"
  local destination="${HOME}/.local/lib/node/1.2.3"
  mkdir -p "${destination}/lib" "${BATS_TEST_TMPDIR}/archive/node/bin"
  printf '#!/bin/sh\nprintf "v1.2.3\\n"\n' >"${BATS_TEST_TMPDIR}/archive/node/bin/node"
  printf '#!/bin/sh\nprintf "10.0.0\\n"\n' >"${BATS_TEST_TMPDIR}/archive/node/bin/npm"
  chmod +x "${BATS_TEST_TMPDIR}/archive/node/bin/node" "${BATS_TEST_TMPDIR}/archive/node/bin/npm"
  tar -czf "${BATS_TEST_TMPDIR}/node.tar.gz" -C "${BATS_TEST_TMPDIR}/archive" node
  node::_official-platform() { printf 'linux-x64\n'; }
  package::_download() { cp -- "${BATS_TEST_TMPDIR}/node.tar.gz" "$2"; }

  run node::_install-official 1.2.3
  [ "${status}" -eq 0 ]
  [ -x "${destination}/bin/node" ]
  [ ! -e "${destination}/unpacked" ]
  [ ! -e "${destination}/lib" ]
  [ "$(readlink "${HOME}/.local/lib/node/current")" = "${destination}" ]
}

@test "Thunderbird uses the Homebrew cask on macOS and the system package on Linux" {
  use_platform darwin
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  brew() { printf '%s\n' "$*" >>"${BREW_LOG}"; }
  run thunderbird::install
  [ "${status}" -eq 0 ]
  [ "$(<"${BREW_LOG}")" = 'install --cask thunderbird' ]
  run thunderbird::install current extra
  [ "${status}" -eq 64 ]

  use_platform ubuntu 24.04 noble
  record_root_commands
  apt-get() { :; }
  run thunderbird::install
  [ "${status}" -eq 0 ]
  grep -Eq 'apt-get install -y .*thunderbird$' "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  use_platform fedora 44
  dnf() { :; }
  run thunderbird::install 1:140.0-1.fc44
  [ "${status}" -eq 0 ]
  grep -Fq 'thunderbird-1:140.0-1.fc44' "${ROOT_LOG}"
}
