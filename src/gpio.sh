#!/usr/bin/env bash
# @file gpio
# @brief GPIO chip and line inspection.
# @description Chips and lines are listed with the libgpiod tools.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the GPIO chips with gpiodetect.
#
# @noargs
# @stdout The output of gpiodetect.
# @exitcode 0 The chips were written.
# @exitcode 64 An argument was given.
# @exitcode 69 gpiodetect is unavailable.
# @exitcode other The status of gpiodetect.
# @example
#   gpio::chip::list
gpio::chip::list() {
  [[ "$#" -eq 0 ]] || return 64
  docker::_run-command gpiodetect
}

# @description Write the GPIO lines of one chip, or of every chip, with gpioinfo.
#
# @arg $1 string Optional chip name or number. Defaults to every chip.
# @stdout The output of gpioinfo.
# @exitcode 0 The lines were written.
# @exitcode 64 More than one argument was given.
# @exitcode 69 gpioinfo is unavailable.
# @exitcode other The status of gpioinfo.
# @example
#   gpio::line::list gpiochip0
gpio::line::list() {
  [[ "$#" -le 1 ]] || return 64
  local arguments=()
  [[ -z "${1:-}" ]] || arguments+=("$1")
  docker::_run-command gpioinfo "${arguments[@]}"
}
