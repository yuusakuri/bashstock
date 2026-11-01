# gimp

GIMP and G'MIC installation.

## Overview

GIMP is installed from the platform package source or the official disk image.

## Index

* [gimp::versions](#gimpversions)
* [gimp::install](#gimpinstall)
* [gimp::gmic::versions](#gimpgmicversions)
* [gimp::gmic::install](#gimpgmicinstall)

### gimp::versions

Write GIMP versions available to the current platform.

#### Example

```bash
gimp::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* GIMP versions, one per line.

### gimp::install

Install GIMP, and on Linux the G'MIC plugin from the selected source.

#### Example

```bash
gimp::install '' official
```

#### Arguments

* **$1** (string): Optional GIMP version from gimp::versions; on macOS only the current version.
* **$2** (string): Optional G'MIC source on Linux: os (default) or official; see gimp::gmic::install.

#### Exit codes

* **0**: GIMP, and on Linux the G'MIC plugin, are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, the version is unavailable, or the G'MIC source cannot provide the plugin.
* other The status of the package manager.

### gimp::gmic::versions

Write G'MIC GIMP plugin versions available from the selected source.

#### Example

```bash
gimp::gmic::versions official
```

#### Arguments

* **$1** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: The versions were written.
* **64**: The source is not os or official.
* **69**: The platform or CPU is unsupported by the source.
* **74**: The official package list could not be downloaded.

#### Output on stdout

* G'MIC plugin versions, one per line.

### gimp::gmic::install

Install the G'MIC GIMP plugin.

The os source installs the plugin package of the system package manager.
Ubuntu 26.04 ships GIMP 3 without one, so the official source installs the
G'MIC project's package for the running Ubuntu release, which contains the
GIMP 3 plugin. A source that cannot provide the plugin returns 69 instead
of switching to the other source.

#### Example

```bash
gimp::gmic::install '' official
```

#### Arguments

* **$1** (string): Optional version from gimp::gmic::versions for the same source.
* **$2** (string): Optional source: os (default) or official. The official source supports Ubuntu on amd64, the only CPU the G'MIC project builds packages for.

#### Exit codes

* **0**: The G'MIC plugin is installed.
* **64**: The source is not os or official.
* **69**: The source cannot provide the plugin for this system, or the version is unavailable.
* **74**: The official package could not be downloaded.
* other The status of the package manager.

#### Output on stderr

* A message when the source cannot provide the plugin.

