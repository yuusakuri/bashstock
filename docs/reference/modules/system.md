# system

Operating-system identity, sleep, and screen-lock settings.

## Overview

Values are normalized so that callers can branch on them without parsing uname output.

## Index

* [system__operating-system](#system__operating-system)
* [system__host-name](#system__host-name)
* [system__kernel-name](#system__kernel-name)
* [system__distribution-name](#system__distribution-name)
* [system__enable-sleep](#system__enable-sleep)
* [system__disable-sleep](#system__disable-sleep)
* [system__disable-auto-lock](#system__disable-auto-lock)
* [system__enable-auto-lock](#system__enable-auto-lock)

### system__operating-system

Write the normalized operating-system family.

#### Example

```bash
[[ "$(system__operating-system)" == darwin ]] && brew --version
```

_Function has no arguments._

#### Exit codes

* **0**: The family was written.
* **64**: An argument was given.

#### Output on stdout

* darwin, linux, or unknown.

### system__host-name

Write the current host name.

HOSTNAME is used when set; otherwise the hostname command is asked.

#### Example

```bash
printf 'Running on %s\n' "$(system__host-name)"
```

_Function has no arguments._

#### Exit codes

* **0**: The host name was written.
* **1**: The host name cannot be determined.
* **64**: An argument was given.

#### Output on stdout

* The host name.

### system__kernel-name

Write the kernel name.

#### Example

```bash
system__kernel-name
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: uname is unavailable.

#### Output on stdout

* The output of uname -s, such as Linux or Darwin.

### system__distribution-name

Write the distribution name.

#### Example

```bash
[[ "$(system__distribution-name)" == ubuntu ]] && sudo apt-get update
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: The distribution cannot be identified.

#### Output on stdout

* darwin, ubuntu, fedora, or the ID from /etc/os-release.

### system__enable-sleep

Enable system sleep.

#### Example

```bash
system__enable-sleep
```

_Function has no arguments._

#### Exit codes

* **0**: Sleep is enabled again.
* **64**: An argument was given.
* **69**: A required command is missing, or the operating system is unsupported.
* **77**: sudo refused the credentials.
* other The status of pmset or systemctl.

### system__disable-sleep

Disable system sleep.

On Linux the sleep, suspend, hibernate, and hybrid-sleep targets are masked; on macOS pmset sets sleep to 0.

#### Example

```bash
system__disable-sleep
```

_Function has no arguments._

#### Exit codes

* **0**: Sleep is disabled until system__enable-sleep.
* **64**: An argument was given.
* **69**: A required command is missing, or the operating system is unsupported.
* **77**: sudo refused the credentials.
* other The status of pmset or systemctl.

### system__disable-auto-lock

Disable automatic screen locking for the current user.

Linux changes GNOME's lock-enabled setting. macOS turns off the password
prompt after the screen saver or display turns off with sysadminctl, which
asks for the current user's login password; macOS no longer reads
com.apple.screensaver askForPassword. Neither changes system sleep or
whether the screen saver starts.

#### Example

```bash
system__disable-auto-lock
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic screen locking is disabled.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or a required command is missing.
* **74**: The screen-lock setting could not be changed, such as after a wrong password.

### system__enable-auto-lock

Enable automatic screen locking for the current user.

Linux enables GNOME's lock-enabled setting and sets lock-delay. macOS asks
for the password after the screen saver or display turns off, set with
sysadminctl, which asks for the current user's login password. Neither
changes system sleep or when the screen saver starts.

#### Example

```bash
system__enable-auto-lock
system__enable-auto-lock 300
```

#### Arguments

* **$1** (integer): Optional seconds between the screen saver or display turning off and the lock. Defaults to 0, which locks immediately.

#### Exit codes

* **0**: Automatic screen locking is enabled.
* **64**: The argument count is wrong, or the delay is not a non-negative integer.
* **69**: The operating system is unsupported, or a required command is missing.
* **74**: The screen-lock setting could not be changed, such as after a wrong password.

