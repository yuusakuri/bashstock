#!/usr/bin/env bats

load test_helper

@test "contains-match handles matches and invalid expressions" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'alpha=1\nbeta=2' >"${file}"

  file__contains-match "${file}" '^alpha=[0-9]+$'
  file__contains-match "${file}" '(?<=alpha)=[0-9]+'
  ! file__contains-match "${file}" '^gamma='

  run file__contains-match "${file}" '['
  [ "${status}" -eq 64 ]
}

@test "contains-match finds text that is not ASCII in any locale" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf '# 日本語の設定\nname=値\n' >"${file}"
  # Python 3.6 reads arguments as ASCII in the C locale; later versions do the same without UTF-8 mode.
  export LC_ALL=C PYTHONUTF8=0

  file__contains-match "${file}" '^name=値$'
  file__contains-match "${file}" '日本語'
  ! file__contains-match "${file}" '^name=別$'
}

@test "SHA-256 verification is case-insensitive" {
  local file="${BATS_TEST_TMPDIR}/input"
  local expected=''
  local incorrect=''
  printf 'content' >"${file}"
  if [[ "$(system__operating-system)" = 'darwin' ]]; then
    expected="$(shasum -a 256 "${file}")"
  else
    expected="$(sha256sum "${file}")"
  fi
  expected="${expected%% *}"

  file__verify-sha256 "${file}" "${expected}"
  file__verify-sha256 "${file}" "$(string__upper "${expected}")"
  if [[ "${expected:0:1}" = '0' ]]; then
    incorrect="1${expected:1}"
  else
    incorrect="0${expected:1}"
  fi
  ! file__verify-sha256 "${file}" "${incorrect}"
}

@test "append-text writes bytes without conversion" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'first' >"${file}"

  file__append-text "${file}" $'\nsecond\\value'
  run command cat "${file}"
  [ "${output}" = $'first\nsecond\\value' ]
}

@test "replace-text updates the first match on each line atomically" {
  local file="${BATS_TEST_TMPDIR}/input"
  local mode_before=''
  local mode_after=''
  printf 'value=1 value=2\nvalue=3' >"${file}"
  chmod 640 "${file}"
  mode_before="$(path__mode "${file}")"

  file__replace-text "${file}" 'value=[0-9]+' 'value=X'
  [ "$(<"${file}")" = $'value=X value=2\nvalue=X' ]

  mode_after="$(path__mode "${file}")"
  [ "${mode_after}" = "${mode_before}" ]
}

@test "replace-text uses Bash ERE and keeps replacement text literal" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'alpha=1 alpha=2\nfoo foo' >"${file}"

  file__replace-all-text "${file}" 'alpha=[0-9]+' '$1\1&'
  [ "$(<"${file}")" = $'$1\\1& $1\\1&\nfoo foo' ]

  file__replace-text "${file}" 'foo$' 'end'
  [ "$(<"${file}")" = $'$1\\1& $1\\1&\nfoo end' ]
}

@test "replace-text rejects expressions outside Bash ERE" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'alpha=1' >"${file}"

  run file__replace-text "${file}" '(?<=alpha)=[0-9]+' 'changed'
  [ "${status}" -eq 64 ]
  [ "$(<"${file}")" = 'alpha=1' ]

  run file__replace-all-text "${file}" 'a*' 'changed'
  [ "${status}" -eq 64 ]
  [ "$(<"${file}")" = 'alpha=1' ]
}

@test "replace-text rejects NUL bytes without changing the file" {
  local file="${BATS_TEST_TMPDIR}/input"
  local original="${BATS_TEST_TMPDIR}/original"
  printf 'alpha\0beta\n' >"${file}"
  cp "${file}" "${original}"

  run file__replace-text "${file}" 'alpha' 'changed'
  [ "${status}" -eq 64 ]
  cmp "${file}" "${original}"
}

@test "replace-text leaves a file unchanged when nothing matches" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'value=1' >"${file}"

  run file__replace-text "${file}" '^missing=' replacement
  [ "${status}" -eq 1 ]
  [ "$(<"${file}")" = 'value=1' ]
}

@test "replace-text-or-append replaces all matches or creates one complete line" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'value=1' >"${file}"

  file__replace-text-or-append "${file}" '^other=.*$' 'other=2'
  [ "$(<"${file}")" = $'value=1\nother=2' ]

  file__replace-text-or-append "${file}" '^other=.*$' 'other=3'
  [ "$(<"${file}")" = $'value=1\nother=3' ]

  printf 'other=1 other=2' >"${file}"
  file__replace-text-or-append "${file}" 'other=[0-9]+' 'other=X'
  [ "$(<"${file}")" = 'other=X other=X' ]
}

@test "multi-file replacement validates every file before updating" {
  local first="${BATS_TEST_TMPDIR}/first"
  local second="${BATS_TEST_TMPDIR}/second"
  printf 'value=1' >"${first}"
  printf 'missing=2' >"${second}"

  run file__replace-text-in-files '^value=' 'value=X' "${first}" "${second}"
  [ "${status}" -eq 1 ]
  [ "$(<"${first}")" = 'value=1' ]
  [ "$(<"${second}")" = 'missing=2' ]

  printf 'value=2' >"${second}"
  file__replace-text-in-files '^value=' 'value=X' "${first}" "${second}"
  [ "$(<"${first}")" = 'value=X1' ]
  [ "$(<"${second}")" = 'value=X2' ]

  printf 'value=1 value=2' >"${first}"
  printf 'value=3 value=4' >"${second}"
  file__replace-all-text-in-files \
    'value=[0-9]+' 'value=X' "${first}" "${second}"
  [ "$(<"${first}")" = 'value=X value=X' ]
  [ "$(<"${second}")" = 'value=X value=X' ]
}

@test "updating functions reject symbolic links" {
  local file="${BATS_TEST_TMPDIR}/input"
  local link="${BATS_TEST_TMPDIR}/link"
  printf 'value' >"${file}"
  ln -s "${file}" "${link}"

  run file__append-text "${link}" text
  [ "${status}" -eq 64 ]
  run file__replace-text "${link}" value replacement
  [ "${status}" -eq 66 ]
}
