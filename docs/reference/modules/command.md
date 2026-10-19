# command

Command lookup and administrator execution.

## Overview

Administrator execution uses sudo only when the current user is not root.

## Index

* [command::exists](#commandexists)
* [command::require](#commandrequire)
* [command::run-as-root](#commandrun-as-root)

### command::exists

Test whether a command name resolves in the current environment.

Functions, aliases, builtins, and executables on PATH all count.

#### Example

```bash
command::exists docker && docker version
```

#### Arguments

* **$1** (string): Command name; it must not start with a dash.

#### Exit codes

* **0**: The command resolves.
* **1**: The command does not resolve.
* **64**: The name is empty, starts with a dash, or contains a newline.

### command::require

Require a command name to resolve in the current environment.

#### Example

```bash
command::require curl || return "$?"
```

#### Arguments

* **$1** (string): Command name.

#### Exit codes

* **0**: The command resolves.
* **64**: The name is invalid.
* **69**: The command is unavailable.

#### Output on stderr

* A message naming the command when it is unavailable.

### command::run-as-root

Run a command directly as root or through validated sudo access.

The command runs as is when the process is already root. Otherwise sudo
validates the credentials first; noninteractive shells never wait for sudo
password input.

#### Example

```bash
command::run-as-root install -m 0644 ./rule /etc/udev/rules.d/90-device.rules
```

#### Arguments

* **$1** (string): Command to run.
* **...** (string): Arguments of the command.

#### Exit codes

* **0**: The command succeeded.
* **64**: No command was given.
* **69**: sudo is unavailable.
* **77**: sudo refused the credentials or would need a password in a noninteractive shell.
* other The status of the command.

#### Output on stderr

* A message when sudo is missing.

