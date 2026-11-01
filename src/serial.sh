#!/usr/bin/env bash
# @file serial
# @brief Serial device configuration and writing.
# @description Devices are configured with stty and written to directly.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Open a serial device with a configured baud rate.
#
# @arg $1 string Serial device.
# @arg $2 integer Optional baud rate. Defaults to 115200.
# @exitcode 0 The baud rate was set.
# @exitcode 64 The arguments are invalid or the device does not exist.
# @exitcode 69 stty is unavailable.
# @exitcode other The status of stty.
# @example
#   serial::configure /dev/ttyUSB0 9600
serial::configure() { [[ "$#" -ge 1 && "$#" -le 2 && -e "$1" ]] || return 64; local device="$1" baud="${2:-115200}"; command -v stty >/dev/null 2>&1 || return 69; stty -F "$device" "$baud" 2>/dev/null || stty -f "$device" "$baud"; }

# @description Write literal data to a serial device.
#
# @arg $1 string Serial device.
# @arg $2 string Data to write without a terminator.
# @exitcode 0 The data was written.
# @exitcode 1 The device could not be written.
# @exitcode 64 The argument count is not two or the device does not exist.
# @example
#   serial::write /dev/ttyUSB0 'AT'
serial::write() { [[ "$#" -eq 2 && -e "$1" ]] || return 64; printf '%s' "$2" >"$1"; }

# @description Write a command and terminator to a serial device.
#
# @arg $1 string Serial device.
# @arg $2 string Command to write.
# @arg $3 string Optional terminator: none, cr, lf, or crlf. Defaults to cr.
# @arg $4 number Optional seconds to wait after writing. Defaults to 0.
# @exitcode 0 The command was written.
# @exitcode 64 The arguments, terminator, or wait time are invalid.
# @exitcode 74 The device could not be written.
# @example
#   serial::write-command /dev/ttyUSB0 'AT+GMR' crlf 0.5
serial::write-command() {
  [[ "$#" -ge 2 && "$#" -le 4 && -e "$1" ]] || return 64
  local device="$1" data="$2" terminator="${3:-cr}" wait="${4:-0}" suffix=''
  case "$terminator" in
    none) suffix='' ;;
    cr) suffix=$'\r' ;;
    lf) suffix=$'\n' ;;
    crlf) suffix=$'\r\n' ;;
    *) return 64 ;;
  esac
  # Every argument is validated before the device receives anything.
  ( [[ "$wait" =~ ^[0-9]+([.][0-9]+)?$ ]] ) || return 64
  printf '%s%s' "$data" "$suffix" >"$device" || return 74
  [[ "$wait" == 0 ]] || sleep "$wait"
}

# @description Release a serial device so another process, such as a Python tool, can open it.
#
# The reference implementation called file-close on the device, which
# killed every holder at once; this follows file::release instead: SIGTERM
# first, SIGKILL only for holders left after the timeout.
#
# @arg $1 string Serial device path.
# @arg $2 integer Optional seconds to wait after SIGTERM. Defaults to 2.
# @exitcode 0 No process holds the device.
# @exitcode 64 The arguments are invalid or the device does not exist.
# @exitcode other The status of file::release.
# @example
#   serial::release /dev/ttyACM0 && esptool.py --port /dev/ttyACM0 chip_id
serial::release() {
  [[ "$#" -ge 1 && "$#" -le 2 && -e "$1" ]] || return 64
  file::release "$@"
}
