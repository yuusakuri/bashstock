#!/usr/bin/env bash
# @file time
# @brief Clocks, timestamps, time zones, and waiting.
# @description Formats follow ISO 8601. Functions that need a clock provider return 69 when it is unavailable.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write milliseconds from the requested monotonic clock.
# @internal
time::_clock-milliseconds() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi


  local operating_system=''
  operating_system="$(system::operating-system)" || return 69
  case "${operating_system}:$1" in
    linux:monotonic)
      python::run -c 'import time; print(int(time.clock_gettime(time.CLOCK_MONOTONIC) * 1000))' 2>/dev/null || return 69
      ;;
    linux:boot-time)
      python::run -c '
import re
try:
    with open("/proc/uptime", encoding="ascii") as stream:
        line = stream.readline()
    match = re.match(r"^([0-9]+)(?:\.([0-9]+))?\s", line)
    if not match:
        raise ValueError()
    fraction = (match.group(2) or "") + "000"
    print(int(match.group(1)) * 1000 + int(fraction[:3]))
except (OSError, ValueError):
    raise SystemExit(69)
' 2>/dev/null || return 69
      ;;
    darwin:monotonic)
      # Python 3.8 added CLOCK_UPTIME_RAW; earlier versions take its value 8 from macOS <time.h>.
      python::run -c 'import time; print(int(time.clock_gettime(getattr(time, "CLOCK_UPTIME_RAW", 8)) * 1000))' 2>/dev/null || return 69
      ;;
    darwin:boot-time)
      # Python builds without CLOCK_MONOTONIC_RAW take its value 4 from macOS <time.h>.
      python::run -c 'import time; print(int(time.clock_gettime(getattr(time, "CLOCK_MONOTONIC_RAW", 4)) * 1000))' 2>/dev/null || return 69
      ;;
    *)
      return 69
      ;;
  esac
}

# @description Write Unix-epoch milliseconds from the real-time clock.
# @internal
time::_realtime-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  python::run -c 'import time; print(int(time.time() * 1000))' 2>/dev/null ||
    return 69
}

# @description Format an epoch-millisecond value in a fixed date-time form.
# @internal
time::_format-milliseconds() {
  if [[ "$#" -ne 2 ]] || ! number::_is-non-negative-integer "$1"; then
    return 64
  fi

  python::run -c '
import datetime
import re
import sys
milliseconds, mode = sys.argv[1:]
if not re.fullmatch(r"[0-9]+", milliseconds):
    sys.exit(64)
milliseconds = int(milliseconds)
seconds, fraction = divmod(milliseconds, 1000)
try:
    if mode.startswith("utc-"):
        value = datetime.datetime.fromtimestamp(seconds, datetime.timezone.utc)
    else:
        value = datetime.datetime.fromtimestamp(seconds).astimezone()
except (OverflowError, OSError, ValueError):
    sys.exit(69)
if mode == "utc-ms-extended":
    print(value.strftime("%Y-%m-%dT%H:%M:%S") + ".%03dZ" % fraction)
elif mode == "utc-s-extended":
    print(value.strftime("%Y-%m-%dT%H:%M:%SZ"))
elif mode == "utc-date-extended":
    print(value.strftime("%Y-%m-%d"))
elif mode in ("local-ms-extended", "local-s-extended"):
    offset = value.strftime("%z")
    if not re.fullmatch(r"[+-][0-9]{4}", offset):
        sys.exit(69)
    offset = offset[:3] + ":" + offset[3:]
    base = value.strftime("%Y-%m-%dT%H:%M:%S")
    if mode == "local-ms-extended":
        print(base + ".%03d" % fraction + offset)
    else:
        print(base + offset)
elif mode == "local-date-extended":
    print(value.strftime("%Y-%m-%d"))
elif mode == "local-s-basic":
    print(value.strftime("%Y%m%dT%H%M%S"))
else:
    sys.exit(64)
' "$1" "$2" 2>/dev/null || {
    local status="$?"
    [[ "${status}" -eq 64 ]] && return 64
    return 69
  }
}

# @description Report that the portable time provider is unavailable.
# @internal
time::_provider-error() {
  console::_write-error 'The portable time provider is unavailable.'
  return 69
}

# @description Write monotonic milliseconds that exclude suspended time.
#
# Use it to measure elapsed time; the value has no fixed origin and does not
# advance while the machine sleeps.
#
# @noargs
# @stdout Milliseconds of a monotonic clock.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   start="$(time::monotonic-milliseconds)"
#   make build
#   printf '%s ms\n' "$(( $(time::monotonic-milliseconds) - start ))"
time::monotonic-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::_clock-milliseconds monotonic || time::_provider-error
}

# @description Write milliseconds since boot including suspended time.
#
# @noargs
# @stdout Milliseconds since the system started.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::boot-time-milliseconds
time::boot-time-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::_clock-milliseconds boot-time || time::_provider-error
}

# @description Write Unix-epoch milliseconds.
#
# @noargs
# @stdout Milliseconds since 1970-01-01T00:00:00Z.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::unix-milliseconds
#   # 1791900000123
time::unix-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::_realtime-milliseconds || time::_provider-error
}

# @description Write Unix-epoch seconds rounded down.
#
# @noargs
# @stdout Seconds since 1970-01-01T00:00:00Z.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   expires=$(( $(time::unix-seconds) + 3600 ))
time::unix-seconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  local milliseconds=''
  milliseconds="$(time::_realtime-milliseconds)" || {
    time::_provider-error
    return 69
  }
  printf '%s\n' "$((milliseconds / 1000))"
}

# @description Write Unix-epoch days rounded down.
#
# @noargs
# @stdout Whole days since 1970-01-01.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::unix-days
#   # 20739
time::unix-days() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  local milliseconds=''
  milliseconds="$(time::_realtime-milliseconds)" || {
    time::_provider-error
    return 69
  }
  printf '%s\n' "$((milliseconds / 86400000))"
}

# @description Format the current real-time clock in a requested date-time form.
# @internal
time::_date-time() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  local milliseconds=''
  milliseconds="$(time::_realtime-milliseconds)" || {
    time::_provider-error
    return 69
  }
  time::_format-milliseconds "${milliseconds}" "$1" || {
    local status="$?"
    [[ "${status}" -eq 64 ]] && return 64
    time::_provider-error
    return 69
  }
}

# @description Write the current UTC date and time in ISO 8601 extended format with milliseconds.
#
# @noargs
# @stdout A time such as 2026-10-14T03:04:05.678Z.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::utc-date-time-milliseconds-extended
#   # 2026-10-14T03:04:05.678Z
time::utc-date-time-milliseconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time utc-ms-extended
}

# @description Write the current UTC date and time in ISO 8601 extended format with seconds.
#
# @noargs
# @stdout A time such as 2026-10-14T03:04:05Z.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::utc-date-time-seconds-extended
#   # 2026-10-14T03:04:05Z
time::utc-date-time-seconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time utc-s-extended
}

# @description Write the current UTC date in ISO 8601 extended format.
#
# @noargs
# @stdout A date such as 2026-10-14.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::utc-date-extended
#   # 2026-10-14
time::utc-date-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time utc-date-extended
}

# @description Write the current local date and time in ISO 8601 extended format with milliseconds and an offset.
#
# @noargs
# @stdout A time such as 2026-10-14T12:04:05.678+09:00.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   time::local-date-time-milliseconds-extended
#   # 2026-10-14T12:04:05.678+09:00
time::local-date-time-milliseconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-ms-extended
}

# @description Write the current local date and time in ISO 8601 extended format with seconds and an offset.
#
# @noargs
# @stdout A time such as 2026-10-14T12:04:05+09:00.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   log_line="$(time::local-date-time-seconds-extended) started"
time::local-date-time-seconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-s-extended
}

# @description Write the current local date in ISO 8601 extended format.
#
# @noargs
# @stdout A date such as 2026-10-14.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   mkdir -p "backup/$(time::local-date-extended)"
time::local-date-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-date-extended
}

# @description Write the current local date and time in ISO 8601 basic format with seconds.
#
# The basic format has no separators, so it suits file names.
#
# @noargs
# @stdout A time such as 20261014T120405.
# @exitcode 0 The value was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or the requested clock provider is unavailable.
# @example
#   cp config.yaml "config.yaml.$(time::local-date-time-seconds-basic)"
time::local-date-time-seconds-basic() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-s-basic
}

# @description Sleep for a non-negative integer number of hours.
#
# @arg $1 integer Number of hours, 0 or more.
# @exitcode 0 The time passed.
# @exitcode 64 The value is not a non-negative integer.
# @exitcode 69 sleep is unavailable.
# @example
#   time::sleep-hours 2 && make release
time::sleep-hours() {
  if ( [[ "$#" -ne 1 || ! "$1" =~ ^(0|[1-9][0-9]*)$ ]] ); then return 64; fi
  command -v sleep >/dev/null 2>&1 || return 69
  sleep "$((10#$1 * 3600))"
}

# @description Write the POSIX TZ string for a UTC offset.
#
# POSIX TZ offsets have the opposite sign of ISO 8601 offsets, so +09:30
# becomes UTC-9:30 and -05:00 becomes UTC+5.
#
# @arg $1 string OFFSET Z or an offset in the form +HH:MM or -HH:MM, with HH up to 23 and MM up to 59.
# @stdout The TZ value, such as UTC-9 or UTC+5:30.
# @exitcode 0 The value was written.
# @exitcode 64 The offset is malformed or out of range.
# @example
#   time::posix-timezone +09:00
#   # UTC-9
time::posix-timezone() {
  [[ "$#" -eq 1 ]] || return 64
  local sign='' hours=0 minutes=0 text=''
  if [[ "$1" == Z ]]; then
    printf 'UTC0\n'
    return 0
  fi
  ( [[ "$1" =~ ^[+-][0-9]{2}:[0-9]{2}$ ]] ) || return 64
  sign="${1:0:1}"
  hours=$((10#${1:1:2}))
  minutes=$((10#${1:4:2}))
  ((hours <= 23 && minutes <= 59)) || return 64
  if ((hours == 0 && minutes == 0)); then
    printf 'UTC0\n'
    return 0
  fi
  if [[ "${sign}" == + ]]; then sign='-'; else sign='+'; fi
  text="UTC${sign}${hours}"
  ((minutes == 0)) || text+="$(printf ':%02d' "${minutes}")"
  printf '%s\n' "${text}"
}

# @description Write the elapsed time since boot and the local time every three seconds until stopped.
#
# @noargs
# @stdout Two lines every three seconds: the seconds since boot and the local date and time.
# @exitcode 64 An argument was given.
# @exitcode 74 sleep failed.
# @exitcode other The status of the clock function that failed.
# @example
#   time::status-continuous   # Stop with Ctrl-C.
time::status-continuous() {
  [[ "$#" -eq 0 ]] || return 64
  local milliseconds='' now=''
  while :; do
    milliseconds="$(time::boot-time-milliseconds)" || return "$?"
    now="$(time::local-date-time-seconds-extended)" || return "$?"
    printf 'Seconds since boot: %d.%03d\nLocal date and time: %s\n' \
      "$((milliseconds / 1000))" "$((milliseconds % 1000))" "${now}"
    sleep 3 || return 74
  done
}
