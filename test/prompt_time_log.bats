#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "confirmation normalizes one input line" {
  run --separate-stderr shell::confirm 'Continue' yes <<<"Y"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'yes' ]
  [ "${stderr}" = 'Continue [yes/no]:' ]

  run --separate-stderr shell::confirm 'Continue' no <<<""
  [ "${status}" -eq 0 ]
  [ "${output}" = 'no' ]

  run --separate-stderr shell::confirm 'Continue' <<<"maybe"
  [ "${status}" -eq 64 ]
}

@test "line input uses the default only for empty input" {
  run shell::read-line 'Name' default <<<"value\\path"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'value\path' ]]

  run shell::read-line 'Name' default <<<""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'default' ]]
}

@test "cancel confirmation and selection normalize results" {
  run shell::confirm-or-cancel 'Continue' cancel <<<"C"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'cancel' ]]

  run shell::choose-one 'Choose' first 'second value' <<<"2"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'second value' ]]

  run shell::choose-one 'Choose' first second <<<"3"
  [ "${status}" -eq 64 ]
}

@test "time functions format one fixed real-time value" {
  time::_realtime-milliseconds() {
    printf '0\n'
  }

  run time::utc-date-time-milliseconds-extended
  [ "${output}" = '1970-01-01T00:00:00.000Z' ]
  run time::utc-date-time-seconds-extended
  [ "${output}" = '1970-01-01T00:00:00Z' ]
  run time::utc-date-extended
  [ "${output}" = '1970-01-01' ]
  run time::unix-milliseconds
  [ "${output}" = '0' ]
  run time::unix-seconds
  [ "${output}" = '0' ]
  run time::unix-days
  [ "${output}" = '0' ]

  export TZ='Asia/Tokyo'
  run time::local-date-time-milliseconds-extended
  [ "${output}" = '1970-01-01T09:00:00.000+09:00' ]
  run time::local-date-time-seconds-extended
  [ "${output}" = '1970-01-01T09:00:00+09:00' ]
  run time::local-date-extended
  [ "${output}" = '1970-01-01' ]
  run time::local-date-time-seconds-basic
  [ "${output}" = '19700101T090000' ]
}

@test "monotonic and boot-time clocks return milliseconds" {
  run time::monotonic-milliseconds
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]

  run time::boot-time-milliseconds
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "time functions start Python once per call" {
  local site="${BATS_TEST_TMPDIR}/site"
  # Clocks are read in polling loops, so every extra interpreter start delays each round.
  mkdir -p "${site}"
  printf '%s\n' 'import os' 'with open(os.environ["PYTHON_START_LOG"], "a") as log:' '    log.write("start\n")' \
    >"${site}/sitecustomize.py"
  export PYTHONPATH="${site}" PYTHON_START_LOG="${BATS_TEST_TMPDIR}/starts.log"

  run time::unix-milliseconds
  [ "${status}" -eq 0 ]
  [ "$(wc -l <"${PYTHON_START_LOG}")" -eq 1 ]
}

@test "macOS clocks keep reading the same clocks on Python without the macOS clock constants" {
  [[ "$(uname -s)" == Darwin ]] || skip 'The clock constants exist only on macOS.'
  local monotonic='' boot='' site="${BATS_TEST_TMPDIR}/site"
  monotonic="$(time::monotonic-milliseconds)"
  boot="$(time::boot-time-milliseconds)"

  # Python 3.6 and 3.7 lack CLOCK_UPTIME_RAW, and some builds lack CLOCK_MONOTONIC_RAW.
  mkdir -p "${site}"
  printf '%s\n' 'import time' 'del time.CLOCK_UPTIME_RAW' 'del time.CLOCK_MONOTONIC_RAW' >"${site}/sitecustomize.py"
  export PYTHONPATH="${site}"
  python3 -c 'import sys, time; sys.exit(hasattr(time, "CLOCK_UPTIME_RAW") or hasattr(time, "CLOCK_MONOTONIC_RAW"))'

  # The clocks without sleep time and with it differ, so a wrong clock moves the value far.
  run time::monotonic-milliseconds
  [ "${status}" -eq 0 ]
  ((output >= monotonic && output - monotonic < 1000))
  run time::boot-time-milliseconds
  [ "${status}" -eq 0 ]
  ((output >= boot && output - boot < 1000))
}

@test "time functions reject arguments" {
  run time::utc-date-extended unexpected
  [ "${status}" -eq 64 ]
  run time::monotonic-milliseconds unexpected
  [ "${status}" -eq 64 ]
  run time::boot-time-milliseconds unexpected
  [ "${status}" -eq 64 ]
}

@test "log functions prefix every message line" {
  time::local-date-time-milliseconds-extended() {
    printf '2026-01-02T03:04:05.006+09:00\n'
  }

  run --separate-stderr log::info $'first\n\nthird'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  [ "${stderr}" = $'2026-01-02T03:04:05.006+09:00 [INFO] [bashstock] first\n2026-01-02T03:04:05.006+09:00 [INFO] [bashstock] \n2026-01-02T03:04:05.006+09:00 [INFO] [bashstock] third' ]

  run --separate-stderr log::warn 'warning'
  [[ "${stderr}" == *'[WARN] [bashstock] warning' ]]
  run --separate-stderr log::error 'failure'
  [[ "${stderr}" == *'[ERROR] [bashstock] failure' ]]
}
