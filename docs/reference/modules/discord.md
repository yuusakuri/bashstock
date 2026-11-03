# discord

Discord desktop application installation.

## Overview

The application is installed from Discord's official downloads.

## Index

* [discord::install](#discordinstall)

### discord::install

Install the newest Discord desktop app.

macOS installs the Homebrew cask discord. Ubuntu installs Discord's Debian
package, and Fedora installs its RPM package.

#### Example

```bash
discord::install
```

_Function has no arguments._

#### Exit codes

* **0**: Discord is installed.
* **64**: An argument was given.
* **69**: The platform is unsupported, or a required command is missing.
* **74**: The package could not be downloaded.
* other The status of the package manager.

