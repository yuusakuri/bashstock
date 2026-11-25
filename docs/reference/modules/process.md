# process

Process and thread lookup.

## Overview

Processes are matched by executable name or command line.

## Index

* [process__ids-by-name](#process__ids-by-name)
* [process__ids-by-name-regex](#process__ids-by-name-regex)
* [process__threads-by-pid](#process__threads-by-pid)
* [process__threads-by-name](#process__threads-by-name)

### process__ids-by-name

Write the IDs of the processes whose executable name is exactly NAME, one per line.

#### Example

```bash
process__ids-by-name sshd
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: At least one process matches.
* **1**: No process matches.
* **64**: The argument count is not one.
* **69**: pgrep is unavailable.

#### Output on stdout

* One process ID per line.

### process__ids-by-name-regex

Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f.

#### Example

```bash
process__ids-by-name-regex 'python3 .*manage\.py runserver'
```

#### Arguments

* **$1** (string): Extended regular expression matched against the full command line.

#### Exit codes

* **0**: At least one process matches.
* **1**: No process matches.
* **64**: The argument count is not one.
* **69**: pgrep is unavailable.

#### Output on stdout

* One process ID per line.

### process__threads-by-pid

Write the threads of one process.

Linux uses ps -T and macOS ps -M.

#### Example

```bash
process__threads-by-pid "$$"
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: The threads were written.
* **1**: No process has the ID.
* **64**: The argument is not one process ID.
* **69**: ps is unavailable or the operating system is unsupported.

#### Output on stdout

* The ps listing of the threads.

### process__threads-by-name

Write the threads of the first process whose executable name is NAME.

#### Example

```bash
process__threads-by-name java
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: The threads were written.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of process__threads-by-pid.

#### Output on stdout

* The ps listing of the threads.

