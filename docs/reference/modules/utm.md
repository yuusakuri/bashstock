# utm

UTM installation.

## Overview

UTM is installed from its release disk image on macOS.

## Index

* [utm__open](#utm__open)
* [utm__versions](#utm__versions)
* [utm__install](#utm__install)

### utm__open

Open the UTM application on macOS.

#### Example

```bash
utm__open
```

_Function has no arguments._

#### Exit codes

* **0**: UTM was opened.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of open.

### utm__versions

Write UTM release versions.

#### Example

```bash
utm__versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: Python 3 is unavailable.
* **74**: The GitHub release list could not be downloaded or read.

#### Output on stdout

* Stable UTM release versions, one per line, oldest first.

### utm__install

Install UTM from its release disk image on macOS.

#### Example

```bash
utm__install 4.6.4
```

#### Arguments

* **$1** (string): Optional UTM release version. Defaults to the newest stable release.
* **$2** (string): Optional destination directory. Defaults to /Applications.

#### Exit codes

* **0**: UTM.app was copied to the destination.
* **64**: The argument count is wrong.
* **66**: The destination directory does not exist.
* **69**: The system is not macOS, or hdiutil is unavailable.
* **74**: The disk image could not be downloaded, mounted, or copied.

