#!/usr/bin/env bats

load test_helper

@test "public functions preserve shell state and caller variables" {
  local directory_before=''
  local ifs_before=''
  local options_before=''
  local shell_options_before=''
  directory_before="${PWD}"
  ifs_before="${IFS}"
  options_before="$(set +o)"
  shell_options_before="$(shopt -p)"
  BASH_REMATCH=('caller-value')

  string::lower 'VALUE' >/dev/null
  string::is-match 'value' '^val' >/dev/null
  number::is-number '12.5'
  path::normalize '/one/../two' >/dev/null
  array::unique one two one >/dev/null
  file::contains-match "${PROJECT_ROOT}/README.md" '^# ' >/dev/null

  [ "${PWD}" = "${directory_before}" ]
  [ "${IFS}" = "${ifs_before}" ]
  [ "$(set +o)" = "${options_before}" ]
  [ "$(shopt -p)" = "${shell_options_before}" ]
  [ "${BASH_REMATCH[0]}" = 'caller-value' ]
}

@test "failed predicates preserve shell state and caller match data" {
  local options_before=''
  local shell_options_before=''
  options_before="$(set +o)"
  shell_options_before="$(shopt -p)"
  BASH_REMATCH=('caller-value')

  ! string::contains value missing
  ! number::is-integer decimal
  ! path::is-regular-file "${BATS_TEST_TMPDIR}/missing"

  [ "$(set +o)" = "${options_before}" ]
  [ "$(shopt -p)" = "${shell_options_before}" ]
  [ "${BASH_REMATCH[0]}" = 'caller-value' ]
}
