# time

Clocks, timestamps, time zones, and waiting.

## Overview

Formats follow ISO 8601. Functions that need a clock provider return 69 when it is unavailable.

## Index

* [time::monotonic-milliseconds](#timemonotonic-milliseconds)
* [time::boot-time-milliseconds](#timeboot-time-milliseconds)
* [time::unix-milliseconds](#timeunix-milliseconds)
* [time::unix-seconds](#timeunix-seconds)
* [time::unix-days](#timeunix-days)
* [time::utc-date-time-milliseconds-extended](#timeutc-date-time-milliseconds-extended)
* [time::utc-date-time-seconds-extended](#timeutc-date-time-seconds-extended)
* [time::utc-date-extended](#timeutc-date-extended)
* [time::local-date-time-milliseconds-extended](#timelocal-date-time-milliseconds-extended)
* [time::local-date-time-seconds-extended](#timelocal-date-time-seconds-extended)
* [time::local-date-extended](#timelocal-date-extended)
* [time::local-date-time-seconds-basic](#timelocal-date-time-seconds-basic)
* [time::sleep-hours](#timesleep-hours)
* [time::posix-timezone](#timeposix-timezone)
* [time::status-continuous](#timestatus-continuous)

### time::monotonic-milliseconds

Write monotonic milliseconds that exclude suspended time.

Use it to measure elapsed time; the value has no fixed origin and does not
advance while the machine sleeps.

#### Example

```bash
start="$(time::monotonic-milliseconds)"
make build
printf '%s ms\n' "$(( $(time::monotonic-milliseconds) - start ))"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* Milliseconds of a monotonic clock.

### time::boot-time-milliseconds

Write milliseconds since boot including suspended time.

#### Example

```bash
time::boot-time-milliseconds
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* Milliseconds since the system started.

### time::unix-milliseconds

Write Unix-epoch milliseconds.

#### Example

```bash
time::unix-milliseconds
# 1791900000123
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* Milliseconds since 1970-01-01T00:00:00Z.

### time::unix-seconds

Write Unix-epoch seconds rounded down.

#### Example

```bash
expires=$(( $(time::unix-seconds) + 3600 ))
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* Seconds since 1970-01-01T00:00:00Z.

### time::unix-days

Write Unix-epoch days rounded down.

#### Example

```bash
time::unix-days
# 20739
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* Whole days since 1970-01-01.

### time::utc-date-time-milliseconds-extended

Write the current UTC date and time in ISO 8601 extended format with milliseconds.

#### Example

```bash
time::utc-date-time-milliseconds-extended
# 2026-10-14T03:04:05.678Z
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A time such as 2026-10-14T03:04:05.678Z.

### time::utc-date-time-seconds-extended

Write the current UTC date and time in ISO 8601 extended format with seconds.

#### Example

```bash
time::utc-date-time-seconds-extended
# 2026-10-14T03:04:05Z
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A time such as 2026-10-14T03:04:05Z.

### time::utc-date-extended

Write the current UTC date in ISO 8601 extended format.

#### Example

```bash
time::utc-date-extended
# 2026-10-14
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A date such as 2026-10-14.

### time::local-date-time-milliseconds-extended

Write the current local date and time in ISO 8601 extended format with milliseconds and an offset.

#### Example

```bash
time::local-date-time-milliseconds-extended
# 2026-10-14T12:04:05.678+09:00
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A time such as 2026-10-14T12:04:05.678+09:00.

### time::local-date-time-seconds-extended

Write the current local date and time in ISO 8601 extended format with seconds and an offset.

#### Example

```bash
log_line="$(time::local-date-time-seconds-extended) started"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A time such as 2026-10-14T12:04:05+09:00.

### time::local-date-extended

Write the current local date in ISO 8601 extended format.

#### Example

```bash
mkdir -p "backup/$(time::local-date-extended)"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A date such as 2026-10-14.

### time::local-date-time-seconds-basic

Write the current local date and time in ISO 8601 basic format with seconds.

The basic format has no separators, so it suits file names.

#### Example

```bash
cp config.yaml "config.yaml.$(time::local-date-time-seconds-basic)"
```

_Function has no arguments._

#### Exit codes

* **0**: The value was written.
* **64**: An argument was given.
* **69**: Perl with Time::HiRes, the clock provider, is unavailable.

#### Output on stdout

* A time such as 20261014T120405.

### time::sleep-hours

Sleep for a non-negative integer number of hours.

#### Example

```bash
time::sleep-hours 2 && make release
```

#### Arguments

* **$1** (integer): Number of hours, 0 or more.

#### Exit codes

* **0**: The time passed.
* **64**: The value is not a non-negative integer.
* **69**: sleep is unavailable.

### time::posix-timezone

Write the POSIX TZ string for a UTC offset.

POSIX TZ offsets have the opposite sign of ISO 8601 offsets, so +09:30
becomes UTC-9:30 and -05:00 becomes UTC+5.

#### Example

```bash
time::posix-timezone +09:00
# UTC-9
```

#### Arguments

* **$1** (string): OFFSET Z or an offset in the form +HH:MM or -HH:MM, with HH up to 23 and MM up to 59.

#### Exit codes

* **0**: The value was written.
* **64**: The offset is malformed or out of range.

#### Output on stdout

* The TZ value, such as UTC-9 or UTC+5:30.

### time::status-continuous

Write the elapsed time since boot and the local time every three seconds until stopped.

#### Example

```bash
time::status-continuous   # Stop with Ctrl-C.
```

_Function has no arguments._

#### Exit codes

* **64**: An argument was given.
* **74**: sleep failed.
* other The status of the clock function that failed.

#### Output on stdout

* Two lines every three seconds: the seconds since boot and the local date and time.

