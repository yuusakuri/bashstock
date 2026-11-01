# git-credential-manager

Git Credential Manager installation.

## Overview

The manager is installed from its GitHub releases.

## Index

* [git-credential-manager::version::list](#git-credential-managerversionlist)
* [git-credential-manager::install](#git-credential-managerinstall)

### git-credential-manager::version::list

Write the installed Git Credential Manager version.

#### Example

```bash
git-credential-manager::version::list
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **64**: An argument was given.
* **69**: git-credential-manager is unavailable.
* other The status of git-credential-manager.

#### Output on stdout

* The installed version.

### git-credential-manager::install

Install an official Git Credential Manager release for this OS and CPU.

Each release is built for a minimum C library: 3.0 needs glibc 2.34, so
Ubuntu 18.04 and 20.04 run 2.9. On Linux the ICU library is installed
first, because the program does not start without it. Without VERSION, releases are tried from
the newest until one starts on this system. A requested VERSION that does
not start returns 69 without installing anything.

#### Example

```bash
git-credential-manager::install 2.6.1
```

#### Arguments

* **$1** (string): Optional major.minor.patch release. Defaults to the newest release that starts.

#### Exit codes

* **0**: Git Credential Manager was installed and configured.
* **64**: More than one argument was given or the version is malformed.
* **69**: The platform or CPU is unsupported, or no release starts.
* **74**: A download or file operation failed.
* other The status of the step that failed.

#### Output on stderr

* A message when no release starts on this system.

