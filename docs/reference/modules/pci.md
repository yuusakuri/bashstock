# pci

PCI device inspection.

## Overview

Devices are listed with lspci.

## Index

* [pci::device::list](#pcidevicelist)

### pci::device::list

Write the PCI devices with lspci.

#### Example

```bash
pci::device::list
```

_Function has no arguments._

#### Exit codes

* **0**: The devices were written.
* **64**: An argument was given.
* **69**: lspci is unavailable.
* other The status of lspci.

#### Output on stdout

* The output of lspci.

