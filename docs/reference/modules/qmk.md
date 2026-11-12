# qmk

QMK firmware tools installation.

## Overview

The CLI uses the official installer; QMK Toolbox uses Homebrew on macOS.

## Index

* [qmk::toolbox::install](#qmktoolboxinstall)
* [qmk::cli::install](#qmkcliinstall)

### qmk::toolbox::install

Install QMK Toolbox with Homebrew on macOS.

#### Example

```bash
qmk::toolbox::install
```

#### Arguments

* **$1** (string): Optional QMK Toolbox version; only the current Homebrew version is accepted.

#### Exit codes

* **0**: QMK Toolbox is installed.
* **64**: The argument count is wrong.
* **69**: The system is not macOS, or the version is not the current one.
* other The status of brew.

### qmk::cli::install

Install the QMK CLI with the official installer and diagnose the environment.

`qmk --version` always confirms the installation. The CLI offers
`qmk doctor` only after `qmk setup` has prepared the firmware tree, so the
diagnosis also runs when that tree exists. Warnings from the diagnosis are
reported without failing; errors return its status.

#### Example

```bash
qmk::cli::install
qmk setup -y
```

#### Arguments

* **$1** (string): Optional QMK CLI version; only the newest stable version from PyPI is accepted.

#### Exit codes

* **0**: The QMK CLI is installed and starts; doctor found at most warnings.
* **64**: The argument count is wrong.
* **69**: The version is not the newest one, or sh is unavailable.
* **74**: The installer or the PyPI release data could not be downloaded or read.
* other The status of the installer, qmk --version, or qmk doctor.

#### Output on stdout

* The output of qmk --version, and of qmk doctor when the firmware tree exists.

