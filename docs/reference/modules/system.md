# system

Operating-system identity, sleep, and screen-lock settings.

## Overview

Values are normalized so that callers can branch on them without parsing uname output.

## Index

* [system::operating-system](#systemoperating-system)
* [system::host-name](#systemhost-name)
* [system::kernel-name](#systemkernel-name)
* [system::distribution-name](#systemdistribution-name)
* [system::enable-sleep](#systemenable-sleep)
* [system::disable-sleep](#systemdisable-sleep)
* [system::disable-auto-lock](#systemdisable-auto-lock)

### system::operating-system

Write the normalized operating-system family.

#### Example

```bash
[[ "$(system::operating-system)" == darwin ]] && brew --version
```

_Function has no arguments._

#### Exit codes

* **0**: The family was written.
* **64**: An argument was given.

#### Output on stdout

* darwin, linux, or unknown.

### system::host-name

Write the current host name.

HOSTNAME is used when set; otherwise the hostname command is asked.

#### Example

```bash
printf 'Running on %s\n' "$(system::host-name)"
```

_Function has no arguments._

#### Exit codes

* **0**: The host name was written.
* **1**: The host name cannot be determined.
* **64**: An argument was given.

#### Output on stdout

* The host name.

### system::kernel-name

Write the kernel name.

#### Example

```bash
system::kernel-name
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: uname is unavailable.

#### Output on stdout

* The output of uname -s, such as Linux or Darwin.

### system::distribution-name

Write the distribution name.

#### Example

```bash
[[ "$(system::distribution-name)" == ubuntu ]] && sudo apt-get update
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: The distribution cannot be identified.

#### Output on stdout

* darwin, ubuntu, fedora, or the ID from /etc/os-release.

### system::enable-sleep

Enable system sleep.

#### Example

```bash
system::enable-sleep
```

_Function has no arguments._

#### Exit codes

* **0**: Sleep is enabled again.
* **64**: An argument was given.
* **69**: A required command is missing, or the operating system is unsupported.
* **77**: sudo refused the credentials.
* other The status of pmset or systemctl.

### system::disable-sleep

Disable system sleep.

On Linux the sleep, suspend, hibernate, and hybrid-sleep targets are masked; on macOS pmset sets sleep to 0.

#### Example

```bash
system::disable-sleep
```

_Function has no arguments._

#### Exit codes

* **0**: Sleep is disabled until system::enable-sleep.
* **64**: An argument was given.
* **69**: A required command is missing, or the operating system is unsupported.
* **77**: sudo refused the credentials.
* other The status of pmset or systemctl.

### system::disable-auto-lock

Disable automatic screen locking for the current user.

Linux changes GNOME's lock-enabled setting. macOS disables the password prompt
after the screen saver or display turns off. Neither changes system sleep or
whether the screen saver starts.

#### Example

```bash
system::disable-auto-lock
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic screen locking is disabled.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or a required command is missing.
* **74**: The screen-lock setting could not be changed.

