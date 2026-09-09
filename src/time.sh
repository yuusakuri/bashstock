#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### Write milliseconds from the requested monotonic clock.
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

### Write Unix-epoch milliseconds from the real-time clock.
time::_realtime-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  command -v perl >/dev/null 2>&1 || return 69
  perl -MTime::HiRes=time -e 'printf "%d\n", int(time() * 1000)' 2>/dev/null ||
    return 69
}

### Format an epoch-millisecond value in a fixed date-time form.
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

### Report that the portable time provider is unavailable.
time::_provider-error() {
  console::_write-error 'The portable time provider is unavailable.'
  return 69
}

### Write monotonic milliseconds that exclude suspended time.
time::monotonic-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::_clock-milliseconds monotonic || time::_provider-error
}

### Write milliseconds since boot including suspended time.
time::boot-time-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::_clock-milliseconds boot-time || time::_provider-error
}

### Write Unix-epoch milliseconds.
time::unix-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::_realtime-milliseconds || time::_provider-error
}

### Write Unix-epoch seconds rounded down.
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

### Write Unix-epoch days rounded down.
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

### Format the current real-time clock in a requested date-time form.
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

### Write the current UTC date and time in ISO 8601 extended format with milliseconds.
time::utc-date-time-milliseconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time utc-ms-extended
}

### Write the current UTC date and time in ISO 8601 extended format with seconds.
time::utc-date-time-seconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time utc-s-extended
}

### Write the current UTC date in ISO 8601 extended format.
time::utc-date-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time utc-date-extended
}

### Write the current local date and time in ISO 8601 extended format with milliseconds and an offset.
time::local-date-time-milliseconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-ms-extended
}

### Write the current local date and time in ISO 8601 extended format with seconds and an offset.
time::local-date-time-seconds-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-s-extended
}

### Write the current local date in ISO 8601 extended format.
time::local-date-extended() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-date-extended
}

### Write the current local date and time in ISO 8601 basic format with seconds.
time::local-date-time-seconds-basic() {
  [[ "$#" -eq 0 ]] || return 64
  time::_date-time local-s-basic
}
