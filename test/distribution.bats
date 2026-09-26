#!/usr/bin/env bats

load test_helper

copy_distribution() {
  local destination="${BATS_TEST_TMPDIR}/standalone directory/library file.sh"
  mkdir -p "${destination%/*}"
  cp "${PROJECT_ROOT}/dist/bashstock.sh" "${destination}"
  printf '%s\n' "${destination}"
}

@test "the standalone file includes the complete license" {
  local license=''
  license="$(sed 's/^/# /' "${PROJECT_ROOT}/LICENSE")"
  [[ "$(<"${PROJECT_ROOT}/dist/bashstock.sh")" == *"${license}"* ]]
}

@test "the copied standalone file works without sibling files or execute permission" {
  local file=''
  file="$(copy_distribution)"
  chmod 644 "${file}"

  run bash -c 'cd /; source "$1"; string::upper hello; path::normalize ./foo/../bar' _ "${file}"
  [ "${status}" -eq 0 ]
  [ "${output}" = $'HELLO\nbar' ]

  run bash -c 'cd "${1%/*}"; source "./${1##*/}"; cd /; string::upper hello' _ "${file}"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'HELLO' ]
}

@test "relative loading retains the absolute file path for privileged execution" {
  local file=''
  local directory=''
  file="$(copy_distribution)"
  directory="$(cd "${file%/*}" && pwd -P)"

  run bash -c '
    cd "${1%/*}"
    source "./${1##*/}"
    cd /
    command::run-as-root() { printf "%s\n" "$@"; }
    file::append-text-as-root "/protected file" "text"
  ' _ "${file}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${BASH}"$'\n--\n'"${directory}/${file##*/}"$'\n--internal-root\nappend-text\n/protected file\ntext' ]
}

@test "sourcing ignores inherited paths and a loaded flag from another process" {
  local file=''
  file="$(copy_distribution)"

  run env BASHSTOCK_ROOT=/missing _BASHSTOCK_FILE=/missing _BASHSTOCK_LOADED=1 \
    bash -c 'source "$1"; string::upper hello; test -f "${_BASHSTOCK_FILE}"' _ "${file}"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'HELLO' ]
}

@test "noninteractive sourcing is silent and preserves caller state and existing completion" {
  run bash -c '
    sample::run() { :; }
    sample::_run-args() { printf "%s\n" -Name; }
    complete -W retained sample::run
    before_completion="$(complete -p sample::run)"
    before_directory="${PWD}"
    before_ifs="${IFS}"
    before_options="$(set +o)"
    before_shopt="$(shopt -p)"
    trap ":" USR1
    before_traps="$(trap -p)"
    BASH_REMATCH=(retained)
    source "$1" >"$2"
    test ! -s "$2"
    test "${PWD}" = "${before_directory}"
    test "${IFS}" = "${before_ifs}"
    test "$(set +o)" = "${before_options}"
    test "$(shopt -p)" = "${before_shopt}"
    test "$(trap -p)" = "${before_traps}"
    test "${BASH_REMATCH[0]}" = retained
    test "$(complete -p sample::run)" = "${before_completion}"
    arg::completion::register-all
    complete -p sample::run
  ' _ "${PROJECT_ROOT}/dist/bashstock.sh" "${BATS_TEST_TMPDIR}/output"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'arg::completion::dispatch'* ]]
}

@test "a second load preserves definitions and explicitly enabled completion" {
  local file=''
  file="$(copy_distribution)"

  run bash -c '
    source "$1"
    string::upper() { printf "retained\n"; }
    sample::run() { :; }
    sample::_run-args() { printf "%s\n" -Name; }
    arg::completion::register-all
    before_completion="$(complete -p sample::run)"
    source "$1"
    test "$(complete -p sample::run)" = "${before_completion}"
    string::upper hello
  ' _ "${file}"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'retained' ]
}

@test "failed initialization returns failure and allows a later successful load" {
  run bash -c '
    dirname() { printf "%s\n" "$2/missing-directory"; }
    if source "$1" 2>/dev/null; then exit 99; else test "$?" -eq 66 || exit 98; fi
    test "${_BASHSTOCK_LOADED:-}" != 1 || exit 97
    unset -f dirname
    source "$1" || exit 96
    string::upper recovered
  ' _ "${PROJECT_ROOT}/dist/bashstock.sh"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'RECOVERED' ]
}

@test "the standalone library works with strict shell options and conditional sourcing" {
  run bash -euo pipefail -c '
    source "$1" || exit 99
    source "$1" || exit 98
    string::upper hello
    if regex::is-match value missing; then exit 97; fi
    file::append-text "$2" value
    file::replace-text "$2" value replacement
    test "$(<"$2")" = replacement
    if file::replace-text "$2" "[" invalid; then exit 96; else test "$?" -eq 64; fi
  ' _ "${PROJECT_ROOT}/dist/bashstock.sh" "${BATS_TEST_TMPDIR}/file"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'HELLO' ]
}

@test "interactive sourcing enables completion automatically and preserves it on reload" {
  run bash --noprofile --norc -ic '
    sample::run() { :; }
    sample::_run-args() { printf "%s\n" -Name -Count; }
    source "$1" >"$2" || exit 90
    test ! -s "$2" || exit 91
    registered="$(complete -p sample::run)" || exit 92
    [[ "${registered}" == *"-F arg::completion::dispatch"* ]] || exit 93
    COMP_WORDS=(sample::run -N)
    COMP_CWORD=1
    arg::completion::dispatch || exit 94
    [[ "${#COMPREPLY[@]}" -eq 1 && "${COMPREPLY[0]}" == -Name ]] || exit 95
    complete -W retained sample::run
    retained="$(complete -p sample::run)"
    source "$1" || exit 96
    test "$(complete -p sample::run)" = "${retained}" || exit 97
  ' _ "${PROJECT_ROOT}/dist/bashstock.sh" "${BATS_TEST_TMPDIR}/output"
  [ "${status}" -eq 0 ]
}
