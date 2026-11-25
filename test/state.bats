#!/usr/bin/env bats

load test_helper

@test "public functions preserve shell state and caller variables" {
  local directory_before=''
  local ifs_before=''
  local options_before=''
  local shell_options_before=''
  local replacement_file="${BATS_TEST_TMPDIR}/replacement"
  directory_before="${PWD}"
  ifs_before="${IFS}"
  options_before="$(set +o)"
  shell_options_before="$(shopt -p)"
  printf 'value=1' >"${replacement_file}"
  BASH_REMATCH=('caller-value')

  string__lower 'VALUE' >/dev/null
  regex__is-match 'value' '^val' >/dev/null
  number__is-number '12.5'
  path__normalize '/one/../two' >/dev/null
  array__unique one two one >/dev/null
  file__contains-match "${PROJECT_ROOT}/README.md" '^# ' >/dev/null
  file__replace-text "${replacement_file}" 'value=[0-9]+' 'value=X'

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

  ! string__contains value missing
  ! number__is-integer decimal
  ! path__is-regular-file "${BATS_TEST_TMPDIR}/missing"

  [ "$(set +o)" = "${options_before}" ]
  [ "$(shopt -p)" = "${shell_options_before}" ]
  [ "${BASH_REMATCH[0]}" = 'caller-value' ]
}

@test "validators and parsers keep the caller's BASH_REMATCH" {
  local dotenv="${BATS_TEST_TMPDIR}/.env"
  printf 'export BASHSTOCK_STATE_VALUE=1 # comment\n' >"${dotenv}"
  [[ 'caller-value' =~ (caller)-(value) ]]

  time__posix-timezone +09:30 >/dev/null
  number__is-integer 12
  env__dotenv__import "${dotenv}"
  git__branch__create -D topic . 2>/dev/null || true
  ssh__config__update "${BATS_TEST_TMPDIR}/missing" host User x 2>/dev/null || true

  [ "${BASH_REMATCH[0]}" = 'caller-value' ]
  [ "${BASH_REMATCH[2]}" = 'value' ]
}
