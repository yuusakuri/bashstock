# ubuntu

Ubuntu setup and server images.

## Overview

Setup functions configure a fresh Ubuntu installation.

## Index

* [ubuntu::server-iso-versions](#ubuntuserver-iso-versions)
* [ubuntu::download-server-iso](#ubuntudownload-server-iso)
* [ubuntu::setup](#ubuntusetup)
* [ubuntu::setup-external](#ubuntusetup-external)
* [ubuntu::setup-desktop](#ubuntusetup-desktop)
* [ubuntu::setup-desktop-22](#ubuntusetup-desktop-22)

### ubuntu::server-iso-versions

Write the Ubuntu Server LTS versions whose live server ISO is published for an architecture.

The LTS series come from the Ubuntu release metadata, and each version is
taken from the official SHA256SUMS of its series, so every listed version
can be downloaded.

#### Example

```bash
ubuntu::server-iso-versions arm64
```

#### Arguments

* **$1** (string): Optional architecture: amd64 or arm64. Defaults to the current machine.

#### Exit codes

* **0**: The versions were written.
* **64**: The architecture is not amd64 or arm64.
* **69**: No image is published for the architecture.
* **74**: The release metadata could not be downloaded.

#### Output on stdout

* Ubuntu Server versions such as 24.04.3, one per line, oldest first.

### ubuntu::download-server-iso

Download an Ubuntu Server live ISO and check it against the official SHA256SUMS.

The image is written to a temporary file next to OUTPUT_PATH and moved into
place only after its checksum matches, so a failed download or a corrupted
image leaves an existing file unchanged.

#### Example

```bash
ubuntu::download-server-iso 24.04.3 amd64 "${HOME}/iso/ubuntu.iso"
```

#### Arguments

* **$1** (string): Optional version from ubuntu::server-iso-versions. Defaults to the newest one.
* **$2** (string): Optional architecture: amd64 or arm64. Defaults to the current machine.
* **$3** (string): Optional destination file. Defaults to the official file name in the current directory.

#### Exit codes

* **0**: The verified image is at the destination.
* **64**: The architecture is invalid, or the argument count is wrong.
* **69**: The version is not published for the architecture.
* **74**: The download failed, the checksum does not match, or the file could not be moved.

### ubuntu::setup

Apply the common Ubuntu user configuration, stopping at the first failure.

Missing curl, Git, and Perl modules that bashstock uses are installed first.
The steps then register ~/.env, set the editor of Bash and Zsh to
code --wait, ignore case in completion, link English names to localized
user directories, add the user to dialout, configure Git, and fix ~/.ssh
permissions. External tools can be installed separately with
ubuntu::setup-external. Electron applications prefer native Wayland rendering
in supported Wayland sessions.

#### Example

```bash
GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' ubuntu::setup
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Ubuntu.
* **77**: sudo refused the credentials.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

### ubuntu::setup-external

Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available.

GitHub CLI is installed from its official Ubuntu APT repository after checking
the repository key against GitHub's published fingerprints. Git is configured
to use Git Credential Manager after the missing external tools are installed.

#### Example

```bash
ubuntu::setup-external
```

_Function has no arguments._

#### Exit codes

* **0**: The missing tools were installed or were already available.
* **64**: An argument was given.
* **69**: The system is not Ubuntu, or a required command is missing.
* **77**: sudo refused the credentials.
* other A package installation or repository setup failed.

### ubuntu::setup-desktop

Apply the Ubuntu user configuration and desktop settings, stopping at the first failure.

After ubuntu::setup, missing IBus Mozc is installed, and the IME keys, Mozc
and US input sources, and Hiragana start are set. Electron applications prefer
native Wayland rendering in supported Wayland sessions. On Ubuntu 22.04, the newest
available Mozc is installed first and the GNOME title-bar buttons are set.

#### Example

```bash
ubuntu::setup-desktop
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Ubuntu.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed.

### ubuntu::setup-desktop-22

Run the Ubuntu 22.04 desktop setup through the shared desktop setup function.

This compatibility entry point validates the Ubuntu release and delegates to
ubuntu::setup-desktop, which handles the version-specific Mozc and title-bar
settings.

#### Example

```bash
ubuntu::setup-desktop-22
```

_Function has no arguments._

#### Exit codes

* **0**: Every step succeeded.
* **64**: An argument was given.
* **69**: The system is not Ubuntu 22.04.
* other The status of the first step that failed.

#### Output on stderr

* The step that failed, or a message on other releases.

