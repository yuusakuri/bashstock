# jdk

JDK installation and versions.

## Overview

The JDK is installed from the platform package source.

## Index

* [jdk::version::list](#jdkversionlist)
* [jdk::version::latest](#jdkversionlatest)
* [jdk::install](#jdkinstall)

### jdk::version::list

Write JDK feature release numbers available to the current platform.

#### Example

```bash
jdk::version::list
```

_Function has no arguments._

#### Exit codes

* **0**: The numbers were written.
* **64**: An argument was given.
* **69**: The platform is unsupported, or the package tool is missing.
* **74**: The package list could not be read.

#### Output on stdout

* JDK feature release numbers such as 17 and 21, one per line, oldest first.

### jdk::version::latest

Write the newest JDK feature release number available to the current platform.

#### Example

```bash
jdk::install "$(jdk::version::latest)"
```

_Function has no arguments._

#### Exit codes

* **0**: The number was written.
* **1**: No JDK is available.
* **64**: An argument was given.
* **69**: The platform is unsupported, or the package tool is missing.

#### Output on stdout

* The newest JDK feature release number.

### jdk::install

Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH.

#### Example

```bash
jdk::install 21
java -version
```

#### Arguments

* **$1** (string): Optional feature release number such as 21. Defaults to jdk::version::latest.

#### Exit codes

* **0**: The JDK is installed and JAVA_HOME and PATH point to it.
* **64**: The version is not a number.
* **69**: The platform is unsupported, or the version is unavailable.
* **74**: java is missing from the selected JDK.
* other The status of the package manager or the alternatives tool.

