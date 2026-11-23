# linux

Common Linux setup.

## Overview

The module defines the setup steps that Ubuntu and Fedora share.

## Index

* [linux::setup](#linuxsetup)

### linux::setup

Apply the common Linux user configuration, stopping at the first failure.

This function supports Ubuntu and Fedora. It ensures the setup tools are
installed, then configures Wayland, the user's environment, shell, Git, and SSH.

#### Example

```bash
linux::setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The platform is not Ubuntu or Fedora.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

