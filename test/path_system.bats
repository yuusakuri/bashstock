#!/usr/bin/env bats

load test_helper

@test "base name and directory name handle lexical paths" {
  run path__directory-name '/one/two/'
  [ "${output}" = '/one' ]
  run path__directory-name 'name'
  [ "${output}" = '.' ]
  run path__directory-name '/'
  [ "${output}" = '/' ]

  run path__base-name '/one/two/'
  [ "${output}" = 'two' ]
  run path__base-name 'archive.tar.gz' '.gz'
  [ "${output}" = 'archive.tar' ]
  run path__base-name '/'
  [ "${output}" = '/' ]
}

@test "path predicates distinguish file types and permissions" {
  local directory="${BATS_TEST_TMPDIR}/directory"
  local file="${BATS_TEST_TMPDIR}/file"
  local link="${BATS_TEST_TMPDIR}/link"
  mkdir "${directory}"
  printf 'value' >"${file}"
  chmod 700 "${file}"
  ln -s "${file}" "${link}"

  path__is-directory "${directory}"
  path__is-empty-directory "${directory}"
  path__is-regular-file "${file}"
  path__is-executable "${file}"
  path__is-executable-file "${file}"
  path__is-readable "${file}"
  path__is-writable "${file}"
  path__is-symbolic-link "${link}"

  printf 'entry' >"${directory}/.hidden"
  ! path__is-empty-directory "${directory}"
}

@test "path mode is a portable octal value" {
  local file="${BATS_TEST_TMPDIR}/file"
  printf 'value' >"${file}"
  chmod 640 "${file}"

  run path__mode "${file}"
  [ "${status}" -eq 0 ]
  [ "${output}" = '640' ]

  run path__mode "${BATS_TEST_TMPDIR}/missing"
  [ "${status}" -eq 66 ]

  run path__mode
  [ "${status}" -eq 64 ]
}

@test "path extension handles hidden files and multiple dots" {
  run path__extension 'archive.tar.gz'
  [ "${output}" = '.gz' ]
  run path__extension '.profile'
  [ -z "${output}" ]
  run path__extension '.config.json'
  [ "${output}" = '.json' ]
  run path__extension 'name.'
  [ "${output}" = '.' ]
}

@test "normalize and relative are lexical and portable" {
  run path__normalize '/one//two/../three/.'
  [ "${output}" = '/one/three' ]
  run path__normalize '../../one/../two'
  [ "${output}" = '../../two' ]

  run path__relative '/one/two' '/one/three/four'
  [ "${output}" = '../three/four' ]
  run path__relative 'one/two' 'one/two'
  [ "${output}" = '.' ]
  run path__relative '/one' 'one'
  [ "${status}" -eq 64 ]
}

@test "configuration home follows XDG rules" {
  XDG_CONFIG_HOME='/custom config'
  run path__config-home
  [ "${output}" = '/custom config' ]

  unset XDG_CONFIG_HOME
  HOME='/Users/example'
  run path__config-home
  [ "${output}" = '/Users/example/.config' ]

  XDG_CONFIG_HOME='relative'
  run path__config-home
  [ "${status}" -eq 64 ]
}

@test "system functions report the current environment" {
  run system__operating-system
  [ "${status}" -eq 0 ]
  [[ "${output}" = 'darwin' || "${output}" = 'linux' ]]

  HOSTNAME='fixed-host'
  run system__host-name
  [ "${output}" = 'fixed-host' ]
}

@test "sleep controls use the platform root helper" {
  local operating_system='linux'
  system__operating-system() { printf '%s\n' "${operating_system}"; }
  command__require() { [[ "$1" == systemctl || "$1" == pmset ]]; }
  command__run-as-root() { printf '%s\n' "$*" >>"${BATS_TEST_TMPDIR}/root-commands"; }

  run system__disable-sleep
  [ "${status}" -eq 0 ]
  [ "$(<"${BATS_TEST_TMPDIR}/root-commands")" = 'systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target' ]

  : >"${BATS_TEST_TMPDIR}/root-commands"
  run system__enable-sleep
  [ "${status}" -eq 0 ]
  [ "$(<"${BATS_TEST_TMPDIR}/root-commands")" = 'systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target' ]

  operating_system='darwin'
  : >"${BATS_TEST_TMPDIR}/root-commands"
  run system__disable-sleep
  [ "${status}" -eq 0 ]
  [ "$(<"${BATS_TEST_TMPDIR}/root-commands")" = 'pmset -a sleep 0' ]

  run system__disable-sleep unexpected
  [ "${status}" -eq 64 ]
}

@test "shell and terminal predicates validate arguments" {
  sample__function() {
    :
  }
  shell__is-function-defined sample__function
  ! shell__is-function-defined printf

  run shell__is-function-defined
  [ "${status}" -eq 64 ]

  run terminal__is-available unexpected
  [ "${status}" -eq 64 ]
}
