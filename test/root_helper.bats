#!/usr/bin/env bats

load test_helper

stub_tree() {
  local tree="${BATS_TEST_TMPDIR}/tree"
  local name=''

  mkdir -p "${tree}/libexec"
  cp "${PROJECT_ROOT}/libexec/bashstock-root" "${tree}/libexec/bashstock-root"
  for name in \
    file::append-text \
    file::replace-text \
    file::replace-text-in-files \
    file::replace-or-append-text \
    platform::_create-system-user \
    platform::_create-login-user \
    platform::_change-owner-recursively; do
    printf '%s() {\n  printf "%%s\\n" "%s" "$@"\n}\n' "${name}" "${name}"
  done >"${tree}/bashstock.sh"

  printf '%s\n' "${tree}"
}

dispatch() {
  run bash -c 'source "${1}/libexec/bashstock-root"; root::_dispatch "${@:2}"' \
    _ "$@"
}

@test "file operation names reach the matching function with the given arguments" {
  local tree=''
  tree="$(stub_tree)"

  dispatch "${tree}" append-text '/protected file' $'text\nvalue'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'file::append-text\n/protected file\ntext\nvalue' ]

  dispatch "${tree}" replace-text '/protected file' '^name=' 'name=value'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'file::replace-text\n/protected file\n^name=\nname=value' ]

  dispatch "${tree}" replace-text-in-files '^name=' 'name=value' '/first file' '/second file'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'file::replace-text-in-files\n^name=\nname=value\n/first file\n/second file' ]

  dispatch "${tree}" replace-or-append-text '/protected file' '^name=' 'name=value'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'file::replace-or-append-text\n/protected file\n^name=\nname=value' ]
}

@test "account and ownership operation names reach the platform provider" {
  local tree=''
  tree="$(stub_tree)"

  dispatch "${tree}" create-system-user _service
  [ "${status}" -eq 0 ]
  [ "${output}" = $'platform::_create-system-user\n_service' ]

  dispatch "${tree}" create-login-user developer 'Developer Name'
  [ "${status}" -eq 0 ]
  [ "${output}" = $'platform::_create-login-user\ndeveloper\nDeveloper Name' ]

  dispatch "${tree}" change-owner-recursively '/data directory' developer
  [ "${status}" -eq 0 ]
  [ "${output}" = $'platform::_change-owner-recursively\n/data directory\ndeveloper' ]
}

@test "an unlisted operation name and a missing operation name are rejected" {
  local tree=''
  tree="$(stub_tree)"

  dispatch "${tree}" unknown-operation
  [ "${status}" -eq 64 ]
  [ "${output}" = '' ]

  dispatch "${tree}" file::append-text '/protected file' text
  [ "${status}" -eq 64 ]
  [ "${output}" = '' ]

  dispatch "${tree}"
  [ "${status}" -eq 64 ]
  [ "${output}" = '' ]
}

@test "the root helper ignores an externally supplied library root" {
  local external_root="${BATS_TEST_TMPDIR}/external"
  local marker="${BATS_TEST_TMPDIR}/external-library-loaded"
  mkdir -p "${external_root}"
  printf 'touch %q\n' "${marker}" >"${external_root}/bashstock.sh"

  run env \
    BASHSTOCK_ROOT="${external_root}" \
    _BASHSTOCK_LOADED='0' \
    "${PROJECT_ROOT}/dist/bashstock/libexec/bashstock-root" unknown-operation

  [[ "${status}" -eq 64 || "${status}" -eq 77 ]]
  [ ! -e "${marker}" ]
}
