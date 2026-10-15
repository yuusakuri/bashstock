# net

IP address checks and network interface configuration.

## Overview

Static addresses are written to the Netplan configuration of Ubuntu.

## Index

* [net::ip::set-static](#netipset-static)

### net::ip::set-static

Replace one Ubuntu Netplan file with a static IPv4 configuration.

Values that are not given come from the current configuration. The new file
is generated and checked in a temporary root before it replaces the old one,
and the host name is set as well.

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

  Netplan file. Defaults to the only /etc/netplan YAML file.

* **--renderer \<RENDERER\>**

  networkd or NetworkManager. Defaults to Netplan's selection.

#### Exit codes

* **0**: The configuration was applied.
* **64**: An option or value is invalid.
* **65**: Netplan rejected the generated configuration.
* **69**: The system is not Ubuntu, a required command is missing, or a default cannot be found.
* **74**: A temporary file could not be written.
* other The status of netplan or hostnamectl.

