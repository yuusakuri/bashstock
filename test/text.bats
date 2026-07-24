#!/usr/bin/env bats

load test_helper

@test "trim removes supported whitespace from both ends" {
  source "${PROJECT_ROOT}/src/text/text.sh"

  run text::trim $'\n \tAlice Smith\r '

  [ "${status}" -eq 0 ]
  [ "${output}" = 'Alice Smith' ]
}

@test "trim keeps inner whitespace" {
  source "${PROJECT_ROOT}/src/text/text.sh"

  run text::trim $'Alice \t Smith'

  [ "${status}" -eq 0 ]
  [ "${output}" = $'Alice \t Smith' ]
}

@test "trim accepts an empty string" {
  source "${PROJECT_ROOT}/src/text/text.sh"

  run text::trim ''

  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
