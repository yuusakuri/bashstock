#!/usr/bin/env bats

load test_helper

@test "base name and directory name handle lexical paths" {
  run path::directory-name '/one/two/'
  [ "${output}" = '/one' ]
  run path::directory-name 'name'
  [ "${output}" = '.' ]
  run path::directory-name '/'
  [ "${output}" = '/' ]

  run path::base-name '/one/two/'
  [ "${output}" = 'two' ]
  run path::base-name 'archive.tar.gz' '.gz'
  [ "${output}" = 'archive.tar' ]
  run path::base-name '/'
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

  path::is-directory "${directory}"
  path::is-empty-directory "${directory}"
  path::is-regular-file "${file}"
  path::is-executable "${file}"
  path::is-executable-file "${file}"
  path::is-readable "${file}"
  path::is-writable "${file}"
  path::is-symbolic-link "${link}"

  printf 'entry' >"${directory}/.hidden"
  ! path::is-empty-directory "${directory}"
}

@test "path extension handles hidden files and multiple dots" {
  run path::extension 'archive.tar.gz'
  [ "${output}" = '.gz' ]
  run path::extension '.profile'
  [ -z "${output}" ]
  run path::extension '.config.json'
  [ "${output}" = '.json' ]
  run path::extension 'name.'
  [ "${output}" = '.' ]
}

@test "normalize and relative are lexical and portable" {
  run path::normalize '/one//two/../three/.'
  [ "${output}" = '/one/three' ]
  run path::normalize '../../one/../two'
  [ "${output}" = '../../two' ]

  run path::relative '/one/two' '/one/three/four'
  [ "${output}" = '../three/four' ]
  run path::relative 'one/two' 'one/two'
  [ "${output}" = '.' ]
  run path::relative '/one' 'one'
  [ "${status}" -eq 64 ]
}

@test "configuration home follows XDG rules" {
  XDG_CONFIG_HOME='/custom config'
  run path::config-home
  [ "${output}" = '/custom config' ]

  unset XDG_CONFIG_HOME
  HOME='/Users/example'
  run path::config-home
  [ "${output}" = '/Users/example/.config' ]

  XDG_CONFIG_HOME='relative'
  run path::config-home
  [ "${status}" -eq 64 ]
}

@test "system functions report the current environment" {
  run system::operating-system
  [ "${status}" -eq 0 ]
  [[ "${output}" = 'darwin' || "${output}" = 'linux' ]]

  HOSTNAME='fixed-host'
  run system::host-name
  [ "${output}" = 'fixed-host' ]
}

@test "shell and terminal predicates validate arguments" {
  sample::function() {
    :
  }
  shell::is-function-defined sample::function
  ! shell::is-function-defined printf

  run shell::is-function-defined
  [ "${status}" -eq 64 ]

  run terminal::is-available unexpected
  [ "${status}" -eq 64 ]
}
