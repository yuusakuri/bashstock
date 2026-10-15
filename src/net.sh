#!/usr/bin/env bash
# @file net
# @brief IP address checks and network interface configuration.
# @description Static addresses are written to the Netplan configuration of Ubuntu.

# @description Return success when a value is an IPv4 address.
# @internal
net::_is-ipv4() {
  if [[ "$#" -ne 1 || ! "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi

  local part=''
  local parts=()
  IFS='.' read -r -a parts <<<"$1"
  [[ "${#parts[@]}" -eq 4 ]] || return 1
  for part in "${parts[@]}"; do
    [[ "${part}" =~ ^(0|[1-9][0-9]{0,2})$ ]] || return 1
    ((10#${part} <= 255)) || return 1
  done
}

# @description Return success when a comma-separated value contains IPv4 addresses.
# @internal
net::_is-ipv4-list() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 1
  fi

  local address=''
  local addresses=()
  IFS=',' read -r -a addresses <<<"$1"
  [[ "${#addresses[@]}" -gt 0 ]] || return 1
  for address in "${addresses[@]}"; do
    net::_is-ipv4 "${address}" || return 1
  done
}

# @description Write a Netplan document for one static IPv4 interface.
# @internal
net::_render-static-ipv4() {
  if [[ "$#" -ne 6 ]]; then
    return 64
  fi

  local interface="$1"
  local address="$2"
  local prefix_length="$3"
  local gateway="$4"
  local dns_servers="$5"
  local renderer="$6"
  local dns_yaml=''

  if [[ ! "${interface}" =~ ^[A-Za-z0-9_.-]{1,15}$ ]] ||
    ! net::_is-ipv4 "${address}" ||
    [[ ! "${prefix_length}" =~ ^([0-9]|[12][0-9]|3[0-2])$ ]] ||
    ! net::_is-ipv4 "${gateway}" ||
    ! net::_is-ipv4-list "${dns_servers}" ||
    [[ -n "${renderer}" &&
      "${renderer}" != 'networkd' &&
      "${renderer}" != 'NetworkManager' ]]; then
    return 64
  fi

  dns_yaml="${dns_servers//,/, }"
  printf 'network:\n'
  printf '  version: 2\n'
  if [[ -n "${renderer}" ]]; then
    printf '  renderer: %s\n' "${renderer}"
  fi
  printf '  ethernets:\n'
  printf '    %s:\n' "${interface}"
  printf '      dhcp4: false\n'
  printf '      dhcp6: false\n'
  printf '      addresses: [%s/%s]\n' "${address}" "${prefix_length}"
  printf '      routes:\n'
  printf '        - to: default\n'
  printf '          via: %s\n' "${gateway}"
  printf '      nameservers:\n'
  printf '        addresses: [%s]\n' "${dns_yaml}"
}

# @description Write the first default-route interface.
# @internal
net::_default-interface() {
  ip -o route show to default 2>/dev/null |
    awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }'
}

# @description Write the first default-route gateway.
# @internal
net::_default-gateway() {
  ip -o route show to default 2>/dev/null |
    awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == "via") { print $(i + 1); exit } }'
}

# @description Write the primary global IPv4 address and prefix length for an interface.
# @internal
net::_interface-ipv4-cidr() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  ip -o -4 addr show dev "$1" scope global 2>/dev/null |
    awk 'NR == 1 { print $4; exit }'
}

# @description Write the only Netplan file under /etc/netplan.
# @internal
net::_only-netplan-file() {
  local path=''
  local paths=()
  for path in /etc/netplan/*.yaml; do
    [[ -f "${path}" ]] || continue
    paths+=("${path}")
  done
  [[ "${#paths[@]}" -eq 1 ]] || return 65
  printf '%s\n' "${paths[0]}"
}

# @description Require an existing regular Netplan file directly under /etc/netplan.
# @internal
net::_require-netplan-file() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local file_directory=''
  file_directory="$(dirname -- "$1")" || return 64
  case "$1" in
    /etc/netplan/*.yaml)
      [[ "${file_directory}" == '/etc/netplan' && -f "$1" && ! -L "$1" ]] ||
        return 64
      ;;
    *)
      return 64
      ;;
  esac
}

# @description Install one validated Netplan file, apply it, and set the host name.
# @internal
net::_install-static-ipv4() {
  if [[ "$#" -ne 3 ]]; then
    return 64
  fi

  local candidate="$1"
  local destination="$2"
  local host_name="$3"
  local destination_directory=''
  destination_directory="$(dirname -- "${destination}")" || return 74

  if [[ -w "${destination}" ||
    ( ! -e "${destination}" && -w "${destination_directory}" ) ]]; then
    install -m 600 -- "${candidate}" "${destination}" || return 74
    netplan generate || return 65
    netplan apply || return 75
    hostnamectl set-hostname "${host_name}" || return 75
  else
    command -v sudo >/dev/null 2>&1 || return 77
    sudo install -m 600 -- "${candidate}" "${destination}" || return 77
    sudo netplan generate || return 65
    sudo netplan apply || return 75
    sudo hostnamectl set-hostname "${host_name}" || return 75
  fi
}

# @description List the named arguments and value candidates for net::ip::set-static.
# @internal
net::ip::_set-static-args() {
  case "${1-}" in
    --renderer)
      printf '%s\n' networkd NetworkManager
      ;;
    '')
      printf '%s\n' \
        --interface --address --prefix-length --gateway \
        --dns --host-name --file --renderer
      ;;
  esac
}

# @description Replace one Ubuntu Netplan file with a static IPv4 configuration.
#
# Values that are not given come from the current configuration. The new file
# is generated and checked in a temporary root before it replaces the old one,
# and the host name is set as well.
#
# @option --interface <INTERFACE> Network interface. Defaults to the first default route.
# @option --address <ADDRESS> IPv4 address. Defaults to the interface's primary address.
# @option --prefix-length <PREFIX_LENGTH> IPv4 prefix length. Defaults to the current value.
# @option --gateway <GATEWAY> IPv4 gateway. Defaults to the first default route.
# @option --dns <DNS_SERVERS> Comma-separated IPv4 DNS servers. Defaults to 1.1.1.1,8.8.8.8.
# @option --host-name <HOST_NAME> Host name. Defaults to the current host name.
# @option --file <FILE> Netplan file. Defaults to the only /etc/netplan YAML file.
# @option --renderer <RENDERER> networkd or NetworkManager. Defaults to Netplan's selection.
# @exitcode 0 The configuration was applied.
# @exitcode 64 An option or value is invalid.
# @exitcode 65 Netplan rejected the generated configuration.
# @exitcode 69 The system is not Ubuntu, a required command is missing, or a default cannot be found.
# @exitcode 74 A temporary file could not be written.
# @exitcode other The status of netplan or hostnamectl.
# @example
#   net::ip::set-static --interface eth0 --address 192.168.1.20 --prefix-length 24 \
#     --gateway 192.168.1.1 --dns 192.168.1.1,1.1.1.1
net::ip::set-static() {
  local interface=''
  local address=''
  local prefix_length=''
  local gateway=''
  local dns_servers='1.1.1.1,8.8.8.8'
  local host_name=''
  local file=''
  local renderer=''
  local cidr=''
  local temporary_root=''
  local candidate=''
  local status=''

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --interface|--address|--prefix-length|--gateway|--dns|--host-name|--file|--renderer)
        arg::require-next "$#" "$1" || return "$?"
        case "$1" in
          --interface) interface="$2" ;;
          --address) address="$2" ;;
          --prefix-length) prefix_length="$2" ;;
          --gateway) gateway="$2" ;;
          --dns) dns_servers="$2" ;;
          --host-name) host_name="$2" ;;
          --file) file="$2" ;;
          --renderer) renderer="$2" ;;
        esac
        shift 2
        ;;
      *)
        arg::unknown "$1" || return "$?"
        ;;
    esac
  done

  [[ "$(platform::_identifier)" == 'ubuntu' ]] || return 69
  local required_command=''
  for required_command in ip awk netplan hostname hostnamectl mktemp mkdir install dirname basename rm; do
    command::require "${required_command}" || return "$?"
  done

  interface="${interface:-$(net::_default-interface)}" || return 69
  gateway="${gateway:-$(net::_default-gateway)}" || return 69
  host_name="${host_name:-$(hostname 2>/dev/null)}" || return 69
  file="${file:-$(net::_only-netplan-file)}" || return "$?"
  net::_require-netplan-file "${file}" || return "$?"

  if [[ -z "${address}" || -z "${prefix_length}" ]]; then
    cidr="$(net::_interface-ipv4-cidr "${interface}")" || return 69
    [[ "${cidr}" == */* ]] || return 69
    [[ -n "${address}" ]] || address="${cidr%/*}"
    [[ -n "${prefix_length}" ]] || prefix_length="${cidr##*/}"
  fi
  if [[ ! "${host_name}" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$ ]]; then
    return 64
  fi

  temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/bashstock-netplan.XXXXXX")" || return 74
  mkdir -p -- "${temporary_root}/etc/netplan" || {
    rm -rf -- "${temporary_root}"
    return 74
  }
  candidate="${temporary_root}/etc/netplan/$(basename -- "${file}")"
  if ! net::_render-static-ipv4 "${interface}" "${address}" "${prefix_length}" \
    "${gateway}" "${dns_servers}" "${renderer}" >"${candidate}"; then
    rm -rf -- "${temporary_root}"
    return 64
  fi
  if ! netplan generate --root-dir "${temporary_root}"; then
    rm -rf -- "${temporary_root}"
    return 65
  fi
  net::_install-static-ipv4 "${candidate}" "${file}" "${host_name}"
  status="$?"
  if [[ "${status}" -ne 0 ]]; then
    rm -rf -- "${temporary_root}"
    return "${status}"
  fi
  rm -rf -- "${temporary_root}"
}
