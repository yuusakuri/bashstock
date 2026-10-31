# desktop

GNOME and macOS desktop and keyboard settings.

## Overview

GNOME settings use gsettings and macOS settings use defaults.

## Index

* [gsettings::string-array::add](#gsettingsstring-arrayadd)
* [gsettings::string-array::remove](#gsettingsstring-arrayremove)
* [gnome::keybinding::set-custom](#gnomekeybindingset-custom)
* [gnome::input-source::set-layout](#gnomeinput-sourceset-layout)
* [keyboard::system-layout::set](#keyboardsystem-layoutset)
* [gnome::keyboard-layout::set-us](#gnomekeyboard-layoutset-us)
* [gnome::keyboard-layout::set-jp](#gnomekeyboard-layoutset-jp)
* [gnome::input-source::set-shortcuts](#gnomeinput-sourceset-shortcuts)
* [gnome::input-source::set-mozc-first](#gnomeinput-sourceset-mozc-first)
* [gnome::window::set-button-layout](#gnomewindowset-button-layout)
* [mozc::ibus::set-hiragana-as-default](#mozcibusset-hiragana-as-default)
* [keyboard::setup-ime-keys](#keyboardsetup-ime-keys)
* [ubuntu::setup](#ubuntusetup)
* [ubuntu::setup-external](#ubuntusetup-external)
* [fedora::setup](#fedorasetup)
* [fedora::setup-external](#fedorasetup-external)
* [ubuntu::setup-desktop](#ubuntusetup-desktop)
* [ubuntu::setup-desktop-22](#ubuntusetup-desktop-22)
* [homebrew::install](#homebrewinstall)
* [homebrew::cask::disable-quarantine](#homebrewcaskdisable-quarantine)
* [shell::zsh::enable-interactive-comments](#shellzshenable-interactive-comments)
* [mac::wake-on-lan::enable](#macwake-on-lanenable)
* [mac::sleep::disable-automatic](#macsleepdisable-automatic)
* [mac::sleep::enable-automatic](#macsleepenable-automatic)
* [mac::software-update::enable-automatic-install](#macsoftware-updateenable-automatic-install)
* [mac::software-update::disable-automatic-install](#macsoftware-updatedisable-automatic-install)
* [mac::keyboard::use-function-keys](#mackeyboarduse-function-keys)
* [mac::keyboard::set-repeat](#mackeyboardset-repeat)
* [mac::trackpad::disable-smart-zoom](#mactrackpaddisable-smart-zoom)
* [mac::dock::set-autohide-instant](#macdockset-autohide-instant)
* [mac::dock::hide-recent-applications](#macdockhide-recent-applications)
* [mac::dock::set-minimize-effect](#macdockset-minimize-effect)
* [mac::dock::set-position](#macdockset-position)
* [mac::applications::remove-bundled](#macapplicationsremove-bundled)
* [mac::quarantine::remove-applications](#macquarantineremove-applications)
* [mac::full-disk-access::target-paths](#macfull-disk-accesstarget-paths)
* [mac::full-disk-access::open](#macfull-disk-accessopen)
* [mac::full-disk-access::is-granted](#macfull-disk-accessis-granted)
* [mac::gatekeeper::disable](#macgatekeeperdisable)
* [mac::setup](#macsetup)

### gsettings::string-array::add

Add a literal value to a GSettings string array when it is absent.

#### Example

```bash
gsettings::string-array::add org.gnome.shell favorite-apps code.desktop
```

#### Arguments

* **$1** (string): GSettings schema, such as org.gnome.shell.
* **$2** (string): Key that holds a string array.
* **$3** (string): Value to add; it must not be empty or contain a newline.

#### Exit codes

* **0**: The value is in the array.
* **64**: The value is empty or contains a newline, or the argument count is not three.
* other The status of gsettings.

### gsettings::string-array::remove

Remove every element equal to a literal value from a GSettings string array.

#### Example

```bash
gsettings::string-array::remove org.gnome.shell favorite-apps firefox.desktop
```

#### Arguments

* **$1** (string): GSettings schema.
* **$2** (string): Key that holds a string array.
* **$3** (string): Value to remove.

#### Exit codes

* **0**: The value is no longer in the array.
* **64**: The value is empty or contains a newline, or the argument count is not three.
* other The status of gsettings.

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

### mozc::ibus::set-hiragana-as-default

Start Mozc in Hiragana mode and restart IBus.

active_on_launch is set to True in ~/.config/mozc/ibus_config.textproto.

#### Example

```bash
mozc::ibus::set-hiragana-as-default
```

_Function has no arguments._

#### Exit codes

* **0**: Mozc starts in Hiragana mode from now on.
* **64**: An argument was given.
* **69**: Perl or ibus-daemon is unavailable.
* **74**: The configuration file could not be created.
* other The status of the settings update or ibus-daemon.

### keyboard::setup-ime-keys

Map the Convert and Nonconvert keys of USB keyboards to henkan and muhenkan.

KC_INT4 (HID usage 0x7008A, Convert) becomes henkan and KC_INT5 (HID usage
0x7008B, Nonconvert) becomes muhenkan, as in the reference script. The input
method handles the keys; this function does not change IME settings. The
hwdb entry applies to every USB keyboard, or only to the keyboard identified
by VENDOR_ID and PRODUCT_ID.

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

### ubuntu::setup

Apply the common Ubuntu user configuration, stopping at the first failure.

Missing curl, Git, and Perl modules that bashstock uses are installed first.
The steps then register ~/.env, set the editor to code --wait, ignore case
in completion, link English names to localized user directories, add the
user to dialout, configure Git with Git Credential Manager, fix ~/.ssh
permissions, and install external tools.

#### Example

```bash
GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' ubuntu::setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Ubuntu.
* **77**: sudo refused the credentials.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

### ubuntu::setup-external

Install GnuPG and GitHub CLI when they are not already available.

GitHub CLI is installed from its official Ubuntu APT repository after checking
the repository key against GitHub's published fingerprints.

#### Example

```bash
ubuntu::setup-external
```

_Function has no arguments._

#### Exit codes

* **0**: The missing tools were installed or were already available.
* **64**: An argument was given.
* **69**: The system is not Ubuntu, or a required command is missing.
* **77**: sudo refused the credentials.
* other A package installation or repository setup failed.

### fedora::setup

Apply the common Fedora user configuration, stopping at the first failure.

The same steps as ubuntu::setup run on Fedora: missing curl, Git, and Perl
modules that bashstock uses are installed, ~/.env is registered, the editor
is set to code --wait, completion ignores case, English names are linked
to localized user directories, the user joins dialout, Git uses Git
Credential Manager, ~/.ssh permissions are fixed, and external tools are
installed.

#### Example

```bash
GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' fedora::setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Fedora.
* **77**: sudo refused the credentials.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

### fedora::setup-external

Install GnuPG and GitHub CLI on Fedora when they are not already available.

GitHub CLI is installed from its official DNF repository after checking the
repository key against GitHub's published fingerprints.

#### Example

```bash
fedora::setup-external
```

_Function has no arguments._

#### Exit codes

* **0**: The missing tools were installed or were already available.
* **64**: An argument was given.
* **69**: The system is not Fedora, or a required command is missing.
* **77**: sudo refused the credentials.
* other A package installation or repository setup failed.

### ubuntu::setup-desktop

Apply the Ubuntu user configuration and desktop settings, stopping at the first failure.

After ubuntu::setup, the IME keys, Mozc and US input sources, Hiragana
start, and VLC as the video application are set.

#### Example

```bash
ubuntu::setup-desktop
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Ubuntu.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

### ubuntu::setup-desktop-22

Install the newest Mozc for Ubuntu 22.04 and apply the desktop settings.

The window button layout is also set as on Ubuntu 22.04's reference setup.

#### Example

```bash
ubuntu::setup-desktop-22
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Ubuntu 22.04.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed, or a message on other releases.

### homebrew::install

Install Homebrew with the official installer when it is missing.

The new Zsh sessions read brew shellenv from .zshrc, and the current
process finds brew on PATH afterwards. The prefix is /opt/homebrew on Apple
silicon and /usr/local on Intel Macs.

#### Example

```bash
homebrew::install
brew --version
```

_Function has no arguments._

#### Exit codes

* **0**: Homebrew is installed.
* **64**: An argument was given.
* **69**: The system is not macOS.
* **74**: The installer could not be downloaded.
* other The status of the official installer.

### homebrew::cask::disable-quarantine

Install Homebrew casks without the quarantine attribute from now on.

HOMEBREW_CASK_OPTS=--no-quarantine is written to the Bash and Zsh startup files
and exported to the current process.

#### Example

```bash
homebrew::cask::disable-quarantine
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **74**: A startup file could not be written.

### shell::zsh::enable-interactive-comments

Allow comments that start with # in interactive Zsh sessions.

setopt interactivecomments is written to ~/.zshrc once.

#### Example

```bash
shell::zsh::enable-interactive-comments
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **74**: ~/.zshrc could not be written.

### mac::wake-on-lan::enable

Let the Mac wake from sleep through the network (Wake on LAN).

#### Example

```bash
mac::wake-on-lan::enable
```

_Function has no arguments._

#### Exit codes

* **0**: Wake on LAN is enabled.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of pmset.

### mac::sleep::disable-automatic

Disable automatic system sleep while preserving display sleep timers.

#### Example

```bash
mac::sleep::disable-automatic
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic system sleep is disabled.
* **64**: An argument was given.
* **69**: The system is not macOS or pmset is unavailable.
* **77**: sudo refused the credentials.
* other The status of pmset.

### mac::sleep::enable-automatic

Enable automatic system sleep after ten minutes while preserving display sleep timers.

#### Example

```bash
mac::sleep::enable-automatic
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic system sleep is enabled with a ten-minute timer.
* **64**: An argument was given.
* **69**: The system is not macOS or pmset is unavailable.
* **77**: sudo refused the credentials.
* other The status of pmset.

### mac::software-update::enable-automatic-install

Let macOS updates install automatically.

Automatic downloads and system data and security update settings stay unchanged.
The automatic macOS installation preference is enabled for all users.

#### Example

```bash
mac::software-update::enable-automatic-install
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic macOS installation is enabled.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults or the root command.

### mac::software-update::disable-automatic-install

Keep macOS updates downloading but stop their automatic installation.

Automatic downloads and system data and security update settings stay unchanged.
The automatic macOS installation preference is disabled for all users.

#### Example

```bash
mac::software-update::disable-automatic-install
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic macOS installation is disabled.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults or the root command.

### mac::keyboard::use-function-keys

Make F1 to F12 act as function keys without the fn key.

#### Example

```bash
mac::keyboard::use-function-keys
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::keyboard::set-repeat

Set the delay before key repeat starts and the repeat interval.

The new values apply after logging in again.

#### Example

```bash
mac::keyboard::set-repeat 15 2
```

#### Arguments

* **$1** (integer): Optional delay before repeating, in units of 15 ms. Defaults to 30.
* **$2** (integer): Optional interval between repeats, in units of 15 ms. Defaults to 1.

#### Exit codes

* **0**: The settings were written.
* **64**: A value is not a non-negative integer.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::trackpad::disable-smart-zoom

Turn off smart zoom, the two-finger double tap, on built-in and external trackpads.

#### Example

```bash
mac::trackpad::disable-smart-zoom
```

_Function has no arguments._

#### Exit codes

* **0**: The settings were written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::dock::set-autohide-instant

Show and hide the Dock immediately, without a delay or an animation.

The Dock restarts to apply the change.

#### Example

```bash
mac::dock::set-autohide-instant
```

_Function has no arguments._

#### Exit codes

* **0**: The settings were applied.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::dock::hide-recent-applications

Hide recently used applications in the Dock.

#### Example

```bash
mac::dock::hide-recent-applications
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was applied.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::dock::set-minimize-effect

Set the effect used when a window is minimized into the Dock.

#### Example

```bash
mac::dock::set-minimize-effect genie
```

#### Arguments

* **$1** (string): Optional effect: genie, scale, or suck. Defaults to scale.

#### Exit codes

* **0**: The setting was applied.
* **64**: The effect is not genie, scale, or suck.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::dock::set-position

Place the Dock on one edge of the screen.

#### Example

```bash
mac::dock::set-position bottom
```

#### Arguments

* **$1** (string): Optional position: left, bottom, or right. Defaults to left.

#### Exit codes

* **0**: The setting was applied.
* **64**: The position is not left, bottom, or right.
* **69**: The system is not macOS.
* other The status of defaults.

### mac::applications::remove-bundled

Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications.

GarageBand's sound library is removed with it. Missing applications are skipped.

#### Example

```bash
mac::applications::remove-bundled
```

_Function has no arguments._

#### Exit codes

* **0**: The applications are gone.
* **64**: An argument was given.
* **69**: The system is not macOS.
* **77**: sudo refused the credentials.
* other The status of rm.

### mac::quarantine::remove-applications

Remove the quarantine attribute from everything below /Applications.

Errors for files without the attribute are ignored.

#### Example

```bash
mac::quarantine::remove-applications
```

_Function has no arguments._

#### Exit codes

* **0**: The attributes were removed.
* **64**: An argument was given.
* **69**: The system is not macOS.

### mac::full-disk-access::target-paths

Write the programs that Full Disk Access must list for a command, a path, or an application.

Symbolic links are resolved, and a file inside an application bundle is
written as the bundle, because System Settings lists bundles. A Python
framework build re-executes as Python.app, so that bundle is written too.
A name that is neither a path nor a command is looked up as an application
in /Applications, /System/Applications, their Utilities folders, and
~/Applications.

#### Example

```bash
mac::full-disk-access::target-paths python3.12
mac::full-disk-access::target-paths Terminal
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

### mac::full-disk-access::open

Open Full Disk Access in System Settings and show the programs to add in Finder.

macOS grants Full Disk Access only through System Settings, so the function
opens the list and reveals each program for dragging into it. A program with
an ad hoc signature, such as a Homebrew build, loses the access when an
update replaces it, which the function reports.

#### Example

```bash
mac::full-disk-access::open python3.12 Terminal
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

### mac::full-disk-access::is-granted

Test whether the application that runs the current shell has Full Disk Access.

macOS usually checks the application that started the shell, such as
Terminal, so the result also applies to the programs the shell starts. The
test opens the user's privacy database, which only Full Disk Access permits.

#### Example

```bash
mac::full-disk-access::is-granted || mac::full-disk-access::open Terminal
```

_Function has no arguments._

#### Exit codes

* **0**: Full Disk Access is granted.
* **1**: Full Disk Access is not granted.
* **64**: An argument was given.
* **69**: The system is not macOS.

### mac::gatekeeper::disable

Ask macOS to allow applications from anywhere and open Privacy & Security.

Recent macOS releases apply spctl --master-disable only after the user
selects "Allow applications from anywhere" in System Settings, so a refusal
from spctl is not a failure; the function opens the settings for that step.

#### Example

```bash
mac::gatekeeper::disable
```

_Function has no arguments._

#### Exit codes

* **0**: System Settings opened at Privacy & Security.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of open.

#### Output on stderr

* The step to take in System Settings.

### mac::setup

Apply the complete macOS setup, continuing after failed steps.

sudo is first made passwordless for the current user and stays so after
the setup. The setup removes bundled applications, removes quarantine
attributes below /Applications, and disables Gatekeeper. It returns the
status of the first failed step after every step has run.

#### Example

```bash
GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' mac::setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of the first step that failed.

#### Output on stderr

* Each step that failed and the steps to take in System Settings.

