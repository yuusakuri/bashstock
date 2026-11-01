# flutter

Flutter SDK installation and projects.

## Overview

The SDK is installed from the official Flutter releases.

## Index

* [flutter::run-chrome-release](#flutterrun-chrome-release)
* [flutter::run-linux-release](#flutterrun-linux-release)
* [flutter::test](#fluttertest)
* [flutter::coverage](#fluttercoverage)
* [flutter::use-version](#flutteruse-version)
* [flutter::versions](#flutterversions)
* [flutter::dependencies::install](#flutterdependenciesinstall)
* [flutter::install](#flutterinstall)

### flutter::run-chrome-release

Run a Flutter project in Chrome in release mode.

#### Example

```bash
flutter::run-chrome-release apps/mobile
```

#### Arguments

* **$1** (string): Optional Flutter project directory. Defaults to the current directory.

#### Exit codes

* **0**: The application ended successfully.
* **64**: More than one argument was given.
* **69**: flutter is unavailable.
* other The status of flutter run or cd.

### flutter::run-linux-release

Run a Flutter project as a Linux desktop application in release mode.

#### Example

```bash
flutter::run-linux-release apps/desktop
```

#### Arguments

* **$1** (string): Optional Flutter project directory. Defaults to the current directory.

#### Exit codes

* **0**: The application ended successfully.
* **64**: More than one argument was given.
* **69**: flutter is unavailable.
* other The status of flutter run or cd.

### flutter::test

Run the Flutter tests of a project with optional flutter test arguments.

#### Example

```bash
flutter::test apps/mobile --name 'login'
```

#### Arguments

* **$1** (string): Optional Flutter project directory, used when it is an existing directory. Defaults to the current directory.
* **...** (string): Optional arguments of flutter test.

#### Exit codes

* **0**: The tests passed.
* **69**: flutter is unavailable.
* other The status of flutter test or cd.

### flutter::coverage

Run the Flutter tests with coverage and write the LCOV HTML report.

#### Example

```bash
flutter::coverage '' apps/mobile
```

#### Arguments

* **$1** (string): Optional report directory. Defaults to coverage/html below the project directory.
* **$2** (string): Optional Flutter project directory. Defaults to the current directory.

#### Exit codes

* **0**: The tests passed and the report was written.
* **64**: More than two arguments were given.
* **69**: flutter or genhtml is unavailable.
* other The status of flutter test or genhtml.

### flutter::use-version

Keep Flutter SDK changes in a retrievable stash and switch versions.

When the stash fails, changes other than ignored files are discarded before
the switch, as decided for the SDK directory.

#### Example

```bash
flutter::use-version 3.24.3
```

#### Arguments

* **$1** (string): Optional tag to check out. Defaults to the newest stable version.
* **$2** (string): Optional Flutter SDK directory. Defaults to $HOME/.local/flutter.

#### Exit codes

* **0**: The SDK is at the version.
* **64**: More than two arguments were given.
* **66**: The directory is not a Git checkout.
* other The status of the git command that failed.

### flutter::versions

Write stable Flutter SDK versions for the current platform.

#### Example

```bash
flutter::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: Perl is unavailable, or the platform is unsupported.
* **74**: The release index could not be downloaded or read.

#### Output on stdout

* Stable Flutter versions such as 3.35.7, one per line, oldest first.

### flutter::dependencies::install

Install packages required to build Flutter applications.

#### Example

```bash
flutter::dependencies::install
```

_Function has no arguments._

#### Exit codes

* **0**: The build dependencies are installed.
* **64**: An argument was given.
* **69**: The platform is unsupported, or git or curl is missing on macOS.
* **74**: The C++ development package could not be determined.
* other The status of the package manager.

### flutter::install

Install dependencies and select a stable Flutter SDK version.

An existing Flutter repository retains its stash and ignored files.

Limitation: Flutter builds Linux desktop applications on Ubuntu 20.04 and
later only. Ubuntu 18.04 installs the SDK and runs Dart code and tests,
but `flutter build linux` stops there because it needs CMake 3.13 and the
release provides 3.10.

#### Example

```bash
flutter::install 3.35.7
flutter doctor
```

#### Arguments

* **$1** (string): Optional stable Flutter version. Defaults to the newest stable release.
* **$2** (string): Optional SDK directory. Defaults to $HOME/.local/flutter.

#### Exit codes

* **0**: The SDK is at the version and its bin directory is on PATH.
* **64**: The version is not major.minor.patch.
* **69**: The platform is unsupported.
* **73**: The directory is neither empty nor a Flutter SDK.
* other The status of the dependency installation, git, or flutter.

#### Output on stderr

* A message when the directory holds something other than a Flutter SDK.

