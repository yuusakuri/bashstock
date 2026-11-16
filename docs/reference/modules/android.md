# android

Android SDK installation and virtual device control.

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
* [android::avd::list](#androidavdlist)
* [android::avd::profiles](#androidavdprofiles)
* [android::system-images::versions](#androidsystem-imagesversions)
* [android::avd::create](#androidavdcreate)
* [android::avd::port::available](#androidavdportavailable)
* [android::avd::port::first](#androidavdportfirst)
* [android::avd::start](#androidavdstart)
* [android::avd::stop](#androidavdstop)
* [android::avd::delete](#androidavddelete)
* [android::build-tools::versions](#androidbuild-toolsversions)
* [android::build-tools::latest-version](#androidbuild-toolslatest-version)

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

sdkmanager and avdmanager run on Java, so a JDK is installed with jdk::install
when neither JAVA_HOME nor PATH provides java.

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
* other The status of the Android CLI or jdk::install.

### android::avd::list

List AVD names in the selected Android SDK environment.

#### Example

```bash
android::avd::list | grep -Fqx pixel_api35 || android::avd::create pixel_api35 35
```

_Function has no arguments._

#### Exit codes

* **0**: The names were written.
* **64**: An argument was given, or the SDK settings conflict.
* **69**: The emulator is not installed.
* other The status of emulator -list-avds.

#### Output on stdout

* One AVD name per line.

### android::avd::profiles

List hardware profiles available to avdmanager.

#### Example

```bash
android::avd::profiles | grep pixel
```

_Function has no arguments._

#### Exit codes

* **0**: The profiles were written.
* **64**: An argument was given, or the SDK settings conflict.
* **69**: Command-line Tools are not installed.
* other The status of avdmanager.

#### Output on stdout

* One profile ID per line, such as medium_phone or pixel_8.

### android::system-images::versions

List stable system images as API, tag, ABI, and revision values.

#### Example

```bash
android::system-images::versions 35 google_apis x86_64
# 35 google_apis x86_64 9
```

#### Arguments

* **$1** (string): Optional API level to keep, such as 35.
* **$2** (string): Optional tag to keep, such as google_apis.
* **$3** (string): Optional ABI to keep, such as arm64-v8a.

#### Exit codes

* **0**: The images were written.
* **64**: A filter is malformed, or the SDK settings conflict.
* **69**: The Android CLI is unavailable.
* other The status of the Android CLI.

#### Output on stdout

* Lines of API, tag, ABI, and revision separated by spaces.

### android::avd::create

Create one AVD from a stable Google APIs image without starting it.

The system image is installed first unless it is already installed. An
existing AVD with the same name is kept unless --replace is given, and then
it is backed up until the new one exists.

#### Example

```bash
android::avd::create pixel_api35 35 pixel_8
android::avd::create pixel_api35 35 pixel_8 google_apis arm64-v8a '' --replace
```

#### Options

* **--replace**

  Replace an existing AVD after keeping a recoverable backup; give it last.

#### Arguments

* **$1** (string): New AVD name: letters, digits, ., _, and -.
* **$2** (integer): Optional Android API level. Defaults to the newest available one.
* **$3** (string): Optional avdmanager profile. Defaults to medium_phone.
* **$4** (string): Optional image tag. Defaults to google_apis.
* **$5** (string): Optional image ABI. Defaults to the host CPU's ABI.
* **$6** (string): Optional image revision. Defaults to the installed one, or to the newest one when the image is not installed. An installed image is never changed, because other AVDs may use it.

#### Exit codes

* **0**: The AVD was created.
* **64**: An argument is malformed.
* **69**: Command-line Tools or the emulator is missing, no image matches, or the installed image has a different revision than the requested one.
* **73**: The AVD exists and --replace was not given, or avdmanager could not create it.
* **74**: The existing AVD could not be backed up or restored.
* other The status of the Android CLI or avdmanager.

### android::avd::port::available

Report whether an even emulator console port and its ADB port are both free.

#### Example

```bash
android::avd::port::available 5556 && android::avd::start pixel_api35 5556
```

#### Arguments

* **$1** (integer): Even console port from 5554 to 5682; the ADB port is the next number.

#### Exit codes

* **0**: Both ports are free.
* **1**: One of the ports is in use.
* **64**: The port is odd or out of range.
* **69**: Neither lsof nor ss is available.
* **74**: ss failed.

### android::avd::port::first

Write the first free emulator console port.

#### Example

```bash
port="$(android::avd::port::first)"
```

_Function has no arguments._

#### Exit codes

* **0**: A free port was written.
* **64**: An argument was given.
* **69**: Neither lsof nor ss is available.
* **75**: Every emulator port is in use.

#### Output on stdout

* An even port from 5554 to 5682.

### android::avd::start

Start one AVD and wait for Android to finish booting.

The function returns when sys.boot_completed is 1. The emulator keeps
running in the background after the function returns. When the boot times
out or the wait is interrupted, only the emulator that this call started is
stopped; the ADB server and other emulators keep running.

#### Example

```bash
serial="$(android::avd::start pixel_api35 '' 300 --headless)"
adb -s "${serial}" install app.apk
```

#### Arguments

* **$1** (string): Optional AVD name. Defaults to the only AVD.
* **$2** (integer): Optional console port. Defaults to the first free one.
* **$3** (integer): Optional boot timeout in seconds. Defaults to 180.
* **$4** (string): Optional --headless to run without a window and audio.

#### Exit codes

* **0**: Android finished booting.
* **1**: The port is in use.
* **64**: An argument is invalid, or no name was given and there is not exactly one AVD.
* **66**: No AVD has that name.
* **69**: The emulator or Platform Tools are not installed.
* **74**: A temporary log could not be created.
* **75**: The emulator exited or Android did not boot before the timeout.
* **130**: The wait was interrupted, and the started emulator was stopped.

#### Output on stdout

* The ADB serial, such as emulator-5554.

#### Output on stderr

* The emulator log when it exits or the boot times out.

### android::avd::stop

Stop the named AVD, or the only running AVD when no name is given.

Only the emulator that reports the AVD name is stopped; the ADB server and
other emulators keep running.

#### Example

```bash
android::avd::stop pixel_api35
```

#### Arguments

* **$1** (string): Optional AVD name. Defaults to the only running AVD.

#### Exit codes

* **0**: The emulator stopped.
* **64**: The name is malformed, or several AVDs match.
* **66**: No running emulator matches.
* **69**: Platform Tools are not installed.
* **74**: The clock could not be read.
* **75**: The emulator refused to stop or did not stop within 60 seconds.

### android::avd::delete

Delete one named AVD without changing other AVDs.

#### Example

```bash
android::avd::delete pixel_api35
```

#### Arguments

* **$1** (string): AVD name.

#### Exit codes

* **0**: The AVD was deleted.
* **64**: The name is malformed, or the argument count is not one.
* **66**: No AVD has that name.
* **69**: Command-line Tools are not installed.
* other The status of avdmanager.

### android::build-tools::versions

Write available stable Android Build Tools versions in ascending order.

Use Android CLI when available, otherwise use sdkmanager.

#### Example

```bash
android::build-tools::versions | tail -n 3
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **1**: No stable version was found.
* **64**: An argument was given.
* **69**: Python 3, or both android and sdkmanager, are unavailable.
* other The status of the SDK command that failed.

#### Output on stdout

* One version per line, oldest first.

### android::build-tools::latest-version

Write the newest available stable Android Build Tools version.

#### Example

```bash
sdkmanager "build-tools;$(android::build-tools::latest-version)"
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **1**: No stable version was found.
* **64**: An argument was given.
* other The status of android::build-tools::versions.

#### Output on stdout

* The newest version, such as 35.0.0.

