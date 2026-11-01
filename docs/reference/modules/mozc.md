# mozc

Mozc input method installation and settings.

## Overview

Mozc is installed from the platform package source.

## Index

* [mozc::config::open](#mozcconfigopen)
* [mozc::server::versions](#mozcserverversions)
* [mozc::server::install](#mozcserverinstall)
* [mozc::ibus::versions](#mozcibusversions)
* [mozc::ibus::install](#mozcibusinstall)
* [mozc::tool::versions](#mozctoolversions)
* [mozc::tool::install](#mozctoolinstall)
* [mozc::ibus::set-hiragana-as-default](#mozcibusset-hiragana-as-default)

### mozc::config::open

Open the Mozc settings dialog on a Linux desktop.

#### Example

```bash
mozc::config::open
```

_Function has no arguments._

#### Exit codes

* **0**: The dialog was closed.
* **64**: An argument was given.
* **69**: mozc_tool is unavailable.
* other The status of mozc_tool.

### mozc::server::versions

Write Mozc server versions provided for the running operating-system release.

#### Example

```bash
mozc::server::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Mozc server package versions, one per line.

### mozc::server::install

Install the Mozc server, defaulting to the newest version for the running release.

#### Example

```bash
mozc::server::install
```

#### Arguments

* **$1** (string): Optional version from mozc::server::versions. Defaults to the newest one.

#### Exit codes

* **0**: The Mozc server is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc::ibus::versions

Write IBus Mozc versions provided for the running operating-system release.

#### Example

```bash
mozc::ibus::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* IBus Mozc package versions, one per line.

### mozc::ibus::install

Install IBus Mozc and the Mozc server of the same version.

#### Example

```bash
mozc::ibus::install
```

#### Arguments

* **$1** (string): Optional version from mozc::ibus::versions. Defaults to the newest one.

#### Exit codes

* **0**: IBus Mozc, and the server of the same version when provided, are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc::tool::versions

Write Mozc GUI tool versions provided for the running operating-system release.

#### Example

```bash
mozc::tool::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Mozc GUI tool package versions, one per line.

### mozc::tool::install

Install the Mozc GUI tools.

#### Example

```bash
mozc::tool::install
mozc::config::open
```

#### Arguments

* **$1** (string): Optional version from mozc::tool::versions. Defaults to the newest one.

#### Exit codes

* **0**: The Mozc GUI tools are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc::ibus::set-hiragana-as-default

Start Mozc in Hiragana mode and restart IBus.

active_on_launch is set to True in ~/.config/mozc/ibus_config.textproto. A
missing file, or one without Mozc's engine list, first gets Mozc's defaults,
because IBus offers no Mozc engine without that list. The IBus cache is then
rewritten so that IBus reads the engine list again.

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

