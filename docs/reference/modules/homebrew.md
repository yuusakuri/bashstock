# homebrew

Homebrew installation and casks.

## Overview

Homebrew is installed with its official installer on macOS.

## Index

* [homebrew::install](#homebrewinstall)
* [homebrew::cask::disable-quarantine](#homebrewcaskdisable-quarantine)

### homebrew::install

Install Homebrew with the official installer when it is missing.

The new Zsh sessions read brew shellenv from .zshrc, and the current
process finds brew on PATH afterwards. Homebrew lives in /opt/homebrew.

#### Example

```bash
homebrew::install
brew --version
```

_Function has no arguments._

#### Exit codes

* **0**: Homebrew is installed.
* **64**: An argument was given.
* **69**: The system is not macOS.
* **74**: The installer could not be downloaded.
* other The status of the official installer.

### homebrew::cask::disable-quarantine

Install Homebrew casks without the quarantine attribute from now on.

HOMEBREW_CASK_OPTS=--no-quarantine is written to the Bash and Zsh startup files
and exported to the current process.

#### Example

```bash
homebrew::cask::disable-quarantine
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **74**: A startup file could not be written.

