#!/usr/bin/env bats

load test_helper

@test "every selected public function is implemented" {
  source "${PROJECT_ROOT}/src/aws/aws.sh"
  source "${PROJECT_ROOT}/src/aws/imds.sh"
  source "${PROJECT_ROOT}/src/aws/ec2.sh"
  source "${PROJECT_ROOT}/src/aws/auto-scaling.sh"

  local expected=''
  local function_name=''
  expected="$(
    {
      awk '/^### Pure Bash Bibleから採用する関数$/{on=1; next} /^### Pure Bash Bibleから採用しない名前付き関数$/{on=0} on' \
        "${PROJECT_ROOT}/docs/design.md"
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

@test "the general library does not load AWS functions" {
  ! declare -F aws::instance-id >/dev/null
  ! declare -F aws::auto-scaling-group >/dev/null
}
