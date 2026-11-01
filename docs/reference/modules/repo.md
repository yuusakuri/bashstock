# repo

Google Repo workspaces.

## Overview

Workspaces are initialized and synchronized with the repo tool.

## Index

* [repo::init](#repoinit)
* [repo::sync](#reposync)
* [repo::write-manifest](#repowrite-manifest)
* [repo::check](#repocheck)
* [repo::reset](#reporeset)

### repo::init

Initialize a Google Repo workspace with shallow history.

#### Example

```bash
repo::init https://android.googlesource.com/platform/manifest android-14.0.0_r1 default.xml aosp
```

#### Arguments

* **$1** (string): Manifest repository URL.
* **$2** (string): Manifest branch.
* **$3** (string): Manifest file name.
* **$4** (string): Optional workspace directory, created when missing. Defaults to the current directory.

#### Exit codes

* **0**: The workspace was initialized.
* **64**: The arguments are invalid.
* **69**: repo is unavailable.
* **74**: The directory could not be created.
* other The status of repo init.

### repo::sync

Synchronize one path of a Google Repo workspace, forcing the sync.

#### Example

```bash
repo::sync frameworks/base 8 aosp
```

#### Arguments

* **$1** (string): Project path to synchronize.
* **$2** (integer): Optional parallel jobs. Defaults to 4.
* **$3** (string): Optional workspace directory. Defaults to the current directory.

#### Exit codes

* **0**: The project was synchronized.
* **64**: The arguments are invalid.
* **69**: repo is unavailable.
* other The status of repo sync.

### repo::write-manifest

Write the current Google Repo manifest with revisions to a file.

#### Example

```bash
repo::write-manifest pinned.xml aosp
```

#### Arguments

* **$1** (string): Optional output file. Defaults to ./manifest.xml.
* **$2** (string): Optional workspace directory. Defaults to the current directory.

#### Exit codes

* **0**: The manifest was written.
* **64**: More than two arguments were given.
* **69**: repo is unavailable.
* other The status of repo manifest.

### repo::check

Run git fsck in every project of a Google Repo workspace.

#### Example

```bash
repo::check aosp
```

#### Arguments

* **$1** (string): Optional workspace directory. Defaults to the current directory.

#### Exit codes

* **0**: Every project passed.
* **64**: More than one argument was given.
* **69**: repo is unavailable.
* other The status of repo forall.

#### Output on stdout

* The output of git fsck for each project.

### repo::reset

Hard reset every project of a Google Repo workspace and remove untracked files.

Every uncommitted change in every project is discarded. Ignored files are kept.

#### Example

```bash
repo::reset aosp
```

#### Arguments

* **$1** (string): Optional workspace directory. Defaults to the current directory.

#### Exit codes

* **0**: Every project was reset.
* **64**: More than one argument was given.
* **69**: repo is unavailable.
* other The status of repo forall.

