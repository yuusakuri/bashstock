#!/usr/bin/env bats

load test_helper

@test "help__show formats the shdoc comment of a function" {
  run help__show string__trim
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = 'NAME' ]
  [ "${lines[1]}" = '    string__trim' ]
  [[ "${output}" == *$'DESCRIPTION\n    Remove leading and trailing whitespace.'* ]]
  [[ "${output}" == *$'ARGUMENTS\n    $1 string Value to trim.'* ]]
  [[ "${output}" == *$'EXIT CODES\n    0 The value was written.\n    64 The argument count is not one.'* ]]
  [[ "${output}" == *$'EXAMPLE\n    string__trim \'  hello world  \'\n    # hello world'* ]]
}

@test "help__show lists options and joins continued description lines" {
  run help__show adb__device__reboot
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'OPTIONS\n    --serial <SERIAL> Device serial. ADB chooses the device when omitted.'* ]]
  [[ "${output}" == *'The function returns after the device has disconnected and connected again.'* ]]
}

@test "help__show reads the documentation of a function loaded from a path with spaces" {
  local file="${BATS_TEST_TMPDIR}/library directory/bash stock.sh"
  mkdir -p "${file%/*}"
  cp "${PROJECT_ROOT}/dist/bashstock.sh" "${file}"

  run bash -c 'source "$1" && help__show number__is-integer' _ "${file}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'Test whether a value is a signed or unsigned decimal integer.'* ]]
}

@test "help__show reports unknown and undocumented functions" {
  run help__show missing__function
  [ "${status}" -eq 1 ]
  [[ "${output}" == *'No function is named missing__function.'* ]]

  sample__undocumented() { :; }
  run help__show sample__undocumented
  [ "${status}" -eq 66 ]
  [[ "${output}" == *'sample__undocumented has no documentation.'* ]]

  run help__show
  [ "${status}" -eq 64 ]
  run help__show string__trim extra
  [ "${status}" -eq 64 ]
}

@test "help__show completes public function names" {
  run _help__show-args
  [ "${status}" -eq 0 ]
  [[ $'\n'"${output}"$'\n' == *$'\nstring__trim\n'* ]]
  [[ $'\n'"${output}"$'\n' != *$'\n_'* ]]
}

@test "every public library function has documentation for help__show" {
  local name='' missing=()
  while IFS= read -r name; do
    help__show "${name}" >/dev/null 2>&1 || missing+=("${name}")
  done < <(_help__show-args)
  [ "${#missing[@]}" -eq 0 ] || { printf '%s\n' "${missing[@]}" >&2; false; }
}
