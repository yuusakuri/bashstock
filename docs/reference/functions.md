# 関数リファレンス

BashStockが公開する関数を名前空間ごとに示します。
各関数の引数、出力、終了状態、例は、名前空間のページと`help::show 関数名`で確認できます。
このファイルと`modules/`は`scripts/docs`が`src/`のshdocコメントから生成します。直接編集しないでください。

関数名と入出力の規則は[ライブラリ仕様](../specifications/library.md)、名前付き引数とTab補完は[名前付き引数とTab補完の仕様](../specifications/named-arguments.md)で定義します。

`-as-root`で終わる関数は、通常権限と管理者権限のどちらで実行するかを呼び出し側が選べる操作です。
管理者権限を常に必要とする操作と、書き込み権限が不足した場合に昇格する操作は、関数名に`-as-root`を付けません。

## [`number`](modules/number.md)

| 関数 | 説明 |
|---|---|
| [`number::is-integer`](modules/number.md#numberis-integer) | Test whether a value is a signed or unsigned decimal integer. |
| [`number::is-decimal`](modules/number.md#numberis-decimal) | Test whether a value is a signed or unsigned decimal fraction. |
| [`number::is-number`](modules/number.md#numberis-number) | Test whether a value is a decimal integer or fraction. |

## [`string`](modules/string.md)

| 関数 | 説明 |
|---|---|
| [`string::trim`](modules/string.md#stringtrim) | Remove leading and trailing whitespace. |
| [`string::collapse-whitespace`](modules/string.md#stringcollapse-whitespace) | Trim whitespace and collapse each interior run to one ASCII space. |
| [`string::split`](modules/string.md#stringsplit) | Split a value by a non-empty literal delimiter and preserve empty fields. |
| [`string::lower`](modules/string.md#stringlower) | Convert ASCII uppercase letters to lowercase. |
| [`string::upper`](modules/string.md#stringupper) | Convert ASCII lowercase letters to uppercase. |
| [`string::swap-case`](modules/string.md#stringswap-case) | Swap the case of every ASCII letter. |
| [`string::lower-first`](modules/string.md#stringlower-first) | Convert the first ASCII letter to lowercase when applicable. |
| [`string::upper-first`](modules/string.md#stringupper-first) | Convert the first ASCII letter to uppercase when applicable. |
| [`string::strip-surrounding-quotes`](modules/string.md#stringstrip-surrounding-quotes) | Remove one matching pair of surrounding single or double quotes. |
| [`string::remove-all-matches`](modules/string.md#stringremove-all-matches) | Remove every substring that matches a Bash pattern. |
| [`string::remove-first-match`](modules/string.md#stringremove-first-match) | Remove the first substring that matches a Bash pattern. |
| [`string::remove-prefix`](modules/string.md#stringremove-prefix) | Remove the longest prefix that matches a Bash pattern. |
| [`string::remove-suffix`](modules/string.md#stringremove-suffix) | Remove the longest suffix that matches a Bash pattern. |
| [`string::encode-url`](modules/string.md#stringencode-url) | Percent-encode a UTF-8 string byte by byte. |
| [`string::decode-url`](modules/string.md#stringdecode-url) | Decode percent-encoded bytes without translating plus signs. |
| [`string::contains`](modules/string.md#stringcontains) | Test whether a value contains a literal substring. |
| [`string::starts-with`](modules/string.md#stringstarts-with) | Test whether a value starts with a literal prefix. |
| [`string::ends-with`](modules/string.md#stringends-with) | Test whether a value ends with a literal suffix. |
| [`string::join`](modules/string.md#stringjoin) | Join values with a literal delimiter. |
| [`string::byte-length`](modules/string.md#stringbyte-length) | Write the byte length of a value. |
| [`string::length`](modules/string.md#stringlength) | Write the character length of a value in a UTF-8 locale. |
| [`string::replace-first`](modules/string.md#stringreplace-first) | Replace the first substring that matches a Bash pattern. |
| [`string::replace-all`](modules/string.md#stringreplace-all) | Replace every substring that matches a Bash pattern. |
| [`string::replace-last`](modules/string.md#stringreplace-last) | Replace the rightmost non-empty substring that matches a Bash pattern. |
| [`string::require-non-empty`](modules/string.md#stringrequire-non-empty) | Require a named value to be non-empty. |
| [`string::require-empty`](modules/string.md#stringrequire-empty) | Require a named value to be empty. |
| [`string::require-allowed`](modules/string.md#stringrequire-allowed) | Require a named value to equal one of the allowed values. |
| [`string::slice`](modules/string.md#stringslice) | Write a validated character range from a UTF-8 string. |

## [`regex`](modules/regex.md)

| 関数 | 説明 |
|---|---|
| [`regex::is-match`](modules/regex.md#regexis-match) | Test a value against a Bash POSIX extended regular expression. |
| [`regex::capture-group`](modules/regex.md#regexcapture-group) | Write one capture group from a Bash POSIX extended regular expression. |
| [`regex::capture-groups`](modules/regex.md#regexcapture-groups) | Write all capture groups from a Bash POSIX extended regular expression. |

## [`array`](modules/array.md)

| 関数 | 説明 |
|---|---|
| [`array::contains`](modules/array.md#arraycontains) | Test whether the remaining arguments contain the expected value. |
| [`array::reverse`](modules/array.md#arrayreverse) | Write the arguments in reverse order, one value per line. |
| [`array::length`](modules/array.md#arraylength) | Write the number of arguments. |
| [`array::first`](modules/array.md#arrayfirst) | Write the first argument when one is available. |
| [`array::last`](modules/array.md#arraylast) | Write the last argument when one is available. |
| [`array::unique`](modules/array.md#arrayunique) | Write each distinct argument once in its original order. |
| [`array::prepend-to-each`](modules/array.md#arrayprepend-to-each) | Prefix every value and write one result per line. |

## [`arg`](modules/arg.md)

| 関数 | 説明 |
|---|---|
| [`arg::require-next`](modules/arg.md#argrequire-next) | Require a value to follow the current named argument. |
| [`arg::require`](modules/arg.md#argrequire) | Require a named argument to have a non-empty value. |
| [`arg::integer`](modules/arg.md#arginteger) | Require a named argument value to be a decimal integer. |
| [`arg::one-of`](modules/arg.md#argone-of) | Require a named argument value to match one candidate. |
| [`arg::unknown`](modules/arg.md#argunknown) | Report a named argument that no case branch recognized. |
| [`arg::completion::dispatch`](modules/arg.md#argcompletiondispatch) | Dispatch Tab completion to the target function's completion helper. |
| [`arg::completion::register-all`](modules/arg.md#argcompletionregister-all) | Register Tab completion for every function that has a completion helper. |

## [`help`](modules/help.md)

| 関数 | 説明 |
|---|---|
| [`help::show`](modules/help.md#helpshow) | Show the documentation of a BashStock function, like Get-Help in PowerShell. |

## [`system`](modules/system.md)

| 関数 | 説明 |
|---|---|
| [`system::operating-system`](modules/system.md#systemoperating-system) | Write the normalized operating-system family. |
| [`system::host-name`](modules/system.md#systemhost-name) | Write the current host name. |
| [`system::kernel-name`](modules/system.md#systemkernel-name) | Write the kernel name. |
| [`system::distribution-name`](modules/system.md#systemdistribution-name) | Write the distribution name. |
| [`system::enable-sleep`](modules/system.md#systemenable-sleep) | Enable system sleep. |
| [`system::disable-sleep`](modules/system.md#systemdisable-sleep) | Disable system sleep. |
| [`system::disable-auto-lock`](modules/system.md#systemdisable-auto-lock) | Disable automatic screen locking for the current user. |
| [`system::enable-auto-lock`](modules/system.md#systemenable-auto-lock) | Enable automatic screen locking for the current user. |

## [`command`](modules/command.md)

| 関数 | 説明 |
|---|---|
| [`command::exists`](modules/command.md#commandexists) | Test whether a command name resolves in the current environment. |
| [`command::require`](modules/command.md#commandrequire) | Require a command name to resolve in the current environment. |
| [`command::run-as-root`](modules/command.md#commandrun-as-root) | Run a command directly as root or through validated sudo access. |

## [`shell`](modules/shell.md)

| 関数 | 説明 |
|---|---|
| [`shell::is-function-defined`](modules/shell.md#shellis-function-defined) | Test whether a shell function is defined. |
| [`shell::editor::set-default`](modules/shell.md#shelleditorset-default) | Set the default editor of new Bash and Zsh sessions and the current process. |
| [`shell::completion::enable-ignore-case`](modules/shell.md#shellcompletionenable-ignore-case) | Make Bash and Zsh completion ignore letter case. |
| [`shell::zsh::enable-interactive-comments`](modules/shell.md#shellzshenable-interactive-comments) | Allow comments that start with # in interactive Zsh sessions. |
| [`shell::confirm`](modules/shell.md#shellconfirm) | Read and normalize a yes-or-no answer. |
| [`shell::read-line`](modules/shell.md#shellread-line) | Read one line and substitute a default only for empty input. |
| [`shell::confirm-or-cancel`](modules/shell.md#shellconfirm-or-cancel) | Read and normalize a yes, no, or cancel answer. |
| [`shell::choose-one`](modules/shell.md#shellchoose-one) | Display indexed choices and write the selected value. |
| [`shell::wait-for-enter`](modules/shell.md#shellwait-for-enter) | Wait for one line from the controlling terminal. |

## [`terminal`](modules/terminal.md)

| 関数 | 説明 |
|---|---|
| [`terminal::is-available`](modules/terminal.md#terminalis-available) | Test whether the controlling terminal is readable and writable. |
| [`terminal::open`](modules/terminal.md#terminalopen) | Open a new window of the desktop's default terminal application. |

## [`path`](modules/path.md)

| 関数 | 説明 |
|---|---|
| [`path::directory-name`](modules/path.md#pathdirectory-name) | Write the lexical directory portion of a path. |
| [`path::base-name`](modules/path.md#pathbase-name) | Write the final component of a path with an optional suffix removed. |
| [`path::is-directory`](modules/path.md#pathis-directory) | Test whether a path names a directory. |
| [`path::is-empty-directory`](modules/path.md#pathis-empty-directory) | Test whether a path names an empty directory. |
| [`path::is-executable`](modules/path.md#pathis-executable) | Test whether the current user may execute a path. |
| [`path::is-executable-file`](modules/path.md#pathis-executable-file) | Test whether a path names an executable regular file. |
| [`path::is-regular-file`](modules/path.md#pathis-regular-file) | Test whether a path names a regular file. |
| [`path::is-symbolic-link`](modules/path.md#pathis-symbolic-link) | Test whether a path names a symbolic link. |
| [`path::is-readable`](modules/path.md#pathis-readable) | Test whether the current user may read a path. |
| [`path::is-writable`](modules/path.md#pathis-writable) | Test whether the current user may write a path. |
| [`path::mode`](modules/path.md#pathmode) | Write a path's permission mode as an octal number. |
| [`path::extension`](modules/path.md#pathextension) | Write the extension of the final path component. |
| [`path::normalize`](modules/path.md#pathnormalize) | Normalize a path lexically without accessing the file system. |
| [`path::relative`](modules/path.md#pathrelative) | Write the lexical relative path from one path to another. |
| [`path::config-home`](modules/path.md#pathconfig-home) | Write the absolute configuration-home directory. |
| [`path::change-owner-recursively`](modules/path.md#pathchange-owner-recursively) | Change directory ownership recursively through the root helper. |
| [`path::change-owner-recursively-as-root`](modules/path.md#pathchange-owner-recursively-as-root) | Change directory ownership recursively in a separate root process. |
| [`path::find`](modules/path.md#pathfind) | Write the paths below a directory that match a case-insensitive Bash ERE, separated by NUL. |

## [`time`](modules/time.md)

| 関数 | 説明 |
|---|---|
| [`time::monotonic-milliseconds`](modules/time.md#timemonotonic-milliseconds) | Write monotonic milliseconds that exclude suspended time. |
| [`time::boot-time-milliseconds`](modules/time.md#timeboot-time-milliseconds) | Write milliseconds since boot including suspended time. |
| [`time::unix-milliseconds`](modules/time.md#timeunix-milliseconds) | Write Unix-epoch milliseconds. |
| [`time::unix-seconds`](modules/time.md#timeunix-seconds) | Write Unix-epoch seconds rounded down. |
| [`time::unix-days`](modules/time.md#timeunix-days) | Write Unix-epoch days rounded down. |
| [`time::utc-date-time-milliseconds-extended`](modules/time.md#timeutc-date-time-milliseconds-extended) | Write the current UTC date and time in ISO 8601 extended format with milliseconds. |
| [`time::utc-date-time-seconds-extended`](modules/time.md#timeutc-date-time-seconds-extended) | Write the current UTC date and time in ISO 8601 extended format with seconds. |
| [`time::utc-date-extended`](modules/time.md#timeutc-date-extended) | Write the current UTC date in ISO 8601 extended format. |
| [`time::local-date-time-milliseconds-extended`](modules/time.md#timelocal-date-time-milliseconds-extended) | Write the current local date and time in ISO 8601 extended format with milliseconds and an offset. |
| [`time::local-date-time-seconds-extended`](modules/time.md#timelocal-date-time-seconds-extended) | Write the current local date and time in ISO 8601 extended format with seconds and an offset. |
| [`time::local-date-extended`](modules/time.md#timelocal-date-extended) | Write the current local date in ISO 8601 extended format. |
| [`time::local-date-time-seconds-basic`](modules/time.md#timelocal-date-time-seconds-basic) | Write the current local date and time in ISO 8601 basic format with seconds. |
| [`time::sleep-hours`](modules/time.md#timesleep-hours) | Sleep for a non-negative integer number of hours. |
| [`time::posix-timezone`](modules/time.md#timeposix-timezone) | Write the POSIX TZ string for a UTC offset. |
| [`time::status-continuous`](modules/time.md#timestatus-continuous) | Write the elapsed time since boot and the local time every three seconds until stopped. |

## [`log`](modules/log.md)

| 関数 | 説明 |
|---|---|
| [`log::info`](modules/log.md#loginfo) | Write an informational log message. |
| [`log::warn`](modules/log.md#logwarn) | Write a warning log message. |
| [`log::error`](modules/log.md#logerror) | Write an error log message without exiting. |

## [`json`](modules/json.md)

| 関数 | 説明 |
|---|---|
| [`json::require-present`](modules/json.md#jsonrequire-present) | Require a named JSON-derived value to be neither empty nor null. |

## [`option`](modules/option.md)

| 関数 | 説明 |
|---|---|
| [`option::require-single`](modules/option.md#optionrequire-single) | Require exactly one named option value to be non-empty. |

## [`file`](modules/file.md)

| 関数 | 説明 |
|---|---|
| [`file::contains-match`](modules/file.md#filecontains-match) | Test whether any file line matches a Perl regular expression. |
| [`file::verify-sha256`](modules/file.md#fileverify-sha256) | Test a file against an expected SHA-256 digest. |
| [`file::append-text`](modules/file.md#fileappend-text) | Append text without conversion, elevating only when permissions require it. |
| [`file::replace-text`](modules/file.md#filereplace-text) | Replace the first Bash ERE match on every file line. |
| [`file::replace-all-text`](modules/file.md#filereplace-all-text) | Replace every nonempty Bash ERE match on every file line. |
| [`file::replace-text-in-files`](modules/file.md#filereplace-text-in-files) | Replace line matches across multiple files. |
| [`file::replace-all-text-in-files`](modules/file.md#filereplace-all-text-in-files) | Replace every line match across multiple files. |
| [`file::replace-text-or-append`](modules/file.md#filereplace-text-or-append) | Replace every line match or append one line when no match exists. |
| [`file::replace-or-append-text`](modules/file.md#filereplace-or-append-text) | Replace matching text or append it using the established API name. |
| [`file::append-text-as-root`](modules/file.md#fileappend-text-as-root) | Append text through the root execution dispatcher. |
| [`file::replace-text-as-root`](modules/file.md#filereplace-text-as-root) | Replace the first expression match through the root execution dispatcher. |
| [`file::replace-all-text-as-root`](modules/file.md#filereplace-all-text-as-root) | Replace every expression match through the root execution dispatcher. |
| [`file::replace-text-in-files-as-root`](modules/file.md#filereplace-text-in-files-as-root) | Replace expression matches in files through the root execution dispatcher. |
| [`file::replace-all-text-in-files-as-root`](modules/file.md#filereplace-all-text-in-files-as-root) | Replace all expression matches in files through the root execution dispatcher. |
| [`file::replace-or-append-text-as-root`](modules/file.md#filereplace-or-append-text-as-root) | Replace matching text or append it through the root execution dispatcher. |
| [`file::write-text`](modules/file.md#filewrite-text) | Write text to a regular file using an atomic replacement. |
| [`file::find-by-content`](modules/file.md#filefind-by-content) | Write the regular files below a directory whose content matches an ERE, separated by NUL. |
| [`file::latest-by-name`](modules/file.md#filelatest-by-name) | Write the most recently modified regular file whose base name matches a Bash ERE. |
| [`file::edit`](modules/file.md#fileedit) | Open an editor for a file, using sudoedit only when required. |
| [`file::release`](modules/file.md#filerelease) | Release a file held by other processes. |
| [`file::tree-with-contents`](modules/file.md#filetree-with-contents) | Write the directories and text files below a path, with the contents of each text file. |
| [`file::modified-time-unix-seconds`](modules/file.md#filemodified-time-unix-seconds) | Write the last modification time of a file as Unix seconds. |

## [`adb`](modules/adb.md)

| 関数 | 説明 |
|---|---|
| [`adb::device::wait`](modules/adb.md#adbdevicewait) | Wait for an ADB device to connect, optionally selected with --serial. |
| [`adb::device::pull`](modules/adb.md#adbdevicepull) | Copy files from an ADB device to the host. |
| [`adb::device::push`](modules/adb.md#adbdevicepush) | Copy files from the host to an ADB device. |
| [`adb::logcat::clear`](modules/adb.md#adblogcatclear) | Clear the selected device log buffers. |
| [`adb::logcat::once`](modules/adb.md#adblogcatonce) | Write the selected device log buffers once. |
| [`adb::logcat::continuous`](modules/adb.md#adblogcatcontinuous) | Stream logs from the selected device. |
| [`adb::device::reboot`](modules/adb.md#adbdevicereboot) | Reboot the selected device. |
| [`adb::device::first`](modules/adb.md#adbdevicefirst) | Write the first connected ADB device serial. |
| [`adb::device::list`](modules/adb.md#adbdevicelist) | List connected ADB device serials. |
| [`adb::device::wait-for-path`](modules/adb.md#adbdevicewait-for-path) | Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout. |
| [`adb::device::screen::capture-once`](modules/adb.md#adbdevicescreencapture-once) | Save one screenshot atomically and print its path. |
| [`adb::device::select-and-pull`](modules/adb.md#adbdeviceselect-and-pull) | Select one requested device path and pull it to the host. |
| [`adb::device::bootloader::enter`](modules/adb.md#adbdevicebootloaderenter) | Reboot the selected device into its bootloader. |
| [`adb::device::bootloader::unlock`](modules/adb.md#adbdevicebootloaderunlock) | Request bootloader unlocking and wait for the device to reconnect. |
| [`adb::device::verity::disable`](modules/adb.md#adbdeviceveritydisable) | Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects. |
| [`adb::device::partition::remount`](modules/adb.md#adbdevicepartitionremount) | Make the system partitions of a rooted device writable. |
| [`adb::device::build::fingerprint`](modules/adb.md#adbdevicebuildfingerprint) | Write the selected device build fingerprint. |
| [`adb::device::build::date`](modules/adb.md#adbdevicebuilddate) | Write the selected device build timestamp as Unix seconds. |
| [`adb::device::slot::suffix`](modules/adb.md#adbdeviceslotsuffix) | Write the selected device active slot suffix. |
| [`adb::device::build::kernel-version`](modules/adb.md#adbdevicebuildkernel-version) | Write the selected device kernel release. |
| [`adb::device::screen::capture-continuous`](modules/adb.md#adbdevicescreencapture-continuous) | Save repeated screenshots; MAX_COUNT of zero runs until interrupted. |
| [`adb::device::partition::sha256`](modules/adb.md#adbdevicepartitionsha256) | Write a device partition SHA-256 checksum. |
| [`adb::wake::lock`](modules/adb.md#adbwakelock) | Hold a kernel wake lock using a tag, defaulting to debug. |
| [`adb::wake::unlock`](modules/adb.md#adbwakeunlock) | Release a kernel wake lock using the same tag. |
| [`adb::wake::list`](modules/adb.md#adbwakelist) | Print active kernel wake locks. |
| [`adb::device::set-default`](modules/adb.md#adbdeviceset-default) | Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL. |
| [`adb::server::start`](modules/adb.md#adbserverstart) | Start the host ADB server. |
| [`adb::server::stop`](modules/adb.md#adbserverstop) | Stop the host ADB server. |
| [`adb::server::restart`](modules/adb.md#adbserverrestart) | Stop and then start the host ADB server. |

## [`android`](modules/android.md)

| 関数 | 説明 |
|---|---|
| [`android::sdk::directory`](modules/android.md#androidsdkdirectory) | Write the SDK directory selected by Android Studio or the caller. |
| [`android::cli::install`](modules/android.md#androidcliinstall) | Install the official Android CLI without replacing a working copy on failure. |
| [`android::sdk::install`](modules/android.md#androidsdkinstall) | Create and configure the selected SDK directory and Android CLI. |
| [`android::platform-tools::install`](modules/android.md#androidplatform-toolsinstall) | Install Android Platform Tools and add adb and fastboot to PATH. |
| [`android::sdk-platform::install`](modules/android.md#androidsdk-platforminstall) | Install an Android SDK Platform and verify its android.jar file. |
| [`android::build-tools::install`](modules/android.md#androidbuild-toolsinstall) | Install one stable Build Tools version and add its executables to PATH. |
| [`android::emulator::install`](modules/android.md#androidemulatorinstall) | Install the Android Emulator into the selected SDK. |
| [`android::command-line-tools::install`](modules/android.md#androidcommand-line-toolsinstall) | Install SDK Command-line Tools and verify sdkmanager and avdmanager. |
| [`android::avd::list`](modules/android.md#androidavdlist) | List AVD names in the selected Android SDK environment. |
| [`android::avd::profiles`](modules/android.md#androidavdprofiles) | List hardware profiles available to avdmanager. |
| [`android::system-images::versions`](modules/android.md#androidsystem-imagesversions) | List stable system images as API, tag, ABI, and revision values. |
| [`android::avd::create`](modules/android.md#androidavdcreate) | Create one AVD from a stable Google APIs image without starting it. |
| [`android::avd::port::available`](modules/android.md#androidavdportavailable) | Report whether an even emulator console port and its ADB port are both free. |
| [`android::avd::port::first`](modules/android.md#androidavdportfirst) | Write the first free emulator console port. |
| [`android::avd::start`](modules/android.md#androidavdstart) | Start one AVD and wait for Android to finish booting. |
| [`android::avd::stop`](modules/android.md#androidavdstop) | Stop the named AVD, or the only running AVD when no name is given. |
| [`android::avd::delete`](modules/android.md#androidavddelete) | Delete one named AVD without changing other AVDs. |
| [`android::build-tools::versions`](modules/android.md#androidbuild-toolsversions) | Write available stable Android Build Tools versions in ascending order. |
| [`android::build-tools::latest-version`](modules/android.md#androidbuild-toolslatest-version) | Write the newest available stable Android Build Tools version. |

## [`apt`](modules/apt.md)

| 関数 | 説明 |
|---|---|
| [`apt::package::candidates`](modules/apt.md#aptpackagecandidates) | Write APT packages whose names start with PREFIX followed by a digit, with candidate versions. |
| [`apt::package::latest`](modules/apt.md#aptpackagelatest) | Write the APT package name with the newest version suffix after PREFIX. |
| [`apt::deb::install-from-url`](modules/apt.md#aptdebinstall-from-url) | Download a Debian package and install it with its dependencies through APT. |

## [`archive`](modules/archive.md)

| 関数 | 説明 |
|---|---|
| [`archive::verify`](modules/archive.md#archiveverify) | Verify all recognized archives below a path. |
| [`archive::remove-broken`](modules/archive.md#archiveremove-broken) | Remove archives that fail verification. |
| [`archive::extract-file`](modules/archive.md#archiveextract-file) | Extract one archive or decompress one compressed file. |
| [`archive::compress-tar-gzip`](modules/archive.md#archivecompress-tar-gzip) | Compress paths into a gzip-compressed tar archive. |
| [`archive::extract`](modules/archive.md#archiveextract) | Extract one archive, or every recognized archive below a directory, next to itself. |

## [`asciidoc`](modules/asciidoc.md)

| 関数 | 説明 |
|---|---|
| [`asciidoc::html`](modules/asciidoc.md#asciidochtml) | Convert AsciiDoc to HTML with diagram support. |

## [`aws`](modules/aws.md)

| 関数 | 説明 |
|---|---|
| [`aws::is-ec2-instance`](modules/aws.md#awsis-ec2-instance) | Test whether IMDSv2 is available for the current instance. |
| [`aws::instance-metadata`](modules/aws.md#awsinstance-metadata) | Write one validated EC2 instance metadata value. |
| [`aws::instance-id`](modules/aws.md#awsinstance-id) | Write the current EC2 instance identifier. |
| [`aws::instance-region`](modules/aws.md#awsinstance-region) | Write the current EC2 instance region. |
| [`aws::instance-availability-zone`](modules/aws.md#awsinstance-availability-zone) | Write the current EC2 instance availability zone. |
| [`aws::instance-private-ip`](modules/aws.md#awsinstance-private-ip) | Write the current EC2 instance private IPv4 address. |
| [`aws::instance-tags`](modules/aws.md#awsinstance-tags) | Write all tags for one EC2 instance. |
| [`aws::instance-tag`](modules/aws.md#awsinstance-tag) | Write one EC2 instance tag value. |
| [`aws::wait-for-instance-tag`](modules/aws.md#awswait-for-instance-tag) | Wait for one EC2 instance tag to become available. |
| [`aws::instances-with-tag`](modules/aws.md#awsinstances-with-tag) | Write EC2 instances that have a requested tag. |
| [`aws::auto-scaling-group`](modules/aws.md#awsauto-scaling-group) | Write the Auto Scaling group that contains an EC2 instance. |
| [`aws::instances-in-auto-scaling-group`](modules/aws.md#awsinstances-in-auto-scaling-group) | Write running or pending instances in an Auto Scaling group. |
| [`aws::auto-scaling-group-name`](modules/aws.md#awsauto-scaling-group-name) | Write the current instance's Auto Scaling group name. |
| [`aws::auto-scaling-group-size`](modules/aws.md#awsauto-scaling-group-size) | Write the desired capacity of an Auto Scaling group. |
| [`aws::vpn-client::log::files`](modules/aws.md#awsvpn-clientlogfiles) | Write AWS VPN Client log files as NUL-separated paths. |
| [`aws::vpn-client::log::clear`](modules/aws.md#awsvpn-clientlogclear) | Remove regular log files below the AWS VPN Client log directory. |
| [`aws::vpn-client::log::open`](modules/aws.md#awsvpn-clientlogopen) | Open log files with an editor command, passing each path as one argument. |

## [`brave`](modules/brave.md)

| 関数 | 説明 |
|---|---|
| [`brave::versions`](modules/brave.md#braveversions) | Write Brave versions available to the current platform. |
| [`brave::install`](modules/brave.md#braveinstall) | Install Brave from its official repository or Homebrew. |

## [`chatgpt`](modules/chatgpt.md)

| 関数 | 説明 |
|---|---|
| [`chatgpt::install`](modules/chatgpt.md#chatgptinstall) | Install the newest ChatGPT desktop app, which also runs Codex. |

## [`chrome`](modules/chrome.md)

| 関数 | 説明 |
|---|---|
| [`chrome::profile::export-bookmarks`](modules/chrome.md#chromeprofileexport-bookmarks) | Export a Chrome profile's Bookmarks file. |
| [`chrome::profile::export-preferences`](modules/chrome.md#chromeprofileexport-preferences) | Export a Chrome profile's Preferences file. |
| [`chrome::profile::email`](modules/chrome.md#chromeprofileemail) | Write the first known email address from a Chrome profile. |
| [`chrome::profile::find-by-email`](modules/chrome.md#chromeprofilefind-by-email) | Find Chrome profiles whose known email matches literally. |
| [`chrome::profile::export-user-data-by-email`](modules/chrome.md#chromeprofileexport-user-data-by-email) | Export Chrome Preferences and Bookmarks for profiles whose email matches literally. |
| [`chrome::versions`](modules/chrome.md#chromeversions) | Write Google Chrome versions available to the current platform. |
| [`chrome::install`](modules/chrome.md#chromeinstall) | Install Google Chrome from the Google repository or Homebrew. |

## [`claude-code`](modules/claude-code.md)

| 関数 | 説明 |
|---|---|
| [`claude-code::install`](modules/claude-code.md#claude-codeinstall) | Install the newest Claude Code CLI. |

## [`claude-desktop`](modules/claude-desktop.md)

| 関数 | 説明 |
|---|---|
| [`claude-desktop::install`](modules/claude-desktop.md#claude-desktopinstall) | Install the newest Claude Desktop, the app that also runs Claude Code sessions. |

## [`codex`](modules/codex.md)

| 関数 | 説明 |
|---|---|
| [`codex::install`](modules/codex.md#codexinstall) | Install the newest OpenAI Codex CLI. |

## [`colima`](modules/colima.md)

| 関数 | 説明 |
|---|---|
| [`colima::versions`](modules/colima.md#colimaversions) | Write Colima versions available from Homebrew. |
| [`colima::install`](modules/colima.md#colimainstall) | Install Colima with Homebrew on macOS and start it. |

## [`device-tree`](modules/device-tree.md)

| 関数 | 説明 |
|---|---|
| [`device-tree::node::list`](modules/device-tree.md#device-treenodelist) | Write the node paths of the Linux device tree. |

## [`dir`](modules/dir.md)

| 関数 | 説明 |
|---|---|
| [`dir::diff`](modules/dir.md#dirdiff) | Run diff for two directories. |
| [`dir::merge`](modules/dir.md#dirmerge) | Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE. |
| [`dir::create-with-date-time`](modules/dir.md#dircreate-with-date-time) | Create a directory named with the local date and time and write its path. |
| [`dir::clear`](modules/dir.md#dirclear) | Remove every entry of a directory, including hidden ones, and keep the directory. |

## [`docker`](modules/docker.md)

| 関数 | 説明 |
|---|---|
| [`docker::container::list-running`](modules/docker.md#dockercontainerlist-running) | List running Docker containers. |
| [`docker::container::list`](modules/docker.md#dockercontainerlist) | List Docker containers. |
| [`docker::container::pull`](modules/docker.md#dockercontainerpull) | Copy files between a Docker container and the host. |
| [`docker::container::push`](modules/docker.md#dockercontainerpush) | Copy a host path into a container. |
| [`docker::container::shell`](modules/docker.md#dockercontainershell) | Run an interactive shell or a command in a container. |
| [`docker::container::logs`](modules/docker.md#dockercontainerlogs) | Follow the log of a container. |
| [`docker::container::stop`](modules/docker.md#dockercontainerstop) | Stop a container. |
| [`docker::container::start`](modules/docker.md#dockercontainerstart) | Start a container. |
| [`docker::container::stop-all`](modules/docker.md#dockercontainerstop-all) | Stop every running container; having none is a success. |
| [`docker::container::remove-all`](modules/docker.md#dockercontainerremove-all) | Remove every container, running or not. |
| [`docker::volume::remove-all`](modules/docker.md#dockervolumeremove-all) | Remove every Docker volume. |
| [`docker::remove-all`](modules/docker.md#dockerremove-all) | Remove every container and then every volume, stopping at the first failure. |
| [`docker::login-artifactory`](modules/docker.md#dockerlogin-artifactory) | Log in to an Artifactory Docker registry using a token on standard input. |
| [`docker::versions`](modules/docker.md#dockerversions) | Write Docker Engine or Docker CLI versions available to the current platform. |
| [`docker::install`](modules/docker.md#dockerinstall) | Install the Docker CLI, and Docker Engine on Linux. |

## [`env`](modules/env.md)

| 関数 | 説明 |
|---|---|
| [`env::dotenv::import`](modules/env.md#envdotenvimport) | Import the variables of a dotenv file into the current process. |
| [`env::set-variable`](modules/env.md#envset-variable) | Set an environment variable for the current shell. |
| [`env::add-path`](modules/env.md#envadd-path) | Add a directory to PATH without creating duplicates. |
| [`env::dotenv::register`](modules/env.md#envdotenvregister) | Load a dotenv file in every new Bash and Zsh session. |

## [`fedora`](modules/fedora.md)

| 関数 | 説明 |
|---|---|
| [`fedora::setup`](modules/fedora.md#fedorasetup) | Apply the common Fedora user configuration, stopping at the first failure. |
| [`fedora::setup-external`](modules/fedora.md#fedorasetup-external) | Install GnuPG, GitHub CLI, and Git Credential Manager on Fedora when they are not already available. |

## [`flutter`](modules/flutter.md)

| 関数 | 説明 |
|---|---|
| [`flutter::run-chrome-release`](modules/flutter.md#flutterrun-chrome-release) | Run a Flutter project in Chrome in release mode. |
| [`flutter::run-linux-release`](modules/flutter.md#flutterrun-linux-release) | Run a Flutter project as a Linux desktop application in release mode. |
| [`flutter::test`](modules/flutter.md#fluttertest) | Run the Flutter tests of a project with optional flutter test arguments. |
| [`flutter::coverage`](modules/flutter.md#fluttercoverage) | Run the Flutter tests with coverage and write the LCOV HTML report. |
| [`flutter::use-version`](modules/flutter.md#flutteruse-version) | Keep Flutter SDK changes in a retrievable stash and switch versions. |
| [`flutter::versions`](modules/flutter.md#flutterversions) | Write stable Flutter SDK versions for the current platform. |
| [`flutter::dependencies::install`](modules/flutter.md#flutterdependenciesinstall) | Install packages required to build Flutter applications. |
| [`flutter::install`](modules/flutter.md#flutterinstall) | Install dependencies and select a stable Flutter SDK version. |

## [`gdb`](modules/gdb.md)

| 関数 | 説明 |
|---|---|
| [`gdb::attach-pid`](modules/gdb.md#gdbattach-pid) | Attach GDB in batch mode to a process and write the backtrace of every thread. |
| [`gdb::server::start`](modules/gdb.md#gdbserverstart) | Start COMMAND with its arguments under gdbserver listening on PORT. |
| [`gdb::connect`](modules/gdb.md#gdbconnect) | Load ELF in GDB and connect to the GDB server at HOST and PORT. |
| [`gdb::run-until`](modules/gdb.md#gdbrun-until) | Run ELF in GDB with optional program arguments and stop at SYMBOL. |
| [`gdb::core::open`](modules/gdb.md#gdbcoreopen) | Open ELF and a core dump in GDB. |
| [`gdb::attach-by-name`](modules/gdb.md#gdbattach-by-name) | Attach GDB to the first process whose executable name is NAME. |

## [`gerrit`](modules/gerrit.md)

| 関数 | 説明 |
|---|---|
| [`gerrit::push-review`](modules/gerrit.md#gerritpush-review) | Push the current HEAD to a Gerrit review reference. |
| [`gerrit::push-review-wip`](modules/gerrit.md#gerritpush-review-wip) | Push the current HEAD to a Gerrit review reference as work in progress. |

## [`gh`](modules/gh.md)

| 関数 | 説明 |
|---|---|
| [`gh::install`](modules/gh.md#ghinstall) | Install GitHub CLI from its official Ubuntu APT or Fedora DNF repository. |

## [`gimp`](modules/gimp.md)

| 関数 | 説明 |
|---|---|
| [`gimp::versions`](modules/gimp.md#gimpversions) | Write GIMP versions available to the current platform. |
| [`gimp::install`](modules/gimp.md#gimpinstall) | Install GIMP, and on Linux the G'MIC plugin from the selected source. |
| [`gimp::gmic::versions`](modules/gimp.md#gimpgmicversions) | Write G'MIC GIMP plugin versions available from the selected source. |
| [`gimp::gmic::install`](modules/gimp.md#gimpgmicinstall) | Install the G'MIC GIMP plugin. |

## [`git`](modules/git.md)

| 関数 | 説明 |
|---|---|
| [`git::commit::edit-via-rebase`](modules/git.md#gitcommitedit-via-rebase) | Start an interactive rebase that stops at one non-merge commit for editing. |
| [`git::clone-shallow`](modules/git.md#gitclone-shallow) | Clone a repository with depth one. |
| [`git::rebase-abort`](modules/git.md#gitrebase-abort) | Abort an in-progress rebase. |
| [`git::rebase-continue`](modules/git.md#gitrebase-continue) | Continue an in-progress rebase. |
| [`git::commit::amend`](modules/git.md#gitcommitamend) | Amend the last commit without changing its message. |
| [`git::commit::create`](modules/git.md#gitcommitcreate) | Create a commit with a message. |
| [`git::commit::uncommit`](modules/git.md#gitcommituncommit) | Remove the last commit while keeping its changes staged. |
| [`git::branch::current`](modules/git.md#gitbranchcurrent) | Write the current branch name. |
| [`git::branch::create`](modules/git.md#gitbranchcreate) | Create a branch at a starting revision. |
| [`git::branch::list`](modules/git.md#gitbranchlist) | List local and remote-tracking branches. |
| [`git::diff::files`](modules/git.md#gitdifffiles) | Show file names changed between two revisions. |
| [`git::diff::patch`](modules/git.md#gitdiffpatch) | Show a patch between two revisions. |
| [`git::diff::uncommitted-patch`](modules/git.md#gitdiffuncommitted-patch) | Show the patch for uncommitted tracked changes. |
| [`git::diff::uncommitted-files`](modules/git.md#gitdiffuncommitted-files) | Show file names changed by uncommitted tracked changes. |
| [`git::diff::latest-patch`](modules/git.md#gitdifflatest-patch) | Show the patch introduced by the latest commit. |
| [`git::diff::latest-files`](modules/git.md#gitdifflatest-files) | Show file names changed by the latest commit. |
| [`git::commit::patch`](modules/git.md#gitcommitpatch) | Write the unified diff that one commit introduced. |
| [`git::commit::revert-without-commit`](modules/git.md#gitcommitrevert-without-commit) | Revert a commit without creating a commit. |
| [`git::commit::revert`](modules/git.md#gitcommitrevert) | Revert a commit and create the revert commit. |
| [`git::fetch`](modules/git.md#gitfetch) | Fetch one remote or all remotes. |
| [`git::fetch-unshallow`](modules/git.md#gitfetch-unshallow) | Convert a shallow clone into a complete history. |
| [`git::stash::patch`](modules/git.md#gitstashpatch) | Show a stash patch. |
| [`git::stash::push`](modules/git.md#gitstashpush) | Save tracked changes and untracked files in a new stash. |
| [`git::stash::pop`](modules/git.md#gitstashpop) | Apply and remove a stash. |
| [`git::stash::drop`](modules/git.md#gitstashdrop) | Delete a stash. |
| [`git::reset`](modules/git.md#gitreset) | Reset a working tree to a revision. |
| [`git::pull-rebase`](modules/git.md#gitpull-rebase) | Update a branch from a remote with rebase. |
| [`git::cherry-pick`](modules/git.md#gitcherry-pick) | Apply one commit, fetching it from a remote only when the repository lacks it. |
| [`git::cherry-pick-continue`](modules/git.md#gitcherry-pick-continue) | Continue an in-progress cherry-pick. |
| [`git::cherry-pick-abort`](modules/git.md#gitcherry-pick-abort) | Abort an in-progress cherry-pick. |
| [`git::push`](modules/git.md#gitpush) | Push a branch to a remote. |
| [`git::push::force-with-lease`](modules/git.md#gitpushforce-with-lease) | Push a branch without overwriting a remote update. |
| [`git::remote::delete-branch`](modules/git.md#gitremotedelete-branch) | Delete a branch on a remote. |
| [`git::submodule::update-all`](modules/git.md#gitsubmoduleupdate-all) | Update all submodules recursively. |
| [`git::commit::discard`](modules/git.md#gitcommitdiscard) | Discard all changes in a working tree. |
| [`git::reset-remote`](modules/git.md#gitreset-remote) | Hard reset the current branch to the branch with the same name on a remote. |
| [`git::pull-base-branch`](modules/git.md#gitpull-base-branch) | Pull the configured base branch with fast-forward-only semantics. |
| [`git::rebase-base-branch`](modules/git.md#gitrebase-base-branch) | Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one. |
| [`git::credentials::remove`](modules/git.md#gitcredentialsremove) | Remove $HOME/.git-credentials and the global credential.helper; both may be absent. |
| [`git::config::enable-origin-all-fetch`](modules/git.md#gitconfigenable-origin-all-fetch) | Make origin fetch every branch in a repository. |
| [`git::config::enable-prune-fetch`](modules/git.md#gitconfigenable-prune-fetch) | Enable pruning on fetch in the global Git configuration. |
| [`git::config::set-default-branch`](modules/git.md#gitconfigset-default-branch) | Set the default branch name of new repositories. |
| [`git::config::enable-rebase-on-pull`](modules/git.md#gitconfigenable-rebase-on-pull) | Enable rebase on pull in the global Git configuration. |
| [`git::config::set-email`](modules/git.md#gitconfigset-email) | Set the global Git email address. |
| [`git::config::set-username`](modules/git.md#gitconfigset-username) | Set the global Git user name. |
| [`git::config::set-http-buffer`](modules/git.md#gitconfigset-http-buffer) | Set the global Git HTTP post buffer. |
| [`git::config::use-gpg-credential-store`](modules/git.md#gitconfiguse-gpg-credential-store) | Make Git Credential Manager store credentials with GPG and pass. |
| [`git::config::use-credential-manager`](modules/git.md#gitconfiguse-credential-manager) | Use Git Credential Manager as the global credential helper. |
| [`git::config::use-osx-keychain`](modules/git.md#gitconfiguse-osx-keychain) | Use the macOS Keychain as the global Git credential helper. |
| [`git::config::setup`](modules/git.md#gitconfigsetup) | Apply the user identity and the standard global Git settings. |
| [`git::stash::list`](modules/git.md#gitstashlist) | List stashes. |

## [`git-credential-manager`](modules/git-credential-manager.md)

| 関数 | 説明 |
|---|---|
| [`git-credential-manager::version::list`](modules/git-credential-manager.md#git-credential-managerversionlist) | Write the installed Git Credential Manager version. |
| [`git-credential-manager::install`](modules/git-credential-manager.md#git-credential-managerinstall) | Install an official Git Credential Manager release for this OS and CPU. |

## [`gnome`](modules/gnome.md)

| 関数 | 説明 |
|---|---|
| [`gnome::keybinding::set-custom`](modules/gnome.md#gnomekeybindingset-custom) | Register a GNOME custom keyboard shortcut after removing conflicting shortcuts. |
| [`gnome::input-source::set-layout`](modules/gnome.md#gnomeinput-sourceset-layout) | Set GNOME input sources to Mozc followed by one XKB layout. |
| [`gnome::keyboard-layout::set-us`](modules/gnome.md#gnomekeyboard-layoutset-us) | Set GNOME input sources and the system keyboard layout to Mozc and US. |
| [`gnome::keyboard-layout::set-jp`](modules/gnome.md#gnomekeyboard-layoutset-jp) | Set GNOME input sources and the system keyboard layout to Mozc and JP. |
| [`gnome::input-source::set-shortcuts`](modules/gnome.md#gnomeinput-sourceset-shortcuts) | Set GNOME input-source switching shortcuts and direct US and Mozc shortcuts. |
| [`gnome::input-source::set-mozc-first`](modules/gnome.md#gnomeinput-sourceset-mozc-first) | Put Mozc first in GNOME input sources while keeping the current XKB layout. |
| [`gnome::window::set-button-layout`](modules/gnome.md#gnomewindowset-button-layout) | Set the GNOME window title-bar button layout. |

## [`go`](modules/go.md)

| 関数 | 説明 |
|---|---|
| [`go::version::list`](modules/go.md#goversionlist) | Write the stable Go versions the platform package source offers, oldest first. |
| [`go::version::latest`](modules/go.md#goversionlatest) | Write the newest stable Go version from go::version::list. |
| [`go::repository::register`](modules/go.md#gorepositoryregister) | Register the official Go package source for the current platform. |
| [`go::install`](modules/go.md#goinstall) | Install Go from the platform package source. |

## [`gpg`](modules/gpg.md)

| 関数 | 説明 |
|---|---|
| [`gpg::decrypt`](modules/gpg.md#gpgdecrypt) | Decrypt a GPG file to standard output without adding a newline. |
| [`gpg::public-key::armor`](modules/gpg.md#gpgpublic-keyarmor) | Write a public GPG key in ASCII armor. |
| [`gpg::secret-key::fingerprints`](modules/gpg.md#gpgsecret-keyfingerprints) | Write the fingerprints of every primary secret GPG key, one per line. |
| [`gpg::secret-key::list`](modules/gpg.md#gpgsecret-keylist) | Write the secret GPG keys in the human-readable GPG format. |
| [`gpg::setup`](modules/gpg.md#gpgsetup) | Create a GPG key and use it for pass, Git credentials, and Git commit signing. |
| [`gpg::key::generate`](modules/gpg.md#gpgkeygenerate) | Generate a GPG primary key and an encryption subkey in one operation. |

## [`gpio`](modules/gpio.md)

| 関数 | 説明 |
|---|---|
| [`gpio::chip::list`](modules/gpio.md#gpiochiplist) | Write the GPIO chips with gpiodetect. |
| [`gpio::line::list`](modules/gpio.md#gpiolinelist) | Write the GPIO lines of one chip, or of every chip, with gpioinfo. |

## [`graphviz`](modules/graphviz.md)

| 関数 | 説明 |
|---|---|
| [`graphviz::versions`](modules/graphviz.md#graphvizversions) | Write Graphviz versions available to the current platform. |
| [`graphviz::install`](modules/graphviz.md#graphvizinstall) | Install Graphviz from the platform package manager. |

## [`gsettings`](modules/gsettings.md)

| 関数 | 説明 |
|---|---|
| [`gsettings::string-array::add`](modules/gsettings.md#gsettingsstring-arrayadd) | Add a literal value to a GSettings string array when it is absent. |
| [`gsettings::string-array::remove`](modules/gsettings.md#gsettingsstring-arrayremove) | Remove every element equal to a literal value from a GSettings string array. |

## [`homebrew`](modules/homebrew.md)

| 関数 | 説明 |
|---|---|
| [`homebrew::install`](modules/homebrew.md#homebrewinstall) | Install Homebrew with the official installer when it is missing. |
| [`homebrew::cask::disable-quarantine`](modules/homebrew.md#homebrewcaskdisable-quarantine) | Install Homebrew casks without the quarantine attribute from now on. |

## [`i2c`](modules/i2c.md)

| 関数 | 説明 |
|---|---|
| [`i2c::bus::list`](modules/i2c.md#i2cbuslist) | Write the I2C buses with i2cdetect -l. |
| [`i2c::device::list`](modules/i2c.md#i2cdevicelist) | Write the devices on one I2C bus with i2cdetect -y. |

## [`iina`](modules/iina.md)

| 関数 | 説明 |
|---|---|
| [`iina::set-default-app`](modules/iina.md#iinaset-default-app) | Set IINA as the default application for video file extensions on macOS. |

## [`jdk`](modules/jdk.md)

| 関数 | 説明 |
|---|---|
| [`jdk::version::list`](modules/jdk.md#jdkversionlist) | Write JDK feature release numbers available to the current platform. |
| [`jdk::version::latest`](modules/jdk.md#jdkversionlatest) | Write the newest JDK feature release number available to the current platform. |
| [`jdk::install`](modules/jdk.md#jdkinstall) | Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH. |

## [`jenkins`](modules/jenkins.md)

| 関数 | 説明 |
|---|---|
| [`jenkins::restart`](modules/jenkins.md#jenkinsrestart) | Restart the Jenkins service through administrator execution. |

## [`jfrog`](modules/jfrog.md)

| 関数 | 説明 |
|---|---|
| [`jfrog::config::clear`](modules/jfrog.md#jfrogconfigclear) | Remove one JFrog CLI server configuration. |
| [`jfrog::config::clear-all`](modules/jfrog.md#jfrogconfigclear-all) | Remove every JFrog CLI server configuration. |
| [`jfrog::config::list`](modules/jfrog.md#jfrogconfiglist) | Display JFrog CLI server configurations. |
| [`jfrog::setup`](modules/jfrog.md#jfrogsetup) | Register and verify a JFrog CLI server. |

## [`keyboard`](modules/keyboard.md)

| 関数 | 説明 |
|---|---|
| [`keyboard::system-layout::set`](modules/keyboard.md#keyboardsystem-layoutset) | Set the system keyboard layout. |
| [`keyboard::setup-ime-keys`](modules/keyboard.md#keyboardsetup-ime-keys) | Map the Convert and Nonconvert keys of USB keyboards to henkan and muhenkan. |

## [`ltrace`](modules/ltrace.md)

| 関数 | 説明 |
|---|---|
| [`ltrace::attach-pid`](modules/ltrace.md#ltraceattach-pid) | Attach ltrace to a process on Linux. |
| [`ltrace::attach-name`](modules/ltrace.md#ltraceattach-name) | Attach ltrace to the first process whose executable name is NAME. |

## [`mac`](modules/mac.md)

| 関数 | 説明 |
|---|---|
| [`mac::wake-on-lan::enable`](modules/mac.md#macwake-on-lanenable) | Let the Mac wake from sleep through the network (Wake on LAN). |
| [`mac::sleep::disable-automatic`](modules/mac.md#macsleepdisable-automatic) | Disable automatic system sleep while preserving display sleep timers. |
| [`mac::sleep::enable-automatic`](modules/mac.md#macsleepenable-automatic) | Enable automatic system sleep after ten minutes while preserving display sleep timers. |
| [`mac::software-update::enable-automatic-install`](modules/mac.md#macsoftware-updateenable-automatic-install) | Let macOS updates install automatically. |
| [`mac::software-update::disable-automatic-install`](modules/mac.md#macsoftware-updatedisable-automatic-install) | Keep macOS updates downloading but stop their automatic installation. |
| [`mac::keyboard::use-function-keys`](modules/mac.md#mackeyboarduse-function-keys) | Make F1 to F12 act as function keys without the fn key. |
| [`mac::keyboard::set-repeat`](modules/mac.md#mackeyboardset-repeat) | Set the delay before key repeat starts and the repeat interval. |
| [`mac::trackpad::disable-smart-zoom`](modules/mac.md#mactrackpaddisable-smart-zoom) | Turn off smart zoom, the two-finger double tap, on built-in and external trackpads. |
| [`mac::dock::set-autohide-instant`](modules/mac.md#macdockset-autohide-instant) | Show and hide the Dock immediately, without a delay or an animation. |
| [`mac::dock::hide-recent-applications`](modules/mac.md#macdockhide-recent-applications) | Hide recently used applications in the Dock. |
| [`mac::dock::set-minimize-effect`](modules/mac.md#macdockset-minimize-effect) | Set the effect used when a window is minimized into the Dock. |
| [`mac::dock::set-position`](modules/mac.md#macdockset-position) | Place the Dock on one edge of the screen. |
| [`mac::applications::remove-bundled`](modules/mac.md#macapplicationsremove-bundled) | Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications. |
| [`mac::quarantine::remove-applications`](modules/mac.md#macquarantineremove-applications) | Remove the quarantine attribute from everything below /Applications. |
| [`mac::full-disk-access::target-paths`](modules/mac.md#macfull-disk-accesstarget-paths) | Write the programs that Full Disk Access must list for a command, a path, or an application. |
| [`mac::full-disk-access::open`](modules/mac.md#macfull-disk-accessopen) | Open Full Disk Access in System Settings and show the programs to add in Finder. |
| [`mac::full-disk-access::is-granted`](modules/mac.md#macfull-disk-accessis-granted) | Test whether the application that runs the current shell has Full Disk Access. |
| [`mac::gatekeeper::disable`](modules/mac.md#macgatekeeperdisable) | Ask macOS to allow applications from anywhere and open Privacy & Security. |
| [`mac::setup`](modules/mac.md#macsetup) | Apply the complete macOS setup, continuing after failed steps. |
| [`mac::keyboard::disable-option-t`](modules/mac.md#mackeyboarddisable-option-t) | Disable the Option+T key binding on macOS. |

## [`mem`](modules/mem.md)

| 関数 | 説明 |
|---|---|
| [`mem::physical-total-bytes`](modules/mem.md#memphysical-total-bytes) | Write the total physical memory in bytes. |
| [`mem::physical-total-gibibytes`](modules/mem.md#memphysical-total-gibibytes) | Write the total physical memory in gibibytes. |
| [`mem::swap::total-bytes`](modules/mem.md#memswaptotal-bytes) | Write the total swap capacity in bytes. |
| [`mem::swap::total-gibibytes`](modules/mem.md#memswaptotal-gibibytes) | Write the total swap capacity in gibibytes. |
| [`mem::total-bytes`](modules/mem.md#memtotal-bytes) | Write the total memory and swap capacity in bytes. |
| [`mem::total-gibibytes`](modules/mem.md#memtotal-gibibytes) | Write the total memory and swap capacity in gibibytes. |
| [`mem::swap::disable-all`](modules/mem.md#memswapdisable-all) | Disable every active swap area through administrator execution. |
| [`mem::swap::remove-all-files`](modules/mem.md#memswapremove-all-files) | Disable every swap file, remove its /etc/fstab entry, and delete it. |
| [`mem::swap::create`](modules/mem.md#memswapcreate) | Create a swap file, enable it, and register it in /etc/fstab. |
| [`mem::swap::list`](modules/mem.md#memswaplist) | List active swap devices. |
| [`mem::swap::ensure-total-size`](modules/mem.md#memswapensure-total-size) | Extend swap capacity up to a target size. |

## [`microsoft-edge`](modules/microsoft-edge.md)

| 関数 | 説明 |
|---|---|
| [`microsoft-edge::versions`](modules/microsoft-edge.md#microsoft-edgeversions) | Write Microsoft Edge versions available to the current platform. |
| [`microsoft-edge::install`](modules/microsoft-edge.md#microsoft-edgeinstall) | Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew. |

## [`mozc`](modules/mozc.md)

| 関数 | 説明 |
|---|---|
| [`mozc::config::open`](modules/mozc.md#mozcconfigopen) | Open the Mozc settings dialog on a Linux desktop. |
| [`mozc::server::versions`](modules/mozc.md#mozcserverversions) | Write Mozc server versions provided for the running operating-system release. |
| [`mozc::server::install`](modules/mozc.md#mozcserverinstall) | Install the Mozc server, defaulting to the newest version for the running release. |
| [`mozc::ibus::versions`](modules/mozc.md#mozcibusversions) | Write IBus Mozc versions provided for the running operating-system release. |
| [`mozc::ibus::install`](modules/mozc.md#mozcibusinstall) | Install IBus Mozc and the Mozc server of the same version. |
| [`mozc::tool::versions`](modules/mozc.md#mozctoolversions) | Write Mozc GUI tool versions provided for the running operating-system release. |
| [`mozc::tool::install`](modules/mozc.md#mozctoolinstall) | Install the Mozc GUI tools. |
| [`mozc::ibus::set-hiragana-as-default`](modules/mozc.md#mozcibusset-hiragana-as-default) | Start Mozc in Hiragana mode and restart IBus. |

## [`net`](modules/net.md)

| 関数 | 説明 |
|---|---|
| [`net::ip::set-static`](modules/net.md#netipset-static) | Replace one Ubuntu Netplan file with a static IPv4 configuration. |
| [`net::interface::default`](modules/net.md#netinterfacedefault) | Write the first default-route interface. |
| [`net::gateway::default`](modules/net.md#netgatewaydefault) | Write the first default-route gateway. |
| [`net::ip::private-v4`](modules/net.md#netipprivate-v4) | Write the primary RFC 1918 IPv4 address of an interface. |
| [`net::ip::private-v6`](modules/net.md#netipprivate-v6) | Write the primary unique local IPv6 address of an interface. |
| [`net::ip::public`](modules/net.md#netippublic) | Write the public IP address reported by ifconfig.me. |
| [`net::dns::test`](modules/net.md#netdnstest) | Test whether a DNS name resolves. |
| [`net::ping`](modules/net.md#netping) | Send ICMP echo requests to a host. |
| [`net::tcp::test`](modules/net.md#nettcptest) | Test whether a TCP connection to HOST and PORT succeeds, without output. |
| [`net::capture-host`](modules/net.md#netcapture-host) | Capture packets addressed to a host. |
| [`net::unused-port`](modules/net.md#netunused-port) | Write a TCP port number the operating system reports as unused. |
| [`net::dns::servers`](modules/net.md#netdnsservers) | Write the configured IPv4 and IPv6 DNS servers, one per line. |
| [`net::dns::manager`](modules/net.md#netdnsmanager) | Write the current DNS manager: systemd-resolved, network-manager, or unknown. |
| [`net::dns::use-systemd-resolved`](modules/net.md#netdnsuse-systemd-resolved) | Make systemd-resolved manage DNS and /etc/resolv.conf. |
| [`net::dns::use-network-manager`](modules/net.md#netdnsuse-network-manager) | Make NetworkManager manage DNS and /etc/resolv.conf directly. |
| [`net::dns::use-google`](modules/net.md#netdnsuse-google) | Configure Google Public DNS while keeping the current DNS manager. |

## [`node`](modules/node.md)

| 関数 | 説明 |
|---|---|
| [`node::versions`](modules/node.md#nodeversions) | Write complete stable Node.js versions from the selected source. |
| [`node::install`](modules/node.md#nodeinstall) | Install Node.js, enable Corepack, and set the pnpm store directory. |

## [`opencode`](modules/opencode.md)

| 関数 | 説明 |
|---|---|
| [`opencode::install`](modules/opencode.md#opencodeinstall) | Install the newest OpenCode command-line application. |

## [`pass`](modules/pass.md)

| 関数 | 説明 |
|---|---|
| [`pass::store::remove`](modules/pass.md#passstoreremove) | Remove a pass store and everything in it. |
| [`pass::store::init`](modules/pass.md#passstoreinit) | Initialize a pass store for a GPG key without removing an existing store. |
| [`pass::versions`](modules/pass.md#passversions) | Write pass versions available to the current platform. |
| [`pass::install`](modules/pass.md#passinstall) | Install pass from the platform package manager. |

## [`pci`](modules/pci.md)

| 関数 | 説明 |
|---|---|
| [`pci::device::list`](modules/pci.md#pcidevicelist) | Write the PCI devices with lspci. |

## [`pipx`](modules/pipx.md)

| 関数 | 説明 |
|---|---|
| [`pipx::versions`](modules/pipx.md#pipxversions) | Write pipx versions available from the selected source. |
| [`pipx::install`](modules/pipx.md#pipxinstall) | Install pipx and add the pipx application directory to PATH. |

## [`plantuml`](modules/plantuml.md)

| 関数 | 説明 |
|---|---|
| [`plantuml::versions`](modules/plantuml.md#plantumlversions) | Write PlantUML versions available to the current platform. |
| [`plantuml::install`](modules/plantuml.md#plantumlinstall) | Install PlantUML from the platform package manager. |

## [`plist`](modules/plist.md)

| 関数 | 説明 |
|---|---|
| [`plist::set`](modules/plist.md#plistset) | Set a string value for one top-level key in a macOS property list. |

## [`process`](modules/process.md)

| 関数 | 説明 |
|---|---|
| [`process::ids-by-name`](modules/process.md#processids-by-name) | Write the IDs of the processes whose executable name is exactly NAME, one per line. |
| [`process::ids-by-name-regex`](modules/process.md#processids-by-name-regex) | Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f. |
| [`process::threads-by-pid`](modules/process.md#processthreads-by-pid) | Write the threads of one process. |
| [`process::threads-by-name`](modules/process.md#processthreads-by-name) | Write the threads of the first process whose executable name is NAME. |

## [`qmk`](modules/qmk.md)

| 関数 | 説明 |
|---|---|
| [`qmk::toolbox::install`](modules/qmk.md#qmktoolboxinstall) | Install QMK Toolbox with Homebrew on macOS. |
| [`qmk::cli::install`](modules/qmk.md#qmkcliinstall) | Install the QMK CLI with the official installer and diagnose the environment. |

## [`rancher-desktop`](modules/rancher-desktop.md)

| 関数 | 説明 |
|---|---|
| [`rancher-desktop::versions`](modules/rancher-desktop.md#rancher-desktopversions) | Write Rancher Desktop versions available to the current platform. |
| [`rancher-desktop::install`](modules/rancher-desktop.md#rancher-desktopinstall) | Install Rancher Desktop and start it. |

## [`repo`](modules/repo.md)

| 関数 | 説明 |
|---|---|
| [`repo::init`](modules/repo.md#repoinit) | Initialize a Google Repo workspace with shallow history. |
| [`repo::sync`](modules/repo.md#reposync) | Synchronize one path of a Google Repo workspace, forcing the sync. |
| [`repo::write-manifest`](modules/repo.md#repowrite-manifest) | Write the current Google Repo manifest with revisions to a file. |
| [`repo::check`](modules/repo.md#repocheck) | Run git fsck in every project of a Google Repo workspace. |
| [`repo::reset`](modules/repo.md#reporeset) | Hard reset every project of a Google Repo workspace and remove untracked files. |

## [`rosetta`](modules/rosetta.md)

| 関数 | 説明 |
|---|---|
| [`rosetta::install`](modules/rosetta.md#rosettainstall) | Install Rosetta when it is missing, accepting its license. |

## [`ruby`](modules/ruby.md)

| 関数 | 説明 |
|---|---|
| [`ruby::version::list`](modules/ruby.md#rubyversionlist) | Write stable Ruby versions that rbenv can install in ascending order. |
| [`ruby::version::latest`](modules/ruby.md#rubyversionlatest) | Write the newest stable Ruby version that rbenv can install. |
| [`ruby::install`](modules/ruby.md#rubyinstall) | Install rbenv, configure the shell, and install a Ruby version globally. |

## [`rust`](modules/rust.md)

| 関数 | 説明 |
|---|---|
| [`rust::install`](modules/rust.md#rustinstall) | Install Rust using rustup and an optional toolchain version. |
| [`rust::versions`](modules/rust.md#rustversions) | Write the stable Rust versions, oldest first, from the rust-lang/rust releases. |

## [`screen`](modules/screen.md)

| 関数 | 説明 |
|---|---|
| [`screen::open`](modules/screen.md#screenopen) | Open a GNU Screen session. |
| [`screen::open-serial`](modules/screen.md#screenopen-serial) | Open a serial device in GNU Screen through administrator execution and log the session. |
| [`screen::kill-all`](modules/screen.md#screenkill-all) | End every GNU Screen process of every user through administrator execution. |

## [`selinux`](modules/selinux.md)

| 関数 | 説明 |
|---|---|
| [`selinux::generate-rule`](modules/selinux.md#selinuxgenerate-rule) | Generate SELinux allow rules from the AVC denials of an audit log. |

## [`serial`](modules/serial.md)

| 関数 | 説明 |
|---|---|
| [`serial::configure`](modules/serial.md#serialconfigure) | Open a serial device with a configured baud rate. |
| [`serial::write`](modules/serial.md#serialwrite) | Write literal data to a serial device. |
| [`serial::write-command`](modules/serial.md#serialwrite-command) | Write a command and terminator to a serial device. |
| [`serial::release`](modules/serial.md#serialrelease) | Release a serial device so another process, such as a Python tool, can open it. |

## [`ssh`](modules/ssh.md)

| 関数 | 説明 |
|---|---|
| [`ssh::setup-directory`](modules/ssh.md#sshsetup-directory) | Create $HOME/.ssh and give it and its files the modes SSH expects. |
| [`ssh::config::update`](modules/ssh.md#sshconfigupdate) | Update one key in a marker-managed SSH Host block. |
| [`ssh::config::set`](modules/ssh.md#sshconfigset) | Create an SSH configuration file when necessary and update one key. |
| [`ssh::config::enable-auto-add-keys`](modules/ssh.md#sshconfigenable-auto-add-keys) | Enable AddKeysToAgent for an optional SSH Host pattern. |
| [`ssh::config::disable-host-key-checking`](modules/ssh.md#sshconfigdisable-host-key-checking) | Disable SSH host-key checks for an optional Host pattern. |
| [`ssh::key::private-files`](modules/ssh.md#sshkeyprivate-files) | List regular files that ssh-keygen can read as private keys. |
| [`ssh::key::add`](modules/ssh.md#sshkeyadd) | Add one private key to ssh-agent. |
| [`ssh::key::add-all`](modules/ssh.md#sshkeyadd-all) | Add every detected private key in a directory to ssh-agent. |
| [`ssh::key::add-all-private-keys`](modules/ssh.md#sshkeyadd-all-private-keys) | Add every detected private key in a directory to ssh-agent. |
| [`ssh::key::generate-rsa4096`](modules/ssh.md#sshkeygenerate-rsa4096) | Generate a 4096-bit RSA SSH key and write its public key. |
| [`ssh::key::generate-ed25519`](modules/ssh.md#sshkeygenerate-ed25519) | Generate an Ed25519 SSH key and write its public key. |
| [`ssh::kill-all`](modules/ssh.md#sshkill-all) | End every SSH process of the current user. |
| [`ssh::server::versions`](modules/ssh.md#sshserverversions) | Write OpenSSH server versions available to the current platform. |
| [`ssh::server::install`](modules/ssh.md#sshserverinstall) | Install the OpenSSH server, enable it at boot, and start it. |

## [`storage`](modules/storage.md)

| 関数 | 説明 |
|---|---|
| [`storage::usage`](modules/storage.md#storageusage) | Show human-readable filesystem usage for a path. |
| [`storage::largest-entries`](modules/storage.md#storagelargest-entries) | Write the largest entries of a directory, including the directory itself, in human-readable sizes. |
| [`storage::clear-trash`](modules/storage.md#storageclear-trash) | Empty the Linux desktop trash of the current user through administrator execution. |

## [`strace`](modules/strace.md)

| 関数 | 説明 |
|---|---|
| [`strace::attach-pid`](modules/strace.md#straceattach-pid) | Attach strace to a process on Linux. |
| [`strace::attach-name`](modules/strace.md#straceattach-name) | Attach strace to the first process whose executable name is NAME. |

## [`sudo`](modules/sudo.md)

| 関数 | 説明 |
|---|---|
| [`sudo::start-keep-alive`](modules/sudo.md#sudostart-keep-alive) | Keep the sudo credentials of the calling process fresh in the background. |
| [`sudo::passwordless::enable`](modules/sudo.md#sudopasswordlessenable) | Let a user run every command through sudo without entering a password. |
| [`sudo::passwordless::disable`](modules/sudo.md#sudopasswordlessdisable) | Remove the passwordless sudo rule that sudo::passwordless::enable added. |

## [`supabase`](modules/supabase.md)

| 関数 | 説明 |
|---|---|
| [`supabase::versions`](modules/supabase.md#supabaseversions) | Write Supabase CLI versions available to the current platform. |
| [`supabase::install`](modules/supabase.md#supabaseinstall) | Install the Supabase CLI from its Homebrew tap or release packages. |

## [`symlink`](modules/symlink.md)

| 関数 | 説明 |
|---|---|
| [`symlink::create`](modules/symlink.md#symlinkcreate) | Create or replace a symbolic link that points to the absolute path of an existing SOURCE. |
| [`symlink::remove`](modules/symlink.md#symlinkremove) | Remove a symbolic link, using administrator execution only when its directory is not writable. |
| [`symlink::create-in-local-bin`](modules/symlink.md#symlinkcreate-in-local-bin) | Create a symbolic link in a user's local bin directory. |

## [`systemd`](modules/systemd.md)

| 関数 | 説明 |
|---|---|
| [`systemd::file`](modules/systemd.md#systemdfile) | Write the path of the file that defines a systemd unit. |
| [`systemd::dependencies`](modules/systemd.md#systemddependencies) | Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines. |
| [`systemd::restart`](modules/systemd.md#systemdrestart) | Restart a systemd unit through administrator execution. |
| [`systemd::start`](modules/systemd.md#systemdstart) | Start a systemd unit through administrator execution. |
| [`systemd::stop`](modules/systemd.md#systemdstop) | Stop a systemd unit through administrator execution. |
| [`systemd::enable`](modules/systemd.md#systemdenable) | Enable a systemd unit at boot through administrator execution. |
| [`systemd::disable`](modules/systemd.md#systemddisable) | Disable a systemd unit at boot through administrator execution. |
| [`systemd::status`](modules/systemd.md#systemdstatus) | Write the current state of a systemd unit and return the status of systemctl status. |
| [`systemd::service::list`](modules/systemd.md#systemdservicelist) | Write every loaded systemd service, including stopped ones. |
| [`systemd::service::list-running`](modules/systemd.md#systemdservicelist-running) | Write the running systemd services. |
| [`systemd::service::list-failed`](modules/systemd.md#systemdservicelist-failed) | Write the failed systemd services. |
| [`systemd::service::list-files`](modules/systemd.md#systemdservicelist-files) | Write every systemd service unit file and its enablement state. |

## [`textproto`](modules/textproto.md)

| 関数 | 説明 |
|---|---|
| [`textproto::set-scalar`](modules/textproto.md#textprotoset-scalar) | Replace or append one top-level scalar field in a textproto file. |

## [`thunderbird`](modules/thunderbird.md)

| 関数 | 説明 |
|---|---|
| [`thunderbird::versions`](modules/thunderbird.md#thunderbirdversions) | Write Thunderbird versions available to the current platform. |
| [`thunderbird::install`](modules/thunderbird.md#thunderbirdinstall) | Install the Thunderbird email client. |

## [`ubuntu`](modules/ubuntu.md)

| 関数 | 説明 |
|---|---|
| [`ubuntu::server-iso-versions`](modules/ubuntu.md#ubuntuserver-iso-versions) | Write the Ubuntu Server LTS versions whose live server ISO is published for an architecture. |
| [`ubuntu::download-server-iso`](modules/ubuntu.md#ubuntudownload-server-iso) | Download an Ubuntu Server live ISO and check it against the official SHA256SUMS. |
| [`ubuntu::setup`](modules/ubuntu.md#ubuntusetup) | Apply the common Ubuntu user configuration, stopping at the first failure. |
| [`ubuntu::setup-external`](modules/ubuntu.md#ubuntusetup-external) | Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available. |
| [`ubuntu::setup-desktop`](modules/ubuntu.md#ubuntusetup-desktop) | Apply the Ubuntu user configuration and desktop settings, stopping at the first failure. |
| [`ubuntu::setup-desktop-22`](modules/ubuntu.md#ubuntusetup-desktop-22) | Install the newest Mozc for Ubuntu 22.04 and apply the desktop settings. |

## [`usb`](modules/usb.md)

| 関数 | 説明 |
|---|---|
| [`usb::device::list`](modules/usb.md#usbdevicelist) | Write the USB devices with lsusb. |
| [`usb::partition::select`](modules/usb.md#usbpartitionselect) | Select a USB partition, or a USB disk without partitions, and write its device path. |
| [`usb::filesystem::repair`](modules/usb.md#usbfilesystemrepair) | Select a USB file system, unmount it, and repair it through administrator execution. |
| [`usb::filesystem::format-fat32`](modules/usb.md#usbfilesystemformat-fat32) | Select a USB partition, unmount it, and format it as FAT32 through administrator execution. |

## [`user`](modules/user.md)

| 関数 | 説明 |
|---|---|
| [`user::name`](modules/user.md#username) | Write the effective user's name. |
| [`user::primary-group`](modules/user.md#userprimary-group) | Write the effective user's primary group name. |
| [`user::is-root`](modules/user.md#useris-root) | Test whether the effective user is root. |
| [`user::exists`](modules/user.md#userexists) | Test whether a local user account exists. |
| [`user::create-system-as-root`](modules/user.md#usercreate-system-as-root) | Create a non-login system account in a separate root process. |
| [`user::create-login-as-root`](modules/user.md#usercreate-login-as-root) | Create a local login account in a separate root process. |
| [`user::create-system`](modules/user.md#usercreate-system) | Create a non-login system account. |
| [`user::create-login`](modules/user.md#usercreate-login) | Create a local login account. |
| [`user::add-to-group`](modules/user.md#useradd-to-group) | Add a user to a supplementary group through administrator execution. |
| [`user::directory::create-english-links`](modules/user.md#userdirectorycreate-english-links) | Link the English XDG user directory names to the directories of the current locale. |

## [`utm`](modules/utm.md)

| 関数 | 説明 |
|---|---|
| [`utm::open`](modules/utm.md#utmopen) | Open the UTM application on macOS. |
| [`utm::versions`](modules/utm.md#utmversions) | Write UTM release versions. |
| [`utm::install`](modules/utm.md#utminstall) | Install UTM from its release disk image on macOS. |

## [`vlc`](modules/vlc.md)

| 関数 | 説明 |
|---|---|
| [`vlc::set-default-app`](modules/vlc.md#vlcset-default-app) | Set VLC as the default application for every MIME type it declares. |

## [`vscode`](modules/vscode.md)

| 関数 | 説明 |
|---|---|
| [`vscode::remove-user-data`](modules/vscode.md#vscoderemove-user-data) | Remove the VS Code user data directory. |
| [`vscode::set-default-app`](modules/vscode.md#vscodeset-default-app) | Set VS Code as the default application for text and source file types on macOS. |
| [`vscode::versions`](modules/vscode.md#vscodeversions) | Write VS Code versions available to the current platform. |
| [`vscode::install`](modules/vscode.md#vscodeinstall) | Install VS Code from the Microsoft repository or Homebrew. |

## [`xcode`](modules/xcode.md)

| 関数 | 説明 |
|---|---|
| [`xcode::command-line-tools::upgrade`](modules/xcode.md#xcodecommand-line-toolsupgrade) | Update Xcode Command Line Tools without removing the installed tools. |
