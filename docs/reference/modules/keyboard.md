# keyboard

Keyboard layouts and IME keys.

## Overview

Layouts are set for the system and for USB keyboards.

## Index

* [keyboard::system-layout::set](#keyboardsystem-layoutset)
* [keyboard::setup-ime-keys](#keyboardsetup-ime-keys)

### keyboard::system-layout::set

Set the system keyboard layout.

Ubuntu replaces or appends XKBLAYOUT in /etc/default/keyboard. Other systems
use localectl.

#### Example

```bash
keyboard::system-layout::set us
```

#### Arguments

* **$1** (string): XKB layout, such as us or jp.

#### Exit codes

* **0**: The layout was set.
* **64**: The layout is malformed, or the argument count is not one.
* **69**: Neither /etc/default/keyboard nor localectl is available.
* other The status of the file update or localectl.

### keyboard::setup-ime-keys

Map USB Convert, Nonconvert, LANG1, and LANG2 keys to henkan and muhenkan.

KC_INT4 (Convert) and KC_LNG1 become henkan; KC_INT5 (Nonconvert) and
KC_LNG2 become muhenkan. This supports the HHKB US ANSI (hhkb/ansi)
alt_convert_non_convert and alt_lang keymaps in
https://github.com/yuusakuri/qmk_firmware without remapping held Alt keys.
The hwdb entry applies to every USB keyboard, or only to VENDOR_ID and
PRODUCT_ID. Use gnome::input-source::setup-ime-keys to bind the keys to
US and Mozc.

#### Example

```bash
keyboard::setup-ime-keys 4653 0001
```

#### Arguments

* **$1** (string): Optional vendor ID as four hexadecimal digits. Requires PRODUCT_ID.
* **$2** (string): Optional product ID as four hexadecimal digits. Requires VENDOR_ID.

#### Exit codes

* **0**: The hwdb entry was written and applied.
* **64**: An ID is malformed, or only one ID was given.
* **69**: The system is not Linux, or systemd-hwdb or udevadm is unavailable.
* other The status of the file write, systemd-hwdb, or udevadm.

