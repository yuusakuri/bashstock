#!/usr/bin/env bash
# @file pci
# @brief PCI device inspection.
# @description Devices are listed with lspci.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the PCI devices with lspci.
#
# @noargs
# @stdout The output of lspci.
# @exitcode 0 The devices were written.
# @exitcode 64 An argument was given.
# @exitcode 69 lspci is unavailable.
# @exitcode other The status of lspci.
# @example
#   pci::device::list
pci::device::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command lspci; }
