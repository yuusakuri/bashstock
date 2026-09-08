#!/usr/bin/env bash

### Prepare one test.
###
### Arguments
###
### This function takes no arguments.
setup() {
  # shellcheck disable=SC2034
  PROJECT_ROOT="$(CDPATH='' cd -- "${BATS_TEST_DIRNAME}/.." >/dev/null 2>&1 && pwd -P)"

  # shellcheck disable=SC1091 # The distribution is generated before the tests run.
  source "${PROJECT_ROOT}/dist/bashstock/bashstock.sh"
}
