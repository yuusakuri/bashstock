# screen

GNU Screen sessions.

## Overview

Sessions are opened, attached to serial devices, and ended.

## Index

* [screen::open](#screenopen)
* [screen::open-serial](#screenopen-serial)
* [screen::kill-all](#screenkill-all)

### screen::open

Open a GNU Screen session.

#### Example

```bash
screen::open build
```

#### Arguments

* **$1** (string): Optional session name. Defaults to default.

#### Exit codes

* **0**: The session ended successfully.
* **64**: More than one argument was given.
* **69**: screen is unavailable.
* other The status of screen.

### screen::open-serial

Open a serial device in GNU Screen through administrator execution and log the session.

#### Example

```bash
TTY_LOG_DIR="${HOME}/logs" screen::open-serial /dev/ttyUSB0
```

#### Arguments

* **$1** (string): Serial device path.
* **$2** (integer): Optional baud rate. Defaults to 115200.
* **$3** (string): Optional log file. Defaults to a file named with the date and time in ${TTY_LOG_DIR:-.}.

#### Exit codes

* **0**: The session ended successfully.
* **64**: The arguments are invalid.
* **69**: screen is unavailable.
* **74**: The log directory could not be created.
* other The status of screen.

### screen::kill-all

End every GNU Screen process of every user through administrator execution.

Having no Screen process is a success.

#### Example

```bash
screen::kill-all
```

_Function has no arguments._

#### Exit codes

* **0**: No Screen process remains.
* **64**: An argument was given.
* **69**: pkill is unavailable.
* other The status of pkill.

