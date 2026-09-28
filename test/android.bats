#!/usr/bin/env bats

load test_helper

@test "Android CLI lists stable Build Tools versions and honors the SDK directory" {
  local log="${BATS_TEST_TMPDIR}/android.log"
  export ANDROID_HOME="${BATS_TEST_TMPDIR}/SDK with spaces"
  android() {
    printf '%s\n' "$@" >"${log}"
    printf '%s\n' \
      'Installed packages:' \
      '  build-tools/34.0.0 34.0.0 Android SDK Build-Tools' \
      'Available packages:' \
      '  build-tools/9.0.0 9.0.0 Android SDK Build-Tools' \
      '  build-tools/35.0.0 35.0.0 Android SDK Build-Tools' \
      '  build-tools/34.0.0 34.0.0 Android SDK Build-Tools' \
      '  build-tools/36.0.0-rc1 36.0.0-rc1 Preview' \
      '  platforms/android-35 2.0 Android SDK Platform'
  }
  sdkmanager() { return 99; }
  run android::build-tools::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = $'9.0.0\n34.0.0\n35.0.0' ]
  [ "$(<"${log}")" = "$(printf '%s\n' --no-metrics "--sdk=${ANDROID_HOME}" sdk list 'build-tools/*' --all --all-versions)" ]

  run android::build-tools::latest-version
  [ "${status}" -eq 0 ]
  [ "${output}" = '35.0.0' ]
}

@test "Android Build Tools queries preserve command failures without pipefail" {
  android() { return 49; }
  set +o pipefail
  run android::build-tools::versions
  [ "${status}" -eq 49 ]
  run android::build-tools::latest-version
  [ "${status}" -eq 49 ]

  android() { printf '  build-tools/36.0.0-rc1 36.0.0-rc1 Preview\n'; }
  run android::build-tools::latest-version
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
}

@test "sdkmanager lists stable numeric versions when Android CLI is unavailable" {
  local tools="${BATS_TEST_TMPDIR}/tools"
  mkdir -p "${tools}"
  ln -s "$(command -v perl)" "${tools}/perl"
  cat >"${tools}/sdkmanager" <<'SCRIPT'
#!/bin/sh
[ "$1" = '--list' ] && [ "$2" = '--channel=0' ] || exit 98
printf '%s\n' \
  '  build-tools;9.0.0 | 9.0.0 | Android SDK Build-Tools' \
  '  build-tools;35.0.0 | 35.0.0 | Android SDK Build-Tools' \
  '  build-tools;34.0.0 | 34.0.0 | Android SDK Build-Tools' \
  '  build-tools;35.0.0 | 35.0.0 | Android SDK Build-Tools' \
  '  build-tools;36.0.0 rc1 | 36.0.0 rc1 | Preview'
SCRIPT
  chmod +x "${tools}/sdkmanager"
  query_with_tools() { (PATH="${tools}"; "$@"); }
  run query_with_tools android::build-tools::versions
  [ "${status}" -eq 0 ]
  [ "${output}" = $'9.0.0\n34.0.0\n35.0.0' ]
  run query_with_tools android::build-tools::latest-version
  [ "${status}" -eq 0 ]
  [ "${output}" = '35.0.0' ]
}

@test "Android Build Tools queries report missing commands and reject arguments" {
  local tools="${BATS_TEST_TMPDIR}/tools"
  mkdir -p "${tools}"
  ln -s "$(command -v perl)" "${tools}/perl"
  query_with_tools() { (PATH="${tools}"; "$@"); }
  run query_with_tools android::build-tools::versions
  [ "${status}" -eq 69 ]
  run query_with_tools android::build-tools::latest-version
  [ "${status}" -eq 69 ]
  run query_with_tools android::build-tools::versions extra
  [ "${status}" -eq 64 ]
  run query_with_tools android::build-tools::latest-version extra
  [ "${status}" -eq 64 ]
}
