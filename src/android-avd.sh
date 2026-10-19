#!/usr/bin/env bash
# @file android-avd
# @brief Android Virtual Device creation and emulator control.
# @description Virtual devices are created with avdmanager and started with the emulator of the SDK.

# shellcheck disable=SC2119,SC2120

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
  [[ -z "${api}" || "${api}" =~ ^[0-9]+$ ]] || return 64
  [[ -z "${tag}" || "${tag}" =~ ^[a-z0-9_]+$ ]] || return 64
  [[ -z "${abi}" || "${abi}" =~ ^[A-Za-z0-9_-]+$ ]] || return 64
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
  [[ "${first}" =~ ^[0-9]+(\.[0-9]+)*$ &&
    "${second}" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 64
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
  [[ "$#" -le 6 && "$1" =~ ^[A-Za-z0-9._-]+$ ]] || return 64
  local name="$1" api="${2:-}" profile="${3:-medium_phone}" tag="${4:-google_apis}"
  local abi="${5:-}" revision="${6:-}" directory='' root=''
  local candidates='' selected='' package='' installed='' command='' backup='' status=0
  [[ -z "${api}" || "${api}" =~ ^[0-9]+$ ]] || return 64
  [[ "${profile}" =~ ^[A-Za-z0-9._-]+$ && "${tag}" =~ ^[a-z0-9_]+$ ]] || return 64
  [[ -z "${revision}" || "${revision}" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 64
  [[ -z "${replace}" || "${replace}" == --replace ]] || return 64
  [[ -n "${abi}" ]] || abi="$(android::avd::_abi)" || return "$?"
  [[ "${abi}" =~ ^[A-Za-z0-9_-]+$ ]] || return 64
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
  [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64
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

# @description Start one AVD and wait for Android to finish booting.
#
# The function returns when sys.boot_completed is 1. The emulator keeps
# running in the background after the function returns.
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
# @example
#   serial="$(android::avd::start pixel_api35 '' 300 --headless)"
#   adb -s "${serial}" install app.apk
android::avd::start() {
  [[ "$#" -le 4 ]] || return 64
  local name="${1:-}" port="${2:-}" timeout="${3:-180}" headless="${4:-}"
  local directory='' avds='' serial=''
  local started='' process_id='' state='' completed='' log=''
  [[ "${timeout}" =~ ^[1-9][0-9]*$ ]] || return 64
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
  started="$(date +%s)" || { rm -f -- "${log}"; return 74; }
  while (( $(date +%s) - started < timeout )); do
    if ! kill -0 "${process_id}" 2>/dev/null; then
      cat -- "${log}" >&2
      rm -f -- "${log}"
      return 75
    fi
    state="$("${directory}/platform-tools/adb" -s "${serial}" get-state 2>/dev/null)" || state=''
    if [[ "${state}" == device ]]; then
      completed="$("${directory}/platform-tools/adb" -s "${serial}" shell getprop \
        sys.boot_completed 2>/dev/null)" || completed=''
      if [[ "${completed}" == 1 ]]; then
        rm -f -- "${log}"
        printf '%s\n' "${serial}"
        return 0
      fi
    fi
    sleep 1 || return 74
  done
  cat -- "${log}" >&2
  rm -f -- "${log}"
  return 75
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
  [[ "$#" -le 1 && ( "$#" -eq 0 || "$1" =~ ^[A-Za-z0-9._-]+$ ) ]] || return 64
  local directory='' name="${1:-}" serial='' state='' identity='' listing='' selected=''
  local started='' response=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/platform-tools/adb" ]] || return 69
  listing="$("${directory}/platform-tools/adb" devices)" || return "$?"
  while read -r serial state; do
    [[ "${serial}" =~ ^emulator-[0-9]+$ && "${state}" == device ]] || continue
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
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._-]+$ ]] || return 64
  local directory='' avds=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  avds="$(android::avd::list)" || return "$?"
  grep -Fqx -- "$1" <<<"${avds}" || return 66
  "${directory}/cmdline-tools/latest/bin/avdmanager" delete avd -n "$1"
}
