# plantuml

PlantUML installation.

## Overview

PlantUML is installed from its releases.

## Index

* [plantuml::versions](#plantumlversions)
* [plantuml::install](#plantumlinstall)

### plantuml::versions

Write PlantUML versions available to the current platform.

#### Example

```bash
plantuml::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* PlantUML versions from the platform package manager, one per line.

### plantuml::install

Install PlantUML from the platform package manager.

#### Example

```bash
plantuml::install
plantuml -tsvg diagram.puml
```

#### Arguments

* **$1** (string): Optional version from plantuml::versions. Defaults to the newest one.

#### Exit codes

* **0**: PlantUML is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

