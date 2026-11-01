#!/usr/bin/env bash
# @file device-tree
# @brief Linux device tree inspection.
# @description Nodes are read from /proc/device-tree.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the node paths of the Linux device tree.
#
# @noargs
# @stdout One node path per line below /sys/firmware/devicetree/base.
# @exitcode 0 The nodes were written.
# @exitcode 64 An argument was given.
# @exitcode 66 The system has no device tree.
# @example
#   device-tree::node::list | grep -i i2c
device-tree::node::list() { [[ "$#" -eq 0 ]] || return 64; [[ -d /sys/firmware/devicetree/base ]] || return 66; find /sys/firmware/devicetree/base -mindepth 1 -print; }
