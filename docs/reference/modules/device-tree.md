# device-tree

Linux device tree inspection.

## Overview

Nodes are read from /proc/device-tree.

## Index

* [device-tree__node__list](#device-tree__node__list)

### device-tree__node__list

Write the node paths of the Linux device tree.

#### Example

```bash
device-tree__node__list | grep -i i2c
```

_Function has no arguments._

#### Exit codes

* **0**: The nodes were written.
* **64**: An argument was given.
* **66**: The system has no device tree.

#### Output on stdout

* One node path per line below /sys/firmware/devicetree/base.

