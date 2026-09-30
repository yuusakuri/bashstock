#!/usr/bin/env bats

load test_helper

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

@test "AVD creation keeps an existing name and refuses an image downgrade" {
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
  sed -i.bak 's/Pkg.Revision=9/Pkg.Revision=8/' \
    "$ANDROID_HOME/system-images/android-35/google_apis/arm64-v8a/source.properties"
  run android::avd::create another_avd 35
  [ "$status" -eq 69 ]
  [ ! -e "$ANDROID_AVD_HOME/another_avd.ini" ]
}
