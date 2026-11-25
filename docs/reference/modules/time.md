# time

Clocks, timestamps, time zones, and waiting.

## Overview

Formats follow ISO 8601. Functions that need a clock provider return 69 when it is unavailable.

## Index

* [time__monotonic-milliseconds](#time__monotonic-milliseconds)
* [time__boot-time-milliseconds](#time__boot-time-milliseconds)
* [time__unix-milliseconds](#time__unix-milliseconds)
* [time__unix-seconds](#time__unix-seconds)
* [time__unix-days](#time__unix-days)
* [time__utc-date-time-milliseconds-extended](#time__utc-date-time-milliseconds-extended)
* [time__utc-date-time-seconds-extended](#time__utc-date-time-seconds-extended)
* [time__utc-date-extended](#time__utc-date-extended)
* [time__local-date-time-milliseconds-extended](#time__local-date-time-milliseconds-extended)
* [time__local-date-time-seconds-extended](#time__local-date-time-seconds-extended)
* [time__local-date-extended](#time__local-date-extended)
* [time__local-date-time-seconds-basic](#time__local-date-time-seconds-basic)
* [time__sleep-hours](#time__sleep-hours)
* [time__posix-timezone](#time__posix-timezone)
* [time__status-continuous](#time__status-continuous)

### time__monotonic-milliseconds

Write monotonic milliseconds that exclude suspended time.

Use it to measure elapsed time; the value has no fixed origin and does not
advance while the machine sleeps.

#### Example

```bash
start="$(time__monotonic-milliseconds)"
make build
printf '%s ms\n' "$(( $(time__monotonic-milliseconds) - start ))"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* Milliseconds of a monotonic clock.

### time__boot-time-milliseconds

Write milliseconds since boot including suspended time.

#### Example

```bash
time__boot-time-milliseconds
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* Milliseconds since the system started.

### time__unix-milliseconds

Write Unix-epoch milliseconds.

#### Example

```bash
time__unix-milliseconds
# 1791900000123
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* Milliseconds since 1970-01-01T00:00:00Z.

### time__unix-seconds

Write Unix-epoch seconds rounded down.

#### Example

```bash
expires=$(( $(time__unix-seconds) + 3600 ))
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* Seconds since 1970-01-01T00:00:00Z.

### time__unix-days

Write Unix-epoch days rounded down.

#### Example

```bash
time__unix-days
# 20739
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* Whole days since 1970-01-01.

### time__utc-date-time-milliseconds-extended

Write the current UTC date and time in ISO 8601 extended format with milliseconds.

#### Example

```bash
time__utc-date-time-milliseconds-extended
# 2026-10-14T03:04:05.678Z
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A time such as 2026-10-14T03:04:05.678Z.

### time__utc-date-time-seconds-extended

Write the current UTC date and time in ISO 8601 extended format with seconds.

#### Example

```bash
time__utc-date-time-seconds-extended
# 2026-10-14T03:04:05Z
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A time such as 2026-10-14T03:04:05Z.

### time__utc-date-extended

Write the current UTC date in ISO 8601 extended format.

#### Example

```bash
time__utc-date-extended
# 2026-10-14
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A date such as 2026-10-14.

### time__local-date-time-milliseconds-extended

Write the current local date and time in ISO 8601 extended format with milliseconds and an offset.

#### Example

```bash
time__local-date-time-milliseconds-extended
# 2026-10-14T12:04:05.678+09:00
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A time such as 2026-10-14T12:04:05.678+09:00.

### time__local-date-time-seconds-extended

Write the current local date and time in ISO 8601 extended format with seconds and an offset.

#### Example

```bash
log_line="$(time__local-date-time-seconds-extended) started"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A time such as 2026-10-14T12:04:05+09:00.

### time__local-date-extended

Write the current local date in ISO 8601 extended format.

#### Example

```bash
mkdir -p "backup/$(time__local-date-extended)"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A date such as 2026-10-14.

### time__local-date-time-seconds-basic

Write the current local date and time in ISO 8601 basic format with seconds.

The basic format has no separators, so it suits file names.

#### Example

```bash
cp config.yaml "config.yaml.$(time__local-date-time-seconds-basic)"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Python 3 or the requested clock provider is unavailable.

#### Output on stdout

* A time such as 20261014T120405.

### time__sleep-hours

Sleep for a non-negative integer number of hours.

#### Example

```bash
time__sleep-hours 2 && make release
```

#### Arguments

* **$1** (integer): Number of hours, 0 or more.

#### Exit codes

* **0**: The time passed.
* **64**: The value is not a non-negative integer.
* **69**: sleep is unavailable.

### time__posix-timezone

Write the POSIX TZ string for a UTC offset.

POSIX TZ offsets have the opposite sign of ISO 8601 offsets, so +09:30
becomes UTC-9:30 and -05:00 becomes UTC+5.

#### Example

```bash
time__posix-timezone +09:00
# UTC-9
```

#### Arguments

* **$1** (string): OFFSET Z or an offset in the form +HH:MM or -HH:MM, with HH up to 23 and MM up to 59.

#### Exit codes

* **0**: The value was written.
* **64**: The offset is malformed or out of range.

#### Output on stdout

* The TZ value, such as UTC-9 or UTC+5:30.

### time__status-continuous

Write the elapsed time since boot and the local time every three seconds until stopped.

#### Example

```bash
time__status-continuous   # Stop with Ctrl-C.
```

_Function has no arguments._

#### Exit codes

* **64**: An argument was given.
* **74**: sleep failed.
* other The status of the clock function that failed.

#### Output on stdout

* Two lines every three seconds: the seconds since boot and the local date and time.

