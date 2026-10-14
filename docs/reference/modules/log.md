# log

Timestamped log messages on standard error.

## Overview

Each line is written as TIMESTAMP [LEVEL] [COMMAND] MESSAGE.

## Index

* [log::info](#loginfo)
* [log::warn](#logwarn)
* [log::error](#logerror)

### log::info

Write an informational log message.

Each line of the message becomes one standard-error line with the local time,
the level, and BASHSTOCK_NAME.

#### Example

```bash
BASHSTOCK_NAME=deploy log::info 'Uploading the release.'
```

#### Arguments

* **$1** (string): Message; a multiline message is written line by line.

#### Exit codes

* **0**: The message was written.
* **64**: The argument count is not one.
* **69**: The clock provider for the timestamp is unavailable.

#### Output on stderr

* Lines such as 2026-10-14T12:04:05.678+09:00 [INFO] [bashstock] message.

### log::warn

Write a warning log message.

#### Example

```bash
log::warn 'The cache is older than one day.'
```

#### Arguments

* **$1** (string): Message; a multiline message is written line by line.

#### Exit codes

* **0**: The message was written.
* **64**: The argument count is not one.
* **69**: The clock provider for the timestamp is unavailable.

#### Output on stderr

* Lines such as 2026-10-14T12:04:05.678+09:00 [WARN] [bashstock] message.

### log::error

Write an error log message without exiting.

#### Example

```bash
docker::install || log::error 'Docker could not be installed.'
```

#### Arguments

* **$1** (string): Message; a multiline message is written line by line.

#### Exit codes

* **0**: The message was written.
* **64**: The argument count is not one.
* **69**: The clock provider for the timestamp is unavailable.

#### Output on stderr

* Lines such as 2026-10-14T12:04:05.678+09:00 [ERROR] [bashstock] message.

