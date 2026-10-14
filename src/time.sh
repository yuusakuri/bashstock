#!/usr/bin/env bash
# @file time
# @brief Clocks, timestamps, and waiting.
# @description Formats follow ISO 8601. Functions that need a clock provider return 69 when it is unavailable.

# shellcheck disable=SC2119,SC2120

# @description Write milliseconds from the requested monotonic clock.
# @internal
time::_clock-milliseconds() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  command -v perl >/dev/null 2>&1 || return 69

  local operating_system=''
  operating_system="$(system::operating-system)" || return 69
  case "${operating_system}:$1" in
    linux:monotonic)
      perl -MTime::HiRes=clock_gettime,CLOCK_MONOTONIC \
        -e 'printf "%d\n", int(clock_gettime(CLOCK_MONOTONIC) * 1000)' \
        2>/dev/null || return 69
      ;;
    linux:boot-time)
      perl -e '
        use strict;
        use warnings;

        open my $input, "<", "/proc/uptime" or exit 69;
        my $line = <$input>;
        close $input or exit 69;
        exit 69 unless defined($line)
          && $line =~ /\A([0-9]+)(?:\.([0-9]+))?[[:space:]]/;

        my $seconds = $1;
        my $fraction = defined($2) ? $2 : "";
        $fraction .= "000";
        printf "%d\n", ($seconds * 1000) + substr($fraction, 0, 3);
      ' 2>/dev/null || return 69
      ;;
    darwin:monotonic)
      perl -MTime::HiRes=clock_gettime,CLOCK_UPTIME_RAW \
        -e 'printf "%d\n", int(clock_gettime(CLOCK_UPTIME_RAW) * 1000)' \
        2>/dev/null || return 69
      ;;
    darwin:boot-time)
      perl -MTime::HiRes=clock_gettime,CLOCK_MONOTONIC_RAW \
        -e 'printf "%d\n", int(clock_gettime(CLOCK_MONOTONIC_RAW) * 1000)' \
        2>/dev/null || return 69
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
  command -v perl >/dev/null 2>&1 || return 69
  perl -MTime::HiRes=time -e 'printf "%d\n", int(time() * 1000)' 2>/dev/null ||
    return 69
}

# @description Format an epoch-millisecond value in a fixed date-time form.
# @internal
time::_format-milliseconds() {
  if [[ "$#" -ne 2 ]] || ! number::_is-non-negative-integer "$1"; then
    return 64
  fi
  command -v perl >/dev/null 2>&1 || return 69

  perl -MPOSIX=strftime -e '
    use strict;
    use warnings;
    my ($milliseconds, $mode) = @ARGV;
    exit 64 unless defined $milliseconds && $milliseconds =~ /\A[0-9]+\z/;
    my $seconds = int($milliseconds / 1000);
    my $fraction = $milliseconds % 1000;
    my ($base, $offset);
    if ($mode eq "utc-ms-extended") {
      $base = strftime("%Y-%m-%dT%H:%M:%S", gmtime($seconds));
      printf "%s.%03dZ\n", $base, $fraction;
    } elsif ($mode eq "utc-s-extended") {
      print strftime("%Y-%m-%dT%H:%M:%SZ", gmtime($seconds)), "\n";
    } elsif ($mode eq "utc-date-extended") {
      print strftime("%Y-%m-%d", gmtime($seconds)), "\n";
    } elsif ($mode eq "local-ms-extended" || $mode eq "local-s-extended") {
      my @local = localtime($seconds);
      $base = strftime("%Y-%m-%dT%H:%M:%S", @local);
      $offset = strftime("%z", @local);
      $offset =~ s/([+-][0-9]{2})([0-9]{2})\z/$1:$2/;
      exit 69 unless $offset =~ /\A[+-][0-9]{2}:[0-9]{2}\z/;
      if ($mode eq "local-ms-extended") {
        printf "%s.%03d%s\n", $base, $fraction, $offset;
      } else {
        print $base, $offset, "\n";
      }
    } elsif ($mode eq "local-date-extended") {
      print strftime("%Y-%m-%d", localtime($seconds)), "\n";
    } elsif ($mode eq "local-s-basic") {
      print strftime("%Y%m%dT%H%M%S", localtime($seconds)), "\n";
    } else {
      exit 64;
    }
  ' -- "$1" "$2" 2>/dev/null || {
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
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
# @exitcode 69 Perl with Time::HiRes, the clock provider, is unavailable.
# @example
#   cp config.yaml "config.yaml.$(time::local-date-time-seconds-basic)"
time::local-date-time-seconds-basic() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-s-basic
}
