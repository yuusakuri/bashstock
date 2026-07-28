#!/usr/bin/env bats

load test_helper

@test "regular expression functions return captures without changing the caller match" {
  BASH_REMATCH=('unchanged')

  regex::is-match 'abc-123' '^([a-z]+)-([0-9]+)$'
  [ "${BASH_REMATCH[0]}" = 'unchanged' ]

  run regex::capture-group 'abc-123' '^([a-z]+)-([0-9]+)$' 2
  [ "${status}" -eq 0 ]
  [ "${output}" = '123' ]

  run regex::capture-group 'abc-123' '^([a-z]+)-([0-9]+)$' 02
  [ "${status}" -eq 0 ]
  [ "${output}" = '123' ]

  run regex::capture-groups 'abc-123' '^([a-z]+)-([0-9]+)$'
  [ "${output}" = $'abc\n123' ]

  run regex::is-match value '['
  [ "${status}" -eq 64 ]
}
