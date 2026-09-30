#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### Write the SDK directory selected by Android Studio or the caller.
android::sdk::directory() {
  [[ "$#" -eq 0 ]] || return 64
  if [[ -n "${ANDROID_HOME:-}" && -n "${ANDROID_SDK_ROOT:-}" &&
    "${ANDROID_HOME}" != "${ANDROID_SDK_ROOT}" ]]; then
    console::_write-error 'ANDROID_HOME and ANDROID_SDK_ROOT identify different SDKs.'
    return 64
  fi
  if [[ -n "${ANDROID_HOME:-}" ]]; then
    printf '%s\n' "${ANDROID_HOME}"
  elif [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    printf '%s\n' "${ANDROID_SDK_ROOT}"
  elif [[ "$(package::_platform)" == darwin ]]; then
    printf '%s\n' "${HOME}/Library/Android/sdk"
  else
    printf '%s\n' "${HOME}/Android/Sdk"
  fi
}

### Write the official Android CLI artifact path for this OS and CPU.
android::_cli-artifact() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  architecture="$(uname -m)" || return 74
  case "${platform}:${architecture}" in
    darwin:arm64 | darwin:aarch64) printf 'darwin_arm64\n' ;;
    darwin:x86_64) printf 'darwin_x86_64\n' ;;
    ubuntu:x86_64 | fedora:x86_64) printf 'linux_x86_64\n' ;;
    *) console::_write-error "Android CLI does not provide ${platform}/${architecture}."; return 69 ;;
  esac
}

### Write the usable Android CLI command, preferring this user's local installation.
android::_cli-command() {
  [[ "$#" -eq 0 ]] || return 64
  if [[ -x "${HOME}/.local/bin/android" ]]; then
    printf '%s\n' "${HOME}/.local/bin/android"
  else
    command -v android || return 69
  fi
}

### Install the official Android CLI without replacing a working copy on failure.
###
### Arguments
###
### * VERSION - Optional complete Android CLI version.
android::cli::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" artifact='' temporary='' actual='' path=''
  [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 64
  artifact="$(android::_cli-artifact)" || return "$?"
  temporary="$(package::_temporary-directory)" || return "$?"
  if [[ -n "${version}" ]]; then path="${version}"; else path='latest'; fi
  package::_download "https://dl.google.com/android/cli/${path}/${artifact}/android" \
    "${temporary}/android" || { rm -rf -- "${temporary}"; return 74; }
  chmod 0755 "${temporary}/android" || { rm -rf -- "${temporary}"; return 74; }
  actual="$("${temporary}/android" --version 2>/dev/null |
    awk '/^[0-9]+\.[0-9]+\.[0-9]+$/ {print; exit}')" ||
    { rm -rf -- "${temporary}"; return 69; }
  [[ -n "${actual}" && ( -z "${version}" || "${actual}" == "${version}" ) ]] ||
    { rm -rf -- "${temporary}"; return 69; }
  mkdir -p -- "${HOME}/.local/bin" || { rm -rf -- "${temporary}"; return 74; }
  mv -f -- "${temporary}/android" "${HOME}/.local/bin/android" ||
    { rm -rf -- "${temporary}"; return 74; }
  rm -rf -- "${temporary}"
  env::add-path "${HOME}/.local/bin"
}

### Create and configure the selected SDK directory and Android CLI.
###
### Arguments
###
### * DIRECTORY - Optional SDK directory.
### * CLI_VERSION - Optional complete Android CLI version.
android::sdk::install() {
  [[ "$#" -le 2 ]] || return 64
  local directory='' selected=''
  selected="$(android::sdk::directory)" || return "$?"
  directory="${1:-${selected}}"
  [[ -n "${directory}" && "${directory}" == /* ]] || return 64
  if [[ -n "${ANDROID_HOME:-}" && "${ANDROID_HOME}" != "${directory}" ]]; then return 64; fi
  if [[ -n "${ANDROID_SDK_ROOT:-}" && "${ANDROID_SDK_ROOT}" != "${directory}" ]]; then return 64; fi
  android::cli::install "${2:-}" || return "$?"
  mkdir -p -- "${directory}" || return 74
  env::set-variable ANDROID_HOME "${directory}"
}

### Install one stable SDK package, accepting its license from standard input.
android::_sdk-install() {
  [[ "$#" -eq 2 && -n "$1" ]] || return 64
  local package="$1" revision="$2" command='' directory='' specification=''
  [[ -z "${revision}" || "${revision}" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 64
  android::_cli-artifact >/dev/null || return "$?"
  directory="$(android::sdk::directory)" || return "$?"
  [[ "${directory}" == /* ]] || return 64
  command="$(android::_cli-command)" ||
    { android::cli::install || return "$?"; command="$(android::_cli-command)" || return "$?"; }
  mkdir -p -- "${directory}" || return 74
  specification="${package}${revision:+@${revision}}"
  if [[ -n "${revision}" ]]; then
    "${command}" --no-metrics "--sdk=${directory}" sdk install --force "${specification}" < <(yes) ||
      return "$?"
  else
    "${command}" --no-metrics "--sdk=${directory}" sdk install "${specification}" < <(yes) ||
      return "$?"
  fi
  env::set-variable ANDROID_HOME "${directory}"
}

### Install Android Platform Tools and add adb and fastboot to PATH.
android::platform-tools::install() {
  [[ "$#" -le 1 ]] || return 64
  android::_sdk-install platform-tools "${1:-}" || return "$?"
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/platform-tools/adb" && -x "${directory}/platform-tools/fastboot" ]] ||
    return 69
  env::add-path "${directory}/platform-tools"
}

### Install an Android SDK Platform and verify its android.jar file.
android::sdk-platform::install() {
  [[ "$#" -ge 1 && "$#" -le 2 && "$1" =~ ^[0-9]+$ ]] || return 64
  android::_sdk-install "platforms/android-$1" "${2:-}" || return "$?"
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -s "${directory}/platforms/android-$1/android.jar" ]] || return 69
}

### Install one stable Build Tools version and add its executables to PATH.
android::build-tools::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" directory=''
  [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 64
  [[ -n "${version}" ]] || version="$(android::build-tools::latest-version)" || return "$?"
  android::_sdk-install "build-tools/${version}" "${2:-}" || return "$?"
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/build-tools/${version}/aapt2" ]] || return 69
  env::add-path "${directory}/build-tools/${version}"
}

### Install the Android Emulator into the selected SDK.
android::emulator::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform='' directory=''
  android::_cli-artifact >/dev/null || return "$?"
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu) package::_install libpulse0 || return "$?" ;;
    fedora) package::_install pulseaudio-libs || return "$?" ;;
  esac
  android::_sdk-install emulator "${1:-}" || return "$?"
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/emulator/emulator" ]] || return 69
  "${directory}/emulator/emulator" -version >/dev/null || return 69
}

### Install SDK Command-line Tools and verify sdkmanager and avdmanager.
android::command-line-tools::install() {
  [[ "$#" -le 1 ]] || return 64
  android::_sdk-install cmdline-tools/latest "${1:-}" || return "$?"
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/sdkmanager" &&
    -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  env::add-path "${directory}/cmdline-tools/latest/bin"
}
