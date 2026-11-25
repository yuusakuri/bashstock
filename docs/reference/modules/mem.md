# mem

Memory capacity and swap files.

## Overview

Capacities are written in bytes or gibibytes; swap files are managed through administrator execution on Linux.

## Index

* [mem__physical-total-bytes](#mem__physical-total-bytes)
* [mem__physical-total-gibibytes](#mem__physical-total-gibibytes)
* [mem__swap__total-bytes](#mem__swap__total-bytes)
* [mem__swap__total-gibibytes](#mem__swap__total-gibibytes)
* [mem__total-bytes](#mem__total-bytes)
* [mem__total-gibibytes](#mem__total-gibibytes)
* [mem__swap__disable-all](#mem__swap__disable-all)
* [mem__swap__remove-all-files](#mem__swap__remove-all-files)
* [mem__swap__create](#mem__swap__create)
* [mem__swap__list](#mem__swap__list)
* [mem__swap__ensure-total-size](#mem__swap__ensure-total-size)

### mem__physical-total-bytes

Write the total physical memory in bytes.

#### Example

```bash
mem__physical-total-bytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or sysctl is missing on macOS.
* **74**: The memory size could not be read.

#### Output on stdout

* The total physical memory in bytes.

### mem__physical-total-gibibytes

Write the total physical memory in gibibytes.

#### Example

```bash
mem__physical-total-gibibytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: The memory size could not be read.

#### Output on stdout

* The total physical memory in GiB with two decimals, such as 15.53.

### mem__swap__total-bytes

Write the total swap capacity in bytes.

#### Example

```bash
[[ "$(mem__swap__total-bytes)" -gt 0 ]] || mem__swap__create 4
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or sysctl is missing on macOS.
* **74**: The swap size could not be read.

#### Output on stdout

* The total swap capacity in bytes; 0 without swap.

### mem__swap__total-gibibytes

Write the total swap capacity in gibibytes.

#### Example

```bash
mem__swap__total-gibibytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: The swap size could not be read.

#### Output on stdout

* The total swap capacity in GiB with two decimals.

### mem__total-bytes

Write the total memory and swap capacity in bytes.

#### Example

```bash
mem__total-bytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: A size could not be read.

#### Output on stdout

* The sum of physical memory and swap in bytes.

### mem__total-gibibytes

Write the total memory and swap capacity in gibibytes.

#### Example

```bash
printf 'Memory and swap: %s GiB\n' "$(mem__total-gibibytes)"
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: A size could not be read.

#### Output on stdout

* The sum of physical memory and swap in GiB with two decimals.

### mem__swap__disable-all

Disable every active swap area through administrator execution.

#### Example

```bash
mem__swap__disable-all
```

_Function has no arguments._

#### Exit codes

* **0**: Every swap area is disabled.
* **64**: An argument was given.
* **69**: swapoff is unavailable.
* other The status of swapoff.

### mem__swap__remove-all-files

Disable every swap file, remove its /etc/fstab entry, and delete it.

Swap partitions are kept. The first failure stops the removal and is reported.

#### Example

```bash
mem__swap__remove-all-files && mem__swap__create 4294967296
```

_Function has no arguments._

#### Exit codes

* **0**: Every swap file was removed.
* **64**: An argument was given.
* **69**: /proc/swaps cannot be read.
* **74**: A swap file could not be disabled, unregistered, or deleted.

#### Output on stderr

* The swap file and step that failed.

### mem__swap__create

Create a swap file, enable it, and register it in /etc/fstab.

The file is created and enabled through administrator execution. When a step
fails, the swap file is disabled and removed again.

#### Example

```bash
mem__swap__create 4294967296
```

#### Arguments

* **$1** (integer): Optional size in bytes. Defaults to 8589934592 (8 GiB).
* **$2** (string): Optional absolute swap file path without blanks or backslashes. Defaults to /swapfile.

#### Exit codes

* **0**: The swap file is enabled and registered.
* **64**: The size or path is invalid, or the path has a blank or a backslash.
* **69**: The system is not Linux or mkswap is unavailable.
* **73**: The path already exists.
* **74**: The file could not be created or enabled.
* other The status of the /etc/fstab update.

#### Output on stderr

* A message when the path already exists.

### mem__swap__list

List active swap devices.

#### Example

```bash
mem__swap__list
```

_Function has no arguments._

#### Exit codes

* **0**: The swap areas were written.
* **64**: An argument was given.
* **69**: swapon is unavailable.

#### Output on stdout

* The output of swapon --show.

### mem__swap__ensure-total-size

Extend swap capacity up to a target size.

#### Example

```bash
mem__swap__ensure-total-size 8589934592
```

#### Arguments

* **$1** (integer): Target total swap size in bytes.
* **$2** (integer): Optional largest size to add in bytes. Defaults to the target.
* **$3** (string): Optional swap file path for the addition. Defaults to /swapfile.

#### Exit codes

* **0**: The swap capacity reaches the target, or the allowed addition was made.
* **64**: The arguments are invalid.
* other The status of mem__swap__total-bytes or mem__swap__create.

