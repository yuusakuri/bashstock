# symlink

Symbolic links.

## Overview

Links point to absolute paths and use administrator execution only when needed.

## Index

* [symlink__create](#symlink__create)
* [symlink__remove](#symlink__remove)
* [symlink__create-in-local-bin](#symlink__create-in-local-bin)

### symlink__create

Create or replace a symbolic link that points to the absolute path of an existing SOURCE.

An existing symbolic link at LINK is replaced; a file or directory there is
kept and returns 73. Administrator execution is used only when the parent
directory of LINK is not writable.

#### Example

```bash
symlink__create ./dotfiles/.vimrc "${HOME}/.vimrc"
```

#### Arguments

* **$1** (string): SOURCE Existing path the link points to.
* **$2** (string): LINK Path of the link.

#### Exit codes

* **0**: LINK points to the absolute path of SOURCE.
* **64**: An argument is empty, or the argument count is not two.
* **66**: SOURCE does not exist.
* **73**: LINK exists and is not a symbolic link.
* **74**: The link could not be created.

### symlink__remove

Remove a symbolic link, using administrator execution only when its directory is not writable.

#### Example

```bash
symlink__remove "${HOME}/.vimrc"
```

#### Arguments

* **$1** (string): Path of an existing symbolic link; its target is not touched.

#### Exit codes

* **0**: The link was removed.
* **64**: The path is not a symbolic link, or the argument count is not one.
* **74**: The link could not be removed.

### symlink__create-in-local-bin

Create a symbolic link in a user's local bin directory.

#### Example

```bash
symlink__create-in-local-bin /opt/flutter/bin/flutter
```

#### Arguments

* **$1** (string): Existing file or directory to link to.
* **$2** (string): Optional link name. Defaults to the base name of the source.
* **$3** (string): Optional bin directory. Defaults to $HOME/.local/bin.

#### Exit codes

* **0**: The link was created.
* **64**: The arguments are invalid or the source does not exist.
* **74**: The bin directory could not be created.
* other The status of symlink__create.

