#!/usr/bin/env bats

load test_helper

copy_build_inputs() {
  local directory="${BATS_TEST_TMPDIR}/build project"
  mkdir -p "${directory}/scripts" "${directory}/dist"
  cp "${PROJECT_ROOT}/scripts/build" "${directory}/scripts/build"
  cp "${PROJECT_ROOT}/LICENSE" "${directory}/LICENSE"
  cp -R "${PROJECT_ROOT}/src" "${directory}/src"
  printf 'retained distribution\n' >"${directory}/dist/bashstock.sh"
  printf '%s\n' "${directory}"
}

@test "a missing build input fails without replacing the existing distribution" {
  local directory=''
  directory="$(copy_build_inputs)"
  rm "${directory}/src/number.sh"

  run bash "${directory}/scripts/build"
  [ "${status}" -ne 0 ]
  [ "$(<"${directory}/dist/bashstock.sh")" = 'retained distribution' ]
  [ "$(find "${directory}/dist" -type f | wc -l | tr -d ' ')" = 1 ]
}

@test "invalid generated syntax fails without replacing the existing distribution" {
  local directory=''
  directory="$(copy_build_inputs)"
  printf '\ninvalid::function() {\n' >>"${directory}/src/string.sh"

  run bash "${directory}/scripts/build"
  [ "${status}" -ne 0 ]
  [ "$(<"${directory}/dist/bashstock.sh")" = 'retained distribution' ]
  [ "$(find "${directory}/dist" -type f | wc -l | tr -d ' ')" = 1 ]
}

@test "the build produces only one complete distribution file" {
  local directory=''
  directory="$(copy_build_inputs)"

  run bash "${directory}/scripts/build"
  [ "${status}" -eq 0 ]
  [ "$(find "${directory}/dist" -type f | wc -l | tr -d ' ')" = 1 ]
  run bash -c 'source "$1"; string::upper built' _ "${directory}/dist/bashstock.sh"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'BUILT' ]
}
