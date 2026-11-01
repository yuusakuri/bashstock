#!/usr/bin/env bash
# @file android
# @brief Android SDK installation and virtual device control.
# @description The SDK directory is ANDROID_HOME, then ANDROID_SDK_ROOT, then the Android Studio default.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

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
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
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
  ( [[ -z "${revision}" || "${revision}" =~ ^[0-9]+(\.[0-9]+)*$ ]] ) || return 64
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
  ( [[ "$#" -ge 1 && "$#" -le 2 && "$1" =~ ^[0-9]+$ ]] ) || return 64
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
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
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
# sdkmanager and avdmanager run on Java, so a JDK is installed with jdk::install
# when neither JAVA_HOME nor PATH provides java.
#
# @arg $1 string Optional package revision. Defaults to the latest stable one.
# @exitcode 0 sdkmanager and avdmanager are installed and on PATH.
# @exitcode 64 The revision is malformed.
# @exitcode 69 The Android CLI is unavailable, or a tool is missing after installation.
# @exitcode other The status of the Android CLI or jdk::install.
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
  if [[ ! -x "${JAVA_HOME:-/nonexistent}/bin/java" ]] && ! command::exists java; then
    jdk::install || return "$?"
  fi
  env::add-path "${directory}/cmdline-tools/latest/bin"
}

# @description List AVD names in the selected Android SDK environment.
#
# @noargs
# @stdout One AVD name per line.
# @exitcode 0 The names were written.
# @exitcode 64 An argument was given, or the SDK settings conflict.
# @exitcode 69 The emulator is not installed.
# @exitcode other The status of emulator -list-avds.
# @example
#   android::avd::list | grep -Fqx pixel_api35 || android::avd::create pixel_api35 35
android::avd::list() {
  [[ "$#" -eq 0 ]] || return 64
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/emulator/emulator" ]] || return 69
  "${directory}/emulator/emulator" -list-avds
}

# @description List hardware profiles available to avdmanager.
#
# @noargs
# @stdout One profile ID per line, such as medium_phone or pixel_8.
# @exitcode 0 The profiles were written.
# @exitcode 64 An argument was given, or the SDK settings conflict.
# @exitcode 69 Command-line Tools are not installed.
# @exitcode other The status of avdmanager.
# @example
#   android::avd::profiles | grep pixel
android::avd::profiles() {
  [[ "$#" -eq 0 ]] || return 64
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  "${directory}/cmdline-tools/latest/bin/avdmanager" list device -c
}

# @description List stable system images as API, tag, ABI, and revision values.
#
# @arg $1 string Optional API level to keep, such as 35.
# @arg $2 string Optional tag to keep, such as google_apis.
# @arg $3 string Optional ABI to keep, such as arm64-v8a.
# @stdout Lines of API, tag, ABI, and revision separated by spaces.
# @exitcode 0 The images were written.
# @exitcode 64 A filter is malformed, or the SDK settings conflict.
# @exitcode 69 The Android CLI is unavailable.
# @exitcode other The status of the Android CLI.
# @example
#   android::system-images::versions 35 google_apis x86_64
#   # 35 google_apis x86_64 9
android::system-images::versions() {
  [[ "$#" -le 3 ]] || return 64
  local api="${1:-}" tag="${2:-}" abi="${3:-}" directory='' command='' listing=''
  ( [[ -z "${api}" || "${api}" =~ ^[0-9]+$ ]] ) || return 64
  ( [[ -z "${tag}" || "${tag}" =~ ^[a-z0-9_]+$ ]] ) || return 64
  ( [[ -z "${abi}" || "${abi}" =~ ^[A-Za-z0-9_-]+$ ]] ) || return 64
  directory="$(android::sdk::directory)" || return "$?"
  command="$(android::_cli-command)" || return "$?"
  listing="$("${command}" --no-metrics "--sdk=${directory}" sdk list 'system-images/*' \
    --all --all-versions)" || return "$?"
  printf '%s\n' "${listing}" | awk -v wanted_api="${api}" -v wanted_tag="${tag}" \
    -v wanted_abi="${abi}" '
    $1 ~ /^system-images\/android-[0-9]+\/[a-z0-9_]+\/[A-Za-z0-9_-]+$/ &&
    $2 ~ /^[0-9]+(\.[0-9]+)*$/ {
      split($1, parts, "/");
      number = parts[2]; sub(/^android-/, "", number);
      if ((wanted_api == "" || number == wanted_api) &&
          (wanted_tag == "" || parts[3] == wanted_tag) &&
          (wanted_abi == "" || parts[4] == wanted_abi))
        print number, parts[3], parts[4], $2;
    }' | sort -u
}

# @description Write the ABI matching the host CPU.
# @internal
android::avd::_abi() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(uname -m)" in
    x86_64 | amd64) printf 'x86_64\n' ;;
    aarch64 | arm64) printf 'arm64-v8a\n' ;;
    *) return 69 ;;
  esac
}

# @description Write the directory containing Android Virtual Device definitions.
# @internal
android::avd::_directory() {
  [[ "$#" -eq 0 ]] || return 64
  if [[ -n "${ANDROID_AVD_HOME:-}" ]]; then
    printf '%s\n' "${ANDROID_AVD_HOME}"
  else
    printf '%s/avd\n' "${ANDROID_USER_HOME:-${HOME}/.android}"
  fi
}

# @description Compare SDK revision values while ignoring zero-only trailing components.
# @internal
android::avd::_same-revision() {
  [[ "$#" -eq 2 ]] || return 64
  local first="$1" second="$2"
  ( [[ "${first}" =~ ^[0-9]+(\.[0-9]+)*$ &&
    "${second}" =~ ^[0-9]+(\.[0-9]+)*$ ]] ) || return 64
  while [[ "${first}" == *.0 ]]; do first="${first%.0}"; done
  while [[ "${second}" == *.0 ]]; do second="${second%.0}"; done
  [[ "${first}" == "${second}" ]]
}

# @description Create one AVD from a stable Google APIs image without starting it.
#
# The system image is installed first unless it is already installed. An
# existing AVD with the same name is kept unless --replace is given, and then
# it is backed up until the new one exists.
#
# @arg $1 string New AVD name: letters, digits, ., _, and -.
# @arg $2 integer Optional Android API level. Defaults to the newest available one.
# @arg $3 string Optional avdmanager profile. Defaults to medium_phone.
# @arg $4 string Optional image tag. Defaults to google_apis.
# @arg $5 string Optional image ABI. Defaults to the host CPU's ABI.
# @arg $6 string Optional image revision. Defaults to the installed one, or to the newest one when the image is not installed. An installed image is never changed, because other AVDs may use it.
# @option --replace Replace an existing AVD after keeping a recoverable backup; give it last.
# @exitcode 0 The AVD was created.
# @exitcode 64 An argument is malformed.
# @exitcode 69 Command-line Tools or the emulator is missing, no image matches, or the installed image has a different revision than the requested one.
# @exitcode 73 The AVD exists and --replace was not given, or avdmanager could not create it.
# @exitcode 74 The existing AVD could not be backed up or restored.
# @exitcode other The status of the Android CLI or avdmanager.
# @example
#   android::avd::create pixel_api35 35 pixel_8
#   android::avd::create pixel_api35 35 pixel_8 google_apis arm64-v8a '' --replace
android::avd::create() {
  [[ "$#" -ge 1 && "$#" -le 7 ]] || return 64
  local replace='' count=0
  if [[ "$#" -gt 1 && "${!#}" == --replace ]]; then
    replace='--replace'
    count=$(($#-1))
    set -- "${@:1:count}"
  fi
  ( [[ "$#" -le 6 && "$1" =~ ^[A-Za-z0-9._-]+$ ]] ) || return 64
  local name="$1" api="${2:-}" profile="${3:-medium_phone}" tag="${4:-google_apis}"
  local abi="${5:-}" revision="${6:-}" directory='' root=''
  local candidates='' selected='' package='' installed='' command='' backup='' status=0
  ( [[ -z "${api}" || "${api}" =~ ^[0-9]+$ ]] ) || return 64
  ( [[ "${profile}" =~ ^[A-Za-z0-9._-]+$ && "${tag}" =~ ^[a-z0-9_]+$ ]] ) || return 64
  ( [[ -z "${revision}" || "${revision}" =~ ^[0-9]+(\.[0-9]+)*$ ]] ) || return 64
  [[ -z "${replace}" || "${replace}" == --replace ]] || return 64
  [[ -n "${abi}" ]] || abi="$(android::avd::_abi)" || return "$?"
  ( [[ "${abi}" =~ ^[A-Za-z0-9_-]+$ ]] ) || return 64
  directory="$(android::sdk::directory)" || return "$?"
  root="$(android::avd::_directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/avdmanager" &&
    -x "${directory}/emulator/emulator" ]] || return 69
  android::avd::profiles | grep -Fqx -- "${profile}" || return 69
  if [[ "${replace}" != --replace ]] &&
    android::avd::list | grep -Fqx -- "${name}"; then
    return 73
  fi
  candidates="$(android::system-images::versions "${api}" "${tag}" "${abi}")" || return "$?"
  [[ -n "${candidates}" ]] || return 69
  if [[ -z "${api}" ]]; then
    api="$(printf '%s\n' "${candidates}" | awk '{print $1}' |
      package::_sort-versions | tail -n 1)" || return "$?"
  fi
  package="system-images/android-${api}/${tag}/${abi}"
  if [[ -f "${directory}/${package}/source.properties" ]]; then
    installed="$(awk -F= '$1 == "Pkg.Revision" {gsub(/[[:space:]]/, "", $2); print $2; exit}' \
      "${directory}/${package}/source.properties")"
  fi
  if [[ -n "${installed}" ]]; then
    # Other AVDs may use the installed image, so its revision is never changed.
    if [[ -z "${revision}" ]]; then
      revision="${installed}"
    elif ! android::avd::_same-revision "${installed}" "${revision}"; then
      console::_write-error "System image ${package} ${installed} is installed and is not changed to ${revision}."
      return 69
    fi
  else
    if [[ -z "${revision}" ]]; then
      revision="$(printf '%s\n' "${candidates}" | awk -v api="${api}" '$1 == api {print $4}' |
        package::_sort-versions | tail -n 1)" || return "$?"
    fi
    selected="${api} ${tag} ${abi} ${revision}"
    grep -Fqx -- "${selected}" <<<"${candidates}" || return 69
    command="$(android::_cli-command)" || return "$?"
    "${command}" --no-metrics "--sdk=${directory}" sdk install "${package}@${revision}" < <(yes) ||
      return "$?"
    [[ -f "${directory}/${package}/source.properties" ]] || return 69
    installed="$(awk -F= '$1 == "Pkg.Revision" {gsub(/[[:space:]]/, "", $2); print $2; exit}' \
      "${directory}/${package}/source.properties")"
    android::avd::_same-revision "${installed}" "${revision}" || return 69
  fi

  mkdir -p -- "${root}" || return 74
  if android::avd::list | grep -Fqx -- "${name}"; then
    [[ -f "${root}/${name}.ini" && -d "${root}/${name}.avd" ]] || return 69
    backup="$(package::_temporary-directory)" || return "$?"
    mv -- "${root}/${name}.ini" "${backup}/" ||
      { rm -rf -- "${backup}"; return 74; }
    mv -- "${root}/${name}.avd" "${backup}/" ||
      { mv -- "${backup}/${name}.ini" "${root}/"; rm -rf -- "${backup}"; return 74; }
  fi
  printf 'no\n' | "${directory}/cmdline-tools/latest/bin/avdmanager" create avd \
    -n "${name}" -k "${package//\//;}" -d "${profile}" -g "${tag}" -b "${abi}" ||
    status="$?"
  if [[ "${status}" -ne 0 ]]; then
    if [[ -n "${backup}" ]]; then
      rm -rf -- "${root}/${name}.ini" "${root}/${name}.avd"
      mv -- "${backup}/${name}.ini" "${backup}/${name}.avd" "${root}/" || return 74
    fi
    return "${status}"
  fi
  [[ -z "${backup}" ]] || rm -rf -- "${backup}"
  android::avd::list | grep -Fqx -- "${name}"
}

# @description Report whether an even emulator console port and its ADB port are both free.
#
# @arg $1 integer Even console port from 5554 to 5682; the ADB port is the next number.
# @exitcode 0 Both ports are free.
# @exitcode 1 One of the ports is in use.
# @exitcode 64 The port is odd or out of range.
# @exitcode 69 Neither lsof nor ss is available.
# @exitcode 74 ss failed.
# @example
#   android::avd::port::available 5556 && android::avd::start pixel_api35 5556
android::avd::port::available() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  local port="$1" occupied=''
  (( port >= 5554 && port <= 5682 && port % 2 == 0 )) || return 64
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -iTCP:"$((port+1))" 2>/dev/null | grep -q . && return 1
  elif command -v ss >/dev/null 2>&1; then
    occupied="$(ss -H -ltn)" || return 74
    printf '%s\n' "${occupied}" | awk -v first=":${port}" -v second=":$((port+1))" '
      $4 ~ first "$" || $4 ~ second "$" {found=1} END {exit !found}' && return 1
  else
    return 69
  fi
  return 0
}

# @description Write the first free emulator console port.
#
# @noargs
# @stdout An even port from 5554 to 5682.
# @exitcode 0 A free port was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Neither lsof nor ss is available.
# @exitcode 75 Every emulator port is in use.
# @example
#   port="$(android::avd::port::first)"
android::avd::port::first() {
  [[ "$#" -eq 0 ]] || return 64
  local port=0 status=0
  for ((port=5554; port<=5682; port+=2)); do
    android::avd::port::available "${port}" && { printf '%s\n' "${port}"; return 0; }
    status="$?"
    [[ "${status}" -eq 1 ]] || return "${status}"
  done
  return 75
}

# @description Succeed while a process runs; a zombie that its parent has not reaped counts as ended.
#
# android::avd::start waits in a subshell, and its parent shell reaps the
# emulator only after the subshell ends, so kill -0 alone would still find an
# emulator that has already exited.
# @internal
# @arg $1 integer Process ID.
android::avd::_process-running() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  local state='' stat=''
  if [[ -d /proc/self ]]; then
    # Linux reports the state after the command name, which may contain spaces.
    [[ -r "/proc/$1/stat" ]] || return 1
    stat="$(<"/proc/$1/stat")" || return 1
    stat="${stat##*) }"
    state="${stat%% *}"
  else
    state="$(ps -o stat= -p "$1" 2>/dev/null)" || return 1
    state="${state//[[:space:]]/}"
  fi
  [[ -n "${state}" && "${state}" != Z* ]]
}

# @description Stop an emulator that android::avd::start launched, leaving other emulators and the ADB server alone.
#
# The emulator is asked to stop through its console first, then sent TERM,
# and finally KILL if it is still running.
# @internal
# @arg $1 integer Process ID of the emulator.
# @arg $2 string adb command.
# @arg $3 string ADB serial of the emulator.
android::avd::_stop-started() {
  [[ "$#" -eq 3 ]] || return 64
  local process_id="$1" adb="$2" serial="$3" signal='' waited=0
  local signals=(TERM KILL)
  android::avd::_process-running "${process_id}" || return 0
  # Waiting for the console's answer only makes sense when the console took the command.
  if "${adb}" -s "${serial}" emu kill >/dev/null 2>&1; then
    signals=('' TERM KILL)
  fi
  for signal in "${signals[@]}"; do
    [[ -z "${signal}" ]] || kill "-${signal}" "${process_id}" 2>/dev/null || true
    waited=0
    while android::avd::_process-running "${process_id}" && (( waited < 10 )); do
      sleep 1
      waited=$((waited + 1))
    done
    android::avd::_process-running "${process_id}" || return 0
  done
  return 75
}

# @description Start one AVD and wait for Android to finish booting.
#
# The function returns when sys.boot_completed is 1. The emulator keeps
# running in the background after the function returns. When the boot times
# out or the wait is interrupted, only the emulator that this call started is
# stopped; the ADB server and other emulators keep running.
#
# @arg $1 string Optional AVD name. Defaults to the only AVD.
# @arg $2 integer Optional console port. Defaults to the first free one.
# @arg $3 integer Optional boot timeout in seconds. Defaults to 180.
# @arg $4 string Optional --headless to run without a window and audio.
# @stdout The ADB serial, such as emulator-5554.
# @stderr The emulator log when it exits or the boot times out.
# @exitcode 0 Android finished booting.
# @exitcode 1 The port is in use.
# @exitcode 64 An argument is invalid, or no name was given and there is not exactly one AVD.
# @exitcode 66 No AVD has that name.
# @exitcode 69 The emulator or Platform Tools are not installed.
# @exitcode 74 A temporary log could not be created.
# @exitcode 75 The emulator exited or Android did not boot before the timeout.
# @exitcode 130 The wait was interrupted, and the started emulator was stopped.
# @example
#   serial="$(android::avd::start pixel_api35 '' 300 --headless)"
#   adb -s "${serial}" install app.apk
android::avd::start() {
  [[ "$#" -le 4 ]] || return 64
  local name="${1:-}" port="${2:-}" timeout="${3:-180}" headless="${4:-}"
  local directory='' avds='' serial=''
  local started='' process_id='' state='' completed='' log=''
  ( [[ "${timeout}" =~ ^[1-9][0-9]*$ ]] ) || return 64
  [[ -z "${headless}" || "${headless}" == --headless ]] || return 64
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/emulator/emulator" && -x "${directory}/platform-tools/adb" ]] || return 69
  avds="$(android::avd::list)" || return "$?"
  if [[ -z "${name}" ]]; then
    [[ -n "${avds}" && "${avds}" != *$'\n'* ]] || return 64
    name="${avds}"
  fi
  grep -Fqx -- "${name}" <<<"${avds}" || return 66
  [[ -n "${port}" ]] || port="$(android::avd::port::first)" || return "$?"
  android::avd::port::available "${port}" || return "$?"
  serial="emulator-${port}"
  local emulator_options=()
  [[ -z "${headless}" ]] || emulator_options=(-no-window -no-audio)
  log="$(mktemp)" || return 74
  nohup "${directory}/emulator/emulator" -avd "${name}" -port "${port}" \
    "${emulator_options[@]}" \
    >"${log}" 2>&1 </dev/null &
  process_id="$!"
  local adb="${directory}/platform-tools/adb" status=0
  # The wait runs in a subshell so that its traps stop only this emulator and
  # leave the caller's traps as they were.
  (
    trap 'android::avd::_stop-started "${process_id}" "${adb}" "${serial}"; exit 130' INT TERM HUP
    started="$(date +%s)" || exit 74
    while (( $(date +%s) - started < timeout )); do
      android::avd::_process-running "${process_id}" || { cat -- "${log}" >&2; exit 75; }
      state="$("${adb}" -s "${serial}" get-state 2>/dev/null)" || state=''
      if [[ "${state}" == device ]]; then
        completed="$("${adb}" -s "${serial}" shell getprop sys.boot_completed 2>/dev/null)" || completed=''
        if [[ "${completed}" == 1 ]]; then
          printf '%s\n' "${serial}"
          exit 0
        fi
      fi
      sleep 1 || exit 74
    done
    cat -- "${log}" >&2
    android::avd::_stop-started "${process_id}" "${adb}" "${serial}"
    exit 75
  ) || status="$?"
  rm -f -- "${log}"
  if [[ "${status}" -ne 0 ]]; then
    # A timeout or an interruption before the subshell started its trap still stops this emulator.
    android::avd::_stop-started "${process_id}" "${adb}" "${serial}" || true
  fi
  return "${status}"
}

# @description Stop the named AVD, or the only running AVD when no name is given.
#
# Only the emulator that reports the AVD name is stopped; the ADB server and
# other emulators keep running.
#
# @arg $1 string Optional AVD name. Defaults to the only running AVD.
# @exitcode 0 The emulator stopped.
# @exitcode 64 The name is malformed, or several AVDs match.
# @exitcode 66 No running emulator matches.
# @exitcode 69 Platform Tools are not installed.
# @exitcode 74 The clock could not be read.
# @exitcode 75 The emulator refused to stop or did not stop within 60 seconds.
# @example
#   android::avd::stop pixel_api35
android::avd::stop() {
  ( [[ "$#" -le 1 && ( "$#" -eq 0 || "$1" =~ ^[A-Za-z0-9._-]+$ ) ]] ) || return 64
  local directory='' name="${1:-}" serial='' state='' identity='' listing='' selected=''
  local started='' response=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/platform-tools/adb" ]] || return 69
  listing="$("${directory}/platform-tools/adb" devices)" || return "$?"
  while read -r serial state; do
    ( [[ "${serial}" =~ ^emulator-[0-9]+$ && "${state}" == device ]] ) || continue
    identity="$("${directory}/platform-tools/adb" -s "${serial}" emu avd name)" || return "$?"
    identity="${identity%%$'\n'*}"
    identity="${identity%$'\r'}"
    [[ -z "${name}" || "${identity}" == "${name}" ]] || continue
    [[ -z "${selected}" ]] || return 64
    selected="${serial}"
  done <<<"${listing}"
  [[ -n "${selected}" ]] || return 66
  response="$("${directory}/platform-tools/adb" -s "${selected}" emu kill)" || return "$?"
  [[ "${response}" == OK* ]] || return 75
  started="$(date +%s)" || return 74
  while (( $(date +%s) - started < 60 )); do
    listing="$("${directory}/platform-tools/adb" devices)" || return "$?"
    [[ "${listing}" != *"${selected}"* ]] && return 0
    sleep 1 || return 74
  done
  return 75
}

# @description Delete one named AVD without changing other AVDs.
#
# @arg $1 string AVD name.
# @exitcode 0 The AVD was deleted.
# @exitcode 64 The name is malformed, or the argument count is not one.
# @exitcode 66 No AVD has that name.
# @exitcode 69 Command-line Tools are not installed.
# @exitcode other The status of avdmanager.
# @example
#   android::avd::delete pixel_api35
android::avd::delete() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._-]+$ ]] ) || return 64
  local directory='' avds=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  avds="$(android::avd::list)" || return "$?"
  grep -Fqx -- "$1" <<<"${avds}" || return 66
  "${directory}/cmdline-tools/latest/bin/avdmanager" delete avd -n "$1"
}

# @description Write available stable Android Build Tools versions in ascending order.
#
# Use Android CLI when available, otherwise use sdkmanager.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 1 No stable version was found.
# @exitcode 64 An argument was given.
# @exitcode 69 perl, or both android and sdkmanager, are unavailable.
# @exitcode other The status of the SDK command that failed.
# @example
#   android::build-tools::versions | tail -n 3
android::build-tools::versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local listing='' versions=''
  local arguments=(--no-metrics)
  if command -v android >/dev/null 2>&1; then
    [[ -z "${ANDROID_HOME:-}" ]] || arguments+=("--sdk=${ANDROID_HOME}")
    listing="$(android "${arguments[@]}" sdk list 'build-tools/*' --all --all-versions)" || return "$?"
  else
    command::require sdkmanager || return "$?"
    listing="$(sdkmanager --list --channel=0)" || return "$?"
  fi
  versions="$(printf '%s\n' "${listing}" | perl -ne '
    print "$1\n" if /^\s*build-tools;([0-9]+\.[0-9]+\.[0-9]+)\s*\|/
      || /^\s*build-tools\/([0-9]+\.[0-9]+\.[0-9]+)\s+[0-9]+\.[0-9]+\.[0-9]+(?=\s|$)/;
  ' | package::_sort-versions)" || return "$?"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}

# @description Write the newest available stable Android Build Tools version.
#
# @noargs
# @stdout The newest version, such as 35.0.0.
# @exitcode 0 The version was written.
# @exitcode 1 No stable version was found.
# @exitcode 64 An argument was given.
# @exitcode other The status of android::build-tools::versions.
# @example
#   sdkmanager "build-tools;$(android::build-tools::latest-version)"
android::build-tools::latest-version() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(android::build-tools::versions)" || return "$?"
  printf '%s\n' "${versions##*$'\n'}"
}
