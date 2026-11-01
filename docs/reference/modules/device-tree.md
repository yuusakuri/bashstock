# device-tree

Linux device tree inspection.

## Overview

Nodes are read from /proc/device-tree.

## Index

* [device-tree::node::list](#device-treenodelist)

### device-tree::node::list

Write the node paths of the Linux device tree.

#### Example

```bash
device-tree::node::list | grep -i i2c
```

_Function has no arguments._

#### Exit codes

* **0**: The nodes were written.
* **64**: An argument was given.
* **66**: The system has no device tree.

#### Output on stdout

* One node path per line below /sys/firmware/devicetree/base.

