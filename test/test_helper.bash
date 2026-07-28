#!/usr/bin/env bash

### Prepare one test.
###
### Arguments
###
### This function takes no arguments.
setup() {
  # shellcheck disable=SC2034
  PROJECT_ROOT="$(CDPATH='' cd -- "${BATS_TEST_DIRNAME}/.." >/dev/null 2>&1 && pwd -P)"
  # shellcheck disable=SC2034
  TOOL="${PROJECT_ROOT}/bin/bashstock"
  # shellcheck disable=SC2034
  GETOPT="${PROJECT_ROOT}/libexec/bashstock-getopt"

  source "${PROJECT_ROOT}/src/settings/settings.sh"
  source "${PROJECT_ROOT}/src/library.sh"

  if declare -F test::load-extra-modules >/dev/null 2>&1; then
    test::load-extra-modules
  fi
}
