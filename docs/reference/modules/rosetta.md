# rosetta

Rosetta installation.

## Overview

Rosetta is installed on Apple silicon when it is missing.

## Index

* [rosetta::install](#rosettainstall)

### rosetta::install

Install Rosetta on Apple silicon when it is missing, accepting its license.

Intel Macs and Macs that already run x86_64 code succeed without changes.

#### Example

```bash
rosetta::install
```

_Function has no arguments._

#### Exit codes

* **0**: Rosetta is installed or not needed.
* **64**: An argument was given.
* **69**: The system is not macOS or softwareupdate is unavailable.
* other The status of softwareupdate.

