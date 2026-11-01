# brave

Brave browser installation.

## Overview

Brave is installed from its official package source.

## Index

* [brave::versions](#braveversions)
* [brave::install](#braveinstall)

### brave::versions

Write Brave versions available to the current platform.

#### Example

```bash
brave::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Brave versions, one per line; on Ubuntu only builds that the installed C library can run.

### brave::install

Install Brave from its official repository or Homebrew.

On Ubuntu, a version is accepted only when the installed C library can run it,
and an omitted version selects the newest such build.

#### Example

```bash
brave::install
```

#### Arguments

* **$1** (string): Optional version from brave::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: Brave is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable or cannot run here.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

