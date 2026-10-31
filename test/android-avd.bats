#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "AVD port selection checks both ports and rejects odd numbers" {
  lsof() {
    if [[ "$*" == *'5554'* || "$*" == *'5555'* ]]; then
      printf 'occupied\n'
    else
      return 1
    fi
  }
  run android::avd::port::available 5555
  [ "$status" -eq 64 ]
  run android::avd::port::available 5554
  [ "$status" -eq 1 ]
  run android::avd::port::first
  [ "$status" -eq 0 ]
  [ "$output" = 5556 ]
}

@test "AVD creation keeps an existing name and the installed image revision" {
  export HOME="$BATS_TEST_TMPDIR/home"
  export ANDROID_HOME="$HOME/Android SDK verify"
  export ANDROID_AVD_HOME="$HOME/.android/avd"
  mkdir -p "$HOME" "$ANDROID_AVD_HOME" "$ANDROID_HOME/cmdline-tools/latest/bin" \
    "$ANDROID_HOME/emulator" "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/android" <<'SCRIPT'
#!/usr/bin/env bash
case "$*" in
  *'sdk list '*)
    printf 'Available packages:\n  system-images/android-35/google_apis/arm64-v8a 9.0.0 Google APIs\n'
    ;;
  *'sdk install '*)
    mkdir -p "$ANDROID_HOME/system-images/android-35/google_apis/arm64-v8a"
    printf 'Pkg.Revision=9\n' >"$ANDROID_HOME/system-images/android-35/google_apis/arm64-v8a/source.properties"
    ;;
esac
SCRIPT
  cat >"$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" <<'SCRIPT'
#!/usr/bin/env bash
case "$*" in
  'list device -c') printf 'medium_phone\n' ;;
  'create avd '*)
    while [[ "$#" -gt 0 ]]; do
      if [[ "$1" == '-n' ]]; then name="$2"; break; fi
      shift
    done
    mkdir -p "$ANDROID_AVD_HOME/$name.avd"
    printf 'path=%s\n' "$ANDROID_AVD_HOME/$name.avd" >"$ANDROID_AVD_HOME/$name.ini"
    ;;
esac
SCRIPT
  cat >"$ANDROID_HOME/emulator/emulator" <<'SCRIPT'
#!/usr/bin/env bash
for file in "$ANDROID_AVD_HOME"/*.ini; do
  [[ -f "$file" ]] && basename "$file" .ini
done
SCRIPT
  chmod +x "$BATS_TEST_TMPDIR/bin/android" \
    "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" "$ANDROID_HOME/emulator/emulator"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export PATH
  uname() { [[ "$1" == '-m' ]] && printf 'aarch64\n'; }

  run android::avd::create test_avd 35
  [ "$status" -eq 0 ]
  [ -f "$ANDROID_AVD_HOME/test_avd.ini" ]
  run android::avd::create test_avd 35
  [ "$status" -eq 73 ]
  run android::avd::create test_avd 35 --replace
  [ "$status" -eq 0 ]
  [ -f "$ANDROID_AVD_HOME/test_avd.ini" ]
  local properties="$ANDROID_HOME/system-images/android-35/google_apis/arm64-v8a/source.properties"
  # Revision 9 is offered after 8 was installed: other AVDs may use 8, so it stays.
  printf 'Pkg.Revision=8\n' >"$properties"
  run android::avd::create default_avd 35
  [ "$status" -eq 0 ]
  [ "$(<"$properties")" = 'Pkg.Revision=8' ]
  [ -f "$ANDROID_AVD_HOME/default_avd.ini" ]
  run android::avd::create explicit_avd 35 medium_phone google_apis arm64-v8a 9
  [ "$status" -eq 69 ]
  [ "$(<"$properties")" = 'Pkg.Revision=8' ]
  [ ! -e "$ANDROID_AVD_HOME/explicit_avd.ini" ]
  run android::avd::create same_avd 35 medium_phone google_apis arm64-v8a 8.0
  [ "$status" -eq 0 ]
}

@test "AVD stop targets the named emulator and waits for disconnection" {
  export HOME="$BATS_TEST_TMPDIR/home"
  export ANDROID_HOME="$HOME/Android/Sdk"
  export ANDROID_TEST_LOG="$BATS_TEST_TMPDIR/adb.log"
  mkdir -p "$ANDROID_HOME/platform-tools"
  cat >"$ANDROID_HOME/platform-tools/adb" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$ANDROID_TEST_LOG"
case "$*" in
  devices)
    printf 'List of devices attached\n'
    if [[ ! -f "${ANDROID_TEST_LOG}.stopped" ]]; then
      printf 'emulator-5554\tdevice\nemulator-5556\tdevice\n'
    fi
    ;;
  '-s emulator-5554 emu avd name') printf 'other\nOK\n' ;;
  '-s emulator-5556 emu avd name') printf 'wanted\nOK\n' ;;
  '-s emulator-5556 emu kill')
    touch "${ANDROID_TEST_LOG}.stopped"
    printf 'OK: killing emulator, bye bye\nOK\n'
    ;;
esac
SCRIPT
  chmod +x "$ANDROID_HOME/platform-tools/adb"
  run android::avd::stop wanted
  [ "$status" -eq 0 ]
  grep -Fqx -- '-s emulator-5556 emu kill' "$ANDROID_TEST_LOG"
  ! grep -Fqx -- '-s emulator-5554 emu kill' "$ANDROID_TEST_LOG"
}

@test "AVD start stops only the emulator it started when the boot times out or is stopped" {
  export HOME="$BATS_TEST_TMPDIR/home"
  export ANDROID_HOME="$HOME/sdk" ANDROID_AVD_HOME="$HOME/.android/avd"
  unset ANDROID_SDK_ROOT
  mkdir -p "$ANDROID_AVD_HOME/test_avd.avd" "$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools"
  : >"$ANDROID_AVD_HOME/test_avd.ini"
  export EMULATOR_PID_FILE="$BATS_TEST_TMPDIR/emulator.pid"
  # An emulator that never finishes booting.
  cat >"$ANDROID_HOME/emulator/emulator" <<'SCRIPT'
#!/usr/bin/env bash
if [[ "$1" == -list-avds ]]; then
  for file in "$ANDROID_AVD_HOME"/*.ini; do basename "$file" .ini; done
  exit 0
fi
printf '%s\n' "$$" >"$EMULATOR_PID_FILE"
exec sleep 300
SCRIPT
  printf '#!/usr/bin/env bash\nexit 1\n' >"$ANDROID_HOME/platform-tools/adb"
  chmod +x "$ANDROID_HOME/emulator/emulator" "$ANDROID_HOME/platform-tools/adb"
  # A process that the call did not start, such as another emulator, keeps running.
  # Bats waits for processes that hold its descriptor 3, so the helpers close it.
  sleep 300 3>&- &
  local other="$!"

  run --separate-stderr android::avd::start test_avd 5554 2
  [ "$status" -eq 75 ]
  ! kill -0 "$(<"$EMULATOR_PID_FILE")" 2>/dev/null
  kill -0 "$other"

  rm -f "$EMULATOR_PID_FILE"
  # The caller ignores TERM like an interactive shell ignores Ctrl-C, and records the status.
  setsid bash -c 'trap "" TERM; source "$1"; android::avd::start test_avd 5554 300; printf "%s\n" "$?" >"$2"' \
    _ "$PROJECT_ROOT/dist/bashstock.sh" "$BATS_TEST_TMPDIR/status" >/dev/null 2>&1 3>&- &
  local caller="$!" waited=0
  until [[ -s "$EMULATOR_PID_FILE" ]] || (( waited >= 50 )); do sleep 0.2; waited=$((waited + 1)); done
  sleep 1
  # A shell started in the background ignores SIGINT, so TERM, which the same trap handles, stands in for Ctrl-C.
  kill -TERM -- "-$caller"
  wait "$caller"
  [ "$(<"$BATS_TEST_TMPDIR/status")" -eq 130 ]
  ! kill -0 "$(<"$EMULATOR_PID_FILE")" 2>/dev/null
  kill -0 "$other"
  kill "$other"
}
