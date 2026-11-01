# microsoft-edge

Microsoft Edge installation.

## Overview

Edge is installed from Microsoft's package source.

## Index

* [microsoft-edge::versions](#microsoft-edgeversions)
* [microsoft-edge::install](#microsoft-edgeinstall)

### microsoft-edge::versions

Write Microsoft Edge versions available to the current platform.

#### Example

```bash
microsoft-edge::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform or CPU is unsupported.
* **74**: The vendor metadata could not be downloaded.

#### Output on stdout

* Microsoft Edge versions, one per line; on Linux only builds for this CPU, and on Ubuntu only builds the C library can run.

### microsoft-edge::install

Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew.

On Linux, a version is accepted only when Microsoft publishes it for the
running CPU, and on Ubuntu only when the installed C library can run it.
Microsoft builds Edge for Linux on amd64 only, so arm64 returns 69.

#### Example

```bash
microsoft-edge::install
```

#### Arguments

* **$1** (string): Optional version from microsoft-edge::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: Microsoft Edge is installed.
* **64**: The argument count is wrong.
* **69**: The platform or CPU is unsupported, or the version is unavailable.
* **74**: The package or repository could not be downloaded.
* other The status of the package manager.

