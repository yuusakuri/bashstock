# system

Operating-system family and host identity.

## Overview

Values are normalized so that callers can branch on them without parsing uname output.

## Index

* [system::operating-system](#systemoperating-system)
* [system::host-name](#systemhost-name)

### system::operating-system

Write the normalized operating-system family.

#### Example

```bash
[[ "$(system::operating-system)" == darwin ]] && brew --version
```

_Function has no arguments._

#### Exit codes

* **0**: The family was written.
* **64**: An argument was given.

#### Output on stdout

* darwin, linux, or unknown.

### system::host-name

Write the current host name.

HOSTNAME is used when set; otherwise the hostname command is asked.

#### Example

```bash
printf 'Running on %s\n' "$(system::host-name)"
```

_Function has no arguments._

#### Exit codes

* **0**: The host name was written.
* **1**: The host name cannot be determined.
* **64**: An argument was given.

#### Output on stdout

* The host name.

