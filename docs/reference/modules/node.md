# node

Node.js installation.

## Overview

Node.js is installed through a version manager.

## Index

* [node::versions](#nodeversions)
* [node::install](#nodeinstall)

### node::versions

Write complete stable Node.js versions from the selected source.

#### Example

```bash
node::versions official | tail -n 3
```

#### Arguments

* **$1** (string): Optional source: os for the system package manager (default) or official for nodejs.org.

#### Exit codes

* **0**: The versions were written.
* **64**: The source is not os or official.
* **69**: The platform is unsupported, or Python 3 is missing for the official source.
* **74**: The release index could not be downloaded or read.

#### Output on stdout

* Complete versions such as 22.11.0, one per line, oldest first.

### node::install

Install Node.js, enable Corepack, and set the pnpm store directory.

Corepack is enabled with pnpm 8.15.9, installing Corepack through npm when the Node.js release no longer bundles it.

#### Example

```bash
node::install 22.11.0 official
pnpm --version
```

#### Arguments

* **$1** (string): Optional complete version from node::versions. Defaults to the newest stable version of the source.
* **$2** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: Node.js, Corepack, and pnpm are ready.
* **64**: The version or source is malformed.
* **69**: The version is unavailable from the source, or older than 16.14.
* **74**: The official archive could not be downloaded or unpacked.
* other The status of the package manager, npm, or Corepack.

#### Output on stderr

* A message when the version is unavailable or too old for Corepack.

