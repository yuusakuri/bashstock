# thunderbird

Thunderbird installation.

## Overview

Thunderbird is installed with Homebrew on macOS and from the system package on Ubuntu and Fedora.

## Index

* [thunderbird::versions](#thunderbirdversions)
* [thunderbird::install](#thunderbirdinstall)

### thunderbird::versions

Write Thunderbird versions available to the current platform.

#### Example

```bash
thunderbird::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Thunderbird versions, one per line.

### thunderbird::install

Install the Thunderbird email client.

macOS installs the Homebrew cask thunderbird, which updates itself. Ubuntu
and Fedora install the thunderbird package of the system; on Ubuntu 24.04
and later that package installs the Snap.

#### Example

```bash
thunderbird::install
```

#### Arguments

* **$1** (string): Optional version from thunderbird::versions; on macOS only the current version. Defaults to the newest one.

#### Exit codes

* **0**: Thunderbird is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

