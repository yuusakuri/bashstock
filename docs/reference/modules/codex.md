# codex

OpenAI Codex CLI installation.

## Overview

macOS uses the Homebrew cask and Linux uses OpenAI's standalone installer.

## Index

* [codex::install](#codexinstall)

### codex::install

Install the newest OpenAI Codex CLI.

macOS installs the Homebrew cask codex. Linux runs OpenAI's standalone
installer, which verifies the release checksum, installs the static musl
build into $HOME/.local, and keeps it updated. $HOME/.local/bin is added
to PATH through env::add-path, so the installer leaves the shell startup
files alone. Signing in is left to the first run of codex.

#### Example

```bash
codex::install && codex --version
```

_Function has no arguments._

#### Exit codes

* **0**: Codex is installed.
* **64**: An argument was given.
* **69**: The platform or CPU is unsupported, or tar is missing.
* **74**: The installer could not be downloaded or $HOME/.local/bin could not be created.
* other The status of the installer or of Homebrew.

#### Output on stdout

* The installer's progress and the installed version.

