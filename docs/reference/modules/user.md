# user

User and group lookup and account creation.

## Overview

Account creation runs through administrator execution and works on macOS, Ubuntu, and Fedora.

## Index

* [user::name](#username)
* [user::primary-group](#userprimary-group)
* [user::is-root](#useris-root)
* [user::exists](#userexists)
* [user::create-system-as-root](#usercreate-system-as-root)
* [user::create-login-as-root](#usercreate-login-as-root)
* [user::create-system](#usercreate-system)
* [user::create-login](#usercreate-login)

### user::name

Write the effective user's name.

#### Example

```bash
printf 'Installing for %s\n' "$(user::name)"
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **74**: id could not report the name.

#### Output on stdout

* The user name.

### user::primary-group

Write the effective user's primary group name.

#### Example

```bash
chown "$(user::name):$(user::primary-group)" "${file}"
```

_Function has no arguments._

#### Exit codes

* **0**: The group was written.
* **64**: An argument was given.
* **74**: id could not report the group.

#### Output on stdout

* The group name.

### user::is-root

Test whether the effective user is root.

#### Example

```bash
user::is-root || printf 'Run this with sudo.\n' >&2
```

_Function has no arguments._

#### Exit codes

* **0**: The effective user ID is 0.
* **1**: The user is not root.
* **64**: An argument was given.

### user::exists

Test whether a local user account exists.

#### Example

```bash
user::exists deploy || user::create-system _deploy
```

#### Arguments

* **$1** (string): User name.

#### Exit codes

* **0**: The account exists.
* **1**: No account has that name.
* **64**: The name is empty, starts with a dash, or contains a newline.

### user::create-system-as-root

Create a non-login system account in a separate root process.

#### Example

```bash
user::create-system-as-root _backup
```

#### Arguments

* **$1** (string): Account name that starts with an underscore, such as _backup.

#### Exit codes

* **0**: The account was created.
* **64**: The name is not an underscore-prefixed lowercase name.
* **73**: The account already exists or cannot be created.
* other The status of the root helper.

### user::create-login-as-root

Create a local login account in a separate root process.

The new password is read from the controlling terminal; a failed password
entry removes the new account again.

#### Example

```bash
user::create-login-as-root alice 'Alice Example'
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

### user::create-system

Create a non-login system account.

#### Example

```bash
user::create-system _backup
```

#### Arguments

* **$1** (string): Account name that starts with an underscore, such as _backup.

#### Exit codes

* **0**: The account was created.
* **64**: The name is not an underscore-prefixed lowercase name.
* **73**: The account already exists or cannot be created.
* other The status of the root helper.

### user::create-login

Create a local login account.

The new password is read from the controlling terminal; a failed password
entry removes the new account again.

#### Example

```bash
user::create-login alice 'Alice Example'
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

