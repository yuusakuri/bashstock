# android

Android SDK and command-line tool installation.

## Overview

The SDK directory is ANDROID_HOME, then ANDROID_SDK_ROOT, then the Android Studio default.

## Index

* [android::sdk::directory](#androidsdkdirectory)
* [android::cli::install](#androidcliinstall)
* [android::sdk::install](#androidsdkinstall)
* [android::platform-tools::install](#androidplatform-toolsinstall)
* [android::sdk-platform::install](#androidsdk-platforminstall)
* [android::build-tools::install](#androidbuild-toolsinstall)
* [android::emulator::install](#androidemulatorinstall)
* [android::command-line-tools::install](#androidcommand-line-toolsinstall)

### android::sdk::directory

Write the SDK directory selected by Android Studio or the caller.

ANDROID_HOME wins, then ANDROID_SDK_ROOT, then Android Studio's default:
~/Library/Android/sdk on macOS and ~/Android/Sdk on Linux.

#### Example

```bash
ls "$(android::sdk::directory)/platforms"
```

_Function has no arguments._

#### Exit codes

* **0**: The directory was written.
* **64**: An argument was given, or ANDROID_HOME and ANDROID_SDK_ROOT name different SDKs.

#### Output on stdout

* The SDK directory, which may not exist yet.

#### Output on stderr

* A message when ANDROID_HOME and ANDROID_SDK_ROOT differ.

### android::cli::install

Install the official Android CLI without replacing a working copy on failure.

The CLI is downloaded to a temporary directory, started once to check its
version, and only then moved to ~/.local/bin/android.

#### Example

```bash
android::cli::install
android --version
```

#### Arguments

* **$1** (string): Optional complete Android CLI version, such as 1.0.16500706. Defaults to the latest.

#### Exit codes

* **0**: The CLI was installed and ~/.local/bin is on PATH.
* **64**: The version is not three dot-separated numbers.
* **69**: Google publishes no CLI for this OS and CPU, or the downloaded CLI does not start or has another version.
* **74**: The download or installation failed.

### android::sdk::install

Create and configure the selected SDK directory and Android CLI.

ANDROID_HOME is written to the Bash and Zsh startup files and the current process.

#### Example

```bash
android::sdk::install "${HOME}/Android/Sdk"
```

#### Arguments

* **$1** (string): Optional absolute SDK directory. Defaults to android::sdk::directory.
* **$2** (string): Optional complete Android CLI version. Defaults to the latest.

#### Exit codes

* **0**: The SDK directory and CLI are ready.
* **64**: The directory is not absolute or differs from ANDROID_HOME or ANDROID_SDK_ROOT.
* **69**: The Android CLI is unavailable for this OS and CPU.
* **74**: The directory could not be created or the CLI could not be installed.

### android::platform-tools::install

Install Android Platform Tools and add adb and fastboot to PATH.

The SDK license is accepted automatically.

#### Example

```bash
android::platform-tools::install
adb devices
```

#### Arguments

* **$1** (string): Optional package revision, such as 36.0.0. Defaults to the latest stable one.

#### Exit codes

* **0**: adb and fastboot are installed and on PATH.
* **64**: The revision is malformed.
* **69**: The Android CLI is unavailable, or adb or fastboot is missing after installation.
* other The status of the Android CLI.

### android::sdk-platform::install

Install an Android SDK Platform and verify its android.jar file.

#### Example

```bash
android::sdk-platform::install 35
```

#### Arguments

* **$1** (integer): Android API level, such as 35.
* **$2** (string): Optional package revision. Defaults to the latest stable one.

#### Exit codes

* **0**: The platform is installed.
* **64**: The API level or revision is malformed.
* **69**: The Android CLI is unavailable, or android.jar is missing after installation.
* other The status of the Android CLI.

### android::build-tools::install

Install one stable Build Tools version and add its executables to PATH.

#### Example

```bash
android::build-tools::install 35.0.0
aapt2 version
```

#### Arguments

* **$1** (string): Optional Build Tools version, such as 35.0.0. Defaults to the latest stable one.
* **$2** (string): Optional package revision. Defaults to the version's latest revision.

#### Exit codes

* **0**: Build Tools are installed and on PATH.
* **64**: The version or revision is malformed.
* **69**: The Android CLI is unavailable, or aapt2 is missing after installation.
* other The status of the Android CLI.

### android::emulator::install

Install the Android Emulator into the selected SDK.

On Linux, the system libraries that the emulator and its bundled libraries
load, including libX11-xcb that it opens at run time, are installed first.
Current emulators need glibc 2.30 or later, so Ubuntu 18.04 returns 69.

#### Example

```bash
android::emulator::install
```

#### Arguments

* **$1** (string): Optional package revision. Defaults to the latest stable one.

#### Exit codes

* **0**: The emulator is installed and starts.
* **64**: The revision is malformed.
* **69**: The Android CLI is unavailable for this OS and CPU, or the emulator does not start.
* other The status of the package manager or the Android CLI.

#### Output on stderr

* A message when the installed emulator does not start.

### android::command-line-tools::install

Install SDK Command-line Tools and verify sdkmanager and avdmanager.

#### Example

```bash
android::command-line-tools::install
avdmanager list device -c
```

#### Arguments

* **$1** (string): Optional package revision. Defaults to the latest stable one.

#### Exit codes

* **0**: sdkmanager and avdmanager are installed and on PATH.
* **64**: The revision is malformed.
* **69**: The Android CLI is unavailable, or a tool is missing after installation.
* other The status of the Android CLI.

