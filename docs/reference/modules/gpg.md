# gpg

GPG keys.

## Overview

Keys are generated, listed, exported, and removed with gpg.

## Index

* [gpg::decrypt](#gpgdecrypt)
* [gpg::public-key::armor](#gpgpublic-keyarmor)
* [gpg::secret-key::fingerprints](#gpgsecret-keyfingerprints)
* [gpg::secret-key::list](#gpgsecret-keylist)
* [gpg::setup](#gpgsetup)
* [gpg::key::generate](#gpgkeygenerate)

### gpg::decrypt

Decrypt a GPG file to standard output without adding a newline.

#### Example

```bash
gpg::decrypt secrets.env.gpg > .env
```

#### Arguments

* **$1** (string): Encrypted file.

#### Exit codes

* **0**: The file was decrypted.
* **64**: The argument is not one existing file.
* **69**: gpg is unavailable.
* other The status of gpg.

#### Output on stdout

* The decrypted content.

### gpg::public-key::armor

Write a public GPG key in ASCII armor.

#### Example

```bash
gpg::public-key::armor > public.asc
```

#### Arguments

* **$1** (string): Optional key fingerprint. Defaults to the first secret key.

#### Exit codes

* **0**: The key was written.
* **1**: No fingerprint was given and no secret key exists.
* **64**: More than one argument was given.
* **69**: gpg is unavailable.
* other The status of gpg.

#### Output on stdout

* The ASCII-armored public key.

### gpg::secret-key::fingerprints

Write the fingerprints of every primary secret GPG key, one per line.

#### Example

```bash
gpg::secret-key::fingerprints
```

_Function has no arguments._

#### Exit codes

* **0**: The fingerprints were written.
* **1**: No secret key exists.
* **64**: An argument was given.
* **69**: gpg is unavailable.

#### Output on stdout

* One fingerprint per line.

### gpg::secret-key::list

Write the secret GPG keys in the human-readable GPG format.

#### Example

```bash
gpg::secret-key::list
```

_Function has no arguments._

#### Exit codes

* **0**: The keys were written.
* **64**: An argument was given.
* **69**: gpg is unavailable.
* other The status of gpg.

#### Output on stdout

* The output of gpg --list-secret-keys.

### gpg::setup

Create a GPG key and use it for pass, Git credentials, and Git commit signing.

The options are passed to gpg::key::generate. pass is installed and its
store initialized with the new key, Git Credential Manager stores
credentials with GPG, Git signs commits with the key, and the public key is
written in ASCII armor. The first failing step stops the setup.

#### Example

```bash
gpg::setup --user-id 'Alex Example <developer@example.com>' --passphrase-fd 3 3<passphrase.txt
```

#### Arguments

* **...** (string): Options of gpg::key::generate, such as --user-id and --passphrase-fd.

#### Exit codes

* **0**: Every step finished.
* **74**: The new key could not be identified.
* other The status of the step that failed.

#### Output on stdout

* The ASCII-armored public key of the new key.

### gpg::key::generate

Generate a GPG primary key and an encryption subkey in one operation.

#### Example

```bash
gpg::key::generate --user-id 'Alex Example <developer@example.com>' --pinentry
gpg::key::generate --algorithm rsa4096 --expires 2y --passphrase-fd 3 3<passphrase.txt
```

#### Options

* **--usage \<USAGE\>**

  Primary key usage: sign, cert, auth, or a comma-separated combination. Defaults to sign.

* **--algorithm \<ALGORITHM\>**

  ed25519, rsa3072, or rsa4096. Defaults to ed25519, which pairs an Ed25519 primary key with a Curve25519 encryption subkey.

* **--expires \<EXPIRES\>**

  GnuPG expiration such as 5y, 12m, or 0. Defaults to 5y.

* **--user-id \<USER_ID\>**

  "Name <email>". Defaults to the Git user name and email.

* **--pinentry**

  Ask for the passphrase through pinentry.

* **--passphrase-fd \<FD\>**

  Read the passphrase from a file descriptor.

#### Exit codes

* **0**: The key was generated.
* **64**: An option is unknown or invalid, or no user ID is available.
* **69**: gpg is unavailable.
* **74**: The parameter file could not be written.
* other The status of gpg.

