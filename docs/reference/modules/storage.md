# storage

Disk usage and trash.

## Overview

Sizes are written in human-readable units.

## Index

* [storage::usage](#storageusage)
* [storage::largest-entries](#storagelargest-entries)
* [storage::clear-trash](#storageclear-trash)

### storage::usage

Show human-readable filesystem usage for a path.

#### Example

```bash
storage::usage "${HOME}"
```

#### Arguments

* **$1** (string): Optional path. Defaults to the current directory.

#### Exit codes

* **0**: The report was written.
* **64**: More than one argument was given.
* **66**: The path does not exist.
* **69**: df is unavailable.

#### Output on stdout

* The df -h report for the file system that holds the path.

### storage::largest-entries

Write the largest entries of a directory, including the directory itself, in human-readable sizes.

Directory sizes include everything below them.

#### Example

```bash
storage::largest-entries "${HOME}/Library/Caches" 5
```

#### Arguments

* **$1** (string): Optional directory to inspect. Defaults to the current directory.
* **$2** (integer): Optional number of entries to write. Defaults to 10.

#### Exit codes

* **0**: The entries were written.
* **64**: The directory does not exist or the count is not a positive integer.
* **69**: du or sort is unavailable.

#### Output on stdout

* Lines of size and path, largest first.

### storage::clear-trash

Empty the Linux desktop trash of the current user through administrator execution.

The entries directly under Trash/files and Trash/info are removed.

#### Example

```bash
storage::clear-trash
```

_Function has no arguments._

#### Exit codes

* **0**: The trash is empty.
* **64**: An argument was given.
* **69**: The system is not Linux.
* **74**: An entry could not be removed.

