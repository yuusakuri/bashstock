# chatgpt

ChatGPT desktop application installation.

## Overview

The application is installed on macOS.

## Index

* [chatgpt::install](#chatgptinstall)

### chatgpt::install

Install the newest ChatGPT desktop app, which also runs Codex.

macOS installs the Homebrew cask chatgpt. Ubuntu 24.04 or later and
Fedora 43 or later install OpenAI's newest package, which registers
OpenAI's signed repository so later releases arrive with the system's
package upgrades. In a Wayland session, Linux also configures the app's
desktop launcher and existing autostart entry to start with native Wayland,
keeping their arguments. A launcher that cannot be found or changed is
reported on stderr without failing the install.

#### Example

```bash
chatgpt::install
```

_Function has no arguments._

#### Exit codes

* **0**: The ChatGPT desktop app is installed.
* **64**: An argument was given.
* **65**: The downloaded package is for another CPU or is not a valid package.
* **69**: The platform, release, or CPU is unsupported.
* **66**: A ChatGPT launcher exists but is not a regular file.
* **74**: The package could not be downloaded or a ChatGPT launcher could not be written.
* other The status of the package manager.

#### Output on stderr

* Each ChatGPT launcher that could not be set to native Wayland.

