#!/usr/bin/env bats

load test_helper

extract_distribution() {
  local destination="${BATS_TEST_TMPDIR}/extracted"

  mkdir -p "${destination}"
  tar -xzf "${PROJECT_ROOT}/dist/bashstock.tar.gz" -C "${destination}"
  printf '%s\n' "${destination}/bashstock"
}

@test "the distribution holds the entry point, every module, and the privileged command" {
  local root=''
  local module=''
  root="$(extract_distribution)"

  [ -f "${root}/bashstock.sh" ]
  [ -x "${root}/libexec/bashstock-root" ]

  while IFS= read -r -d '' module; do
    [ -f "${root}/src/$(basename "${module}")" ]
  done < <(find "${PROJECT_ROOT}/src" -type f -name '*.sh' -print0)
}

@test "the extracted distribution defines public functions from any directory" {
  local root=''
  root="$(extract_distribution)"

  run bash -c 'cd /; source "${1}/bashstock.sh"; string::upper hello' _ "${root}"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'HELLO' ]

  run bash -c 'cd "${1}"; source ./bashstock.sh; path::normalize ./foo/../bar' _ "${root}"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'bar' ]
}

@test "the extracted entry point resolves its own modules and privileged command" {
  local root=''
  local sibling="${BATS_TEST_TMPDIR}/sibling"
  root="$(extract_distribution)"
  mkdir -p "${sibling}"

  run bash -c 'cd "${2}"; source "${1}/bashstock.sh"; printf "%s\n" "${BASHSTOCK_ROOT}"' \
    _ "${root}" "${sibling}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${root}" ]

  [ -x "${output}/libexec/bashstock-root" ]
  [ -f "${output}/src/file.sh" ]
}

@test "a second load of the extracted entry point keeps the first definitions" {
  local root=''
  root="$(extract_distribution)"

  run bash -c '
    source "${1}/bashstock.sh"
    string::upper() {
      printf "replaced\n"
    }
    source "${1}/bashstock.sh"
    string::upper hello
  ' _ "${root}"
  [ "${status}" -eq 0 ]
  [ "${output}" = 'replaced' ]
}
