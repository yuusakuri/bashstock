# path

Lexical path operations and file-type tests.

## Overview

Lexical functions never touch the file system; tests follow the Bash test semantics.

## Index

* [path::directory-name](#pathdirectory-name)
* [path::base-name](#pathbase-name)
* [path::is-directory](#pathis-directory)
* [path::is-empty-directory](#pathis-empty-directory)
* [path::is-executable](#pathis-executable)
* [path::is-executable-file](#pathis-executable-file)
* [path::is-regular-file](#pathis-regular-file)
* [path::is-symbolic-link](#pathis-symbolic-link)
* [path::is-readable](#pathis-readable)
* [path::is-writable](#pathis-writable)
* [path::mode](#pathmode)
* [path::extension](#pathextension)
* [path::normalize](#pathnormalize)
* [path::relative](#pathrelative)
* [path::config-home](#pathconfig-home)
* [path::change-owner-recursively](#pathchange-owner-recursively)
* [path::change-owner-recursively-as-root](#pathchange-owner-recursively-as-root)

### path::directory-name

Write the lexical directory portion of a path.

Like dirname, but without running a command or reading the file system.

#### Example

```bash
path::directory-name /usr/local/bin/node
# /usr/local/bin
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The directory was written.
* **64**: The argument count is not one.

#### Output on stdout

* The directory part; . for a bare name and / for the root.

### path::base-name

Write the final component of a path with an optional suffix removed.

#### Example

```bash
path::base-name /tmp/archive.tar.gz .tar.gz
# archive
```

#### Arguments

* **$1** (string): Path.
* **$2** (string): Optional suffix to remove from the final component.

#### Exit codes

* **0**: The name was written.
* **64**: The argument count is not one or two.

#### Output on stdout

* The final component.

### path::is-directory

Test whether a path names a directory.

A symbolic link to a directory counts.

#### Example

```bash
path::is-directory "${HOME}/.ssh" || mkdir -m 700 "${HOME}/.ssh"
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is a directory.
* **1**: The path is not a directory or does not exist.
* **64**: The argument count is not one.

### path::is-empty-directory

Test whether a path names an empty directory.

Hidden entries count, so a directory with only .gitkeep is not empty.

#### Example

```bash
path::is-empty-directory build && rmdir build
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is a directory without entries.
* **1**: The path is not a directory or has entries.
* **64**: The argument count is not one.

### path::is-executable

Test whether the current user may execute a path.

#### Example

```bash
path::is-executable "${HOME}/.local/bin/android"
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is executable, or searchable for a directory.
* **1**: The path cannot be executed or does not exist.
* **64**: The argument count is not one.

### path::is-executable-file

Test whether a path names an executable regular file.

#### Example

```bash
path::is-executable-file ./gradlew && ./gradlew build
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is a regular file that the current user may execute.
* **1**: The path is not an executable regular file.
* **64**: The argument count is not one.

### path::is-regular-file

Test whether a path names a regular file.

#### Example

```bash
path::is-regular-file "${HOME}/.env" && env::dotenv::import "${HOME}/.env"
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is a regular file.
* **1**: The path is not a regular file or does not exist.
* **64**: The argument count is not one.

### path::is-symbolic-link

Test whether a path names a symbolic link.

#### Example

```bash
path::is-symbolic-link "${HOME}/Desktop" && readlink "${HOME}/Desktop"
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is a symbolic link, even a broken one.
* **1**: The path is not a symbolic link.
* **64**: The argument count is not one.

### path::is-readable

Test whether the current user may read a path.

#### Example

```bash
path::is-readable /etc/os-release && . /etc/os-release
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is readable.
* **1**: The path is not readable or does not exist.
* **64**: The argument count is not one.

### path::is-writable

Test whether the current user may write a path.

#### Example

```bash
path::is-writable /etc/hosts || command::run-as-root cp hosts /etc/hosts
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path is writable.
* **1**: The path is not writable or does not exist.
* **64**: The argument count is not one.

### path::mode

Write a path's permission mode as an octal number.

A symbolic link reports the mode of the link itself.

#### Example

```bash
[[ "$(path::mode "${HOME}/.ssh")" == 700 ]] || chmod 700 "${HOME}/.ssh"
```

#### Arguments

* **$1** (string): Existing path.

#### Exit codes

* **0**: The mode was written.
* **64**: The path is empty, or the argument count is not one.
* **66**: The path does not exist.

#### Output on stdout

* The mode, such as 644 or 4755.

### path::extension

Write the extension of the final path component.

A leading dot does not start an extension, so .bashrc has none.

#### Example

```bash
path::extension /tmp/archive.tar.gz
# .gz
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The extension was written.
* **64**: The argument count is not one.

#### Output on stdout

* The extension with its dot, or an empty line when there is none.

### path::normalize

Normalize a path lexically without accessing the file system.

Repeated slashes and . components are removed and .. removes the previous
component. Leading .. components of a relative path are kept.

#### Example

```bash
path::normalize /usr//local/./lib/../bin
# /usr/local/bin
```

#### Arguments

* **$1** (string): Path.

#### Exit codes

* **0**: The path was written.
* **64**: The argument count is not one.

#### Output on stdout

* The normalized path; . for an empty relative result.

### path::relative

Write the lexical relative path from one path to another.

Both paths are normalized first and must both be absolute or both be relative.

#### Example

```bash
path::relative /usr/local/bin /usr/share/doc
# ../../share/doc
```

#### Arguments

* **$1** (string): Starting directory.
* **$2** (string): Target path.

#### Exit codes

* **0**: The relative path was written.
* **64**: One path is absolute and the other is relative, or the argument count is not two.

#### Output on stdout

* The path that leads from the first path to the second.

### path::config-home

Write the absolute configuration-home directory.

XDG_CONFIG_HOME is used when set; otherwise $HOME/.config.

#### Example

```bash
mkdir -p "$(path::config-home)/mozc"
```

_Function has no arguments._

#### Exit codes

* **0**: The directory was written.
* **64**: An argument was given, or XDG_CONFIG_HOME or HOME is not an absolute path.

#### Output on stdout

* The configuration directory.

### path::change-owner-recursively

Change directory ownership recursively through the root helper.

The ownership change runs in a separate root process of this library and does
not follow symbolic links or cross file systems.

#### Example

```bash
path::change-owner-recursively /srv/app deploy
```

#### Arguments

* **$1** (string): Existing directory; a symbolic link is refused.
* **$2** (string): New owner name.
* **$3** (string): Optional group. Defaults to the owner's primary group.

#### Exit codes

* **0**: The ownership was changed.
* **64**: An owner or group is empty or contains a newline, or the argument count is wrong.
* **66**: The directory does not exist or is a symbolic link.
* other The status of the root helper.

### path::change-owner-recursively-as-root

Change directory ownership recursively in a separate root process.

Same as path::change-owner-recursively; the name states that root is used.

#### Example

```bash
path::change-owner-recursively-as-root /srv/app deploy www-data
```

#### Arguments

* **$1** (string): Existing directory; a symbolic link is refused.
* **$2** (string): New owner name.
* **$3** (string): Optional group. Defaults to the owner's primary group.

#### Exit codes

* **0**: The ownership was changed.
* **64**: An argument is invalid.
* **66**: The directory does not exist or is a symbolic link.
* other The status of the root helper.

