# dir

Directory creation, comparison, merging, and clearing.

## Overview

Operations keep the directory itself and act on its entries.

## Index

* [dir::diff](#dirdiff)
* [dir::merge](#dirmerge)
* [dir::create-with-date-time](#dircreate-with-date-time)
* [dir::clear](#dirclear)

### dir::diff

Run diff for two directories.

#### Example

```bash
dir::diff config.orig config > config.patch
```

#### Arguments

* **$1** (string): Original directory.
* **$2** (string): Changed directory.

#### Exit codes

* **0**: The directories are identical.
* **1**: The directories differ.
* **64**: The argument count is not two or a directory does not exist.
* **69**: diff is unavailable.
* **2**: diff failed.

#### Output on stdout

* A unified diff that includes new files.

### dir::merge

Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE.

Directories are merged recursively. A file or symbolic link in SOURCE
replaces the entry with the same name in DESTINATION. Symbolic links are
never followed. The first failure stops the merge.

#### Example

```bash
dir::merge "${HOME}/デスクトップ" "${HOME}/Desktop"
```

#### Arguments

* **$1** (string): SOURCE Directory to empty and remove.
* **$2** (string): DESTINATION Directory to receive the entries; created when missing.

#### Exit codes

* **0**: SOURCE was merged into DESTINATION and removed.
* **64**: SOURCE is not a directory, DESTINATION is a symbolic link or a file, DESTINATION is SOURCE or inside it, or SOURCE holds an entry that would replace SOURCE itself.
* **74**: An entry could not be moved, or SOURCE could not be removed.

### dir::create-with-date-time

Create a directory named with the local date and time and write its path.

The name has the form YYYYMMDDTHHMMSS. When that name exists, a suffix
counting from -2 is added.

#### Example

```bash
backup="$(dir::create-with-date-time /var/backups)"
```

#### Arguments

* **$1** (string): DIRECTORY Parent directory. Defaults to the current directory.

#### Exit codes

* **0**: The directory was created.
* **64**: More than one argument was given.
* **66**: The parent directory does not exist.
* **69**: The clock provider is unavailable.
* **74**: The directory could not be created.

#### Output on stdout

* The path of the new directory, such as ./20261014T120405.

### dir::clear

Remove every entry of a directory, including hidden ones, and keep the directory.

An empty name, the file system root, the home directory, and a symbolic
link are refused, because a link would empty the directory it points to.

#### Example

```bash
dir::clear ./build
```

#### Arguments

* **$1** (string): DIRECTORY Directory to empty. Defaults to the current directory.

#### Exit codes

* **0**: The directory is empty.
* **64**: The directory is missing, a symbolic link, the root, or the home directory.
* **66**: The directory cannot be entered.
* **74**: An entry could not be removed.

#### Output on stderr

* A message when the directory is refused.

