# iina

IINA installation.

## Overview

IINA is installed with Homebrew on macOS.

## Index

* [iina::set-default-app](#iinaset-default-app)

### iina::set-default-app

Set IINA as the default application for video file extensions on macOS.

duti is installed with Homebrew when it is missing.

#### Example

```bash
iina::set-default-app
```

_Function has no arguments._

#### Exit codes

* **0**: IINA opens the listed video types.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of brew or duti.

