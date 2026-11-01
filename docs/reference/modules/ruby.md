# ruby

Ruby installation and versions.

## Overview

Ruby is installed with rbenv.

## Index

* [ruby::version::list](#rubyversionlist)
* [ruby::version::latest](#rubyversionlatest)
* [ruby::install](#rubyinstall)

### ruby::version::list

Write stable Ruby versions that rbenv can install in ascending order.

#### Example

```bash
ruby::version::list | tail -n 5
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: rbenv is unavailable.
* **74**: rbenv could not list the versions.

#### Output on stdout

* One version per line, oldest first.

### ruby::version::latest

Write the newest stable Ruby version that rbenv can install.

#### Example

```bash
ruby::version::latest
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **1**: No stable version was found.
* **64**: An argument was given.

#### Output on stdout

* The newest version, such as 3.3.5.

### ruby::install

Install rbenv, configure the shell, and install a Ruby version globally.

#### Example

```bash
ruby::install 3.4.7
ruby --version
```

#### Arguments

* **$1** (string): Optional Ruby version such as 3.4.7. Defaults to ruby::version::latest.

#### Exit codes

* **0**: Ruby is installed and selected with rbenv global.
* **64**: The version is not major.minor.patch.
* **69**: rbenv is unavailable after installation.
* other The status of the package manager, git, or rbenv install.

