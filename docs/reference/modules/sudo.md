# sudo

sudo credentials and passwordless rules.

## Overview

Rules are written as sudoers drop-in files after validation with visudo.

## Index

* [sudo::start-keep-alive](#sudostart-keep-alive)
* [sudo::passwordless::enable](#sudopasswordlessenable)
* [sudo::passwordless::disable](#sudopasswordlessdisable)

### sudo::start-keep-alive

Keep the sudo credentials of the calling process fresh in the background.

sudo is authenticated once, and a background process renews the
credentials every 60 seconds until the calling process exits.

#### Example

```bash
sudo::start-keep-alive && go::install && rust::install
```

_Function has no arguments._

#### Exit codes

* **0**: The credentials are fresh and the renewal runs in the background.
* **64**: An argument was given.
* **69**: sudo is unavailable.
* **77**: sudo authentication failed.

### sudo::passwordless::enable

Let a user run every command through sudo without entering a password.

The rule `USER ALL=(ALL) NOPASSWD: ALL` is written to its own file in
/etc/sudoers.d without opening an editor. visudo checks the rule before it
is installed and the whole configuration afterwards. sudo applies the last
matching rule, so the file name sorts after other drop-in files, and the
main sudoers file of macOS, Ubuntu, and Fedora reads the directory after
its group rules. If sudo still asks the user for a password, the file is
removed and the function fails. Running it again rewrites the same file.

#### Example

```bash
sudo::passwordless::enable "$(id -un)"
```

#### Arguments

* **$1** (string): Optional login name. Defaults to the user who invoked sudo, or the current user.

#### Exit codes

* **0**: The user can run sudo without a password.
* **64**: More than one argument was given or the user does not exist.
* **69**: sudo still asks for a password; the file was removed.
* **74**: The rule could not be written, checked, or installed.
* other The status of the user lookup.

#### Output on stderr

* A message when the user does not exist or sudo does not apply the rule.

### sudo::passwordless::disable

Remove the passwordless sudo rule that sudo::passwordless::enable added.

Only the BashStock drop-in file of the user is removed, so sudo asks for
the password again unless another sudoers rule also grants NOPASSWD. The
function succeeds when the file does not exist.

#### Example

```bash
sudo::passwordless::disable
```

#### Arguments

* **$1** (string): Optional login name. Defaults to the user who invoked sudo, or the current user.

#### Exit codes

* **0**: The rule file does not exist.
* **64**: More than one argument was given.
* **74**: The file could not be removed.
* other The status of the user lookup.

