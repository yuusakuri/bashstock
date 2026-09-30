#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### List AVD names in the selected Android SDK environment.
android::avd::list() {
  [[ "$#" -eq 0 ]] || return 64
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/emulator/emulator" ]] || return 69
  "${directory}/emulator/emulator" -list-avds
}

### List hardware profiles available to avdmanager.
android::avd::profiles() {
  [[ "$#" -eq 0 ]] || return 64
  local directory=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  "${directory}/cmdline-tools/latest/bin/avdmanager" list device -c
}

### List stable system images as API, tag, ABI, and revision values.
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

### Write the ABI matching the host CPU.
android::avd::_abi() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(uname -m)" in
    x86_64 | amd64) printf 'x86_64\n' ;;
    aarch64 | arm64) printf 'arm64-v8a\n' ;;
    *) return 69 ;;
  esac
}

### Write the directory containing Android Virtual Device definitions.
android::avd::_directory() {
  [[ "$#" -eq 0 ]] || return 64
  if [[ -n "${ANDROID_AVD_HOME:-}" ]]; then
    printf '%s\n' "${ANDROID_AVD_HOME}"
  else
    printf '%s/avd\n' "${ANDROID_USER_HOME:-${HOME}/.android}"
  fi
}

### Compare SDK revision values while ignoring zero-only trailing components.
android::avd::_same-revision() {
  [[ "$#" -eq 2 ]] || return 64
  local first="$1" second="$2"
  [[ "${first}" =~ ^[0-9]+(\.[0-9]+)*$ &&
    "${second}" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 64
  while [[ "${first}" == *.0 ]]; do first="${first%.0}"; done
  while [[ "${second}" == *.0 ]]; do second="${second%.0}"; done
  [[ "${first}" == "${second}" ]]
}

### Create one AVD from a stable Google APIs image without starting it.
###
### Arguments
###
### * NAME - New AVD name.
### * API - Optional Android API number; defaults to the newest available one.
### * PROFILE - Optional avdmanager profile; defaults to medium_phone.
### * TAG - Optional image tag; defaults to google_apis.
### * ABI - Optional image ABI; defaults to the host CPU's ABI.
### * REVISION - Optional image revision. An installed image is never downgraded.
### * --replace - Replace an existing AVD after keeping a recoverable backup.
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
  if [[ -z "${revision}" ]]; then
    revision="$(printf '%s\n' "${candidates}" | awk -v api="${api}" '$1 == api {print $4}' |
      package::_sort-versions | tail -n 1)" || return "$?"
  fi
  selected="${api} ${tag} ${abi} ${revision}"
  grep -Fqx -- "${selected}" <<<"${candidates}" || return 69
  package="system-images/android-${api}/${tag}/${abi}"
  if [[ -f "${directory}/${package}/source.properties" ]]; then
    installed="$(awk -F= '$1 == "Pkg.Revision" {gsub(/[[:space:]]/, "", $2); print $2; exit}' \
      "${directory}/${package}/source.properties")"
    android::avd::_same-revision "${installed}" "${revision}" || return 69
  fi
  command="$(android::_cli-command)" || return "$?"
  "${command}" --no-metrics "--sdk=${directory}" sdk install "${package}@${revision}" < <(yes) ||
    return "$?"
  [[ -f "${directory}/${package}/source.properties" ]] || return 69
  installed="$(awk -F= '$1 == "Pkg.Revision" {gsub(/[[:space:]]/, "", $2); print $2; exit}' \
    "${directory}/${package}/source.properties")"
  android::avd::_same-revision "${installed}" "${revision}" || return 69

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

### Report whether an even emulator console port and its ADB port are both free.
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

### Write the first free emulator console port.
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

### Start one AVD and wait for Android to finish booting.
android::avd::start() {
  [[ "$#" -le 4 ]] || return 64
  local name="${1:-}" port="${2:-}" timeout="${3:-180}" headless="${4:-}"
  local directory='' avds='' serial=''
  local started='' process_id='' state='' completed=''
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
  nohup "${directory}/emulator/emulator" -avd "${name}" -port "${port}" \
    "${emulator_options[@]}" \
    >/dev/null 2>&1 </dev/null &
  process_id="$!"
  started="$(date +%s)" || return 74
  while (( $(date +%s) - started < timeout )); do
    kill -0 "${process_id}" 2>/dev/null || return 75
    state="$("${directory}/platform-tools/adb" -s "${serial}" get-state 2>/dev/null)" || state=''
    if [[ "${state}" == device ]]; then
      completed="$("${directory}/platform-tools/adb" -s "${serial}" shell getprop \
        sys.boot_completed 2>/dev/null)" || completed=''
      if [[ "${completed}" == 1 ]]; then
        printf '%s\n' "${serial}"
        return 0
      fi
    fi
    sleep 1 || return 74
  done
  return 75
}

### Stop the named AVD, or the only running AVD when no name is given.
android::avd::stop() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' command=''
  directory="$(android::sdk::directory)" || return "$?"
  command="$(android::_cli-command)" || return "$?"
  if [[ "$#" -eq 0 ]]; then
    "${command}" --no-metrics "--sdk=${directory}" emulator stop
  else
    "${command}" --no-metrics "--sdk=${directory}" emulator stop "$1"
  fi
}

### Delete one named AVD without changing other AVDs.
android::avd::delete() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._-]+$ ]] || return 64
  local directory='' avds=''
  directory="$(android::sdk::directory)" || return "$?"
  [[ -x "${directory}/cmdline-tools/latest/bin/avdmanager" ]] || return 69
  avds="$(android::avd::list)" || return "$?"
  grep -Fqx -- "$1" <<<"${avds}" || return 66
  "${directory}/cmdline-tools/latest/bin/avdmanager" delete avd -n "$1"
}
