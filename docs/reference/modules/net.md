# net

IP addresses, DNS, routes, and connectivity checks.

## Overview

Static addresses are written to the Netplan configuration of Ubuntu.

## Index

* [net::ip::set-static](#netipset-static)
* [net::interface::default](#netinterfacedefault)
* [net::gateway::default](#netgatewaydefault)
* [net::ip::private-v4](#netipprivate-v4)
* [net::ip::private-v6](#netipprivate-v6)
* [net::ip::public](#netippublic)
* [net::dns::test](#netdnstest)
* [net::ping](#netping)
* [net::tcp::test](#nettcptest)
* [net::capture-host](#netcapture-host)
* [net::unused-port](#netunused-port)
* [net::dns::servers](#netdnsservers)
* [net::dns::manager](#netdnsmanager)
* [net::dns::use-systemd-resolved](#netdnsuse-systemd-resolved)
* [net::dns::use-network-manager](#netdnsuse-network-manager)
* [net::dns::use-google](#netdnsuse-google)

### net::ip::set-static

Replace one Ubuntu Netplan file with a static IPv4 configuration.

Values that are not given come from the current configuration. The new file
is generated and checked in a temporary root before it replaces the old one,
and the host name is set as well. When Netplan rejects or cannot apply the new
file, the previous file is restored and applied again.

#### Example

```bash
net::ip::set-static --interface eth0 --address 192.168.1.20 --prefix-length 24 \
  --gateway 192.168.1.1 --dns 192.168.1.1,1.1.1.1
```

#### Options

* **--interface \<INTERFACE\>**

  Network interface. Defaults to the first default route.

* **--address \<ADDRESS\>**

  IPv4 address. Defaults to the interface's primary address.

* **--prefix-length \<PREFIX_LENGTH\>**

  IPv4 prefix length. Defaults to the current value.

* **--gateway \<GATEWAY\>**

  IPv4 gateway. Defaults to the first default route.

* **--dns \<DNS_SERVERS\>**

  Comma-separated IPv4 DNS servers. Defaults to 1.1.1.1,8.8.8.8.

* **--host-name \<HOST_NAME\>**

  Host name. Defaults to the current host name.

* **--file \<FILE\>**

  Netplan file. Defaults to the only /etc/netplan YAML file; pass it when NetworkManager has written its own files there.

* **--renderer \<RENDERER\>**

  networkd or NetworkManager. Defaults to Netplan's selection.

#### Exit codes

* **0**: The configuration was applied.
* **64**: An option or value is invalid.
* **65**: Netplan rejected the generated configuration.
* **69**: The system is not Ubuntu, a required command is missing, or a default cannot be found, such as the Netplan file when /etc/netplan holds several.
* **74**: A temporary file or the Netplan file could not be written.
* **75**: Netplan could not apply the configuration, so the previous file was restored, or the host name could not be set.
* **77**: sudo is unavailable or refused the credentials.

### net::interface::default

Write the first default-route interface.

#### Example

```bash
net::ip::private-v4 "$(net::interface::default)"
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: No default route exists, or the routing tool is unavailable.

#### Output on stdout

* The interface name, such as eth0 or en0.

### net::gateway::default

Write the first default-route gateway.

#### Example

```bash
net::ping "$(net::gateway::default)"
```

_Function has no arguments._

#### Exit codes

* **0**: The address was written.
* **64**: An argument was given.
* **69**: No default route exists, or the routing tool is unavailable.

#### Output on stdout

* The gateway address.

### net::ip::private-v4

Write the primary RFC 1918 IPv4 address of an interface.

#### Example

```bash
net::ip::private-v4 eth0
```

#### Arguments

* **$1** (string): INTERFACE Interface name. Defaults to the interface of the default route.

#### Exit codes

* **0**: The address was written.
* **1**: The interface has no private IPv4 address.
* **64**: More than one argument was given.
* **69**: No interface was given and there is no default route, or the address tool is unavailable.

#### Output on stdout

* The address without a prefix length, such as 192.168.1.20.

### net::ip::private-v6

Write the primary unique local IPv6 address of an interface.

Only addresses in fc00::/7 are considered, in the order the operating
system lists them, after removing the excluded prefixes.

#### Example

```bash
net::ip::private-v6 en0 fe80
```

#### Arguments

* **$1** (string): INTERFACE Interface name. Defaults to the interface of the default route.
* **$2** (string): EXCLUDED_PREFIXES Comma-separated address prefixes to skip. Defaults to fe80,fda6: link-local addresses and the auxiliary ULA of the reference network.

#### Exit codes

* **0**: The address was written.
* **1**: No address remains after the exclusions.
* **64**: More than two arguments were given.
* **69**: No interface was given and there is no default route, or the address tool is unavailable.

#### Output on stdout

* The address without a prefix length.

### net::ip::public

Write the public IP address reported by ifconfig.me.

curl is preferred and wget is used when curl is missing. The response
must be one IPv4 or IPv6 address; anything else returns 74.

#### Example

```bash
net::ip::public
```

_Function has no arguments._

#### Exit codes

* **0**: The address was written.
* **64**: An argument was given.
* **69**: Neither curl nor wget is available.
* **74**: The request failed or the response is not an address.

#### Output on stdout

* One IPv4 or IPv6 address.

#### Output on stderr

* A message when neither curl nor wget is available.

### net::dns::test

Test whether a DNS name resolves.

#### Example

```bash
net::dns::test github.com || net::dns::use-google
```

#### Arguments

* **$1** (string): Host name to resolve.

#### Exit codes

* **0**: The name resolves.
* **1**: The name does not resolve.
* **64**: The name is empty, or the argument count is not one.
* **69**: Neither getent nor dscacheutil is available.

### net::ping

Send ICMP echo requests to a host.

#### Example

```bash
net::ping 192.168.1.1 1 2
```

#### Arguments

* **$1** (string): Optional host name or address. Defaults to google.com.
* **$2** (integer): Optional number of requests. Defaults to 3.
* **$3** (integer): Optional seconds to wait for each reply. Defaults to 5.

#### Exit codes

* **0**: A reply was received.
* **64**: The arguments are invalid.
* **69**: ping is unavailable or the operating system is unsupported.
* other The status of ping.

#### Output on stdout

* The output of ping.

### net::tcp::test

Test whether a TCP connection to HOST and PORT succeeds, without output.

#### Example

```bash
  net::tcp::test github.com 22 5 && git::fetch
shellcheck disable=SC2329
```

#### Arguments

* **$1** (string): Host name or address.
* **$2** (integer): TCP port.
* **$3** (integer): Optional connection timeout in seconds. Defaults to 10.

#### Exit codes

* **0**: The connection succeeded.
* **1**: The connection failed.
* **64**: The arguments are invalid.
* **69**: nc is unavailable.

### net::capture-host

Capture packets addressed to a host.

tcpdump is retried through sudo when it fails without administrator rights.

#### Example

```bash
net::capture-host 192.168.1.20 eth0
```

#### Arguments

* **$1** (string): Host name or address.
* **$2** (string): Optional interface. Defaults to any.

#### Exit codes

* **0**: The capture ended successfully.
* **64**: The argument count is not one or two.
* **69**: The capture failed and sudo is unavailable.
* other The status of tcpdump.

#### Output on stdout

* The packets that tcpdump captures.

### net::unused-port

Write a TCP port number the operating system reports as unused.

A socket is bound to port 0 on the loopback address, and the port the
system assigned is written before the socket closes.

#### Example

```bash
port="$(net::unused-port)" && python3 -m http.server "${port}"
```

_Function has no arguments._

#### Exit codes

* **0**: The port was written.
* **64**: An argument was given.
* **69**: Python 3 is unavailable or the socket could not be bound.

#### Output on stdout

* The port number.

### net::dns::servers

Write the configured IPv4 and IPv6 DNS servers, one per line.

Linux uses the servers of systemd-resolved when resolvectl (systemd-resolve on
systemd 237) answers, and otherwise the nameserver lines of /etc/resolv.conf.
macOS uses scutil --dns.

#### Example

```bash
net::dns::servers
```

_Function has no arguments._

#### Exit codes

* **0**: The servers were written.
* **64**: An argument was given.
* **66**: /etc/resolv.conf cannot be read.
* **69**: The operating system is unsupported or scutil is unavailable.
* **74**: scutil failed.

#### Output on stdout

* One server address per line without duplicates.

### net::dns::manager

Write the current DNS manager: systemd-resolved, network-manager, or unknown.

#### Example

```bash
[[ "$(net::dns::manager)" == systemd-resolved ]] && resolvectl status
```

_Function has no arguments._

#### Exit codes

* **0**: The manager was written.
* **64**: An argument was given.

#### Output on stdout

* systemd-resolved, network-manager, or unknown.

### net::dns::use-systemd-resolved

Make systemd-resolved manage DNS and /etc/resolv.conf.

The previous /etc/resolv.conf is kept as a backup.

#### Example

```bash
net::dns::use-systemd-resolved
```

_Function has no arguments._

#### Exit codes

* **0**: systemd-resolved manages DNS.
* **64**: An argument was given.
* **74**: /etc/resolv.conf could not be linked.
* other The status of the service, backup, or verification step that failed.

### net::dns::use-network-manager

Make NetworkManager manage DNS and /etc/resolv.conf directly.

The previous /etc/resolv.conf is kept as a backup.

#### Example

```bash
net::dns::use-network-manager
```

_Function has no arguments._

#### Exit codes

* **0**: NetworkManager manages DNS.
* **64**: An argument was given.
* **69**: NetworkManager is unavailable.
* **74**: The configuration or link could not be written.
* other The status of the restart, backup, or verification step that failed.

### net::dns::use-google

Configure Google Public DNS while keeping the current DNS manager.

systemd-resolved receives a drop-in file, and NetworkManager receives the servers on every active connection. IPv6 servers are added only to connections with IPv6 configured.

#### Example

```bash
net::dns::use-google && net::dns::servers
```

_Function has no arguments._

#### Exit codes

* **0**: Google Public DNS is in use.
* **64**: An argument was given.
* **69**: The DNS manager is unknown or NetworkManager has no active connection.
* **74**: A configuration could not be written.
* **75**: A connection could not be reactivated.
* other The status of the restart or verification step that failed.

#### Output on stderr

* A message when the DNS manager is unknown.

