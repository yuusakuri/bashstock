#!/usr/bin/env bats

load test_helper

assert_file_content() {
  local expected="$1"
  local file="$2"
  local expected_file="${BATS_TEST_TMPDIR}/expected"
  printf '%s' "${expected}" >"${expected_file}"
  cmp "${expected_file}" "${file}"
}

@test "replace-text accepts only the documented signatures" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'value=1 value=2' >"${file}"

  run file::replace-text "${file}" 'value=[0-9]+' 'value=X'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  assert_file_content 'value=X value=2' "${file}"

  printf 'value=1 value=2' >"${file}"
  run file::replace-all-text "${file}" 'value=[0-9]+' 'value=X'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  assert_file_content 'value=X value=X' "${file}"
}

@test "replacement functions reject missing excess and obsolete option arguments" {
  local file="${BATS_TEST_TMPDIR}/input"
  local original="${BATS_TEST_TMPDIR}/original"
  printf 'value=1' >"${file}"
  cp "${file}" "${original}"

  run file::replace-text
  [ "${status}" -eq 64 ]
  run file::replace-text "${file}"
  [ "${status}" -eq 64 ]
  run file::replace-text "${file}" 'value'
  [ "${status}" -eq 64 ]
  run file::replace-text "${file}" 'value' 'changed' 'excess'
  [ "${status}" -eq 64 ]
  run file::replace-all-text
  [ "${status}" -eq 64 ]
  run file::replace-all-text "${file}"
  [ "${status}" -eq 64 ]
  run file::replace-all-text "${file}" 'value'
  [ "${status}" -eq 64 ]
  run file::replace-all-text "${file}" 'value' 'changed' 'excess'
  [ "${status}" -eq 64 ]
  run file::replace-text --unknown "${file}" 'value' 'changed'
  [ "${status}" -eq 64 ]
  run file::replace-text --all "${file}" 'value' 'changed'
  [ "${status}" -eq 64 ]
  run file::replace-all-text --all "${file}" 'value' 'changed'
  [ "${status}" -eq 64 ]
  cmp "${original}" "${file}"
}

@test "replace-text validates every file type before replacement" {
  local directory="${BATS_TEST_TMPDIR}/directory"
  local missing="${BATS_TEST_TMPDIR}/missing"
  local target="${BATS_TEST_TMPDIR}/target"
  local link="${BATS_TEST_TMPDIR}/link"
  local fifo="${BATS_TEST_TMPDIR}/fifo"
  mkdir "${directory}"
  printf 'value=1' >"${target}"
  ln -s "${target}" "${link}"
  mkfifo "${fifo}"

  run file::replace-text '' 'value' 'changed'
  [ "${status}" -eq 64 ]
  run file::replace-text "${missing}" 'value' 'changed'
  [ "${status}" -eq 66 ]
  run file::replace-text "${directory}" 'value' 'changed'
  [ "${status}" -eq 66 ]
  run file::replace-text "${link}" 'value' 'changed'
  [ "${status}" -eq 66 ]
  run file::replace-text "${fifo}" 'value' 'changed'
  [ "${status}" -eq 66 ]
  assert_file_content 'value=1' "${target}"
}

@test "replace-text handles spaces newlines and pattern characters in file names" {
  local file="${BATS_TEST_TMPDIR}/file name"$'\n''[*?] --all'
  printf 'before' >"${file}"

  file::replace-text "${file}" '^before$' 'after'
  assert_file_content 'after' "${file}"
}

@test "replace-text changes the first match on every line by default" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'a1 a2 a3\n\ta4  a5\nmissing\n' >"${file}"

  file::replace-text "${file}" 'a[0-9]' 'X'
  assert_file_content $'X a2 a3\n\tX  a5\nmissing\n' "${file}"
}

@test "replace-all-text changes every nonempty match on every line" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'a1 a2 a3\n\ta4  a5\nmissing\n' >"${file}"

  file::replace-all-text "${file}" 'a[0-9]' 'X'
  assert_file_content $'X X X\n\tX  X\nmissing\n' "${file}"
}

@test "replace-text follows leftmost-longest Bash ERE matching" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'aaa' >"${file}"

  file::replace-text "${file}" 'a|aa' 'X'
  assert_file_content 'Xa' "${file}"

  printf 'aaa' >"${file}"
  file::replace-all-text "${file}" 'a|aa' 'X'
  assert_file_content 'XX' "${file}"
}

@test "replace-text handles start end whole-line and empty-line anchors" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'foo foo\nfoo\n\n' >"${file}"

  file::replace-text "${file}" 'foo$' 'END'
  assert_file_content $'foo END\nEND\n\n' "${file}"

  file::replace-text "${file}" '^foo' 'START'
  assert_file_content $'START END\nEND\n\n' "${file}"

  file::replace-text "${file}" '^$' 'EMPTY'
  assert_file_content $'START END\nEND\nEMPTY\n' "${file}"
}

@test "replace-text supports Bash ERE groups alternation classes and quantifiers" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'cat12 dog3 bird4 猫45 a.b' >"${file}"

  file::replace-all-text \
    "${file}" '(cat|dog|猫)[[:digit:]]+' 'ANIMAL'
  assert_file_content 'ANIMAL ANIMAL bird4 ANIMAL a.b' "${file}"

  file::replace-text "${file}" 'a[.]b$' 'DOT'
  assert_file_content 'ANIMAL ANIMAL bird4 ANIMAL DOT' "${file}"
}

@test "replace-text supports dot and literal regular-expression punctuation" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'a.b axb a/b' >"${file}"

  file::replace-all-text "${file}" 'a.b' 'ANY'
  assert_file_content 'ANY ANY ANY' "${file}"

  printf 'a.b axb' >"${file}"
  file::replace-all-text "${file}" 'a\.b' 'ESCAPED'
  assert_file_content 'ESCAPED axb' "${file}"

  printf 'a.b a+b a?b a/b a(b)' >"${file}"
  file::replace-all-text \
    "${file}" 'a[.]b|a[+]b|a[?]b|a/b|a[(]b[)]' 'LITERAL'
  assert_file_content \
    'LITERAL LITERAL LITERAL LITERAL LITERAL' "${file}"
}

@test "replace-text supports positive negative and POSIX bracket classes" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'A1 b2 c3 d4 _5' >"${file}"

  file::replace-all-text "${file}" '[Abc][[:digit:]]' 'CLASS'
  assert_file_content 'CLASS CLASS CLASS d4 _5' "${file}"

  file::replace-all-text "${file}" '[^[:space:]_][[:digit:]]' 'NEGATED'
  assert_file_content 'CLASS CLASS CLASS NEGATED _5' "${file}"
}

@test "replace-text supports star plus question and interval repetition" {
  local file="${BATS_TEST_TMPDIR}/input"

  printf 'a ab abb abbb abbbb' >"${file}"
  file::replace-all-text "${file}" 'ab+' 'PLUS'
  assert_file_content 'a PLUS PLUS PLUS PLUS' "${file}"

  printf 'a ab ac' >"${file}"
  file::replace-all-text "${file}" 'ab?' 'QUESTION'
  assert_file_content 'QUESTION QUESTION QUESTIONc' "${file}"

  printf 'ac abc abbc' >"${file}"
  file::replace-all-text "${file}" 'ab*c' 'STAR'
  assert_file_content 'STAR STAR STAR' "${file}"

  printf 'ab abb abbb abbbb' >"${file}"
  file::replace-all-text "${file}" 'ab{2,3}' 'INTERVAL'
  assert_file_content 'ab INTERVAL INTERVAL INTERVALb' "${file}"
}

@test "replace-text supports anchored nested groups and alternation" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'release/main\nhotfix/bug-1\nfeature/topic\nrelease/\n' >"${file}"

  file::replace-text \
    "${file}" '^(release|hotfix)/([[:alnum:]_-]+)$' 'ACCEPTED'
  assert_file_content \
    $'ACCEPTED\nACCEPTED\nfeature/topic\nrelease/\n' "${file}"
}

@test "replace-text is case-sensitive even when nocasematch is enabled" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'Value value VALUE' >"${file}"

  shopt -s nocasematch
  file::replace-all-text "${file}" 'value' 'MATCH'
  shopt -u nocasematch

  assert_file_content 'Value MATCH VALUE' "${file}"
}

@test "replace-text writes replacement metacharacters literally" {
  local file="${BATS_TEST_TMPDIR}/input"
  local replacement='$1\1&/$HOME;$(touch file);`id`;*?[]'
  printf 'token token' >"${file}"

  file::replace-all-text "${file}" 'token' "${replacement}"
  assert_file_content "${replacement} ${replacement}" "${file}"
  [ ! -e "${BATS_TEST_TMPDIR}/file" ]
}

@test "replace-text supports empty replacement" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'abc abc' >"${file}"

  file::replace-all-text "${file}" 'abc' ''
  assert_file_content ' ' "${file}"

  printf 'bbb' >"${file}"
  file::replace-text "${file}" 'a*' 'START'
  assert_file_content 'STARTbbb' "${file}"
}

@test "replace-all-text rejects invalid and empty-matching expressions" {
  local file="${BATS_TEST_TMPDIR}/input"
  local original="${BATS_TEST_TMPDIR}/original"
  local expression=''
  printf 'alpha=1' >"${file}"
  cp "${file}" "${original}"

  run file::replace-text "${file}" '' 'changed'
  [ "${status}" -eq 64 ]
  cmp "${original}" "${file}"

  for expression in '[' '(' '(?<=alpha)=[0-9]+' 'a*' 'a?' '^' '$'; do
    run file::replace-all-text "${file}" "${expression}" 'changed'
    [ "${status}" -eq 64 ]
    cmp "${original}" "${file}"
  done
}

@test "replace-text rejects multiline expression and replacement values" {
  local file="${BATS_TEST_TMPDIR}/input"
  local original="${BATS_TEST_TMPDIR}/original"
  printf 'alpha=1' >"${file}"
  cp "${file}" "${original}"

  run file::replace-text "${file}" $'alpha\nbeta' 'changed'
  [ "${status}" -eq 64 ]
  cmp "${original}" "${file}"

  run file::replace-text "${file}" 'alpha' $'changed\nvalue'
  [ "${status}" -eq 64 ]
  cmp "${original}" "${file}"
}

@test "replace-text preserves LF CRLF and missing final line endings" {
  local file="${BATS_TEST_TMPDIR}/input"

  printf 'alpha\nbeta\n' >"${file}"
  file::replace-text "${file}" 'alpha' 'one'
  assert_file_content $'one\nbeta\n' "${file}"

  printf 'alpha\r\nbeta\r\n' >"${file}"
  file::replace-all-text "${file}" 'alpha|beta' 'value'
  assert_file_content $'value\r\nvalue\r\n' "${file}"

  printf 'alpha\nbeta' >"${file}"
  file::replace-text "${file}" 'beta$' 'last'
  assert_file_content $'alpha\nlast' "${file}"
}

@test "replace-text leaves empty and nonmatching files byte-identical" {
  local file="${BATS_TEST_TMPDIR}/input"
  local original="${BATS_TEST_TMPDIR}/original"
  : >"${file}"
  cp "${file}" "${original}"

  run file::replace-text "${file}" 'value' 'changed'
  [ "${status}" -eq 1 ]
  cmp "${original}" "${file}"

  printf 'alpha\nbeta\n' >"${file}"
  cp "${file}" "${original}"
  run file::replace-all-text "${file}" 'missing' 'changed'
  [ "${status}" -eq 1 ]
  cmp "${original}" "${file}"
}

@test "replace-text rejects NUL at the start and chunk boundary" {
  local file="${BATS_TEST_TMPDIR}/input"
  local original="${BATS_TEST_TMPDIR}/original"
  local prefix=''
  local index=''

  printf '\0alpha' >"${file}"
  cp "${file}" "${original}"
  run file::replace-text "${file}" 'alpha' 'changed'
  [ "${status}" -eq 64 ]
  cmp "${original}" "${file}"

  for ((index = 0; index < 8192; index++)); do
    prefix="${prefix}a"
  done
  printf '%s\0tail' "${prefix}" >"${file}"
  cp "${file}" "${original}"
  run file::replace-text "${file}" '^a' 'changed'
  [ "${status}" -eq 64 ]
  cmp "${original}" "${file}"
}

@test "replace-text preserves mode and caller shell state" {
  local file="${BATS_TEST_TMPDIR}/input"
  local directory_before="${PWD}"
  local ifs_before="${IFS}"
  local options_before=''
  local shell_options_before=''
  local mode_before=''
  options_before="$(set +o)"
  shell_options_before="$(shopt -p)"
  printf 'value=1' >"${file}"
  chmod 751 "${file}"
  mode_before="$(path::mode "${file}")"
  BASH_REMATCH=('caller-value')

  file::replace-text "${file}" 'value=[0-9]+' 'value=X'

  assert_file_content 'value=X' "${file}"
  [ "$(path::mode "${file}")" = "${mode_before}" ]
  [ "${PWD}" = "${directory_before}" ]
  [ "${IFS}" = "${ifs_before}" ]
  [ "$(set +o)" = "${options_before}" ]
  [ "$(shopt -p)" = "${shell_options_before}" ]
  [ "${BASH_REMATCH[0]}" = 'caller-value' ]
}

@test "replace-text returns success when replacement bytes are unchanged" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'same' >"${file}"

  run file::replace-text "${file}" '^same$' 'same'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  assert_file_content 'same' "${file}"
}

@test "replace-text marks only the selected interactive rebase todo entry" {
  local file="${BATS_TEST_TMPDIR}/git-rebase-todo"
  printf \
    'pick abc123 first commit\np def456 second commit\npick fed789 third commit\n' \
    >"${file}"

  file::replace-text \
    "${file}" '^(pick|p)[[:space:]]+def456' 'edit def456'
  assert_file_content \
    $'pick abc123 first commit\nedit def456 second commit\npick fed789 third commit\n' \
    "${file}"

  file::replace-text \
    "${file}" '^(pick|p)[[:space:]]+abc123' 'edit abc123'
  assert_file_content \
    $'edit abc123 first commit\nedit def456 second commit\npick fed789 third commit\n' \
    "${file}"
}

@test "replace-text reproduces the keyboard layout sed substitutions" {
  local file="${BATS_TEST_TMPDIR}/keyboard"
  printf 'BACKSPACE="guess"\nXKBLAYOUT="jp"\nXKBVARIANT=""\n' >"${file}"

  file::replace-text \
    "${file}" 'XKBLAYOUT="[^"]*"' 'XKBLAYOUT="us"'
  assert_file_content \
    $'BACKSPACE="guess"\nXKBLAYOUT="us"\nXKBVARIANT=""\n' "${file}"

  file::replace-text \
    "${file}" 'XKBLAYOUT="[^"]*"' 'XKBLAYOUT="jp"'
  assert_file_content \
    $'BACKSPACE="guess"\nXKBLAYOUT="jp"\nXKBVARIANT=""\n' "${file}"
}
