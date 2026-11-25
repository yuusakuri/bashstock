#!/usr/bin/env bats

load test_helper

@test "command existence handles commands functions and unknown names" {
  sample__command() {
    :
  }
  command__exists printf
  command__exists sample__command
  ! command__exists command-that-does-not-exist

  run command__exists ''
  [ "${status}" -eq 64 ]
}

@test "command requirement returns unavailable status with a diagnosis" {
  run command__require command-that-does-not-exist
  [ "${status}" -eq 69 ]
  [[ "${output}" == *'Required command is unavailable'* ]]
}

@test "run-as-root validates an empty command" {
  run command__run-as-root
  [ "${status}" -eq 64 ]
}

@test "root variants pass exact argument values to the standalone file" {
  command__run-as-root() {
    printf '%s\n' "$@"
  }

  run file__append-text-as-root '/protected file' $'text\nvalue'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'append-text\n/protected file\ntext\nvalue' ]]

  run file__replace-text-as-root '/protected file' '^name=' 'name=value'
  [[ "${output}" == *$'replace-text\n/protected file\n^name=\nname=value' ]]

  run file__replace-text-in-files-as-root '^name=' 'name=value' '/first file' '/second file'
  [[ "${output}" == *$'replace-text-in-files\n^name=\nname=value\n/first file\n/second file' ]]

  run file__replace-or-append-text-as-root '/protected file' '^name=' 'name=value'
  [[ "${output}" == *$'replace-or-append-text\n/protected file\n^name=\nname=value' ]]
}

@test "JSON and option requirements enforce one selected value" {
  json__require-present Field value
  json__require-present Field false
  option__require-single First value Second ''

  run json__require-present Field null
  [ "${status}" -eq 64 ]
  run option__require-single First '' Second ''
  [ "${status}" -eq 64 ]
  run option__require-single First value
  [ "${status}" -eq 64 ]
}

@test "user queries return the effective account" {
  run user__name
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]

  run user__primary-group
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]

  user__exists "$(id -un)"
  ! user__exists bashstock-user-that-does-not-exist

  if [[ "${EUID}" -eq 0 ]]; then
    user__is-root
  else
    ! user__is-root
  fi
}

@test "user creation functions validate account types before escalation" {
  run user__create-system-as-root service
  [ "${status}" -eq 64 ]
  run user__create-login-as-root _service 'Service Account'
  [ "${status}" -eq 64 ]
  run user__create-login-as-root user 'Bad:Name'
  [ "${status}" -eq 64 ]
}

@test "valid user creation requests dispatch to the operating-system provider" {
  user__exists() {
    return 1
  }
  terminal__is-available() {
    return 0
  }
  command__run-as-root() {
    printf '%s\n' "$@"
  }

  run user__create-system-as-root _service
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'create-system-user\n_service' ]]

  run user__create-login-as-root developer 'Developer Name'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'create-login-user\ndeveloper\nDeveloper Name' ]]
}

@test "recursive ownership validates the path before escalation" {
  run path__change-owner-recursively-as-root \
    "${BATS_TEST_TMPDIR}/missing" "$(id -un)"
  [ "${status}" -eq 66 ]
}
