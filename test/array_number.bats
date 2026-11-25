#!/usr/bin/env bats

load test_helper

@test "array queries preserve exact values" {
  array__contains 'a*b' 'plain' 'a*b'
  ! array__contains 'missing' 'plain' 'a*b'

  run array__length '' 'two'
  [ "${status}" -eq 0 ]
  [ "${output}" = '2' ]

  run array__first '' 'two'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]

  run array__last 'one' ''
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "array transformations preserve order and empty elements" {
  run array__reverse one '' three
  [ "${status}" -eq 0 ]
  [ "${output}" = $'three\n\none' ]

  run array__unique one two one '' ''
  [ "${status}" -eq 0 ]
  [ "${output}" = $'one\ntwo' ]

  run array__prepend-to-each 'x:' one 'two words'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'x:one\nx:two words' ]
}

@test "line-oriented array functions reject embedded newlines" {
  run array__reverse $'one\ntwo'
  [ "${status}" -eq 64 ]

  run array__prepend-to-each 'x:' $'one\ntwo'
  [ "${status}" -eq 64 ]
}

@test "numeric predicates distinguish integers and decimals" {
  number__is-integer '-001'
  ! number__is-integer '1.0'

  number__is-decimal '+.5'
  number__is-decimal '1.'
  ! number__is-decimal '1'

  number__is-number '-10'
  number__is-number '10.25'
  ! number__is-number '1e3'
}

@test "numeric predicates reject an invalid argument count" {
  run number__is-integer
  [ "${status}" -eq 64 ]

  run number__is-number 1 2
  [ "${status}" -eq 64 ]
}
