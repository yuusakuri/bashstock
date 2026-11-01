# rancher-desktop

Rancher Desktop installation.

## Overview

Rancher Desktop is installed from its official releases.

## Index

* [rancher-desktop::versions](#rancher-desktopversions)
* [rancher-desktop::install](#rancher-desktopinstall)

### rancher-desktop::versions

Write Rancher Desktop versions available to the current platform.

#### Example

```bash
rancher-desktop::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Rancher Desktop versions, one per line.

### rancher-desktop::install

Install Rancher Desktop and start it.

Rosetta and Colima are installed separately with rosetta::install and colima::install.
Ubuntu 22.04 or later and Fedora 35 or later install from Rancher's
repository; Fedora uses the packages that Rancher builds for Fedora.

#### Example

```bash
rancher-desktop::install
```

#### Arguments

* **$1** (string): Optional version from rancher-desktop::versions; on macOS only the current version.

#### Exit codes

* **0**: Rancher Desktop is installed and was started.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, Ubuntu is older than 22.04, Fedora is older than 35, or the version is unavailable.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

#### Output on stderr

* On Linux, a reminder to log in again when the user was added to the kvm group.

