# go

Go installation and versions.

## Overview

Go is installed from the official package source of the platform.

## Index

* [go__version__list](#go__version__list)
* [go__version__latest](#go__version__latest)
* [go__repository__register](#go__repository__register)
* [go__install](#go__install)

### go__version__list

Write the stable Go versions the platform package source offers, oldest first.

Ubuntu lists the versioned golang-X.Y packages, Fedora the golang package,
and macOS the Homebrew go formulae. Each value is accepted by go__install.

#### Example

```bash
go__version__list
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **1**: No version was found.
* **64**: An argument was given.
* **69**: The platform or its package tool is unsupported or unavailable.
* other The status of the package query that failed.

#### Output on stdout

* One version per line, oldest first.

### go__version__latest

Write the newest stable Go version from go__version__list.

#### Example

```bash
go__install "$(go__version__latest)"
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **1**: No version was found.
* **64**: An argument was given.
* other The status of go__version__list.

#### Output on stdout

* The newest version, such as 1.23.

### go__repository__register

Register the official Go package source for the current platform.

Go comes from the distribution or Homebrew, so this only checks that the package tool is available.

#### Example

```bash
go__repository__register
```

_Function has no arguments._

#### Exit codes

* **0**: The package source is available.
* **64**: An argument was given.
* **69**: The platform is unsupported or its package tool is unavailable.

### go__install

Install Go from the platform package source.

On Ubuntu a given version installs golang-VERSION and becomes the go and
gofmt of every user through links in /usr/local/bin; an omitted version
installs the golang package and removes those links, so its default version
answers again. On Fedora an omitted version installs the newest version,
which also replaces an older one installed earlier.

#### Example

```bash
go__install "$(go__version__latest)"
```

#### Arguments

* **$1** (string): Optional version from go__version__list. Defaults to the package source default.

#### Exit codes

* **0**: Go was installed.
* **64**: More than one argument was given.
* **69**: The platform is unsupported or the version is not offered.
* **74**: The links in /usr/local/bin could not be changed.
* other The status of the package installation.

