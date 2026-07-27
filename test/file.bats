#!/usr/bin/env bats

load test_helper

@test "contains-match handles matches and invalid expressions" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'alpha=1\nbeta=2' >"${file}"

  file::contains-match "${file}" '^alpha=[0-9]+$'
  ! file::contains-match "${file}" '^gamma='

  run file::contains-match "${file}" '['
  [ "${status}" -eq 64 ]
}

@test "SHA-256 verification is case-insensitive" {
  local file="${BATS_TEST_TMPDIR}/input"
  local expected=''
  local incorrect=''
  printf 'content' >"${file}"
  if [[ "$(system::operating-system)" = 'darwin' ]]; then
    expected="$(shasum -a 256 "${file}")"
  else
    expected="$(sha256sum "${file}")"
  fi
  expected="${expected%% *}"

  file::verify-sha256 "${file}" "${expected}"
  file::verify-sha256 "${file}" "$(string::upper "${expected}")"
  if [[ "${expected:0:1}" = '0' ]]; then
    incorrect="1${expected:1}"
  else
    incorrect="0${expected:1}"
  fi
  ! file::verify-sha256 "${file}" "${incorrect}"
}

@test "append-text writes bytes without conversion" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'first' >"${file}"

  file::append-text "${file}" $'\nsecond\\value'
  run command cat "${file}"
  [ "${output}" = $'first\nsecond\\value' ]
}

@test "replace-text updates the first match on each line atomically" {
  local file="${BATS_TEST_TMPDIR}/input"
  local mode_before=''
  local mode_after=''
  printf 'value=1 value=2\nvalue=3' >"${file}"
  chmod 640 "${file}"
  mode_before="$(stat -f '%Lp' "${file}" 2>/dev/null || stat -c '%a' "${file}")"

  file::replace-text "${file}" 'value=[0-9]+' 'value=X'
  [ "$(<"${file}")" = $'value=X value=2\nvalue=X' ]

  mode_after="$(stat -f '%Lp' "${file}" 2>/dev/null || stat -c '%a' "${file}")"
  [ "${mode_after}" = "${mode_before}" ]
}

@test "replace-text leaves a file unchanged when nothing matches" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'value=1' >"${file}"

  run file::replace-text "${file}" '^missing=' replacement
  [ "${status}" -eq 1 ]
  [ "$(<"${file}")" = 'value=1' ]
}

@test "replace-or-append-text creates one complete line" {
  local file="${BATS_TEST_TMPDIR}/input"
  printf 'value=1' >"${file}"

  file::replace-or-append-text "${file}" '^other=.*$' 'other=2'
  [ "$(<"${file}")" = $'value=1\nother=2' ]

  file::replace-or-append-text "${file}" '^other=.*$' 'other=3'
  [ "$(<"${file}")" = $'value=1\nother=3' ]
}

@test "multi-file replacement validates every file before updating" {
  local first="${BATS_TEST_TMPDIR}/first"
  local second="${BATS_TEST_TMPDIR}/second"
  printf 'value=1' >"${first}"
  printf 'missing=2' >"${second}"

  run file::replace-text-in-files '^value=' 'value=X' "${first}" "${second}"
  [ "${status}" -eq 1 ]
  [ "$(<"${first}")" = 'value=1' ]
  [ "$(<"${second}")" = 'missing=2' ]

  printf 'value=2' >"${second}"
  file::replace-text-in-files '^value=' 'value=X' "${first}" "${second}"
  [ "$(<"${first}")" = 'value=X1' ]
  [ "$(<"${second}")" = 'value=X2' ]
}

@test "updating functions reject symbolic links" {
  local file="${BATS_TEST_TMPDIR}/input"
  local link="${BATS_TEST_TMPDIR}/link"
  printf 'value' >"${file}"
  ln -s "${file}" "${link}"

  run file::append-text "${link}" text
  [ "${status}" -eq 64 ]
  run file::replace-text "${link}" value replacement
  [ "${status}" -eq 66 ]
}
