#!/usr/bin/env bats

load test_helper

@test "every selected public function is implemented" {
  local expected=''
  local function_name=''
  expected="$(
    {
      awk '/^## 採用する関数$/{on=1; next} /^## 採用しない名前付き関数$/{on=0} on' \
        "${PROJECT_ROOT}/docs/references/pure-bash-bible.md"
      awk '/^## 採用するモジュール$/{on=1; next} /^## 採用しないモジュール$/{on=0} on' \
        "${PROJECT_ROOT}/docs/references/lobash.md"
      awk '/^## 採用する関数$/{on=1; next} /^## 対応環境の検証$/{on=0} on' \
        "${PROJECT_ROOT}/docs/references/bash-commons.md"
    } |
      perl -nle 'while (/`([a-z][a-z0-9-]*::[a-z][a-z0-9-]*)`/g) { print $1 }' |
      sort -u
  )"

  [ -n "${expected}" ]

  while IFS= read -r function_name; do
    [ -n "${function_name}" ]
    declare -F "${function_name}" >/dev/null
  done <<<"${expected}"
}

@test "regular expression functions use the regex namespace" {
  declare -F regex::is-match >/dev/null
  declare -F regex::capture-group >/dev/null
  declare -F regex::capture-groups >/dev/null

  ! declare -F string::is-match >/dev/null
  ! declare -F string::capture-group >/dev/null
  ! declare -F string::capture-groups >/dev/null
}

@test "the library loads AWS functions by default" {
  declare -F aws::instance-id >/dev/null
  declare -F aws::auto-scaling-group >/dev/null
}
