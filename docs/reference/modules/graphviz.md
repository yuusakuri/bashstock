# graphviz

Graphviz installation.

## Overview

Graphviz is installed from the platform package source.

## Index

* [graphviz::versions](#graphvizversions)
* [graphviz::install](#graphvizinstall)

### graphviz::versions

Write Graphviz versions available to the current platform.

#### Example

```bash
graphviz::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Graphviz versions from the platform package manager, one per line.

### graphviz::install

Install Graphviz from the platform package manager.

#### Example

```bash
graphviz::install
dot -Tpng graph.dot -o graph.png
```

#### Arguments

* **$1** (string): Optional version from graphviz::versions. Defaults to the newest one.

#### Exit codes

* **0**: Graphviz is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

