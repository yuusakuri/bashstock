# user

User and group lookup, account creation, and home directories.

## Overview

Account creation runs through administrator execution and works on macOS, Ubuntu, and Fedora.

## Index

* [user__name](#user__name)
* [user__primary-group](#user__primary-group)
* [user__is-root](#user__is-root)
* [user__exists](#user__exists)
* [user__create-system-as-root](#user__create-system-as-root)
* [user__create-login-as-root](#user__create-login-as-root)
* [user__create-system](#user__create-system)
* [user__create-login](#user__create-login)
* [user__add-to-group](#user__add-to-group)
* [user__directory__create-english-links](#user__directory__create-english-links)

### user__name

Write the effective user's name.

#### Example

```bash
printf 'Installing for %s\n' "$(user__name)"
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **74**: id could not report the name.

#### Output on stdout

* The user name.

### user__primary-group

Write the effective user's primary group name.

#### Example

```bash
chown "$(user__name):$(user__primary-group)" "${file}"
```

_Function has no arguments._

#### Exit codes

* **0**: The group was written.
* **64**: An argument was given.
* **74**: id could not report the group.

#### Output on stdout

* The group name.

### user__is-root

Test whether the effective user is root.

#### Example

```bash
user__is-root || printf 'Run this with sudo.\n' >&2
```

_Function has no arguments._

#### Exit codes

* **0**: The effective user ID is 0.
* **1**: The user is not root.
* **64**: An argument was given.

### user__exists

Test whether a local user account exists.

#### Example

```bash
user__exists deploy || user__create-system _deploy
```

#### Arguments

* **$1** (string): User name.

#### Exit codes

* **0**: The account exists.
* **1**: No account has that name.
* **64**: The name is empty, starts with a dash, or contains a newline.

### user__create-system-as-root

Create a non-login system account in a separate root process.

#### Example

```bash
user__create-system-as-root _backup
```

#### Arguments

* **$1** (string): Account name that starts with an underscore, such as _backup.

#### Exit codes

* **0**: The account was created.
* **64**: The name is not an underscore-prefixed lowercase name.
* **73**: The account already exists or cannot be created.
* other The status of the root helper.

### user__create-login-as-root

Create a local login account in a separate root process.

The new password is read from the controlling terminal; a failed password
entry removes the new account again.

#### Example

```bash
user__create-login-as-root alice 'Alice Example'
```

#### Arguments

* **$1** (string): Account name: a lowercase letter followed by lowercase letters, digits, - or _.
* **$2** (string): Full name; it must not contain : or control characters.

#### Exit codes

* **0**: The account was created.
* **64**: The name or full name is invalid.
* **66**: No controlling terminal is available for the password.
* **73**: The account already exists or cannot be created.
* other The status of the root helper.

### user__create-system

Create a non-login system account.

#### Example

```bash
user__create-system _backup
```

#### Arguments

* **$1** (string): Account name that starts with an underscore, such as _backup.

#### Exit codes

* **0**: The account was created.
* **64**: The name is not an underscore-prefixed lowercase name.
* **73**: The account already exists or cannot be created.
* other The status of the root helper.

### user__create-login

Create a local login account.

The new password is read from the controlling terminal; a failed password
entry removes the new account again.

#### Example

```bash
user__create-login alice 'Alice Example'
```

#### Arguments

* **$1** (string): Account name: a lowercase letter followed by lowercase letters, digits, - or _.
* **$2** (string): Full name; it must not contain : or control characters.

#### Exit codes

* **0**: The account was created.
* **64**: The name or full name is invalid.
* **66**: No controlling terminal is available for the password.
* **73**: The account already exists or cannot be created.
* other The status of the root helper.

### user__add-to-group

Add a user to a supplementary group through administrator execution.

#### Example

```bash
user__add-to-group dialout
```

#### Arguments

* **$1** (string): Group name.
* **$2** (string): Optional user name. Defaults to the current user.

#### Exit codes

* **0**: The user is in the group; it applies to new login sessions.
* **64**: The group name is invalid, or the argument count is wrong.
* **69**: The operating system is unsupported, or usermod or dseditgroup is unavailable.
* **77**: sudo refused the credentials.
* other The status of usermod or dseditgroup.

### user__directory__create-english-links

Link the English XDG user directory names to the directories of the current locale.

Each standard XDG directory is resolved with xdg-user-dir. A localized
directory that does not exist is skipped and never created. An existing
English directory is merged into the localized one, overwriting entries
with the same name, and then replaced by the link.

#### Example

```bash
user__directory__create-english-links
```

#### Arguments

* **$1** (string): Optional home directory to update. Defaults to $HOME.

#### Exit codes

* **0**: Every link was created or already existed.
* **64**: More than one argument was given.
* **66**: The home directory does not exist.
* **69**: xdg-user-dir is unavailable.
* **73**: An English name is held by something other than a directory or link.
* **74**: A directory could not be resolved, removed, or linked.
* other The status of dir__merge.

#### Output on stderr

* A message for each English name that is not a directory.

