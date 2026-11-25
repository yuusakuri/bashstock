#!/usr/bin/env bash
# @file usb
# @brief USB devices, partitions, and file systems.
# @description Devices are listed with lsusb and lsblk.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the USB devices with lsusb.
#
# @noargs
# @stdout The output of lsusb.
# @exitcode 0 The devices were written.
# @exitcode 64 An argument was given.
# @exitcode 69 lsusb is unavailable.
# @exitcode other The status of lsusb.
# @example
#   usb__device__list
usb__device__list() { [[ "$#" -eq 0 ]] || return 64; _docker__run-command lsusb; }

# @description Select a USB partition, or a USB disk without partitions, and write its device path.
#
# One candidate is selected automatically; several are offered for
# interactive selection with their size, file system, and label.
#
# @noargs
# @stdout The device path, such as /dev/sdb1.
# @exitcode 0 The path was written.
# @exitcode 1 No USB block device is connected.
# @exitcode 64 An argument was given.
# @exitcode other The status of lsblk or the prompt.
# @example
#   device="$(usb__partition__select)"
usb__partition__select() {
  [[ "$#" -eq 0 ]] || return 64
  local candidates='' line='' selected=''
  local choices=()
  candidates="$(_usb__candidates)" || return "$?"
  [[ -n "${candidates}" ]] || return 1
  if [[ "${candidates}" != *$'\n'* ]]; then
    printf '%s\n' "${candidates%%$'\t'*}"
    return 0
  fi
  while IFS= read -r line; do
    choices+=("${line//$'\t'/ }")
  done <<<"${candidates}"
  selected="$(shell__choose-one 'Select a USB device' "${choices[@]}")" || return "$?"
  printf '%s\n' "${selected%% *}"
}

# @description Unmount every mount point of a block device through administrator execution.
# @internal
_usb__unmount() {
  [[ "$#" -eq 1 && -b "$1" ]] || return 64
  command__require findmnt || return "$?"
  local mount_point='' mount_points='' status=0
  # lsblk's MOUNTPOINT column holds only one location, and MOUNTPOINTS is
  # missing before util-linux 2.37, so findmnt lists every mount of the device.
  # Status 1 means no mount; any other failure stops before the file system is used.
  mount_points="$(findmnt -n -l -o TARGET --source "$1")" || status="$?"
  case "${status}" in
    0) ;;
    1) mount_points='' ;;
    *) return 74 ;;
  esac
  while IFS= read -r mount_point; do
    [[ -n "${mount_point}" ]] || continue
    command__run-as-root umount -- "${mount_point}" || return 74
  done <<<"${mount_points}"
  # A second query confirms that nothing is left mounted.
  status=0
  findmnt -n -l -o TARGET --source "$1" >/dev/null || status="$?"
  [[ "${status}" -eq 1 ]] || return 74
}

# @description Write the USB block devices that can be selected: partitions, or disks without partitions.
#
# Each line holds the device path, the size, the file system type, and the label, separated by tabs.
# @internal
_usb__candidates() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system__operating-system)" == linux ]] || return 69
  command__require lsblk || return "$?"
  local disk='' name='' type='' fstype='' size='' label='' found=0
  while IFS= read -r disk; do
    found=0
    while IFS=$'\t' read -r name type size fstype label; do
      [[ "${type}" == part ]] || continue
      found=1
      printf '%s\t%s\t%s\t%s\n' "${name}" "${size}" "${fstype}" "${label}"
    done < <(lsblk -lnpo NAME,TYPE,SIZE,FSTYPE,LABEL "${disk}" | awk 'BEGIN {OFS = "\t"} {print $1, $2, $3, $4, $5}')
    if [[ "${found}" -eq 0 ]]; then
      lsblk -dnpo NAME,SIZE,FSTYPE,LABEL "${disk}" | awk 'BEGIN {OFS = "\t"} {print $1, $2, $3, $4}'
    fi
  done < <(lsblk -dnpo NAME,TRAN | awk '$2 == "usb" {print $1}')
}

# @description Select a USB file system, unmount it, and repair it through administrator execution.
#
# FAT uses fsck.fat -a, exFAT fsck.exfat -a, and other types fsck -y.
#
# @noargs
# @exitcode 0 The file system was repaired or is clean.
# @exitcode 1 No USB block device is connected.
# @exitcode 64 An argument was given.
# @exitcode 74 The file system type could not be read.
# @exitcode other The status of the unmount or of fsck.
# @example
#   usb__filesystem__repair
usb__filesystem__repair() {
  [[ "$#" -eq 0 ]] || return 64
  local device='' type=''
  device="$(usb__partition__select)" || return "$?"
  type="$(lsblk -no FSTYPE "${device}" | head -n 1)" || return 74
  _usb__unmount "${device}" || return "$?"
  case "${type}" in
    vfat | fat | msdos) command__run-as-root fsck.fat -a "${device}" ;;
    exfat) command__run-as-root fsck.exfat -a "${device}" ;;
    *) command__run-as-root fsck -y "${device}" ;;
  esac
}

# @description Select a USB partition, unmount it, and format it as FAT32 through administrator execution.
#
# Everything on the selected partition is erased.
#
# @noargs
# @exitcode 0 The partition was formatted.
# @exitcode 1 No USB block device is connected.
# @exitcode 64 An argument was given.
# @exitcode other The status of the unmount or of mkfs.vfat.
# @example
#   usb__filesystem__format-fat32
usb__filesystem__format-fat32() {
  [[ "$#" -eq 0 ]] || return 64
  local device=''
  device="$(usb__partition__select)" || return "$?"
  _usb__unmount "${device}" || return "$?"
  command__run-as-root mkfs.vfat -F 32 "${device}"
}
