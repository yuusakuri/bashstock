#!/usr/bin/env bats

load test_helper

write_adb_stub() {
  local bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin"
  cat >"$bin/adb" <<'SCRIPT'
#!/usr/bin/env bash
case "${ADB_TEST_MODE:-}" in
  list) printf 'List of devices attached\nready-1\tdevice\nlost\toffline\nready-2\tdevice\n' ;;
  none) printf 'List of devices attached\nlost\toffline\n' ;;
  fail) exit 49 ;;
  reboot)
    printf '%s\n' "$*" >>"$ADB_TEST_LOG"
    if [[ "$*" == *'get-state' ]]; then
      count=0
      [[ ! -f "$ADB_TEST_COUNT" ]] || count="$(cat "$ADB_TEST_COUNT")"
      count=$((count+1))
      printf '%s' "$count" >"$ADB_TEST_COUNT"
      if [[ "$count" -eq 1 ]]; then exit 1; fi
      printf 'device\n'
    fi
    ;;
  control)
    printf '%s\n' "$*" >>"$ADB_TEST_LOG"
    case "$*" in
      *'get-state') printf 'device\n' ;;
      *'shell id -u') printf '0\n' ;;
    esac
    ;;
esac
SCRIPT
  chmod +x "$bin/adb"
  PATH="$bin:$PATH"
  export PATH
}

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

@test "ADB device listing returns only connected serials and preserves command failures" {
  write_adb_stub
  export ADB_TEST_MODE=list
  run adb::device::list
  [ "$status" -eq 0 ]
  [ "$output" = $'ready-1\nready-2' ]
  run adb::device::first
  [ "$status" -eq 0 ]
  [ "$output" = ready-1 ]

  export ADB_TEST_MODE=none
  run adb::device::first
  [ "$status" -eq 1 ]
  export ADB_TEST_MODE=fail
  run adb::device::list
  [ "$status" -eq 49 ]
}

@test "ADB screenshot failure preserves an existing image and validates the serial" {
  local image="$BATS_TEST_TMPDIR/screen.png"
  printf 'original image' >"$image"
  write_adb_stub
  export ADB_TEST_MODE=fail
  run adb::device::screen::capture-once "$image" -Serial target-1
  [ "$status" -ne 0 ]
  [ "$(cat "$image")" = 'original image' ]
  run adb::device::screen::capture-once "$image" -Serial ''
  [ "$status" -eq 64 ]
}

@test "ADB reboot waits for the selected device to disconnect and reconnect" {
  export ADB_TEST_LOG="$BATS_TEST_TMPDIR/adb.log"
  export ADB_TEST_COUNT="$BATS_TEST_TMPDIR/count"
  write_adb_stub
  export ADB_TEST_MODE=reboot
  run adb::device::reboot 5 -Serial target-1
  [ "$status" -eq 0 ]
  grep -Fqx -- '-s target-1 reboot' "$ADB_TEST_LOG"
  grep -Fqx -- '-s target-1 get-state' "$ADB_TEST_LOG"
}

@test "ADB bootloader unlock uses fastboot for the selected device" {
  export ADB_TEST_LOG="$BATS_TEST_TMPDIR/adb.log"
  export FASTBOOT_TEST_LOG="$BATS_TEST_TMPDIR/fastboot.log"
  write_adb_stub
  cat >"$BATS_TEST_TMPDIR/bin/fastboot" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$FASTBOOT_TEST_LOG"
SCRIPT
  chmod +x "$BATS_TEST_TMPDIR/bin/fastboot"
  export ADB_TEST_MODE=control
  run adb::device::bootloader::unlock -Serial target-1
  [ "$status" -eq 0 ]
  grep -Fqx -- '-s target-1 reboot bootloader' "$ADB_TEST_LOG"
  grep -Fqx -- '-s target-1 getvar version' "$FASTBOOT_TEST_LOG"
  grep -Fqx -- '-s target-1 flashing unlock' "$FASTBOOT_TEST_LOG"
}

@test "ADB partition checksum rejects paths outside device blocks before execution" {
  export ADB_TEST_LOG="$BATS_TEST_TMPDIR/adb.log"
  write_adb_stub
  export ADB_TEST_MODE=control
  run adb::device::partition::sha256 '/dev/block/../bad' -Serial target-1
  [ "$status" -eq 64 ]
  [ ! -e "$ADB_TEST_LOG" ]
  run adb::device::partition::sha256 '/dev/block/by-name/system' -Serial target-1
  [ "$status" -eq 0 ]
  grep -Fqx -- '-s target-1 shell sha256sum /dev/block/by-name/system' "$ADB_TEST_LOG"
}

@test "ADB wake lock requires root and writes the requested sysfs tag" {
  export ADB_TEST_LOG="$BATS_TEST_TMPDIR/adb.log"
  write_adb_stub
  export ADB_TEST_MODE=control
  run adb::wake::lock verify -Serial target-1
  [ "$status" -eq 0 ]
  grep -Fqx -- '-s target-1 root' "$ADB_TEST_LOG"
  grep -Fqx -- '-s target-1 shell test -w /sys/power/wake_lock' "$ADB_TEST_LOG"
  grep -Fqx -- "-s target-1 shell printf '%s' 'verify' > /sys/power/wake_lock" "$ADB_TEST_LOG"
}
