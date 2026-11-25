#!/usr/bin/env bats

load test_helper

@test "whitespace functions preserve interior content" {
  run string__trim $' \t日本  語\n'
  [ "${status}" -eq 0 ]
  [ "${output}" = '日本  語' ]

  run string__collapse-whitespace $' \t日本 \n 語  '
  [ "${status}" -eq 0 ]
  [ "${output}" = '日本 語' ]
}

@test "ASCII case functions preserve non-ASCII text" {
  run string__lower 'AbC日本'
  [ "${output}" = 'abc日本' ]
  run string__upper 'AbC日本'
  [ "${output}" = 'ABC日本' ]
  run string__swap-case 'AbC日本'
  [ "${output}" = 'aBc日本' ]
  run string__lower-first 'Hello'
  [ "${output}" = 'hello' ]
  run string__upper-first 'hello'
  [ "${output}" = 'Hello' ]
}

@test "quote and pattern removal functions follow their contracts" {
  run string__strip-surrounding-quotes '"a'\''b"'
  [ "${output}" = "a'b" ]
  run string__remove-first-match 'one-two-two' 'two'
  [ "${output}" = 'one--two' ]
  run string__remove-all-matches 'one-two-two' 'two'
  [ "${output}" = 'one--' ]
  run string__remove-prefix 'aaab' 'a*'
  [ -z "${output}" ]
  run string__remove-suffix 'baaa' '*a'
  [ -z "${output}" ]
}

@test "URL encoding operates on UTF-8 bytes" {
  run string__encode-url 'a 日本%+'
  [ "${status}" -eq 0 ]
  [ "${output}" = 'a%20%E6%97%A5%E6%9C%AC%25%2B' ]

  run string__decode-url 'a%20%E6%97%A5%E6%9C%AC%25%2B'
  [ "${status}" -eq 0 ]
  [ "${output}" = 'a 日本%+' ]

  run string__decode-url '%0'
  [ "${status}" -eq 64 ]
  run string__decode-url '%00'
  [ "${status}" -eq 64 ]
}

@test "literal string relations do not evaluate patterns" {
  string__contains 'a*b' '*'
  string__starts-with '[abc]' '['
  string__ends-with '[abc]' ']'
  ! string__contains 'abc' '*'
}

@test "join and split preserve empty values" {
  run string__join '::' one '' three
  [ "${output}" = 'one::::three' ]

  run string__split 'one::::three' '::'
  [ "${output}" = $'one\n\nthree' ]

  run string__split 'value' ''
  [ "${status}" -eq 64 ]
}

@test "length functions distinguish characters from bytes" {
  # Character counts follow the locale, so the test selects a UTF-8 locale itself.
  export LC_ALL=C.UTF-8
  run string__length '日本'
  [ "${output}" = '2' ]

  run string__byte-length '日本'
  [ "${output}" = '6' ]

  export LC_ALL='C'
  run string__length '日本'
  [ "${status}" -eq 69 ]
}

@test "replacement functions replace the requested occurrence" {
  run string__replace-first 'ab-ab-ab' 'ab' 'X&'
  [ "${output}" = 'X&-ab-ab' ]
  run string__replace-all 'ab-ab-ab' 'ab' 'X&'
  [ "${output}" = 'X&-X&-X&' ]
  run string__replace-last 'ab-ab-ab' 'ab' 'X&'
  [ "${output}" = 'ab-ab-X&' ]
  run string__replace-last 'abc' 'a*' 'X'
  [ "${output}" = 'X' ]
  run string__replace-last 'abc' '?' 'X'
  [ "${output}" = 'abX' ]
  run string__replace-last 'abc' '*' 'X'
  [ "${output}" = 'abX' ]
  run string__replace-last 'abc' 'z*' 'X'
  [ "${output}" = 'abc' ]

  run string__replace-all 'ab-ab' 'ab' 'X\Y'
  [ "${output}" = 'X\Y-X\Y' ]
}

@test "requirement and slice functions validate input" {
  # string__slice requires a UTF-8 locale, so the test selects one itself.
  export LC_ALL=C.UTF-8
  string__require-non-empty Name value
  string__require-empty Name ''
  string__require-allowed Mode safe fast safe

  run string__slice '日本abc' 1 4
  [ "${status}" -eq 0 ]
  [ "${output}" = '本ab' ]

  run string__slice 'abc' 2 1
  [ "${status}" -eq 64 ]
  run string__slice 'abc' 999999999999999999999999
  [ "${status}" -eq 64 ]

  run string__require-non-empty Name ''
  [ "${status}" -eq 64 ]
  [[ "${output}" == *'Name must not be empty.'* ]]
}
