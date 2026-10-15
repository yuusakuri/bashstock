#!/usr/bin/env bash
# @file android
# @brief Android SDK and command-line tool installation.
# @description The SDK directory is ANDROID_HOME, then ANDROID_SDK_ROOT, then the Android Studio default.

# shellcheck disable=SC2119,SC2120

# @description Write the SDK directory selected by Android Studio or the caller.
#
# ANDROID_HOME wins, then ANDROID_SDK_ROOT, then Android Studio's default:
# ~/Library/Android/sdk on macOS and ~/Android/Sdk on Linux.
#
# @noargs
# @stdout The SDK directory, which may not exist yet.
# @stderr A message when ANDROID_HOME and ANDROID_SDK_ROOT differ.
# @exitcode 0 The directory was written.
# @exitcode 64 An argument was given, or ANDROID_HOME and ANDROID_SDK_ROOT name different SDKs.
# @example
#   ls "$(android::sdk::directory)/platforms"
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

# @description Write the official Android CLI artifact path for this OS and CPU.
# @internal
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

# @description Write the usable Android CLI command, preferring this user's local installation.
# @internal
android::_cli-command() {
  [[ "$#" -eq 0 ]] || return 64
  if [[ -x "${HOME}/.local/bin/android" ]]; then
    printf '%s\n' "${HOME}/.local/bin/android"
  else
    command -v android || return 69
  fi
}

# @description Install the official Android CLI without replacing a working copy on failure.
#
# The CLI is downloaded to a temporary directory, started once to check its
# version, and only then moved to ~/.local/bin/android.
#
# @arg $1 string Optional complete Android CLI version, such as 1.0.16500706. Defaults to the latest.
# @exitcode 0 The CLI was installed and ~/.local/bin is on PATH.
# @exitcode 64 The version is not three dot-separated numbers.
# @exitcode 69 Google publishes no CLI for this OS and CPU, or the downloaded CLI does not start or has another version.
# @exitcode 74 The download or installation failed.
# @example
#   android::cli::install
#   android --version
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

# @description Create and configure the selected SDK directory and Android CLI.
#
# ANDROID_HOME is written to the Bash and Zsh startup files and the current process.
#
# @arg $1 string Optional absolute SDK directory. Defaults to android::sdk::directory.
# @arg $2 string Optional complete Android CLI version. Defaults to the latest.
# @exitcode 0 The SDK directory and CLI are ready.
# @exitcode 64 The directory is not absolute or differs from ANDROID_HOME or ANDROID_SDK_ROOT.
# @exitcode 69 The Android CLI is unavailable for this OS and CPU.
# @exitcode 74 The directory could not be created or the CLI could not be installed.
# @example
#   android::sdk::install "${HOME}/Android/Sdk"
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

# @description Install one stable SDK package, accepting its license from standard input.
# @internal
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

# @description Install Android Platform Tools and add adb and fastboot to PATH.
#
# The SDK license is accepted automatically.
#
# @arg $1 string Optional package revision, such as 36.0.0. Defaults to the latest stable one.
# @exitcode 0 adb and fastboot are installed and on PATH.
# @exitcode 64 The revision is malformed.
# @exitcode 69 The Android CLI is unavailable, or adb or fastboot is missing after installation.
# @exitcode other The status of the Android CLI.
# @example
#   android::platform-tools::install
#   adb devices
android::platform-tools::install() {
  [[ "$#" -le 1 ]] || return 64
  android::_sdk-install platform-tools "${1:-}" || return "$?"
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/platform-tools/adb" && -x "${directory}/platform-tools/fastboot" ]] ||
    return 69
  env::add-path "${directory}/platform-tools"
}

# @description Install an Android SDK Platform and verify its android.jar file.
#
# @arg $1 integer Android API level, such as 35.
# @arg $2 string Optional package revision. Defaults to the latest stable one.
# @exitcode 0 The platform is installed.
# @exitcode 64 The API level or revision is malformed.
# @exitcode 69 The Android CLI is unavailable, or android.jar is missing after installation.
# @exitcode other The status of the Android CLI.
# @example
#   android::sdk-platform::install 35
android::sdk-platform::install() {
  [[ "$#" -ge 1 && "$#" -le 2 && "$1" =~ ^[0-9]+$ ]] || return 64
  android::_sdk-install "platforms/android-$1" "${2:-}" || return "$?"
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -s "${directory}/platforms/android-$1/android.jar" ]] || return 69
}

# @description Install one stable Build Tools version and add its executables to PATH.
#
# @arg $1 string Optional Build Tools version, such as 35.0.0. Defaults to the latest stable one.
# @arg $2 string Optional package revision. Defaults to the version's latest revision.
# @exitcode 0 Build Tools are installed and on PATH.
# @exitcode 64 The version or revision is malformed.
# @exitcode 69 The Android CLI is unavailable, or aapt2 is missing after installation.
# @exitcode other The status of the Android CLI.
# @example
#   android::build-tools::install 35.0.0
#   aapt2 version
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

# @description Install the Android Emulator into the selected SDK.
#
# On Linux, the system libraries that the emulator and its bundled libraries
# load, including libX11-xcb that it opens at run time, are installed first.
# Current emulators need glibc 2.30 or later, so Ubuntu 18.04 returns 69.
#
# @arg $1 string Optional package revision. Defaults to the latest stable one.
# @stderr A message when the installed emulator does not start.
# @exitcode 0 The emulator is installed and starts.
# @exitcode 64 The revision is malformed.
# @exitcode 69 The Android CLI is unavailable for this OS and CPU, or the emulator does not start.
# @exitcode other The status of the package manager or the Android CLI.
# @example
#   android::emulator::install
android::emulator::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform='' directory=''
  android::_cli-artifact >/dev/null || return "$?"
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_install libpulse0 libnss3 libpng16-16 libx11-6 libx11-xcb1 libxext6 libxi6 libice6 libsm6 \
        libxcb1 libxkbfile1 libbsd0 libdbus-1-3 libdrm2 libgbm1 libexpat1 libuuid1 zlib1g || return "$?"
      ;;
    fedora)
      package::_install pulseaudio-libs nss nspr libpng libX11 libX11-xcb libXext libXi libICE libSM \
        libxcb libxkbfile libbsd dbus-libs libdrm mesa-libgbm expat libuuid zlib || return "$?"
      ;;
  esac
  android::_sdk-install emulator "${1:-}" || return "$?"
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/emulator/emulator" ]] || return 69
  if ! "${directory}/emulator/emulator" -version >/dev/null; then
    console::_write-error 'The Android Emulator does not start on this system.'
    return 69
  fi
}

# @description Install SDK Command-line Tools and verify sdkmanager and avdmanager.
#
# @arg $1 string Optional package revision. Defaults to the latest stable one.
# @exitcode 0 sdkmanager and avdmanager are installed and on PATH.
# @exitcode 64 The revision is malformed.
# @exitcode 69 The Android CLI is unavailable, or a tool is missing after installation.
# @exitcode other The status of the Android CLI.
# @example
#   android::command-line-tools::install
#   avdmanager list device -c
android::command-line-tools::install() {
  [[ "$#" -le 1 ]] || return 64
  android::_sdk-install cmdline-tools/latest "${1:-}" || return "$?"
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/sdkmanager" &&
    -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  env::add-path "${directory}/cmdline-tools/latest/bin"
}
