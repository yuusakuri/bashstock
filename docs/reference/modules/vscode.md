# vscode

Visual Studio Code installation and settings.

## Overview

VS Code is installed from Microsoft's package source.

## Index

* [vscode::remove-user-data](#vscoderemove-user-data)
* [vscode::set-default-app](#vscodeset-default-app)
* [vscode::versions](#vscodeversions)
* [vscode::install](#vscodeinstall)

### vscode::remove-user-data

Remove the VS Code user data directory.

VS Code is not checked for running instances.

#### Example

```bash
vscode::remove-user-data
```

#### Arguments

* **$1** (string): Optional directory to remove. Defaults to the standard user data directory.

#### Exit codes

* **0**: The directory was removed.
* **64**: More than one argument was given.
* **66**: The directory does not exist, is /, or is a symbolic link.
* **74**: The directory could not be removed.

### vscode::set-default-app

Set VS Code as the default application for text and source file types on macOS.

Extensions and UTIs that this macOS does not declare are reported and
skipped; any other failure returns its status.

#### Example

```bash
vscode::set-default-app
```

_Function has no arguments._

#### Exit codes

* **0**: VS Code opens the listed types.
* **64**: An argument was given.
* **69**: The system is not macOS, or duti is unavailable.
* other The status of duti.

#### Output on stderr

* Each skipped extension or UTI.

### vscode::versions

Write VS Code versions available to the current platform.

#### Example

```bash
vscode::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* VS Code versions, one per line; on Ubuntu only builds that the installed C library can run.

### vscode::install

Install VS Code from the Microsoft repository or Homebrew.

On Ubuntu, a version is accepted only when the installed C library can run it,
and an omitted version selects the newest such build.

#### Example

```bash
vscode::install
code --version
```

#### Arguments

* **$1** (string): Optional version from vscode::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: VS Code is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable or cannot run here.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

