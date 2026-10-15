#!/usr/bin/env bats

load test_helper

@test "help::show formats the shdoc comment of a function" {
  run help::show string::trim
  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = 'NAME' ]
  [ "${lines[1]}" = '    string::trim' ]
  [[ "${output}" == *$'DESCRIPTION\n    Remove leading and trailing whitespace.'* ]]
  [[ "${output}" == *$'ARGUMENTS\n    $1 string Value to trim.'* ]]
  [[ "${output}" == *$'EXIT CODES\n    0 The value was written.\n    64 The argument count is not one.'* ]]
  [[ "${output}" == *$'EXAMPLE\n    string::trim \'  hello world  \'\n    # hello world'* ]]
}

@test "help::show lists options and joins continued description lines" {
  run help::show adb::device::reboot
  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'OPTIONS\n    --serial <SERIAL> Device serial. ADB chooses the device when omitted.'* ]]
  [[ "${output}" == *'The function returns after the device has disconnected and connected again.'* ]]
}

@test "help::show reads the documentation of a function loaded from a path with spaces" {
  local file="${BATS_TEST_TMPDIR}/library directory/bash stock.sh"
  mkdir -p "${file%/*}"
  cp "${PROJECT_ROOT}/dist/bashstock.sh" "${file}"

  run bash -c 'source "$1" && help::show number::is-integer' _ "${file}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'Test whether a value is a signed or unsigned decimal integer.'* ]]
}

@test "help::show reports unknown and undocumented functions" {
  run help::show missing::function
  [ "${status}" -eq 1 ]
  [[ "${output}" == *'No function is named missing::function.'* ]]

  sample::undocumented() { :; }
  run help::show sample::undocumented
  [ "${status}" -eq 66 ]
  [[ "${output}" == *'sample::undocumented has no documentation.'* ]]

  run help::show
  [ "${status}" -eq 64 ]
  run help::show string::trim extra
  [ "${status}" -eq 64 ]
}

@test "help::show completes public function names" {
  run help::_show-args
  [ "${status}" -eq 0 ]
  [[ $'\n'"${output}"$'\n' == *$'\nstring::trim\n'* ]]
  [[ $'\n'"${output}"$'\n' != *'::_'* ]]
}

@test "every public library function has documentation for help::show" {
  local name='' missing=()
  while IFS= read -r name; do
    help::show "${name}" >/dev/null 2>&1 || missing+=("${name}")
  done < <(help::_show-args)
  [ "${#missing[@]}" -eq 0 ] || { printf '%s\n' "${missing[@]}" >&2; false; }
}
