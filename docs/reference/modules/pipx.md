# pipx

pipx installation.

## Overview

pipx is installed from the platform package source.

## Index

* [pipx::versions](#pipxversions)
* [pipx::install](#pipxinstall)

### pipx::versions

Write pipx versions available from the selected source.

The official source lists the PyPI releases that the installed Python 3
can run.

#### Example

```bash
pipx::versions official | tail -n 1
```

#### Arguments

* **$1** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: The versions were written.
* **64**: The source is not os or official.
* **69**: Python 3 is missing for the official source.
* **74**: The PyPI index could not be downloaded or read.

#### Output on stdout

* pipx versions, one per line, oldest first.

### pipx::install

Install pipx and add the pipx application directory to PATH.

The os source installs the package of the system package manager. The
official source installs the release from PyPI for the current user with
pip, as the pipx documentation describes for systems without a package.
A source that cannot provide pipx returns an error instead of switching to
the other source. On Ubuntu, python3-venv is installed with either source,
because pipx creates a virtual environment for every application.

#### Example

```bash
pipx::install
pipx install pycowsay
```

#### Arguments

* **$1** (string): Optional version from pipx::versions for the same source.
* **$2** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: pipx is installed and ~/.local/bin is on PATH.
* **64**: The source is not os or official.
* **69**: The source cannot provide pipx, or the installed version differs.
* **74**: The application directory could not be created.
* other The status of the package manager or pip.

#### Output on stderr

* A message when the source cannot provide pipx.

