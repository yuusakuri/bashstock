#!/usr/bin/env bats

load test_helper

@test "array queries preserve exact values" {
  array::contains 'a*b' 'plain' 'a*b'
  ! array::contains 'missing' 'plain' 'a*b'

  run array::length '' 'two'
  [ "${status}" -eq 0 ]
  [ "${output}" = '2' ]

  run array::first '' 'two'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]

  run array::last 'one' ''
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "array transformations preserve order and empty elements" {
  run array::reverse one '' three
  [ "${status}" -eq 0 ]
  [ "${output}" = $'three\n\none' ]

  run array::unique one two one '' ''
  [ "${status}" -eq 0 ]
  [ "${output}" = $'one\ntwo' ]

  run array::prepend-to-each 'x:' one 'two words'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'x:one\nx:two words' ]
}

@test "line-oriented array functions reject embedded newlines" {
  run array::reverse $'one\ntwo'
  [ "${status}" -eq 64 ]

  run array::prepend-to-each 'x:' $'one\ntwo'
  [ "${status}" -eq 64 ]
}

@test "numeric predicates distinguish integers and decimals" {
  number::is-integer '-001'
  ! number::is-integer '1.0'

  number::is-decimal '+.5'
  number::is-decimal '1.'
  ! number::is-decimal '1'

  number::is-number '-10'
  number::is-number '10.25'
  ! number::is-number '1e3'
}

@test "numeric predicates reject an invalid argument count" {
  run number::is-integer
  [ "${status}" -eq 64 ]

  run number::is-number 1 2
  [ "${status}" -eq 64 ]
}
