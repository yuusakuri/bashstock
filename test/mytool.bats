#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "default values write one greeting" {
  run --separate-stderr "${TOOL}"

  [ "${status}" -eq 0 ]
  [ "${output}" = 'Hello, World!' ]
  [ -z "${stderr}" ]
}

@test "the short name option accepts a value" {
  run --separate-stderr "${TOOL}" -n 'Alice'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'Hello, Alice!' ]
}

@test "the long name option accepts spaces" {
  run --separate-stderr "${TOOL}" --name 'Ada Lovelace'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'Hello, Ada Lovelace!' ]
}

@test "the inline long name option accepts spaces" {
  run --separate-stderr "${TOOL}" '--name=Grace Hopper'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'Hello, Grace Hopper!' ]
}

@test "a single quote stays data" {
  run --separate-stderr "${TOOL}" --name "O'Brien"

  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello, O'Brien!" ]
}

@test "a command expression stays data" {
  local marker="${BATS_TEST_TMPDIR}/created"
  local value="\$(touch ${marker})"

  run --separate-stderr "${TOOL}" --name "${value}"

  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello, ${value}!" ]
  [ ! -e "${marker}" ]
}

@test "name whitespace is trimmed" {
  run --separate-stderr "${TOOL}" --name $' \tAlice\r '

  [ "${status}" -eq 0 ]
  [ "${output}" = 'Hello, Alice!' ]
}

@test "a blank name returns a usage error" {
  run --separate-stderr "${TOOL}" --name $' \t '

  [ "${status}" -eq 64 ]
  [ -z "${output}" ]
  [ "${stderr}" = 'mytool: The name must contain a visible character.' ]
}

@test "a control character in a name returns a usage error" {
  run --separate-stderr "${TOOL}" --name $'Alice\e'

  [ "${status}" -eq 64 ]
  [ -z "${output}" ]
  [ "${stderr}" = 'mytool: The name must not contain control characters.' ]
}

@test "times writes the requested line count" {
  run --separate-stderr "${TOOL}" --times 3 --name 'Alice'

  [ "${status}" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Hello, Alice!' ]
  [ "${lines[1]}" = 'Hello, Alice!' ]
  [ "${lines[2]}" = 'Hello, Alice!' ]
}

@test "times accepts the upper limit" {
  run --separate-stderr "${TOOL}" --times 100

  [ "${status}" -eq 0 ]
  [ "${#lines[@]}" -eq 100 ]
}

@test "times rejects zero" {
  run --separate-stderr "${TOOL}" --times 0

  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'mytool: The times value must be from 1 through 100.' ]
}

@test "times rejects a non-integer" {
  run --separate-stderr "${TOOL}" --times 'many'

  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *'invalid integer value (many)'* ]]
}

@test "times rejects a value above the limit" {
  run --separate-stderr "${TOOL}" --times 101

  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'mytool: The times value must be from 1 through 100.' ]
}

@test "help writes usage and returns success" {
  run --separate-stderr "${TOOL}" --help

  [ "${status}" -eq 0 ]
  [[ "${output}" == 'Usage: mytool [options]'* ]]
  [ -z "${stderr}" ]
}

@test "version writes the command version" {
  run --separate-stderr "${TOOL}" --version

  [ "${status}" -eq 0 ]
  [ "${output}" = 'mytool 1.0.0' ]
  [ -z "${stderr}" ]
}

@test "a positional argument returns a usage error" {
  run --separate-stderr "${TOOL}" 'Alice'

  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'mytool: Positional arguments are not accepted.' ]
}

@test "an unknown option returns a parser error" {
  run --separate-stderr "${TOOL}" --unknown

  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *'unknown option: --unknown'* ]]
}

@test "an option without its required value returns a parser error" {
  run --separate-stderr "${TOOL}" --name

  [ "${status}" -eq 2 ]
  [[ "${stderr}" == *'option needs a value: --name'* ]]
}
