# mozc

Mozc input method installation and settings.

## Overview

Mozc is installed from the platform package source.

## Index

* [mozc__config__open](#mozc__config__open)
* [mozc__server__versions](#mozc__server__versions)
* [mozc__server__install](#mozc__server__install)
* [mozc__ibus__versions](#mozc__ibus__versions)
* [mozc__ibus__install](#mozc__ibus__install)
* [mozc__ibus__upgrade](#mozc__ibus__upgrade)
* [mozc__tool__versions](#mozc__tool__versions)
* [mozc__tool__install](#mozc__tool__install)
* [mozc__ibus__set-hiragana-as-default](#mozc__ibus__set-hiragana-as-default)

### mozc__config__open

Open the Mozc settings dialog on a Linux desktop.

#### Example

```bash
mozc__config__open
```

_Function has no arguments._

#### Exit codes

* **0**: The dialog was closed.
* **64**: An argument was given.
* **69**: mozc_tool is unavailable.
* other The status of mozc_tool.

### mozc__server__versions

Write Mozc server versions provided for the running operating-system release.

#### Example

```bash
mozc__server__versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Mozc server package versions, one per line.

### mozc__server__install

Install the Mozc server, defaulting to the newest version for the running release.

#### Example

```bash
mozc__server__install
```

#### Arguments

* **$1** (string): Optional version from mozc__server__versions. Defaults to the newest one.

#### Exit codes

* **0**: The Mozc server is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc__ibus__versions

Write IBus Mozc versions provided for the running operating-system release.

#### Example

```bash
mozc__ibus__versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* IBus Mozc package versions, one per line.

### mozc__ibus__install

Install IBus Mozc and the Mozc server of the same version.

#### Example

```bash
mozc__ibus__install
```

#### Arguments

* **$1** (string): Optional version from mozc__ibus__versions. Defaults to the newest one.

#### Exit codes

* **0**: IBus Mozc, and the server of the same version when provided, are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc__ibus__upgrade

Install IBus Mozc on Ubuntu, or upgrade it when the release offers a newer version.

The newest version from mozc__ibus__versions is installed through
mozc__ibus__install, with the Mozc server of the same version when the
release provides it. An installed version at least as new is kept, so a
newer version is never downgraded. Fedora is not supported yet.

#### Example

```bash
mozc__ibus__upgrade
```

_Function has no arguments._

#### Exit codes

* **0**: IBus Mozc was installed or upgraded, or is already up to date.
* **64**: An argument was given.
* **69**: The system is not Ubuntu, or the release provides no IBus Mozc version.
* other The status of the package manager.

#### Output on stderr

* A message when the release provides no IBus Mozc version.

### mozc__tool__versions

Write Mozc GUI tool versions provided for the running operating-system release.

#### Example

```bash
mozc__tool__versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Mozc GUI tool package versions, one per line.

### mozc__tool__install

Install the Mozc GUI tools.

#### Example

```bash
mozc__tool__install
mozc__config__open
```

#### Arguments

* **$1** (string): Optional version from mozc__tool__versions. Defaults to the newest one.

#### Exit codes

* **0**: The Mozc GUI tools are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc__ibus__set-hiragana-as-default

Start Mozc in Hiragana mode and restart IBus.

active_on_launch is set to True in ~/.config/mozc/ibus_config.textproto. A
missing file, or one without Mozc's engine list, first gets Mozc's defaults,
because IBus offers no Mozc engine without that list. The IBus cache is then
rewritten so that IBus reads the engine list again.

#### Example

```bash
mozc__ibus__set-hiragana-as-default
```

_Function has no arguments._

#### Exit codes

* **0**: Mozc starts in Hiragana mode from now on.
* **64**: An argument was given.
* **69**: Python 3 or ibus-daemon is unavailable.
* **74**: The configuration file could not be created.
* other The status of the settings update or ibus-daemon.

