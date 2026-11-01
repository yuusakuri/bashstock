#!/usr/bin/env bash
# @file keyboard
# @brief Keyboard layouts and IME keys.
# @description Layouts are set for the system and for USB keyboards.

# shellcheck disable=SC2119,SC2120

# @description Require a keyboard layout name accepted by XKB.
# @internal
keyboard::_require-layout() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[a-z][a-z0-9_]*(\+[A-Za-z0-9_-]+)?$ ]] ) || return 64
}

# @description Set the system keyboard layout.
#
# Ubuntu replaces or appends XKBLAYOUT in /etc/default/keyboard. Other systems
# use localectl.
#
# @arg $1 string XKB layout, such as us or jp.
# @exitcode 0 The layout was set.
# @exitcode 64 The layout is malformed, or the argument count is not one.
# @exitcode 69 Neither /etc/default/keyboard nor localectl is available.
# @exitcode other The status of the file update or localectl.
# @example
#   keyboard::system-layout::set us
keyboard::system-layout::set() {
  [[ "$#" -eq 1 ]] || return 64
  keyboard::_require-layout "$1" || return "$?"
  if [[ -f /etc/default/keyboard ]]; then
    file::replace-text-or-append /etc/default/keyboard '^XKBLAYOUT=.*$' "XKBLAYOUT=\"$1\""
    return
  fi
  command::require localectl || return "$?"
  command::run-as-root localectl set-x11-keymap "$1"
}

# @description Map the Convert and Nonconvert keys of USB keyboards to henkan and muhenkan.
#
# KC_INT4 (HID usage 0x7008A, Convert) becomes henkan and KC_INT5 (HID usage
# 0x7008B, Nonconvert) becomes muhenkan, as in the reference script. The input
# method handles the keys; this function does not change IME settings. The
# hwdb entry applies to every USB keyboard, or only to the keyboard identified
# by VENDOR_ID and PRODUCT_ID.
#
# @arg $1 string Optional vendor ID as four hexadecimal digits. Requires PRODUCT_ID.
# @arg $2 string Optional product ID as four hexadecimal digits. Requires VENDOR_ID.
# @exitcode 0 The hwdb entry was written and applied.
# @exitcode 64 An ID is malformed, or only one ID was given.
# @exitcode 69 The system is not Linux, or systemd-hwdb or udevadm is unavailable.
# @exitcode other The status of the file write, systemd-hwdb, or udevadm.
# @example
#   keyboard::setup-ime-keys 4653 0001
keyboard::setup-ime-keys() {
  [[ "$#" -eq 0 || "$#" -eq 2 ]] || return 64
  local match='evdev:input:b0003v*p*' content=''
  if [[ "$#" -eq 2 ]]; then
    ( [[ "$1" =~ ^[0-9A-Fa-f]{4}$ && "$2" =~ ^[0-9A-Fa-f]{4}$ ]] ) || return 64
    match="evdev:input:b0003v$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')p$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')*"
  fi
  [[ "$(system::operating-system)" == 'linux' ]] || return 69
  command::require systemd-hwdb || return "$?"
  command::require udevadm || return "$?"
  content='# Managed by BashStock keyboard::setup-ime-keys.'$'\n'"${match}"$'\n'
  content+=' KEYBOARD_KEY_7008a=henkan'$'\n'' KEYBOARD_KEY_7008b=muhenkan'$'\n'
  file::write-text /etc/udev/hwdb.d/90-bashstock-ime-keys.hwdb "${content}" || return "$?"
  command::run-as-root systemd-hwdb update || return "$?"
  command::run-as-root udevadm trigger --subsystem-match=input --action=change
}
