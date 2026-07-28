#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

time::__clock-milliseconds() {
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
    linux:boottime)
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
    darwin:boottime)
      perl -MTime::HiRes=clock_gettime,CLOCK_MONOTONIC_RAW \
        -e 'printf "%d\n", int(clock_gettime(CLOCK_MONOTONIC_RAW) * 1000)' \
        2>/dev/null || return 69
      ;;
    *)
      return 69
      ;;
  esac
}

time::__realtime-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  command -v perl >/dev/null 2>&1 || return 69
  perl -MTime::HiRes=time -e 'printf "%d\n", int(time() * 1000)' 2>/dev/null ||
    return 69
}

time::__format-milliseconds() {
  if [[ "$#" -ne 2 ]] || ! core::__is-non-negative-integer "$1"; then
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
    if ($mode eq "utc-ms") {
      $base = strftime("%Y-%m-%dT%H:%M:%S", gmtime($seconds));
      printf "%s.%03dZ\n", $base, $fraction;
    } elsif ($mode eq "utc-s") {
      print strftime("%Y-%m-%dT%H:%M:%SZ", gmtime($seconds)), "\n";
    } elsif ($mode eq "utc-date") {
      print strftime("%Y-%m-%d", gmtime($seconds)), "\n";
    } elsif ($mode eq "local-ms" || $mode eq "local-s") {
      my @local = localtime($seconds);
      $base = strftime("%Y-%m-%dT%H:%M:%S", @local);
      $offset = strftime("%z", @local);
      $offset =~ s/([+-][0-9]{2})([0-9]{2})\z/$1:$2/;
      exit 69 unless $offset =~ /\A[+-][0-9]{2}:[0-9]{2}\z/;
      if ($mode eq "local-ms") {
        printf "%s.%03d%s\n", $base, $fraction, $offset;
      } else {
        print $base, $offset, "\n";
      }
    } elsif ($mode eq "local-date") {
      print strftime("%Y-%m-%d", localtime($seconds)), "\n";
    } else {
      exit 64;
    }
  ' -- "$1" "$2" 2>/dev/null || {
    local status="$?"
    [[ "${status}" -eq 64 ]] && return 64
    return 69
  }
}

time::__provider-error() {
  core::__error 'The portable time provider is unavailable.'
  return 69
}

time::monotonic-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::__clock-milliseconds monotonic || time::__provider-error
}

time::boottime-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::__clock-milliseconds boottime || time::__provider-error
}

time::unix-milliseconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  time::__realtime-milliseconds || time::__provider-error
}

time::unix-seconds() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  local milliseconds=''
  milliseconds="$(time::__realtime-milliseconds)" || {
    time::__provider-error
    return 69
  }
  printf '%s\n' "$((milliseconds / 1000))"
}

time::unix-days() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  local milliseconds=''
  milliseconds="$(time::__realtime-milliseconds)" || {
    time::__provider-error
    return 69
  }
  printf '%s\n' "$((milliseconds / 86400000))"
}

time::__date-time() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  local milliseconds=''
  milliseconds="$(time::__realtime-milliseconds)" || {
    time::__provider-error
    return 69
  }
  time::__format-milliseconds "${milliseconds}" "$1" || {
    local status="$?"
    [[ "${status}" -eq 64 ]] && return 64
    time::__provider-error
    return 69
  }
}

time::utc-date-time-milliseconds() {
  [[ "$#" -eq 0 ]] || return 64
  time::__date-time utc-ms
}

time::utc-date-time-seconds() {
  [[ "$#" -eq 0 ]] || return 64
  time::__date-time utc-s
}

time::utc-date() {
  [[ "$#" -eq 0 ]] || return 64
  time::__date-time utc-date
}

time::local-date-time-milliseconds() {
  [[ "$#" -eq 0 ]] || return 64
  time::__date-time local-ms
}

time::local-date-time-seconds() {
  [[ "$#" -eq 0 ]] || return 64
  time::__date-time local-s
}

time::local-date() {
  [[ "$#" -eq 0 ]] || return 64
  time::__date-time local-date
}
