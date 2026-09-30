#!/usr/bin/env bash

### Prepare one test.
###
### Arguments
###
### This function takes no arguments.
setup() {
  # shellcheck disable=SC2034
  PROJECT_ROOT="$(CDPATH='' cd -- "${BATS_TEST_DIRNAME}/.." >/dev/null 2>&1 && pwd -P)"

  # CI runners preinstall an Android SDK; tests select their own SDK and devices.
  unset ANDROID_HOME ANDROID_SDK_ROOT ANDROID_USER_HOME ANDROID_AVD_HOME ANDROID_SERIAL

  # shellcheck disable=SC1091 # The distribution is generated before the tests run.
  source "${PROJECT_ROOT}/dist/bashstock.sh"
}
