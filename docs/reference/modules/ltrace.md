# ltrace

Library call tracing.

## Overview

Processes are traced with ltrace on Linux.

## Index

* [ltrace__attach-pid](#ltrace__attach-pid)
* [ltrace__attach-name](#ltrace__attach-name)

### ltrace__attach-pid

Attach ltrace to a process on Linux.

Administrator execution is used only when the process cannot be traced
with the current permissions.

#### Example

```bash
ltrace__attach-pid 4242
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: ltrace ended successfully.
* **64**: The argument is not one process ID.
* **69**: The system is not Linux or ltrace is unavailable.
* other The status of ltrace.

#### Output on stderr

* The library calls that ltrace reports.

### ltrace__attach-name

Attach ltrace to the first process whose executable name is NAME.

#### Example

```bash
ltrace__attach-name myapp
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: ltrace ended successfully.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of ltrace__attach-pid.

#### Output on stderr

* The library calls that ltrace reports.

