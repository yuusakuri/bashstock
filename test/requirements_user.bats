#!/usr/bin/env bats

load test_helper

@test "command existence handles commands functions and unknown names" {
  sample::command() {
    :
  }
  command::exists printf
  command::exists sample::command
  ! command::exists command-that-does-not-exist

  run command::exists ''
  [ "${status}" -eq 64 ]
}

@test "command requirement returns unavailable status with a diagnosis" {
  run command::require command-that-does-not-exist
  [ "${status}" -eq 69 ]
  [[ "${output}" == *'Required command is unavailable'* ]]
}

@test "run-as-root validates an empty command" {
  run command::run-as-root
  [ "${status}" -eq 64 ]
}

@test "root variants dispatch exact argument values to the root helper" {
  command::run-as-root() {
    printf '%s\n' "$@"
  }

  run file::append-text-as-root '/protected file' $'text\nvalue'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'append-text\n/protected file\ntext\nvalue' ]]

  run file::replace-text-as-root '/protected file' '^name=' 'name=value'
  [[ "${output}" == *$'replace-text\n/protected file\n^name=\nname=value' ]]

  run file::replace-text-in-files-as-root '^name=' 'name=value' '/first file' '/second file'
  [[ "${output}" == *$'replace-text-in-files\n^name=\nname=value\n/first file\n/second file' ]]

  run file::replace-or-append-text-as-root '/protected file' '^name=' 'name=value'
  [[ "${output}" == *$'replace-or-append-text\n/protected file\n^name=\nname=value' ]]
}

@test "the root helper ignores an externally supplied library root" {
  local external_root="${BATS_TEST_TMPDIR}/external"
  local marker="${BATS_TEST_TMPDIR}/external-library-loaded"
  mkdir -p "${external_root}/src"
  printf 'touch %q\n' "${marker}" >"${external_root}/src/library.sh"

  run env \
    BASHSTOCK_ROOT="${external_root}" \
    BASHSTOCK_LOADED='0' \
    "${PROJECT_ROOT}/libexec/bashstock-root" unknown-operation

  [[ "${status}" -eq 64 || "${status}" -eq 77 ]]
  [ ! -e "${marker}" ]
}

@test "JSON and option requirements enforce one selected value" {
  json::require-present Field value
  json::require-present Field false
  option::require-single First value Second ''

  run json::require-present Field null
  [ "${status}" -eq 64 ]
  run option::require-single First '' Second ''
  [ "${status}" -eq 64 ]
  run option::require-single First value
  [ "${status}" -eq 64 ]
}

@test "user queries return the effective account" {
  run user::name
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]

  run user::primary-group
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]

  user::exists "$(id -un)"
  ! user::exists bashstock-user-that-does-not-exist

  if [[ "${EUID}" -eq 0 ]]; then
    user::is-root
  else
    ! user::is-root
  fi
}

@test "user creation functions validate account types before escalation" {
  run user::create-system-as-root service
  [ "${status}" -eq 64 ]
  run user::create-login-as-root _service 'Service Account'
  [ "${status}" -eq 64 ]
  run user::create-login-as-root user 'Bad:Name'
  [ "${status}" -eq 64 ]
}

@test "valid user creation requests dispatch to the operating-system provider" {
  user::exists() {
    return 1
  }
  terminal::is-available() {
    return 0
  }
  command::run-as-root() {
    printf '%s\n' "$@"
  }

  run user::create-system-as-root _service
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'create-system-user\n_service' ]]

  run user::create-login-as-root developer 'Developer Name'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'create-login-user\ndeveloper\nDeveloper Name' ]]
}

@test "recursive ownership validates the path before escalation" {
  run path::change-owner-recursively-as-root \
    "${BATS_TEST_TMPDIR}/missing" "$(id -un)"
  [ "${status}" -eq 66 ]
}
