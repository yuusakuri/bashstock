# adb

Android devices over ADB and fastboot.

## Overview

Functions select a device by serial number and wrap one adb or fastboot command each.

## Index

* [adb__device__wait](#adb__device__wait)
* [adb__device__pull](#adb__device__pull)
* [adb__device__push](#adb__device__push)
* [adb__logcat__clear](#adb__logcat__clear)
* [adb__logcat__once](#adb__logcat__once)
* [adb__logcat__continuous](#adb__logcat__continuous)
* [adb__device__reboot](#adb__device__reboot)
* [adb__device__first](#adb__device__first)
* [adb__device__list](#adb__device__list)
* [adb__device__wait-for-path](#adb__device__wait-for-path)
* [adb__device__screen__capture-once](#adb__device__screen__capture-once)
* [adb__device__select-and-pull](#adb__device__select-and-pull)
* [adb__device__bootloader__enter](#adb__device__bootloader__enter)
* [adb__device__bootloader__unlock](#adb__device__bootloader__unlock)
* [adb__device__verity__disable](#adb__device__verity__disable)
* [adb__device__partition__remount](#adb__device__partition__remount)
* [adb__device__build__fingerprint](#adb__device__build__fingerprint)
* [adb__device__build__date](#adb__device__build__date)
* [adb__device__slot__suffix](#adb__device__slot__suffix)
* [adb__device__build__kernel-version](#adb__device__build__kernel-version)
* [adb__device__screen__capture-continuous](#adb__device__screen__capture-continuous)
* [adb__device__partition__sha256](#adb__device__partition__sha256)
* [adb__wake__lock](#adb__wake__lock)
* [adb__wake__unlock](#adb__wake__unlock)
* [adb__wake__list](#adb__wake__list)
* [adb__device__set-default](#adb__device__set-default)
* [adb__server__start](#adb__server__start)
* [adb__server__stop](#adb__server__stop)
* [adb__server__restart](#adb__server__restart)

### adb__device__wait

Wait for an ADB device to connect, optionally selected with --serial.

#### Example

```bash
adb__device__wait --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The device is connected.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb wait-for-device.

### adb__device__pull

Copy files from an ADB device to the host.

#### Example

```bash
adb__device__pull /sdcard/DCIM/Camera ./camera --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **...** (string): Device paths followed by an optional host destination.

#### Exit codes

* **0**: The files were copied.
* **64**: No path was given.
* **69**: adb is unavailable.
* other The status of adb pull.

### adb__device__push

Copy files from the host to an ADB device.

#### Example

```bash
adb__device__push app-debug.apk /data/local/tmp/
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **...** (string): Host paths followed by the device destination.

#### Exit codes

* **0**: The files were copied.
* **64**: No path was given.
* **69**: adb is unavailable.
* other The status of adb push.

### adb__logcat__clear

Clear the selected device log buffers.

#### Example

```bash
adb__logcat__clear --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The log buffers were cleared.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

### adb__logcat__once

Write the selected device log buffers once.

#### Example

```bash
adb__logcat__once > device.log
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The log was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

#### Output on stdout

* The current log buffers.

### adb__logcat__continuous

Stream logs from the selected device.

#### Example

```bash
adb__logcat__continuous | grep -i crash
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: adb logcat ended successfully.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

#### Output on stdout

* The device log, streamed until interrupted.

### adb__device__reboot

Reboot the selected device.

The function returns after the device has disconnected and connected again.

#### Example

```bash
adb__device__reboot 120 --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (integer): Optional seconds to wait for the device to come back. Defaults to 60.

#### Exit codes

* **0**: The device rebooted and reconnected.
* **64**: The arguments are invalid.
* **69**: adb is unavailable.
* **74**: The clock or sleep failed.
* **75**: The device did not reconnect in time.
* other The status of adb reboot.

### adb__device__first

Write the first connected ADB device serial.

#### Example

```bash
serial="$(adb__device__first)"
```

_Function has no arguments._

#### Exit codes

* **0**: The serial was written.
* **1**: No device is connected.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb devices.

#### Output on stdout

* The serial of the first connected device.

### adb__device__list

List connected ADB device serials.

#### Example

```bash
adb__device__list
```

_Function has no arguments._

#### Exit codes

* **0**: The serials were written; there may be none.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb devices.

#### Output on stdout

* One serial per line for devices in the device state.

### adb__device__wait-for-path

Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout.

#### Example

```bash
adb__device__wait-for-path /sdcard/Download/report.json 60
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Path on the device.
* **$2** (integer): Optional seconds to wait. Defaults to 30.

#### Exit codes

* **0**: The path exists.
* **64**: The arguments are invalid.
* **74**: The clock or sleep failed.
* **75**: The path did not appear in time.

### adb__device__screen__capture-once

Save one screenshot atomically and print its path.

#### Example

```bash
adb__device__screen__capture-once ./screen.png --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional output PNG file. Defaults to ${WORK_DIR:-.}/STAMP/STAMP-adb-image.png.

#### Exit codes

* **0**: The screenshot was saved.
* **64**: The arguments are invalid.
* **74**: The file could not be written.
* **75**: The device returned no image.

#### Output on stdout

* The path of the saved screenshot.

### adb__device__select-and-pull

Select one requested device path and pull it to the host.

#### Example

```bash
adb__device__select-and-pull /sdcard/Download /sdcard/DCIM --output-directory ./device
```

#### Options

* **--output-directory \<DIRECTORY\>**

  Host directory to copy to. Defaults to the current directory.

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **...** (string): Device paths to choose from.

#### Exit codes

* **0**: The selected path was copied.
* **64**: No path was given or an option has no value.
* **74**: The output directory could not be created.
* other The status of the prompt or of adb pull.

### adb__device__bootloader__enter

Reboot the selected device into its bootloader.

#### Example

```bash
  adb__device__bootloader__enter --serial 0123456789ABCDEF
shellcheck disable=SC2329
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The device is rebooting into its bootloader.
* **64**: The arguments are invalid.
* **69**: adb is unavailable.
* other The status of adb reboot.

### adb__device__bootloader__unlock

Request bootloader unlocking and wait for the device to reconnect.

The unlock must be confirmed on the device. Unlocking erases user data. A
device that stays in fastboot afterwards is rebooted.

#### Example

```bash
adb__device__bootloader__unlock --serial 0123456789ABCDEF
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The bootloader was unlocked and ADB reconnected.
* **64**: The arguments are invalid.
* **69**: fastboot or adb is unavailable.
* **74**: The clock or sleep failed.
* **75**: The device did not reach fastboot or ADB in time.
* other The status of the adb or fastboot command that failed.

### adb__device__verity__disable

Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects.

#### Example

```bash
adb__device__verity__disable && adb__device__partition__remount
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: dm-verity is disabled and ADB reconnected.
* **64**: The arguments are invalid.
* **74**: sleep failed.
* **75**: The device did not reconnect in time.
* other The status of the adb command that failed.

### adb__device__partition__remount

Make the system partitions of a rooted device writable.

adb root and adb remount run first, and the root file system is then
remounted read-write.

#### Example

```bash
adb__device__partition__remount --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The partitions are writable.
* **64**: The arguments are invalid.
* **75**: The device did not reconnect in time.
* other The status of the adb command that failed.

### adb__device__build__fingerprint

Write the selected device build fingerprint.

#### Example

```bash
adb__device__build__fingerprint
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The value of ro.build.fingerprint.

### adb__device__build__date

Write the selected device build timestamp as Unix seconds.

#### Example

```bash
date -d "@$(adb__device__build__date)"
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The value of ro.build.date.utc.

### adb__device__slot__suffix

Write the selected device active slot suffix.

#### Example

```bash
adb__device__slot__suffix
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The value of ro.boot.slot_suffix, such as _a; empty on devices without slots.

### adb__device__build__kernel-version

Write the selected device kernel release.

#### Example

```bash
adb__device__build__kernel-version
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The output of uname -r on the device.

### adb__device__screen__capture-continuous

Save repeated screenshots; MAX_COUNT of zero runs until interrupted.

#### Example

```bash
adb__device__screen__capture-continuous ./frames 0.5 20
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional output directory. Defaults to ./screencap-loop.
* **$2** (number): Optional seconds between screenshots. Defaults to 1.
* **$3** (integer): Optional number of screenshots; 0 runs until interrupted. Defaults to 0.

#### Exit codes

* **0**: The requested screenshots were saved.
* **64**: The arguments are invalid.
* **74**: The directory could not be created or sleep failed.
* other The status of adb__device__screen__capture-once.

#### Output on stdout

* The path of each saved screenshot.

### adb__device__partition__sha256

Write a device partition SHA-256 checksum.

#### Example

```bash
adb__device__partition__sha256 /dev/block/by-name/boot_a
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Partition path below /dev/block.

#### Exit codes

* **0**: The checksum was written.
* **64**: The path or options are invalid.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The output of sha256sum on the device.

### adb__wake__lock

Hold a kernel wake lock using a tag, defaulting to debug.

The device must allow adb root.

#### Example

```bash
adb__wake__lock benchmark
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional wake lock tag. Defaults to debug.

#### Exit codes

* **0**: The wake lock is held.
* **64**: The arguments are invalid.
* **69**: adb root is unavailable or /sys/power/wake_lock is not writable.
* other The status of the adb command that failed.

### adb__wake__unlock

Release a kernel wake lock using the same tag.

The device must allow adb root.

#### Example

```bash
adb__wake__unlock benchmark
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional wake lock tag. Defaults to debug.

#### Exit codes

* **0**: The wake lock was released.
* **64**: The arguments are invalid.
* **69**: adb root is unavailable or /sys/power/wake_unlock is not writable.
* other The status of the adb command that failed.

### adb__wake__list

Print active kernel wake locks.

#### Example

```bash
adb__wake__list
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The tags were written.
* **64**: The arguments are invalid.
* **69**: adb root is unavailable or /sys/power/wake_lock is not readable.
* other The status of the adb command that failed.

#### Output on stdout

* The active wake lock tags.

### adb__device__set-default

Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL.

#### Example

```bash
adb__device__set-default "$(adb__device__first)"
```

#### Arguments

* **$1** (string): Device serial.

#### Variables set

* **ANDROID_SERIAL** (is): exported in the current shell.

#### Exit codes

* **0**: The variable was set.
* **64**: The argument is not one valid serial.

### adb__server__start

Start the host ADB server.

#### Example

```bash
adb__server__start
```

_Function has no arguments._

#### Exit codes

* **0**: The server is running.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb start-server.

### adb__server__stop

Stop the host ADB server.

#### Example

```bash
adb__server__stop
```

_Function has no arguments._

#### Exit codes

* **0**: The server stopped.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb kill-server.

### adb__server__restart

Stop and then start the host ADB server.

#### Example

```bash
adb__server__restart
```

_Function has no arguments._

#### Exit codes

* **0**: The server was restarted.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb.

