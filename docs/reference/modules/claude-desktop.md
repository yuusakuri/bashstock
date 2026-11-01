# claude-desktop

Claude desktop application installation.

## Overview

The application is installed from Anthropic's signed packages.

## Index

* [claude-desktop::install](#claude-desktopinstall)

### claude-desktop::install

Install the newest Claude Desktop, the app that also runs Claude Code sessions.

macOS installs the Homebrew cask claude, which updates itself. Ubuntu 22.04
or later installs from Anthropic's APT repository, and later releases
arrive through the system's regular APT upgrades. Anthropic does not
publish Claude Desktop for Fedora; use claude-code::install there.

#### Example

```bash
claude-desktop::install
```

_Function has no arguments._

#### Exit codes

* **0**: Claude Desktop is installed.
* **64**: An argument was given.
* **65**: The downloaded signing key is not Anthropic's published key.
* **69**: The system is neither macOS nor Ubuntu 22.04 or later, or the CPU is unsupported.
* **74**: The repository key could not be downloaded.
* other The status of the package manager.

