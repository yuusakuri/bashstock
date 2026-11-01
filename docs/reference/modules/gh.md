# gh

GitHub CLI installation.

## Overview

gh is installed from GitHub's official package source.

## Index

* [gh::install](#ghinstall)

### gh::install

Install GitHub CLI from its official Ubuntu APT or Fedora DNF repository.

The downloaded key must contain both fingerprints published by GitHub. It is
installed in /etc/apt/keyrings on Ubuntu or /etc/pki/rpm-gpg on Fedora and
referenced from the repository definition before gh is installed.

#### Example

```bash
gh::install
```

_Function has no arguments._

#### Exit codes

* **0**: GitHub CLI is installed.
* **64**: An argument was given.
* **65**: The downloaded signing key does not match GitHub's fingerprints.
* **69**: The system is not Ubuntu or Fedora, or gpg is missing.
* **74**: The key download or repository configuration failed.
* **77**: sudo refused the credentials.
* other The status of the package manager.

