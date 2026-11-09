# setup

Linux setup and shared setup steps.

## Overview

The module defines common Linux configuration and internal setup helpers.

## Index

* [setup::linux-config](#setuplinux-config)

### setup::linux-config

Apply the common Linux user configuration, stopping at the first failure.

This function supports Ubuntu and Fedora. It ensures the setup tools are
installed, then configures Wayland, the user's environment, shell, Git, and SSH.

#### Example

```bash
setup::linux-config
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The platform is not Ubuntu or Fedora.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

