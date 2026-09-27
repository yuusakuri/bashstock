#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

### Record administrator commands instead of running them.
record_root_commands() {
  ROOT_LOG="${BATS_TEST_TMPDIR}/root.log"
  : >"${ROOT_LOG}"
  # shellcheck disable=SC2317
  command::run-as-root() { printf '%s\n' "$*" >>"${ROOT_LOG}"; }
}

@test "version helpers sort numerically and drop previews" {
  run package::_sort-stable-versions <<<$'1.10.0\n1.9.2\n2.0.0-rc1\n1.9.10\n1.9.2\n3.0.0-beta\n'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'1.9.2\n1.9.10\n1.10.0' ]

  run package::_latest-stable-version <<<$'5:29.8.0-1~ubuntu.24.04~noble\n5:29.10.1-1~ubuntu.24.04~noble\n'
  [ "${status}" -eq 0 ]
  [ "${output}" = '5:29.10.1-1~ubuntu.24.04~noble' ]

  run package::_latest-stable-version </dev/null
  [ "${status}" -eq 1 ]
}

@test "package installation builds package-manager specific requests" {
  record_root_commands
  command::require() { return 0; }
  package::_platform() { printf 'ubuntu\n'; }
  run package::_install pass 'docker-ce=5:29.8.1-1~ubuntu.24.04~noble'
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y pass docker-ce=5:29.8.1-1~ubuntu.24.04~noble' ]

  : >"${ROOT_LOG}"
  package::_platform() { printf 'fedora\n'; }
  run package::_install-version pass 1.7.4
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'dnf install -y pass-1.7.4' ]

  run package::_install 'bad name'
  [ "${status}" -eq 64 ]
}

@test "Homebrew installation selects versioned formulae only for other versions" {
  BREW_LOG="${BATS_TEST_TMPDIR}/brew.log"
  package::_platform() { printf 'darwin\n'; }
  package::_brew-formula-stable-version() { printf '25.0.1\n'; }
  brew() { printf '%s\n' "$*" >>"${BREW_LOG}"; }
  command::require() { return 0; }
  run package::_install openjdk=21 node=25.0.1
  [ "${status}" -eq 0 ]
  [ "$(<"${BREW_LOG}")" = 'install openjdk@21 node' ]
}

@test "casks accept only the current version" {
  package::_platform() { printf 'darwin\n'; }
  package::_brew-cask-version() { printf '1.2.3\n'; }
  brew() { printf '%s\n' "$*"; }
  command::require() { return 0; }
  run package::_install-cask rancher 1.2.3
  [ "${status}" -eq 0 ]
  [ "${output}" = 'install --cask rancher' ]
  run --separate-stderr package::_install-cask rancher 1.0.0
  [ "${status}" -eq 69 ]
}

@test "platform-specific operations reject other platforms" {
  package::_platform() { printf 'fedora\n'; }
  run deb::install-from-url https://example.invalid/package.deb
  [ "${status}" -eq 69 ]
  run deb::install-from-url http://example.invalid/package.deb
  [ "${status}" -eq 64 ]
  run colima::install
  [ "${status}" -eq 69 ]
  run xcode::command-line-tools::upgrade
  [ "${status}" -eq 69 ]
}

@test "Docker on macOS requires a running container runtime" {
  package::_platform() { printf 'darwin\n'; }
  docker::_container-runtime-is-running() { return 1; }
  run --separate-stderr docker::install
  [ "${status}" -eq 69 ]
  [[ "${stderr}" == *'Colima or Rancher Desktop'* ]]
}

@test "APT candidates are ordered by the version suffix" {
  package::_platform() { printf 'ubuntu\n'; }
  run package::_sort-by-first-field <<<$'12\tgcc-12\t12.4\n9\tgcc-9\t9.5\n13\tgcc-13\t13.3\n'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'gcc-9\t9.5\ngcc-12\t12.4\ngcc-13\t13.3' ]
  apt::package::candidates() { printf 'gcc-9\t9.5\ngcc-12\t12.4\n'; }
  run apt::package::latest gcc-
  [ "${status}" -eq 0 ]
  [ "${output}" = 'gcc-12' ]
}

@test "GVariant string arrays round-trip quotes and commas" {
  run gsettings::_parse-string-array "['a', 'b, c', 'it\\'s', \"d\"]"
  [ "${status}" -eq 0 ]
  [ "${output}" = $'a\nb, c\nit\'s\nd' ]
  run gsettings::_parse-string-array '@as []'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  run gsettings::_parse-string-array "['unterminated]"
  [ "${status}" -eq 65 ]
  run gsettings::_format-string-array <<<$'a\nit\'s'
  [ "${output}" = "['a', 'it\\'s']" ]
}

@test "GSettings string-array helpers add and remove literal values" {
  GSETTINGS_VALUE="${BATS_TEST_TMPDIR}/value"
  printf "%s" "['/a/', '/b/']" >"${GSETTINGS_VALUE}"
  gsettings() {
    case "$1" in
      range) printf 'type as\n' ;;
      get) cat "${GSETTINGS_VALUE}" ;;
      set) printf '%s' "$4" >"${GSETTINGS_VALUE}" ;;
    esac
  }
  command::require() { return 0; }
  run gsettings::string-array::add schema key '/c/'
  [ "${status}" -eq 0 ]
  [ "$(<"${GSETTINGS_VALUE}")" = "['/a/', '/b/', '/c/']" ]
  run gsettings::string-array::add schema key '/a/'
  [ "$(<"${GSETTINGS_VALUE}")" = "['/a/', '/b/', '/c/']" ]
  run gsettings::string-array::remove schema key '/b/'
  [ "${status}" -eq 0 ]
  [ "$(<"${GSETTINGS_VALUE}")" = "['/a/', '/c/']" ]
}

@test "keyboard IME keys validate identifiers and write a managed hwdb entry" {
  record_root_commands
  run keyboard::setup-ime-keys 046d
  [ "${status}" -eq 64 ]
  run keyboard::setup-ime-keys 046d zzzz
  [ "${status}" -eq 64 ]

  HWDB_LOG="${BATS_TEST_TMPDIR}/hwdb"
  system::operating-system() { printf 'linux\n'; }
  command::require() { return 0; }
  file::write-text() { printf '%s' "$2" >"${HWDB_LOG}"; }
  run keyboard::setup-ime-keys 046d c52b
  [ "${status}" -eq 0 ]
  grep -Fqx 'evdev:input:b0003v046DpC52B*' "${HWDB_LOG}"
  grep -Fqx ' KEYBOARD_KEY_7008a=henkan' "${HWDB_LOG}"
  grep -Fqx ' KEYBOARD_KEY_7008b=muhenkan' "${HWDB_LOG}"
  [ "$(<"${ROOT_LOG}")" = $'systemd-hwdb update\nudevadm trigger --subsystem-match=input --action=change' ]
}

@test "input-source shortcuts accept documented options only" {
  run gnome::input-source::set-shortcuts -Unknown value
  [ "${status}" -eq 64 ]
  run gnome::input-source::_set-shortcuts-args
  [ "${output}" = $'-Next\n-Previous\n-Us\n-Mozc' ]
  run gnome::window::set-button-layout 'bad;layout'
  [ "${status}" -eq 64 ]
}

@test "GPG key generation validates options before running gpg" {
  run gpg::key::generate -Algorithm dsa -UserId 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate -Pinentry -PassphraseFd 3 -UserId 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate -Expires never -UserId 'Test <test@example.invalid>'
  [ "${status}" -eq 64 ]
  run gpg::key::generate -UserId 'no email'
  [ "${status}" -eq 64 ]
  run gpg::key::_generate-args -Algorithm
  [ "${output}" = $'ed25519\nrsa3072\nrsa4096' ]
}

@test "GPG key generation writes batch parameters" {
  PARAMETERS="${BATS_TEST_TMPDIR}/parameters"
  command::require() { return 0; }
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
  [[ "$(<"${PARAMETERS}.args")" == '--batch --generate-key '* ]]
}

@test "textproto scalar fields are replaced or appended" {
  local file="${BATS_TEST_TMPDIR}/ibus_config.textproto"
  printf 'active_on_launch: False\nother: 1\n' >"${file}"
  run textproto::set-scalar "${file}" active_on_launch True
  [ "${status}" -eq 0 ]
  run textproto::set-scalar "${file}" new_field 3
  [ "${status}" -eq 0 ]
  [ "$(<"${file}")" = $'active_on_launch: True\nother: 1\nnew_field: 3' ]
  run textproto::set-scalar "${file}" 'bad field' 1
  [ "${status}" -eq 64 ]
}

@test "AWS VPN Client log functions select and remove log files" {
  local directory="${BATS_TEST_TMPDIR}/logs"
  mkdir -p "${directory}/nested"
  : >"${directory}/aws_vpn_client_1.log"
  : >"${directory}/nested/aws_vpn_client_2.log"
  : >"${directory}/ovpn_aws_vpn_client_3.log"
  aws-vpn-client::log::files "${directory}" >"${BATS_TEST_TMPDIR}/files"
  [ "$(tr '\0' '\n' <"${BATS_TEST_TMPDIR}/files" | sort)" = "$(printf '%s\n%s' "${directory}/aws_vpn_client_1.log" "${directory}/nested/aws_vpn_client_2.log")" ]
  run aws-vpn-client::log::open cat "${directory}/missing.log"
  [ "${status}" -eq 66 ]
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

@test "Microsoft Edge artifact URLs come from package metadata" {
  package::_platform() { printf 'ubuntu\n'; }
  microsoft-edge::_index-url() { printf 'https://example.invalid/Packages.gz\n'; }
  package::_deb-index-entries() {
    printf '1.0-1\tpool/main/m/edge_1.0-1_amd64.deb\n2.0-1\tpool/main/m/edge_2.0-1_amd64.deb\n'
  }
  run microsoft-edge::_artifact-url
  [ "${output}" = 'https://packages.microsoft.com/repos/edge/pool/main/m/edge_2.0-1_amd64.deb' ]
  run microsoft-edge::_artifact-url 1.0-1
  [ "${output}" = 'https://packages.microsoft.com/repos/edge/pool/main/m/edge_1.0-1_amd64.deb' ]
  run microsoft-edge::_artifact-url 3.0-1
  [ "${status}" -eq 1 ]
}

@test "Command Line Tools upgrade installs the newest offered label" {
  record_root_commands
  package::_platform() { printf 'darwin\n'; }
  command::require() { return 0; }
  softwareupdate() {
    printf '%s\n' 'Software Update Tool' \
      '* Label: Command Line Tools for Xcode-16.2' \
      '* Label: Command Line Tools for Xcode-16.10'
  }
  xcode-select() { return 0; }
  pkgutil() { return 0; }
  run xcode::command-line-tools::upgrade
  [ "${status}" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'softwareupdate --install Command Line Tools for Xcode-16.10' ]
  softwareupdate() { printf 'No new software available.\n'; }
  : >"${ROOT_LOG}"
  run --separate-stderr xcode::command-line-tools::upgrade
  [ "${status}" -eq 0 ]
  [ ! -s "${ROOT_LOG}" ]
}

@test "Ubuntu 22.04 desktop setup rejects other releases" {
  package::_platform() { printf 'ubuntu\n'; }
  package::_os-release-value() { printf '24.04\n'; }
  run --separate-stderr ubuntu::setup-desktop-22
  [ "${status}" -eq 69 ]
}

@test "setup composites stop at the first failed step" {
  package::_platform() { printf 'ubuntu\n'; }
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
  env::dotenv::register() { return 0; }
  shell::editor::set-default() { return 74; }
  shell::completion::enable-ignore-case() { printf 'unexpected\n'; }
  run --separate-stderr ubuntu::setup
  [ "${status}" -eq 74 ]
  [ -f "${HOME}/.env" ]
  [ -z "${output}" ]
  [[ "${stderr}" == *'shell::editor::set-default'* ]]
}

@test "remaining adopted helpers use their documented forms" {
  local file="${BATS_TEST_TMPDIR}/file"
  : >"${file}"
  run file::modified-time-unix-seconds "${file}"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  run file::modified-time-unix-seconds "${BATS_TEST_TMPDIR}/missing"
  [ "${status}" -eq 66 ]

  run adb::device::set-default 'bad serial'
  [ "${status}" -eq 64 ]
  adb::device::set-default emulator-5554
  [ "${ANDROID_SERIAL}" = 'emulator-5554' ]
  unset ANDROID_SERIAL

  local repository="${BATS_TEST_TMPDIR}/repository"
  git init -q "${repository}"
  run git::stash::list "${repository}"
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
