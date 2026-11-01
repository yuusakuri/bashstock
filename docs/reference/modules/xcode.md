# xcode

Xcode Command Line Tools.

## Overview

The tools are installed and upgraded with softwareupdate.

## Index

* [xcode::command-line-tools::upgrade](#xcodecommand-line-toolsupgrade)

### xcode::command-line-tools::upgrade

Update Xcode Command Line Tools without removing the installed tools.

When softwareupdate offers no Command Line Tools update, nothing changes.

#### Example

```bash
xcode::command-line-tools::upgrade
clang --version
```

_Function has no arguments._

#### Exit codes

* **0**: The tools were updated, or no update is available.
* **64**: An argument was given.
* **69**: The system is not macOS, or softwareupdate or xcode-select is unavailable.
* **74**: softwareupdate could not list updates, or xcode-select finds no tools after the update.
* other The status of softwareupdate or pkgutil.

#### Output on stdout

* The package information of the updated tools.

#### Output on stderr

* A message when no update is available.

