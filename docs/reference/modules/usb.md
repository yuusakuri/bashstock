# usb

USB devices, partitions, and file systems.

## Overview

Devices are listed with lsusb and lsblk.

## Index

* [usb__device__list](#usb__device__list)
* [usb__partition__select](#usb__partition__select)
* [usb__filesystem__repair](#usb__filesystem__repair)
* [usb__filesystem__format-fat32](#usb__filesystem__format-fat32)

### usb__device__list

Write the USB devices with lsusb.

#### Example

```bash
usb__device__list
```

_Function has no arguments._

#### Exit codes

* **0**: The devices were written.
* **64**: An argument was given.
* **69**: lsusb is unavailable.
* other The status of lsusb.

#### Output on stdout

* The output of lsusb.

### usb__partition__select

Select a USB partition, or a USB disk without partitions, and write its device path.

One candidate is selected automatically; several are offered for
interactive selection with their size, file system, and label.

#### Example

```bash
device="$(usb__partition__select)"
```

_Function has no arguments._

#### Exit codes

* **0**: The path was written.
* **1**: No USB block device is connected.
* **64**: An argument was given.
* other The status of lsblk or the prompt.

#### Output on stdout

* The device path, such as /dev/sdb1.

### usb__filesystem__repair

Select a USB file system, unmount it, and repair it through administrator execution.

FAT uses fsck.fat -a, exFAT fsck.exfat -a, and other types fsck -y.

#### Example

```bash
usb__filesystem__repair
```

_Function has no arguments._

#### Exit codes

* **0**: The file system was repaired or is clean.
* **1**: No USB block device is connected.
* **64**: An argument was given.
* **74**: The file system type could not be read.
* other The status of the unmount or of fsck.

### usb__filesystem__format-fat32

Select a USB partition, unmount it, and format it as FAT32 through administrator execution.

Everything on the selected partition is erased.

#### Example

```bash
usb__filesystem__format-fat32
```

_Function has no arguments._

#### Exit codes

* **0**: The partition was formatted.
* **1**: No USB block device is connected.
* **64**: An argument was given.
* other The status of the unmount or of mkfs.vfat.

