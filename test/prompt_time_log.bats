#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "confirmation normalizes one input line" {
  run --separate-stderr prompt::confirm 'Continue' yes <<<"Y"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'yes' ]
  [ "${stderr}" = 'Continue [yes/no]:' ]

  run --separate-stderr prompt::confirm 'Continue' no <<<""
  [ "${status}" -eq 0 ]
  [ "${output}" = 'no' ]

  run --separate-stderr prompt::confirm 'Continue' <<<"maybe"
  [ "${status}" -eq 64 ]
}

@test "line input uses the default only for empty input" {
  run prompt::read-line-with-default 'Name' default <<<"value\\path"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'value\path' ]]

  run prompt::read-line-with-default 'Name' default <<<""
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'default' ]]
}

@test "cancel confirmation and selection normalize results" {
  run prompt::confirm-or-cancel 'Continue' cancel <<<"C"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'cancel' ]]

  run prompt::select-one 'Choose' first 'second value' <<<"2"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'second value' ]]

  run prompt::select-one 'Choose' first second <<<"3"
  [ "${status}" -eq 64 ]
}

@test "time functions format one fixed real-time value" {
  time::__realtime-milliseconds() {
    printf '0\n'
  }

  run time::utc-date-time-milliseconds
  [ "${output}" = '1970-01-01T00:00:00.000Z' ]
  run time::utc-date-time-seconds
  [ "${output}" = '1970-01-01T00:00:00Z' ]
  run time::utc-date
  [ "${output}" = '1970-01-01' ]
  run time::unix-milliseconds
  [ "${output}" = '0' ]
  run time::unix-seconds
  [ "${output}" = '0' ]
  run time::unix-days
  [ "${output}" = '0' ]

  export TZ='Asia/Tokyo'
  run time::local-date-time-milliseconds
  [ "${output}" = '1970-01-01T09:00:00.000+09:00' ]
  run time::local-date-time-seconds
  [ "${output}" = '1970-01-01T09:00:00+09:00' ]
  run time::local-date
  [ "${output}" = '1970-01-01' ]
}

@test "elapsed time uses the monotonic start value and truncates units" {
  BASHSTOCK_START_MONOTONIC_MILLISECONDS='1000'
  time::__monotonic-milliseconds() {
    printf '86402001\n'
  }

  run time::elapsed-milliseconds
  [ "${output}" = '86401001' ]
  run time::elapsed-seconds
  [ "${output}" = '86401' ]
  run time::elapsed-days
  [ "${output}" = '1' ]
}

@test "time functions reject arguments" {
  run time::utc-date unexpected
  [ "${status}" -eq 64 ]
  run time::elapsed-milliseconds unexpected
  [ "${status}" -eq 64 ]
}

@test "log functions prefix every message line" {
  time::local-date-time-milliseconds() {
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
