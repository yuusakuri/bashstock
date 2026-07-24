#!/usr/bin/env bats

load test_helper

@test "the adapter reports enhanced getopt behavior" {
  run "${GETOPT}" -lfoo '' --foo

  [ "${status}" -eq 0 ]
  [ "${output}" = ' --foo --' ]
}

@test "the adapter quotes spaces" {
  run "${GETOPT}" -o 'n:' -l 'name:' -- --name 'Ada Lovelace'

  [ "${status}" -eq 0 ]
  [ "${output}" = " --name 'Ada Lovelace' --" ]
}

@test "the adapter quotes single quotes" {
  run "${GETOPT}" -o 'n:' -l 'name:' -- --name "O'Brien"

  [ "${status}" -eq 0 ]
  [ "${output}" = " --name 'O'\\''Brien' --" ]
}

@test "the adapter expands a short boolean cluster" {
  run "${GETOPT}" -o 'vh' -l 'version,help' -- -vh

  [ "${status}" -eq 0 ]
  [ "${output}" = ' -v -h --' ]
}

@test "the adapter rejects an unknown option" {
  run "${GETOPT}" -o 'n:' -l 'name:' -- --other

  [ "${status}" -eq 1 ]
  [ "${output}" = 'mytool-getopt: unknown option: --other' ]
}
