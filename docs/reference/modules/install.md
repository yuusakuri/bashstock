# install

Installers for development tools and desktop applications.

## Overview

Most installers accept an optional version; each function documents its default.

## Index

* [deb::install-from-url](#debinstall-from-url)
* [apt::package::candidates](#aptpackagecandidates)
* [apt::package::latest](#aptpackagelatest)
* [chrome::profile::export-user-data-by-email](#chromeprofileexport-user-data-by-email)
* [aws-vpn-client::log::files](#aws-vpn-clientlogfiles)
* [aws-vpn-client::log::clear](#aws-vpn-clientlogclear)
* [aws-vpn-client::log::open](#aws-vpn-clientlogopen)
* [node::versions](#nodeversions)
* [node::install](#nodeinstall)
* [docker::versions](#dockerversions)
* [docker::install](#dockerinstall)
* [colima::versions](#colimaversions)
* [colima::install](#colimainstall)
* [ruby::install](#rubyinstall)
* [jdk::version::list](#jdkversionlist)
* [jdk::version::latest](#jdkversionlatest)
* [jdk::install](#jdkinstall)
* [pipx::versions](#pipxversions)
* [pipx::install](#pipxinstall)
* [vscode::set-default-app](#vscodeset-default-app)
* [iina::set-default-app](#iinaset-default-app)
* [utm::versions](#utmversions)
* [utm::install](#utminstall)
* [ubuntu::server-iso-versions](#ubuntuserver-iso-versions)
* [ubuntu::download-server-iso](#ubuntudownload-server-iso)
* [rancher-desktop::versions](#rancher-desktopversions)
* [rancher-desktop::install](#rancher-desktopinstall)
* [key-binding::disable-option-t](#key-bindingdisable-option-t)
* [pass::versions](#passversions)
* [pass::install](#passinstall)
* [plantuml::versions](#plantumlversions)
* [plantuml::install](#plantumlinstall)
* [graphviz::versions](#graphvizversions)
* [graphviz::install](#graphvizinstall)
* [flutter::versions](#flutterversions)
* [flutter::dependencies::install](#flutterdependenciesinstall)
* [flutter::install](#flutterinstall)
* [vlc::set-default-app](#vlcset-default-app)
* [mozc::server::versions](#mozcserverversions)
* [mozc::server::install](#mozcserverinstall)
* [mozc::ibus::versions](#mozcibusversions)
* [mozc::ibus::install](#mozcibusinstall)
* [mozc::tool::versions](#mozctoolversions)
* [mozc::tool::install](#mozctoolinstall)
* [ssh-server::versions](#ssh-serverversions)
* [ssh-server::install](#ssh-serverinstall)
* [vscode::versions](#vscodeversions)
* [vscode::install](#vscodeinstall)
* [gh::install](#ghinstall)
* [brave::versions](#braveversions)
* [brave::install](#braveinstall)
* [chrome::versions](#chromeversions)
* [chrome::install](#chromeinstall)
* [claude-desktop::install](#claude-desktopinstall)
* [claude-code::install](#claude-codeinstall)
* [codex::install](#codexinstall)
* [chatgpt::install](#chatgptinstall)
* [gimp::versions](#gimpversions)
* [gimp::install](#gimpinstall)
* [gimp::gmic::versions](#gimpgmicversions)
* [gimp::gmic::install](#gimpgmicinstall)
* [microsoft-edge::versions](#microsoft-edgeversions)
* [microsoft-edge::install](#microsoft-edgeinstall)
* [xcode::command-line-tools::upgrade](#xcodecommand-line-toolsupgrade)
* [qmk::toolbox::install](#qmktoolboxinstall)
* [qmk::cli::install](#qmkcliinstall)
* [supabase::versions](#supabaseversions)
* [supabase::install](#supabaseinstall)

### deb::install-from-url

Download a Debian package and install it with its dependencies through APT.

#### Example

```bash
deb::install-from-url https://example.com/tool_1.2.3_amd64.deb
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
* **69**: The system is not Ubuntu, or apt-cache or Perl is missing.
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
* **69**: The system is not Ubuntu, or apt-cache or Perl is missing.
* **74**: apt-cache policy failed.

#### Output on stdout

* The package name with the newest version, such as gcc-14.

### chrome::profile::export-user-data-by-email

Export Chrome Preferences and Bookmarks for profiles whose email matches literally.

#### Example

```bash
chrome::profile::export-user-data-by-email alice@example.com "${HOME}/chrome-backup"
```

#### Arguments

* **$1** (string): Email address of the Chrome profile, compared literally.
* **$2** (string): Optional destination directory. Defaults to the current directory.

#### Exit codes

* **0**: Preferences and Bookmarks of every matching profile were copied as PROFILE_preferences.json and PROFILE_bookmarks.json.
* **1**: No profile has that email address.
* **64**: The email address is empty, or the argument count is wrong.
* **66**: Chrome's user data directory does not exist.
* **74**: The destination could not be created or a file could not be copied.

### aws-vpn-client::log::files

Write AWS VPN Client log files as NUL-separated paths.

Files whose names contain aws_vpn_client_ and do not contain
ovpn_aws_vpn_client are selected, as in the reference script.

#### Example

```bash
aws-vpn-client::log::files | xargs -0 tail -n 50
```

#### Arguments

* **$1** (string): Optional log directory. Defaults to the AWS VPN Client log directory of this OS.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: find is unavailable.

#### Output on stdout

* NUL-separated paths of the log files.

### aws-vpn-client::log::clear

Remove regular log files below the AWS VPN Client log directory.

#### Example

```bash
aws-vpn-client::log::clear
```

#### Arguments

* **$1** (string): Optional log directory. Defaults to the AWS VPN Client log directory of this OS.

#### Exit codes

* **0**: Every regular file below the directory was removed.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: find is unavailable.
* **74**: A file could not be removed.

### aws-vpn-client::log::open

Open log files with an editor command, passing each path as one argument.

#### Example

```bash
files=()
while IFS= read -r -d '' file; do files+=("${file}"); done < <(aws-vpn-client::log::files)
aws-vpn-client::log::open code "${files[@]}"
```

#### Arguments

* **$1** (string): Editor command, such as code.
* **...** (string): Log files; at least one.

#### Exit codes

* **0**: The editor was started.
* **64**: The editor is empty, or no file was given.
* **66**: A path is not a regular file.
* **69**: The editor command is unavailable.
* other The status of the editor.

### node::versions

Write complete stable Node.js versions from the selected source.

#### Example

```bash
node::versions official | tail -n 3
```

#### Arguments

* **$1** (string): Optional source: os for the system package manager (default) or official for nodejs.org.

#### Exit codes

* **0**: The versions were written.
* **64**: The source is not os or official.
* **69**: The platform is unsupported, or Perl is missing for the official source.
* **74**: The release index could not be downloaded or read.

#### Output on stdout

* Complete versions such as 22.11.0, one per line, oldest first.

### node::install

Install Node.js, enable Corepack, and set the pnpm store directory.

Corepack is enabled with pnpm 8.15.9, installing Corepack through npm when the Node.js release no longer bundles it.

#### Example

```bash
node::install 22.11.0 official
pnpm --version
```

#### Arguments

* **$1** (string): Optional complete version from node::versions. Defaults to the newest stable version of the source.
* **$2** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: Node.js, Corepack, and pnpm are ready.
* **64**: The version or source is malformed.
* **69**: The version is unavailable from the source, or older than 16.14.
* **74**: The official archive could not be downloaded or unpacked.
* other The status of the package manager, npm, or Corepack.

#### Output on stderr

* A message when the version is unavailable or too old for Corepack.

### docker::versions

Write Docker Engine or Docker CLI versions available to the current platform.

#### Example

```bash
docker::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported, or Docker publishes nothing for this release.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Docker Engine versions on Linux, or Docker CLI versions from Homebrew on macOS, one per line.

### docker::install

Install the Docker CLI, and Docker Engine on Linux.

On macOS, Colima or Rancher Desktop must already be installed and running.
On Ubuntu and Fedora, the official Docker repository is registered and the
docker service is enabled and started.

#### Example

```bash
docker::install
docker run --rm hello-world
```

#### Arguments

* **$1** (string): Optional version from docker::versions. Defaults to the newest stable version.

#### Exit codes

* **0**: Docker is installed, and on Linux the service is enabled and running.
* **64**: The argument count is wrong.
* **69**: The platform or version is unsupported, or on macOS neither Colima nor Rancher Desktop is running.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager or systemctl.

#### Output on stderr

* A message on macOS when no container runtime is running.

### colima::versions

Write Colima versions available from Homebrew.

#### Example

```bash
colima::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of brew.

#### Output on stdout

* Colima versions from Homebrew, one per line.

### colima::install

Install Colima with Homebrew on macOS and start it.

Colima's Docker runtime needs the docker command before it starts, so the
Docker CLI formula is installed with it. Without Hypervisor.framework, as in
a virtual machine without nested virtualization, the VM cannot boot, so the
function returns 69 instead of starting it.

#### Example

```bash
colima::install
docker::install
```

#### Arguments

* **$1** (string): Optional Colima version; only the current Homebrew version is accepted.

#### Exit codes

* **0**: Colima is installed and running.
* **64**: The argument count is wrong.
* **69**: The system is not macOS, the version is not the current one, or Hypervisor.framework is unavailable.
* other The status of brew or colima start.

#### Output on stderr

* A message when Hypervisor.framework is unavailable.

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

### pipx::versions

Write pipx versions available from the selected source.

The official source lists the PyPI releases that the installed Python 3
can run.

#### Example

```bash
pipx::versions official | tail -n 1
```

#### Arguments

* **$1** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: The versions were written.
* **64**: The source is not os or official.
* **69**: Python 3 is missing for the official source.
* **74**: The PyPI index could not be downloaded or read.

#### Output on stdout

* pipx versions, one per line, oldest first.

### pipx::install

Install pipx and add the pipx application directory to PATH.

The os source installs the package of the system package manager. The
official source installs the release from PyPI for the current user with
pip, as the pipx documentation describes for systems without a package.
A source that cannot provide pipx returns an error instead of switching to
the other source. On Ubuntu, python3-venv is installed with either source,
because pipx creates a virtual environment for every application.

#### Example

```bash
pipx::install
pipx install pycowsay
```

#### Arguments

* **$1** (string): Optional version from pipx::versions for the same source.
* **$2** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: pipx is installed and ~/.local/bin is on PATH.
* **64**: The source is not os or official.
* **69**: The source cannot provide pipx, or the installed version differs.
* **74**: The application directory could not be created.
* other The status of the package manager or pip.

#### Output on stderr

* A message when the source cannot provide pipx.

### vscode::set-default-app

Set VS Code as the default application for text and source file types on macOS.

Extensions and UTIs that this macOS does not declare are reported and
skipped; any other failure returns its status.

#### Example

```bash
vscode::set-default-app
```

_Function has no arguments._

#### Exit codes

* **0**: VS Code opens the listed types.
* **64**: An argument was given.
* **69**: The system is not macOS, or duti is unavailable.
* other The status of duti.

#### Output on stderr

* Each skipped extension or UTI.

### iina::set-default-app

Set IINA as the default application for video file extensions on macOS.

duti is installed with Homebrew when it is missing.

#### Example

```bash
iina::set-default-app
```

_Function has no arguments._

#### Exit codes

* **0**: IINA opens the listed video types.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of brew or duti.

### utm::versions

Write UTM release versions.

#### Example

```bash
utm::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: Perl is unavailable.
* **74**: The GitHub release list could not be downloaded or read.

#### Output on stdout

* Stable UTM release versions, one per line, oldest first.

### utm::install

Install UTM from its release disk image on macOS.

#### Example

```bash
utm::install 4.6.4
```

#### Arguments

* **$1** (string): Optional UTM release version. Defaults to the newest stable release.
* **$2** (string): Optional destination directory. Defaults to /Applications.

#### Exit codes

* **0**: UTM.app was copied to the destination.
* **64**: The argument count is wrong.
* **66**: The destination directory does not exist.
* **69**: The system is not macOS, or hdiutil is unavailable.
* **74**: The disk image could not be downloaded, mounted, or copied.

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

### rancher-desktop::versions

Write Rancher Desktop versions available to the current platform.

#### Example

```bash
rancher-desktop::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Rancher Desktop versions, one per line.

### rancher-desktop::install

Install Rancher Desktop and start it.

Rosetta and Colima are installed separately with rosetta::install and colima::install.

#### Example

```bash
rancher-desktop::install
```

#### Arguments

* **$1** (string): Optional version from rancher-desktop::versions; on macOS only the current version.

#### Exit codes

* **0**: Rancher Desktop is installed and was started.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

#### Output on stderr

* On Linux, a reminder to log in again when the user was added to the kvm group.

### key-binding::disable-option-t

Disable the Option+T key binding on macOS.

#### Example

```bash
key-binding::disable-option-t
```

_Function has no arguments._

#### Exit codes

* **0**: Option+T no longer types a character.
* **64**: An argument was given.
* **65**: The existing DefaultKeyBinding.dict is not a valid property list.
* **69**: The system is not macOS, or plutil is unavailable.
* **74**: The property list could not be written.

### pass::versions

Write pass versions available to the current platform.

#### Example

```bash
pass::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* pass versions from the platform package manager, one per line.

### pass::install

Install pass from the platform package manager.

#### Example

```bash
pass::install
pass init "$(gpg::secret-key::fingerprints | head -n 1)"
```

#### Arguments

* **$1** (string): Optional version from pass::versions. Defaults to the newest one.

#### Exit codes

* **0**: pass is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### plantuml::versions

Write PlantUML versions available to the current platform.

#### Example

```bash
plantuml::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* PlantUML versions from the platform package manager, one per line.

### plantuml::install

Install PlantUML from the platform package manager.

#### Example

```bash
plantuml::install
plantuml -tsvg diagram.puml
```

#### Arguments

* **$1** (string): Optional version from plantuml::versions. Defaults to the newest one.

#### Exit codes

* **0**: PlantUML is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### graphviz::versions

Write Graphviz versions available to the current platform.

#### Example

```bash
graphviz::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Graphviz versions from the platform package manager, one per line.

### graphviz::install

Install Graphviz from the platform package manager.

#### Example

```bash
graphviz::install
dot -Tpng graph.dot -o graph.png
```

#### Arguments

* **$1** (string): Optional version from graphviz::versions. Defaults to the newest one.

#### Exit codes

* **0**: Graphviz is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

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

### vlc::set-default-app

Set VLC as the default application for every MIME type it declares.

#### Example

```bash
vlc::set-default-app
xdg-mime query default video/mp4
```

_Function has no arguments._

#### Exit codes

* **0**: VLC opens every MIME type it declares.
* **64**: An argument was given.
* **66**: VLC's desktop file was not found or declares no MIME type.
* **69**: xdg-mime is unavailable.
* other The status of xdg-mime.

### mozc::server::versions

Write Mozc server versions provided for the running operating-system release.

#### Example

```bash
mozc::server::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Mozc server package versions, one per line.

### mozc::server::install

Install the Mozc server, defaulting to the newest version for the running release.

#### Example

```bash
mozc::server::install
```

#### Arguments

* **$1** (string): Optional version from mozc::server::versions. Defaults to the newest one.

#### Exit codes

* **0**: The Mozc server is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc::ibus::versions

Write IBus Mozc versions provided for the running operating-system release.

#### Example

```bash
mozc::ibus::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* IBus Mozc package versions, one per line.

### mozc::ibus::install

Install IBus Mozc and the Mozc server of the same version.

#### Example

```bash
mozc::ibus::install
```

#### Arguments

* **$1** (string): Optional version from mozc::ibus::versions. Defaults to the newest one.

#### Exit codes

* **0**: IBus Mozc, and the server of the same version when provided, are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### mozc::tool::versions

Write Mozc GUI tool versions provided for the running operating-system release.

#### Example

```bash
mozc::tool::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* Mozc GUI tool package versions, one per line.

### mozc::tool::install

Install the Mozc GUI tools.

#### Example

```bash
mozc::tool::install
mozc::config::open
```

#### Arguments

* **$1** (string): Optional version from mozc::tool::versions. Defaults to the newest one.

#### Exit codes

* **0**: The Mozc GUI tools are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager.

### ssh-server::versions

Write OpenSSH server versions available to the current platform.

#### Example

```bash
ssh-server::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* OpenSSH server package versions, one per line.

### ssh-server::install

Install the OpenSSH server, enable it at boot, and start it.

#### Example

```bash
ssh-server::install
```

#### Arguments

* **$1** (string): Optional version from ssh-server::versions. Defaults to the newest one.

#### Exit codes

* **0**: The server is installed, enabled at boot, and running.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable.
* other The status of the package manager or systemctl.

### vscode::versions

Write VS Code versions available to the current platform.

#### Example

```bash
vscode::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* VS Code versions, one per line; on Ubuntu only builds that the installed C library can run.

### vscode::install

Install VS Code from the Microsoft repository or Homebrew.

On Ubuntu, a version is accepted only when the installed C library can run it,
and an omitted version selects the newest such build.

#### Example

```bash
vscode::install
code --version
```

#### Arguments

* **$1** (string): Optional version from vscode::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: VS Code is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable or cannot run here.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

### gh::install

Install GitHub CLI from its official Ubuntu APT repository.

The downloaded keyring must contain both fingerprints published by GitHub.
The keyring is installed in /etc/apt/keyrings and referenced from a deb822
source file before APT indexes are refreshed and gh is installed.

#### Example

```bash
gh::install
```

_Function has no arguments._

#### Exit codes

* **0**: GitHub CLI is installed.
* **64**: An argument was given.
* **65**: The downloaded signing key does not match GitHub's fingerprints.
* **69**: The system is not Ubuntu, or gpg is missing.
* **74**: The key download or repository configuration failed.
* **77**: sudo refused the credentials.
* other The status of APT.

### brave::versions

Write Brave versions available to the current platform.

#### Example

```bash
brave::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Brave versions, one per line; on Ubuntu only builds that the installed C library can run.

### brave::install

Install Brave from its official repository or Homebrew.

On Ubuntu, a version is accepted only when the installed C library can run it,
and an omitted version selects the newest such build.

#### Example

```bash
brave::install
```

#### Arguments

* **$1** (string): Optional version from brave::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: Brave is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable or cannot run here.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

### chrome::versions

Write Google Chrome versions available to the current platform.

#### Example

```bash
chrome::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Google Chrome versions, one per line; on Ubuntu only builds that the installed C library can run.

### chrome::install

Install Google Chrome from the Google repository or Homebrew.

On Ubuntu, a version is accepted only when the installed C library can run it,
and an omitted version selects the newest such build.

#### Example

```bash
chrome::install
```

#### Arguments

* **$1** (string): Optional version from chrome::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: Google Chrome is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable or cannot run here.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

### claude-desktop::install

Install the newest Claude Desktop, the app that also runs Claude Code sessions.

macOS installs the Homebrew cask claude, which updates itself. Ubuntu 22.04
or later installs from Anthropic's APT repository, and later releases
arrive through the system's regular APT upgrades. Anthropic does not
publish Claude Desktop for Fedora; use claude-code::install there.

#### Example

```bash
claude-desktop::install
```

_Function has no arguments._

#### Exit codes

* **0**: Claude Desktop is installed.
* **64**: An argument was given.
* **65**: The downloaded signing key is not Anthropic's published key.
* **69**: The system is neither macOS nor Ubuntu 22.04 or later, or the CPU is unsupported.
* **74**: The repository key could not be downloaded.
* other The status of the package manager.

### claude-code::install

Install the newest Claude Code CLI.

macOS installs the Homebrew cask claude-code. Ubuntu 20.04 or later and
Fedora install from Anthropic's signed stable repository, so later
releases arrive with the system's package upgrades. Signing in is left to
the first run of claude.

#### Example

```bash
claude-code::install && claude --version
```

_Function has no arguments._

#### Exit codes

* **0**: Claude Code is installed.
* **64**: An argument was given.
* **65**: The downloaded signing key is not Anthropic's published key.
* **69**: The platform is unsupported, Ubuntu is older than 20.04, or the CPU is unsupported.
* **74**: The repository key could not be downloaded.
* other The status of the package manager.

### codex::install

Install the newest OpenAI Codex CLI.

macOS installs the Homebrew cask codex. Linux runs OpenAI's standalone
installer, which verifies the release checksum, installs the static musl
build into $HOME/.local, and keeps it updated. $HOME/.local/bin is added
to PATH through env::add-path, so the installer leaves the shell startup
files alone. Signing in is left to the first run of codex.

#### Example

```bash
codex::install && codex --version
```

_Function has no arguments._

#### Exit codes

* **0**: Codex is installed.
* **64**: An argument was given.
* **69**: The platform or CPU is unsupported, or tar is missing.
* **74**: The installer could not be downloaded or $HOME/.local/bin could not be created.
* other The status of the installer or of Homebrew.

#### Output on stdout

* The installer's progress and the installed version.

### chatgpt::install

Install the newest ChatGPT desktop app, which also runs Codex.

macOS installs the Homebrew cask chatgpt. Ubuntu 24.04 or later and
Fedora 43 or later install OpenAI's newest package, which registers
OpenAI's signed repository so later releases arrive with the system's
package upgrades.

#### Example

```bash
chatgpt::install
```

_Function has no arguments._

#### Exit codes

* **0**: The ChatGPT desktop app is installed.
* **64**: An argument was given.
* **65**: The downloaded package is for another CPU or is not a valid package.
* **69**: The platform, release, or CPU is unsupported.
* **74**: The package could not be downloaded.
* other The status of the package manager.

### gimp::versions

Write GIMP versions available to the current platform.

#### Example

```bash
gimp::versions
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.

#### Output on stdout

* GIMP versions, one per line.

### gimp::install

Install GIMP, and on Linux the G'MIC plugin from the selected source.

#### Example

```bash
gimp::install '' official
```

#### Arguments

* **$1** (string): Optional GIMP version from gimp::versions; on macOS only the current version.
* **$2** (string): Optional G'MIC source on Linux: os (default) or official; see gimp::gmic::install.

#### Exit codes

* **0**: GIMP, and on Linux the G'MIC plugin, are installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, the version is unavailable, or the G'MIC source cannot provide the plugin.
* other The status of the package manager.

### gimp::gmic::versions

Write G'MIC GIMP plugin versions available from the selected source.

#### Example

```bash
gimp::gmic::versions official
```

#### Arguments

* **$1** (string): Optional source: os (default) or official.

#### Exit codes

* **0**: The versions were written.
* **64**: The source is not os or official.
* **69**: The platform or CPU is unsupported by the source.
* **74**: The official package list could not be downloaded.

#### Output on stdout

* G'MIC plugin versions, one per line.

### gimp::gmic::install

Install the G'MIC GIMP plugin.

The os source installs the plugin package of the system package manager.
Ubuntu 26.04 ships GIMP 3 without one, so the official source installs the
G'MIC project's package for the running Ubuntu release, which contains the
GIMP 3 plugin. A source that cannot provide the plugin returns 69 instead
of switching to the other source.

#### Example

```bash
gimp::gmic::install '' official
```

#### Arguments

* **$1** (string): Optional version from gimp::gmic::versions for the same source.
* **$2** (string): Optional source: os (default) or official. The official source supports Ubuntu on amd64, the only CPU the G'MIC project builds packages for.

#### Exit codes

* **0**: The G'MIC plugin is installed.
* **64**: The source is not os or official.
* **69**: The source cannot provide the plugin for this system, or the version is unavailable.
* **74**: The official package could not be downloaded.
* other The status of the package manager.

#### Output on stderr

* A message when the source cannot provide the plugin.

### microsoft-edge::versions

Write Microsoft Edge versions available to the current platform.

#### Example

```bash
microsoft-edge::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform or CPU is unsupported.
* **74**: The vendor metadata could not be downloaded.

#### Output on stdout

* Microsoft Edge versions, one per line; on Linux only builds for this CPU, and on Ubuntu only builds the C library can run.

### microsoft-edge::install

Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew.

On Linux, a version is accepted only when Microsoft publishes it for the
running CPU, and on Ubuntu only when the installed C library can run it.
Microsoft builds Edge for Linux on amd64 only, so arm64 returns 69.

#### Example

```bash
microsoft-edge::install
```

#### Arguments

* **$1** (string): Optional version from microsoft-edge::versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: Microsoft Edge is installed.
* **64**: The argument count is wrong.
* **69**: The platform or CPU is unsupported, or the version is unavailable.
* **74**: The package or repository could not be downloaded.
* other The status of the package manager.

### xcode::command-line-tools::upgrade

Update Xcode Command Line Tools without removing the installed tools.

When softwareupdate offers no Command Line Tools update, nothing changes.

#### Example

```bash
xcode::command-line-tools::upgrade
clang --version
```

_Function has no arguments._

#### Exit codes

* **0**: The tools were updated, or no update is available.
* **64**: An argument was given.
* **69**: The system is not macOS, or softwareupdate or xcode-select is unavailable.
* **74**: softwareupdate could not list updates, or xcode-select finds no tools after the update.
* other The status of softwareupdate or pkgutil.

#### Output on stdout

* The package information of the updated tools.

#### Output on stderr

* A message when no update is available.

### qmk::toolbox::install

Install QMK Toolbox with Homebrew on macOS.

#### Example

```bash
qmk::toolbox::install
```

#### Arguments

* **$1** (string): Optional QMK Toolbox version; only the current Homebrew version is accepted.

#### Exit codes

* **0**: QMK Toolbox is installed.
* **64**: The argument count is wrong.
* **69**: The system is not macOS, or the version is not the current one.
* other The status of brew.

### qmk::cli::install

Install the QMK CLI with the official installer and diagnose the environment.

`qmk --version` always confirms the installation. The CLI offers
`qmk doctor` only after `qmk setup` has prepared the firmware tree, so the
diagnosis also runs when that tree exists. Warnings from the diagnosis are
reported without failing; errors return its status.

#### Example

```bash
qmk::cli::install
qmk setup -y
```

#### Arguments

* **$1** (string): Optional QMK CLI version; only the newest stable version from PyPI is accepted.

#### Exit codes

* **0**: The QMK CLI is installed and starts; doctor found at most warnings.
* **64**: The argument count is wrong.
* **69**: The version is not the newest one, or sh is unavailable.
* **74**: The installer could not be downloaded.
* other The status of the installer, qmk --version, or qmk doctor.

#### Output on stdout

* The output of qmk --version, and of qmk doctor when the firmware tree exists.

### supabase::versions

Write Supabase CLI versions available to the current platform.

#### Example

```bash
supabase::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported, or Perl is missing.
* **74**: The release list could not be downloaded.

#### Output on stdout

* Supabase CLI versions, one per line.

### supabase::install

Install the Supabase CLI from its Homebrew tap or release packages.

#### Example

```bash
supabase::install
supabase --version
```

#### Arguments

* **$1** (string): Optional version from supabase::versions; on macOS only the current tap version. Defaults to the newest one.

#### Exit codes

* **0**: The Supabase CLI is installed.
* **64**: The argument count is wrong.
* **69**: The platform or CPU is unsupported, or the version is unavailable.
* **74**: The release package could not be downloaded.
* other The status of brew or the package manager.

