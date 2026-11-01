# claude-code

Claude Code installation.

## Overview

Claude Code is installed with Anthropic's native installer.

## Index

* [claude-code::install](#claude-codeinstall)

### claude-code::install

Install the newest Claude Code CLI.

macOS installs the Homebrew cask claude-code. Ubuntu 20.04 or later and
Fedora install from Anthropic's signed stable repository, so later
releases arrive with the system's package upgrades. Signing in is left to
the first run of claude.

#### Example

```bash
claude-code::install && claude --version
```

_Function has no arguments._

#### Exit codes

* **0**: Claude Code is installed.
* **64**: An argument was given.
* **65**: The downloaded signing key is not Anthropic's published key.
* **69**: The platform is unsupported, Ubuntu is older than 20.04, or the CPU is unsupported.
* **74**: The repository key could not be downloaded.
* other The status of the package manager.

