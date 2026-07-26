#!/usr/bin/env bats

load test_helper

@test "the adapter reports enhanced getopt behavior" {
  run "${GETOPT}" -lfoo '' --foo

  [ "${status}" -eq 0 ]
  [ "${output}" = ' --foo --' ]
}

@test "the adapter quotes spaces" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- --file 'reports/July report.txt'

  [ "${status}" -eq 0 ]
  [ "${output}" = " --file 'reports/July report.txt' --" ]
}

@test "the adapter parses an inline long value" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- '--file=reports/July report.txt'

  [ "${status}" -eq 0 ]
  [ "${output}" = " --file 'reports/July report.txt' --" ]
}

@test "the adapter parses a separate short value" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- -f 'reports/July report.txt'

  [ "${status}" -eq 0 ]
  [ "${output}" = " -f 'reports/July report.txt' --" ]
}

@test "the adapter parses an attached short value" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- '-freports/July report.txt'

  [ "${status}" -eq 0 ]
  [ "${output}" = " -f 'reports/July report.txt' --" ]
}

@test "the adapter quotes single quotes" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- --file "reports/O'Brien.txt"

  [ "${status}" -eq 0 ]
  [ "${output}" = " --file 'reports/O'\\''Brien.txt' --" ]
}

@test "the adapter expands a short boolean cluster" {
  run "${GETOPT}" -o 'vh' -l 'version,help' -- -vh

  [ "${status}" -eq 0 ]
  [ "${output}" = ' -v -h --' ]
}

@test "the adapter rejects an unknown option" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- --other

  [ "${status}" -eq 1 ]
  [ "${output}" = 'mytool-getopt: unknown option: --other' ]
}

@test "the adapter rejects a missing long value" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- --file

  [ "${status}" -eq 1 ]
  [ "${output}" = 'mytool-getopt: option needs a value: --file' ]
}

@test "the adapter rejects a missing short value" {
  run "${GETOPT}" -o 'f:' -l 'file:' -- -f

  [ "${status}" -eq 1 ]
  [ "${output}" = 'mytool-getopt: option needs a value: -f' ]
}

@test "the adapter rejects a value for a boolean option" {
  run "${GETOPT}" -o 'v' -l 'version' -- --version=true

  [ "${status}" -eq 1 ]
  [ "${output}" = 'mytool-getopt: option does not take a value: --version' ]
}
