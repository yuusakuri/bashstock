# 関数リファレンス

BashStockが公開する関数を名前空間ごとに示します。
各関数の引数、出力、終了状態、例は、名前空間のページと`help__show 関数名`で確認できます。
このファイルと`modules/`は`scripts/docs`が`src/`のshdocコメントから生成します。直接編集しないでください。

関数名と入出力の規則は[ライブラリ仕様](../specifications/library.md)、名前付き引数とTab補完は[名前付き引数とTab補完の仕様](../specifications/named-arguments.md)で定義します。

`-as-root`で終わる関数は、通常権限と管理者権限のどちらで実行するかを呼び出し側が選べる操作です。
管理者権限を常に必要とする操作と、書き込み権限が不足した場合に昇格する操作は、関数名に`-as-root`を付けません。

## [`number`](modules/number.md)

| 関数 | 説明 |
|---|---|
| [`number__is-integer`](modules/number.md#number__is-integer) | Test whether a value is a signed or unsigned decimal integer. |
| [`number__is-decimal`](modules/number.md#number__is-decimal) | Test whether a value is a signed or unsigned decimal fraction. |
| [`number__is-number`](modules/number.md#number__is-number) | Test whether a value is a decimal integer or fraction. |

## [`string`](modules/string.md)

| 関数 | 説明 |
|---|---|
| [`string__trim`](modules/string.md#string__trim) | Remove leading and trailing whitespace. |
| [`string__collapse-whitespace`](modules/string.md#string__collapse-whitespace) | Trim whitespace and collapse each interior run to one ASCII space. |
| [`string__split`](modules/string.md#string__split) | Split a value by a non-empty literal delimiter and preserve empty fields. |
| [`string__lower`](modules/string.md#string__lower) | Convert ASCII uppercase letters to lowercase. |
| [`string__upper`](modules/string.md#string__upper) | Convert ASCII lowercase letters to uppercase. |
| [`string__swap-case`](modules/string.md#string__swap-case) | Swap the case of every ASCII letter. |
| [`string__lower-first`](modules/string.md#string__lower-first) | Convert the first ASCII letter to lowercase when applicable. |
| [`string__upper-first`](modules/string.md#string__upper-first) | Convert the first ASCII letter to uppercase when applicable. |
| [`string__strip-surrounding-quotes`](modules/string.md#string__strip-surrounding-quotes) | Remove one matching pair of surrounding single or double quotes. |
| [`string__remove-all-matches`](modules/string.md#string__remove-all-matches) | Remove every substring that matches a Bash pattern. |
| [`string__remove-first-match`](modules/string.md#string__remove-first-match) | Remove the first substring that matches a Bash pattern. |
| [`string__remove-prefix`](modules/string.md#string__remove-prefix) | Remove the longest prefix that matches a Bash pattern. |
| [`string__remove-suffix`](modules/string.md#string__remove-suffix) | Remove the longest suffix that matches a Bash pattern. |
| [`string__encode-url`](modules/string.md#string__encode-url) | Percent-encode a UTF-8 string byte by byte. |
| [`string__decode-url`](modules/string.md#string__decode-url) | Decode percent-encoded bytes without translating plus signs. |
| [`string__contains`](modules/string.md#string__contains) | Test whether a value contains a literal substring. |
| [`string__starts-with`](modules/string.md#string__starts-with) | Test whether a value starts with a literal prefix. |
| [`string__ends-with`](modules/string.md#string__ends-with) | Test whether a value ends with a literal suffix. |
| [`string__join`](modules/string.md#string__join) | Join values with a literal delimiter. |
| [`string__byte-length`](modules/string.md#string__byte-length) | Write the byte length of a value. |
| [`string__length`](modules/string.md#string__length) | Write the character length of a value in a UTF-8 locale. |
| [`string__replace-first`](modules/string.md#string__replace-first) | Replace the first substring that matches a Bash pattern. |
| [`string__replace-all`](modules/string.md#string__replace-all) | Replace every substring that matches a Bash pattern. |
| [`string__replace-last`](modules/string.md#string__replace-last) | Replace the rightmost non-empty substring that matches a Bash pattern. |
| [`string__require-non-empty`](modules/string.md#string__require-non-empty) | Require a named value to be non-empty. |
| [`string__require-empty`](modules/string.md#string__require-empty) | Require a named value to be empty. |
| [`string__require-allowed`](modules/string.md#string__require-allowed) | Require a named value to equal one of the allowed values. |
| [`string__slice`](modules/string.md#string__slice) | Write a validated character range from a UTF-8 string. |

## [`regex`](modules/regex.md)

| 関数 | 説明 |
|---|---|
| [`regex__is-match`](modules/regex.md#regex__is-match) | Test a value against a Bash POSIX extended regular expression. |
| [`regex__capture-group`](modules/regex.md#regex__capture-group) | Write one capture group from a Bash POSIX extended regular expression. |
| [`regex__capture-groups`](modules/regex.md#regex__capture-groups) | Write all capture groups from a Bash POSIX extended regular expression. |

## [`array`](modules/array.md)

| 関数 | 説明 |
|---|---|
| [`array__contains`](modules/array.md#array__contains) | Test whether the remaining arguments contain the expected value. |
| [`array__reverse`](modules/array.md#array__reverse) | Write the arguments in reverse order, one value per line. |
| [`array__length`](modules/array.md#array__length) | Write the number of arguments. |
| [`array__first`](modules/array.md#array__first) | Write the first argument when one is available. |
| [`array__last`](modules/array.md#array__last) | Write the last argument when one is available. |
| [`array__unique`](modules/array.md#array__unique) | Write each distinct argument once in its original order. |
| [`array__prepend-to-each`](modules/array.md#array__prepend-to-each) | Prefix every value and write one result per line. |

## [`arg`](modules/arg.md)

| 関数 | 説明 |
|---|---|
| [`arg__require-next`](modules/arg.md#arg__require-next) | Require a value to follow the current named argument. |
| [`arg__require`](modules/arg.md#arg__require) | Require a named argument to have a non-empty value. |
| [`arg__integer`](modules/arg.md#arg__integer) | Require a named argument value to be a decimal integer. |
| [`arg__one-of`](modules/arg.md#arg__one-of) | Require a named argument value to match one candidate. |
| [`arg__unknown`](modules/arg.md#arg__unknown) | Report a named argument that no case branch recognized. |
| [`arg__completion__dispatch`](modules/arg.md#arg__completion__dispatch) | Dispatch Tab completion to the target function's completion helper. |
| [`arg__completion__register-all`](modules/arg.md#arg__completion__register-all) | Register Tab completion for every function that has a completion helper. |

## [`help`](modules/help.md)

| 関数 | 説明 |
|---|---|
| [`help__show`](modules/help.md#help__show) | Show the documentation of a BashStock function, like Get-Help in PowerShell. |

## [`system`](modules/system.md)

| 関数 | 説明 |
|---|---|
| [`system__operating-system`](modules/system.md#system__operating-system) | Write the normalized operating-system family. |
| [`system__host-name`](modules/system.md#system__host-name) | Write the current host name. |
| [`system__kernel-name`](modules/system.md#system__kernel-name) | Write the kernel name. |
| [`system__distribution-name`](modules/system.md#system__distribution-name) | Write the distribution name. |
| [`system__enable-sleep`](modules/system.md#system__enable-sleep) | Enable system sleep. |
| [`system__disable-sleep`](modules/system.md#system__disable-sleep) | Disable system sleep. |
| [`system__disable-auto-lock`](modules/system.md#system__disable-auto-lock) | Disable automatic screen locking for the current user. |
| [`system__enable-auto-lock`](modules/system.md#system__enable-auto-lock) | Enable automatic screen locking for the current user. |

## [`command`](modules/command.md)

| 関数 | 説明 |
|---|---|
| [`command__exists`](modules/command.md#command__exists) | Test whether a command name resolves in the current environment. |
| [`command__require`](modules/command.md#command__require) | Require a command name to resolve in the current environment. |
| [`command__run-as-root`](modules/command.md#command__run-as-root) | Run a command directly as root or through validated sudo access. |

## [`shell`](modules/shell.md)

| 関数 | 説明 |
|---|---|
| [`shell__is-function-defined`](modules/shell.md#shell__is-function-defined) | Test whether a shell function is defined. |
| [`shell__editor__set-default`](modules/shell.md#shell__editor__set-default) | Set the default editor of new Bash and Zsh sessions and the current process. |
| [`shell__completion__enable-ignore-case`](modules/shell.md#shell__completion__enable-ignore-case) | Make Bash and Zsh completion ignore letter case. |
| [`shell__zsh__enable-interactive-comments`](modules/shell.md#shell__zsh__enable-interactive-comments) | Allow comments that start with # in interactive Zsh sessions. |
| [`shell__confirm`](modules/shell.md#shell__confirm) | Read and normalize a yes-or-no answer. |
| [`shell__read-line`](modules/shell.md#shell__read-line) | Read one line and substitute a default only for empty input. |
| [`shell__confirm-or-cancel`](modules/shell.md#shell__confirm-or-cancel) | Read and normalize a yes, no, or cancel answer. |
| [`shell__choose-one`](modules/shell.md#shell__choose-one) | Display indexed choices and write the selected value. |
| [`shell__pause`](modules/shell.md#shell__pause) | Wait for one line from the controlling terminal. |

## [`terminal`](modules/terminal.md)

| 関数 | 説明 |
|---|---|
| [`terminal__is-available`](modules/terminal.md#terminal__is-available) | Test whether the controlling terminal is readable and writable. |
| [`terminal__open`](modules/terminal.md#terminal__open) | Open a new window of the desktop's default terminal application. |

## [`path`](modules/path.md)

| 関数 | 説明 |
|---|---|
| [`path__directory-name`](modules/path.md#path__directory-name) | Write the lexical directory portion of a path. |
| [`path__base-name`](modules/path.md#path__base-name) | Write the final component of a path with an optional suffix removed. |
| [`path__is-directory`](modules/path.md#path__is-directory) | Test whether a path names a directory. |
| [`path__is-empty-directory`](modules/path.md#path__is-empty-directory) | Test whether a path names an empty directory. |
| [`path__is-executable`](modules/path.md#path__is-executable) | Test whether the current user may execute a path. |
| [`path__is-executable-file`](modules/path.md#path__is-executable-file) | Test whether a path names an executable regular file. |
| [`path__is-regular-file`](modules/path.md#path__is-regular-file) | Test whether a path names a regular file. |
| [`path__is-symbolic-link`](modules/path.md#path__is-symbolic-link) | Test whether a path names a symbolic link. |
| [`path__is-readable`](modules/path.md#path__is-readable) | Test whether the current user may read a path. |
| [`path__is-writable`](modules/path.md#path__is-writable) | Test whether the current user may write a path. |
| [`path__mode`](modules/path.md#path__mode) | Write a path's permission mode as an octal number. |
| [`path__extension`](modules/path.md#path__extension) | Write the extension of the final path component. |
| [`path__normalize`](modules/path.md#path__normalize) | Normalize a path lexically without accessing the file system. |
| [`path__relative`](modules/path.md#path__relative) | Write the lexical relative path from one path to another. |
| [`path__config-home`](modules/path.md#path__config-home) | Write the absolute configuration-home directory. |
| [`path__change-owner-recursively`](modules/path.md#path__change-owner-recursively) | Change directory ownership recursively through the root helper. |
| [`path__change-owner-recursively-as-root`](modules/path.md#path__change-owner-recursively-as-root) | Change directory ownership recursively in a separate root process. |
| [`path__find`](modules/path.md#path__find) | Write the paths below a directory that match a case-insensitive Bash ERE, separated by NUL. |

## [`time`](modules/time.md)

| 関数 | 説明 |
|---|---|
| [`time__monotonic-milliseconds`](modules/time.md#time__monotonic-milliseconds) | Write monotonic milliseconds that exclude suspended time. |
| [`time__boot-time-milliseconds`](modules/time.md#time__boot-time-milliseconds) | Write milliseconds since boot including suspended time. |
| [`time__unix-milliseconds`](modules/time.md#time__unix-milliseconds) | Write Unix-epoch milliseconds. |
| [`time__unix-seconds`](modules/time.md#time__unix-seconds) | Write Unix-epoch seconds rounded down. |
| [`time__unix-days`](modules/time.md#time__unix-days) | Write Unix-epoch days rounded down. |
| [`time__utc-date-time-milliseconds-extended`](modules/time.md#time__utc-date-time-milliseconds-extended) | Write the current UTC date and time in ISO 8601 extended format with milliseconds. |
| [`time__utc-date-time-seconds-extended`](modules/time.md#time__utc-date-time-seconds-extended) | Write the current UTC date and time in ISO 8601 extended format with seconds. |
| [`time__utc-date-extended`](modules/time.md#time__utc-date-extended) | Write the current UTC date in ISO 8601 extended format. |
| [`time__local-date-time-milliseconds-extended`](modules/time.md#time__local-date-time-milliseconds-extended) | Write the current local date and time in ISO 8601 extended format with milliseconds and an offset. |
| [`time__local-date-time-seconds-extended`](modules/time.md#time__local-date-time-seconds-extended) | Write the current local date and time in ISO 8601 extended format with seconds and an offset. |
| [`time__local-date-extended`](modules/time.md#time__local-date-extended) | Write the current local date in ISO 8601 extended format. |
| [`time__local-date-time-seconds-basic`](modules/time.md#time__local-date-time-seconds-basic) | Write the current local date and time in ISO 8601 basic format with seconds. |
| [`time__sleep-hours`](modules/time.md#time__sleep-hours) | Sleep for a non-negative integer number of hours. |
| [`time__posix-timezone`](modules/time.md#time__posix-timezone) | Write the POSIX TZ string for a UTC offset. |
| [`time__status-continuous`](modules/time.md#time__status-continuous) | Write the elapsed time since boot and the local time every three seconds until stopped. |

## [`log`](modules/log.md)

| 関数 | 説明 |
|---|---|
| [`log__info`](modules/log.md#log__info) | Write an informational log message. |
| [`log__warn`](modules/log.md#log__warn) | Write a warning log message. |
| [`log__error`](modules/log.md#log__error) | Write an error log message without exiting. |

## [`json`](modules/json.md)

| 関数 | 説明 |
|---|---|
| [`json__require-present`](modules/json.md#json__require-present) | Require a named JSON-derived value to be neither empty nor null. |

## [`option`](modules/option.md)

| 関数 | 説明 |
|---|---|
| [`option__require-single`](modules/option.md#option__require-single) | Require exactly one named option value to be non-empty. |

## [`file`](modules/file.md)

| 関数 | 説明 |
|---|---|
| [`file__ensure-exists`](modules/file.md#file__ensure-exists) | Create an empty regular file when it does not exist. |
| [`file__contains-match`](modules/file.md#file__contains-match) | Test whether any file line matches a Python regular expression. |
| [`file__verify-sha256`](modules/file.md#file__verify-sha256) | Test a file against an expected SHA-256 digest. |
| [`file__append-text`](modules/file.md#file__append-text) | Append text without conversion, elevating only when permissions require it. |
| [`file__replace-text`](modules/file.md#file__replace-text) | Replace the first Bash ERE match on every file line. |
| [`file__replace-all-text`](modules/file.md#file__replace-all-text) | Replace every nonempty Bash ERE match on every file line. |
| [`file__replace-text-in-files`](modules/file.md#file__replace-text-in-files) | Replace line matches across multiple files. |
| [`file__replace-all-text-in-files`](modules/file.md#file__replace-all-text-in-files) | Replace every line match across multiple files. |
| [`file__replace-text-or-append`](modules/file.md#file__replace-text-or-append) | Replace every line match or append one line when no match exists. |
| [`file__replace-or-append-text`](modules/file.md#file__replace-or-append-text) | Replace matching text or append it using the established API name. |
| [`file__append-text-as-root`](modules/file.md#file__append-text-as-root) | Append text through the root execution dispatcher. |
| [`file__replace-text-as-root`](modules/file.md#file__replace-text-as-root) | Replace the first expression match through the root execution dispatcher. |
| [`file__replace-all-text-as-root`](modules/file.md#file__replace-all-text-as-root) | Replace every expression match through the root execution dispatcher. |
| [`file__replace-text-in-files-as-root`](modules/file.md#file__replace-text-in-files-as-root) | Replace expression matches in files through the root execution dispatcher. |
| [`file__replace-all-text-in-files-as-root`](modules/file.md#file__replace-all-text-in-files-as-root) | Replace all expression matches in files through the root execution dispatcher. |
| [`file__replace-or-append-text-as-root`](modules/file.md#file__replace-or-append-text-as-root) | Replace matching text or append it through the root execution dispatcher. |
| [`file__write-text`](modules/file.md#file__write-text) | Write text to a regular file using an atomic replacement. |
| [`file__find-by-content`](modules/file.md#file__find-by-content) | Write the regular files below a directory whose content matches an ERE, separated by NUL. |
| [`file__latest-by-name`](modules/file.md#file__latest-by-name) | Write the most recently modified regular file whose base name matches a Bash ERE. |
| [`file__edit`](modules/file.md#file__edit) | Open an editor for a file, using sudoedit only when required. |
| [`file__release`](modules/file.md#file__release) | Release a file held by other processes. |
| [`file__tree-with-contents`](modules/file.md#file__tree-with-contents) | Write the directories and text files below a path, with the contents of each text file. |
| [`file__modified-time-unix-seconds`](modules/file.md#file__modified-time-unix-seconds) | Write the last modification time of a file as Unix seconds. |

## [`adb`](modules/adb.md)

| 関数 | 説明 |
|---|---|
| [`adb__device__wait`](modules/adb.md#adb__device__wait) | Wait for an ADB device to connect, optionally selected with --serial. |
| [`adb__device__pull`](modules/adb.md#adb__device__pull) | Copy files from an ADB device to the host. |
| [`adb__device__push`](modules/adb.md#adb__device__push) | Copy files from the host to an ADB device. |
| [`adb__logcat__clear`](modules/adb.md#adb__logcat__clear) | Clear the selected device log buffers. |
| [`adb__logcat__once`](modules/adb.md#adb__logcat__once) | Write the selected device log buffers once. |
| [`adb__logcat__continuous`](modules/adb.md#adb__logcat__continuous) | Stream logs from the selected device. |
| [`adb__device__reboot`](modules/adb.md#adb__device__reboot) | Reboot the selected device. |
| [`adb__device__first`](modules/adb.md#adb__device__first) | Write the first connected ADB device serial. |
| [`adb__device__list`](modules/adb.md#adb__device__list) | List connected ADB device serials. |
| [`adb__device__wait-for-path`](modules/adb.md#adb__device__wait-for-path) | Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout. |
| [`adb__device__screen__capture-once`](modules/adb.md#adb__device__screen__capture-once) | Save one screenshot atomically and print its path. |
| [`adb__device__select-and-pull`](modules/adb.md#adb__device__select-and-pull) | Select one requested device path and pull it to the host. |
| [`adb__device__bootloader__enter`](modules/adb.md#adb__device__bootloader__enter) | Reboot the selected device into its bootloader. |
| [`adb__device__bootloader__unlock`](modules/adb.md#adb__device__bootloader__unlock) | Request bootloader unlocking and wait for the device to reconnect. |
| [`adb__device__verity__disable`](modules/adb.md#adb__device__verity__disable) | Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects. |
| [`adb__device__partition__remount`](modules/adb.md#adb__device__partition__remount) | Make the system partitions of a rooted device writable. |
| [`adb__device__build__fingerprint`](modules/adb.md#adb__device__build__fingerprint) | Write the selected device build fingerprint. |
| [`adb__device__build__date`](modules/adb.md#adb__device__build__date) | Write the selected device build timestamp as Unix seconds. |
| [`adb__device__slot__suffix`](modules/adb.md#adb__device__slot__suffix) | Write the selected device active slot suffix. |
| [`adb__device__build__kernel-version`](modules/adb.md#adb__device__build__kernel-version) | Write the selected device kernel release. |
| [`adb__device__screen__capture-continuous`](modules/adb.md#adb__device__screen__capture-continuous) | Save repeated screenshots; MAX_COUNT of zero runs until interrupted. |
| [`adb__device__partition__sha256`](modules/adb.md#adb__device__partition__sha256) | Write a device partition SHA-256 checksum. |
| [`adb__wake__lock`](modules/adb.md#adb__wake__lock) | Hold a kernel wake lock using a tag, defaulting to debug. |
| [`adb__wake__unlock`](modules/adb.md#adb__wake__unlock) | Release a kernel wake lock using the same tag. |
| [`adb__wake__list`](modules/adb.md#adb__wake__list) | Print active kernel wake locks. |
| [`adb__device__set-default`](modules/adb.md#adb__device__set-default) | Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL. |
| [`adb__server__start`](modules/adb.md#adb__server__start) | Start the host ADB server. |
| [`adb__server__stop`](modules/adb.md#adb__server__stop) | Stop the host ADB server. |
| [`adb__server__restart`](modules/adb.md#adb__server__restart) | Stop and then start the host ADB server. |

## [`android`](modules/android.md)

| 関数 | 説明 |
|---|---|
| [`android__sdk__directory`](modules/android.md#android__sdk__directory) | Write the SDK directory selected by Android Studio or the caller. |
| [`android__cli__install`](modules/android.md#android__cli__install) | Install the official Android CLI without replacing a working copy on failure. |
| [`android__sdk__install`](modules/android.md#android__sdk__install) | Create and configure the selected SDK directory and Android CLI. |
| [`android__platform-tools__install`](modules/android.md#android__platform-tools__install) | Install Android Platform Tools and add adb and fastboot to PATH. |
| [`android__sdk-platform__install`](modules/android.md#android__sdk-platform__install) | Install an Android SDK Platform and verify its android.jar file. |
| [`android__build-tools__install`](modules/android.md#android__build-tools__install) | Install one stable Build Tools version and add its executables to PATH. |
| [`android__emulator__install`](modules/android.md#android__emulator__install) | Install the Android Emulator into the selected SDK. |
| [`android__command-line-tools__install`](modules/android.md#android__command-line-tools__install) | Install SDK Command-line Tools and verify sdkmanager and avdmanager. |
| [`android__avd__list`](modules/android.md#android__avd__list) | List AVD names in the selected Android SDK environment. |
| [`android__avd__profiles`](modules/android.md#android__avd__profiles) | List hardware profiles available to avdmanager. |
| [`android__system-images__versions`](modules/android.md#android__system-images__versions) | List stable system images as API, tag, ABI, and revision values. |
| [`android__avd__create`](modules/android.md#android__avd__create) | Create one AVD from a stable Google APIs image without starting it. |
| [`android__avd__port__available`](modules/android.md#android__avd__port__available) | Report whether an even emulator console port and its ADB port are both free. |
| [`android__avd__port__first`](modules/android.md#android__avd__port__first) | Write the first free emulator console port. |
| [`android__avd__start`](modules/android.md#android__avd__start) | Start one AVD and wait for Android to finish booting. |
| [`android__avd__stop`](modules/android.md#android__avd__stop) | Stop the named AVD, or the only running AVD when no name is given. |
| [`android__avd__delete`](modules/android.md#android__avd__delete) | Delete one named AVD without changing other AVDs. |
| [`android__build-tools__versions`](modules/android.md#android__build-tools__versions) | Write available stable Android Build Tools versions in ascending order. |
| [`android__build-tools__latest-version`](modules/android.md#android__build-tools__latest-version) | Write the newest available stable Android Build Tools version. |

## [`apt`](modules/apt.md)

| 関数 | 説明 |
|---|---|
| [`apt__package__candidates`](modules/apt.md#apt__package__candidates) | Write APT packages whose names start with PREFIX followed by a digit, with candidate versions. |
| [`apt__package__latest`](modules/apt.md#apt__package__latest) | Write the APT package name with the newest version suffix after PREFIX. |
| [`apt__deb__install-from-url`](modules/apt.md#apt__deb__install-from-url) | Download a Debian package and install it with its dependencies through APT. |

## [`archive`](modules/archive.md)

| 関数 | 説明 |
|---|---|
| [`archive__verify`](modules/archive.md#archive__verify) | Verify all recognized archives below a path. |
| [`archive__remove-broken`](modules/archive.md#archive__remove-broken) | Remove archives that fail verification. |
| [`archive__extract-file`](modules/archive.md#archive__extract-file) | Extract one archive or decompress one compressed file. |
| [`archive__compress-tar-gzip`](modules/archive.md#archive__compress-tar-gzip) | Compress paths into a gzip-compressed tar archive. |
| [`archive__extract`](modules/archive.md#archive__extract) | Extract one archive, or every recognized archive below a directory, next to itself. |

## [`asciidoc`](modules/asciidoc.md)

| 関数 | 説明 |
|---|---|
| [`asciidoc__html`](modules/asciidoc.md#asciidoc__html) | Convert AsciiDoc to HTML with diagram support. |

## [`aws`](modules/aws.md)

| 関数 | 説明 |
|---|---|
| [`aws__is-ec2-instance`](modules/aws.md#aws__is-ec2-instance) | Test whether IMDSv2 is available for the current instance. |
| [`aws__instance-metadata`](modules/aws.md#aws__instance-metadata) | Write one validated EC2 instance metadata value. |
| [`aws__instance-id`](modules/aws.md#aws__instance-id) | Write the current EC2 instance identifier. |
| [`aws__instance-region`](modules/aws.md#aws__instance-region) | Write the current EC2 instance region. |
| [`aws__instance-availability-zone`](modules/aws.md#aws__instance-availability-zone) | Write the current EC2 instance availability zone. |
| [`aws__instance-private-ip`](modules/aws.md#aws__instance-private-ip) | Write the current EC2 instance private IPv4 address. |
| [`aws__instance-tags`](modules/aws.md#aws__instance-tags) | Write all tags for one EC2 instance. |
| [`aws__instance-tag`](modules/aws.md#aws__instance-tag) | Write one EC2 instance tag value. |
| [`aws__wait-for-instance-tag`](modules/aws.md#aws__wait-for-instance-tag) | Wait for one EC2 instance tag to become available. |
| [`aws__instances-with-tag`](modules/aws.md#aws__instances-with-tag) | Write EC2 instances that have a requested tag. |
| [`aws__auto-scaling-group`](modules/aws.md#aws__auto-scaling-group) | Write the Auto Scaling group that contains an EC2 instance. |
| [`aws__instances-in-auto-scaling-group`](modules/aws.md#aws__instances-in-auto-scaling-group) | Write running or pending instances in an Auto Scaling group. |
| [`aws__auto-scaling-group-name`](modules/aws.md#aws__auto-scaling-group-name) | Write the current instance's Auto Scaling group name. |
| [`aws__auto-scaling-group-size`](modules/aws.md#aws__auto-scaling-group-size) | Write the desired capacity of an Auto Scaling group. |
| [`aws__vpn-client__log__files`](modules/aws.md#aws__vpn-client__log__files) | Write AWS VPN Client log files as NUL-separated paths. |
| [`aws__vpn-client__log__clear`](modules/aws.md#aws__vpn-client__log__clear) | Remove regular log files below the AWS VPN Client log directory. |
| [`aws__vpn-client__log__open`](modules/aws.md#aws__vpn-client__log__open) | Open log files with an editor command, passing each path as one argument. |

## [`brave`](modules/brave.md)

| 関数 | 説明 |
|---|---|
| [`brave__versions`](modules/brave.md#brave__versions) | Write Brave versions available to the current platform. |
| [`brave__install`](modules/brave.md#brave__install) | Install Brave from its official repository or Homebrew. |

## [`chatgpt`](modules/chatgpt.md)

| 関数 | 説明 |
|---|---|
| [`chatgpt__install`](modules/chatgpt.md#chatgpt__install) | Install the newest ChatGPT desktop app, which also runs Codex. |

## [`chrome`](modules/chrome.md)

| 関数 | 説明 |
|---|---|
| [`chrome__profile__export-bookmarks`](modules/chrome.md#chrome__profile__export-bookmarks) | Export a Chrome profile's Bookmarks file. |
| [`chrome__profile__export-preferences`](modules/chrome.md#chrome__profile__export-preferences) | Export a Chrome profile's Preferences file. |
| [`chrome__profile__email`](modules/chrome.md#chrome__profile__email) | Write the first known email address from a Chrome profile. |
| [`chrome__profile__find-by-email`](modules/chrome.md#chrome__profile__find-by-email) | Find Chrome profiles whose known email matches literally. |
| [`chrome__profile__export-user-data-by-email`](modules/chrome.md#chrome__profile__export-user-data-by-email) | Export Chrome Preferences and Bookmarks for profiles whose email matches literally. |
| [`chrome__versions`](modules/chrome.md#chrome__versions) | Write Google Chrome versions available to the current platform. |
| [`chrome__install`](modules/chrome.md#chrome__install) | Install Google Chrome from the Google repository or Homebrew. |

## [`claude-code`](modules/claude-code.md)

| 関数 | 説明 |
|---|---|
| [`claude-code__install`](modules/claude-code.md#claude-code__install) | Install the newest Claude Code CLI. |

## [`claude-desktop`](modules/claude-desktop.md)

| 関数 | 説明 |
|---|---|
| [`claude-desktop__install`](modules/claude-desktop.md#claude-desktop__install) | Install the newest Claude Desktop, the app that also runs Claude Code sessions. |

## [`codex`](modules/codex.md)

| 関数 | 説明 |
|---|---|
| [`codex__install`](modules/codex.md#codex__install) | Install the newest OpenAI Codex CLI. |

## [`colima`](modules/colima.md)

| 関数 | 説明 |
|---|---|
| [`colima__versions`](modules/colima.md#colima__versions) | Write Colima versions available from Homebrew. |
| [`colima__install`](modules/colima.md#colima__install) | Install Colima with Homebrew on macOS and start it. |

## [`device-tree`](modules/device-tree.md)

| 関数 | 説明 |
|---|---|
| [`device-tree__node__list`](modules/device-tree.md#device-tree__node__list) | Write the node paths of the Linux device tree. |

## [`dir`](modules/dir.md)

| 関数 | 説明 |
|---|---|
| [`dir__diff`](modules/dir.md#dir__diff) | Run diff for two directories. |
| [`dir__merge`](modules/dir.md#dir__merge) | Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE. |
| [`dir__create-with-date-time`](modules/dir.md#dir__create-with-date-time) | Create a directory named with the local date and time and write its path. |
| [`dir__clear`](modules/dir.md#dir__clear) | Remove every entry of a directory, including hidden ones, and keep the directory. |

## [`discord`](modules/discord.md)

| 関数 | 説明 |
|---|---|
| [`discord__install`](modules/discord.md#discord__install) | Install the newest Discord desktop app. |

## [`docker`](modules/docker.md)

| 関数 | 説明 |
|---|---|
| [`docker__container__list-running`](modules/docker.md#docker__container__list-running) | List running Docker containers. |
| [`docker__container__list`](modules/docker.md#docker__container__list) | List Docker containers. |
| [`docker__container__pull`](modules/docker.md#docker__container__pull) | Copy files between a Docker container and the host. |
| [`docker__container__push`](modules/docker.md#docker__container__push) | Copy a host path into a container. |
| [`docker__container__shell`](modules/docker.md#docker__container__shell) | Run an interactive shell or a command in a container. |
| [`docker__container__logs`](modules/docker.md#docker__container__logs) | Follow the log of a container. |
| [`docker__container__stop`](modules/docker.md#docker__container__stop) | Stop a container. |
| [`docker__container__start`](modules/docker.md#docker__container__start) | Start a container. |
| [`docker__container__stop-all`](modules/docker.md#docker__container__stop-all) | Stop every running container; having none is a success. |
| [`docker__container__remove-all`](modules/docker.md#docker__container__remove-all) | Remove every container, running or not. |
| [`docker__volume__remove-all`](modules/docker.md#docker__volume__remove-all) | Remove every Docker volume. |
| [`docker__remove-all`](modules/docker.md#docker__remove-all) | Remove every container and then every volume, stopping at the first failure. |
| [`docker__login-artifactory`](modules/docker.md#docker__login-artifactory) | Log in to an Artifactory Docker registry using a token on standard input. |
| [`docker__versions`](modules/docker.md#docker__versions) | Write Docker Engine or Docker CLI versions available to the current platform. |
| [`docker__install`](modules/docker.md#docker__install) | Install the Docker CLI, and Docker Engine on Linux. |

## [`electron`](modules/electron.md)

| 関数 | 説明 |
|---|---|
| [`electron__wayland__enable`](modules/electron.md#electron__wayland__enable) | Prefer native Wayland rendering for Electron applications in a Wayland session. |
| [`electron__wayland__disable`](modules/electron.md#electron__wayland__disable) | Remove BashStock's native Wayland preference for Electron applications. |

## [`env`](modules/env.md)

| 関数 | 説明 |
|---|---|
| [`env__dotenv__import`](modules/env.md#env__dotenv__import) | Import the variables of a dotenv file into the current process. |
| [`env__set-variable`](modules/env.md#env__set-variable) | Set an environment variable for the current shell. |
| [`env__add-path`](modules/env.md#env__add-path) | Add a directory to PATH without creating duplicates. |
| [`env__dotenv__register`](modules/env.md#env__dotenv__register) | Load a dotenv file in every new Bash and Zsh session. |

## [`fedora`](modules/fedora.md)

| 関数 | 説明 |
|---|---|
| [`fedora__setup`](modules/fedora.md#fedora__setup) | Apply the common Fedora user configuration, stopping at the first failure. |
| [`fedora__setup-external`](modules/fedora.md#fedora__setup-external) | Install GnuPG, GitHub CLI, and Git Credential Manager on Fedora when they are not already available. |

## [`flutter`](modules/flutter.md)

| 関数 | 説明 |
|---|---|
| [`flutter__run-chrome-release`](modules/flutter.md#flutter__run-chrome-release) | Run a Flutter project in Chrome in release mode. |
| [`flutter__run-linux-release`](modules/flutter.md#flutter__run-linux-release) | Run a Flutter project as a Linux desktop application in release mode. |
| [`flutter__test`](modules/flutter.md#flutter__test) | Run the Flutter tests of a project with optional flutter test arguments. |
| [`flutter__coverage`](modules/flutter.md#flutter__coverage) | Run the Flutter tests with coverage and write the LCOV HTML report. |
| [`flutter__use-version`](modules/flutter.md#flutter__use-version) | Keep Flutter SDK changes in a retrievable stash and switch versions. |
| [`flutter__versions`](modules/flutter.md#flutter__versions) | Write stable Flutter SDK versions for the current platform. |
| [`flutter__dependencies__install`](modules/flutter.md#flutter__dependencies__install) | Install packages required to build Flutter applications. |
| [`flutter__install`](modules/flutter.md#flutter__install) | Install dependencies and select a stable Flutter SDK version. |

## [`gdb`](modules/gdb.md)

| 関数 | 説明 |
|---|---|
| [`gdb__attach-pid`](modules/gdb.md#gdb__attach-pid) | Attach GDB in batch mode to a process and write the backtrace of every thread. |
| [`gdb__server__start`](modules/gdb.md#gdb__server__start) | Start COMMAND with its arguments under gdbserver listening on PORT. |
| [`gdb__connect`](modules/gdb.md#gdb__connect) | Load ELF in GDB and connect to the GDB server at HOST and PORT. |
| [`gdb__run-until`](modules/gdb.md#gdb__run-until) | Run ELF in GDB with optional program arguments and stop at SYMBOL. |
| [`gdb__core__open`](modules/gdb.md#gdb__core__open) | Open ELF and a core dump in GDB. |
| [`gdb__attach-by-name`](modules/gdb.md#gdb__attach-by-name) | Attach GDB to the first process whose executable name is NAME. |

## [`gerrit`](modules/gerrit.md)

| 関数 | 説明 |
|---|---|
| [`gerrit__push-review`](modules/gerrit.md#gerrit__push-review) | Push the current HEAD to a Gerrit review reference. |
| [`gerrit__push-review-wip`](modules/gerrit.md#gerrit__push-review-wip) | Push the current HEAD to a Gerrit review reference as work in progress. |

## [`gh`](modules/gh.md)

| 関数 | 説明 |
|---|---|
| [`gh__install`](modules/gh.md#gh__install) | Install GitHub CLI from its official Ubuntu APT or Fedora DNF repository. |

## [`gimp`](modules/gimp.md)

| 関数 | 説明 |
|---|---|
| [`gimp__versions`](modules/gimp.md#gimp__versions) | Write GIMP versions available to the current platform. |
| [`gimp__install`](modules/gimp.md#gimp__install) | Install GIMP, and on Linux the G'MIC plugin from the selected source. |
| [`gimp__gmic__versions`](modules/gimp.md#gimp__gmic__versions) | Write G'MIC GIMP plugin versions available from the selected source. |
| [`gimp__gmic__install`](modules/gimp.md#gimp__gmic__install) | Install the G'MIC GIMP plugin. |

## [`git`](modules/git.md)

| 関数 | 説明 |
|---|---|
| [`git__commit__edit-via-rebase`](modules/git.md#git__commit__edit-via-rebase) | Start an interactive rebase that stops at one non-merge commit for editing. |
| [`git__clone-shallow`](modules/git.md#git__clone-shallow) | Clone a repository with depth one. |
| [`git__rebase-abort`](modules/git.md#git__rebase-abort) | Abort an in-progress rebase. |
| [`git__rebase-continue`](modules/git.md#git__rebase-continue) | Continue an in-progress rebase. |
| [`git__commit__amend`](modules/git.md#git__commit__amend) | Amend the last commit without changing its message. |
| [`git__commit__create`](modules/git.md#git__commit__create) | Create a commit with a message. |
| [`git__commit__uncommit`](modules/git.md#git__commit__uncommit) | Remove the last commit while keeping its changes staged. |
| [`git__branch__current`](modules/git.md#git__branch__current) | Write the current branch name. |
| [`git__branch__create`](modules/git.md#git__branch__create) | Create a branch at a starting revision. |
| [`git__branch__list`](modules/git.md#git__branch__list) | List local and remote-tracking branches. |
| [`git__diff__files`](modules/git.md#git__diff__files) | Show file names changed between two revisions. |
| [`git__diff__patch`](modules/git.md#git__diff__patch) | Show a patch between two revisions. |
| [`git__diff__uncommitted-patch`](modules/git.md#git__diff__uncommitted-patch) | Show the patch for uncommitted tracked changes. |
| [`git__diff__uncommitted-files`](modules/git.md#git__diff__uncommitted-files) | Show file names changed by uncommitted tracked changes. |
| [`git__diff__latest-patch`](modules/git.md#git__diff__latest-patch) | Show the patch introduced by the latest commit. |
| [`git__diff__latest-files`](modules/git.md#git__diff__latest-files) | Show file names changed by the latest commit. |
| [`git__commit__patch`](modules/git.md#git__commit__patch) | Write the unified diff that one commit introduced. |
| [`git__commit__revert-without-commit`](modules/git.md#git__commit__revert-without-commit) | Revert a commit without creating a commit. |
| [`git__commit__revert`](modules/git.md#git__commit__revert) | Revert a commit and create the revert commit. |
| [`git__fetch`](modules/git.md#git__fetch) | Fetch one remote or all remotes. |
| [`git__fetch-unshallow`](modules/git.md#git__fetch-unshallow) | Convert a shallow clone into a complete history. |
| [`git__stash__patch`](modules/git.md#git__stash__patch) | Show a stash patch. |
| [`git__stash__push`](modules/git.md#git__stash__push) | Save tracked changes and untracked files in a new stash. |
| [`git__stash__pop`](modules/git.md#git__stash__pop) | Apply and remove a stash. |
| [`git__stash__drop`](modules/git.md#git__stash__drop) | Delete a stash. |
| [`git__reset`](modules/git.md#git__reset) | Reset a working tree to a revision. |
| [`git__pull-rebase`](modules/git.md#git__pull-rebase) | Update a branch from a remote with rebase. |
| [`git__cherry-pick`](modules/git.md#git__cherry-pick) | Apply one commit, fetching it from a remote only when the repository lacks it. |
| [`git__cherry-pick-continue`](modules/git.md#git__cherry-pick-continue) | Continue an in-progress cherry-pick. |
| [`git__cherry-pick-abort`](modules/git.md#git__cherry-pick-abort) | Abort an in-progress cherry-pick. |
| [`git__push`](modules/git.md#git__push) | Push a branch to a remote. |
| [`git__push__force-with-lease`](modules/git.md#git__push__force-with-lease) | Push a branch without overwriting a remote update. |
| [`git__remote__delete-branch`](modules/git.md#git__remote__delete-branch) | Delete a branch on a remote. |
| [`git__submodule__update-all`](modules/git.md#git__submodule__update-all) | Update all submodules recursively. |
| [`git__commit__discard`](modules/git.md#git__commit__discard) | Discard all changes in a working tree. |
| [`git__reset-remote`](modules/git.md#git__reset-remote) | Hard reset the current branch to the branch with the same name on a remote. |
| [`git__pull-base-branch`](modules/git.md#git__pull-base-branch) | Pull the configured base branch with fast-forward-only semantics. |
| [`git__rebase-base-branch`](modules/git.md#git__rebase-base-branch) | Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one. |
| [`git__credentials__remove`](modules/git.md#git__credentials__remove) | Remove $HOME/.git-credentials and the global credential.helper; both may be absent. |
| [`git__config__enable-origin-all-fetch`](modules/git.md#git__config__enable-origin-all-fetch) | Make origin fetch every branch in a repository. |
| [`git__config__enable-prune-fetch`](modules/git.md#git__config__enable-prune-fetch) | Enable pruning on fetch in the global Git configuration. |
| [`git__config__set-default-branch`](modules/git.md#git__config__set-default-branch) | Set the default branch name of new repositories. |
| [`git__config__enable-rebase-on-pull`](modules/git.md#git__config__enable-rebase-on-pull) | Enable rebase on pull in the global Git configuration. |
| [`git__config__set-email`](modules/git.md#git__config__set-email) | Set the global Git email address. |
| [`git__config__set-username`](modules/git.md#git__config__set-username) | Set the global Git user name. |
| [`git__config__set-http-buffer`](modules/git.md#git__config__set-http-buffer) | Set the global Git HTTP post buffer. |
| [`git__config__use-gpg-credential-store`](modules/git.md#git__config__use-gpg-credential-store) | Make Git Credential Manager store credentials with GPG and pass. |
| [`git__config__use-credential-manager`](modules/git.md#git__config__use-credential-manager) | Use Git Credential Manager as the global credential helper. |
| [`git__config__use-osx-keychain`](modules/git.md#git__config__use-osx-keychain) | Use the macOS Keychain as the global Git credential helper. |
| [`git__config__setup`](modules/git.md#git__config__setup) | Apply the user identity and the standard global Git settings. |
| [`git__stash__list`](modules/git.md#git__stash__list) | List stashes. |

## [`git-credential-manager`](modules/git-credential-manager.md)

| 関数 | 説明 |
|---|---|
| [`git-credential-manager__version__list`](modules/git-credential-manager.md#git-credential-manager__version__list) | Write the installed Git Credential Manager version. |
| [`git-credential-manager__install`](modules/git-credential-manager.md#git-credential-manager__install) | Install an official Git Credential Manager release for this OS and CPU. |

## [`gnome`](modules/gnome.md)

| 関数 | 説明 |
|---|---|
| [`gnome__keybinding__set-custom`](modules/gnome.md#gnome__keybinding__set-custom) | Register a GNOME custom keyboard shortcut after removing conflicting shortcuts. |
| [`gnome__input-source__set-layout`](modules/gnome.md#gnome__input-source__set-layout) | Set GNOME input sources to Mozc followed by one XKB layout. |
| [`gnome__keyboard-layout__set-us`](modules/gnome.md#gnome__keyboard-layout__set-us) | Set GNOME input sources and the system keyboard layout to Mozc and US. |
| [`gnome__keyboard-layout__set-jp`](modules/gnome.md#gnome__keyboard-layout__set-jp) | Set GNOME input sources and the system keyboard layout to Mozc and JP. |
| [`gnome__input-source__set-shortcuts`](modules/gnome.md#gnome__input-source__set-shortcuts) | Set GNOME input-source switching shortcuts and direct US and Mozc shortcuts. |
| [`gnome__input-source__setup-ime-keys`](modules/gnome.md#gnome__input-source__setup-ime-keys) | Bind Nonconvert to the US input source and Convert to Mozc. |
| [`gnome__input-source__set-mozc-first`](modules/gnome.md#gnome__input-source__set-mozc-first) | Put Mozc first in GNOME input sources while keeping the current XKB layout. |
| [`gnome__window__set-button-layout`](modules/gnome.md#gnome__window__set-button-layout) | Set the GNOME window title-bar button layout. |

## [`go`](modules/go.md)

| 関数 | 説明 |
|---|---|
| [`go__version__list`](modules/go.md#go__version__list) | Write the stable Go versions the platform package source offers, oldest first. |
| [`go__version__latest`](modules/go.md#go__version__latest) | Write the newest stable Go version from go__version__list. |
| [`go__repository__register`](modules/go.md#go__repository__register) | Register the official Go package source for the current platform. |
| [`go__install`](modules/go.md#go__install) | Install Go from the platform package source. |

## [`gpg`](modules/gpg.md)

| 関数 | 説明 |
|---|---|
| [`gpg__decrypt`](modules/gpg.md#gpg__decrypt) | Decrypt a GPG file to standard output without adding a newline. |
| [`gpg__public-key__armor`](modules/gpg.md#gpg__public-key__armor) | Write a public GPG key in ASCII armor. |
| [`gpg__secret-key__fingerprints`](modules/gpg.md#gpg__secret-key__fingerprints) | Write the fingerprints of every primary secret GPG key, one per line. |
| [`gpg__secret-key__list`](modules/gpg.md#gpg__secret-key__list) | Write the secret GPG keys in the human-readable GPG format. |
| [`gpg__setup`](modules/gpg.md#gpg__setup) | Create a GPG key and use it for pass, Git credentials, and Git commit signing. |
| [`gpg__key__generate`](modules/gpg.md#gpg__key__generate) | Generate a GPG primary key and an encryption subkey in one operation. |

## [`gpio`](modules/gpio.md)

| 関数 | 説明 |
|---|---|
| [`gpio__chip__list`](modules/gpio.md#gpio__chip__list) | Write the GPIO chips with gpiodetect. |
| [`gpio__line__list`](modules/gpio.md#gpio__line__list) | Write the GPIO lines of one chip, or of every chip, with gpioinfo. |

## [`graphviz`](modules/graphviz.md)

| 関数 | 説明 |
|---|---|
| [`graphviz__versions`](modules/graphviz.md#graphviz__versions) | Write Graphviz versions available to the current platform. |
| [`graphviz__install`](modules/graphviz.md#graphviz__install) | Install Graphviz from the platform package manager. |

## [`gsettings`](modules/gsettings.md)

| 関数 | 説明 |
|---|---|
| [`gsettings__string-array__add`](modules/gsettings.md#gsettings__string-array__add) | Add a literal value to a GSettings string array when it is absent. |
| [`gsettings__string-array__remove`](modules/gsettings.md#gsettings__string-array__remove) | Remove every element equal to a literal value from a GSettings string array. |

## [`homebrew`](modules/homebrew.md)

| 関数 | 説明 |
|---|---|
| [`homebrew__install`](modules/homebrew.md#homebrew__install) | Install Homebrew with the official installer when it is missing. |
| [`homebrew__cask__disable-quarantine`](modules/homebrew.md#homebrew__cask__disable-quarantine) | Install Homebrew casks without the quarantine attribute from now on. |

## [`i2c`](modules/i2c.md)

| 関数 | 説明 |
|---|---|
| [`i2c__bus__list`](modules/i2c.md#i2c__bus__list) | Write the I2C buses with i2cdetect -l. |
| [`i2c__device__list`](modules/i2c.md#i2c__device__list) | Write the devices on one I2C bus with i2cdetect -y. |

## [`iina`](modules/iina.md)

| 関数 | 説明 |
|---|---|
| [`iina__set-default-app`](modules/iina.md#iina__set-default-app) | Set IINA as the default application for video file extensions on macOS. |

## [`jdk`](modules/jdk.md)

| 関数 | 説明 |
|---|---|
| [`jdk__version__list`](modules/jdk.md#jdk__version__list) | Write JDK feature release numbers available to the current platform. |
| [`jdk__version__latest`](modules/jdk.md#jdk__version__latest) | Write the newest JDK feature release number available to the current platform. |
| [`jdk__install`](modules/jdk.md#jdk__install) | Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH. |

## [`jenkins`](modules/jenkins.md)

| 関数 | 説明 |
|---|---|
| [`jenkins__restart`](modules/jenkins.md#jenkins__restart) | Restart the Jenkins service through administrator execution. |

## [`jfrog`](modules/jfrog.md)

| 関数 | 説明 |
|---|---|
| [`jfrog__config__clear`](modules/jfrog.md#jfrog__config__clear) | Remove one JFrog CLI server configuration. |
| [`jfrog__config__clear-all`](modules/jfrog.md#jfrog__config__clear-all) | Remove every JFrog CLI server configuration. |
| [`jfrog__config__list`](modules/jfrog.md#jfrog__config__list) | Display JFrog CLI server configurations. |
| [`jfrog__setup`](modules/jfrog.md#jfrog__setup) | Register and verify a JFrog CLI server. |

## [`keyboard`](modules/keyboard.md)

| 関数 | 説明 |
|---|---|
| [`keyboard__system-layout__set`](modules/keyboard.md#keyboard__system-layout__set) | Set the system keyboard layout. |
| [`keyboard__setup-ime-keys`](modules/keyboard.md#keyboard__setup-ime-keys) | Map USB Convert, Nonconvert, LANG1, and LANG2 keys to henkan and muhenkan. |

## [`linux`](modules/linux.md)

| 関数 | 説明 |
|---|---|
| [`linux__setup`](modules/linux.md#linux__setup) | Apply the common Linux user configuration, stopping at the first failure. |

## [`ltrace`](modules/ltrace.md)

| 関数 | 説明 |
|---|---|
| [`ltrace__attach-pid`](modules/ltrace.md#ltrace__attach-pid) | Attach ltrace to a process on Linux. |
| [`ltrace__attach-name`](modules/ltrace.md#ltrace__attach-name) | Attach ltrace to the first process whose executable name is NAME. |

## [`mac`](modules/mac.md)

| 関数 | 説明 |
|---|---|
| [`mac__wake-on-lan__enable`](modules/mac.md#mac__wake-on-lan__enable) | Let the Mac wake from sleep through the network (Wake on LAN). |
| [`mac__sleep__disable-automatic`](modules/mac.md#mac__sleep__disable-automatic) | Disable automatic system sleep while preserving display sleep timers. |
| [`mac__sleep__enable-automatic`](modules/mac.md#mac__sleep__enable-automatic) | Enable automatic system sleep after ten minutes while preserving display sleep timers. |
| [`mac__software-update__enable-automatic-install`](modules/mac.md#mac__software-update__enable-automatic-install) | Let macOS updates install automatically. |
| [`mac__software-update__disable-automatic-install`](modules/mac.md#mac__software-update__disable-automatic-install) | Keep macOS updates downloading but stop their automatic installation. |
| [`mac__keyboard__use-function-keys`](modules/mac.md#mac__keyboard__use-function-keys) | Make F1 to F12 act as function keys without the fn key. |
| [`mac__keyboard__set-repeat`](modules/mac.md#mac__keyboard__set-repeat) | Set the delay before key repeat starts and the repeat interval. |
| [`mac__trackpad__disable-smart-zoom`](modules/mac.md#mac__trackpad__disable-smart-zoom) | Turn off smart zoom, the two-finger double tap, on built-in and external trackpads. |
| [`mac__dock__set-autohide-instant`](modules/mac.md#mac__dock__set-autohide-instant) | Show and hide the Dock immediately, without a delay or an animation. |
| [`mac__dock__hide-recent-applications`](modules/mac.md#mac__dock__hide-recent-applications) | Hide recently used applications in the Dock. |
| [`mac__dock__set-minimize-effect`](modules/mac.md#mac__dock__set-minimize-effect) | Set the effect used when a window is minimized into the Dock. |
| [`mac__dock__set-position`](modules/mac.md#mac__dock__set-position) | Place the Dock on one edge of the screen. |
| [`mac__applications__remove-bundled`](modules/mac.md#mac__applications__remove-bundled) | Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications. |
| [`mac__quarantine__remove-applications`](modules/mac.md#mac__quarantine__remove-applications) | Remove the quarantine attribute from everything below /Applications. |
| [`mac__full-disk-access__target-paths`](modules/mac.md#mac__full-disk-access__target-paths) | Write the programs that Full Disk Access must list for a command, a path, or an application. |
| [`mac__full-disk-access__open`](modules/mac.md#mac__full-disk-access__open) | Open Full Disk Access in System Settings and show the programs to add in Finder. |
| [`mac__full-disk-access__is-granted`](modules/mac.md#mac__full-disk-access__is-granted) | Test whether the application that runs the current shell has Full Disk Access. |
| [`mac__gatekeeper__disable`](modules/mac.md#mac__gatekeeper__disable) | Ask macOS to allow applications from anywhere and open Privacy & Security. |
| [`mac__setup`](modules/mac.md#mac__setup) | Apply the complete macOS setup, continuing after failed steps. |
| [`mac__keyboard__disable-option-t`](modules/mac.md#mac__keyboard__disable-option-t) | Disable the Option+T key binding on macOS. |

## [`mem`](modules/mem.md)

| 関数 | 説明 |
|---|---|
| [`mem__physical-total-bytes`](modules/mem.md#mem__physical-total-bytes) | Write the total physical memory in bytes. |
| [`mem__physical-total-gibibytes`](modules/mem.md#mem__physical-total-gibibytes) | Write the total physical memory in gibibytes. |
| [`mem__swap__total-bytes`](modules/mem.md#mem__swap__total-bytes) | Write the total swap capacity in bytes. |
| [`mem__swap__total-gibibytes`](modules/mem.md#mem__swap__total-gibibytes) | Write the total swap capacity in gibibytes. |
| [`mem__total-bytes`](modules/mem.md#mem__total-bytes) | Write the total memory and swap capacity in bytes. |
| [`mem__total-gibibytes`](modules/mem.md#mem__total-gibibytes) | Write the total memory and swap capacity in gibibytes. |
| [`mem__swap__disable-all`](modules/mem.md#mem__swap__disable-all) | Disable every active swap area through administrator execution. |
| [`mem__swap__remove-all-files`](modules/mem.md#mem__swap__remove-all-files) | Disable every swap file, remove its /etc/fstab entry, and delete it. |
| [`mem__swap__create`](modules/mem.md#mem__swap__create) | Create a swap file, enable it, and register it in /etc/fstab. |
| [`mem__swap__list`](modules/mem.md#mem__swap__list) | List active swap devices. |
| [`mem__swap__ensure-total-size`](modules/mem.md#mem__swap__ensure-total-size) | Extend swap capacity up to a target size. |

## [`microsoft-edge`](modules/microsoft-edge.md)

| 関数 | 説明 |
|---|---|
| [`microsoft-edge__versions`](modules/microsoft-edge.md#microsoft-edge__versions) | Write Microsoft Edge versions available to the current platform. |
| [`microsoft-edge__install`](modules/microsoft-edge.md#microsoft-edge__install) | Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew. |

## [`mozc`](modules/mozc.md)

| 関数 | 説明 |
|---|---|
| [`mozc__config__open`](modules/mozc.md#mozc__config__open) | Open the Mozc settings dialog on a Linux desktop. |
| [`mozc__server__versions`](modules/mozc.md#mozc__server__versions) | Write Mozc server versions provided for the running operating-system release. |
| [`mozc__server__install`](modules/mozc.md#mozc__server__install) | Install the Mozc server, defaulting to the newest version for the running release. |
| [`mozc__ibus__versions`](modules/mozc.md#mozc__ibus__versions) | Write IBus Mozc versions provided for the running operating-system release. |
| [`mozc__ibus__install`](modules/mozc.md#mozc__ibus__install) | Install IBus Mozc and the Mozc server of the same version. |
| [`mozc__ibus__upgrade`](modules/mozc.md#mozc__ibus__upgrade) | Install IBus Mozc on Ubuntu, or upgrade it when the release offers a newer version. |
| [`mozc__tool__versions`](modules/mozc.md#mozc__tool__versions) | Write Mozc GUI tool versions provided for the running operating-system release. |
| [`mozc__tool__install`](modules/mozc.md#mozc__tool__install) | Install the Mozc GUI tools. |
| [`mozc__ibus__set-hiragana-as-default`](modules/mozc.md#mozc__ibus__set-hiragana-as-default) | Start Mozc in Hiragana mode and restart IBus. |

## [`net`](modules/net.md)

| 関数 | 説明 |
|---|---|
| [`net__ip__set-static`](modules/net.md#net__ip__set-static) | Replace one Ubuntu Netplan file with a static IPv4 configuration. |
| [`net__interface__default`](modules/net.md#net__interface__default) | Write the first default-route interface. |
| [`net__gateway__default`](modules/net.md#net__gateway__default) | Write the first default-route gateway. |
| [`net__ip__private-v4`](modules/net.md#net__ip__private-v4) | Write the primary RFC 1918 IPv4 address of an interface. |
| [`net__ip__private-v6`](modules/net.md#net__ip__private-v6) | Write the primary unique local IPv6 address of an interface. |
| [`net__ip__public`](modules/net.md#net__ip__public) | Write the public IP address reported by ifconfig.me. |
| [`net__dns__test`](modules/net.md#net__dns__test) | Test whether a DNS name resolves. |
| [`net__ping`](modules/net.md#net__ping) | Send ICMP echo requests to a host. |
| [`net__tcp__test`](modules/net.md#net__tcp__test) | Test whether a TCP connection to HOST and PORT succeeds, without output. |
| [`net__capture-host`](modules/net.md#net__capture-host) | Capture packets addressed to a host. |
| [`net__unused-port`](modules/net.md#net__unused-port) | Write a TCP port number the operating system reports as unused. |
| [`net__dns__servers`](modules/net.md#net__dns__servers) | Write the configured IPv4 and IPv6 DNS servers, one per line. |
| [`net__dns__manager`](modules/net.md#net__dns__manager) | Write the current DNS manager: systemd-resolved, network-manager, or unknown. |
| [`net__dns__use-systemd-resolved`](modules/net.md#net__dns__use-systemd-resolved) | Make systemd-resolved manage DNS and /etc/resolv.conf. |
| [`net__dns__use-network-manager`](modules/net.md#net__dns__use-network-manager) | Make NetworkManager manage DNS and /etc/resolv.conf directly. |
| [`net__dns__use-google`](modules/net.md#net__dns__use-google) | Configure Google Public DNS while keeping the current DNS manager. |

## [`node`](modules/node.md)

| 関数 | 説明 |
|---|---|
| [`node__versions`](modules/node.md#node__versions) | Write complete stable Node.js versions from the selected source. |
| [`node__install`](modules/node.md#node__install) | Install Node.js, enable Corepack, and set the pnpm store directory. |

## [`opencode`](modules/opencode.md)

| 関数 | 説明 |
|---|---|
| [`opencode__install`](modules/opencode.md#opencode__install) | Install the newest OpenCode command-line application. |

## [`pass`](modules/pass.md)

| 関数 | 説明 |
|---|---|
| [`pass__store__remove`](modules/pass.md#pass__store__remove) | Remove a pass store and everything in it. |
| [`pass__store__init`](modules/pass.md#pass__store__init) | Initialize a pass store for a GPG key without removing an existing store. |
| [`pass__versions`](modules/pass.md#pass__versions) | Write pass versions available to the current platform. |
| [`pass__install`](modules/pass.md#pass__install) | Install pass from the platform package manager. |

## [`pci`](modules/pci.md)

| 関数 | 説明 |
|---|---|
| [`pci__device__list`](modules/pci.md#pci__device__list) | Write the PCI devices with lspci. |

## [`pipx`](modules/pipx.md)

| 関数 | 説明 |
|---|---|
| [`pipx__versions`](modules/pipx.md#pipx__versions) | Write pipx versions available from the selected source. |
| [`pipx__install`](modules/pipx.md#pipx__install) | Install pipx and add the pipx application directory to PATH. |

## [`plantuml`](modules/plantuml.md)

| 関数 | 説明 |
|---|---|
| [`plantuml__versions`](modules/plantuml.md#plantuml__versions) | Write PlantUML versions available to the current platform. |
| [`plantuml__install`](modules/plantuml.md#plantuml__install) | Install PlantUML from the platform package manager. |

## [`plist`](modules/plist.md)

| 関数 | 説明 |
|---|---|
| [`plist__set`](modules/plist.md#plist__set) | Set a string value for one top-level key in a macOS property list. |

## [`process`](modules/process.md)

| 関数 | 説明 |
|---|---|
| [`process__ids-by-name`](modules/process.md#process__ids-by-name) | Write the IDs of the processes whose executable name is exactly NAME, one per line. |
| [`process__ids-by-name-regex`](modules/process.md#process__ids-by-name-regex) | Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f. |
| [`process__threads-by-pid`](modules/process.md#process__threads-by-pid) | Write the threads of one process. |
| [`process__threads-by-name`](modules/process.md#process__threads-by-name) | Write the threads of the first process whose executable name is NAME. |

## [`qmk`](modules/qmk.md)

| 関数 | 説明 |
|---|---|
| [`qmk__toolbox__install`](modules/qmk.md#qmk__toolbox__install) | Install QMK Toolbox with Homebrew on macOS. |
| [`qmk__cli__install`](modules/qmk.md#qmk__cli__install) | Install the QMK CLI with the official installer and diagnose the environment. |

## [`rancher-desktop`](modules/rancher-desktop.md)

| 関数 | 説明 |
|---|---|
| [`rancher-desktop__versions`](modules/rancher-desktop.md#rancher-desktop__versions) | Write Rancher Desktop versions available to the current platform. |
| [`rancher-desktop__install`](modules/rancher-desktop.md#rancher-desktop__install) | Install Rancher Desktop and start it. |

## [`repo`](modules/repo.md)

| 関数 | 説明 |
|---|---|
| [`repo__init`](modules/repo.md#repo__init) | Initialize a Google Repo workspace with shallow history. |
| [`repo__sync`](modules/repo.md#repo__sync) | Synchronize one path of a Google Repo workspace, forcing the sync. |
| [`repo__write-manifest`](modules/repo.md#repo__write-manifest) | Write the current Google Repo manifest with revisions to a file. |
| [`repo__check`](modules/repo.md#repo__check) | Run git fsck in every project of a Google Repo workspace. |
| [`repo__reset`](modules/repo.md#repo__reset) | Hard reset every project of a Google Repo workspace and remove untracked files. |

## [`rosetta`](modules/rosetta.md)

| 関数 | 説明 |
|---|---|
| [`rosetta__install`](modules/rosetta.md#rosetta__install) | Install Rosetta when it is missing, accepting its license. |

## [`ruby`](modules/ruby.md)

| 関数 | 説明 |
|---|---|
| [`ruby__version__list`](modules/ruby.md#ruby__version__list) | Write stable Ruby versions that rbenv can install in ascending order. |
| [`ruby__version__latest`](modules/ruby.md#ruby__version__latest) | Write the newest stable Ruby version that rbenv can install. |
| [`ruby__install`](modules/ruby.md#ruby__install) | Install rbenv, configure the shell, and install a Ruby version globally. |

## [`rust`](modules/rust.md)

| 関数 | 説明 |
|---|---|
| [`rust__install`](modules/rust.md#rust__install) | Install Rust using rustup and an optional toolchain version. |
| [`rust__versions`](modules/rust.md#rust__versions) | Write the stable Rust versions, oldest first, from the rust-lang/rust releases. |

## [`screen`](modules/screen.md)

| 関数 | 説明 |
|---|---|
| [`screen__open`](modules/screen.md#screen__open) | Open a GNU Screen session. |
| [`screen__open-serial`](modules/screen.md#screen__open-serial) | Open a serial device in GNU Screen through administrator execution and log the session. |
| [`screen__kill-all`](modules/screen.md#screen__kill-all) | End every GNU Screen process of every user through administrator execution. |

## [`selinux`](modules/selinux.md)

| 関数 | 説明 |
|---|---|
| [`selinux__generate-rule`](modules/selinux.md#selinux__generate-rule) | Generate SELinux allow rules from the AVC denials of an audit log. |

## [`serial`](modules/serial.md)

| 関数 | 説明 |
|---|---|
| [`serial__configure`](modules/serial.md#serial__configure) | Open a serial device with a configured baud rate. |
| [`serial__write`](modules/serial.md#serial__write) | Write literal data to a serial device. |
| [`serial__write-command`](modules/serial.md#serial__write-command) | Write a command and terminator to a serial device. |
| [`serial__release`](modules/serial.md#serial__release) | Release a serial device so another process, such as a Python tool, can open it. |

## [`ssh`](modules/ssh.md)

| 関数 | 説明 |
|---|---|
| [`ssh__setup-directory`](modules/ssh.md#ssh__setup-directory) | Create $HOME/.ssh and give it and its files the modes SSH expects. |
| [`ssh__config__update`](modules/ssh.md#ssh__config__update) | Update one key in a marker-managed SSH Host block. |
| [`ssh__config__set`](modules/ssh.md#ssh__config__set) | Create an SSH configuration file when necessary and update one key. |
| [`ssh__config__enable-auto-add-keys`](modules/ssh.md#ssh__config__enable-auto-add-keys) | Enable AddKeysToAgent for an optional SSH Host pattern. |
| [`ssh__config__disable-host-key-checking`](modules/ssh.md#ssh__config__disable-host-key-checking) | Disable SSH host-key checks for an optional Host pattern. |
| [`ssh__key__private-files`](modules/ssh.md#ssh__key__private-files) | List regular files that ssh-keygen can read as private keys. |
| [`ssh__key__add`](modules/ssh.md#ssh__key__add) | Add one private key to ssh-agent. |
| [`ssh__key__add-all`](modules/ssh.md#ssh__key__add-all) | Add every detected private key in a directory to ssh-agent. |
| [`ssh__key__add-all-private-keys`](modules/ssh.md#ssh__key__add-all-private-keys) | Add every detected private key in a directory to ssh-agent. |
| [`ssh__key__generate-rsa4096`](modules/ssh.md#ssh__key__generate-rsa4096) | Generate a 4096-bit RSA SSH key and write its public key. |
| [`ssh__key__generate-ed25519`](modules/ssh.md#ssh__key__generate-ed25519) | Generate an Ed25519 SSH key and write its public key. |
| [`ssh__kill-all`](modules/ssh.md#ssh__kill-all) | End every SSH process of the current user. |
| [`ssh__server__versions`](modules/ssh.md#ssh__server__versions) | Write OpenSSH server versions available to the current platform. |
| [`ssh__server__install`](modules/ssh.md#ssh__server__install) | Install the OpenSSH server, enable it at boot, and start it. |

## [`storage`](modules/storage.md)

| 関数 | 説明 |
|---|---|
| [`storage__usage`](modules/storage.md#storage__usage) | Show human-readable filesystem usage for a path. |
| [`storage__largest-entries`](modules/storage.md#storage__largest-entries) | Write the largest entries of a directory, including the directory itself, in human-readable sizes. |
| [`storage__clear-trash`](modules/storage.md#storage__clear-trash) | Empty the Linux desktop trash of the current user through administrator execution. |

## [`strace`](modules/strace.md)

| 関数 | 説明 |
|---|---|
| [`strace__attach-pid`](modules/strace.md#strace__attach-pid) | Attach strace to a process on Linux. |
| [`strace__attach-name`](modules/strace.md#strace__attach-name) | Attach strace to the first process whose executable name is NAME. |

## [`sudo`](modules/sudo.md)

| 関数 | 説明 |
|---|---|
| [`sudo__start-keep-alive`](modules/sudo.md#sudo__start-keep-alive) | Keep the sudo credentials of the calling process fresh in the background. |
| [`sudo__passwordless__enable`](modules/sudo.md#sudo__passwordless__enable) | Let a user run every command through sudo without entering a password. |
| [`sudo__passwordless__disable`](modules/sudo.md#sudo__passwordless__disable) | Remove the passwordless sudo rule that sudo__passwordless__enable added. |

## [`supabase`](modules/supabase.md)

| 関数 | 説明 |
|---|---|
| [`supabase__versions`](modules/supabase.md#supabase__versions) | Write Supabase CLI versions available to the current platform. |
| [`supabase__install`](modules/supabase.md#supabase__install) | Install the Supabase CLI from its Homebrew tap or release packages. |

## [`symlink`](modules/symlink.md)

| 関数 | 説明 |
|---|---|
| [`symlink__create`](modules/symlink.md#symlink__create) | Create or replace a symbolic link that points to the absolute path of an existing SOURCE. |
| [`symlink__remove`](modules/symlink.md#symlink__remove) | Remove a symbolic link, using administrator execution only when its directory is not writable. |
| [`symlink__create-in-local-bin`](modules/symlink.md#symlink__create-in-local-bin) | Create a symbolic link in a user's local bin directory. |

## [`systemd`](modules/systemd.md)

| 関数 | 説明 |
|---|---|
| [`systemd__file`](modules/systemd.md#systemd__file) | Write the path of the file that defines a systemd unit. |
| [`systemd__dependencies`](modules/systemd.md#systemd__dependencies) | Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines. |
| [`systemd__restart`](modules/systemd.md#systemd__restart) | Restart a systemd unit through administrator execution. |
| [`systemd__start`](modules/systemd.md#systemd__start) | Start a systemd unit through administrator execution. |
| [`systemd__stop`](modules/systemd.md#systemd__stop) | Stop a systemd unit through administrator execution. |
| [`systemd__enable`](modules/systemd.md#systemd__enable) | Enable a systemd unit at boot through administrator execution. |
| [`systemd__disable`](modules/systemd.md#systemd__disable) | Disable a systemd unit at boot through administrator execution. |
| [`systemd__status`](modules/systemd.md#systemd__status) | Write the current state of a systemd unit and return the status of systemctl status. |
| [`systemd__service__list`](modules/systemd.md#systemd__service__list) | Write every loaded systemd service, including stopped ones. |
| [`systemd__service__list-running`](modules/systemd.md#systemd__service__list-running) | Write the running systemd services. |
| [`systemd__service__list-failed`](modules/systemd.md#systemd__service__list-failed) | Write the failed systemd services. |
| [`systemd__service__list-files`](modules/systemd.md#systemd__service__list-files) | Write every systemd service unit file and its enablement state. |

## [`textproto`](modules/textproto.md)

| 関数 | 説明 |
|---|---|
| [`textproto__set-scalar`](modules/textproto.md#textproto__set-scalar) | Replace or append one top-level scalar field in a textproto file. |

## [`thunderbird`](modules/thunderbird.md)

| 関数 | 説明 |
|---|---|
| [`thunderbird__versions`](modules/thunderbird.md#thunderbird__versions) | Write Thunderbird versions available to the current platform. |
| [`thunderbird__install`](modules/thunderbird.md#thunderbird__install) | Install the Thunderbird email client. |

## [`ubuntu`](modules/ubuntu.md)

| 関数 | 説明 |
|---|---|
| [`ubuntu__server-iso-versions`](modules/ubuntu.md#ubuntu__server-iso-versions) | Write the Ubuntu Server LTS versions whose live server ISO is published for an architecture. |
| [`ubuntu__download-server-iso`](modules/ubuntu.md#ubuntu__download-server-iso) | Download an Ubuntu Server live ISO and check it against the official SHA256SUMS. |
| [`ubuntu__setup`](modules/ubuntu.md#ubuntu__setup) | Apply the common Ubuntu user configuration, stopping at the first failure. |
| [`ubuntu__setup-external`](modules/ubuntu.md#ubuntu__setup-external) | Install GnuPG, GitHub CLI, and Git Credential Manager when they are not already available. |
| [`ubuntu__setup-desktop`](modules/ubuntu.md#ubuntu__setup-desktop) | Apply the Ubuntu user configuration and desktop settings, stopping at the first failure. |

## [`usb`](modules/usb.md)

| 関数 | 説明 |
|---|---|
| [`usb__device__list`](modules/usb.md#usb__device__list) | Write the USB devices with lsusb. |
| [`usb__partition__select`](modules/usb.md#usb__partition__select) | Select a USB partition, or a USB disk without partitions, and write its device path. |
| [`usb__filesystem__repair`](modules/usb.md#usb__filesystem__repair) | Select a USB file system, unmount it, and repair it through administrator execution. |
| [`usb__filesystem__format-fat32`](modules/usb.md#usb__filesystem__format-fat32) | Select a USB partition, unmount it, and format it as FAT32 through administrator execution. |

## [`user`](modules/user.md)

| 関数 | 説明 |
|---|---|
| [`user__name`](modules/user.md#user__name) | Write the effective user's name. |
| [`user__primary-group`](modules/user.md#user__primary-group) | Write the effective user's primary group name. |
| [`user__is-root`](modules/user.md#user__is-root) | Test whether the effective user is root. |
| [`user__exists`](modules/user.md#user__exists) | Test whether a local user account exists. |
| [`user__create-system-as-root`](modules/user.md#user__create-system-as-root) | Create a non-login system account in a separate root process. |
| [`user__create-login-as-root`](modules/user.md#user__create-login-as-root) | Create a local login account in a separate root process. |
| [`user__create-system`](modules/user.md#user__create-system) | Create a non-login system account. |
| [`user__create-login`](modules/user.md#user__create-login) | Create a local login account. |
| [`user__add-to-group`](modules/user.md#user__add-to-group) | Add a user to a supplementary group through administrator execution. |
| [`user__directory__create-english-links`](modules/user.md#user__directory__create-english-links) | Link the English XDG user directory names to the directories of the current locale. |

## [`utm`](modules/utm.md)

| 関数 | 説明 |
|---|---|
| [`utm__open`](modules/utm.md#utm__open) | Open the UTM application on macOS. |
| [`utm__versions`](modules/utm.md#utm__versions) | Write UTM release versions. |
| [`utm__install`](modules/utm.md#utm__install) | Install UTM from its release disk image on macOS. |

## [`vlc`](modules/vlc.md)

| 関数 | 説明 |
|---|---|
| [`vlc__set-default-app`](modules/vlc.md#vlc__set-default-app) | Set VLC as the default application for every MIME type it declares. |

## [`vscode`](modules/vscode.md)

| 関数 | 説明 |
|---|---|
| [`vscode__remove-user-data`](modules/vscode.md#vscode__remove-user-data) | Remove the VS Code user data directory. |
| [`vscode__set-default-app`](modules/vscode.md#vscode__set-default-app) | Set VS Code as the default application for text and source file types on macOS. |
| [`vscode__versions`](modules/vscode.md#vscode__versions) | Write VS Code versions available to the current platform. |
| [`vscode__install`](modules/vscode.md#vscode__install) | Install VS Code from the Microsoft repository or Homebrew. |

## [`xcode`](modules/xcode.md)

| 関数 | 説明 |
|---|---|
| [`xcode__command-line-tools__upgrade`](modules/xcode.md#xcode__command-line-tools__upgrade) | Update Xcode Command Line Tools without removing the installed tools. |
