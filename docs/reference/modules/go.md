# go

Go installation and versions.

## Overview

Go is installed from the official package source of the platform.

## Index

* [go::version::list](#goversionlist)
* [go::version::latest](#goversionlatest)
* [go::repository::register](#gorepositoryregister)
* [go::install](#goinstall)

### go::version::list

Write the stable Go versions the platform package source offers, oldest first.

Ubuntu lists the versioned golang-X.Y packages, Fedora the golang package,
and macOS the Homebrew go formulae. Each value is accepted by go::install.

#### Example

```bash
go::version::list
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

### go::version::latest

Write the newest stable Go version from go::version::list.

#### Example

```bash
go::install "$(go::version::latest)"
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **1**: No version was found.
* **64**: An argument was given.
* other The status of go::version::list.

#### Output on stdout

* The newest version, such as 1.23.

### go::repository::register

Register the official Go package source for the current platform.

Go comes from the distribution or Homebrew, so this only checks that the package tool is available.

#### Example

```bash
go::repository::register
```

_Function has no arguments._

#### Exit codes

* **0**: The package source is available.
* **64**: An argument was given.
* **69**: The platform is unsupported or its package tool is unavailable.

### go::install

Install Go from the platform package source.

#### Example

```bash
go::install "$(go::version::latest)"
```

#### Arguments

* **$1** (string): Optional version from go::version::list. Defaults to the package source default.

#### Exit codes

* **0**: Go was installed.
* **64**: More than one argument was given.
* **69**: The platform is unsupported or the version is not offered.
* other The status of the package installation.

