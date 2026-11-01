# gnome

GNOME desktop settings.

## Overview

Settings are written with gsettings.

## Index

* [gnome::keybinding::set-custom](#gnomekeybindingset-custom)
* [gnome::input-source::set-layout](#gnomeinput-sourceset-layout)
* [gnome::keyboard-layout::set-us](#gnomekeyboard-layoutset-us)
* [gnome::keyboard-layout::set-jp](#gnomekeyboard-layoutset-jp)
* [gnome::input-source::set-shortcuts](#gnomeinput-sourceset-shortcuts)
* [gnome::input-source::set-mozc-first](#gnomeinput-sourceset-mozc-first)
* [gnome::window::set-button-layout](#gnomewindowset-button-layout)

### gnome::keybinding::set-custom

Register a GNOME custom keyboard shortcut after removing conflicting shortcuts.

Conflicts are shortcuts with the same name, or with the same command and binding.

#### Example

```bash
gnome::keybinding::set-custom custom100 Terminal gnome-terminal '<Super>Return'
```

#### Arguments

* **$1** (string): Identifier used in the shortcut path, such as custom100.
* **$2** (string): Descriptive shortcut name.
* **$3** (string): Command that GNOME runs.
* **$4** (string): Key combination, such as <Alt>a.

#### Exit codes

* **0**: The shortcut was registered.
* **64**: The identifier is malformed or another argument is empty.
* **74**: A value could not be quoted for gsettings.
* other The status of gsettings.

### gnome::input-source::set-layout

Set GNOME input sources to Mozc followed by one XKB layout.

#### Example

```bash
gnome::input-source::set-layout us
```

#### Arguments

* **$1** (string): XKB layout, such as us or jp.

#### Exit codes

* **0**: The input sources were set.
* **64**: The layout is malformed, or the argument count is not one.
* **69**: gsettings is unavailable.
* other The status of gsettings.

### gnome::keyboard-layout::set-us

Set GNOME input sources and the system keyboard layout to Mozc and US.

#### Example

```bash
gnome::keyboard-layout::set-us
```

_Function has no arguments._

#### Exit codes

* **0**: The layouts were set.
* **64**: An argument was given.
* **69**: gsettings or the system layout tool is unavailable.
* other The status of gsettings or the system layout update.

### gnome::keyboard-layout::set-jp

Set GNOME input sources and the system keyboard layout to Mozc and JP.

#### Example

```bash
gnome::keyboard-layout::set-jp
```

_Function has no arguments._

#### Exit codes

* **0**: The layouts were set.
* **64**: An argument was given.
* **69**: gsettings or the system layout tool is unavailable.
* other The status of gsettings or the system layout update.

### gnome::input-source::set-shortcuts

Set GNOME input-source switching shortcuts and direct US and Mozc shortcuts.

The direct shortcuts are custom keyboard shortcuts that activate the US layout
or Mozc regardless of the current source.

#### Example

```bash
gnome::input-source::set-shortcuts --us '<Alt>u' --mozc '<Alt>j'
```

#### Options

* **--next \<BINDING\>**

  Next input source. Defaults to <Alt>grave.

* **--previous \<BINDING\>**

  Previous input source. Defaults to <Shift><Alt>grave.

* **--us \<BINDING\>**

  Switch to the US layout. Defaults to <Alt>semicolon.

* **--mozc \<BINDING\>**

  Switch to Mozc. Defaults to <Alt>a.

#### Exit codes

* **0**: The shortcuts were set.
* **64**: An option is unknown or has no value.
* **74**: A binding could not be quoted for gsettings.
* other The status of gsettings.

### gnome::input-source::set-mozc-first

Put Mozc first in GNOME input sources while keeping the current XKB layout.

#### Example

```bash
gnome::input-source::set-mozc-first
```

_Function has no arguments._

#### Exit codes

* **0**: The input sources were set.
* **1**: The current input sources have no XKB layout; nothing was changed.
* **64**: An argument was given.
* **69**: gsettings is unavailable.
* **74**: gsettings could not read the current input sources.
* other The status of gsettings.

### gnome::window::set-button-layout

Set the GNOME window title-bar button layout.

#### Example

```bash
gnome::window::set-button-layout close,minimize,maximize:
```

#### Arguments

* **$1** (string): Optional button layout. Defaults to appmenu:minimize,maximize,close.

#### Exit codes

* **0**: The layout was set.
* **64**: The layout has characters other than lowercase letters, commas, and colons.
* **69**: gsettings is unavailable.
* other The status of gsettings.

