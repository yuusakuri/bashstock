# mac

macOS system, Dock, keyboard, and security settings.

## Overview

Settings are written with defaults and take effect after the related process restarts.

## Index

* [mac__wake-on-lan__enable](#mac__wake-on-lan__enable)
* [mac__sleep__disable-automatic](#mac__sleep__disable-automatic)
* [mac__sleep__enable-automatic](#mac__sleep__enable-automatic)
* [mac__software-update__enable-automatic-install](#mac__software-update__enable-automatic-install)
* [mac__software-update__disable-automatic-install](#mac__software-update__disable-automatic-install)
* [mac__keyboard__use-function-keys](#mac__keyboard__use-function-keys)
* [mac__keyboard__set-repeat](#mac__keyboard__set-repeat)
* [mac__trackpad__disable-smart-zoom](#mac__trackpad__disable-smart-zoom)
* [mac__dock__set-autohide-instant](#mac__dock__set-autohide-instant)
* [mac__dock__hide-recent-applications](#mac__dock__hide-recent-applications)
* [mac__dock__set-minimize-effect](#mac__dock__set-minimize-effect)
* [mac__dock__set-position](#mac__dock__set-position)
* [mac__applications__remove-bundled](#mac__applications__remove-bundled)
* [mac__quarantine__remove-applications](#mac__quarantine__remove-applications)
* [mac__full-disk-access__target-paths](#mac__full-disk-access__target-paths)
* [mac__full-disk-access__open](#mac__full-disk-access__open)
* [mac__full-disk-access__is-granted](#mac__full-disk-access__is-granted)
* [mac__gatekeeper__disable](#mac__gatekeeper__disable)
* [mac__setup](#mac__setup)
* [mac__keyboard__disable-option-t](#mac__keyboard__disable-option-t)

### mac__wake-on-lan__enable

Let the Mac wake from sleep through the network (Wake on LAN).

#### Example

```bash
mac__wake-on-lan__enable
```

_Function has no arguments._

#### Exit codes

* **0**: Wake on LAN is enabled.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of pmset.

### mac__sleep__disable-automatic

Disable automatic system sleep while preserving display sleep timers.

#### Example

```bash
mac__sleep__disable-automatic
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic system sleep is disabled.
* **64**: An argument was given.
* **69**: The system is not macOS or pmset is unavailable.
* **77**: sudo refused the credentials.
* other The status of pmset.

### mac__sleep__enable-automatic

Enable automatic system sleep after ten minutes while preserving display sleep timers.

#### Example

```bash
mac__sleep__enable-automatic
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic system sleep is enabled with a ten-minute timer.
* **64**: An argument was given.
* **69**: The system is not macOS or pmset is unavailable.
* **77**: sudo refused the credentials.
* other The status of pmset.

### mac__software-update__enable-automatic-install

Let macOS updates install automatically.

Automatic downloads and system data and security update settings stay unchanged.
The automatic macOS installation preference is enabled for all users.

#### Example

```bash
mac__software-update__enable-automatic-install
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic macOS installation is enabled.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults or the root command.

### mac__software-update__disable-automatic-install

Keep macOS updates downloading but stop their automatic installation.

Automatic downloads and system data and security update settings stay unchanged.
The automatic macOS installation preference is disabled for all users.

#### Example

```bash
mac__software-update__disable-automatic-install
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic macOS installation is disabled.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults or the root command.

### mac__keyboard__use-function-keys

Make F1 to F12 act as function keys without the fn key.

#### Example

```bash
mac__keyboard__use-function-keys
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__keyboard__set-repeat

Set the delay before key repeat starts and the repeat interval.

The new values apply after logging in again.

#### Example

```bash
mac__keyboard__set-repeat 15 2
```

#### Arguments

* **$1** (integer): Optional delay before repeating, in units of 15 ms. Defaults to 30.
* **$2** (integer): Optional interval between repeats, in units of 15 ms. Defaults to 1.

#### Exit codes

* **0**: The settings were written.
* **64**: A value is not a non-negative integer.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__trackpad__disable-smart-zoom

Turn off smart zoom, the two-finger double tap, on built-in and external trackpads.

#### Example

```bash
mac__trackpad__disable-smart-zoom
```

_Function has no arguments._

#### Exit codes

* **0**: The settings were written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__dock__set-autohide-instant

Show and hide the Dock immediately, without a delay or an animation.

The Dock restarts to apply the change.

#### Example

```bash
mac__dock__set-autohide-instant
```

_Function has no arguments._

#### Exit codes

* **0**: The settings were applied.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__dock__hide-recent-applications

Hide recently used applications in the Dock.

#### Example

```bash
mac__dock__hide-recent-applications
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was applied.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__dock__set-minimize-effect

Set the effect used when a window is minimized into the Dock.

#### Example

```bash
mac__dock__set-minimize-effect genie
```

#### Arguments

* **$1** (string): Optional effect: genie, scale, or suck. Defaults to scale.

#### Exit codes

* **0**: The setting was applied.
* **64**: The effect is not genie, scale, or suck.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__dock__set-position

Place the Dock on one edge of the screen.

#### Example

```bash
mac__dock__set-position bottom
```

#### Arguments

* **$1** (string): Optional position: left, bottom, or right. Defaults to left.

#### Exit codes

* **0**: The setting was applied.
* **64**: The position is not left, bottom, or right.
* **69**: The system is not macOS.
* other The status of defaults.

### mac__applications__remove-bundled

Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications.

GarageBand's sound library is removed with it. Missing applications are skipped.

#### Example

```bash
mac__applications__remove-bundled
```

_Function has no arguments._

#### Exit codes

* **0**: The applications are gone.
* **64**: An argument was given.
* **69**: The system is not macOS.
* **77**: sudo refused the credentials.
* other The status of rm.

### mac__quarantine__remove-applications

Remove the quarantine attribute from everything below /Applications.

Errors for files without the attribute are ignored.

#### Example

```bash
mac__quarantine__remove-applications
```

_Function has no arguments._

#### Exit codes

* **0**: The attributes were removed.
* **64**: An argument was given.
* **69**: The system is not macOS.

### mac__full-disk-access__target-paths

Write the programs that Full Disk Access must list for a command, a path, or an application.

Symbolic links are resolved, and a file inside an application bundle is
written as the bundle, because System Settings lists bundles. A Python
framework build re-executes as Python.app, so that bundle is written too.
A name that is neither a path nor a command is looked up as an application
in /Applications, /System/Applications, their Utilities folders, and
~/Applications.

#### Example

```bash
mac__full-disk-access__target-paths python3.12
mac__full-disk-access__target-paths Terminal
```

#### Arguments

* **$1** (string): A command name, a path, or an application name such as Terminal.

#### Exit codes

* **0**: The paths were written.
* **1**: No command or application has the name.
* **64**: The argument count is not one or the argument is empty.
* **66**: The path does not exist.
* **69**: readlink is unavailable.

#### Output on stdout

* The absolute paths to add to Full Disk Access, one per line.

### mac__full-disk-access__open

Open Full Disk Access in System Settings and show the programs to add in Finder.

macOS grants Full Disk Access only through System Settings, so the function
opens the list and reveals each program for dragging into it. A program with
an ad hoc signature, such as a Homebrew build, loses the access when an
update replaces it, which the function reports.

#### Example

```bash
mac__full-disk-access__open python3.12 Terminal
```

#### Arguments

* **...** (string): Optional command names, paths, or application names.

#### Exit codes

* **0**: System Settings opened.
* **1**: No command or application has one of the names.
* **64**: An argument is empty.
* **66**: A path does not exist.
* **69**: The system is not macOS.
* other The status of open.

#### Output on stderr

* Each program to add and a note for each ad hoc signed program.

### mac__full-disk-access__is-granted

Test whether the application that runs the current shell has Full Disk Access.

macOS usually checks the application that started the shell, such as
Terminal, so the result also applies to the programs the shell starts. The
test opens the user's privacy database, which only Full Disk Access permits.

#### Example

```bash
mac__full-disk-access__is-granted || mac__full-disk-access__open Terminal
```

_Function has no arguments._

#### Exit codes

* **0**: Full Disk Access is granted.
* **1**: Full Disk Access is not granted.
* **64**: An argument was given.
* **69**: The system is not macOS.

### mac__gatekeeper__disable

Ask macOS to allow applications from anywhere and open Privacy & Security.

Recent macOS releases apply spctl --master-disable only after the user
selects "Allow applications from anywhere" in System Settings, so a refusal
from spctl is not a failure; the function opens the settings for that step.

#### Example

```bash
mac__gatekeeper__disable
```

_Function has no arguments._

#### Exit codes

* **0**: System Settings opened at Privacy & Security.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of open.

#### Output on stderr

* The step to take in System Settings.

### mac__setup

Apply the complete macOS setup, continuing after failed steps.

sudo is first made passwordless for the current user and stays so after
the setup. The setup removes bundled applications, removes quarantine
attributes below /Applications, and disables Gatekeeper. It returns the
status of the first failed step after every step has run.

#### Example

```bash
GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' mac__setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of the first step that failed.

#### Output on stderr

* Each step that failed and the steps to take in System Settings.

### mac__keyboard__disable-option-t

Disable the Option+T key binding on macOS.

#### Example

```bash
mac__keyboard__disable-option-t
```

_Function has no arguments._

#### Exit codes

* **0**: Option+T no longer types a character.
* **64**: An argument was given.
* **65**: The existing DefaultKeyBinding.dict is not a valid property list.
* **69**: The system is not macOS, or plutil is unavailable.
* **74**: The property list could not be written.

