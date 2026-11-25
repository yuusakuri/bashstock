#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

# These tests replace only external boundaries: the commands each function
# delegates to, the operating-system name, and administrator execution.

# @description Record administrator commands instead of running them.
record_root_commands() {
  ROOT_LOG="${BATS_TEST_TMPDIR}/root.log"
  : >"${ROOT_LOG}"
  # shellcheck disable=SC2317
  command__run-as-root() { printf '%s\n' "$*" >>"${ROOT_LOG}"; }
}

@test "systemd helpers validate unit names and elevate only state changes" {
  system__operating-system() { printf 'linux\n'; }
  record_root_commands
  systemctl() { printf 'systemctl %s\n' "$*"; }
  run systemd__restart 'nginx.service'
  [ "$status" -eq 0 ]
  [ "$(<"${ROOT_LOG}")" = 'systemctl restart -- nginx.service' ]
  run systemd__restart 'bad unit; rm -rf /'
  [ "$status" -eq 64 ]
  run systemd__file ssh.service
  [ "$output" = 'systemctl show --property=FragmentPath --value -- ssh.service' ]
  run systemd__dependencies ssh.service
  [ "$output" = 'systemctl show --property=After --property=Requires --property=Wants -- ssh.service' ]
  : >"${ROOT_LOG}"
  run jenkins__restart
  [ "$(<"${ROOT_LOG}")" = 'systemctl restart -- jenkins.service' ]
  system__operating-system() { printf 'darwin\n'; }
  run systemd__start ssh.service
  [ "$status" -eq 69 ]
}

@test "GPG fingerprints list primary secret keys and pass uses the first by default" {
  HOME="${BATS_TEST_TMPDIR}/home"
  unset PASSWORD_STORE_DIR
  gpg() {
    printf 'sec:u:255:22:AAAA:1:::::::scESC:\nfpr:::::::::PRIMARY1:\nssb:u:255:18:BBBB:1::::::e:\nfpr:::::::::SUBKEY1:\n'
    printf 'sec:u:255:22:CCCC:1:::::::scESC:\nfpr:::::::::PRIMARY2:\n'
  }
  run gpg__secret-key__fingerprints
  [ "$output" = $'PRIMARY1\nPRIMARY2' ]
  pass() { printf '%s %s\n' "$PASSWORD_STORE_DIR" "$*"; }
  run pass__store__init
  [ "$output" = "$HOME/.password-store init PRIMARY1" ]
  PASSWORD_STORE_DIR="${BATS_TEST_TMPDIR}/store" run pass__store__init KEY
  [ "$output" = "${BATS_TEST_TMPDIR}/store init KEY" ]
  mkdir -p "$HOME/.password-store/site"
  run pass__store__remove
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.password-store" ]
  run pass__store__remove
  [ "$status" -eq 66 ]
}

@test "USB selection picks the only candidate and lists partitions of USB disks" {
  system__operating-system() { printf 'linux\n'; }
  lsblk() {
    case "$*" in
      '-dnpo NAME,TRAN') printf '/dev/sda sata\n/dev/sdb usb\n' ;;
      '-lnpo NAME,TYPE,SIZE,FSTYPE,LABEL /dev/sdb') printf '/dev/sdb disk 16G\n/dev/sdb1 part 16G vfat STICK\n' ;;
      *) return 1 ;;
    esac
  }
  run usb__partition__select
  [ "$status" -eq 0 ]
  [ "$output" = /dev/sdb1 ]
  lsblk() { [[ "$*" == '-dnpo NAME,TRAN' ]] && printf '/dev/sda sata\n'; }
  run usb__partition__select
  [ "$status" -eq 1 ]
}

@test "USB unmount releases every mount point of the device" {
  local device=''
  device="$(find /dev -maxdepth 1 -type b 2>/dev/null | head -n 1)"
  [[ -n "${device}" ]] || skip 'no block device is available'
  local log="${BATS_TEST_TMPDIR}/root.log"
  command__run-as-root() { printf '%s\n' "$*" >>"${log}"; }
  # The first query lists the mounts; after the umount calls none is left.
  findmnt() {
    [[ "$*" == "-n -l -o TARGET --source ${device}" ]] || return 2
    [[ ! -s "${log}" ]] || return 1
    printf '/media/usb\n/mnt/backup copy\n'
  }
  run _usb__unmount "${device}"
  [ "$status" -eq 0 ]
  [ "$(<"${log}")" = $'umount -- /media/usb\numount -- /mnt/backup copy' ]

  # A failed query stops before anything is unmounted.
  : >"${log}"
  findmnt() { return 2; }
  run _usb__unmount "${device}"
  [ "$status" -eq 74 ]
  [ ! -s "${log}" ]

  # A mount that is still listed after umount is reported.
  findmnt() { printf '/media/usb\n'; }
  run _usb__unmount "${device}"
  [ "$status" -eq 74 ]
}

@test "Go versions come from the versioned Ubuntu packages" {
  _package__platform() { printf 'ubuntu\n'; }
  apt-cache() { printf 'golang-1.22\ngolang-1.21-go\ngolang-1.18\ngolang-go\ngolang-1.24\n'; }
  run go__version__list
  [ "$output" = $'1.18\n1.22\n1.24' ]
  run go__version__latest
  [ "$output" = 1.24 ]
}

@test "Docker cleanup removes every container and volume and stops at the first failure" {
  local log="${BATS_TEST_TMPDIR}/docker.log"
  docker() {
    printf '%s\n' "$*" >>"$log"
    case "$*" in
      'ps -aq') printf 'c1\nc2\n' ;;
      'volume ls -q') printf 'v1\n' ;;
    esac
  }
  run docker__remove-all
  [ "$status" -eq 0 ]
  [ "$(<"$log")" = $'ps -aq\nrm --force c1\nrm --force c2\nvolume ls -q\nvolume rm --force v1' ]
  : >"$log"
  docker() { printf '%s\n' "$*" >>"$log"; [[ "$1" != rm ]] || return 3; [[ "$*" != 'ps -aq' ]] || printf 'c1\n'; }
  run docker__remove-all
  [ "$status" -eq 3 ]
  ! grep -q volume "$log"
}

@test "SSH key generation keeps an existing key without a terminal and reads the passphrase from a descriptor" {
  command -v ssh-keygen >/dev/null 2>&1 || skip 'ssh-keygen is not installed'
  local key="${BATS_TEST_TMPDIR}/keys/id_test"
  run ssh__key__generate-ed25519 --output "$key" --comment 'test key'
  [ "$status" -eq 0 ]
  [[ "$output" == ssh-ed25519\ *' test key' ]]
  terminal__is-available() { return 1; }
  run --separate-stderr ssh__key__generate-ed25519 --output "$key"
  [ "$status" -eq 73 ]
  local protected="${BATS_TEST_TMPDIR}/keys/id_protected"
  run ssh__key__generate-ed25519 --output "$protected" --passphrase-fd 3 3<<<'secret phrase'
  [ "$status" -eq 0 ]
  ssh-keygen -y -P 'secret phrase' -f "$protected" >/dev/null
  ! ssh-keygen -y -P '' -f "$protected" >/dev/null 2>&1
  run ssh__key__generate-rsa4096 -Unknown value
  [ "$status" -eq 64 ]
}

@test "SSH key generation leaves nothing behind when ssh-keygen fails" {
  local directory="${BATS_TEST_TMPDIR}/keys"
  ssh-keygen() {
    while [ "$#" -gt 0 ] && [ "$1" != -f ]; do shift; done
    printf 'partial\n' >"$2"
    return 3
  }
  run ssh__key__generate-ed25519 --output "${directory}/id_test"
  [ "${status}" -eq 3 ]
  [ -z "$(ls -A "${directory}")" ]
}

@test "repo, SELinux, and VS Code helpers apply their documented defaults" {
  local work="${BATS_TEST_TMPDIR}/work"
  mkdir -p "$work/Code/User"
  cd "$work"
  repo() { printf 'repo %s\n' "$*"; }
  run repo__sync device/common
  [ "$output" = 'repo sync --force-sync -j 4 device/common' ]
  run repo__write-manifest
  [ "$output" = "repo manifest -r -o $work/./manifest.xml" ]
  run repo__init https://example.invalid/manifest main default.xml "$work/workspace"
  [ "$output" = 'repo init --depth=1 -u https://example.invalid/manifest -b main -m default.xml' ]
  [ -d "$work/workspace" ]
  audit2allow() { sed 's/^/rule: /'; }
  printf 'type=AVC msg=audit: avc: denied { read }\ntype=SYSCALL other\n' >"$work/audit.log"
  run selinux__generate-rule "$work/audit.log"
  [ "$status" -eq 0 ]
  [ "$(<"$work/selinux.txt")" = 'rule: type=AVC msg=audit: avc: denied { read }' ]
  run vscode__remove-user-data "$work/Code"
  [ "$status" -eq 0 ]
  [ ! -e "$work/Code" ]
}

@test "textproto updates only the top-level scalar and refuses ambiguous files" {
  local file="${BATS_TEST_TMPDIR}/config.textproto"
  printf '%s\n' '# mode: comment' 'inner {' '  mode: NESTED' '  label: "brace } in string"' '}' 'mode: OLD # keep' 'other: 1' >"$file"
  run textproto__set-scalar "$file" mode NEW
  [ "$status" -eq 0 ]
  [ "$(<"$file")" = "$(printf '%s\n' '# mode: comment' 'inner {' '  mode: NESTED' '  label: "brace } in string"' '}' 'mode: NEW' 'other: 1')" ]
  run textproto__set-scalar "$file" added 'true'
  [ "$(tail -n 1 "$file")" = 'added: true' ]

  printf 'mode: A\nmode: B\n' >"$file"
  run textproto__set-scalar "$file" mode C
  [ "$status" -eq 65 ]
  [ "$(<"$file")" = $'mode: A\nmode: B' ]
  printf 'mode {\n  value: 1\n}\n' >"$file"
  run textproto__set-scalar "$file" mode C
  [ "$status" -eq 65 ]
  printf 'open {\n' >"$file"
  run textproto__set-scalar "$file" mode C
  [ "$status" -eq 65 ]
}

@test "textproto keeps text that is not ASCII, and bytes that are not UTF-8, in any locale" {
  local file="${BATS_TEST_TMPDIR}/config.textproto" expected="${BATS_TEST_TMPDIR}/expected"
  # Python 3.6 writes ASCII in the C locale; later versions do the same without UTF-8 mode.
  export PYTHONUTF8=0
  printf '# 日本語のコメント\n# \377\nmode: OLD\n' >"$file"
  run textproto__set-scalar "$file" mode NEW
  [ "$status" -eq 0 ]
  printf '# 日本語のコメント\n# \377\nmode: NEW\n' >"$expected"
  cmp "$file" "$expected"

  export LC_ALL=C
  run textproto__set-scalar "$file" label '"値"'
  [ "$status" -eq 0 ]
  printf '# 日本語のコメント\n# \377\nmode: NEW\nlabel: "値"\n' >"$expected"
  cmp "$file" "$expected"
}

@test "file release validates the timeout before signaling holders" {
  local file="${BATS_TEST_TMPDIR}/held"
  : >"${file}"
  lsof() {
    printf 'lsof\n' >>"${BATS_TEST_TMPDIR}/lsof.log"
    return 1
  }
  run file__release "${file}" abc
  [ "${status}" -eq 64 ]
  [ ! -e "${BATS_TEST_TMPDIR}/lsof.log" ]

  run file__release "${file}" 0
  [ "${status}" -eq 0 ]
}

@test "container shell attaches a terminal only for the interactive shell" {
  local log="${BATS_TEST_TMPDIR}/docker.log"
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s"\n' "${log}" >"${BATS_TEST_TMPDIR}/bin/docker"
  chmod +x "${BATS_TEST_TMPDIR}/bin/docker"
  PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
  run docker__container__shell web nginx -t
  [ "${status}" -eq 0 ]
  run docker__container__shell web
  [ "${status}" -eq 0 ]
  [ "$(sed -n 1p "${log}")" = 'exec -i web nginx -t' ]
  [[ "$(sed -n 2p "${log}")" == 'exec -it web sh -c '* ]]
}

@test "serial command writing validates every argument before writing" {
  local device="${BATS_TEST_TMPDIR}/tty"
  : >"${device}"
  run serial__write-command "${device}" RESET cr nope
  [ "${status}" -eq 64 ]
  [ ! -s "${device}" ]
  run serial__write-command "${device}" RESET unknown
  [ "${status}" -eq 64 ]
  [ ! -s "${device}" ]

  run serial__write-command "${device}" AT crlf 0
  [ "${status}" -eq 0 ]
  [ "$(od -An -c "${device}" | tr -d ' ')" = 'AT\r\n' ]
}

@test "SSH key pair replacement keeps both old keys when a move fails" {
  local directory="${BATS_TEST_TMPDIR}/work" key_path="${BATS_TEST_TMPDIR}/id_test"
  mkdir -p "${directory}"
  printf 'old private\n' >"${key_path}"
  printf 'old public\n' >"${key_path}.pub"
  printf 'new private\n' >"${directory}/key"
  printf 'new public\n' >"${directory}/key.pub"
  # Only the move of the new public key fails; restoring the old one works.
  mv() {
    [[ "$*" != *"${directory}/key.pub ${key_path}.pub" ]] || return 1
    command mv "$@"
  }
  run _ssh__key__replace-pair "${directory}" "${key_path}"
  [ "${status}" -eq 74 ]
  [ "$(<"${key_path}")" = 'old private' ]
  [ "$(<"${key_path}.pub")" = 'old public' ]

  unset -f mv
  printf 'new private\n' >"${directory}/key"
  printf 'new public\n' >"${directory}/key.pub"
  run _ssh__key__replace-pair "${directory}" "${key_path}"
  [ "${status}" -eq 0 ]
  [ "$(<"${key_path}")" = 'new private' ]
  [ "$(<"${key_path}.pub")" = 'new public' ]
}

@test "terminal open uses the first available terminal and passes the command as separate arguments" {
  local log="${BATS_TEST_TMPDIR}/terminal.log"
  # shellcheck disable=SC2317
  system__operating-system() { printf 'linux\n'; }
  # shellcheck disable=SC2317
  gnome-terminal() { printf 'gnome-terminal %s\n' "$*" >>"${log}"; }
  # shellcheck disable=SC2317
  xterm() { printf 'xterm %s\n' "$*" >>"${log}"; }
  local saved_path="${PATH}"
  PATH="${BATS_TEST_TMPDIR}/empty"
  run terminal__open
  [ "${status}" -eq 0 ]
  run terminal__open printf '%s\n' 'two words'
  [ "${status}" -eq 0 ]
  PATH="${saved_path}"
  [ "$(sed -n 1p "${log}")" = 'gnome-terminal ' ]
  [ "$(sed -n 2p "${log}")" = 'gnome-terminal -- bash -c "$@"; exec bash -i bash printf %s\n two words' ]
  unset -f gnome-terminal xterm
  PATH="${BATS_TEST_TMPDIR}/empty"
  run terminal__open
  PATH="${saved_path}"
  [ "${status}" -eq 69 ]
}
