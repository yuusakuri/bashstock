# serial

Serial device configuration and writing.

## Overview

Devices are configured with stty and written to directly.

## Index

* [serial__configure](#serial__configure)
* [serial__write](#serial__write)
* [serial__write-command](#serial__write-command)
* [serial__release](#serial__release)

### serial__configure

Open a serial device with a configured baud rate.

#### Example

```bash
serial__configure /dev/ttyUSB0 9600
```

#### Arguments

* **$1** (string): Serial device.
* **$2** (integer): Optional baud rate. Defaults to 115200.

#### Exit codes

* **0**: The baud rate was set.
* **64**: The arguments are invalid or the device does not exist.
* **69**: stty is unavailable.
* other The status of stty.

### serial__write

Write literal data to a serial device.

#### Example

```bash
serial__write /dev/ttyUSB0 'AT'
```

#### Arguments

* **$1** (string): Serial device.
* **$2** (string): Data to write without a terminator.

#### Exit codes

* **0**: The data was written.
* **1**: The device could not be written.
* **64**: The argument count is not two or the device does not exist.

### serial__write-command

Write a command and terminator to a serial device.

#### Example

```bash
serial__write-command /dev/ttyUSB0 'AT+GMR' crlf 0.5
```

#### Arguments

* **$1** (string): Serial device.
* **$2** (string): Command to write.
* **$3** (string): Optional terminator: none, cr, lf, or crlf. Defaults to cr.
* **$4** (number): Optional seconds to wait after writing. Defaults to 0.

#### Exit codes

* **0**: The command was written.
* **64**: The arguments, terminator, or wait time are invalid.
* **74**: The device could not be written.

### serial__release

Release a serial device so another process, such as a Python tool, can open it.

The reference implementation called file-close on the device, which
killed every holder at once; this follows file__release instead: SIGTERM
first, SIGKILL only for holders left after the timeout.

#### Example

```bash
serial__release /dev/ttyACM0 && esptool.py --port /dev/ttyACM0 chip_id
```

#### Arguments

* **$1** (string): Serial device path.
* **$2** (integer): Optional seconds to wait after SIGTERM. Defaults to 2.

#### Exit codes

* **0**: No process holds the device.
* **64**: The arguments are invalid or the device does not exist.
* other The status of file__release.

