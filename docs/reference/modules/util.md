# util

Everyday commands for storage, Git, SSH, Docker, Android devices, debugging, and system settings.

## Overview

Most functions wrap one external command with argument checks and documented exit codes.

## Index

* [prompt::pause](#promptpause)
* [time::sleep-hours](#timesleep-hours)
* [storage::usage](#storageusage)
* [storage::largest-entries](#storagelargest-entries)
* [mem::physical-total-bytes](#memphysical-total-bytes)
* [mem::physical-total-gibibytes](#memphysical-total-gibibytes)
* [mem::swap-total-bytes](#memswap-total-bytes)
* [mem::swap-total-gibibytes](#memswap-total-gibibytes)
* [mem::total-bytes](#memtotal-bytes)
* [mem::total-gibibytes](#memtotal-gibibytes)
* [file::write-text](#filewrite-text)
* [file::find-by-content](#filefind-by-content)
* [file::latest-by-name](#filelatest-by-name)
* [symlink::create](#symlinkcreate)
* [symlink::remove](#symlinkremove)
* [net::interface::default](#netinterfacedefault)
* [net::gateway::default](#netgatewaydefault)
* [net::ip::private-v4](#netipprivate-v4)
* [net::ip::private-v6](#netipprivate-v6)
* [net::ip::public](#netippublic)
* [net::dns::test](#netdnstest)
* [user::add-to-group](#useradd-to-group)
* [system::kernel-name](#systemkernel-name)
* [system::distribution-name](#systemdistribution-name)
* [system::enable-sleep](#systemenable-sleep)
* [system::disable-sleep](#systemdisable-sleep)
* [system::disable-auto-lock](#systemdisable-auto-lock)
* [time::posix-timezone](#timeposix-timezone)
* [directory::merge](#directorymerge)
* [directory::create-with-date-time](#directorycreate-with-date-time)
* [directory::clear](#directoryclear)
* [time::status-continuous](#timestatus-continuous)
* [file::edit](#fileedit)
* [file::release](#filerelease)
* [screen::open](#screenopen)
* [archive::verify](#archiveverify)
* [archive::remove-broken](#archiveremove-broken)
* [archive::extract-file](#archiveextract-file)
* [archive::compress-tar-gzip](#archivecompress-tar-gzip)
* [diff::directories](#diffdirectories)
* [git::clone-shallow](#gitclone-shallow)
* [git::rebase-abort](#gitrebase-abort)
* [git::rebase-continue](#gitrebase-continue)
* [git::commit::amend](#gitcommitamend)
* [git::commit::create](#gitcommitcreate)
* [git::commit::uncommit](#gitcommituncommit)
* [git::branch::current](#gitbranchcurrent)
* [git::branch::create](#gitbranchcreate)
* [git::branch::list](#gitbranchlist)
* [git::diff::files](#gitdifffiles)
* [git::diff::patch](#gitdiffpatch)
* [git::diff::uncommitted-patch](#gitdiffuncommitted-patch)
* [git::diff::uncommitted-files](#gitdiffuncommitted-files)
* [git::diff::latest-patch](#gitdifflatest-patch)
* [git::diff::latest-files](#gitdifflatest-files)
* [git::commit::patch](#gitcommitpatch)
* [git::commit::revert-without-commit](#gitcommitrevert-without-commit)
* [git::commit::revert](#gitcommitrevert)
* [git::fetch](#gitfetch)
* [git::fetch-unshallow](#gitfetch-unshallow)
* [git::stash::patch](#gitstashpatch)
* [git::stash::push](#gitstashpush)
* [git::stash::pop](#gitstashpop)
* [git::stash::drop](#gitstashdrop)
* [git::reset](#gitreset)
* [git::pull-rebase](#gitpull-rebase)
* [git::cherry-pick](#gitcherry-pick)
* [git::cherry-pick-continue](#gitcherry-pick-continue)
* [git::cherry-pick-abort](#gitcherry-pick-abort)
* [git::push](#gitpush)
* [git::push::force-with-lease](#gitpushforce-with-lease)
* [gerrit::push-review](#gerritpush-review)
* [gerrit::push-review-wip](#gerritpush-review-wip)
* [git::remote::delete-branch](#gitremotedelete-branch)
* [git::submodule::update-all](#gitsubmoduleupdate-all)
* [git::commit::discard](#gitcommitdiscard)
* [git::reset-remote](#gitreset-remote)
* [git::pull-base-branch](#gitpull-base-branch)
* [env::dotenv::import](#envdotenvimport)
* [env::set-variable](#envset-variable)
* [env::add-path](#envadd-path)
* [env::dotenv::register](#envdotenvregister)
* [symlink::create-in-local-bin](#symlinkcreate-in-local-bin)
* [ssh::setup-directory](#sshsetup-directory)
* [ssh::config::update](#sshconfigupdate)
* [ssh::config::set](#sshconfigset)
* [ssh::config::enable-auto-add-keys](#sshconfigenable-auto-add-keys)
* [ssh::config::disable-host-key-checking](#sshconfigdisable-host-key-checking)
* [ssh::key::private-files](#sshkeyprivate-files)
* [ssh::key::add](#sshkeyadd)
* [ssh::key::add-all](#sshkeyadd-all)
* [ssh::key::add-all-private-keys](#sshkeyadd-all-private-keys)
* [net::ping](#netping)
* [swap::disable-all](#swapdisable-all)
* [swap::remove-all-files](#swapremove-all-files)
* [swap::create](#swapcreate)
* [swap::list](#swaplist)
* [path::find](#pathfind)
* [file::tree-with-contents](#filetree-with-contents)
* [net::tcp::test](#nettcptest)
* [serial::configure](#serialconfigure)
* [serial::write](#serialwrite)
* [serial::write-command](#serialwrite-command)
* [screen::open-serial](#screenopen-serial)
* [screen::kill-all](#screenkill-all)
* [net::capture-host](#netcapture-host)
* [net::unused-port](#netunused-port)
* [serial::release](#serialrelease)
* [repo::init](#repoinit)
* [repo::sync](#reposync)
* [repo::write-manifest](#repowrite-manifest)
* [repo::check](#repocheck)
* [docker::container::list-running](#dockercontainerlist-running)
* [docker::container::list](#dockercontainerlist)
* [docker::container::pull](#dockercontainerpull)
* [docker::container::push](#dockercontainerpush)
* [docker::container::shell](#dockercontainershell)
* [docker::container::logs](#dockercontainerlogs)
* [docker::container::stop](#dockercontainerstop)
* [docker::container::start](#dockercontainerstart)
* [docker::container::stop-all](#dockercontainerstop-all)
* [docker::container::remove-all](#dockercontainerremove-all)
* [docker::volume::remove-all](#dockervolumeremove-all)
* [docker::remove-all](#dockerremove-all)
* [adb::device::wait](#adbdevicewait)
* [adb::device::pull](#adbdevicepull)
* [adb::device::push](#adbdevicepush)
* [adb::logcat::clear](#adblogcatclear)
* [adb::logcat::once](#adblogcatonce)
* [adb::logcat::continuous](#adblogcatcontinuous)
* [adb::device::reboot](#adbdevicereboot)
* [adb::device::first](#adbdevicefirst)
* [adb::device::list](#adbdevicelist)
* [adb::device::wait-for-path](#adbdevicewait-for-path)
* [adb::device::screen::capture-once](#adbdevicescreencapture-once)
* [adb::device::select-and-pull](#adbdeviceselect-and-pull)
* [adb::device::bootloader::enter](#adbdevicebootloaderenter)
* [adb::device::bootloader::unlock](#adbdevicebootloaderunlock)
* [adb::device::verity::disable](#adbdeviceveritydisable)
* [adb::device::partition::remount](#adbdevicepartitionremount)
* [adb::device::build::fingerprint](#adbdevicebuildfingerprint)
* [adb::device::build::date](#adbdevicebuilddate)
* [adb::device::slot::suffix](#adbdeviceslotsuffix)
* [adb::device::build::kernel-version](#adbdevicebuildkernel-version)
* [adb::device::screen::capture-continuous](#adbdevicescreencapture-continuous)
* [adb::device::partition::sha256](#adbdevicepartitionsha256)
* [adb::wake::lock](#adbwakelock)
* [adb::wake::unlock](#adbwakeunlock)
* [adb::wake::list](#adbwakelist)
* [process::ids-by-name](#processids-by-name)
* [process::ids-by-name-regex](#processids-by-name-regex)
* [process::threads-by-pid](#processthreads-by-pid)
* [process::threads-by-name](#processthreads-by-name)
* [syscall::trace-by-pid](#syscalltrace-by-pid)
* [lib::trace-by-pid](#libtrace-by-pid)
* [gdb::attach-pid](#gdbattach-pid)
* [gdb::server::start](#gdbserverstart)
* [gdb::connect](#gdbconnect)
* [gdb::run-until](#gdbrun-until)
* [gdb::core::open](#gdbcoreopen)
* [device-tree::node::list](#device-treenodelist)
* [i2c::bus::list](#i2cbuslist)
* [i2c::device::list](#i2cdevicelist)
* [gpio::chip::list](#gpiochiplist)
* [gpio::line::list](#gpiolinelist)
* [usb::device::list](#usbdevicelist)
* [pci::device::list](#pcidevicelist)
* [asciidoc::html](#asciidochtml)
* [flutter::run-chrome-release](#flutterrun-chrome-release)
* [flutter::run-linux-release](#flutterrun-linux-release)
* [flutter::test](#fluttertest)
* [flutter::coverage](#fluttercoverage)
* [systemd::file](#systemdfile)
* [systemd::dependencies](#systemddependencies)
* [systemd::restart](#systemdrestart)
* [systemd::start](#systemdstart)
* [systemd::stop](#systemdstop)
* [systemd::enable](#systemdenable)
* [systemd::disable](#systemddisable)
* [systemd::status](#systemdstatus)
* [systemd::service::list](#systemdservicelist)
* [systemd::service::list-running](#systemdservicelist-running)
* [systemd::service::list-failed](#systemdservicelist-failed)
* [systemd::service::list-files](#systemdservicelist-files)
* [gpg::decrypt](#gpgdecrypt)
* [gpg::public-key::armor](#gpgpublic-keyarmor)
* [gpg::secret-key::fingerprints](#gpgsecret-keyfingerprints)
* [gpg::secret-key::list](#gpgsecret-keylist)
* [user::directory::create-english-links](#userdirectorycreate-english-links)
* [android::build-tools::versions](#androidbuild-toolsversions)
* [android::build-tools::latest-version](#androidbuild-toolslatest-version)
* [go::version::list](#goversionlist)
* [go::version::latest](#goversionlatest)
* [ruby::version::list](#rubyversionlist)
* [ruby::version::latest](#rubyversionlatest)
* [rosetta::install](#rosettainstall)
* [net::dns::servers](#netdnsservers)
* [utm::open](#utmopen)
* [mozc::config::open](#mozcconfigopen)
* [archive::extract](#archiveextract)
* [syscall::trace-by-name](#syscalltrace-by-name)
* [lib::trace-by-name](#libtrace-by-name)
* [gdb::attach-by-name](#gdbattach-by-name)
* [jenkins::restart](#jenkinsrestart)
* [sudo::start-keep-alive](#sudostart-keep-alive)
* [sudo::passwordless::enable](#sudopasswordlessenable)
* [sudo::passwordless::disable](#sudopasswordlessdisable)
* [storage::clear-trash](#storageclear-trash)
* [usb::partition::select](#usbpartitionselect)
* [usb::filesystem::repair](#usbfilesystemrepair)
* [usb::filesystem::format-fat32](#usbfilesystemformat-fat32)
* [git::rebase-base-branch](#gitrebase-base-branch)
* [repo::reset](#reporeset)
* [selinux::generate-rule](#selinuxgenerate-rule)
* [terminal::gnome-bash](#terminalgnome-bash)
* [shell::editor::set-default](#shelleditorset-default)
* [plist::set](#plistset)
* [textproto::set-scalar](#textprotoset-scalar)
* [shell::completion::enable-ignore-case](#shellcompletionenable-ignore-case)
* [git::credentials::remove](#gitcredentialsremove)
* [git::config::enable-origin-all-fetch](#gitconfigenable-origin-all-fetch)
* [git::config::enable-prune-fetch](#gitconfigenable-prune-fetch)
* [git::config::set-default-branch](#gitconfigset-default-branch)
* [git::config::enable-rebase-on-pull](#gitconfigenable-rebase-on-pull)
* [git::config::set-email](#gitconfigset-email)
* [git::config::set-username](#gitconfigset-username)
* [git::config::set-http-buffer](#gitconfigset-http-buffer)
* [git::config::use-gpg-credential-store](#gitconfiguse-gpg-credential-store)
* [git::config::use-credential-manager](#gitconfiguse-credential-manager)
* [pass::store::remove](#passstoreremove)
* [pass::store::init](#passstoreinit)
* [gpg::setup](#gpgsetup)
* [ssh::key::generate-rsa4096](#sshkeygenerate-rsa4096)
* [ssh::key::generate-ed25519](#sshkeygenerate-ed25519)
* [ssh::kill-all](#sshkill-all)
* [git::config::use-osx-keychain](#gitconfiguse-osx-keychain)
* [git-credential-manager::version::list](#git-credential-managerversionlist)
* [git-credential-manager::install](#git-credential-managerinstall)
* [git::config::setup](#gitconfigsetup)
* [go::repository::register](#gorepositoryregister)
* [go::install](#goinstall)
* [rust::install](#rustinstall)
* [rust::versions](#rustversions)
* [flutter::use-version](#flutteruse-version)
* [jfrog::config::clear](#jfrogconfigclear)
* [jfrog::config::clear-all](#jfrogconfigclear-all)
* [jfrog::config::list](#jfrogconfiglist)
* [jfrog::setup](#jfrogsetup)
* [opencode::install](#opencodeinstall)
* [docker::login-artifactory](#dockerlogin-artifactory)
* [chrome::profile::export-bookmarks](#chromeprofileexport-bookmarks)
* [chrome::profile::export-preferences](#chromeprofileexport-preferences)
* [chrome::profile::email](#chromeprofileemail)
* [chrome::profile::find-by-email](#chromeprofilefind-by-email)
* [swap::ensure-total-size](#swapensure-total-size)
* [vscode::remove-user-data](#vscoderemove-user-data)
* [adb::device::set-default](#adbdeviceset-default)
* [adb::server::start](#adbserverstart)
* [adb::server::stop](#adbserverstop)
* [adb::server::restart](#adbserverrestart)
* [git::stash::list](#gitstashlist)
* [file::modified-time-unix-seconds](#filemodified-time-unix-seconds)
* [gpg::key::generate](#gpgkeygenerate)
* [net::dns::manager](#netdnsmanager)
* [net::dns::use-systemd-resolved](#netdnsuse-systemd-resolved)
* [net::dns::use-network-manager](#netdnsuse-network-manager)
* [net::dns::use-google](#netdnsuse-google)

### prompt::pause

Wait for one line from the controlling terminal.

#### Example

```bash
prompt::pause 'Connect the device, then press Enter.'
```

#### Arguments

* **$1** (string): Optional message. Defaults to "Press Enter to continue.".

#### Exit codes

* **0**: A line was read.
* **64**: More than one argument was given.
* **69**: No controlling terminal is available.
* **74**: The terminal could not be read.

### time::sleep-hours

Sleep for a non-negative integer number of hours.

#### Example

```bash
time::sleep-hours 2 && make release
```

#### Arguments

* **$1** (integer): Number of hours, 0 or more.

#### Exit codes

* **0**: The time passed.
* **64**: The value is not a non-negative integer.
* **69**: sleep is unavailable.

### storage::usage

Show human-readable filesystem usage for a path.

#### Example

```bash
storage::usage "${HOME}"
```

#### Arguments

* **$1** (string): Optional path. Defaults to the current directory.

#### Exit codes

* **0**: The report was written.
* **64**: More than one argument was given.
* **66**: The path does not exist.
* **69**: df is unavailable.

#### Output on stdout

* The df -h report for the file system that holds the path.

### storage::largest-entries

Write the largest entries of a directory, including the directory itself, in human-readable sizes.

Directory sizes include everything below them.

#### Example

```bash
storage::largest-entries "${HOME}/Library/Caches" 5
```

#### Arguments

* **$1** (string): Optional directory to inspect. Defaults to the current directory.
* **$2** (integer): Optional number of entries to write. Defaults to 10.

#### Exit codes

* **0**: The entries were written.
* **64**: The directory does not exist or the count is not a positive integer.
* **69**: du or sort is unavailable.

#### Output on stdout

* Lines of size and path, largest first.

### mem::physical-total-bytes

Write the total physical memory in bytes.

#### Example

```bash
mem::physical-total-bytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or sysctl is missing on macOS.
* **74**: The memory size could not be read.

#### Output on stdout

* The total physical memory in bytes.

### mem::physical-total-gibibytes

Write the total physical memory in gibibytes.

#### Example

```bash
mem::physical-total-gibibytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: The memory size could not be read.

#### Output on stdout

* The total physical memory in GiB with two decimals, such as 15.53.

### mem::swap-total-bytes

Write the total swap capacity in bytes.

#### Example

```bash
[[ "$(mem::swap-total-bytes)" -gt 0 ]] || swap::create 4
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or sysctl is missing on macOS.
* **74**: The swap size could not be read.

#### Output on stdout

* The total swap capacity in bytes; 0 without swap.

### mem::swap-total-gibibytes

Write the total swap capacity in gibibytes.

#### Example

```bash
mem::swap-total-gibibytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: The swap size could not be read.

#### Output on stdout

* The total swap capacity in GiB with two decimals.

### mem::total-bytes

Write the total memory and swap capacity in bytes.

#### Example

```bash
mem::total-bytes
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: A size could not be read.

#### Output on stdout

* The sum of physical memory and swap in bytes.

### mem::total-gibibytes

Write the total memory and swap capacity in gibibytes.

#### Example

```bash
printf 'Memory and swap: %s GiB\n' "$(mem::total-gibibytes)"
```

_Function has no arguments._

#### Exit codes

* **0**: The size was written.
* **64**: An argument was given.
* **69**: The operating system is unsupported.
* **74**: A size could not be read.

#### Output on stdout

* The sum of physical memory and swap in GiB with two decimals.

### file::write-text

Write text to a regular file using an atomic replacement.

New files use 0666 filtered by the caller's umask; existing metadata is preserved.

#### Example

```bash
file::write-text /etc/udev/rules.d/90-device.rules $'SUBSYSTEM=="usb", MODE="0666"\n'
```

#### Arguments

* **$1** (string): File path; a symbolic link is refused.
* **$2** (string): Text to write exactly; include a trailing newline when one is needed.

#### Exit codes

* **0**: The file holds the text.
* **64**: The path is empty or a symbolic link, or the argument count is not two.
* **66**: The path exists but is not a regular file.
* **74**: The temporary file could not be written or moved into place.
* other The status of the root helper when elevation was needed.

### file::find-by-content

Write the regular files below a directory whose content matches an ERE, separated by NUL.

The files are searched in parallel by grep -E.

#### Example

```bash
file::find-by-content 'FIXME|XXX' src | xargs -0 grep -nE 'FIXME|XXX'
```

#### Arguments

* **$1** (string): Extended regular expression evaluated by grep -E.
* **$2** (string): Optional directory to search. Defaults to the current directory.
* **$3** (integer): Optional number of parallel grep processes. Defaults to the number of online CPUs.
* **$4** (string): Optional binary mode: skip (default) ignores binary files; include searches them as text.

#### Exit codes

* **0**: At least one file matches.
* **1**: No file matches.
* **64**: The expression is invalid, or a mode or count is malformed.
* **66**: The directory does not exist.
* **69**: find, xargs, or grep is unavailable.
* **74**: A file could not be searched.

#### Output on stdout

* NUL-separated paths of the matching files.

### file::latest-by-name

Write the most recently modified regular file whose base name matches a Bash ERE.

Files modified at the same second are ordered by their path bytes, and the
first one is written.

#### Example

```bash
file::latest-by-name '^backup-.*\.tar\.gz$' /var/backups
```

#### Arguments

* **$1** (string): Extended regular expression matched against base names.
* **$2** (string): Optional directory to search recursively. Defaults to the current directory.

#### Exit codes

* **0**: A file was written.
* **1**: No file matches.
* **64**: The argument count is wrong.
* **66**: The directory does not exist.

#### Output on stdout

* The path of the newest matching file.

### symlink::create

Create or replace a symbolic link that points to the absolute path of an existing SOURCE.

An existing symbolic link at LINK is replaced; a file or directory there is
kept and returns 73. Administrator execution is used only when the parent
directory of LINK is not writable.

#### Example

```bash
symlink::create ./dotfiles/.vimrc "${HOME}/.vimrc"
```

#### Arguments

* **$1** (string): SOURCE Existing path the link points to.
* **$2** (string): LINK Path of the link.

#### Exit codes

* **0**: LINK points to the absolute path of SOURCE.
* **64**: An argument is empty, or the argument count is not two.
* **66**: SOURCE does not exist.
* **73**: LINK exists and is not a symbolic link.
* **74**: The link could not be created.

### symlink::remove

Remove a symbolic link, using administrator execution only when its directory is not writable.

#### Example

```bash
symlink::remove "${HOME}/.vimrc"
```

#### Arguments

* **$1** (string): Path of an existing symbolic link; its target is not touched.

#### Exit codes

* **0**: The link was removed.
* **64**: The path is not a symbolic link, or the argument count is not one.
* **74**: The link could not be removed.

### net::interface::default

Write the first default-route interface.

#### Example

```bash
net::ip::private-v4 "$(net::interface::default)"
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: No default route exists, or the routing tool is unavailable.

#### Output on stdout

* The interface name, such as eth0 or en0.

### net::gateway::default

Write the first default-route gateway.

#### Example

```bash
net::ping "$(net::gateway::default)"
```

_Function has no arguments._

#### Exit codes

* **0**: The address was written.
* **64**: An argument was given.
* **69**: No default route exists, or the routing tool is unavailable.

#### Output on stdout

* The gateway address.

### net::ip::private-v4

Write the primary RFC 1918 IPv4 address of an interface.

#### Example

```bash
net::ip::private-v4 eth0
```

#### Arguments

* **$1** (string): INTERFACE Interface name. Defaults to the interface of the default route.

#### Exit codes

* **0**: The address was written.
* **1**: The interface has no private IPv4 address.
* **64**: More than one argument was given.
* **69**: No interface was given and there is no default route, or the address tool is unavailable.

#### Output on stdout

* The address without a prefix length, such as 192.168.1.20.

### net::ip::private-v6

Write the primary unique local IPv6 address of an interface.

Only addresses in fc00::/7 are considered, in the order the operating
system lists them, after removing the excluded prefixes.

#### Example

```bash
net::ip::private-v6 en0 fe80
```

#### Arguments

* **$1** (string): INTERFACE Interface name. Defaults to the interface of the default route.
* **$2** (string): EXCLUDED_PREFIXES Comma-separated address prefixes to skip. Defaults to fe80,fda6: link-local addresses and the auxiliary ULA of the reference network.

#### Exit codes

* **0**: The address was written.
* **1**: No address remains after the exclusions.
* **64**: More than two arguments were given.
* **69**: No interface was given and there is no default route, or the address tool is unavailable.

#### Output on stdout

* The address without a prefix length.

### net::ip::public

Write the public IP address reported by ifconfig.me.

curl is preferred and wget is used when curl is missing. The response
must be one IPv4 or IPv6 address; anything else returns 74.

#### Example

```bash
net::ip::public
```

_Function has no arguments._

#### Exit codes

* **0**: The address was written.
* **64**: An argument was given.
* **69**: Neither curl nor wget is available.
* **74**: The request failed or the response is not an address.

#### Output on stdout

* One IPv4 or IPv6 address.

#### Output on stderr

* A message when neither curl nor wget is available.

### net::dns::test

Test whether a DNS name resolves.

#### Example

```bash
net::dns::test github.com || net::dns::use-google
```

#### Arguments

* **$1** (string): Host name to resolve.

#### Exit codes

* **0**: The name resolves.
* **1**: The name does not resolve.
* **64**: The name is empty, or the argument count is not one.
* **69**: Neither getent nor dscacheutil is available.

### user::add-to-group

Add a user to a supplementary group through administrator execution.

#### Example

```bash
user::add-to-group dialout
```

#### Arguments

* **$1** (string): Group name.
* **$2** (string): Optional user name. Defaults to the current user.

#### Exit codes

* **0**: The user is in the group; it applies to new login sessions.
* **64**: The group name is invalid, or the argument count is wrong.
* **69**: The operating system is unsupported, or usermod or dseditgroup is unavailable.
* **77**: sudo refused the credentials.
* other The status of usermod or dseditgroup.

### system::kernel-name

Write the kernel name.

#### Example

```bash
system::kernel-name
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: uname is unavailable.

#### Output on stdout

* The output of uname -s, such as Linux or Darwin.

### system::distribution-name

Write the distribution name.

#### Example

```bash
[[ "$(system::distribution-name)" == ubuntu ]] && sudo apt-get update
```

_Function has no arguments._

#### Exit codes

* **0**: The name was written.
* **64**: An argument was given.
* **69**: The distribution cannot be identified.

#### Output on stdout

* darwin, ubuntu, fedora, or the ID from /etc/os-release.

### system::enable-sleep

Enable system sleep.

#### Example

```bash
system::enable-sleep
```

_Function has no arguments._

#### Exit codes

* **0**: Sleep is enabled again.
* **64**: An argument was given.
* **69**: A required command is missing, or the operating system is unsupported.
* **77**: sudo refused the credentials.
* other The status of pmset or systemctl.

### system::disable-sleep

Disable system sleep.

On Linux the sleep, suspend, hibernate, and hybrid-sleep targets are masked; on macOS pmset sets sleep to 0.

#### Example

```bash
system::disable-sleep
```

_Function has no arguments._

#### Exit codes

* **0**: Sleep is disabled until system::enable-sleep.
* **64**: An argument was given.
* **69**: A required command is missing, or the operating system is unsupported.
* **77**: sudo refused the credentials.
* other The status of pmset or systemctl.

### system::disable-auto-lock

Disable automatic screen locking for the current user.

Linux changes GNOME's lock-enabled setting. macOS disables the password prompt
after the screen saver or display turns off. Neither changes system sleep or
whether the screen saver starts.

#### Example

```bash
system::disable-auto-lock
```

_Function has no arguments._

#### Exit codes

* **0**: Automatic screen locking is disabled.
* **64**: An argument was given.
* **69**: The operating system is unsupported, or a required command is missing.
* **74**: The screen-lock setting could not be changed.

### time::posix-timezone

Write the POSIX TZ string for a UTC offset.

POSIX TZ offsets have the opposite sign of ISO 8601 offsets, so +09:30
becomes UTC-9:30 and -05:00 becomes UTC+5.

#### Example

```bash
time::posix-timezone +09:00
# UTC-9
```

#### Arguments

* **$1** (string): OFFSET Z or an offset in the form +HH:MM or -HH:MM, with HH up to 23 and MM up to 59.

#### Exit codes

* **0**: The value was written.
* **64**: The offset is malformed or out of range.

#### Output on stdout

* The TZ value, such as UTC-9 or UTC+5:30.

### directory::merge

Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE.

Directories are merged recursively. A file or symbolic link in SOURCE
replaces the entry with the same name in DESTINATION. Symbolic links are
never followed. The first failure stops the merge.

#### Example

```bash
directory::merge "${HOME}/デスクトップ" "${HOME}/Desktop"
```

#### Arguments

* **$1** (string): SOURCE Directory to empty and remove.
* **$2** (string): DESTINATION Directory to receive the entries; created when missing.

#### Exit codes

* **0**: SOURCE was merged into DESTINATION and removed.
* **64**: SOURCE is not a directory, or DESTINATION is a symbolic link or a file.
* **74**: An entry could not be moved, or SOURCE could not be removed.

### directory::create-with-date-time

Create a directory named with the local date and time and write its path.

The name has the form YYYYMMDDTHHMMSS. When that name exists, a suffix
counting from -2 is added.

#### Example

```bash
backup="$(directory::create-with-date-time /var/backups)"
```

#### Arguments

* **$1** (string): DIRECTORY Parent directory. Defaults to the current directory.

#### Exit codes

* **0**: The directory was created.
* **64**: More than one argument was given.
* **66**: The parent directory does not exist.
* **69**: The clock provider is unavailable.
* **74**: The directory could not be created.

#### Output on stdout

* The path of the new directory, such as ./20261014T120405.

### directory::clear

Remove every entry of a directory, including hidden ones, and keep the directory.

An empty name, the file system root, the home directory, and a symbolic
link are refused, because a link would empty the directory it points to.

#### Example

```bash
directory::clear ./build
```

#### Arguments

* **$1** (string): DIRECTORY Directory to empty. Defaults to the current directory.

#### Exit codes

* **0**: The directory is empty.
* **64**: The directory is missing, a symbolic link, the root, or the home directory.
* **66**: The directory cannot be entered.
* **74**: An entry could not be removed.

#### Output on stderr

* A message when the directory is refused.

### time::status-continuous

Write the elapsed time since boot and the local time every three seconds until stopped.

#### Example

```bash
time::status-continuous   # Stop with Ctrl-C.
```

_Function has no arguments._

#### Exit codes

* **64**: An argument was given.
* **74**: sleep failed.
* other The status of the clock function that failed.

#### Output on stdout

* Two lines every three seconds: the seconds since boot and the local date and time.

### file::edit

Open an editor for a file, using sudoedit only when required.

EDITOR is split on whitespace into a command and its arguments, such as
code --wait. It defaults to vi.

#### Example

```bash
EDITOR=nano file::edit /etc/hosts
```

#### Arguments

* **$1** (string): File to edit. A missing file is created by the editor.

#### Exit codes

* **0**: The editor exited successfully.
* **64**: The argument count is not one or the path is empty.
* **66**: The path exists but is not a regular file.
* **69**: The file is not writable and sudoedit is unavailable.
* other The status of the editor.

### file::release

Release a file held by other processes.

Each holder receives SIGTERM, and holders left after the timeout receive
SIGKILL. A signal the current user may not send is sent through
administrator execution.

#### Example

```bash
file::release "${HOME}/.local/share/app/database.lock" 5
```

#### Arguments

* **$1** (string): File to release.
* **$2** (integer): Optional seconds to wait after SIGTERM: a non-negative integer. Defaults to 2.

#### Exit codes

* **0**: No process holds the file.
* **64**: The arguments are invalid, the timeout is not a non-negative integer, or the file does not exist.
* **69**: lsof is unavailable.
* **74**: The clock could not be read.
* **75**: The file is still open after SIGKILL.

### screen::open

Open a GNU Screen session.

#### Example

```bash
screen::open build
```

#### Arguments

* **$1** (string): Optional session name. Defaults to default.

#### Exit codes

* **0**: The session ended successfully.
* **64**: More than one argument was given.
* **69**: screen is unavailable.
* other The status of screen.

### archive::verify

Verify all recognized archives below a path.

The recognized extensions are .tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2,
.tbz2, .tbz, .tar.zst, .tzst, .zip, .7z, .gz, .xz, .bz2, and .zst.
Compressed data is tested in full, and tar archives are read to the end of
their entries; the bytes of the files inside a tar archive are covered only
by the compression checksum. An archive that cannot be verified, because
its tool is missing, it is encrypted, or it cannot be read, is reported on
standard error but not counted as broken, and does not change the status.

#### Example

```bash
archive::verify "${HOME}/Downloads"
```

#### Arguments

* **$1** (string): Optional archive file or directory to search. Defaults to the current directory.

#### Exit codes

* **0**: Every archive is valid.
* **1**: At least one archive is broken.
* **64**: More than one argument was given.
* **66**: The path does not exist or cannot be searched.
* **74**: The temporary list could not be created.

#### Output on stderr

* The path of each broken archive, and a message for each archive that cannot be verified.

### archive::remove-broken

Remove archives that fail verification.

Only archives that archive::verify reports as broken are removed. An
archive that cannot be verified is kept and does not change the status.

#### Example

```bash
archive::remove-broken "${HOME}/Downloads"
```

#### Arguments

* **$1** (string): Optional archive file or directory to search. Defaults to the current directory.

#### Exit codes

* **0**: No archive was broken.
* **1**: At least one broken archive was removed.
* **64**: More than one argument was given.
* **66**: The path does not exist or cannot be searched.
* **74**: A broken archive or the temporary list could not be removed or created.

#### Output on stderr

* The path of each removed archive, and a message for each archive that cannot be verified.

### archive::extract-file

Extract one archive or decompress one compressed file.

Archives (.tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2, .tbz2, .tbz,
.tar.zst, .tzst, .zip, .7z) are extracted into a directory. Entry names that
are absolute or climb with .. are refused before extraction. The archive is
extracted into a staging directory inside the destination, and a symbolic
link that points outside the destination discards the extraction with 65.
A single compressed file (.gz, .xz, .bz2, .zst) is decompressed into one
file named without the extension. Existing files are overwritten.

#### Example

```bash
archive::extract-file release.tar.xz /opt/release
archive::extract-file access.log.gz
```

#### Arguments

* **$1** (string): Archive or compressed file.
* **$2** (string): Optional output directory. Defaults to the archive path without its extension, or to the directory of a single compressed file.

#### Exit codes

* **0**: The archive was extracted.
* **64**: The arguments are invalid or the extension is not recognized.
* **65**: The archive is corrupt or contains an entry outside the destination.
* **69**: A required tool is unavailable, or the entry names of an encrypted 7z archive cannot be read.
* **73**: A single compressed file would replace a directory.
* **74**: The destination could not be written.

#### Output on stderr

* The rejected entry or symbolic link when the archive is refused.

### archive::compress-tar-gzip

Compress paths into a gzip-compressed tar archive.

#### Example

```bash
archive::compress-tar-gzip --output backup.tar.gz Documents Pictures
```

#### Options

* **--output \<FILE\>**

  Archive to write. Defaults to the first path with .tar.gz appended.

#### Arguments

* **...** (string): Paths to add to the archive.

#### Exit codes

* **0**: The archive was written.
* **64**: No path was given or --output has no value.
* **69**: tar is unavailable.
* other The status of tar.

### diff::directories

Run diff for two directories.

#### Example

```bash
diff::directories config.orig config > config.patch
```

#### Arguments

* **$1** (string): Original directory.
* **$2** (string): Changed directory.

#### Exit codes

* **0**: The directories are identical.
* **1**: The directories differ.
* **64**: The argument count is not two or a directory does not exist.
* **69**: diff is unavailable.
* **2**: diff failed.

#### Output on stdout

* A unified diff that includes new files.

### git::clone-shallow

Clone a repository with depth one.

#### Example

```bash
git::clone-shallow https://github.com/reconquest/shdoc.git --branch v1.4 vendor/shdoc
```

#### Options

* **--branch \<BRANCH\>**

  Branch or tag to check out.

#### Arguments

* **$1** (string): Repository URL.
* **$2** (string): Optional output directory. Defaults to the name Git derives from the URL.

#### Exit codes

* **0**: The repository was cloned.
* **64**: The arguments are invalid.
* other The status of git clone.

### git::rebase-abort

Abort an in-progress rebase.

#### Example

```bash
git::rebase-abort "${HOME}/src/project"
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The rebase was aborted.
* **64**: More than one argument was given.
* other The status of git rebase.

### git::rebase-continue

Continue an in-progress rebase.

#### Example

```bash
git add README.md && git::rebase-continue
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The rebase continued.
* **64**: More than one argument was given.
* other The status of git rebase.

### git::commit::amend

Amend the last commit without changing its message.

#### Example

```bash
git add README.md && git::commit::amend
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was amended.
* **64**: More than one argument was given.
* other The status of git commit.

### git::commit::create

Create a commit with a message.

#### Example

```bash
git add README.md && git::commit::create 'docs: describe the installer'
```

#### Arguments

* **$1** (string): Commit message.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was created.
* **64**: The argument count is not one or two.
* other The status of git commit.

### git::commit::uncommit

Remove the last commit while keeping its changes staged.

#### Example

```bash
git::commit::uncommit
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was removed.
* **64**: More than one argument was given.
* other The status of git reset.

### git::branch::current

Write the current branch name.

#### Example

```bash
branch="$(git::branch::current)"
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch name was written.
* **1**: HEAD is detached or the directory is not a repository.
* **64**: More than one argument was given.

#### Output on stdout

* The short name of the checked-out branch.

### git::branch::create

Create a branch at a starting revision.

#### Example

```bash
git::branch::create release/1.2 v1.2.0
```

#### Arguments

* **$1** (string): New branch name.
* **$2** (string): Optional starting revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was created.
* **64**: The argument count is not one to three.
* other The status of git branch.

### git::branch::list

List local and remote-tracking branches.

#### Example

```bash
git::branch::list
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branches were written.
* **64**: More than one argument was given.
* other The status of git branch.

#### Output on stdout

* The output of git branch -a.

### git::diff::files

Show file names changed between two revisions.

#### Example

```bash
git::diff::files origin/main
```

#### Arguments

* **$1** (string): Base revision.
* **$2** (string): Optional target revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: The argument count is not one to three.
* other The status of git diff.

#### Output on stdout

* One changed path per line.

### git::diff::patch

Show a patch between two revisions.

#### Example

```bash
git::diff::patch v1.0.0 v1.1.0 > changes.patch
```

#### Arguments

* **$1** (string): Base revision.
* **$2** (string): Optional target revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: The argument count is not one to three.
* other The status of git diff.

#### Output on stdout

* The unified diff.

### git::diff::uncommitted-patch

Show the patch for uncommitted tracked changes.

#### Example

```bash
git::diff::uncommitted-patch > work.patch
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than one argument was given.
* other The status of git diff.

#### Output on stdout

* The unified diff of staged and unstaged tracked changes.

### git::diff::uncommitted-files

Show file names changed by uncommitted tracked changes.

#### Example

```bash
git::diff::uncommitted-files
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* other The status of git diff.

#### Output on stdout

* One changed path per line.

### git::diff::latest-patch

Show the patch introduced by the latest commit.

#### Example

```bash
git::diff::latest-patch > latest.patch
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than one argument was given.
* other The status of git show.

#### Output on stdout

* The unified diff of HEAD.

### git::diff::latest-files

Show file names changed by the latest commit.

#### Example

```bash
git::diff::latest-files
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* other The status of git show.

#### Output on stdout

* One changed path per line.

### git::commit::patch

Write the unified diff that one commit introduced.

The commit is fetched from REMOTE only when the repository lacks it, and it
is compared with its first parent, or with the empty tree for a root commit.
In a shallow clone, a parent beyond the shallow boundary is fetched as well.

#### Example

```bash
git::commit::patch 3ce3b61 > fix.patch
```

#### Arguments

* **$1** (string): Commit to show.
* **$2** (string): Optional remote to fetch a missing commit from. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: The arguments are invalid.
* **74**: The empty tree could not be computed.
* other The status of the git command that failed.

#### Output on stdout

* The unified diff of the commit.

### git::commit::revert-without-commit

Revert a commit without creating a commit.

#### Example

```bash
git::commit::revert-without-commit 3ce3b61
```

#### Arguments

* **$1** (string): Optional commit to revert. Defaults to HEAD.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were reverted in the working tree and index.
* **64**: More than two arguments were given.
* other The status of git revert.

### git::commit::revert

Revert a commit and create the revert commit.

#### Example

```bash
git::commit::revert 3ce3b61
```

#### Arguments

* **$1** (string): Optional commit to revert. Defaults to HEAD.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The revert commit was created.
* **64**: More than two arguments were given.
* other The status of git revert.

### git::fetch

Fetch one remote or all remotes.

#### Example

```bash
git::fetch upstream
```

#### Arguments

* **$1** (string): Optional remote. Defaults to every remote.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The fetch finished.
* **64**: More than two arguments were given.
* other The status of git fetch.

### git::fetch-unshallow

Convert a shallow clone into a complete history.

#### Example

```bash
git::fetch-unshallow origin
```

#### Arguments

* **$1** (string): Optional remote to fetch. Defaults to every remote.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The history is complete.
* **64**: More than two arguments were given.
* **66**: The repository has no remote.
* other The status of the git command that failed.

### git::stash::patch

Show a stash patch.

#### Example

```bash
git::stash::patch 'stash@{1}'
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than two arguments were given.
* other The status of git stash.

#### Output on stdout

* The unified diff of the stash.

### git::stash::push

Save tracked changes and untracked files in a new stash.

#### Example

```bash
git::stash::push 'before rebase'
```

#### Arguments

* **$1** (string): Optional stash message.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were stashed.
* **64**: More than two arguments were given.
* other The status of git stash.

### git::stash::pop

Apply and remove a stash.

#### Example

```bash
git::stash::pop
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stash was applied and removed.
* **64**: More than two arguments were given.
* other The status of git stash.

### git::stash::drop

Delete a stash.

#### Example

```bash
git::stash::drop 'stash@{2}'
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stash was deleted.
* **64**: More than two arguments were given.
* other The status of git stash.

### git::reset

Reset a working tree to a revision.

#### Example

```bash
git::fetch origin && git::reset origin/main
```

#### Arguments

* **$1** (string): Revision to reset to.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The working tree and index match the revision.
* **64**: The argument count is not one or two.
* other The status of git reset.

### git::pull-rebase

Update a branch from a remote with rebase.

#### Example

```bash
git::pull-rebase main upstream
```

#### Arguments

* **$1** (string): Optional remote branch to pull. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was updated.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git pull.

### git::cherry-pick

Apply one commit, fetching it from a remote only when the repository lacks it.

#### Example

```bash
git::cherry-pick 3ce3b61 upstream
```

#### Arguments

* **$1** (string): Commit to apply.
* **$2** (string): Optional remote to fetch a missing commit from. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was applied.
* **64**: The arguments are invalid.
* other The status of the git command that failed.

### git::cherry-pick-continue

Continue an in-progress cherry-pick.

#### Example

```bash
git add src/util.sh && git::cherry-pick-continue
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The cherry-pick continued.
* **64**: More than one argument was given.
* other The status of git cherry-pick.

### git::cherry-pick-abort

Abort an in-progress cherry-pick.

Untracked files left by the cherry-pick are stashed, or removed when stashing fails.

#### Example

```bash
git::cherry-pick-abort
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The cherry-pick was aborted.
* **64**: More than one argument was given.
* other The status of the git command that failed.

### git::push

Push a branch to a remote.

#### Example

```bash
git::push feature/login
```

#### Arguments

* **$1** (string): Optional branch. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### git::push::force-with-lease

Push a branch without overwriting a remote update.

#### Example

```bash
git rebase origin/main && git::push::force-with-lease
```

#### Arguments

* **$1** (string): Optional branch. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### gerrit::push-review

Push the current HEAD to a Gerrit review reference.

#### Example

```bash
gerrit::push-review main
```

#### Arguments

* **$1** (string): Optional target branch of the review. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The review was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### gerrit::push-review-wip

Push the current HEAD to a Gerrit review reference as work in progress.

#### Example

```bash
gerrit::push-review-wip main
```

#### Arguments

* **$1** (string): Optional target branch of the review. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The review was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### git::remote::delete-branch

Delete a branch on a remote.

#### Example

```bash
git::remote::delete-branch feature/login
```

#### Arguments

* **$1** (string): Optional branch to delete. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The remote branch was deleted.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### git::submodule::update-all

Update all submodules recursively.

#### Example

```bash
git::submodule::update-all
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: Every submodule was initialized and updated.
* **64**: More than one argument was given.
* other The status of git submodule.

### git::commit::discard

Discard all changes in a working tree.

The changes, including untracked files, are first saved in a stash, and the branch is reset to the parent of HEAD.

#### Example

```bash
git::commit::discard
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were stashed and the latest commit was removed.
* **64**: More than one argument was given.
* other The status of the git command that failed, including when HEAD has no parent.

### git::reset-remote

Hard reset the current branch to the branch with the same name on a remote.

#### Example

```bash
git::reset-remote upstream
```

#### Arguments

* **$1** (string): Optional remote. Defaults to origin.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch matches the remote branch.
* **1**: HEAD is detached.
* **64**: More than two arguments were given.
* other The status of the git command that failed.

### git::pull-base-branch

Pull the configured base branch with fast-forward-only semantics.

The base branch is checked out and fast-forwarded from origin, and the original branch is then rebased onto it.

#### Example

```bash
git::pull-base-branch develop
```

#### Arguments

* **$1** (string): Optional base branch. Defaults to main.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The base branch was updated and the current branch was rebased.
* **64**: More than two arguments were given.
* **65**: HEAD is detached.
* **75**: The base branch could not be fast-forwarded, or the original branch could not be checked out again.
* other The status of git checkout or git rebase.

### env::dotenv::import

Import the variables of a dotenv file into the current process.

The file is parsed as data and never executed. Every line is validated
before any variable changes; see env::dotenv::_entries for the syntax.

#### Example

```bash
env::dotenv::import .env && printf '%s\n' "${DATABASE_URL}"
```

#### Arguments

* **$1** (string): Regular dotenv file. A symbolic link is refused.

#### Variables set

* **Each** (variable): of the file is set and exported.

#### Exit codes

* **0**: The variables were imported.
* **64**: The argument is not one regular file.
* **65**: A line is not valid dotenv syntax; no variable changes.
* other The status of the parser.

### env::set-variable

Set an environment variable for the current shell.

The export line is written to the startup file of each shell, replacing an earlier export of the same name.

#### Example

```bash
env::set-variable EDITOR vim bash
```

#### Arguments

* **$1** (string): Variable name.
* **$2** (string): Value.
* **$3** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Variables set

* **The** (variable): is exported in the current shell.

#### Exit codes

* **0**: The variable was set and saved.
* **64**: The name or the shell list is invalid.
* other The status of the file operation that failed.

### env::add-path

Add a directory to PATH without creating duplicates.

A line that adds the directory once is written to the startup file of each shell.

#### Example

```bash
env::add-path "${HOME}/.local/bin"
```

#### Arguments

* **$1** (string): Existing directory.
* **$2** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Variables set

* **PATH** (gains): the directory in the current shell when it is missing.

#### Exit codes

* **0**: PATH was updated and saved.
* **64**: The directory does not exist or the shell list is invalid.
* other The status of the file operation that failed.

### env::dotenv::register

Load a dotenv file in every new Bash and Zsh session.

Bash startup files load BashStock and call env::dotenv::import. Zsh cannot
load a Bash library, so its startup file asks Bash for the parsed values
and evaluates the resulting export commands. Each startup file receives the
line once, and the file is always read as data.

#### Example

```bash
env::dotenv::register "${HOME}/.config/app/.env" zsh
```

#### Arguments

* **$1** (string): Regular dotenv file. A relative path is stored as an absolute path.
* **$2** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Exit codes

* **0**: The startup files load the file.
* **64**: The file is not a regular file or the shell list is invalid.
* other The status of the file operation that failed.

### symlink::create-in-local-bin

Create a symbolic link in a user's local bin directory.

#### Example

```bash
symlink::create-in-local-bin /opt/flutter/bin/flutter
```

#### Arguments

* **$1** (string): Existing file or directory to link to.
* **$2** (string): Optional link name. Defaults to the base name of the source.
* **$3** (string): Optional bin directory. Defaults to $HOME/.local/bin.

#### Exit codes

* **0**: The link was created.
* **64**: The arguments are invalid or the source does not exist.
* **74**: The bin directory could not be created.
* other The status of symlink::create.

### ssh::setup-directory

Create $HOME/.ssh and give it and its files the modes SSH expects.

Entries owned by another user are first given back to the current user
through administrator execution. Directories become 700 and files 644,
except private keys, config, and authorized_keys, which become 600. A
private key is recognized by its PEM or OpenSSH header, so no passphrase
is ever requested.

#### Example

```bash
ssh::setup-directory
```

_Function has no arguments._

#### Exit codes

* **0**: The directory and its files have the expected modes.
* **64**: An argument was given.
* **74**: A mode or owner could not be changed.

### ssh::config::update

Update one key in a marker-managed SSH Host block.

The Host block is created when missing. Only blocks written by BashStock are changed.

#### Example

```bash
ssh::config::update "${HOME}/.ssh/config" github.com IdentityFile '~/.ssh/github'
```

#### Arguments

* **$1** (string): SSH configuration file.
* **$2** (string): Host pattern.
* **$3** (string): Key, such as IdentityFile.
* **$4** (string): Value on one line.

#### Exit codes

* **0**: The key was written.
* **64**: The arguments are invalid.
* other The status of the file update.

### ssh::config::set

Create an SSH configuration file when necessary and update one key.

#### Example

```bash
ssh::config::set "${HOME}/.ssh/config" 'build-*' User builder
```

#### Arguments

* **$1** (string): SSH configuration file. It and its directory are created when missing.
* **$2** (string): Host pattern.
* **$3** (string): Key, such as User.
* **$4** (string): Value on one line.

#### Exit codes

* **0**: The key was written.
* **64**: The arguments are invalid or the file is a symbolic link.
* **66**: The path exists but is not a regular file.
* **74**: The file could not be created.
* other The status of ssh::config::update.

### ssh::config::enable-auto-add-keys

Enable AddKeysToAgent for an optional SSH Host pattern.

#### Example

```bash
ssh::config::enable-auto-add-keys
```

#### Arguments

* **$1** (string): Optional SSH configuration file. Defaults to $HOME/.ssh/config.
* **$2** (string): Optional Host pattern. Defaults to *.

#### Exit codes

* **0**: AddKeysToAgent is enabled.
* **64**: More than two arguments were given.
* other The status of ssh::config::set.

### ssh::config::disable-host-key-checking

Disable SSH host-key checks for an optional Host pattern.

Normal use should register the correct host key in known_hosts instead.

#### Example

```bash
ssh::config::disable-host-key-checking "${HOME}/.ssh/config" '192.168.56.*'
```

#### Arguments

* **$1** (string): Optional SSH configuration file. Defaults to $HOME/.ssh/config.
* **$2** (string): Optional Host pattern. Defaults to *.

#### Exit codes

* **0**: Host-key checks are disabled for the pattern.
* **64**: More than two arguments were given or the file is a symbolic link.
* **66**: The path exists but is not a regular file.
* **74**: The file could not be created.
* other The status of the file update.

### ssh::key::private-files

List regular files that ssh-keygen can read as private keys.

#### Example

```bash
ssh::key::private-files
```

#### Arguments

* **$1** (string): Optional directory. Defaults to $HOME/.ssh.

#### Exit codes

* **0**: The paths were written; none may match.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: ssh-keygen is unavailable.

#### Output on stdout

* One private key path per line.

### ssh::key::add

Add one private key to ssh-agent.

#### Example

```bash
ssh::key::add "${HOME}/.ssh/id_ed25519"
```

#### Arguments

* **$1** (string): Private key file.

#### Exit codes

* **0**: The key was added.
* **64**: The argument is not one regular file.
* **69**: ssh-add is unavailable.
* other The status of ssh-add.

### ssh::key::add-all

Add every detected private key in a directory to ssh-agent.

#### Example

```bash
ssh::key::add-all
```

#### Arguments

* **$1** (string): Optional directory. Defaults to $HOME/.ssh.

#### Exit codes

* **0**: Every key was added.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: ssh-add or ssh-keygen is unavailable.
* other The status of the last ssh-add that failed.

### ssh::key::add-all-private-keys

Add every detected private key in a directory to ssh-agent.

This is an alias of ssh::key::add-all.

#### Example

```bash
ssh::key::add-all-private-keys
```

#### Arguments

* **$1** (string): Optional directory. Defaults to $HOME/.ssh.

#### Exit codes

* **0**: Every key was added.
* other The status of ssh::key::add-all.

### net::ping

Send ICMP echo requests to a host.

#### Example

```bash
net::ping 192.168.1.1 1 2
```

#### Arguments

* **$1** (string): Optional host name or address. Defaults to google.com.
* **$2** (integer): Optional number of requests. Defaults to 3.
* **$3** (integer): Optional seconds to wait for each reply. Defaults to 5.

#### Exit codes

* **0**: A reply was received.
* **64**: The arguments are invalid.
* **69**: ping is unavailable or the operating system is unsupported.
* other The status of ping.

#### Output on stdout

* The output of ping.

### swap::disable-all

Disable every active swap area through administrator execution.

#### Example

```bash
swap::disable-all
```

_Function has no arguments._

#### Exit codes

* **0**: Every swap area is disabled.
* **64**: An argument was given.
* **69**: swapoff is unavailable.
* other The status of swapoff.

### swap::remove-all-files

Disable every swap file, remove its /etc/fstab entry, and delete it.

Swap partitions are kept. The first failure stops the removal and is reported.

#### Example

```bash
swap::remove-all-files && swap::create 4294967296
```

_Function has no arguments._

#### Exit codes

* **0**: Every swap file was removed.
* **64**: An argument was given.
* **69**: /proc/swaps cannot be read.
* **74**: A swap file could not be disabled, unregistered, or deleted.

#### Output on stderr

* The swap file and step that failed.

### swap::create

Create a swap file, enable it, and register it in /etc/fstab.

The file is created and enabled through administrator execution.

#### Example

```bash
swap::create 4294967296
```

#### Arguments

* **$1** (integer): Optional size in bytes. Defaults to 8589934592 (8 GiB).
* **$2** (string): Optional absolute swap file path. Defaults to /swapfile.

#### Exit codes

* **0**: The swap file is enabled and registered.
* **64**: The size or path is invalid.
* **69**: The system is not Linux or mkswap is unavailable.
* **73**: The path already exists.
* **74**: The file could not be created or enabled.
* other The status of the /etc/fstab update.

#### Output on stderr

* A message when the path already exists.

### swap::list

List active swap devices.

#### Example

```bash
swap::list
```

_Function has no arguments._

#### Exit codes

* **0**: The swap areas were written.
* **64**: An argument was given.
* **69**: swapon is unavailable.

#### Output on stdout

* The output of swapon --show.

### path::find

Write the paths below a directory that match a case-insensitive Bash ERE, separated by NUL.

#### Example

```bash
path::find '\.(jpe?g|png)$' "${HOME}/Pictures" | xargs -0 ls -l
```

#### Arguments

* **$1** (string): Extended regular expression evaluated by Bash on each path.
* **$2** (string): Optional directory to search. Defaults to the current directory.

#### Exit codes

* **0**: At least one path matches.
* **1**: No path matches.
* **64**: The arguments are invalid or the expression is not valid.
* **66**: The directory does not exist.

#### Output on stdout

* NUL-separated matching paths.

### file::tree-with-contents

Write the directories and text files below a path, with the contents of each text file.

Directories are written as paths. Regular files whose MIME type is text/*
are written by file::_print-text; other files are skipped.

#### Example

```bash
file::tree-with-contents src 1 2 > context.txt
```

#### Arguments

* **$1** (string): Optional starting path. Defaults to the current directory.
* **$2** (integer): Optional minimum depth. Defaults to 1.
* **$3** (integer): Optional maximum depth. Unlimited when omitted.

#### Exit codes

* **0**: The tree was written.
* **64**: The arguments are invalid.
* **66**: The path does not exist.
* **69**: file is unavailable.
* other The status of the file that could not be written.

#### Output on stdout

* Directory paths and the contents of text files.

### net::tcp::test

Test whether a TCP connection to HOST and PORT succeeds, without output.

#### Example

```bash
  net::tcp::test github.com 22 5 && git::fetch
shellcheck disable=SC2329
```

#### Arguments

* **$1** (string): Host name or address.
* **$2** (integer): TCP port.
* **$3** (integer): Optional connection timeout in seconds. Defaults to 10.

#### Exit codes

* **0**: The connection succeeded.
* **1**: The connection failed.
* **64**: The arguments are invalid.
* **69**: nc is unavailable.

### serial::configure

Open a serial device with a configured baud rate.

#### Example

```bash
serial::configure /dev/ttyUSB0 9600
```

#### Arguments

* **$1** (string): Serial device.
* **$2** (integer): Optional baud rate. Defaults to 115200.

#### Exit codes

* **0**: The baud rate was set.
* **64**: The arguments are invalid or the device does not exist.
* **69**: stty is unavailable.
* other The status of stty.

### serial::write

Write literal data to a serial device.

#### Example

```bash
serial::write /dev/ttyUSB0 'AT'
```

#### Arguments

* **$1** (string): Serial device.
* **$2** (string): Data to write without a terminator.

#### Exit codes

* **0**: The data was written.
* **1**: The device could not be written.
* **64**: The argument count is not two or the device does not exist.

### serial::write-command

Write a command and terminator to a serial device.

#### Example

```bash
serial::write-command /dev/ttyUSB0 'AT+GMR' crlf 0.5
```

#### Arguments

* **$1** (string): Serial device.
* **$2** (string): Command to write.
* **$3** (string): Optional terminator: none, cr, lf, or crlf. Defaults to cr.
* **$4** (number): Optional seconds to wait after writing. Defaults to 0.

#### Exit codes

* **0**: The command was written.
* **64**: The arguments, terminator, or wait time are invalid.
* **74**: The device could not be written.

### screen::open-serial

Open a serial device in GNU Screen through administrator execution and log the session.

#### Example

```bash
TTY_LOG_DIR="${HOME}/logs" screen::open-serial /dev/ttyUSB0
```

#### Arguments

* **$1** (string): Serial device path.
* **$2** (integer): Optional baud rate. Defaults to 115200.
* **$3** (string): Optional log file. Defaults to a file named with the date and time in ${TTY_LOG_DIR:-.}.

#### Exit codes

* **0**: The session ended successfully.
* **64**: The arguments are invalid.
* **69**: screen is unavailable.
* **74**: The log directory could not be created.
* other The status of screen.

### screen::kill-all

End every GNU Screen process of every user through administrator execution.

Having no Screen process is a success.

#### Example

```bash
screen::kill-all
```

_Function has no arguments._

#### Exit codes

* **0**: No Screen process remains.
* **64**: An argument was given.
* **69**: pkill is unavailable.
* other The status of pkill.

### net::capture-host

Capture packets addressed to a host.

tcpdump is retried through sudo when it fails without administrator rights.

#### Example

```bash
net::capture-host 192.168.1.20 eth0
```

#### Arguments

* **$1** (string): Host name or address.
* **$2** (string): Optional interface. Defaults to any.

#### Exit codes

* **0**: The capture ended successfully.
* **64**: The argument count is not one or two.
* **69**: The capture failed and sudo is unavailable.
* other The status of tcpdump.

#### Output on stdout

* The packets that tcpdump captures.

### net::unused-port

Write a TCP port number the operating system reports as unused.

A socket is bound to port 0 on the loopback address, and the port the
system assigned is written before the socket closes.

#### Example

```bash
port="$(net::unused-port)" && python3 -m http.server "${port}"
```

_Function has no arguments._

#### Exit codes

* **0**: The port was written.
* **64**: An argument was given.
* **69**: perl is unavailable or the socket could not be bound.

#### Output on stdout

* The port number.

### serial::release

Release a serial device so another process, such as a Python tool, can open it.

The reference implementation called file-close on the device, which
killed every holder at once; this follows file::release instead: SIGTERM
first, SIGKILL only for holders left after the timeout.

#### Example

```bash
serial::release /dev/ttyACM0 && esptool.py --port /dev/ttyACM0 chip_id
```

#### Arguments

* **$1** (string): Serial device path.
* **$2** (integer): Optional seconds to wait after SIGTERM. Defaults to 2.

#### Exit codes

* **0**: No process holds the device.
* **64**: The arguments are invalid or the device does not exist.
* other The status of file::release.

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

### docker::container::list-running

List running Docker containers.

#### Example

```bash
docker::container::list-running
```

_Function has no arguments._

#### Exit codes

* **0**: The containers were written.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of docker ps.

#### Output on stdout

* The output of docker ps.

### docker::container::list

List Docker containers.

#### Example

```bash
docker::container::list
```

_Function has no arguments._

#### Exit codes

* **0**: The containers were written.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of docker ps.

#### Output on stdout

* The output of docker ps -a.

### docker::container::pull

Copy files between a Docker container and the host.

#### Example

```bash
docker::container::pull web /var/log/nginx ./logs
```

#### Arguments

* **$1** (string): Container name or ID.
* **$2** (string): Path in the container.
* **$3** (string): Optional host destination. Defaults to the current directory.

#### Exit codes

* **0**: The files were copied.
* **64**: The argument count is not two or three.
* **69**: docker is unavailable.
* other The status of docker cp.

### docker::container::push

Copy a host path into a container.

#### Example

```bash
docker::container::push web ./nginx.conf /etc/nginx/nginx.conf
```

#### Arguments

* **$1** (string): Container name or ID.
* **$2** (string): Path on the host.
* **$3** (string): Optional destination in the container. Defaults to its working directory.

#### Exit codes

* **0**: The files were copied.
* **64**: The argument count is not two or three.
* **69**: docker is unavailable.
* other The status of docker cp.

### docker::container::shell

Run an interactive shell or a command in a container.

Without COMMAND, Bash is used when the container has it and sh otherwise,
with a terminal attached. A COMMAND receives standard input without a
terminal, so it also works from scripts and CI.

#### Example

```bash
docker::container::shell web
docker::container::shell web nginx -t
```

#### Arguments

* **$1** (string): Container name or ID.
* **...** (string): Optional command and its arguments.

#### Exit codes

* **0**: The shell or command exited successfully.
* **64**: No container was given.
* **69**: docker is unavailable.
* other The status of docker exec.

### docker::container::logs

Follow the log of a container.

#### Example

```bash
docker::container::logs web
```

#### Arguments

* **$1** (string): Container name or ID.

#### Exit codes

* **0**: docker logs ended successfully.
* **64**: The argument count is not one.
* **69**: docker is unavailable.
* other The status of docker logs.

#### Output on stdout

* The container log, followed until interrupted.

### docker::container::stop

Stop a container.

#### Example

```bash
docker::container::stop web
```

#### Arguments

* **$1** (string): Container name or ID.

#### Exit codes

* **0**: The container stopped.
* **64**: The argument count is not one.
* **69**: docker is unavailable.
* other The status of docker stop.

### docker::container::start

Start a container.

#### Example

```bash
docker::container::start web
```

#### Arguments

* **$1** (string): Container name or ID.

#### Exit codes

* **0**: The container started.
* **64**: The argument count is not one.
* **69**: docker is unavailable.
* other The status of docker start.

### docker::container::stop-all

Stop every running container; having none is a success.

#### Example

```bash
docker::container::stop-all
```

_Function has no arguments._

#### Exit codes

* **0**: No container is running.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::container::remove-all

Remove every container, running or not.

#### Example

```bash
docker::container::remove-all
```

_Function has no arguments._

#### Exit codes

* **0**: No container remains.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::volume::remove-all

Remove every Docker volume.

#### Example

```bash
docker::volume::remove-all
```

_Function has no arguments._

#### Exit codes

* **0**: No volume remains.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::remove-all

Remove every container and then every volume, stopping at the first failure.

#### Example

```bash
docker::remove-all
```

_Function has no arguments._

#### Exit codes

* **0**: No container or volume remains.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### adb::device::wait

Wait for an ADB device to connect, optionally selected with --serial.

#### Example

```bash
adb::device::wait --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The device is connected.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb wait-for-device.

### adb::device::pull

Copy files from an ADB device to the host.

#### Example

```bash
adb::device::pull /sdcard/DCIM/Camera ./camera --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **...** (string): Device paths followed by an optional host destination.

#### Exit codes

* **0**: The files were copied.
* **64**: No path was given.
* **69**: adb is unavailable.
* other The status of adb pull.

### adb::device::push

Copy files from the host to an ADB device.

#### Example

```bash
adb::device::push app-debug.apk /data/local/tmp/
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **...** (string): Host paths followed by the device destination.

#### Exit codes

* **0**: The files were copied.
* **64**: No path was given.
* **69**: adb is unavailable.
* other The status of adb push.

### adb::logcat::clear

Clear the selected device log buffers.

#### Example

```bash
adb::logcat::clear --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The log buffers were cleared.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

### adb::logcat::once

Write the selected device log buffers once.

#### Example

```bash
adb::logcat::once > device.log
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The log was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

#### Output on stdout

* The current log buffers.

### adb::logcat::continuous

Stream logs from the selected device.

#### Example

```bash
adb::logcat::continuous | grep -i crash
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: adb logcat ended successfully.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb logcat.

#### Output on stdout

* The device log, streamed until interrupted.

### adb::device::reboot

Reboot the selected device.

The function returns after the device has disconnected and connected again.

#### Example

```bash
adb::device::reboot 120 --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (integer): Optional seconds to wait for the device to come back. Defaults to 60.

#### Exit codes

* **0**: The device rebooted and reconnected.
* **64**: The arguments are invalid.
* **69**: adb is unavailable.
* **74**: The clock or sleep failed.
* **75**: The device did not reconnect in time.
* other The status of adb reboot.

### adb::device::first

Write the first connected ADB device serial.

#### Example

```bash
serial="$(adb::device::first)"
```

_Function has no arguments._

#### Exit codes

* **0**: The serial was written.
* **1**: No device is connected.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb devices.

#### Output on stdout

* The serial of the first connected device.

### adb::device::list

List connected ADB device serials.

#### Example

```bash
adb::device::list
```

_Function has no arguments._

#### Exit codes

* **0**: The serials were written; there may be none.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb devices.

#### Output on stdout

* One serial per line for devices in the device state.

### adb::device::wait-for-path

Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout.

#### Example

```bash
adb::device::wait-for-path /sdcard/Download/report.json 60
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Path on the device.
* **$2** (integer): Optional seconds to wait. Defaults to 30.

#### Exit codes

* **0**: The path exists.
* **64**: The arguments are invalid.
* **74**: The clock or sleep failed.
* **75**: The path did not appear in time.

### adb::device::screen::capture-once

Save one screenshot atomically and print its path.

#### Example

```bash
adb::device::screen::capture-once ./screen.png --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional output PNG file. Defaults to ${WORK_DIR:-.}/STAMP/STAMP-adb-image.png.

#### Exit codes

* **0**: The screenshot was saved.
* **64**: The arguments are invalid.
* **74**: The file could not be written.
* **75**: The device returned no image.

#### Output on stdout

* The path of the saved screenshot.

### adb::device::select-and-pull

Select one requested device path and pull it to the host.

#### Example

```bash
adb::device::select-and-pull /sdcard/Download /sdcard/DCIM --output-directory ./device
```

#### Options

* **--output-directory \<DIRECTORY\>**

  Host directory to copy to. Defaults to the current directory.

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **...** (string): Device paths to choose from.

#### Exit codes

* **0**: The selected path was copied.
* **64**: No path was given or an option has no value.
* **74**: The output directory could not be created.
* other The status of the prompt or of adb pull.

### adb::device::bootloader::enter

Reboot the selected device into its bootloader.

#### Example

```bash
  adb::device::bootloader::enter --serial 0123456789ABCDEF
shellcheck disable=SC2329
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The device is rebooting into its bootloader.
* **64**: The arguments are invalid.
* **69**: adb is unavailable.
* other The status of adb reboot.

### adb::device::bootloader::unlock

Request bootloader unlocking and wait for the device to reconnect.

The unlock must be confirmed on the device. Unlocking erases user data.

#### Example

```bash
adb::device::bootloader::unlock --serial 0123456789ABCDEF
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The bootloader was unlocked and ADB reconnected.
* **64**: The arguments are invalid.
* **69**: fastboot or adb is unavailable.
* **74**: The clock or sleep failed.
* **75**: The device did not reach fastboot or ADB in time.
* other The status of the adb or fastboot command that failed.

### adb::device::verity::disable

Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects.

#### Example

```bash
adb::device::verity::disable && adb::device::partition::remount
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: dm-verity is disabled and ADB reconnected.
* **64**: The arguments are invalid.
* **74**: sleep failed.
* **75**: The device did not reconnect in time.
* other The status of the adb command that failed.

### adb::device::partition::remount

Make the system partitions of a rooted device writable.

adb root and adb remount run first, and the root file system is then
remounted read-write.

#### Example

```bash
adb::device::partition::remount --serial emulator-5554
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The partitions are writable.
* **64**: The arguments are invalid.
* **75**: The device did not reconnect in time.
* other The status of the adb command that failed.

### adb::device::build::fingerprint

Write the selected device build fingerprint.

#### Example

```bash
adb::device::build::fingerprint
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The value of ro.build.fingerprint.

### adb::device::build::date

Write the selected device build timestamp as Unix seconds.

#### Example

```bash
date -d "@$(adb::device::build::date)"
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The value of ro.build.date.utc.

### adb::device::slot::suffix

Write the selected device active slot suffix.

#### Example

```bash
adb::device::slot::suffix
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The value of ro.boot.slot_suffix, such as _a; empty on devices without slots.

### adb::device::build::kernel-version

Write the selected device kernel release.

#### Example

```bash
adb::device::build::kernel-version
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The value was written.
* **64**: --serial is repeated or has no value.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The output of uname -r on the device.

### adb::device::screen::capture-continuous

Save repeated screenshots; MAX_COUNT of zero runs until interrupted.

#### Example

```bash
adb::device::screen::capture-continuous ./frames 0.5 20
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional output directory. Defaults to ./screencap-loop.
* **$2** (number): Optional seconds between screenshots. Defaults to 1.
* **$3** (integer): Optional number of screenshots; 0 runs until interrupted. Defaults to 0.

#### Exit codes

* **0**: The requested screenshots were saved.
* **64**: The arguments are invalid.
* **74**: The directory could not be created or sleep failed.
* other The status of adb::device::screen::capture-once.

#### Output on stdout

* The path of each saved screenshot.

### adb::device::partition::sha256

Write a device partition SHA-256 checksum.

#### Example

```bash
adb::device::partition::sha256 /dev/block/by-name/boot_a
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Partition path below /dev/block.

#### Exit codes

* **0**: The checksum was written.
* **64**: The path or options are invalid.
* **69**: adb is unavailable.
* other The status of adb shell.

#### Output on stdout

* The output of sha256sum on the device.

### adb::wake::lock

Hold a kernel wake lock using a tag, defaulting to debug.

The device must allow adb root.

#### Example

```bash
adb::wake::lock benchmark
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional wake lock tag. Defaults to debug.

#### Exit codes

* **0**: The wake lock is held.
* **64**: The arguments are invalid.
* **69**: adb root is unavailable or /sys/power/wake_lock is not writable.
* other The status of the adb command that failed.

### adb::wake::unlock

Release a kernel wake lock using the same tag.

The device must allow adb root.

#### Example

```bash
adb::wake::unlock benchmark
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Arguments

* **$1** (string): Optional wake lock tag. Defaults to debug.

#### Exit codes

* **0**: The wake lock was released.
* **64**: The arguments are invalid.
* **69**: adb root is unavailable or /sys/power/wake_unlock is not writable.
* other The status of the adb command that failed.

### adb::wake::list

Print active kernel wake locks.

#### Example

```bash
adb::wake::list
```

#### Options

* **--serial \<SERIAL\>**

  Device serial. ADB chooses the device when omitted.

#### Exit codes

* **0**: The tags were written.
* **64**: The arguments are invalid.
* **69**: adb root is unavailable or /sys/power/wake_lock is not readable.
* other The status of the adb command that failed.

#### Output on stdout

* The active wake lock tags.

### process::ids-by-name

Write the IDs of the processes whose executable name is exactly NAME, one per line.

#### Example

```bash
process::ids-by-name sshd
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: At least one process matches.
* **1**: No process matches.
* **64**: The argument count is not one.
* **69**: pgrep is unavailable.

#### Output on stdout

* One process ID per line.

### process::ids-by-name-regex

Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f.

#### Example

```bash
process::ids-by-name-regex 'python3 .*manage\.py runserver'
```

#### Arguments

* **$1** (string): Extended regular expression matched against the full command line.

#### Exit codes

* **0**: At least one process matches.
* **1**: No process matches.
* **64**: The argument count is not one.
* **69**: pgrep is unavailable.

#### Output on stdout

* One process ID per line.

### process::threads-by-pid

Write the threads of one process.

Linux uses ps -T and macOS ps -M.

#### Example

```bash
process::threads-by-pid "$$"
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: The threads were written.
* **1**: No process has the ID.
* **64**: The argument is not one process ID.
* **69**: ps is unavailable or the operating system is unsupported.

#### Output on stdout

* The ps listing of the threads.

### process::threads-by-name

Write the threads of the first process whose executable name is NAME.

#### Example

```bash
process::threads-by-name java
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: The threads were written.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of process::threads-by-pid.

#### Output on stdout

* The ps listing of the threads.

### syscall::trace-by-pid

Attach strace to a process on Linux.

Administrator execution is used only when the process cannot be traced
with the current permissions.

#### Example

```bash
syscall::trace-by-pid "$(pgrep -x nginx | head -n 1)"
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: strace ended successfully.
* **64**: The argument is not one process ID.
* **69**: The system is not Linux or strace is unavailable.
* other The status of strace.

#### Output on stderr

* The system calls that strace reports.

### lib::trace-by-pid

Attach ltrace to a process on Linux.

Administrator execution is used only when the process cannot be traced
with the current permissions.

#### Example

```bash
lib::trace-by-pid 4242
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: ltrace ended successfully.
* **64**: The argument is not one process ID.
* **69**: The system is not Linux or ltrace is unavailable.
* other The status of ltrace.

#### Output on stderr

* The library calls that ltrace reports.

### gdb::attach-pid

Attach GDB in batch mode to a process and write the backtrace of every thread.

#### Example

```bash
gdb::attach-pid 4242 > backtrace.txt
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: The backtrace was written.
* **64**: The argument is not one process ID.
* **69**: gdb is unavailable.
* other The status of gdb.

#### Output on stdout

* The backtrace of every thread.

### gdb::server::start

Start COMMAND with its arguments under gdbserver listening on PORT.

#### Example

```bash
gdb::server::start 2345 ./build/app --verbose
```

#### Arguments

* **$1** (integer): TCP port to listen on.
* **$2** (string): Command to run.
* **...** (string): Optional arguments of the command.

#### Exit codes

* **0**: gdbserver ended successfully.
* **64**: The port or command is invalid.
* **69**: gdbserver is unavailable.
* other The status of gdbserver.

### gdb::connect

Load ELF in GDB and connect to the GDB server at HOST and PORT.

#### Example

```bash
gdb::connect ./build/app 192.168.1.50 2345
```

#### Arguments

* **$1** (string): ELF file with symbols.
* **$2** (string): Host of the GDB server.
* **$3** (integer): Port of the GDB server.

#### Exit codes

* **0**: GDB ended successfully.
* **64**: The arguments are invalid or the ELF file does not exist.
* **69**: gdb is unavailable.
* other The status of gdb.

### gdb::run-until

Run ELF in GDB with optional program arguments and stop at SYMBOL.

#### Example

```bash
gdb::run-until ./build/app parse_config --config test.ini
```

#### Arguments

* **$1** (string): ELF file to run.
* **$2** (string): Symbol or location to break at.
* **...** (string): Optional program arguments.

#### Exit codes

* **0**: GDB ended successfully.
* **64**: The ELF file does not exist or no symbol was given.
* **69**: gdb is unavailable.
* other The status of gdb.

### gdb::core::open

Open ELF and a core dump in GDB.

#### Example

```bash
gdb::core::open ./build/app core.4242
```

#### Arguments

* **$1** (string): ELF file that produced the core dump.
* **$2** (string): Core dump file.

#### Exit codes

* **0**: GDB ended successfully.
* **64**: The argument count is not two or a file does not exist.
* **69**: gdb is unavailable.
* other The status of gdb.

### device-tree::node::list

Write the node paths of the Linux device tree.

#### Example

```bash
device-tree::node::list | grep -i i2c
```

_Function has no arguments._

#### Exit codes

* **0**: The nodes were written.
* **64**: An argument was given.
* **66**: The system has no device tree.

#### Output on stdout

* One node path per line below /sys/firmware/devicetree/base.

### i2c::bus::list

Write the I2C buses with i2cdetect -l.

#### Example

```bash
i2c::bus::list
```

_Function has no arguments._

#### Exit codes

* **0**: The buses were written.
* **64**: An argument was given.
* **69**: i2cdetect is unavailable.
* other The status of i2cdetect.

#### Output on stdout

* The output of i2cdetect -l.

### i2c::device::list

Write the devices on one I2C bus with i2cdetect -y.

#### Example

```bash
i2c::device::list 1
```

#### Arguments

* **$1** (integer): I2C bus number.

#### Exit codes

* **0**: The devices were written.
* **64**: The argument is not one bus number.
* **69**: i2cdetect is unavailable.
* other The status of i2cdetect.

#### Output on stdout

* The address map that i2cdetect writes.

### gpio::chip::list

Write the GPIO chips with gpiodetect.

#### Example

```bash
gpio::chip::list
```

_Function has no arguments._

#### Exit codes

* **0**: The chips were written.
* **64**: An argument was given.
* **69**: gpiodetect is unavailable.
* other The status of gpiodetect.

#### Output on stdout

* The output of gpiodetect.

### gpio::line::list

Write the GPIO lines of one chip, or of every chip, with gpioinfo.

#### Example

```bash
gpio::line::list gpiochip0
```

#### Arguments

* **$1** (string): Optional chip name or number. Defaults to every chip.

#### Exit codes

* **0**: The lines were written.
* **64**: More than one argument was given.
* **69**: gpioinfo is unavailable.
* other The status of gpioinfo.

#### Output on stdout

* The output of gpioinfo.

### usb::device::list

Write the USB devices with lsusb.

#### Example

```bash
usb::device::list
```

_Function has no arguments._

#### Exit codes

* **0**: The devices were written.
* **64**: An argument was given.
* **69**: lsusb is unavailable.
* other The status of lsusb.

#### Output on stdout

* The output of lsusb.

### pci::device::list

Write the PCI devices with lspci.

#### Example

```bash
pci::device::list
```

_Function has no arguments._

#### Exit codes

* **0**: The devices were written.
* **64**: An argument was given.
* **69**: lspci is unavailable.
* other The status of lspci.

#### Output on stdout

* The output of lspci.

### asciidoc::html

Convert AsciiDoc to HTML with diagram support.

#### Example

```bash
asciidoc::html docs/design.adoc build/html
```

#### Arguments

* **$1** (string): AsciiDoc file.
* **$2** (string): Optional directory for the HTML. Defaults to the current directory.

#### Exit codes

* **0**: The HTML was written.
* **64**: The arguments are invalid or the file does not exist.
* **69**: asciidoctor is unavailable.
* other The status of asciidoctor.

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

### systemd::file

Write the path of the file that defines a systemd unit.

#### Example

```bash
systemd::file ssh.service
```

#### Arguments

* **$1** (string): Unit name, such as ssh.service.

#### Exit codes

* **0**: The path was written.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The path of the unit file; empty for a unit without a file.

### systemd::dependencies

Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines.

#### Example

```bash
systemd::dependencies docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The dependencies were written.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* After=, Requires=, and Wants= lines.

### systemd::restart

Restart a systemd unit through administrator execution.

#### Example

```bash
systemd::restart nginx.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was restarted.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::start

Start a systemd unit through administrator execution.

#### Example

```bash
systemd::start docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was started.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::stop

Stop a systemd unit through administrator execution.

#### Example

```bash
systemd::stop docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was stopped.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::enable

Enable a systemd unit at boot through administrator execution.

#### Example

```bash
systemd::enable ssh.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was enabled.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::disable

Disable a systemd unit at boot through administrator execution.

#### Example

```bash
systemd::disable cups.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was disabled.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::status

Write the current state of a systemd unit and return the status of systemctl status.

#### Example

```bash
systemd::status ssh.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit is active.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl status, such as **3**: for an inactive unit.

#### Output on stdout

* The output of systemctl status.

### systemd::service::list

Write every loaded systemd service, including stopped ones.

#### Example

```bash
systemd::service::list
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The output of systemctl list-units --type=service.

### systemd::service::list-running

Write the running systemd services.

#### Example

```bash
systemd::service::list-running
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The running services.

### systemd::service::list-failed

Write the failed systemd services.

#### Example

```bash
systemd::service::list-failed
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The failed services.

### systemd::service::list-files

Write every systemd service unit file and its enablement state.

#### Example

```bash
systemd::service::list-files | grep enabled
```

_Function has no arguments._

#### Exit codes

* **0**: The files were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The service unit files and their states.

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

### user::directory::create-english-links

Link the English XDG user directory names to the directories of the current locale.

Each standard XDG directory is resolved with xdg-user-dir. A localized
directory that does not exist is skipped and never created. An existing
English directory is merged into the localized one, overwriting entries
with the same name, and then replaced by the link.

#### Example

```bash
user::directory::create-english-links
```

#### Arguments

* **$1** (string): Optional home directory to update. Defaults to $HOME.

#### Exit codes

* **0**: Every link was created or already existed.
* **64**: More than one argument was given.
* **66**: The home directory does not exist.
* **69**: xdg-user-dir is unavailable.
* **73**: An English name is held by something other than a directory or link.
* **74**: A directory could not be resolved, removed, or linked.
* other The status of directory::merge.

#### Output on stderr

* A message for each English name that is not a directory.

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
* **69**: perl, or both android and sdkmanager, are unavailable.
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

### go::version::list

Write the stable Go versions the platform package source offers, oldest first.

Ubuntu lists the versioned golang-X.Y packages, Fedora the golang package,
and macOS the Homebrew go formulae. Each value is accepted by go::install.

#### Example

```bash
go::version::list
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **1**: No version was found.
* **64**: An argument was given.
* **69**: The platform or its package tool is unsupported or unavailable.
* other The status of the package query that failed.

#### Output on stdout

* One version per line, oldest first.

### go::version::latest

Write the newest stable Go version from go::version::list.

#### Example

```bash
go::install "$(go::version::latest)"
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **1**: No version was found.
* **64**: An argument was given.
* other The status of go::version::list.

#### Output on stdout

* The newest version, such as 1.23.

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

### rosetta::install

Install Rosetta on Apple silicon when it is missing, accepting its license.

Intel Macs and Macs that already run x86_64 code succeed without changes.

#### Example

```bash
rosetta::install
```

_Function has no arguments._

#### Exit codes

* **0**: Rosetta is installed or not needed.
* **64**: An argument was given.
* **69**: The system is not macOS or softwareupdate is unavailable.
* other The status of softwareupdate.

### net::dns::servers

Write the configured IPv4 and IPv6 DNS servers, one per line.

Linux uses the servers of systemd-resolved when resolvectl answers, and
otherwise the nameserver lines of /etc/resolv.conf. macOS uses scutil --dns.

#### Example

```bash
net::dns::servers
```

_Function has no arguments._

#### Exit codes

* **0**: The servers were written.
* **64**: An argument was given.
* **66**: /etc/resolv.conf cannot be read.
* **69**: The operating system is unsupported or scutil is unavailable.
* **74**: scutil failed.

#### Output on stdout

* One server address per line without duplicates.

### utm::open

Open the UTM application on macOS.

#### Example

```bash
utm::open
```

_Function has no arguments._

#### Exit codes

* **0**: UTM was opened.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of open.

### mozc::config::open

Open the Mozc settings dialog on a Linux desktop.

#### Example

```bash
mozc::config::open
```

_Function has no arguments._

#### Exit codes

* **0**: The dialog was closed.
* **64**: An argument was given.
* **69**: mozc_tool is unavailable.
* other The status of mozc_tool.

### archive::extract

Extract one archive, or every recognized archive below a directory, next to itself.

#### Example

```bash
archive::extract "${HOME}/Downloads"
```

#### Arguments

* **$1** (string): Optional archive file or directory to search. Defaults to the current directory.

#### Exit codes

* **0**: Every archive was extracted.
* **64**: More than one argument was given.
* **66**: The directory does not exist or cannot be searched.
* **74**: The temporary list could not be created.
* other The status of archive::extract-file for the first archive that failed.

### syscall::trace-by-name

Attach strace to the first process whose executable name is NAME.

#### Example

```bash
syscall::trace-by-name nginx
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: strace ended successfully.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of syscall::trace-by-pid.

#### Output on stderr

* The system calls that strace reports.

### lib::trace-by-name

Attach ltrace to the first process whose executable name is NAME.

#### Example

```bash
lib::trace-by-name myapp
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: ltrace ended successfully.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of lib::trace-by-pid.

#### Output on stderr

* The library calls that ltrace reports.

### gdb::attach-by-name

Attach GDB to the first process whose executable name is NAME.

#### Example

```bash
gdb::attach-by-name myapp > backtrace.txt
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: The backtrace was written.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of gdb::attach-pid.

#### Output on stdout

* The backtrace of every thread.

### jenkins::restart

Restart the Jenkins service through administrator execution.

#### Example

```bash
jenkins::restart
```

_Function has no arguments._

#### Exit codes

* **0**: Jenkins was restarted.
* **64**: An argument was given.
* other The status of systemd::restart.

### sudo::start-keep-alive

Keep the sudo credentials of the calling process fresh in the background.

sudo is authenticated once, and a background process renews the
credentials every 60 seconds until the calling process exits.

#### Example

```bash
sudo::start-keep-alive && go::install && rust::install
```

_Function has no arguments._

#### Exit codes

* **0**: The credentials are fresh and the renewal runs in the background.
* **64**: An argument was given.
* **69**: sudo is unavailable.
* **77**: sudo authentication failed.

### sudo::passwordless::enable

Let a user run every command through sudo without entering a password.

The rule `USER ALL=(ALL) NOPASSWD: ALL` is written to its own file in
/etc/sudoers.d without opening an editor. visudo checks the rule before it
is installed and the whole configuration afterwards. sudo applies the last
matching rule, so the file name sorts after other drop-in files, and the
main sudoers file of macOS, Ubuntu, and Fedora reads the directory after
its group rules. If sudo still asks the user for a password, the file is
removed and the function fails. Running it again rewrites the same file.

#### Example

```bash
sudo::passwordless::enable "$(id -un)"
```

#### Arguments

* **$1** (string): Optional login name. Defaults to the user who invoked sudo, or the current user.

#### Exit codes

* **0**: The user can run sudo without a password.
* **64**: More than one argument was given or the user does not exist.
* **69**: sudo still asks for a password; the file was removed.
* **74**: The rule could not be written, checked, or installed.
* other The status of the user lookup.

#### Output on stderr

* A message when the user does not exist or sudo does not apply the rule.

### sudo::passwordless::disable

Remove the passwordless sudo rule that sudo::passwordless::enable added.

Only the BashStock drop-in file of the user is removed, so sudo asks for
the password again unless another sudoers rule also grants NOPASSWD. The
function succeeds when the file does not exist.

#### Example

```bash
sudo::passwordless::disable
```

#### Arguments

* **$1** (string): Optional login name. Defaults to the user who invoked sudo, or the current user.

#### Exit codes

* **0**: The rule file does not exist.
* **64**: More than one argument was given.
* **74**: The file could not be removed.
* other The status of the user lookup.

### storage::clear-trash

Empty the Linux desktop trash of the current user through administrator execution.

The entries directly under Trash/files and Trash/info are removed.

#### Example

```bash
storage::clear-trash
```

_Function has no arguments._

#### Exit codes

* **0**: The trash is empty.
* **64**: An argument was given.
* **69**: The system is not Linux.
* **74**: An entry could not be removed.

### usb::partition::select

Select a USB partition, or a USB disk without partitions, and write its device path.

One candidate is selected automatically; several are offered for
interactive selection with their size, file system, and label.

#### Example

```bash
device="$(usb::partition::select)"
```

_Function has no arguments._

#### Exit codes

* **0**: The path was written.
* **1**: No USB block device is connected.
* **64**: An argument was given.
* other The status of lsblk or the prompt.

#### Output on stdout

* The device path, such as /dev/sdb1.

### usb::filesystem::repair

Select a USB file system, unmount it, and repair it through administrator execution.

FAT uses fsck.fat -a, exFAT fsck.exfat -a, and other types fsck -y.

#### Example

```bash
usb::filesystem::repair
```

_Function has no arguments._

#### Exit codes

* **0**: The file system was repaired or is clean.
* **1**: No USB block device is connected.
* **64**: An argument was given.
* **74**: The file system type could not be read.
* other The status of the unmount or of fsck.

### usb::filesystem::format-fat32

Select a USB partition, unmount it, and format it as FAT32 through administrator execution.

Everything on the selected partition is erased.

#### Example

```bash
usb::filesystem::format-fat32
```

_Function has no arguments._

#### Exit codes

* **0**: The partition was formatted.
* **1**: No USB block device is connected.
* **64**: An argument was given.
* other The status of the unmount or of mkfs.vfat.

### git::rebase-base-branch

Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one.

#### Example

```bash
git::rebase-base-branch develop origin
```

#### Arguments

* **$1** (string): Optional base branch. Defaults to main.
* **$2** (string): Optional remote. Defaults to upstream.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was rebased.
* **64**: More than three arguments were given.
* other The status of the git command that failed.

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

### selinux::generate-rule

Generate SELinux allow rules from the AVC denials of an audit log.

#### Example

```bash
selinux::generate-rule /var/log/audit/audit.log ./allow.te
```

#### Arguments

* **$1** (string): Audit log, such as /var/log/audit/audit.log.
* **$2** (string): Optional rule file. Defaults to selinux.txt next to the audit log.

#### Exit codes

* **0**: The rules were written.
* **1**: The log has no AVC denial.
* **64**: The arguments are invalid or the log does not exist.
* **69**: audit2allow is unavailable.
* other The status of audit2allow.

#### Output on stderr

* A message when the log has no AVC denial.

### terminal::gnome-bash

Start an interactive Bash in a new GNOME Terminal window.

When COMMAND is given, it runs with its arguments first, and the
interactive shell starts after it ends.

#### Example

```bash
terminal::gnome-bash make watch
```

#### Arguments

* **...** (string): Optional command and arguments to run before the interactive shell.

#### Exit codes

* **0**: GNOME Terminal opened the window.
* **69**: gnome-terminal is unavailable.
* other The status of gnome-terminal.

### shell::editor::set-default

Set the default editor of new Bash and Zsh sessions and the current process.

#### Example

```bash
shell::editor::set-default vim bash,zsh
```

#### Arguments

* **$1** (string): Optional editor command. Defaults to code --wait.
* **$2** (string): Optional comma-separated shells, bash and zsh. Defaults to bash.

#### Variables set

* **EDITOR** (is): exported in the current process.

#### Exit codes

* **0**: The editor was set.
* **64**: More than two arguments were given or the shell list is invalid.
* other The status of env::set-variable.

### plist::set

Set a string value for one top-level key in a macOS property list.

The file is created as an empty dictionary when it does not exist and is
validated with plutil before and after the change.

#### Example

```bash
plist::set "${HOME}/Library/Preferences/com.example.app.plist" Theme dark
```

#### Arguments

* **$1** (string): Property list file. A symbolic link is refused.
* **$2** (string): Top-level key without a dot.
* **$3** (string): String value.

#### Exit codes

* **0**: The value was written.
* **64**: The arguments are invalid.
* **65**: The file is not a valid property list.
* **66**: The path is not a regular file.
* **69**: plutil is unavailable.
* **74**: The file could not be created or changed.

### textproto::set-scalar

Replace or append one top-level scalar field in a textproto file.

The file is read with its comments, quoted strings, and nested messages
taken into account, so only a FIELD at the top level is changed. An
existing field line is replaced; a missing field is appended. A field that
occurs more than once at the top level, a field that holds a message, and
unbalanced braces or strings in the result return 65 without a change.

#### Example

```bash
textproto::set-scalar config.textproto timeout_seconds 30
textproto::set-scalar config.textproto name '"production"'
```

#### Arguments

* **$1** (string): Existing textproto file. A symbolic link is refused.
* **$2** (string): Field name.
* **$3** (string): Literal scalar value on one line, quoted when it is a string.

#### Exit codes

* **0**: The field was written.
* **64**: The arguments are invalid.
* **65**: The field is ambiguous or holds a message, or the file is unbalanced.
* **66**: The file cannot be read.
* **69**: perl is unavailable.
* other The status of file::write-text.

### shell::completion::enable-ignore-case

Make Bash and Zsh completion ignore letter case.

Bash reads the setting from $HOME/.inputrc. A new .inputrc first includes
/etc/inputrc, because Readline stops reading the system file once a
personal one exists. Zsh receives a matcher-list zstyle in $HOME/.zshrc.

#### Example

```bash
shell::completion::enable-ignore-case bash
```

#### Arguments

* **$1** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the shell list is invalid.
* other The status of the file operation that failed.

### git::credentials::remove

Remove $HOME/.git-credentials and the global credential.helper; both may be absent.

#### Example

```bash
git::credentials::remove
```

_Function has no arguments._

#### Exit codes

* **0**: Neither the file nor the helper remains.
* **64**: An argument was given.
* other The status of git config or rm.

### git::config::enable-origin-all-fetch

Make origin fetch every branch in a repository.

#### Example

```bash
git::config::enable-origin-all-fetch && git::fetch origin
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The refspec was set.
* **64**: More than one argument was given.
* other The status of git config.

### git::config::enable-prune-fetch

Enable pruning on fetch in the global Git configuration.

#### Example

```bash
git::config::enable-prune-fetch
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git::config::set-default-branch

Set the default branch name of new repositories.

#### Example

```bash
git::config::set-default-branch trunk
```

#### Arguments

* **$1** (string): Optional branch name. Defaults to main.

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the name is not a valid branch name.
* other The status of git config.

### git::config::enable-rebase-on-pull

Enable rebase on pull in the global Git configuration.

#### Example

```bash
git::config::enable-rebase-on-pull
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git::config::set-email

Set the global Git email address.

#### Example

```bash
git::config::set-email developer@example.com
```

#### Arguments

* **$1** (string): Optional email address. Defaults to GIT_EMAIL, then to input from the controlling terminal.

#### Exit codes

* **0**: The address was set, or an existing one was kept.
* **64**: More than one argument was given or the value has several lines.
* **66**: No address is available and none is configured.
* **74**: The terminal could not be read.
* other The status of git config.

### git::config::set-username

Set the global Git user name.

#### Example

```bash
git::config::set-username 'Alex Example'
```

#### Arguments

* **$1** (string): Optional display name. Defaults to GIT_USERNAME, then to input from the controlling terminal.

#### Exit codes

* **0**: The name was set, or an existing one was kept.
* **64**: More than one argument was given or the value has several lines.
* **66**: No name is available and none is configured.
* **74**: The terminal could not be read.
* other The status of git config.

### git::config::set-http-buffer

Set the global Git HTTP post buffer.

#### Example

```bash
git::config::set-http-buffer 1048576000
```

#### Arguments

* **$1** (integer): Optional buffer size in bytes. Defaults to 524288000 (500 MiB).

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the size is not an integer.
* other The status of git config.

### git::config::use-gpg-credential-store

Make Git Credential Manager store credentials with GPG and pass.

The guidance for initializing the pass store is written to standard error.

#### Example

```bash
git::config::use-gpg-credential-store && pass::store::init
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

#### Output on stderr

* How to initialize the pass store.

### git::config::use-credential-manager

Use Git Credential Manager as the global credential helper.

#### Example

```bash
git-credential-manager::install && git::config::use-credential-manager
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### pass::store::remove

Remove a pass store and everything in it.

#### Example

```bash
pass::store::remove "${HOME}/.password-store-old"
```

#### Arguments

* **$1** (string): Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.

#### Exit codes

* **0**: The store was removed.
* **64**: More than one argument was given, or the directory is / or a symbolic link.
* **66**: The store does not exist.
* **74**: The store could not be removed.

### pass::store::init

Initialize a pass store for a GPG key without removing an existing store.

#### Example

```bash
pass::store::init "$(gpg::secret-key::fingerprints | head -n 1)"
```

#### Arguments

* **$1** (string): Optional GPG key fingerprint. Defaults to the first secret key.
* **$2** (string): Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.

#### Exit codes

* **0**: The store was initialized.
* **1**: No fingerprint was given and no secret key exists.
* **64**: More than two arguments were given.
* **69**: pass is unavailable.
* other The status of pass init.

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

### ssh::key::generate-rsa4096

Generate a 4096-bit RSA SSH key and write its public key.

An existing key is replaced only after confirmation on the controlling
terminal; without a terminal it is kept and 73 is returned. The old key
stays in place until the new key has been generated.

#### Example

```bash
ssh::key::generate-rsa4096 --comment 'build server' --output "${HOME}/.ssh/build_rsa"
```

#### Options

* **--comment \<COMMENT\>**

  Key comment. Defaults to an empty comment.

* **--output \<FILE\>**

  Private key path. Defaults to $HOME/.ssh/id_rsa.

* **--passphrase-fd \<FD\>**

  File descriptor to read the passphrase from. Defaults to no passphrase.

#### Exit codes

* **0**: The key was generated.
* **64**: An option is unknown or has an invalid value.
* **66**: The passphrase could not be read.
* **69**: ssh-keygen is unavailable.
* **73**: The key exists and was kept.
* **74**: The directory or the temporary key could not be created, or the new key could not replace the old one.
* other The status of ssh-keygen.

#### Output on stdout

* The public key.

### ssh::key::generate-ed25519

Generate an Ed25519 SSH key and write its public key.

An existing key is replaced only after confirmation on the controlling
terminal; without a terminal it is kept and 73 is returned. The old key
stays in place until the new key has been generated.

#### Example

```bash
ssh::key::generate-ed25519 --comment "$(id -un)@$(hostname)" --passphrase-fd 3 3<passphrase.txt
```

#### Options

* **--comment \<COMMENT\>**

  Key comment. Defaults to an empty comment.

* **--output \<FILE\>**

  Private key path. Defaults to $HOME/.ssh/id_ed25519.

* **--passphrase-fd \<FD\>**

  File descriptor to read the passphrase from. Defaults to no passphrase.

#### Exit codes

* **0**: The key was generated.
* **64**: An option is unknown or has an invalid value.
* **66**: The passphrase could not be read.
* **69**: ssh-keygen is unavailable.
* **73**: The key exists and was kept.
* **74**: The directory or the temporary key could not be created, or the new key could not replace the old one.
* other The status of ssh-keygen.

#### Output on stdout

* The public key.

### ssh::kill-all

End every SSH process of the current user.

#### Example

```bash
ssh::kill-all
```

_Function has no arguments._

#### Exit codes

* **0**: At least one SSH process was signaled.
* **1**: No SSH process was running.
* **64**: An argument was given.
* **69**: pkill is unavailable.

### git::config::use-osx-keychain

Use the macOS Keychain as the global Git credential helper.

#### Example

```bash
git::config::use-osx-keychain
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of git config.

### git-credential-manager::version::list

Write the installed Git Credential Manager version.

#### Example

```bash
git-credential-manager::version::list
```

_Function has no arguments._

#### Exit codes

* **0**: The version was written.
* **64**: An argument was given.
* **69**: git-credential-manager is unavailable.
* other The status of git-credential-manager.

#### Output on stdout

* The installed version.

### git-credential-manager::install

Install an official Git Credential Manager release for this OS and CPU.

Each release is built for a minimum C library: 3.0 needs glibc 2.34, so
Ubuntu 18.04 and 20.04 run 2.9. On Linux the ICU library is installed
first, because the program does not start without it. Without VERSION, releases are tried from
the newest until one starts on this system. A requested VERSION that does
not start returns 69 without installing anything.

#### Example

```bash
git-credential-manager::install 2.6.1
```

#### Arguments

* **$1** (string): Optional major.minor.patch release. Defaults to the newest release that starts.

#### Exit codes

* **0**: Git Credential Manager was installed and configured.
* **64**: More than one argument was given or the version is malformed.
* **69**: The platform or CPU is unsupported, or no release starts.
* **74**: A download or file operation failed.
* other The status of the step that failed.

#### Output on stderr

* A message when no release starts on this system.

### git::config::setup

Apply the user identity and the standard global Git settings.

#### Example

```bash
git::config::setup developer@example.com 'Alex Example'
```

#### Arguments

* **$1** (string): Optional email address passed to git::config::set-email.
* **$2** (string): Optional display name passed to git::config::set-username.

#### Exit codes

* **0**: Every setting was applied.
* **64**: More than two arguments were given.
* other The status of the setting that failed.

### go::repository::register

Register the official Go package source for the current platform.

Go comes from the distribution or Homebrew, so this only checks that the package tool is available.

#### Example

```bash
go::repository::register
```

_Function has no arguments._

#### Exit codes

* **0**: The package source is available.
* **64**: An argument was given.
* **69**: The platform is unsupported or its package tool is unavailable.

### go::install

Install Go from the platform package source.

#### Example

```bash
go::install "$(go::version::latest)"
```

#### Arguments

* **$1** (string): Optional version from go::version::list. Defaults to the package source default.

#### Exit codes

* **0**: Go was installed.
* **64**: More than one argument was given.
* **69**: The platform is unsupported or the version is not offered.
* other The status of the package installation.

### rust::install

Install Rust using rustup and an optional toolchain version.

#### Example

```bash
rust::install 1.81.0
```

#### Arguments

* **$1** (string): Optional toolchain, such as 1.81.0 or nightly. Defaults to stable.

#### Exit codes

* **0**: Rust was installed and $HOME/.cargo/bin was added to PATH.
* **64**: More than one argument was given.
* **69**: curl or a C compiler is unavailable, or the platform is unsupported.
* **74**: rustup could not be downloaded.
* other The status of the rustup installer.

### rust::versions

Write the stable Rust versions, oldest first, from the rust-lang/rust releases.

#### Example

```bash
rust::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **1**: No version was found.
* **64**: An argument was given.
* other The status of the GitHub query.

#### Output on stdout

* One version per line, oldest first.

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

### jfrog::config::clear

Remove one JFrog CLI server configuration.

#### Example

```bash
jfrog::config::clear artifactory-prod
```

#### Arguments

* **$1** (string): Server ID.

#### Exit codes

* **0**: The configuration was removed.
* **64**: The argument count is not one.
* **69**: jf is unavailable.
* other The status of jf config remove.

### jfrog::config::clear-all

Remove every JFrog CLI server configuration.

#### Example

```bash
jfrog::config::clear-all
```

_Function has no arguments._

#### Exit codes

* **0**: Every configuration was removed.
* **64**: An argument was given.
* **69**: jf is unavailable.
* other The status of jf config clean.

### jfrog::config::list

Display JFrog CLI server configurations.

#### Example

```bash
jfrog::config::list
```

_Function has no arguments._

#### Exit codes

* **0**: The configurations were written.
* **64**: An argument was given.
* **69**: jf is unavailable.
* other The status of jf config show.

#### Output on stdout

* The output of jf config show.

### jfrog::setup

Register and verify a JFrog CLI server.

The access token is read from JFROG_ACCESS_TOKEN and passed to jf on standard input, never as an argument.

#### Example

```bash
JFROG_ACCESS_TOKEN="$(pass show jfrog/token)" jfrog::setup prod https://example.jfrog.io builder
```

#### Arguments

* **$1** (string): Server ID.
* **$2** (string): Platform URL, such as https://example.jfrog.io.
* **$3** (string): User name.

#### Exit codes

* **0**: The server was registered and answered ping.
* **64**: An argument is empty or JFROG_ACCESS_TOKEN is unset.
* **69**: jf is unavailable.
* other The status of jf config add or jf rt ping.

### opencode::install

Install the newest OpenCode command-line application.

macOS uses the Homebrew tap. Linux installs the official opencode-ai npm
package into $HOME/.local; its installer picks the build for the CPU and C
library, and the glibc builds run on Ubuntu 18.04 and later. Linux needs
npm: the Ubuntu nodejs package does not provide it, so install Node.js with
`node::install VERSION official` first there.

#### Example

```bash
opencode::install
```

_Function has no arguments._

#### Exit codes

* **0**: OpenCode was installed.
* **64**: An argument was given.
* **69**: npm is unavailable.
* **74**: $HOME/.local could not be created.
* other The status of the installation.

#### Output on stdout

* The installed version.

### docker::login-artifactory

Log in to an Artifactory Docker registry using a token on standard input.

The token is passed to docker on standard input, never as an argument.

#### Example

```bash
docker::login-artifactory example.jfrog.io builder "$(pass show jfrog/token)"
```

#### Arguments

* **$1** (string): Registry host.
* **$2** (string): User name.
* **$3** (string): Access token.

#### Exit codes

* **0**: The login succeeded.
* **64**: The argument count is not three or an argument is empty.
* **69**: docker is unavailable.
* other The status of docker login.

### chrome::profile::export-bookmarks

Export a Chrome profile's Bookmarks file.

#### Example

```bash
chrome::profile::export-bookmarks "${HOME}/.config/google-chrome/Default" backup/bookmarks.json
```

#### Arguments

* **$1** (string): Chrome profile directory.
* **$2** (string): Optional output file. Defaults to ./bookmarks.json.

#### Exit codes

* **0**: The file was copied.
* **64**: The arguments are invalid or the profile is not a directory.
* **66**: The profile has no Bookmarks file.
* other The status of cp.

### chrome::profile::export-preferences

Export a Chrome profile's Preferences file.

#### Example

```bash
chrome::profile::export-preferences "${HOME}/.config/google-chrome/Profile 1"
```

#### Arguments

* **$1** (string): Chrome profile directory.
* **$2** (string): Optional output file. Defaults to ./preferences.json.

#### Exit codes

* **0**: The file was copied.
* **64**: The arguments are invalid or the profile is not a directory.
* **66**: The profile has no Preferences file.
* other The status of cp.

### chrome::profile::email

Write the first known email address from a Chrome profile.

#### Example

```bash
chrome::profile::email "${HOME}/.config/google-chrome/Default"
```

#### Arguments

* **$1** (string): Chrome profile directory.

#### Exit codes

* **0**: The address was written.
* **1**: The profile has no email address.
* **64**: The argument is not a profile with a Preferences file.
* **69**: jq is unavailable.
* **74**: Preferences could not be read.

#### Output on stdout

* The email address.

### chrome::profile::find-by-email

Find Chrome profiles whose known email matches literally.

#### Example

```bash
chrome::profile::find-by-email developer@example.com
```

#### Arguments

* **$1** (string): Email address.
* **$2** (string): Optional Chrome user data directory. Defaults to the standard directory of the platform.

#### Exit codes

* **0**: At least one profile matches.
* **1**: No profile matches.
* **64**: The arguments are invalid.
* **66**: The user data directory does not exist.

#### Output on stdout

* One matching profile directory per line.

### swap::ensure-total-size

Extend swap capacity up to a target size.

#### Example

```bash
swap::ensure-total-size 8589934592
```

#### Arguments

* **$1** (integer): Target total swap size in bytes.
* **$2** (integer): Optional largest size to add in bytes. Defaults to the target.
* **$3** (string): Optional swap file path for the addition. Defaults to /swapfile.

#### Exit codes

* **0**: The swap capacity reaches the target, or the allowed addition was made.
* **64**: The arguments are invalid.
* other The status of mem::swap-total-bytes or swap::create.

### vscode::remove-user-data

Remove the VS Code user data directory.

VS Code is not checked for running instances.

#### Example

```bash
vscode::remove-user-data
```

#### Arguments

* **$1** (string): Optional directory to remove. Defaults to the standard user data directory.

#### Exit codes

* **0**: The directory was removed.
* **64**: More than one argument was given.
* **66**: The directory does not exist, is /, or is a symbolic link.
* **74**: The directory could not be removed.

### adb::device::set-default

Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL.

#### Example

```bash
adb::device::set-default "$(adb::device::first)"
```

#### Arguments

* **$1** (string): Device serial.

#### Variables set

* **ANDROID_SERIAL** (is): exported in the current shell.

#### Exit codes

* **0**: The variable was set.
* **64**: The argument is not one valid serial.

### adb::server::start

Start the host ADB server.

#### Example

```bash
adb::server::start
```

_Function has no arguments._

#### Exit codes

* **0**: The server is running.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb start-server.

### adb::server::stop

Stop the host ADB server.

#### Example

```bash
adb::server::stop
```

_Function has no arguments._

#### Exit codes

* **0**: The server stopped.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb kill-server.

### adb::server::restart

Stop and then start the host ADB server.

#### Example

```bash
adb::server::restart
```

_Function has no arguments._

#### Exit codes

* **0**: The server was restarted.
* **64**: An argument was given.
* **69**: adb is unavailable.
* other The status of adb.

### git::stash::list

List stashes.

#### Example

```bash
git::stash::list
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stashes were written.
* **64**: More than one argument was given.
* other The status of git stash.

#### Output on stdout

* The output of git stash list.

### file::modified-time-unix-seconds

Write the last modification time of a file as Unix seconds.

#### Example

```bash
file::modified-time-unix-seconds /etc/hosts
```

#### Arguments

* **$1** (string): File or symbolic link.

#### Exit codes

* **0**: The time was written.
* **64**: The argument count is not one or the path is empty.
* **66**: The path does not exist.
* **69**: stat is unavailable or the operating system is unsupported.
* **74**: stat failed.

#### Output on stdout

* The modification time in seconds since 1970-01-01 UTC.

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

### net::dns::manager

Write the current DNS manager: systemd-resolved, network-manager, or unknown.

#### Example

```bash
[[ "$(net::dns::manager)" == systemd-resolved ]] && resolvectl status
```

_Function has no arguments._

#### Exit codes

* **0**: The manager was written.
* **64**: An argument was given.

#### Output on stdout

* systemd-resolved, network-manager, or unknown.

### net::dns::use-systemd-resolved

Make systemd-resolved manage DNS and /etc/resolv.conf.

The previous /etc/resolv.conf is kept as a backup.

#### Example

```bash
net::dns::use-systemd-resolved
```

_Function has no arguments._

#### Exit codes

* **0**: systemd-resolved manages DNS.
* **64**: An argument was given.
* **74**: /etc/resolv.conf could not be linked.
* other The status of the service, backup, or verification step that failed.

### net::dns::use-network-manager

Make NetworkManager manage DNS and /etc/resolv.conf directly.

The previous /etc/resolv.conf is kept as a backup.

#### Example

```bash
net::dns::use-network-manager
```

_Function has no arguments._

#### Exit codes

* **0**: NetworkManager manages DNS.
* **64**: An argument was given.
* **69**: NetworkManager is unavailable.
* **74**: The configuration or link could not be written.
* other The status of the restart, backup, or verification step that failed.

### net::dns::use-google

Configure Google Public DNS while keeping the current DNS manager.

systemd-resolved receives a drop-in file, and NetworkManager receives the servers on every active connection. IPv6 servers are added only to connections with IPv6 configured.

#### Example

```bash
net::dns::use-google && net::dns::servers
```

_Function has no arguments._

#### Exit codes

* **0**: Google Public DNS is in use.
* **64**: An argument was given.
* **69**: The DNS manager is unknown or NetworkManager has no active connection.
* **74**: A configuration could not be written.
* **75**: A connection could not be reactivated.
* other The status of the restart or verification step that failed.

#### Output on stderr

* A message when the DNS manager is unknown.

