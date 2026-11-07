# fedora

Fedora setup.

## Overview

Setup functions configure a fresh Fedora installation.

## Index

* [fedora::setup](#fedorasetup)
* [fedora::setup-external](#fedorasetup-external)

### fedora::setup

Apply the common Fedora user configuration, stopping at the first failure.

The same steps as ubuntu::setup run on Fedora: missing curl, Git, and Perl
modules that bashstock uses are installed, ~/.env is registered, the editor
of Bash and Zsh is set to code --wait, completion ignores case, English
names are linked to localized user directories, the user joins dialout, Git
uses Git Credential Manager, ~/.ssh permissions are fixed, and external
tools are installed. In supported Wayland sessions, Electron applications
also prefer native Wayland rendering.

#### Example

```bash
GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' fedora::setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Fedora.
* **77**: sudo refused the credentials.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

### fedora::setup-external

Install GnuPG, GitHub CLI, and Git Credential Manager on Fedora when they are not already available.

GitHub CLI is installed from its official DNF repository after checking the
repository key against GitHub's published fingerprints.

#### Example

```bash
fedora::setup-external
```

_Function has no arguments._

#### Exit codes

* **0**: The missing tools were installed or were already available.
* **64**: An argument was given.
* **69**: The system is not Fedora, or a required command is missing.
* **77**: sudo refused the credentials.
* other A package installation or repository setup failed.

