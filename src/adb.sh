#!/usr/bin/env bash
# @file adb
# @brief Android devices over ADB and fastboot.
# @description Functions select a device by serial number and wrap one adb or fastboot command each.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Run an ADB command with an optional serial number.
# @internal
adb::_run() {
  [[ "$#" -ge 1 ]] || return 64
  local serial='' seen_serial=0
  local args=()
  while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == '--serial' ]]; then
      [[ "$#" -ge 2 && -n "$2" && "$seen_serial" -eq 0 ]] || return 64
      serial="$2"
      seen_serial=1
      shift 2
    else
      args+=("$1")
      shift
    fi
  done
  [[ "$seen_serial" -eq 0 ]] || args=(-s "$serial" "${args[@]}")
  docker::_run-command adb "${args[@]}"
}

# @description List --serial and, after it, the serials of the connected devices for Tab completion.
# @internal
adb::_complete-serial() {
  case "${1-}" in
    --serial) adb::device::list 2>/dev/null || true ;;
    '') printf '%s\n' --serial ;;
  esac
}

# @description List the named arguments and value candidates of adb::device::wait.
# @internal
adb::device::_wait-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::pull.
# @internal
adb::device::_pull-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::push.
# @internal
adb::device::_push-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::logcat::clear.
# @internal
adb::logcat::_clear-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::logcat::once.
# @internal
adb::logcat::_once-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::logcat::continuous.
# @internal
adb::logcat::_continuous-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::reboot.
# @internal
adb::device::_reboot-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::wait-for-path.
# @internal
adb::device::_wait-for-path-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::screen::capture-once.
# @internal
adb::device::screen::_capture-once-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::bootloader::enter.
# @internal
adb::device::bootloader::_enter-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::bootloader::unlock.
# @internal
adb::device::bootloader::_unlock-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::verity::disable.
# @internal
adb::device::verity::_disable-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::partition::remount.
# @internal
adb::device::partition::_remount-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::build::fingerprint.
# @internal
adb::device::build::_fingerprint-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::build::date.
# @internal
adb::device::build::_date-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::slot::suffix.
# @internal
adb::device::slot::_suffix-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::build::kernel-version.
# @internal
adb::device::build::_kernel-version-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::screen::capture-continuous.
# @internal
adb::device::screen::_capture-continuous-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::partition::sha256.
# @internal
adb::device::partition::_sha256-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::wake::lock.
# @internal
adb::wake::_lock-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::wake::unlock.
# @internal
adb::wake::_unlock-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::wake::list.
# @internal
adb::wake::_list-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::select-and-pull.
# @internal
adb::device::_select-and-pull-args() {
  case "${1-}" in
    --serial) adb::device::list 2>/dev/null || true ;;
    '') printf '%s\n' --output-directory --serial ;;
  esac
}

# @description Wait for an ADB device to connect, optionally selected with --serial.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The device is connected.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb wait-for-device.
# @example
#   adb::device::wait --serial emulator-5554
adb::device::wait() { adb::_run wait-for-device "$@"; }

# @description Copy files from an ADB device to the host.
#
# @arg $@ string Device paths followed by an optional host destination.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The files were copied.
# @exitcode 64 No path was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb pull.
# @example
#   adb::device::pull /sdcard/DCIM/Camera ./camera --serial emulator-5554
adb::device::pull() { [[ "$#" -ge 1 ]] || return 64; adb::_run pull "$@"; }

# @description Copy files from the host to an ADB device.
#
# @arg $@ string Host paths followed by the device destination.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The files were copied.
# @exitcode 64 No path was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb push.
# @example
#   adb::device::push app-debug.apk /data/local/tmp/
adb::device::push() { [[ "$#" -ge 1 ]] || return 64; adb::_run push "$@"; }

# @description Clear the selected device log buffers.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The log buffers were cleared.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb logcat.
# @example
#   adb::logcat::clear --serial emulator-5554
adb::logcat::clear() { adb::_run logcat -c "$@"; }

# @description Write the selected device log buffers once.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The current log buffers.
# @exitcode 0 The log was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb logcat.
# @example
#   adb::logcat::once > device.log
adb::logcat::once() { adb::_run logcat -d "$@"; }

# @description Stream logs from the selected device.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The device log, streamed until interrupted.
# @exitcode 0 adb logcat ended successfully.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb logcat.
# @example
#   adb::logcat::continuous | grep -i crash
adb::logcat::continuous() { adb::_run logcat "$@"; }

# @description Reboot the selected device.
#
# The function returns after the device has disconnected and connected again.
#
# @arg $1 integer Optional seconds to wait for the device to come back. Defaults to 60.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The device rebooted and reconnected.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb is unavailable.
# @exitcode 74 The clock or sleep failed.
# @exitcode 75 The device did not reconnect in time.
# @exitcode other The status of adb reboot.
# @example
#   adb::device::reboot 120 --serial emulator-5554
adb::device::reboot() {
  [[ "$#" -le 3 ]] || return 64
  local timeout=60 serial='' start='' state='' disconnected=0
  local serial_args=()
  if [[ "$#" -ge 1 && "$1" != '--serial' ]]; then timeout="$1"; shift; fi
  ( [[ "$timeout" =~ ^[1-9][0-9]*$ ]] ) || return 64
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial="$2"
    serial_args=(--serial "$serial")
  fi
  adb::_run reboot "${serial_args[@]}" || return "$?"
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    state="$(adb::_run get-state "${serial_args[@]}" 2>/dev/null)" || state=''
    if [[ "$state" == device ]]; then
      [[ "$disconnected" -eq 0 ]] || return 0
    else
      disconnected=1
    fi
    sleep 1 || return 74
  done
  return 75
}

# @description Write the first connected ADB device serial.
#
# @noargs
# @stdout The serial of the first connected device.
# @exitcode 0 The serial was written.
# @exitcode 1 No device is connected.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb devices.
# @example
#   serial="$(adb::device::first)"
adb::device::first() {
  [[ "$#" -eq 0 ]] || return 64
  local devices=''
  devices="$(adb::device::list)" || return "$?"
  [[ -n "$devices" ]] || return 1
  printf '%s\n' "${devices%%$'\n'*}"
}

# @description List connected ADB device serials.
#
# @noargs
# @stdout One serial per line for devices in the device state.
# @exitcode 0 The serials were written; there may be none.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb devices.
# @example
#   adb::device::list
adb::device::list() {
  [[ "$#" -eq 0 ]] || return 64
  local devices=''
  devices="$(adb::_run devices)" || return "$?"
  printf '%s\n' "$devices" | awk 'NR>1 && $2=="device" {print $1}'
}

# @description Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout.
#
# @arg $1 string Path on the device.
# @arg $2 integer Optional seconds to wait. Defaults to 30.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The path exists.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The clock or sleep failed.
# @exitcode 75 The path did not appear in time.
# @example
#   adb::device::wait-for-path /sdcard/Download/report.json 60
adb::device::wait-for-path() {
  [[ "$#" -ge 1 && "$#" -le 4 && -n "$1" ]] || return 64
  local path="$1" timeout=30 start='' quoted=''
  local serial_args=()
  shift
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then timeout="$1"; shift; fi
  ( [[ "$timeout" =~ ^[1-9][0-9]*$ ]] ) || return 64
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial_args=(--serial "$2")
  fi
  [[ "$path" != *$'\n'* && "$path" != *$'\r'* ]] || return 64
  printf -v quoted '%q' "$path"
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    adb::_run shell "test -e $quoted" "${serial_args[@]}" >/dev/null 2>&1 && return 0
    sleep 1 || return 74
  done
  return 75
}

# @description Save one screenshot atomically and print its path.
#
# @arg $1 string Optional output PNG file. Defaults to ${WORK_DIR:-.}/STAMP/STAMP-adb-image.png.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The path of the saved screenshot.
# @exitcode 0 The screenshot was saved.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The file could not be written.
# @exitcode 75 The device returned no image.
# @example
#   adb::device::screen::capture-once ./screen.png --serial emulator-5554
adb::device::screen::capture-once() {
  [[ "$#" -le 3 ]] || return 64
  local output='' stamp='' directory='' temporary=''
  local serial_args=()
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then output="$1"; shift; fi
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial_args=(--serial "$2")
  fi
  if [[ -z "$output" ]]; then
    stamp="$(date +%Y%m%dT%H%M%S)" || return 74
    output="${WORK_DIR:-.}/$stamp/$stamp-adb-image.png"
  fi
  directory="$(dirname -- "$output")" || return 74
  mkdir -p -- "$directory" || return 74
  temporary="$(mktemp "$directory/.bashstock-image.XXXXXX")" || return 74
  if ! adb::_run exec-out screencap -p "${serial_args[@]}" >"$temporary" || [[ ! -s "$temporary" ]]; then
    rm -f -- "$temporary"
    return 75
  fi
  mv -f -- "$temporary" "$output" || { rm -f -- "$temporary"; return 74; }
  printf '%s\n' "$output"
}

# @description Select one requested device path and pull it to the host.
#
# @arg $@ string Device paths to choose from.
# @option --output-directory <DIRECTORY> Host directory to copy to. Defaults to the current directory.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The selected path was copied.
# @exitcode 64 No path was given or an option has no value.
# @exitcode 74 The output directory could not be created.
# @exitcode other The status of the prompt or of adb pull.
# @example
#   adb::device::select-and-pull /sdcard/Download /sdcard/DCIM --output-directory ./device
adb::device::select-and-pull() {
  [[ "$#" -ge 1 ]] || return 64
  local output='.' serial='' selected=''
  local paths=() serial_args=()
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --output-directory) [[ "$#" -ge 2 && -n "$2" ]] || return 64; output="$2"; shift 2 ;;
      --serial) [[ "$#" -ge 2 && -n "$2" && -z "$serial" ]] || return 64; serial="$2"; shift 2 ;;
      --) shift; paths+=("$@"); break ;;
      *) paths+=("$1"); shift ;;
    esac
  done
  [[ "${#paths[@]}" -gt 0 ]] || return 64
  [[ -z "$serial" ]] || serial_args=(--serial "$serial")
  selected="$(shell::choose-one 'Select a device path' "${paths[@]}")" || return "$?"
  mkdir -p -- "$output" || return 74
  adb::_run pull "$selected" "$output" "${serial_args[@]}"
}

# @description Reboot the selected device into its bootloader.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The device is rebooting into its bootloader.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb reboot.
# @example
#   adb::device::bootloader::enter --serial 0123456789ABCDEF
# shellcheck disable=SC2329
adb::device::bootloader::enter() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::_run reboot bootloader "$@"
}

# @description Request bootloader unlocking and wait for the device to reconnect.
#
# The unlock must be confirmed on the device. Unlocking erases user data. A
# device that stays in fastboot afterwards is rebooted.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The bootloader was unlocked and ADB reconnected.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 fastboot or adb is unavailable.
# @exitcode 74 The clock or sleep failed.
# @exitcode 75 The device did not reach fastboot or ADB in time.
# @exitcode other The status of the adb or fastboot command that failed.
# @example
#   adb::device::bootloader::unlock --serial 0123456789ABCDEF
adb::device::bootloader::unlock() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  command -v fastboot >/dev/null 2>&1 || return 69
  local start='' ready=0
  local fastboot_args=()
  [[ "$#" -eq 0 ]] || fastboot_args=(-s "$2")
  adb::device::bootloader::enter "$@" || return "$?"
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < 30 )); do
    if fastboot ${fastboot_args[@]+"${fastboot_args[@]}"} getvar version >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 0.25 || return 74
  done
  [[ "$ready" -eq 1 ]] || return 75
  fastboot ${fastboot_args[@]+"${fastboot_args[@]}"} flashing unlock || return "$?"
  # Some bootloaders stay in fastboot after the unlock. fastboot reboot waits
  # forever for a missing device, so it is sent only while the device is listed.
  if adb::_fastboot-listed "$@"; then
    fastboot ${fastboot_args[@]+"${fastboot_args[@]}"} reboot || return "$?"
  fi
  adb::_wait-device 60 "$@"
}

# @description Succeed when fastboot lists the selected device, or any device without --serial.
# @internal
adb::_fastboot-listed() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  local devices=''
  devices="$(fastboot devices 2>/dev/null)" || return 1
  if [[ "$#" -eq 0 ]]; then
    [[ -n "${devices}" ]]
  else
    awk -v serial="$2" '$1 == serial { found = 1 } END { exit !found }' <<<"${devices}"
  fi
}

# @description Wait for the selected device to return to the connected state.
# @internal
adb::_wait-device() {
  [[ "$#" -eq 1 || ( "$#" -eq 3 && "$2" == '--serial' && -n "$3" ) ]] || return 64
  local timeout="$1" start='' state=''
  ( [[ "$timeout" =~ ^[1-9][0-9]*$ ]] ) || return 64
  shift
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    state="$(adb::_run get-state "$@" 2>/dev/null)" || state=''
    [[ "$state" != device ]] || return 0
    sleep 1 || return 74
  done
  return 75
}

# @description Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 dm-verity is disabled and ADB reconnected.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 sleep failed.
# @exitcode 75 The device did not reconnect in time.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::device::verity::disable && adb::device::partition::remount
adb::device::verity::disable() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::_run root "$@" || return "$?"
  adb::_wait-device 60 "$@" || return "$?"
  adb::_run disable-verity "$@" || return "$?"
  adb::_run reboot "$@" || return "$?"
  sleep 5 || return 74
  adb::_wait-device 180 "$@"
}

# @description Make the system partitions of a rooted device writable.
#
# adb root and adb remount run first, and the root file system is then
# remounted read-write.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The partitions are writable.
# @exitcode 64 The arguments are invalid.
# @exitcode 75 The device did not reconnect in time.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::device::partition::remount --serial emulator-5554
adb::device::partition::remount() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::_run root "$@" || return "$?"
  adb::_wait-device 60 "$@" || return "$?"
  adb::_run remount "$@" || return "$?"
  adb::_run shell 'mount -o rw,remount /' "$@"
}

# @description Write the selected device build fingerprint.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The value of ro.build.fingerprint.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::build::fingerprint
adb::device::build::fingerprint() { adb::_run shell getprop ro.build.fingerprint "$@"; }

# @description Write the selected device build timestamp as Unix seconds.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The value of ro.build.date.utc.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   date -d "@$(adb::device::build::date)"
adb::device::build::date() { adb::_run shell getprop ro.build.date.utc "$@"; }

# @description Write the selected device active slot suffix.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The value of ro.boot.slot_suffix, such as _a; empty on devices without slots.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::slot::suffix
adb::device::slot::suffix() { adb::_run shell getprop ro.boot.slot_suffix "$@"; }

# @description Write the selected device kernel release.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The output of uname -r on the device.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::build::kernel-version
adb::device::build::kernel-version() { adb::_run shell uname -r "$@"; }

# @description Save repeated screenshots; MAX_COUNT of zero runs until interrupted.
#
# @arg $1 string Optional output directory. Defaults to ./screencap-loop.
# @arg $2 number Optional seconds between screenshots. Defaults to 1.
# @arg $3 integer Optional number of screenshots; 0 runs until interrupted. Defaults to 0.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The path of each saved screenshot.
# @exitcode 0 The requested screenshots were saved.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The directory could not be created or sleep failed.
# @exitcode other The status of adb::device::screen::capture-once.
# @example
#   adb::device::screen::capture-continuous ./frames 0.5 20
adb::device::screen::capture-continuous() {
  [[ "$#" -le 5 ]] || return 64
  local directory='./screencap-loop' interval=1 max=0 index=0
  local serial_args=()
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then directory="$1"; shift; fi
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then interval="$1"; shift; fi
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then max="$1"; shift; fi
  ( [[ "$interval" =~ ^[0-9]+([.][0-9]+)?$ && "$interval" =~ [1-9] ]] ) || return 64
  ( [[ "$max" =~ ^[0-9]+$ ]] ) || return 64
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial_args=(--serial "$2")
  fi
  mkdir -p -- "$directory" || return 74
  while [[ "$max" -eq 0 || "$index" -lt "$max" ]]; do
    adb::device::screen::capture-once "$directory/screen-${index}.png" "${serial_args[@]}" || return "$?"
    index=$((index+1))
    [[ "$max" -ne 0 && "$index" -ge "$max" ]] && break
    sleep "$interval" || return 74
  done
}

# @description Write a device partition SHA-256 checksum.
#
# @arg $1 string Partition path below /dev/block.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The output of sha256sum on the device.
# @exitcode 0 The checksum was written.
# @exitcode 64 The path or options are invalid.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::partition::sha256 /dev/block/by-name/boot_a
adb::device::partition::sha256() {
  [[ "$#" -eq 1 || "$#" -eq 3 ]] || return 64
  local path="$1"
  ( [[ "$path" =~ ^/dev/block/[A-Za-z0-9._/-]+$ && "$path" != *'..'* ]] ) || return 64
  shift
  if [[ "$#" -gt 0 ]]; then
    [[ "$1" == '--serial' && -n "$2" ]] || return 64
  fi
  adb::_run shell sha256sum "$path" "$@"
}

# @description Require a rooted ADB device for sysfs wake lock operations.
# @internal
adb::wake::_require-root() {
  adb::_run root "$@" || return "$?"
  adb::_wait-device 30 "$@" || return "$?"
  local user_id=''
  user_id="$(adb::_run shell id -u "$@")" || return "$?"
  [[ "$user_id" == 0 ]] || return 69
}

# @description Hold a kernel wake lock using a tag, defaulting to debug.
#
# The device must allow adb root.
#
# @arg $1 string Optional wake lock tag. Defaults to debug.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The wake lock is held.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb root is unavailable or /sys/power/wake_lock is not writable.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::wake::lock benchmark
adb::wake::lock() {
  [[ "$#" -le 3 ]] || return 64
  local tag=debug
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then tag="$1"; shift; fi
  ( [[ "$tag" =~ ^[A-Za-z0-9_.-]+$ ]] ) || return 64
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::wake::_require-root "$@" || return "$?"
  adb::_run shell "test -w /sys/power/wake_lock" "$@" || return 69
  adb::_run shell "printf '%s' '$tag' > /sys/power/wake_lock" "$@"
}

# @description Release a kernel wake lock using the same tag.
#
# The device must allow adb root.
#
# @arg $1 string Optional wake lock tag. Defaults to debug.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The wake lock was released.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb root is unavailable or /sys/power/wake_unlock is not writable.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::wake::unlock benchmark
adb::wake::unlock() {
  [[ "$#" -le 3 ]] || return 64
  local tag=debug
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then tag="$1"; shift; fi
  ( [[ "$tag" =~ ^[A-Za-z0-9_.-]+$ ]] ) || return 64
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::wake::_require-root "$@" || return "$?"
  adb::_run shell "test -w /sys/power/wake_unlock" "$@" || return 69
  adb::_run shell "printf '%s' '$tag' > /sys/power/wake_unlock" "$@"
}

# @description Print active kernel wake locks.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The active wake lock tags.
# @exitcode 0 The tags were written.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb root is unavailable or /sys/power/wake_lock is not readable.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::wake::list
adb::wake::list() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::wake::_require-root "$@" || return "$?"
  adb::_run shell "test -r /sys/power/wake_lock" "$@" || return 69
  adb::_run shell "cat /sys/power/wake_lock" "$@"
}

# @description Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL.
#
# @arg $1 string Device serial.
# @set ANDROID_SERIAL is exported in the current shell.
# @exitcode 0 The variable was set.
# @exitcode 64 The argument is not one valid serial.
# @example
#   adb::device::set-default "$(adb::device::first)"
adb::device::set-default() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._:-]+$ ]] ) || return 64
  export ANDROID_SERIAL="$1"
}

# @description Start the host ADB server.
#
# @noargs
# @exitcode 0 The server is running.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb start-server.
# @example
#   adb::server::start
adb::server::start() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command adb start-server; }

# @description Stop the host ADB server.
#
# @noargs
# @exitcode 0 The server stopped.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb kill-server.
# @example
#   adb::server::stop
adb::server::stop() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command adb kill-server; }

# @description Stop and then start the host ADB server.
#
# @noargs
# @exitcode 0 The server was restarted.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb.
# @example
#   adb::server::restart
adb::server::restart() { [[ "$#" -eq 0 ]] || return 64; adb::server::stop || return "$?"; adb::server::start; }
