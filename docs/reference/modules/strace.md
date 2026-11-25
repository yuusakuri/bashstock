# strace

System call tracing.

## Overview

Processes are traced with strace on Linux.

## Index

* [strace__attach-pid](#strace__attach-pid)
* [strace__attach-name](#strace__attach-name)

### strace__attach-pid

Attach strace to a process on Linux.

Administrator execution is used only when the process cannot be traced
with the current permissions.

#### Example

```bash
strace__attach-pid "$(pgrep -x nginx | head -n 1)"
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: strace ended successfully.
* **64**: The argument is not one process ID.
* **69**: The system is not Linux or strace is unavailable.
* other The status of strace.

#### Output on stderr

* The system calls that strace reports.

### strace__attach-name

Attach strace to the first process whose executable name is NAME.

#### Example

```bash
strace__attach-name nginx
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: strace ended successfully.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of strace__attach-pid.

#### Output on stderr

* The system calls that strace reports.

