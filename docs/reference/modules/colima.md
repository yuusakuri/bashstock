# colima

Colima installation.

## Overview

Colima is installed with Homebrew on macOS.

## Index

* [colima::versions](#colimaversions)
* [colima::install](#colimainstall)

### colima::versions

Write Colima versions available from Homebrew.

#### Example

```bash
colima::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of brew.

#### Output on stdout

* Colima versions from Homebrew, one per line.

### colima::install

Install Colima with Homebrew on macOS and start it.

Colima's Docker runtime needs the docker command before it starts, so the
Docker CLI formula is installed with it. Without Hypervisor.framework, as in
a virtual machine without nested virtualization, the VM cannot boot, so the
function returns 69 instead of starting it.

#### Example

```bash
colima::install
docker::install
```

#### Arguments

* **$1** (string): Optional Colima version; only the current Homebrew version is accepted.

#### Exit codes

* **0**: Colima is installed and running.
* **64**: The argument count is wrong.
* **69**: The system is not macOS, the version is not the current one, or Hypervisor.framework is unavailable.
* other The status of brew or colima start.

#### Output on stderr

* A message when Hypervisor.framework is unavailable.

