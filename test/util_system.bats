#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

# These tests replace only external boundaries: network commands, the
# operating-system name, and administrator execution.

# @description Record administrator commands instead of running them.
record_root_commands() {
  ROOT_LOG="${BATS_TEST_TMPDIR}/root.log"
  : >"${ROOT_LOG}"
  # shellcheck disable=SC2317
  command__run-as-root() { printf '%s\n' "$*" >>"${ROOT_LOG}"; }
}

@test "ping uses the documented defaults and the reply timeout unit of each OS" {
  ping() { printf '%s\n' "$*"; }
  system__operating-system() { printf 'linux\n'; }
  run net__ping
  [ "$output" = '-c 3 -W 5 google.com' ]
  system__operating-system() { printf 'darwin\n'; }
  run net__ping example.com 1 2
  [ "$output" = '-c 1 -W 2000 example.com' ]
  run net__ping example.com 0
  [ "$status" -eq 64 ]
}

@test "public IP lookup accepts only one address from ifconfig.me" {
  curl() { [[ " $* " == *' https://ifconfig.me '* ]] && printf '203.0.113.7'; }
  run net__ip__public
  [ "$status" -eq 0 ]
  [ "$output" = 203.0.113.7 ]
  curl() { printf '2001:db8::7'; }
  run net__ip__public
  [ "$output" = 2001:db8::7 ]
  curl() { printf '<html>error</html>'; }
  run --separate-stderr net__ip__public
  [ "$status" -eq 74 ]
  curl() { printf '999.1.1.1'; }
  run --separate-stderr net__ip__public
  [ "$status" -eq 74 ]
}

@test "private addresses come only from RFC 1918 and unique local ranges" {
  system__operating-system() { printf 'linux\n'; }
  _net__default-interface() { printf 'eth0\n'; }
  _net__interface-ipv4-cidr() { printf '203.0.113.5/24\n'; }
  ip() {
    case "$2" in
      -4) printf '2: eth0    inet 203.0.113.5/24 scope global eth0\n2: eth0    inet 172.20.1.9/16 scope global eth0\n' ;;
      -6) printf '2: eth0    inet6 fe80::1/64 scope link\n2: eth0    inet6 fda6::5/64 scope global\n2: eth0    inet6 2001:db8::5/64 scope global\n2: eth0    inet6 fd12::5/64 scope global\n' ;;
    esac
  }
  run net__ip__private-v4
  [ "$output" = 172.20.1.9 ]
  run net__ip__private-v6
  [ "$output" = fd12::5 ]
  run net__ip__private-v6 eth0 ''
  [ "$output" = fda6::5 ]
  run net__ip__private-v6 eth0 'fda6,fd12'
  [ "$status" -eq 1 ]
}

@test "unused port is a free TCP port" {
  run net__unused-port
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [ "$output" -gt 0 ] && [ "$output" -lt 65536 ]
}

@test "DNS servers come from systemd-resolved or resolv.conf without duplicates" {
  system__operating-system() { printf 'linux\n'; }
  resolvectl() {
    printf 'Global: 8.8.8.8#dns.google 2001:4860:4860::8888\n'
    printf 'Link 2 (eth0): 192.0.2.53 fe80::1%%eth0 8.8.8.8\n'
    printf 'Link 3 (lo):\n'
  }
  run net__dns__servers
  [ "$status" -eq 0 ]
  [ "$output" = $'8.8.8.8\n2001:4860:4860::8888\n192.0.2.53\nfe80::1' ]
}

@test "DNS servers come from systemd-resolve --status where resolvectl is missing" {
  system__operating-system() { printf 'linux\n'; }
  # Ubuntu 18.04 has systemd 237, which names the command systemd-resolve.
  systemd-resolve() {
    [ "$1" = --status ]
    printf 'Global\n'
    printf '         DNS Servers: 8.8.8.8\n'
    printf '                      2001:4860:4860::8888\n'
    printf '          DNSSEC NTA: 10.in-addr.arpa\n'
    printf '                      local\n'
    printf '\nLink 2 (ens3)\n'
    printf '      Current Scopes: DNS\n'
    printf '         DNS Servers: 192.168.122.1\n'
    printf '          DNS Domain: ~.\n'
  }
  local saved_path="${PATH}"
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  ln -s "$(command -v awk)" "${BATS_TEST_TMPDIR}/bin/awk"
  PATH="${BATS_TEST_TMPDIR}/bin"
  run net__dns__servers
  PATH="${saved_path}"
  [ "$status" -eq 0 ]
  [ "$output" = $'8.8.8.8\n2001:4860:4860::8888\n192.168.122.1' ]
}

@test "swap creation registers the file once and refuses existing paths" {
  system__operating-system() { printf 'linux\n'; }
  record_root_commands
  mkswap() { :; }
  file__append-text() { printf 'append %s %s' "$1" "$2" >>"${ROOT_LOG}"; }
  run mem__swap__create '' "${BATS_TEST_TMPDIR}/swapfile"
  [ "$status" -eq 0 ]
  grep -Fqx "fallocate -l 8589934592 ${BATS_TEST_TMPDIR}/swapfile" "${ROOT_LOG}"
  grep -Fqx "swapon ${BATS_TEST_TMPDIR}/swapfile" "${ROOT_LOG}"
  grep -Fq "append /etc/fstab ${BATS_TEST_TMPDIR}/swapfile none swap sw 0 0" "${ROOT_LOG}"
  : >"${BATS_TEST_TMPDIR}/existing"
  run --separate-stderr mem__swap__create 1048576 "${BATS_TEST_TMPDIR}/existing"
  [ "$status" -eq 73 ]
  run mem__swap__create 1048576 relative
  [ "$status" -eq 64 ]
  run mem__swap__create 1048576 '/swap file'
  [ "${status}" -eq 64 ]
  run mem__swap__create 1048576 '/swap\file'
  [ "${status}" -eq 64 ]
}

@test "screen kill-all succeeds when no Screen process exists" {
  pkill() { :; }
  command__run-as-root() { [[ "$1" == pkill ]] && return 1; }
  run screen__kill-all
  [ "$status" -eq 0 ]
  command__run-as-root() { return 2; }
  run screen__kill-all
  [ "$status" -eq 2 ]
}

@test "process helpers use the first matching process" {
  system__operating-system() { printf 'linux\n'; }
  process__ids-by-name() { printf '41\n42\n'; }
  ps() { printf 'ps %s\n' "$*"; }
  run process__threads-by-name worker
  [ "$output" = 'ps -T -p 41' ]
  gdb() { printf 'gdb %s\n' "$*"; }
  run gdb__attach-by-name worker
  [ "$output" = 'gdb -q -batch -p 41 -ex thread apply all bt' ]
  process__ids-by-name() { return 1; }
  run process__threads-by-name missing
  [ "$status" -eq 1 ]
}

@test "default route helpers read macOS and Linux routing tables" {
  system__operating-system() { printf 'darwin\n'; }
  route() {
    printf '   route to: default\n    gateway: 192.0.2.1\n  interface: en0\n'
  }
  run net__interface__default
  [ "${status}" -eq 0 ]
  [ "${output}" = 'en0' ]
  run net__gateway__default
  [ "${status}" -eq 0 ]
  [ "${output}" = '192.0.2.1' ]

  system__operating-system() { printf 'ubuntu\n'; }
  ip() {
    printf 'default via 198.51.100.1 dev eth1 proto dhcp metric 100\n'
  }
  run net__interface__default
  [ "${output}" = 'eth1' ]
  run net__gateway__default
  [ "${output}" = '198.51.100.1' ]

  ip() { :; }
  run net__interface__default
  [ "${status}" -eq 69 ]
  [ -z "${output}" ]
}

@test "swap size reads the macOS value after the equals sign" {
  system__operating-system() { printf 'darwin\n'; }
  sysctl() {
    printf 'total = 2048.00M  used = 1201.25M  free = 846.75M  (encrypted)\n'
  }
  run mem__swap__total-bytes
  [ "${status}" -eq 0 ]
  [ "${output}" = '2147483648' ]

  sysctl() {
    printf 'total = 0.00M  used = 0.00M  free = 0.00M  (encrypted)\n'
  }
  run mem__swap__total-bytes
  [ "${output}" = '0' ]
}

@test "swap creation removes the file again when a later step fails" {
  system__operating-system() { printf 'linux\n'; }
  record_root_commands
  mkswap() { :; }
  file__append-text() { return 74; }
  run mem__swap__create 1048576 "${BATS_TEST_TMPDIR}/swapfile"
  [ "$status" -eq 74 ]
  grep -Fqx "swapoff ${BATS_TEST_TMPDIR}/swapfile" "${ROOT_LOG}"
  grep -Fqx "rm -f -- ${BATS_TEST_TMPDIR}/swapfile" "${ROOT_LOG}"

  : >"${ROOT_LOG}"
  command__run-as-root() {
    printf '%s\n' "$*" >>"${ROOT_LOG}"
    [[ "$1" != mkswap ]]
  }
  run mem__swap__create 1048576 "${BATS_TEST_TMPDIR}/swapfile"
  [ "$status" -eq 74 ]
  ! grep -q '^swapon\|^swapoff' "${ROOT_LOG}"
  grep -Fqx "rm -f -- ${BATS_TEST_TMPDIR}/swapfile" "${ROOT_LOG}"
}
