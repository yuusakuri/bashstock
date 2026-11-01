# ssh

SSH keys, configuration, connections, and server installation.

## Overview

Keys and host entries live in the user's ~/.ssh directory.

## Index

* [ssh::setup-directory](#sshsetup-directory)
* [ssh::config::update](#sshconfigupdate)
* [ssh::config::set](#sshconfigset)
* [ssh::config::enable-auto-add-keys](#sshconfigenable-auto-add-keys)
* [ssh::config::disable-host-key-checking](#sshconfigdisable-host-key-checking)
* [ssh::key::private-files](#sshkeyprivate-files)
* [ssh::key::add](#sshkeyadd)
* [ssh::key::add-all](#sshkeyadd-all)
* [ssh::key::add-all-private-keys](#sshkeyadd-all-private-keys)
* [ssh::key::generate-rsa4096](#sshkeygenerate-rsa4096)
* [ssh::key::generate-ed25519](#sshkeygenerate-ed25519)
* [ssh::kill-all](#sshkill-all)
* [ssh::server::versions](#sshserverversions)
* [ssh::server::install](#sshserverinstall)

### ssh::setup-directory

Create $HOME/.ssh and give it and its files the modes SSH expects.

Entries owned by another user are first given back to the current user
through administrator execution. Directories become 700 and files 644,
except private keys, config, and authorized_keys, which become 600. A
private key is recognized by its PEM or OpenSSH header, so no passphrase
is ever requested.

#### Example

```bash
ssh::setup-directory
```

_Function has no arguments._

#### Exit codes

* **0**: The directory and its files have the expected modes.
* **64**: An argument was given.
* **74**: A mode or owner could not be changed.

### ssh::config::update

Update one key in a marker-managed SSH Host block.

The Host block is created when missing. Only blocks written by BashStock are changed.

#### Example

```bash
ssh::config::update "${HOME}/.ssh/config" github.com IdentityFile '~/.ssh/github'
```

#### Arguments

* **$1** (string): SSH configuration file.
* **$2** (string): Host pattern.
* **$3** (string): Key, such as IdentityFile.
* **$4** (string): Value on one line.

#### Exit codes

* **0**: The key was written.
* **64**: The arguments are invalid.
* **65**: The file has a begin marker without an end marker, or ssh rejected the result; the file is unchanged.
* other The status of the file update.

### ssh::config::set

Create an SSH configuration file when necessary and update one key.

#### Example

```bash
ssh::config::set "${HOME}/.ssh/config" 'build-*' User builder
```

#### Arguments

* **$1** (string): SSH configuration file. It and its directory are created when missing.
* **$2** (string): Host pattern.
* **$3** (string): Key, such as User.
* **$4** (string): Value on one line.

#### Exit codes

* **0**: The key was written.
* **64**: The arguments are invalid or the file is a symbolic link.
* **66**: The path exists but is not a regular file.
* **74**: The file could not be created.
* other The status of ssh::config::update.

### ssh::config::enable-auto-add-keys

Enable AddKeysToAgent for an optional SSH Host pattern.

#### Example

```bash
ssh::config::enable-auto-add-keys
```

#### Arguments

* **$1** (string): Optional SSH configuration file. Defaults to $HOME/.ssh/config.
* **$2** (string): Optional Host pattern. Defaults to *.

#### Exit codes

* **0**: AddKeysToAgent is enabled.
* **64**: More than two arguments were given.
* other The status of ssh::config::set.

### ssh::config::disable-host-key-checking

Disable SSH host-key checks for an optional Host pattern.

Normal use should register the correct host key in known_hosts instead.

#### Example

```bash
ssh::config::disable-host-key-checking "${HOME}/.ssh/config" '192.168.56.*'
```

#### Arguments

* **$1** (string): Optional SSH configuration file. Defaults to $HOME/.ssh/config.
* **$2** (string): Optional Host pattern. Defaults to *.

#### Exit codes

* **0**: Host-key checks are disabled for the pattern.
* **64**: More than two arguments were given or the file is a symbolic link.
* **66**: The path exists but is not a regular file.
* **74**: The file could not be created.
* other The status of the file update.

### ssh::key::private-files

List regular files that ssh-keygen can read as private keys.

#### Example

```bash
ssh::key::private-files
```

#### Arguments

* **$1** (string): Optional directory. Defaults to $HOME/.ssh.

#### Exit codes

* **0**: The paths were written; none may match.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: ssh-keygen is unavailable.

#### Output on stdout

* One private key path per line.

### ssh::key::add

Add one private key to ssh-agent.

#### Example

```bash
ssh::key::add "${HOME}/.ssh/id_ed25519"
```

#### Arguments

* **$1** (string): Private key file.

#### Exit codes

* **0**: The key was added.
* **64**: The argument is not one regular file.
* **69**: ssh-add is unavailable.
* other The status of ssh-add.

### ssh::key::add-all

Add every detected private key in a directory to ssh-agent.

#### Example

```bash
ssh::key::add-all
```

#### Arguments

* **$1** (string): Optional directory. Defaults to $HOME/.ssh.

#### Exit codes

* **0**: Every key was added.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: ssh-add or ssh-keygen is unavailable.
* other The status of the last ssh-add that failed.

### ssh::key::add-all-private-keys

Add every detected private key in a directory to ssh-agent.

This is an alias of ssh::key::add-all.

#### Example

```bash
ssh::key::add-all-private-keys
```

#### Arguments

* **$1** (string): Optional directory. Defaults to $HOME/.ssh.

#### Exit codes

* **0**: Every key was added.
* other The status of ssh::key::add-all.

### ssh::key::generate-rsa4096

Generate a 4096-bit RSA SSH key and write its public key.

An existing key is replaced only after confirmation on the controlling
terminal; without a terminal it is kept and 73 is returned. The old key
stays in place until the new key has been generated.

#### Example

```bash
ssh::key::generate-rsa4096 --comment 'build server' --output "${HOME}/.ssh/build_rsa"
```

#### Options

* **--comment \<COMMENT\>**

  Key comment. Defaults to an empty comment.

* **--output \<FILE\>**

  Private key path. Defaults to $HOME/.ssh/id_rsa.

* **--passphrase-fd \<FD\>**

  File descriptor to read the passphrase from. Defaults to no passphrase.

#### Exit codes

* **0**: The key was generated.
* **64**: An option is unknown or has an invalid value.
* **66**: The passphrase could not be read.
* **69**: ssh-keygen is unavailable.
* **73**: The key exists and was kept.
* **74**: The directory or the temporary key could not be created, or the new key could not replace the old one.
* other The status of ssh-keygen.

#### Output on stdout

* The public key.

### ssh::key::generate-ed25519

Generate an Ed25519 SSH key and write its public key.

An existing key is replaced only after confirmation on the controlling
terminal; without a terminal it is kept and 73 is returned. The old key
stays in place until the new key has been generated.

#### Example

```bash
ssh::key::generate-ed25519 --comment "$(id -un)@$(hostname)" --passphrase-fd 3 3<passphrase.txt
```

#### Options

* **--comment \<COMMENT\>**

  Key comment. Defaults to an empty comment.

* **--output \<FILE\>**

  Private key path. Defaults to $HOME/.ssh/id_ed25519.

* **--passphrase-fd \<FD\>**

  File descriptor to read the passphrase from. Defaults to no passphrase.

#### Exit codes

* **0**: The key was generated.
* **64**: An option is unknown or has an invalid value.
* **66**: The passphrase could not be read.
* **69**: ssh-keygen is unavailable.
* **73**: The key exists and was kept.
* **74**: The directory or the temporary key could not be created, or the new key could not replace the old one.
* other The status of ssh-keygen.

#### Output on stdout

* The public key.

### ssh::kill-all

End every SSH process of the current user.

#### Example

```bash
ssh::kill-all
```

_Function has no arguments._

#### Exit codes

* **0**: At least one SSH process was signaled.
* **1**: No SSH process was running.
* **64**: An argument was given.
* **69**: pkill is unavailable.

### ssh::server::versions

Write OpenSSH server versions available to the current platform.

#### Example

```bash
ssh::server::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* OpenSSH server package versions, one per line.

### ssh::server::install

Install the OpenSSH server, enable it at boot, and start it.

#### Example

```bash
ssh::server::install
```

#### Arguments

* **$1** (string): Optional version from ssh::server::versions. Defaults to the newest one.

#### Exit codes

* **0**: The server is installed, enabled at boot, and running.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager or systemctl.

