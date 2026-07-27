#!/usr/bin/env bash

### Prepare paths for one test.
###
### Arguments
###
### This function takes no arguments.
setup_project() {
  # shellcheck disable=SC2034
  PROJECT_ROOT="$(CDPATH='' cd -- "${BATS_TEST_DIRNAME}/.." >/dev/null 2>&1 && pwd -P)"
  # shellcheck disable=SC2034
  TOOL="${PROJECT_ROOT}/bin/mytool"
  # shellcheck disable=SC2034
  GETOPT="${PROJECT_ROOT}/libexec/mytool-getopt"
}

setup() {
  setup_project
  source "${PROJECT_ROOT}/src/settings/settings.sh"
  source "${PROJECT_ROOT}/src/library.sh"
}
