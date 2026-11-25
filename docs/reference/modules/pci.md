# pci

PCI device inspection.

## Overview

Devices are listed with lspci.

## Index

* [pci__device__list](#pci__device__list)

### pci__device__list

Write the PCI devices with lspci.

#### Example

```bash
pci__device__list
```

_Function has no arguments._

#### Exit codes

* **0**: The devices were written.
* **64**: An argument was given.
* **69**: lspci is unavailable.
* other The status of lspci.

#### Output on stdout

* The output of lspci.

