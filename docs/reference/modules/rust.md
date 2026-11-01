# rust

Rust installation and versions.

## Overview

Rust is installed with rustup.

## Index

* [rust::install](#rustinstall)
* [rust::versions](#rustversions)

### rust::install

Install Rust using rustup and an optional toolchain version.

#### Example

```bash
rust::install 1.81.0
```

#### Arguments

* **$1** (string): Optional toolchain, such as 1.81.0 or nightly. Defaults to stable.

#### Exit codes

* **0**: Rust was installed and $HOME/.cargo/bin was added to PATH.
* **64**: More than one argument was given.
* **69**: curl or a C compiler is unavailable, or the platform is unsupported.
* **74**: rustup could not be downloaded.
* other The status of the rustup installer.

### rust::versions

Write the stable Rust versions, oldest first, from the rust-lang/rust releases.

#### Example

```bash
rust::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **1**: No version was found.
* **64**: An argument was given.
* other The status of the GitHub query.

#### Output on stdout

* One version per line, oldest first.

