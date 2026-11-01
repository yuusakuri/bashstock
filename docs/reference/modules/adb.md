# adb

Android devices over ADB and fastboot.

## Overview

Functions select a device by serial number and wrap one adb or fastboot command each.

## Index

* [adb::device::wait](#adbdevicewait)
* [adb::device::pull](#adbdevicepull)
* [adb::device::push](#adbdevicepush)
* [adb::logcat::clear](#adblogcatclear)
* [adb::logcat::once](#adblogcatonce)
* [adb::logcat::continuous](#adblogcatcontinuous)
* [adb::device::reboot](#adbdevicereboot)
* [adb::device::first](#adbdevicefirst)
* [adb::device::list](#adbdevicelist)
* [adb::device::wait-for-path](#adbdevicewait-for-path)
* [adb::device::screen::capture-once](#adbdevicescreencapture-once)
* [adb::device::select-and-pull](#adbdeviceselect-and-pull)
* [adb::device::bootloader::enter](#adbdevicebootloaderenter)
* [adb::device::bootloader::unlock](#adbdevicebootloaderunlock)
* [adb::device::verity::disable](#adbdeviceveritydisable)
* [adb::device::partition::remount](#adbdevicepartitionremount)
* [adb::device::build::fingerprint](#adbdevicebuildfingerprint)
* [adb::device::build::date](#adbdevicebuilddate)
* [adb::device::slot::suffix](#adbdeviceslotsuffix)
* [adb::device::build::kernel-version](#adbdevicebuildkernel-version)
* [adb::device::screen::capture-continuous](#adbdevicescreencapture-continuous)
* [adb::device::partition::sha256](#adbdevicepartitionsha256)
* [adb::wake::lock](#adbwakelock)
* [adb::wake::unlock](#adbwakeunlock)
* [adb::wake::list](#adbwakelist)
* [adb::device::set-default](#adbdeviceset-default)
* [adb::server::start](#adbserverstart)
* [adb::server::stop](#adbserverstop)
* [adb::server::restart](#adbserverrestart)

### adb::device::wait

Wait for an ADB device to connect, optionally selected with --serial.

#### Example

```bash
adb::device::wait --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The device is connected.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb wait-for-device.

### adb::device::pull

Copy files from an ADB device to the host.

#### Example

```bash
adb::device::pull /sdcard/DCIM/Camera ./camera --serial emulator-5554
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

### adb::device::push

Copy files from the host to an ADB device.

#### Example

```bash
adb::device::push app-debug.apk /data/local/tmp/
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

### adb::logcat::clear

Clear the selected device log buffers.

#### Example

```bash
adb::logcat::clear --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The log buffers were cleared.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

### adb::logcat::once

Write the selected device log buffers once.

#### Example

```bash
adb::logcat::once > device.log
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

### adb::logcat::continuous

Stream logs from the selected device.

#### Example

```bash
adb::logcat::continuous | grep -i crash
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

### adb::device::reboot

Reboot the selected device.

The function returns after the device has disconnected and connected again.

#### Example

```bash
adb::device::reboot 120 --serial emulator-5554
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

### adb::device::first

Write the first connected ADB device serial.

#### Example

```bash
serial="$(adb::device::first)"
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

### adb::device::list

List connected ADB device serials.

#### Example

```bash
adb::device::list
```

_Function has no arguments._

#### Exit codes

* **0**: The serials were written; there may be none.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb devices.

#### Output on stdout

* One serial per line for devices in the device state.

### adb::device::wait-for-path

Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout.

#### Example

```bash
adb::device::wait-for-path /sdcard/Download/report.json 60
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

### adb::device::screen::capture-once

Save one screenshot atomically and print its path.

#### Example

```bash
adb::device::screen::capture-once ./screen.png --serial emulator-5554
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

### adb::device::select-and-pull

Select one requested device path and pull it to the host.

#### Example

```bash
adb::device::select-and-pull /sdcard/Download /sdcard/DCIM --output-directory ./device
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

### adb::device::bootloader::enter

Reboot the selected device into its bootloader.

#### Example

```bash
  adb::device::bootloader::enter --serial 0123456789ABCDEF
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

### adb::device::bootloader::unlock

Request bootloader unlocking and wait for the device to reconnect.

The unlock must be confirmed on the device. Unlocking erases user data. A
device that stays in fastboot afterwards is rebooted.

#### Example

```bash
adb::device::bootloader::unlock --serial 0123456789ABCDEF
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

### adb::device::verity::disable

Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects.

#### Example

```bash
adb::device::verity::disable && adb::device::partition::remount
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

### adb::device::partition::remount

Make the system partitions of a rooted device writable.

adb root and adb remount run first, and the root file system is then
remounted read-write.

#### Example

```bash
adb::device::partition::remount --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The partitions are writable.
* **64**: The arguments are invalid.
* **75**: The device did not reconnect in time.
* other The status of the adb command that failed.

### adb::device::build::fingerprint

Write the selected device build fingerprint.

#### Example

```bash
adb::device::build::fingerprint
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

### adb::device::build::date

Write the selected device build timestamp as Unix seconds.

#### Example

```bash
date -d "@$(adb::device::build::date)"
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

### adb::device::slot::suffix

Write the selected device active slot suffix.

#### Example

```bash
adb::device::slot::suffix
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

### adb::device::build::kernel-version

Write the selected device kernel release.

#### Example

```bash
adb::device::build::kernel-version
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

### adb::device::screen::capture-continuous

Save repeated screenshots; MAX_COUNT of zero runs until interrupted.

#### Example

```bash
adb::device::screen::capture-continuous ./frames 0.5 20
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
* other The status of adb::device::screen::capture-once.

#### Output on stdout

* The path of each saved screenshot.

### adb::device::partition::sha256

Write a device partition SHA-256 checksum.

#### Example

```bash
adb::device::partition::sha256 /dev/block/by-name/boot_a
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

### adb::wake::lock

Hold a kernel wake lock using a tag, defaulting to debug.

The device must allow adb root.

#### Example

```bash
adb::wake::lock benchmark
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

### adb::wake::unlock

Release a kernel wake lock using the same tag.

The device must allow adb root.

#### Example

```bash
adb::wake::unlock benchmark
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

### adb::wake::list

Print active kernel wake locks.

#### Example

```bash
adb::wake::list
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

### adb::device::set-default

Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL.

#### Example

```bash
adb::device::set-default "$(adb::device::first)"
```

#### Arguments

* **$1** (string): Device serial.

#### Variables set

* **ANDROID_SERIAL** (is): exported in the current shell.

#### Exit codes

* **0**: The variable was set.
* **64**: The argument is not one valid serial.

### adb::server::start

Start the host ADB server.

#### Example

```bash
adb::server::start
```

_Function has no arguments._

#### Exit codes

* **0**: The server is running.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb start-server.

### adb::server::stop

Stop the host ADB server.

#### Example

```bash
adb::server::stop
```

_Function has no arguments._

#### Exit codes

* **0**: The server stopped.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb kill-server.

### adb::server::restart

Stop and then start the host ADB server.

#### Example

```bash
adb::server::restart
```

_Function has no arguments._

#### Exit codes

* **0**: The server was restarted.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb.

