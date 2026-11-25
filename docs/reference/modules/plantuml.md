# plantuml

PlantUML installation.

## Overview

PlantUML is installed from its releases.

## Index

* [plantuml__versions](#plantuml__versions)
* [plantuml__install](#plantuml__install)

### plantuml__versions

Write PlantUML versions available to the current platform.

#### Example

```bash
plantuml__versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* PlantUML versions from the platform package manager, one per line.

### plantuml__install

Install PlantUML from the platform package manager.

#### Example

```bash
plantuml__install
plantuml -tsvg diagram.puml
```

#### Arguments

* **$1** (string): Optional version from plantuml__versions. Defaults to the newest one.

#### Exit codes

* **0**: PlantUML is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

