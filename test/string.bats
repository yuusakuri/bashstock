#!/usr/bin/env bats

load test_helper

@test "whitespace functions preserve interior content" {
  run string::trim $' \t日本  語\n'
  [ "${status}" -eq 0 ]
  [ "${output}" = '日本  語' ]

  run string::collapse-whitespace $' \t日本 \n 語  '
  [ "${status}" -eq 0 ]
  [ "${output}" = '日本 語' ]
}

@test "ASCII case functions preserve non-ASCII text" {
  run string::lower 'AbC日本'
  [ "${output}" = 'abc日本' ]
  run string::upper 'AbC日本'
  [ "${output}" = 'ABC日本' ]
  run string::swap-case 'AbC日本'
  [ "${output}" = 'aBc日本' ]
  run string::lower-first 'Hello'
  [ "${output}" = 'hello' ]
  run string::upper-first 'hello'
  [ "${output}" = 'Hello' ]
}

@test "quote and pattern removal functions follow their contracts" {
  run string::strip-surrounding-quotes '"a'\''b"'
  [ "${output}" = "a'b" ]
  run string::remove-first-match 'one-two-two' 'two'
  [ "${output}" = 'one--two' ]
  run string::remove-all-matches 'one-two-two' 'two'
  [ "${output}" = 'one--' ]
  run string::remove-prefix 'aaab' 'a*'
  [ -z "${output}" ]
  run string::remove-suffix 'baaa' '*a'
  [ -z "${output}" ]
}

@test "URL encoding operates on UTF-8 bytes" {
  run string::encode-url 'a 日本%+'
  [ "${status}" -eq 0 ]
  [ "${output}" = 'a%20%E6%97%A5%E6%9C%AC%25%2B' ]

  run string::decode-url 'a%20%E6%97%A5%E6%9C%AC%25%2B'
  [ "${status}" -eq 0 ]
  [ "${output}" = 'a 日本%+' ]

  run string::decode-url '%0'
  [ "${status}" -eq 64 ]
  run string::decode-url '%00'
  [ "${status}" -eq 64 ]
}

@test "literal string relations do not evaluate patterns" {
  string::contains 'a*b' '*'
  string::starts-with '[abc]' '['
  string::ends-with '[abc]' ']'
  ! string::contains 'abc' '*'
}

@test "join and split preserve empty values" {
  run string::join '::' one '' three
  [ "${output}" = 'one::::three' ]

  run string::split 'one::::three' '::'
  [ "${output}" = $'one\n\nthree' ]

  run string::split 'value' ''
  [ "${status}" -eq 64 ]
}

@test "regular expression functions return captures without changing the caller match" {
  BASH_REMATCH=('unchanged')

  string::is-match 'abc-123' '^([a-z]+)-([0-9]+)$'
  [ "${BASH_REMATCH[0]}" = 'unchanged' ]

  run string::capture-group 'abc-123' '^([a-z]+)-([0-9]+)$' 2
  [ "${status}" -eq 0 ]
  [ "${output}" = '123' ]

  run string::capture-groups 'abc-123' '^([a-z]+)-([0-9]+)$'
  [ "${output}" = $'abc\n123' ]

  run string::is-match value '['
  [ "${status}" -eq 64 ]
}

@test "length functions distinguish characters from bytes" {
  run string::length '日本'
  [ "${output}" = '2' ]

  run string::byte-length '日本'
  [ "${output}" = '6' ]

  export LC_ALL='C'
  run string::length '日本'
  [ "${status}" -eq 69 ]
}

@test "replacement functions replace the requested occurrence" {
  run string::replace-first 'ab-ab-ab' 'ab' 'X&'
  [ "${output}" = 'X&-ab-ab' ]
  run string::replace-all 'ab-ab-ab' 'ab' 'X&'
  [ "${output}" = 'X&-X&-X&' ]
  run string::replace-last 'ab-ab-ab' 'ab' 'X&'
  [ "${output}" = 'ab-ab-X&' ]
  run string::replace-last 'abc' 'a*' 'X'
  [ "${output}" = 'X' ]
  run string::replace-last 'abc' '?' 'X'
  [ "${output}" = 'abX' ]
  run string::replace-last 'abc' '*' 'X'
  [ "${output}" = 'abX' ]
  run string::replace-last 'abc' 'z*' 'X'
  [ "${output}" = 'abc' ]

  run string::replace-all 'ab-ab' 'ab' 'X\Y'
  [ "${output}" = 'X\Y-X\Y' ]
}

@test "requirement and slice functions validate input" {
  string::require-non-empty Name value
  string::require-empty Name ''
  string::require-allowed Mode safe fast safe

  run string::slice '日本abc' 1 4
  [ "${status}" -eq 0 ]
  [ "${output}" = '本ab' ]

  run string::slice 'abc' 2 1
  [ "${status}" -eq 64 ]
  run string::slice 'abc' 999999999999999999999999
  [ "${status}" -eq 64 ]

  run string::require-non-empty Name ''
  [ "${status}" -eq 64 ]
  [[ "${output}" == *'Name must not be empty.'* ]]
}
