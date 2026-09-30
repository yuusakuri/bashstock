#!/usr/bin/env bats

load test_helper

write_android_stub() {
  local bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin"
  cat >"$bin/android" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$ANDROID_TEST_LOG"
case "$*" in
  *'sdk install '*)
    case "$*" in
      *'platform-tools'*) mkdir -p "$ANDROID_HOME/platform-tools"; touch "$ANDROID_HOME/platform-tools/adb" "$ANDROID_HOME/platform-tools/fastboot"; chmod +x "$ANDROID_HOME/platform-tools/"* ;;
      *'platforms/android-35'*) mkdir -p "$ANDROID_HOME/platforms/android-35"; printf jar >"$ANDROID_HOME/platforms/android-35/android.jar" ;;
      *'build-tools/35.0.0'*) mkdir -p "$ANDROID_HOME/build-tools/35.0.0"; touch "$ANDROID_HOME/build-tools/35.0.0/aapt2"; chmod +x "$ANDROID_HOME/build-tools/35.0.0/aapt2" ;;
    esac
    ;;
esac
SCRIPT
  chmod +x "$bin/android"
  PATH="$bin:$PATH"
  export PATH
}

@test "Android SDK rejects conflicting configured directories" {
  export ANDROID_HOME="$BATS_TEST_TMPDIR/first"
  export ANDROID_SDK_ROOT="$BATS_TEST_TMPDIR/second"
  run android::sdk::directory
  [ "$status" -eq 64 ]
}

@test "Android CLI rejects unsupported Linux ARM before downloading" {
  platform::_identifier() { printf 'ubuntu\n'; }
  uname() { [[ "$1" == '-m' ]] && printf 'aarch64\n'; }
  run android::cli::install
  [ "$status" -eq 69 ]
}

@test "Android component installers keep the selected SDK and explicit revision" {
  export HOME="$BATS_TEST_TMPDIR/home"
  export ANDROID_HOME="$HOME/Android SDK verify"
  export ANDROID_TEST_LOG="$BATS_TEST_TMPDIR/android.log"
  mkdir -p "$HOME" "$ANDROID_HOME"
  write_android_stub

  run android::platform-tools::install
  [ "$status" -eq 0 ]
  [ -x "$ANDROID_HOME/platform-tools/adb" ]
  run android::sdk-platform::install 35 2
  [ "$status" -eq 0 ]
  run android::build-tools::install 35.0.0
  [ "$status" -eq 0 ]
  grep -Fqx -- "--no-metrics --sdk=$ANDROID_HOME sdk install platform-tools" "$ANDROID_TEST_LOG"
  grep -Fqx -- "--no-metrics --sdk=$ANDROID_HOME sdk install --force platforms/android-35@2" "$ANDROID_TEST_LOG"
  grep -Fqx -- "--no-metrics --sdk=$ANDROID_HOME sdk install build-tools/35.0.0" "$ANDROID_TEST_LOG"
}
