#!/usr/bin/env bash
# @file net
# @brief IP addresses, DNS, routes, and connectivity checks.
# @description Static addresses are written to the Netplan configuration of Ubuntu.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Return success when a value is an IPv4 address.
# @internal
net::_is-ipv4() {
  if ( [[ "$#" -ne 1 || ! "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] ); then
    return 1
  fi

  local part=''
  local parts=()
  IFS='.' read -r -a parts <<<"$1"
  [[ "${#parts[@]}" -eq 4 ]] || return 1
  for part in "${parts[@]}"; do
    ( [[ "${part}" =~ ^(0|[1-9][0-9]{0,2})$ ]] ) || return 1
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

  if ( [[ ! "${interface}" =~ ^[A-Za-z0-9_.-]{1,15}$ ]] ) ||
    ! net::_is-ipv4 "${address}" ||
    ( [[ ! "${prefix_length}" =~ ^([0-9]|[12][0-9]|3[0-2])$ ]] ) ||
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

# @description Write one field of the first default route.
#
# macOS reads route -n get default, and other systems read ip route.
# The status is 69 when the routing tool is missing or there is no default route.
#
# @internal
net::_default-route-field() {
  [[ "$#" -eq 2 ]] || return 64
  local value=''
  if [[ "$(system::operating-system)" == darwin ]]; then
    command -v route >/dev/null 2>&1 || return 69
    value="$(route -n get default 2>/dev/null |
      awk -v key="$1:" '$1 == key { print $2; exit }')"
  else
    command -v ip >/dev/null 2>&1 || return 69
    value="$(ip -o route show to default 2>/dev/null |
      awk -v key="$2" 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == key) { print $(i + 1); exit } }')"
  fi
  [[ -n "${value}" ]] || return 69
  printf '%s\n' "${value}"
}

# @description Write the first default-route interface.
# @internal
net::_default-interface() {
  net::_default-route-field interface dev
}

# @description Write the first default-route gateway.
# @internal
net::_default-gateway() {
  net::_default-route-field gateway via
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

# @description Write the only Netplan file in a directory such as /etc/netplan.
#
# NetworkManager on Ubuntu 23.10 and later writes its own 90-NM-*.yaml files
# there, so a desktop often has several files and the caller must choose one.
# @internal
# @arg $1 string Directory to search.
# @exitcode 69 The directory holds no Netplan file or several of them.
net::_only-netplan-file() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local directory="$1" path=''
  local paths=()
  for path in "${directory}"/*.yaml; do
    [[ -f "${path}" ]] || continue
    paths+=("${path}")
  done
  if [[ "${#paths[@]}" -eq 0 ]]; then
    console::_write-error "No Netplan file exists in ${directory}; pass --file."
    return 69
  fi
  if [[ "${#paths[@]}" -gt 1 ]]; then
    console::_write-error "Several Netplan files exist in ${directory}; pass --file with the one to replace."
    return 69
  fi
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
#
# The previous file is restored and applied again when Netplan rejects the new one.
#
# @internal
net::_install-static-ipv4() {
  if [[ "$#" -ne 3 ]]; then
    return 64
  fi

  local candidate="$1"
  local destination="$2"
  local host_name="$3"
  local backup="${candidate}.previous"
  local write_status=74
  local status=0
  local runner=()

  if [[ ! -w "${destination}" ]]; then
    command -v sudo >/dev/null 2>&1 || return 77
    runner=(sudo)
    write_status=77
  fi
  ${runner[@]+"${runner[@]}"} cp -p -- "${destination}" "${backup}" ||
    return "${write_status}"
  ${runner[@]+"${runner[@]}"} install -m 600 -- "${candidate}" "${destination}" ||
    return "${write_status}"
  ${runner[@]+"${runner[@]}"} netplan generate || status=65
  if [[ "${status}" -eq 0 ]]; then
    ${runner[@]+"${runner[@]}"} netplan apply || status=75
  fi
  if [[ "${status}" -ne 0 ]]; then
    ${runner[@]+"${runner[@]}"} cp -p -- "${backup}" "${destination}" &&
      ${runner[@]+"${runner[@]}"} netplan generate &&
      ${runner[@]+"${runner[@]}"} netplan apply
    return "${status}"
  fi
  ${runner[@]+"${runner[@]}"} hostnamectl set-hostname "${host_name}" || return 75
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
# and the host name is set as well. When Netplan rejects or cannot apply the new
# file, the previous file is restored and applied again.
#
# @option --interface <INTERFACE> Network interface. Defaults to the first default route.
# @option --address <ADDRESS> IPv4 address. Defaults to the interface's primary address.
# @option --prefix-length <PREFIX_LENGTH> IPv4 prefix length. Defaults to the current value.
# @option --gateway <GATEWAY> IPv4 gateway. Defaults to the first default route.
# @option --dns <DNS_SERVERS> Comma-separated IPv4 DNS servers. Defaults to 1.1.1.1,8.8.8.8.
# @option --host-name <HOST_NAME> Host name. Defaults to the current host name.
# @option --file <FILE> Netplan file. Defaults to the only /etc/netplan YAML file; pass it when NetworkManager has written its own files there.
# @option --renderer <RENDERER> networkd or NetworkManager. Defaults to Netplan's selection.
# @exitcode 0 The configuration was applied.
# @exitcode 64 An option or value is invalid.
# @exitcode 65 Netplan rejected the generated configuration.
# @exitcode 69 The system is not Ubuntu, a required command is missing, or a default cannot be found, such as the Netplan file when /etc/netplan holds several.
# @exitcode 74 A temporary file or the Netplan file could not be written.
# @exitcode 75 Netplan could not apply the configuration, so the previous file was restored, or the host name could not be set.
# @exitcode 77 sudo is unavailable or refused the credentials.
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
  for required_command in ip awk netplan hostname hostnamectl mktemp mkdir install cp dirname basename rm; do
    command::require "${required_command}" || return "$?"
  done

  interface="${interface:-$(net::_default-interface)}" || return 69
  gateway="${gateway:-$(net::_default-gateway)}" || return 69
  host_name="${host_name:-$(hostname 2>/dev/null)}" || return 69
  file="${file:-$(net::_only-netplan-file /etc/netplan)}" || return "$?"
  net::_require-netplan-file "${file}" || return "$?"

  if [[ -z "${address}" || -z "${prefix_length}" ]]; then
    cidr="$(net::_interface-ipv4-cidr "${interface}")" || return 69
    [[ "${cidr}" == */* ]] || return 69
    [[ -n "${address}" ]] || address="${cidr%/*}"
    [[ -n "${prefix_length}" ]] || prefix_length="${cidr##*/}"
  fi
  if ( [[ ! "${host_name}" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$ ]] ); then
    return 64
  fi

  temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/bashstock-netplan.XXXXXX")" || return 74
  mkdir -p -- "${temporary_root}/etc/netplan" || {
    rm -rf -- "${temporary_root}"
    return 74
  }
  candidate="${temporary_root}/etc/netplan/$(basename -- "${file}")"
  # Netplan warns about a file that others can read, so the candidate is private like the installed file.
  if ! (umask 077 && net::_render-static-ipv4 "${interface}" "${address}" "${prefix_length}" \
    "${gateway}" "${dns_servers}" "${renderer}" >"${candidate}"); then
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

# @description Write the first default-route interface.
#
# @noargs
# @stdout The interface name, such as eth0 or en0.
# @exitcode 0 The name was written.
# @exitcode 64 An argument was given.
# @exitcode 69 No default route exists, or the routing tool is unavailable.
# @example
#   net::ip::private-v4 "$(net::interface::default)"
net::interface::default() { [[ "$#" -eq 0 ]] || return 64; net::_default-interface; }

# @description Write the first default-route gateway.
#
# @noargs
# @stdout The gateway address.
# @exitcode 0 The address was written.
# @exitcode 64 An argument was given.
# @exitcode 69 No default route exists, or the routing tool is unavailable.
# @example
#   net::ping "$(net::gateway::default)"
net::gateway::default() { [[ "$#" -eq 0 ]] || return 64; net::_default-gateway; }

# @description Write the primary RFC 1918 IPv4 address of an interface.
#
# @arg $1 string INTERFACE Interface name. Defaults to the interface of the default route.
# @stdout The address without a prefix length, such as 192.168.1.20.
# @exitcode 0 The address was written.
# @exitcode 1 The interface has no private IPv4 address.
# @exitcode 64 More than one argument was given.
# @exitcode 69 No interface was given and there is no default route, or the address tool is unavailable.
# @example
#   net::ip::private-v4 eth0
net::ip::private-v4() {
  [[ "$#" -le 1 ]] || return 64
  local interface="${1:-}" address='' candidate='' cidr=''
  if [[ -z "${interface}" ]]; then
    interface="$(net::_default-interface)" || return "$?"
  fi
  while IFS= read -r candidate; do
    case "${candidate}" in
      10.* | 192.168.* | 172.1[6-9].* | 172.2[0-9].* | 172.3[01].*)
        address="${candidate}"
        break
        ;;
    esac
  done < <(
    if [[ "$(system::operating-system)" == darwin ]]; then
      ifconfig "${interface}" 2>/dev/null | awk '$1 == "inet" {print $2}'
    else
      cidr="$(net::_interface-ipv4-cidr "${interface}" 2>/dev/null)" && printf '%s\n' "${cidr%/*}"
      ip -o -4 addr show dev "${interface}" 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4}'
    fi
  )
  [[ -n "${address}" ]] || return 1
  printf '%s\n' "${address}"
}

# @description Write the primary unique local IPv6 address of an interface.
#
# Only addresses in fc00::/7 are considered, in the order the operating
# system lists them, after removing the excluded prefixes.
#
# @arg $1 string INTERFACE Interface name. Defaults to the interface of the default route.
# @arg $2 string EXCLUDED_PREFIXES Comma-separated address prefixes to skip. Defaults to fe80,fda6: link-local addresses and the auxiliary ULA of the reference network.
# @stdout The address without a prefix length.
# @exitcode 0 The address was written.
# @exitcode 1 No address remains after the exclusions.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 No interface was given and there is no default route, or the address tool is unavailable.
# @example
#   net::ip::private-v6 en0 fe80
net::ip::private-v6() {
  [[ "$#" -le 2 ]] || return 64
  local interface="${1:-}" excluded="${2-fe80,fda6}" candidate='' prefix='' skip='' lower=''
  local prefixes=()
  if [[ -z "${interface}" ]]; then
    interface="$(net::_default-interface)" || return "$?"
  fi
  IFS=',' read -r -a prefixes <<<"${excluded}"
  while IFS= read -r candidate; do
    candidate="${candidate%%%*}"
    lower="$(string::lower "${candidate}")" || return "$?"
    [[ "${lower}" == fc* || "${lower}" == fd* ]] || continue
    skip=0
    for prefix in "${prefixes[@]}"; do
      [[ -n "${prefix}" && "${lower}" == "$(string::lower "${prefix}")"* ]] && skip=1
    done
    [[ "${skip}" -eq 0 ]] || continue
    printf '%s\n' "${candidate}"
    return 0
  done < <(
    if [[ "$(system::operating-system)" == darwin ]]; then
      ifconfig "${interface}" 2>/dev/null | awk '$1 == "inet6" {print $2}'
    else
      ip -o -6 addr show dev "${interface}" 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4}'
    fi
  )
  return 1
}

# @description Write the public IP address reported by ifconfig.me.
#
# curl is preferred and wget is used when curl is missing. The response
# must be one IPv4 or IPv6 address; anything else returns 74.
#
# @noargs
# @stdout One IPv4 or IPv6 address.
# @stderr A message when neither curl nor wget is available.
# @exitcode 0 The address was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Neither curl nor wget is available.
# @exitcode 74 The request failed or the response is not an address.
# @example
#   net::ip::public
net::ip::public() {
  [[ "$#" -eq 0 ]] || return 64
  local address=''
  if command -v curl >/dev/null 2>&1; then
    address="$(curl -fsS --max-time 10 https://ifconfig.me)" || return 74
  elif command -v wget >/dev/null 2>&1; then
    address="$(wget -qO- --timeout=10 https://ifconfig.me)" || return 74
  else
    console::_write-error 'curl or wget is required.'
    return 69
  fi
  if ! net::_is-ip-address "${address}"; then
    console::_write-error 'ifconfig.me did not return an IP address.'
    return 74
  fi
  printf '%s\n' "${address}"
}

# @description Test whether a DNS name resolves.
#
# @arg $1 string Host name to resolve.
# @exitcode 0 The name resolves.
# @exitcode 1 The name does not resolve.
# @exitcode 64 The name is empty, or the argument count is not one.
# @exitcode 69 Neither getent nor dscacheutil is available.
# @example
#   net::dns::test github.com || net::dns::use-google
net::dns::test() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  if command -v getent >/dev/null 2>&1; then
    getent ahosts "$1" >/dev/null 2>&1
    return
  fi
  command -v dscacheutil >/dev/null 2>&1 || return 69
  dscacheutil -q host -a name "$1" >/dev/null 2>&1
}

# @description Send ICMP echo requests to a host.
#
# @arg $1 string Optional host name or address. Defaults to google.com.
# @arg $2 integer Optional number of requests. Defaults to 3.
# @arg $3 integer Optional seconds to wait for each reply. Defaults to 5.
# @stdout The output of ping.
# @exitcode 0 A reply was received.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 ping is unavailable or the operating system is unsupported.
# @exitcode other The status of ping.
# @example
#   net::ping 192.168.1.1 1 2
net::ping() {
  [[ "$#" -le 3 ]] || return 64
  local host="${1:-google.com}" attempts="${2:-3}" timeout="${3:-5}"
  ( [[ -n "${host}" && "${attempts}" =~ ^[1-9][0-9]*$ && "${timeout}" =~ ^[1-9][0-9]*$ ]] ) || return 64
  command::require ping || return "$?"
  case "$(system::operating-system)" in
    # BSD ping takes the reply timeout in milliseconds.
    darwin) ping -c "${attempts}" -W "$((timeout * 1000))" "${host}" ;;
    linux) ping -c "${attempts}" -W "${timeout}" "${host}" ;;
    *) return 69 ;;
  esac
}

# @description Test whether a string is one IPv4 or IPv6 address.
# @internal
net::_is-ip-address() {
  [[ "$#" -eq 1 ]] || return 64
  local octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
  ( [[ "$1" =~ ^${octet}\.${octet}\.${octet}\.${octet}$ ]] ) && return 0
  ( [[ "$1" =~ ^[0-9A-Fa-f:.]+$ && "$1" == *:*:* && "$1" != *:::* ]] )
}

# @description Test whether a TCP connection to HOST and PORT succeeds, without output.
#
# @arg $1 string Host name or address.
# @arg $2 integer TCP port.
# @arg $3 integer Optional connection timeout in seconds. Defaults to 10.
# @exitcode 0 The connection succeeded.
# @exitcode 1 The connection failed.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 nc is unavailable.
# @example
#   net::tcp::test github.com 22 5 && git::fetch
# shellcheck disable=SC2329
net::tcp::test() {
  ( [[ "$#" -ge 2 && "$#" -le 3 && -n "$1" && "$2" =~ ^[0-9]+$ ]] ) || return 64
  local timeout="${3:-10}"
  ( [[ "${timeout}" =~ ^[1-9][0-9]*$ ]] ) || return 64
  command::require nc || return "$?"
  nc -z -w "${timeout}" "$1" "$2" >/dev/null 2>&1
}

# @description Capture packets addressed to a host.
#
# tcpdump is retried through sudo when it fails without administrator rights.
#
# @arg $1 string Host name or address.
# @arg $2 string Optional interface. Defaults to any.
# @stdout The packets that tcpdump captures.
# @exitcode 0 The capture ended successfully.
# @exitcode 64 The argument count is not one or two.
# @exitcode 69 The capture failed and sudo is unavailable.
# @exitcode other The status of tcpdump.
# @example
#   net::capture-host 192.168.1.20 eth0
net::capture-host() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; local host="$1" interface="${2:-any}"; if tcpdump -i "$interface" host "$host" 2>/dev/null; then return 0; fi; command -v sudo >/dev/null 2>&1 || return 69; sudo tcpdump -i "$interface" host "$host"; }

# @description Write a TCP port number the operating system reports as unused.
#
# A socket is bound to port 0 on the loopback address, and the port the
# system assigned is written before the socket closes.
#
# @noargs
# @stdout The port number.
# @exitcode 0 The port was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 is unavailable or the socket could not be bound.
# @example
#   port="$(net::unused-port)" && python3 -m http.server "${port}"
net::unused-port() {
  [[ "$#" -eq 0 ]] || return 64
  python::run -c '
import socket
try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        print(sock.getsockname()[1])
except OSError:
    raise SystemExit(69)
'
}

# @description Write the DNS servers that systemd-resolved uses, one per line.
#
# systemd 239 renamed systemd-resolve to resolvectl, so Ubuntu 18.04 (systemd 237)
# is read through systemd-resolve --status.
# @internal
# @exitcode 69 Neither resolvectl nor systemd-resolve is available.
# @exitcode 74 The command failed.
net::dns::_resolved-servers() {
  [[ "$#" -eq 0 ]] || return 64
  local status=''
  if command -v resolvectl >/dev/null 2>&1; then
    status="$(resolvectl dns 2>/dev/null)" || return 74
    printf '%s\n' "${status}" |
      awk '{sub(/^[^:]*: */, ""); for (i = 1; i <= NF; i++) {sub(/#.*/, "", $i); sub(/%.*/, "", $i); if ($i != "") print $i}}'
  elif command -v systemd-resolve >/dev/null 2>&1; then
    status="$(systemd-resolve --status 2>/dev/null)" || return 74
    # The first server follows "DNS Servers:"; the others are alone on indented lines.
    printf '%s\n' "${status}" |
      awk '/^[[:space:]]*DNS Servers:/ {sub(/^[^:]*: */, ""); print; listing = 1; next}
        listing && /^[[:space:]]+[^[:space:]]+$/ {print $1; next}
        {listing = 0}'
  else
    console::_write-error 'Required command is unavailable: resolvectl'
    return 69
  fi
}

# @description Write the configured IPv4 and IPv6 DNS servers, one per line.
#
# Linux uses the servers of systemd-resolved when resolvectl (systemd-resolve on
# systemd 237) answers, and otherwise the nameserver lines of /etc/resolv.conf.
# macOS uses scutil --dns.
#
# @noargs
# @stdout One server address per line without duplicates.
# @exitcode 0 The servers were written.
# @exitcode 64 An argument was given.
# @exitcode 66 /etc/resolv.conf cannot be read.
# @exitcode 69 The operating system is unsupported or scutil is unavailable.
# @exitcode 74 scutil failed.
# @example
#   net::dns::servers
net::dns::servers() {
  [[ "$#" -eq 0 ]] || return 64
  local servers=''
  case "$(system::operating-system)" in
    darwin)
      command::require scutil || return "$?"
      servers="$(scutil --dns | awk '$1 ~ /^nameserver\[/ {print $3}')" || return 74
      ;;
    linux)
      if ! servers="$(net::dns::_resolved-servers 2>/dev/null)"; then
        [[ -r /etc/resolv.conf ]] || return 66
        servers="$(awk '$1 == "nameserver" {print $2}' /etc/resolv.conf)"
      fi
      ;;
    *) return 69 ;;
  esac
  printf '%s\n' "${servers}" | awk 'NF && !seen[$0]++'
}

# @description Write the current DNS manager: systemd-resolved, network-manager, or unknown.
#
# @noargs
# @stdout systemd-resolved, network-manager, or unknown.
# @exitcode 0 The manager was written.
# @exitcode 64 An argument was given.
# @example
#   [[ "$(net::dns::manager)" == systemd-resolved ]] && resolvectl status
net::dns::manager() { [[ "$#" -eq 0 ]] || return 64; net::dns::_manager; }

# @description Write one setting from the effective NetworkManager configuration.
# @internal
net::dns::_network-manager-setting() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[a-z-]+$ ]] ) || return 64
  command -v NetworkManager >/dev/null 2>&1 || return 1
  NetworkManager --print-config 2>/dev/null |
    awk -F= -v key="$1" '/^\[/ {section=$0} section == "[main]" && $1 == key {print $2; exit}'
}

# @description Write the current DNS manager by inspecting resolv.conf and NetworkManager settings.
# @internal
net::dns::_manager() {
  [[ "$#" -eq 0 ]] || return 64
  local target='' dns=''
  if [[ -L /etc/resolv.conf ]]; then
    target="$(readlink /etc/resolv.conf)" || target=''
  fi
  dns="$(net::dns::_network-manager-setting dns)" || dns=''
  case "${target}" in
    */run/NetworkManager/resolv.conf)
      printf 'network-manager\n'
      return 0
      ;;
    */run/systemd/resolve/stub-resolv.conf | */run/systemd/resolve/resolv.conf)
      printf 'systemd-resolved\n'
      return 0
      ;;
  esac
  case "${dns}" in
    systemd-resolved) printf 'systemd-resolved\n' ;;
    default | dnsmasq) printf 'network-manager\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

# @description Back up /etc/resolv.conf when it differs from the link that will replace it.
# @internal
net::dns::_backup-resolv-conf() {
  [[ "$#" -eq 1 && "$1" == /* ]] || return 64
  [[ -e /etc/resolv.conf || -L /etc/resolv.conf ]] || return 0
  # Ubuntu links resolv.conf relatively, so compare the resolved paths.
  if [[ -L /etc/resolv.conf && "$(readlink -f /etc/resolv.conf)" == "$(readlink -f "$1")" ]]; then
    return 0
  fi
  local stamp=''
  stamp="$(time::local-date-time-seconds-basic)" || return "$?"
  command::run-as-root cp -P -- /etc/resolv.conf "/etc/resolv.conf.bashstock-${stamp}" || return 74
}

# @description Write UUIDs of active connections that NetworkManager itself manages, excluding VPNs.
#
# Connections on devices that another program configures, such as the docker0
# bridge, are reported as "connected (externally)" and are left alone.
# @internal
net::dns::_active-network-manager-connections() {
  [[ "$#" -eq 0 ]] || return 64
  command::require nmcli || return "$?"
  local uuid='' type='' device='' state=''
  while IFS=: read -r uuid type device; do
    [[ -n "${uuid}" && "${type}" != vpn && "${type}" != wireguard && "${type}" != loopback ]] || continue
    if [[ -n "${device}" ]]; then
      state="$(nmcli -g GENERAL.STATE device show "${device}" 2>/dev/null)" || state=''
      [[ "${state}" != *externally* ]] || continue
    fi
    printf '%s\n' "${uuid}"
  done < <(nmcli -t -f UUID,TYPE,DEVICE connection show --active 2>/dev/null)
}

# @description Restart systemd-resolved and confirm that it is active.
# @internal
net::dns::_restart-systemd-resolved() {
  [[ "$#" -eq 0 ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl restart systemd-resolved || return 75
  systemctl is-active --quiet systemd-resolved || return 75
}

# @description Restart NetworkManager and wait until it writes its runtime resolv.conf.
# @internal
net::dns::_restart-network-manager() {
  [[ "$#" -eq 0 ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl restart NetworkManager || return 75
  systemctl is-active --quiet NetworkManager || return 75
  local attempt=0
  while [[ ! -f /run/NetworkManager/resolv.conf ]]; do
    attempt=$((attempt + 1))
    [[ "${attempt}" -le 20 ]] || return 75
    sleep 0.5 || return 74
  done
}

# @description Verify the DNS manager, configured servers, resolv.conf link, and name resolution.
# @internal
# @arg $1 string MANAGER Expected DNS manager.
# @arg $2 string SERVER... DNS servers that must be configured.
net::dns::_verify() {
  [[ "$#" -ge 1 ]] || return 64
  local manager="$1" actual='' configured='' server=''
  shift
  actual="$(net::dns::_manager)" || return "$?"
  if [[ "${actual}" != "${manager}" ]]; then
    console::_write-error "DNS manager is ${actual}, expected ${manager}."
    return 75
  fi
  case "${manager}" in
    systemd-resolved)
      [[ "$(readlink /etc/resolv.conf 2>/dev/null)" == */run/systemd/resolve/*resolv.conf ]] || return 75
      configured="$(net::dns::_resolved-servers)" || return "$?"
      ;;
    network-manager)
      [[ "$(readlink /etc/resolv.conf 2>/dev/null)" == */run/NetworkManager/resolv.conf ]] || return 75
      configured="$(<"/etc/resolv.conf")"
      ;;
  esac
  for server in "$@"; do
    if [[ "${configured}" != *"${server}"* ]]; then
      console::_write-error "DNS server is not configured: ${server}"
      return 75
    fi
  done
  net::dns::test example.com || return 75
}

# @description Make systemd-resolved manage DNS and /etc/resolv.conf.
#
# The previous /etc/resolv.conf is kept as a backup.
#
# @noargs
# @exitcode 0 systemd-resolved manages DNS.
# @exitcode 64 An argument was given.
# @exitcode 74 /etc/resolv.conf could not be linked.
# @exitcode other The status of the service, backup, or verification step that failed.
# @example
#   net::dns::use-systemd-resolved
net::dns::use-systemd-resolved() {
  [[ "$#" -eq 0 ]] || return 64
  local link='/run/systemd/resolve/stub-resolv.conf'
  package::_enable-service systemd-resolved || return "$?"
  net::dns::_backup-resolv-conf "${link}" || return "$?"
  command::run-as-root ln -sfn "${link}" /etc/resolv.conf || return 74
  net::dns::_restart-systemd-resolved || return "$?"
  net::dns::_verify systemd-resolved
}

# @description Make NetworkManager manage DNS and /etc/resolv.conf directly.
#
# The previous /etc/resolv.conf is kept as a backup.
#
# @noargs
# @exitcode 0 NetworkManager manages DNS.
# @exitcode 64 An argument was given.
# @exitcode 69 NetworkManager is unavailable.
# @exitcode 74 The configuration or link could not be written.
# @exitcode other The status of the restart, backup, or verification step that failed.
# @example
#   net::dns::use-network-manager
net::dns::use-network-manager() {
  [[ "$#" -eq 0 ]] || return 64
  local link='/run/NetworkManager/resolv.conf'
  command::require NetworkManager || return "$?"
  command::run-as-root install -d -m 0755 /etc/NetworkManager/conf.d || return 74
  file::write-text /etc/NetworkManager/conf.d/90-bashstock-dns.conf \
    $'[main]\ndns=default\nrc-manager=symlink\n' || return "$?"
  net::dns::_restart-network-manager || return "$?"
  net::dns::_backup-resolv-conf "${link}" || return "$?"
  command::run-as-root ln -sfn "${link}" /etc/resolv.conf || return 74
  net::dns::_verify network-manager
}

# @description Configure Google Public DNS while keeping the current DNS manager.
#
# systemd-resolved receives a drop-in file, and NetworkManager receives the servers on every active connection. IPv6 servers are added only to connections with IPv6 configured.
#
# @noargs
# @stderr A message when the DNS manager is unknown.
# @exitcode 0 Google Public DNS is in use.
# @exitcode 64 An argument was given.
# @exitcode 69 The DNS manager is unknown or NetworkManager has no active connection.
# @exitcode 74 A configuration could not be written.
# @exitcode 75 A connection could not be reactivated.
# @exitcode other The status of the restart or verification step that failed.
# @example
#   net::dns::use-google && net::dns::servers
net::dns::use-google() {
  [[ "$#" -eq 0 ]] || return 64
  local manager='' connection='' connections=''
  manager="$(net::dns::_manager)" || return "$?"
  case "${manager}" in
    systemd-resolved)
      command::run-as-root install -d -m 0755 /etc/systemd/resolved.conf.d || return 74
      file::write-text /etc/systemd/resolved.conf.d/90-bashstock-google.conf \
        $'[Resolve]\nDNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844\n' || return "$?"
      net::dns::_restart-systemd-resolved || return "$?"
      ;;
    network-manager)
      connections="$(net::dns::_active-network-manager-connections)" || return "$?"
      [[ -n "${connections}" ]] || return 69
      while IFS= read -r connection; do
        local settings=(ipv4.dns '8.8.8.8 8.8.4.4' ipv4.ignore-auto-dns yes)
        # NetworkManager rejects IPv6 DNS servers unless IPv6 is configured with addresses.
        case "$(nmcli -g ipv6.method connection show "${connection}" 2>/dev/null)" in
          auto | dhcp | manual)
            settings+=(ipv6.dns '2001:4860:4860::8888 2001:4860:4860::8844' ipv6.ignore-auto-dns yes)
            ;;
        esac
        command::run-as-root nmcli connection modify "${connection}" "${settings[@]}" || return 74
        command::run-as-root nmcli connection up "${connection}" >/dev/null || return 75
      done <<<"${connections}"
      ;;
    *)
      console::_write-error 'The DNS manager is unknown; no change was made.'
      return 69
      ;;
  esac
  net::dns::_verify "${manager}" 8.8.8.8 8.8.4.4
}
