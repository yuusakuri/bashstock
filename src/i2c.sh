#!/usr/bin/env bash
# @file i2c
# @brief I2C bus and device inspection.
# @description Buses and devices are listed with i2cdetect.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the I2C buses with i2cdetect -l.
#
# @noargs
# @stdout The output of i2cdetect -l.
# @exitcode 0 The buses were written.
# @exitcode 64 An argument was given.
# @exitcode 69 i2cdetect is unavailable.
# @exitcode other The status of i2cdetect.
# @example
#   i2c::bus::list
i2c::bus::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command i2cdetect -l; }

# @description Write the devices on one I2C bus with i2cdetect -y.
#
# @arg $1 integer I2C bus number.
# @stdout The address map that i2cdetect writes.
# @exitcode 0 The devices were written.
# @exitcode 64 The argument is not one bus number.
# @exitcode 69 i2cdetect is unavailable.
# @exitcode other The status of i2cdetect.
# @example
#   i2c::device::list 1
i2c::device::list() { ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64; docker::_run-command i2cdetect -y "$1"; }
