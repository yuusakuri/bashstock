#!/usr/bin/env bats

load test_helper

@test "IPv4 validation accepts canonical addresses and rejects malformed values" {
  run net::_is-ipv4 0.0.0.0
  [ "${status}" -eq 0 ]
  run net::_is-ipv4 192.168.10.250
  [ "${status}" -eq 0 ]
  run net::_is-ipv4 255.255.255.255
  [ "${status}" -eq 0 ]

  run net::_is-ipv4 192.168.1
  [ "${status}" -eq 1 ]
  run net::_is-ipv4 256.1.1.1
  [ "${status}" -eq 1 ]
  run net::_is-ipv4 01.2.3.4
  [ "${status}" -eq 1 ]
  run net::_is-ipv4 '1.2.3.4; command'
  [ "${status}" -eq 1 ]
}

@test "static IPv4 rendering emits validated Netplan YAML" {
  run net::_render-static-ipv4 \
    enp0s3 192.168.1.20 24 192.168.1.1 1.1.1.1,8.8.8.8 networkd
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(cat <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      dhcp6: false
      addresses: [192.168.1.20/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
EOF
)" ]

  run net::_render-static-ipv4 eth0 192.168.1.20 33 192.168.1.1 1.1.1.1 ''
  [ "${status}" -eq 64 ]
  run net::_render-static-ipv4 'eth0: invalid' 192.168.1.20 24 192.168.1.1 1.1.1.1 ''
  [ "${status}" -eq 64 ]
  run net::_render-static-ipv4 eth0 192.168.1.20 24 192.168.1.1 '1.1.1.1, 8.8.8.8' ''
  [ "${status}" -eq 64 ]
  run net::_render-static-ipv4 eth0 192.168.1.20 24 192.168.1.1 1.1.1.1 invalid
  [ "${status}" -eq 64 ]
}

@test "static IPv4 setup uses explicit values without remote downloads" {
  platform::_identifier() {
    printf 'ubuntu\n'
  }
  command::require() {
    return 0
  }
  netplan() {
    [ "$1" = 'generate' ]
  }
  net::_install-static-ipv4() {
    printf '%s\n' "$2" "$3"
    cat "$1"
  }
  net::_require-netplan-file() {
    return 0
  }

  run net::ip::set-static \
    -Interface enp0s3 \
    -Address 10.0.0.20 \
    -PrefixLength 24 \
    -Gateway 10.0.0.1 \
    -Dns 9.9.9.9,149.112.112.112 \
    -HostName server-1 \
    -File /etc/netplan/50-cloud-init.yaml \
    -Renderer NetworkManager

  [ "${status}" -eq 0 ]
  [[ "${output}" == /etc/netplan/50-cloud-init.yaml$'\n'server-1$'\n'* ]]
  [[ "${output}" == *'renderer: NetworkManager'* ]]
  [[ "${output}" == *'addresses: [10.0.0.20/24]'* ]]
  [[ "${output}" == *'addresses: [9.9.9.9, 149.112.112.112]'* ]]
}

@test "rendered static IPv4 YAML passes Netplan validation when available" {
  command -v netplan >/dev/null 2>&1 || skip 'Netplan is unavailable.'

  local temporary_root=''
  temporary_root="$(mktemp -d "${BATS_TEST_TMPDIR}/netplan.XXXXXX")"
  mkdir -p "${temporary_root}/etc/netplan"
  net::_render-static-ipv4 \
    enp0s3 192.0.2.20 24 192.0.2.1 1.1.1.1,8.8.8.8 '' \
    >"${temporary_root}/etc/netplan/50-bashstock.yaml"

  run netplan generate --root-dir "${temporary_root}"
  [ "${status}" -eq 0 ]
}

@test "static IPv4 setup rejects unsupported systems and invalid options" {
  platform::_identifier() {
    printf 'darwin\n'
  }
  run net::ip::set-static
  [ "${status}" -eq 69 ]

  run net::ip::set-static -Unknown value
  [ "${status}" -eq 64 ]
  run net::ip::set-static -Address
  [ "${status}" -eq 64 ]
}
