# rosetta

Rosetta installation.

## Overview

Rosetta is installed on Apple silicon when it is missing.

## Index

* [rosetta__install](#rosetta__install)

### rosetta__install

Install Rosetta when it is missing, accepting its license.

A Mac that already runs x86_64 code succeeds without changes.

#### Example

```bash
rosetta__install
```

_Function has no arguments._

#### Exit codes

* **0**: Rosetta is installed or was already installed.
* **64**: An argument was given.
* **69**: The system is not macOS or softwareupdate is unavailable.
* other The status of softwareupdate.

