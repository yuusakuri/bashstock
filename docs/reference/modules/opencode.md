# opencode

OpenCode installation.

## Overview

OpenCode is installed with its official installer.

## Index

* [opencode::install](#opencodeinstall)

### opencode::install

Install the newest OpenCode command-line application.

macOS uses the Homebrew tap. Linux installs the official opencode-ai npm
package into $HOME/.local; its installer picks the build for the CPU and C
library, and the glibc builds run on Ubuntu 18.04 and later. Linux needs
npm: the Ubuntu nodejs package does not provide it, so install Node.js with
`node::install VERSION official` first there.

#### Example

```bash
opencode::install
```

_Function has no arguments._

#### Exit codes

* **0**: OpenCode was installed.
* **64**: An argument was given.
* **69**: npm is unavailable.
* **74**: $HOME/.local could not be created.
* other The status of the installation.

#### Output on stdout

* The installed version.

