# pass

pass installation and password stores.

## Overview

Stores are initialized for a GPG key.

## Index

* [pass__store__remove](#pass__store__remove)
* [pass__store__init](#pass__store__init)
* [pass__versions](#pass__versions)
* [pass__install](#pass__install)

### pass__store__remove

Remove a pass store and everything in it.

#### Example

```bash
pass__store__remove "${HOME}/.password-store-old"
```

#### Arguments

* **$1** (string): Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.

#### Exit codes

* **0**: The store was removed.
* **64**: More than one argument was given, or the directory is / or a symbolic link.
* **66**: The store does not exist.
* **74**: The store could not be removed.

### pass__store__init

Initialize a pass store for a GPG key without removing an existing store.

#### Example

```bash
pass__store__init "$(gpg__secret-key__fingerprints | head -n 1)"
```

#### Arguments

* **$1** (string): Optional GPG key fingerprint. Defaults to the first secret key.
* **$2** (string): Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.

#### Exit codes

* **0**: The store was initialized.
* **1**: No fingerprint was given and no secret key exists.
* **64**: More than two arguments were given.
* **69**: pass is unavailable.
* other The status of pass init.

### pass__versions

Write pass versions available to the current platform.

#### Example

```bash
pass__versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* pass versions from the platform package manager, one per line.

### pass__install

Install pass from the platform package manager.

#### Example

```bash
pass__install
pass init "$(gpg__secret-key__fingerprints | head -n 1)"
```

#### Arguments

* **$1** (string): Optional version from pass__versions. Defaults to the newest one.

#### Exit codes

* **0**: pass is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

