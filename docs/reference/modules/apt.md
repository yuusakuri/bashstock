# apt

APT package versions and Debian package installation.

## Overview

Versions come from apt-cache policy; Debian packages are downloaded over HTTPS and installed with their dependencies.

## Index

* [apt::package::candidates](#aptpackagecandidates)
* [apt::package::latest](#aptpackagelatest)
* [apt::deb::install-from-url](#aptdebinstall-from-url)

### apt::package::candidates

Write APT packages whose names start with PREFIX followed by a digit, with candidate versions.

Each line contains a package name and its candidate version separated by a tab.

#### Example

```bash
apt::package::candidates gcc-
# gcc-12	12.3.0-1ubuntu1~22.04
```

#### Arguments

* **$1** (string): Package name prefix, such as openjdk- or libstdc++-.

#### Exit codes

* **0**: The candidates were written; none is not an error.
* **64**: The prefix is not a valid package name start.
* **69**: The system is not Ubuntu, or apt-cache or Python 3 is missing.
* **74**: apt-cache policy failed.

#### Output on stdout

* Lines of package name and candidate version separated by a tab, ordered by version.

### apt::package::latest

Write the APT package name with the newest version suffix after PREFIX.

#### Example

```bash
package::_install "$(apt::package::latest gcc-)"
```

#### Arguments

* **$1** (string): Package name prefix followed by a version number in the package names.

#### Exit codes

* **0**: The name was written.
* **1**: No package name starts with the prefix and a digit.
* **64**: The prefix is invalid.
* **69**: The system is not Ubuntu, or apt-cache or Python 3 is missing.
* **74**: apt-cache policy failed.

#### Output on stdout

* The package name with the newest version, such as gcc-14.

### apt::deb::install-from-url

Download a Debian package and install it with its dependencies through APT.

#### Example

```bash
apt::deb::install-from-url https://example.com/tool_1.2.3_amd64.deb
```

#### Arguments

* **$1** (string): HTTPS URL of the Debian package.
* **$2** (string): Optional accepted architecture. Defaults to the system architecture; packages for all architectures are also accepted.

#### Exit codes

* **0**: The package and its dependencies are installed.
* **64**: The URL is not HTTPS, or the argument count is wrong.
* **65**: The package is for another architecture or is not a valid Debian package.
* **69**: The system is not Ubuntu, or curl, dpkg, or apt-get is missing.
* **74**: The download failed.
* other The status of apt-get.

