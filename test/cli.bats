#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "default execution writes help" {
  run --separate-stderr "${TOOL}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == 'Usage: bashstock [options]'* ]]
  [ -z "${stderr}" ]
}

@test "the long help option writes help" {
  run --separate-stderr "${TOOL}" --help

  [ "${status}" -eq 0 ]
  [[ "${output}" == 'Usage: bashstock [options]'* ]]
  [ -z "${stderr}" ]
}

@test "the short help option writes help" {
  run --separate-stderr "${TOOL}" -h

  [ "${status}" -eq 0 ]
  [[ "${output}" == 'Usage: bashstock [options]'* ]]
  [ -z "${stderr}" ]
}

@test "the long version option writes the command version" {
  run --separate-stderr "${TOOL}" --version

  [ "${status}" -eq 0 ]
  [ "${output}" = 'bashstock 1.0.0' ]
  [ -z "${stderr}" ]
}

@test "the short version option writes the command version" {
  run --separate-stderr "${TOOL}" -v

  [ "${status}" -eq 0 ]
  [ "${output}" = 'bashstock 1.0.0' ]
  [ -z "${stderr}" ]
}

@test "a positional argument returns a usage error" {
  run --separate-stderr "${TOOL}" 'value'

  [ "${status}" -eq 64 ]
  [ -z "${output}" ]
  [ "${stderr}" = 'bashstock: Positional arguments are not accepted.' ]
}

@test "a positional command expression stays data" {
  local marker="${BATS_TEST_TMPDIR}/created"
  local value="\$(touch ${marker})"

  run --separate-stderr "${TOOL}" "${value}"

  [ "${status}" -eq 64 ]
  [ ! -e "${marker}" ]
}

@test "a positional argument after version returns a usage error" {
  run --separate-stderr "${TOOL}" --version 'value'

  [ "${status}" -eq 64 ]
  [ -z "${output}" ]
  [ "${stderr}" = 'bashstock: Positional arguments are not accepted.' ]
}

@test "an unknown long option returns a parser error" {
  run --separate-stderr "${TOOL}" --unknown

  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *'unknown option: --unknown'* ]]
}

@test "an unknown short option returns a parser error" {
  run --separate-stderr "${TOOL}" -x

  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *'unknown option: -x'* ]]
}
