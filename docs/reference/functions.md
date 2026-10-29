# 関数リファレンス

BashStockが公開する関数をモジュールごとに示します。
各関数の引数、出力、終了状態、例は、モジュールのページと`help::show 関数名`で確認できます。
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

## [`arguments`](modules/arguments.md)

| 関数 | 説明 |
|---|---|
| [`arg::require-next`](modules/arguments.md#argrequire-next) | Require a value to follow the current named argument. |
| [`arg::require`](modules/arguments.md#argrequire) | Require a named argument to have a non-empty value. |
| [`arg::integer`](modules/arguments.md#arginteger) | Require a named argument value to be a decimal integer. |
| [`arg::one-of`](modules/arguments.md#argone-of) | Require a named argument value to match one candidate. |
| [`arg::unknown`](modules/arguments.md#argunknown) | Report a named argument that no case branch recognized. |

## [`completion`](modules/completion.md)

| 関数 | 説明 |
|---|---|
| [`arg::completion::dispatch`](modules/completion.md#argcompletiondispatch) | Dispatch Tab completion to the target function's completion helper. |
| [`arg::completion::register-all`](modules/completion.md#argcompletionregister-all) | Register Tab completion for every function that has a completion helper. |

## [`help`](modules/help.md)

| 関数 | 説明 |
|---|---|
| [`help::show`](modules/help.md#helpshow) | Show the documentation of a BashStock function, like Get-Help in PowerShell. |

## [`system`](modules/system.md)

| 関数 | 説明 |
|---|---|
| [`system::operating-system`](modules/system.md#systemoperating-system) | Write the normalized operating-system family. |
| [`system::host-name`](modules/system.md#systemhost-name) | Write the current host name. |

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

## [`terminal`](modules/terminal.md)

| 関数 | 説明 |
|---|---|
| [`terminal::is-available`](modules/terminal.md#terminalis-available) | Test whether the controlling terminal is readable and writable. |

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

## [`prompt`](modules/prompt.md)

| 関数 | 説明 |
|---|---|
| [`prompt::confirm`](modules/prompt.md#promptconfirm) | Read and normalize a yes-or-no answer. |
| [`prompt::read-line-with-default`](modules/prompt.md#promptread-line-with-default) | Read one line and substitute a default only for empty input. |
| [`prompt::confirm-or-cancel`](modules/prompt.md#promptconfirm-or-cancel) | Read and normalize a yes, no, or cancel answer. |
| [`prompt::select-one`](modules/prompt.md#promptselect-one) | Display indexed choices and write the selected value. |

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

## [`git`](modules/git.md)

| 関数 | 説明 |
|---|---|
| [`git::commit::edit-via-rebase`](modules/git.md#gitcommitedit-via-rebase) | Start an interactive rebase that stops at one non-merge commit for editing. |

## [`net`](modules/net.md)

| 関数 | 説明 |
|---|---|
| [`net::ip::set-static`](modules/net.md#netipset-static) | Replace one Ubuntu Netplan file with a static IPv4 configuration. |

## [`util`](modules/util.md)

| 関数 | 説明 |
|---|---|
| [`prompt::pause`](modules/util.md#promptpause) | Wait for one line from the controlling terminal. |
| [`time::sleep-hours`](modules/util.md#timesleep-hours) | Sleep for a non-negative integer number of hours. |
| [`storage::usage`](modules/util.md#storageusage) | Show human-readable filesystem usage for a path. |
| [`storage::largest-entries`](modules/util.md#storagelargest-entries) | Write the largest entries of a directory, including the directory itself, in human-readable sizes. |
| [`mem::physical-total-bytes`](modules/util.md#memphysical-total-bytes) | Write the total physical memory in bytes. |
| [`mem::physical-total-gibibytes`](modules/util.md#memphysical-total-gibibytes) | Write the total physical memory in gibibytes. |
| [`mem::swap-total-bytes`](modules/util.md#memswap-total-bytes) | Write the total swap capacity in bytes. |
| [`mem::swap-total-gibibytes`](modules/util.md#memswap-total-gibibytes) | Write the total swap capacity in gibibytes. |
| [`mem::total-bytes`](modules/util.md#memtotal-bytes) | Write the total memory and swap capacity in bytes. |
| [`mem::total-gibibytes`](modules/util.md#memtotal-gibibytes) | Write the total memory and swap capacity in gibibytes. |
| [`file::write-text`](modules/util.md#filewrite-text) | Write text to a regular file using an atomic replacement. |
| [`file::find-by-content`](modules/util.md#filefind-by-content) | Write the regular files below a directory whose content matches an ERE, separated by NUL. |
| [`file::latest-by-name`](modules/util.md#filelatest-by-name) | Write the most recently modified regular file whose base name matches a Bash ERE. |
| [`symlink::create`](modules/util.md#symlinkcreate) | Create or replace a symbolic link that points to the absolute path of an existing SOURCE. |
| [`symlink::remove`](modules/util.md#symlinkremove) | Remove a symbolic link, using administrator execution only when its directory is not writable. |
| [`net::interface::default`](modules/util.md#netinterfacedefault) | Write the first default-route interface. |
| [`net::gateway::default`](modules/util.md#netgatewaydefault) | Write the first default-route gateway. |
| [`net::ip::private-v4`](modules/util.md#netipprivate-v4) | Write the primary RFC 1918 IPv4 address of an interface. |
| [`net::ip::private-v6`](modules/util.md#netipprivate-v6) | Write the primary unique local IPv6 address of an interface. |
| [`net::ip::public`](modules/util.md#netippublic) | Write the public IP address reported by ifconfig.me. |
| [`net::dns::test`](modules/util.md#netdnstest) | Test whether a DNS name resolves. |
| [`user::add-to-group`](modules/util.md#useradd-to-group) | Add a user to a supplementary group through administrator execution. |
| [`system::kernel-name`](modules/util.md#systemkernel-name) | Write the kernel name. |
| [`system::distribution-name`](modules/util.md#systemdistribution-name) | Write the distribution name. |
| [`system::enable-sleep`](modules/util.md#systemenable-sleep) | Enable system sleep. |
| [`system::disable-sleep`](modules/util.md#systemdisable-sleep) | Disable system sleep. |
| [`system::disable-auto-lock`](modules/util.md#systemdisable-auto-lock) | Disable automatic screen locking for the current user. |
| [`time::posix-timezone`](modules/util.md#timeposix-timezone) | Write the POSIX TZ string for a UTC offset. |
| [`directory::merge`](modules/util.md#directorymerge) | Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE. |
| [`directory::create-with-date-time`](modules/util.md#directorycreate-with-date-time) | Create a directory named with the local date and time and write its path. |
| [`directory::clear`](modules/util.md#directoryclear) | Remove every entry of a directory, including hidden ones, and keep the directory. |
| [`time::status-continuous`](modules/util.md#timestatus-continuous) | Write the elapsed time since boot and the local time every three seconds until stopped. |
| [`file::edit`](modules/util.md#fileedit) | Open an editor for a file, using sudoedit only when required. |
| [`file::release`](modules/util.md#filerelease) | Release a file held by other processes. |
| [`screen::open`](modules/util.md#screenopen) | Open a GNU Screen session. |
| [`archive::verify`](modules/util.md#archiveverify) | Verify all recognized archives below a path. |
| [`archive::remove-broken`](modules/util.md#archiveremove-broken) | Remove archives that fail verification. |
| [`archive::extract-file`](modules/util.md#archiveextract-file) | Extract one archive or decompress one compressed file. |
| [`archive::compress-tar-gzip`](modules/util.md#archivecompress-tar-gzip) | Compress paths into a gzip-compressed tar archive. |
| [`diff::directories`](modules/util.md#diffdirectories) | Run diff for two directories. |
| [`git::clone-shallow`](modules/util.md#gitclone-shallow) | Clone a repository with depth one. |
| [`git::rebase-abort`](modules/util.md#gitrebase-abort) | Abort an in-progress rebase. |
| [`git::rebase-continue`](modules/util.md#gitrebase-continue) | Continue an in-progress rebase. |
| [`git::commit::amend`](modules/util.md#gitcommitamend) | Amend the last commit without changing its message. |
| [`git::commit::create`](modules/util.md#gitcommitcreate) | Create a commit with a message. |
| [`git::commit::uncommit`](modules/util.md#gitcommituncommit) | Remove the last commit while keeping its changes staged. |
| [`git::branch::current`](modules/util.md#gitbranchcurrent) | Write the current branch name. |
| [`git::branch::create`](modules/util.md#gitbranchcreate) | Create a branch at a starting revision. |
| [`git::branch::list`](modules/util.md#gitbranchlist) | List local and remote-tracking branches. |
| [`git::diff::files`](modules/util.md#gitdifffiles) | Show file names changed between two revisions. |
| [`git::diff::patch`](modules/util.md#gitdiffpatch) | Show a patch between two revisions. |
| [`git::diff::uncommitted-patch`](modules/util.md#gitdiffuncommitted-patch) | Show the patch for uncommitted tracked changes. |
| [`git::diff::uncommitted-files`](modules/util.md#gitdiffuncommitted-files) | Show file names changed by uncommitted tracked changes. |
| [`git::diff::latest-patch`](modules/util.md#gitdifflatest-patch) | Show the patch introduced by the latest commit. |
| [`git::diff::latest-files`](modules/util.md#gitdifflatest-files) | Show file names changed by the latest commit. |
| [`git::commit::patch`](modules/util.md#gitcommitpatch) | Write the unified diff that one commit introduced. |
| [`git::commit::revert-without-commit`](modules/util.md#gitcommitrevert-without-commit) | Revert a commit without creating a commit. |
| [`git::commit::revert`](modules/util.md#gitcommitrevert) | Revert a commit and create the revert commit. |
| [`git::fetch`](modules/util.md#gitfetch) | Fetch one remote or all remotes. |
| [`git::fetch-unshallow`](modules/util.md#gitfetch-unshallow) | Convert a shallow clone into a complete history. |
| [`git::stash::patch`](modules/util.md#gitstashpatch) | Show a stash patch. |
| [`git::stash::push`](modules/util.md#gitstashpush) | Save tracked changes and untracked files in a new stash. |
| [`git::stash::pop`](modules/util.md#gitstashpop) | Apply and remove a stash. |
| [`git::stash::drop`](modules/util.md#gitstashdrop) | Delete a stash. |
| [`git::reset`](modules/util.md#gitreset) | Reset a working tree to a revision. |
| [`git::pull-rebase`](modules/util.md#gitpull-rebase) | Update a branch from a remote with rebase. |
| [`git::cherry-pick`](modules/util.md#gitcherry-pick) | Apply one commit, fetching it from a remote only when the repository lacks it. |
| [`git::cherry-pick-continue`](modules/util.md#gitcherry-pick-continue) | Continue an in-progress cherry-pick. |
| [`git::cherry-pick-abort`](modules/util.md#gitcherry-pick-abort) | Abort an in-progress cherry-pick. |
| [`git::push`](modules/util.md#gitpush) | Push a branch to a remote. |
| [`git::push::force-with-lease`](modules/util.md#gitpushforce-with-lease) | Push a branch without overwriting a remote update. |
| [`gerrit::push-review`](modules/util.md#gerritpush-review) | Push the current HEAD to a Gerrit review reference. |
| [`gerrit::push-review-wip`](modules/util.md#gerritpush-review-wip) | Push the current HEAD to a Gerrit review reference as work in progress. |
| [`git::remote::delete-branch`](modules/util.md#gitremotedelete-branch) | Delete a branch on a remote. |
| [`git::submodule::update-all`](modules/util.md#gitsubmoduleupdate-all) | Update all submodules recursively. |
| [`git::commit::discard`](modules/util.md#gitcommitdiscard) | Discard all changes in a working tree. |
| [`git::reset-remote`](modules/util.md#gitreset-remote) | Hard reset the current branch to the branch with the same name on a remote. |
| [`git::pull-base-branch`](modules/util.md#gitpull-base-branch) | Pull the configured base branch with fast-forward-only semantics. |
| [`env::dotenv::import`](modules/util.md#envdotenvimport) | Import the variables of a dotenv file into the current process. |
| [`env::set-variable`](modules/util.md#envset-variable) | Set an environment variable for the current shell. |
| [`env::add-path`](modules/util.md#envadd-path) | Add a directory to PATH without creating duplicates. |
| [`env::dotenv::register`](modules/util.md#envdotenvregister) | Load a dotenv file in every new Bash and Zsh session. |
| [`symlink::create-in-local-bin`](modules/util.md#symlinkcreate-in-local-bin) | Create a symbolic link in a user's local bin directory. |
| [`ssh::setup-directory`](modules/util.md#sshsetup-directory) | Create $HOME/.ssh and give it and its files the modes SSH expects. |
| [`ssh::config::update`](modules/util.md#sshconfigupdate) | Update one key in a marker-managed SSH Host block. |
| [`ssh::config::set`](modules/util.md#sshconfigset) | Create an SSH configuration file when necessary and update one key. |
| [`ssh::config::enable-auto-add-keys`](modules/util.md#sshconfigenable-auto-add-keys) | Enable AddKeysToAgent for an optional SSH Host pattern. |
| [`ssh::config::disable-host-key-checking`](modules/util.md#sshconfigdisable-host-key-checking) | Disable SSH host-key checks for an optional Host pattern. |
| [`ssh::key::private-files`](modules/util.md#sshkeyprivate-files) | List regular files that ssh-keygen can read as private keys. |
| [`ssh::key::add`](modules/util.md#sshkeyadd) | Add one private key to ssh-agent. |
| [`ssh::key::add-all`](modules/util.md#sshkeyadd-all) | Add every detected private key in a directory to ssh-agent. |
| [`ssh::key::add-all-private-keys`](modules/util.md#sshkeyadd-all-private-keys) | Add every detected private key in a directory to ssh-agent. |
| [`net::ping`](modules/util.md#netping) | Send ICMP echo requests to a host. |
| [`swap::disable-all`](modules/util.md#swapdisable-all) | Disable every active swap area through administrator execution. |
| [`swap::remove-all-files`](modules/util.md#swapremove-all-files) | Disable every swap file, remove its /etc/fstab entry, and delete it. |
| [`swap::create`](modules/util.md#swapcreate) | Create a swap file, enable it, and register it in /etc/fstab. |
| [`swap::list`](modules/util.md#swaplist) | List active swap devices. |
| [`path::find`](modules/util.md#pathfind) | Write the paths below a directory that match a case-insensitive Bash ERE, separated by NUL. |
| [`file::tree-with-contents`](modules/util.md#filetree-with-contents) | Write the directories and text files below a path, with the contents of each text file. |
| [`net::tcp::test`](modules/util.md#nettcptest) | Test whether a TCP connection to HOST and PORT succeeds, without output. |
| [`serial::configure`](modules/util.md#serialconfigure) | Open a serial device with a configured baud rate. |
| [`serial::write`](modules/util.md#serialwrite) | Write literal data to a serial device. |
| [`serial::write-command`](modules/util.md#serialwrite-command) | Write a command and terminator to a serial device. |
| [`screen::open-serial`](modules/util.md#screenopen-serial) | Open a serial device in GNU Screen through administrator execution and log the session. |
| [`screen::kill-all`](modules/util.md#screenkill-all) | End every GNU Screen process of every user through administrator execution. |
| [`net::capture-host`](modules/util.md#netcapture-host) | Capture packets addressed to a host. |
| [`net::unused-port`](modules/util.md#netunused-port) | Write a TCP port number the operating system reports as unused. |
| [`serial::release`](modules/util.md#serialrelease) | Release a serial device so another process, such as a Python tool, can open it. |
| [`repo::init`](modules/util.md#repoinit) | Initialize a Google Repo workspace with shallow history. |
| [`repo::sync`](modules/util.md#reposync) | Synchronize one path of a Google Repo workspace, forcing the sync. |
| [`repo::write-manifest`](modules/util.md#repowrite-manifest) | Write the current Google Repo manifest with revisions to a file. |
| [`repo::check`](modules/util.md#repocheck) | Run git fsck in every project of a Google Repo workspace. |
| [`docker::container::list-running`](modules/util.md#dockercontainerlist-running) | List running Docker containers. |
| [`docker::container::list`](modules/util.md#dockercontainerlist) | List Docker containers. |
| [`docker::container::pull`](modules/util.md#dockercontainerpull) | Copy files between a Docker container and the host. |
| [`docker::container::push`](modules/util.md#dockercontainerpush) | Copy a host path into a container. |
| [`docker::container::shell`](modules/util.md#dockercontainershell) | Run an interactive shell or a command in a container. |
| [`docker::container::logs`](modules/util.md#dockercontainerlogs) | Follow the log of a container. |
| [`docker::container::stop`](modules/util.md#dockercontainerstop) | Stop a container. |
| [`docker::container::start`](modules/util.md#dockercontainerstart) | Start a container. |
| [`docker::container::stop-all`](modules/util.md#dockercontainerstop-all) | Stop every running container; having none is a success. |
| [`docker::container::remove-all`](modules/util.md#dockercontainerremove-all) | Remove every container, running or not. |
| [`docker::volume::remove-all`](modules/util.md#dockervolumeremove-all) | Remove every Docker volume. |
| [`docker::remove-all`](modules/util.md#dockerremove-all) | Remove every container and then every volume, stopping at the first failure. |
| [`adb::device::wait`](modules/util.md#adbdevicewait) | Wait for an ADB device to connect, optionally selected with --serial. |
| [`adb::device::pull`](modules/util.md#adbdevicepull) | Copy files from an ADB device to the host. |
| [`adb::device::push`](modules/util.md#adbdevicepush) | Copy files from the host to an ADB device. |
| [`adb::logcat::clear`](modules/util.md#adblogcatclear) | Clear the selected device log buffers. |
| [`adb::logcat::once`](modules/util.md#adblogcatonce) | Write the selected device log buffers once. |
| [`adb::logcat::continuous`](modules/util.md#adblogcatcontinuous) | Stream logs from the selected device. |
| [`adb::device::reboot`](modules/util.md#adbdevicereboot) | Reboot the selected device. |
| [`adb::device::first`](modules/util.md#adbdevicefirst) | Write the first connected ADB device serial. |
| [`adb::device::list`](modules/util.md#adbdevicelist) | List connected ADB device serials. |
| [`adb::device::wait-for-path`](modules/util.md#adbdevicewait-for-path) | Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout. |
| [`adb::device::screen::capture-once`](modules/util.md#adbdevicescreencapture-once) | Save one screenshot atomically and print its path. |
| [`adb::device::select-and-pull`](modules/util.md#adbdeviceselect-and-pull) | Select one requested device path and pull it to the host. |
| [`adb::device::bootloader::enter`](modules/util.md#adbdevicebootloaderenter) | Reboot the selected device into its bootloader. |
| [`adb::device::bootloader::unlock`](modules/util.md#adbdevicebootloaderunlock) | Request bootloader unlocking and wait for the device to reconnect. |
| [`adb::device::verity::disable`](modules/util.md#adbdeviceveritydisable) | Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects. |
| [`adb::device::partition::remount`](modules/util.md#adbdevicepartitionremount) | Make the system partitions of a rooted device writable. |
| [`adb::device::build::fingerprint`](modules/util.md#adbdevicebuildfingerprint) | Write the selected device build fingerprint. |
| [`adb::device::build::date`](modules/util.md#adbdevicebuilddate) | Write the selected device build timestamp as Unix seconds. |
| [`adb::device::slot::suffix`](modules/util.md#adbdeviceslotsuffix) | Write the selected device active slot suffix. |
| [`adb::device::build::kernel-version`](modules/util.md#adbdevicebuildkernel-version) | Write the selected device kernel release. |
| [`adb::device::screen::capture-continuous`](modules/util.md#adbdevicescreencapture-continuous) | Save repeated screenshots; MAX_COUNT of zero runs until interrupted. |
| [`adb::device::partition::sha256`](modules/util.md#adbdevicepartitionsha256) | Write a device partition SHA-256 checksum. |
| [`adb::wake::lock`](modules/util.md#adbwakelock) | Hold a kernel wake lock using a tag, defaulting to debug. |
| [`adb::wake::unlock`](modules/util.md#adbwakeunlock) | Release a kernel wake lock using the same tag. |
| [`adb::wake::list`](modules/util.md#adbwakelist) | Print active kernel wake locks. |
| [`process::ids-by-name`](modules/util.md#processids-by-name) | Write the IDs of the processes whose executable name is exactly NAME, one per line. |
| [`process::ids-by-name-regex`](modules/util.md#processids-by-name-regex) | Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f. |
| [`process::threads-by-pid`](modules/util.md#processthreads-by-pid) | Write the threads of one process. |
| [`process::threads-by-name`](modules/util.md#processthreads-by-name) | Write the threads of the first process whose executable name is NAME. |
| [`syscall::trace-by-pid`](modules/util.md#syscalltrace-by-pid) | Attach strace to a process on Linux. |
| [`lib::trace-by-pid`](modules/util.md#libtrace-by-pid) | Attach ltrace to a process on Linux. |
| [`gdb::attach-pid`](modules/util.md#gdbattach-pid) | Attach GDB in batch mode to a process and write the backtrace of every thread. |
| [`gdb::server::start`](modules/util.md#gdbserverstart) | Start COMMAND with its arguments under gdbserver listening on PORT. |
| [`gdb::connect`](modules/util.md#gdbconnect) | Load ELF in GDB and connect to the GDB server at HOST and PORT. |
| [`gdb::run-until`](modules/util.md#gdbrun-until) | Run ELF in GDB with optional program arguments and stop at SYMBOL. |
| [`gdb::core::open`](modules/util.md#gdbcoreopen) | Open ELF and a core dump in GDB. |
| [`device-tree::node::list`](modules/util.md#device-treenodelist) | Write the node paths of the Linux device tree. |
| [`i2c::bus::list`](modules/util.md#i2cbuslist) | Write the I2C buses with i2cdetect -l. |
| [`i2c::device::list`](modules/util.md#i2cdevicelist) | Write the devices on one I2C bus with i2cdetect -y. |
| [`gpio::chip::list`](modules/util.md#gpiochiplist) | Write the GPIO chips with gpiodetect. |
| [`gpio::line::list`](modules/util.md#gpiolinelist) | Write the GPIO lines of one chip, or of every chip, with gpioinfo. |
| [`usb::device::list`](modules/util.md#usbdevicelist) | Write the USB devices with lsusb. |
| [`pci::device::list`](modules/util.md#pcidevicelist) | Write the PCI devices with lspci. |
| [`asciidoc::html`](modules/util.md#asciidochtml) | Convert AsciiDoc to HTML with diagram support. |
| [`flutter::run-chrome-release`](modules/util.md#flutterrun-chrome-release) | Run a Flutter project in Chrome in release mode. |
| [`flutter::run-linux-release`](modules/util.md#flutterrun-linux-release) | Run a Flutter project as a Linux desktop application in release mode. |
| [`flutter::test`](modules/util.md#fluttertest) | Run the Flutter tests of a project with optional flutter test arguments. |
| [`flutter::coverage`](modules/util.md#fluttercoverage) | Run the Flutter tests with coverage and write the LCOV HTML report. |
| [`systemd::file`](modules/util.md#systemdfile) | Write the path of the file that defines a systemd unit. |
| [`systemd::dependencies`](modules/util.md#systemddependencies) | Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines. |
| [`systemd::restart`](modules/util.md#systemdrestart) | Restart a systemd unit through administrator execution. |
| [`systemd::start`](modules/util.md#systemdstart) | Start a systemd unit through administrator execution. |
| [`systemd::stop`](modules/util.md#systemdstop) | Stop a systemd unit through administrator execution. |
| [`systemd::enable`](modules/util.md#systemdenable) | Enable a systemd unit at boot through administrator execution. |
| [`systemd::disable`](modules/util.md#systemddisable) | Disable a systemd unit at boot through administrator execution. |
| [`systemd::status`](modules/util.md#systemdstatus) | Write the current state of a systemd unit and return the status of systemctl status. |
| [`systemd::service::list`](modules/util.md#systemdservicelist) | Write every loaded systemd service, including stopped ones. |
| [`systemd::service::list-running`](modules/util.md#systemdservicelist-running) | Write the running systemd services. |
| [`systemd::service::list-failed`](modules/util.md#systemdservicelist-failed) | Write the failed systemd services. |
| [`systemd::service::list-files`](modules/util.md#systemdservicelist-files) | Write every systemd service unit file and its enablement state. |
| [`gpg::decrypt`](modules/util.md#gpgdecrypt) | Decrypt a GPG file to standard output without adding a newline. |
| [`gpg::public-key::armor`](modules/util.md#gpgpublic-keyarmor) | Write a public GPG key in ASCII armor. |
| [`gpg::secret-key::fingerprints`](modules/util.md#gpgsecret-keyfingerprints) | Write the fingerprints of every primary secret GPG key, one per line. |
| [`gpg::secret-key::list`](modules/util.md#gpgsecret-keylist) | Write the secret GPG keys in the human-readable GPG format. |
| [`user::directory::create-english-links`](modules/util.md#userdirectorycreate-english-links) | Link the English XDG user directory names to the directories of the current locale. |
| [`android::build-tools::versions`](modules/util.md#androidbuild-toolsversions) | Write available stable Android Build Tools versions in ascending order. |
| [`android::build-tools::latest-version`](modules/util.md#androidbuild-toolslatest-version) | Write the newest available stable Android Build Tools version. |
| [`go::version::list`](modules/util.md#goversionlist) | Write the stable Go versions the platform package source offers, oldest first. |
| [`go::version::latest`](modules/util.md#goversionlatest) | Write the newest stable Go version from go::version::list. |
| [`ruby::version::list`](modules/util.md#rubyversionlist) | Write stable Ruby versions that rbenv can install in ascending order. |
| [`ruby::version::latest`](modules/util.md#rubyversionlatest) | Write the newest stable Ruby version that rbenv can install. |
| [`rosetta::install`](modules/util.md#rosettainstall) | Install Rosetta on Apple silicon when it is missing, accepting its license. |
| [`net::dns::servers`](modules/util.md#netdnsservers) | Write the configured IPv4 and IPv6 DNS servers, one per line. |
| [`utm::open`](modules/util.md#utmopen) | Open the UTM application on macOS. |
| [`mozc::config::open`](modules/util.md#mozcconfigopen) | Open the Mozc settings dialog on a Linux desktop. |
| [`archive::extract`](modules/util.md#archiveextract) | Extract one archive, or every recognized archive below a directory, next to itself. |
| [`syscall::trace-by-name`](modules/util.md#syscalltrace-by-name) | Attach strace to the first process whose executable name is NAME. |
| [`lib::trace-by-name`](modules/util.md#libtrace-by-name) | Attach ltrace to the first process whose executable name is NAME. |
| [`gdb::attach-by-name`](modules/util.md#gdbattach-by-name) | Attach GDB to the first process whose executable name is NAME. |
| [`jenkins::restart`](modules/util.md#jenkinsrestart) | Restart the Jenkins service through administrator execution. |
| [`sudo::start-keep-alive`](modules/util.md#sudostart-keep-alive) | Keep the sudo credentials of the calling process fresh in the background. |
| [`sudo::passwordless::enable`](modules/util.md#sudopasswordlessenable) | Let a user run every command through sudo without entering a password. |
| [`sudo::passwordless::disable`](modules/util.md#sudopasswordlessdisable) | Remove the passwordless sudo rule that sudo::passwordless::enable added. |
| [`storage::clear-trash`](modules/util.md#storageclear-trash) | Empty the Linux desktop trash of the current user through administrator execution. |
| [`usb::partition::select`](modules/util.md#usbpartitionselect) | Select a USB partition, or a USB disk without partitions, and write its device path. |
| [`usb::filesystem::repair`](modules/util.md#usbfilesystemrepair) | Select a USB file system, unmount it, and repair it through administrator execution. |
| [`usb::filesystem::format-fat32`](modules/util.md#usbfilesystemformat-fat32) | Select a USB partition, unmount it, and format it as FAT32 through administrator execution. |
| [`git::rebase-base-branch`](modules/util.md#gitrebase-base-branch) | Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one. |
| [`repo::reset`](modules/util.md#reporeset) | Hard reset every project of a Google Repo workspace and remove untracked files. |
| [`selinux::generate-rule`](modules/util.md#selinuxgenerate-rule) | Generate SELinux allow rules from the AVC denials of an audit log. |
| [`terminal::gnome-bash`](modules/util.md#terminalgnome-bash) | Start an interactive Bash in a new GNOME Terminal window. |
| [`shell::editor::set-default`](modules/util.md#shelleditorset-default) | Set the default editor of new Bash and Zsh sessions and the current process. |
| [`plist::set`](modules/util.md#plistset) | Set a string value for one top-level key in a macOS property list. |
| [`textproto::set-scalar`](modules/util.md#textprotoset-scalar) | Replace or append one top-level scalar field in a textproto file. |
| [`shell::completion::enable-ignore-case`](modules/util.md#shellcompletionenable-ignore-case) | Make Bash and Zsh completion ignore letter case. |
| [`git::credentials::remove`](modules/util.md#gitcredentialsremove) | Remove $HOME/.git-credentials and the global credential.helper; both may be absent. |
| [`git::config::enable-origin-all-fetch`](modules/util.md#gitconfigenable-origin-all-fetch) | Make origin fetch every branch in a repository. |
| [`git::config::enable-prune-fetch`](modules/util.md#gitconfigenable-prune-fetch) | Enable pruning on fetch in the global Git configuration. |
| [`git::config::set-default-branch`](modules/util.md#gitconfigset-default-branch) | Set the default branch name of new repositories. |
| [`git::config::enable-rebase-on-pull`](modules/util.md#gitconfigenable-rebase-on-pull) | Enable rebase on pull in the global Git configuration. |
| [`git::config::set-email`](modules/util.md#gitconfigset-email) | Set the global Git email address. |
| [`git::config::set-username`](modules/util.md#gitconfigset-username) | Set the global Git user name. |
| [`git::config::set-http-buffer`](modules/util.md#gitconfigset-http-buffer) | Set the global Git HTTP post buffer. |
| [`git::config::use-gpg-credential-store`](modules/util.md#gitconfiguse-gpg-credential-store) | Make Git Credential Manager store credentials with GPG and pass. |
| [`git::config::use-credential-manager`](modules/util.md#gitconfiguse-credential-manager) | Use Git Credential Manager as the global credential helper. |
| [`pass::store::remove`](modules/util.md#passstoreremove) | Remove a pass store and everything in it. |
| [`pass::store::init`](modules/util.md#passstoreinit) | Initialize a pass store for a GPG key without removing an existing store. |
| [`gpg::setup`](modules/util.md#gpgsetup) | Create a GPG key and use it for pass, Git credentials, and Git commit signing. |
| [`ssh::key::generate-rsa4096`](modules/util.md#sshkeygenerate-rsa4096) | Generate a 4096-bit RSA SSH key and write its public key. |
| [`ssh::key::generate-ed25519`](modules/util.md#sshkeygenerate-ed25519) | Generate an Ed25519 SSH key and write its public key. |
| [`ssh::kill-all`](modules/util.md#sshkill-all) | End every SSH process of the current user. |
| [`git::config::use-osx-keychain`](modules/util.md#gitconfiguse-osx-keychain) | Use the macOS Keychain as the global Git credential helper. |
| [`git-credential-manager::version::list`](modules/util.md#git-credential-managerversionlist) | Write the installed Git Credential Manager version. |
| [`git-credential-manager::install`](modules/util.md#git-credential-managerinstall) | Install an official Git Credential Manager release for this OS and CPU. |
| [`git::config::setup`](modules/util.md#gitconfigsetup) | Apply the user identity and the standard global Git settings. |
| [`go::repository::register`](modules/util.md#gorepositoryregister) | Register the official Go package source for the current platform. |
| [`go::install`](modules/util.md#goinstall) | Install Go from the platform package source. |
| [`rust::install`](modules/util.md#rustinstall) | Install Rust using rustup and an optional toolchain version. |
| [`rust::versions`](modules/util.md#rustversions) | Write the stable Rust versions, oldest first, from the rust-lang/rust releases. |
| [`flutter::use-version`](modules/util.md#flutteruse-version) | Keep Flutter SDK changes in a retrievable stash and switch versions. |
| [`jfrog::config::clear`](modules/util.md#jfrogconfigclear) | Remove one JFrog CLI server configuration. |
| [`jfrog::config::clear-all`](modules/util.md#jfrogconfigclear-all) | Remove every JFrog CLI server configuration. |
| [`jfrog::config::list`](modules/util.md#jfrogconfiglist) | Display JFrog CLI server configurations. |
| [`jfrog::setup`](modules/util.md#jfrogsetup) | Register and verify a JFrog CLI server. |
| [`opencode::install`](modules/util.md#opencodeinstall) | Install the newest OpenCode command-line application. |
| [`docker::login-artifactory`](modules/util.md#dockerlogin-artifactory) | Log in to an Artifactory Docker registry using a token on standard input. |
| [`chrome::profile::export-bookmarks`](modules/util.md#chromeprofileexport-bookmarks) | Export a Chrome profile's Bookmarks file. |
| [`chrome::profile::export-preferences`](modules/util.md#chromeprofileexport-preferences) | Export a Chrome profile's Preferences file. |
| [`chrome::profile::email`](modules/util.md#chromeprofileemail) | Write the first known email address from a Chrome profile. |
| [`chrome::profile::find-by-email`](modules/util.md#chromeprofilefind-by-email) | Find Chrome profiles whose known email matches literally. |
| [`swap::ensure-total-size`](modules/util.md#swapensure-total-size) | Extend swap capacity up to a target size. |
| [`vscode::remove-user-data`](modules/util.md#vscoderemove-user-data) | Remove the VS Code user data directory. |
| [`adb::device::set-default`](modules/util.md#adbdeviceset-default) | Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL. |
| [`adb::server::start`](modules/util.md#adbserverstart) | Start the host ADB server. |
| [`adb::server::stop`](modules/util.md#adbserverstop) | Stop the host ADB server. |
| [`adb::server::restart`](modules/util.md#adbserverrestart) | Stop and then start the host ADB server. |
| [`git::stash::list`](modules/util.md#gitstashlist) | List stashes. |
| [`file::modified-time-unix-seconds`](modules/util.md#filemodified-time-unix-seconds) | Write the last modification time of a file as Unix seconds. |
| [`gpg::key::generate`](modules/util.md#gpgkeygenerate) | Generate a GPG primary key and an encryption subkey in one operation. |
| [`net::dns::manager`](modules/util.md#netdnsmanager) | Write the current DNS manager: systemd-resolved, network-manager, or unknown. |
| [`net::dns::use-systemd-resolved`](modules/util.md#netdnsuse-systemd-resolved) | Make systemd-resolved manage DNS and /etc/resolv.conf. |
| [`net::dns::use-network-manager`](modules/util.md#netdnsuse-network-manager) | Make NetworkManager manage DNS and /etc/resolv.conf directly. |
| [`net::dns::use-google`](modules/util.md#netdnsuse-google) | Configure Google Public DNS while keeping the current DNS manager. |

## [`install`](modules/install.md)

| 関数 | 説明 |
|---|---|
| [`deb::install-from-url`](modules/install.md#debinstall-from-url) | Download a Debian package and install it with its dependencies through APT. |
| [`apt::package::candidates`](modules/install.md#aptpackagecandidates) | Write APT packages whose names start with PREFIX followed by a digit, with candidate versions. |
| [`apt::package::latest`](modules/install.md#aptpackagelatest) | Write the APT package name with the newest version suffix after PREFIX. |
| [`chrome::profile::export-user-data-by-email`](modules/install.md#chromeprofileexport-user-data-by-email) | Export Chrome Preferences and Bookmarks for profiles whose email matches literally. |
| [`aws-vpn-client::log::files`](modules/install.md#aws-vpn-clientlogfiles) | Write AWS VPN Client log files as NUL-separated paths. |
| [`aws-vpn-client::log::clear`](modules/install.md#aws-vpn-clientlogclear) | Remove regular log files below the AWS VPN Client log directory. |
| [`aws-vpn-client::log::open`](modules/install.md#aws-vpn-clientlogopen) | Open log files with an editor command, passing each path as one argument. |
| [`node::versions`](modules/install.md#nodeversions) | Write complete stable Node.js versions from the selected source. |
| [`node::install`](modules/install.md#nodeinstall) | Install Node.js, enable Corepack, and set the pnpm store directory. |
| [`docker::versions`](modules/install.md#dockerversions) | Write Docker Engine or Docker CLI versions available to the current platform. |
| [`docker::install`](modules/install.md#dockerinstall) | Install the Docker CLI, and Docker Engine on Linux. |
| [`colima::versions`](modules/install.md#colimaversions) | Write Colima versions available from Homebrew. |
| [`colima::install`](modules/install.md#colimainstall) | Install Colima with Homebrew on macOS and start it. |
| [`ruby::install`](modules/install.md#rubyinstall) | Install rbenv, configure the shell, and install a Ruby version globally. |
| [`jdk::version::list`](modules/install.md#jdkversionlist) | Write JDK feature release numbers available to the current platform. |
| [`jdk::version::latest`](modules/install.md#jdkversionlatest) | Write the newest JDK feature release number available to the current platform. |
| [`jdk::install`](modules/install.md#jdkinstall) | Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH. |
| [`pipx::versions`](modules/install.md#pipxversions) | Write pipx versions available from the selected source. |
| [`pipx::install`](modules/install.md#pipxinstall) | Install pipx and add the pipx application directory to PATH. |
| [`vscode::set-default-app`](modules/install.md#vscodeset-default-app) | Set VS Code as the default application for text and source file types on macOS. |
| [`iina::set-default-app`](modules/install.md#iinaset-default-app) | Set IINA as the default application for video file extensions on macOS. |
| [`utm::versions`](modules/install.md#utmversions) | Write UTM release versions. |
| [`utm::install`](modules/install.md#utminstall) | Install UTM from its release disk image on macOS. |
| [`ubuntu::server-iso-versions`](modules/install.md#ubuntuserver-iso-versions) | Write the Ubuntu Server LTS versions whose live server ISO is published for an architecture. |
| [`ubuntu::download-server-iso`](modules/install.md#ubuntudownload-server-iso) | Download an Ubuntu Server live ISO and check it against the official SHA256SUMS. |
| [`rancher-desktop::versions`](modules/install.md#rancher-desktopversions) | Write Rancher Desktop versions available to the current platform. |
| [`rancher-desktop::install`](modules/install.md#rancher-desktopinstall) | Install Rancher Desktop and start it. |
| [`key-binding::disable-option-t`](modules/install.md#key-bindingdisable-option-t) | Disable the Option+T key binding on macOS. |
| [`pass::versions`](modules/install.md#passversions) | Write pass versions available to the current platform. |
| [`pass::install`](modules/install.md#passinstall) | Install pass from the platform package manager. |
| [`plantuml::versions`](modules/install.md#plantumlversions) | Write PlantUML versions available to the current platform. |
| [`plantuml::install`](modules/install.md#plantumlinstall) | Install PlantUML from the platform package manager. |
| [`graphviz::versions`](modules/install.md#graphvizversions) | Write Graphviz versions available to the current platform. |
| [`graphviz::install`](modules/install.md#graphvizinstall) | Install Graphviz from the platform package manager. |
| [`flutter::versions`](modules/install.md#flutterversions) | Write stable Flutter SDK versions for the current platform. |
| [`flutter::dependencies::install`](modules/install.md#flutterdependenciesinstall) | Install packages required to build Flutter applications. |
| [`flutter::install`](modules/install.md#flutterinstall) | Install dependencies and select a stable Flutter SDK version. |
| [`vlc::set-default-app`](modules/install.md#vlcset-default-app) | Set VLC as the default application for every MIME type it declares. |
| [`mozc::server::versions`](modules/install.md#mozcserverversions) | Write Mozc server versions provided for the running operating-system release. |
| [`mozc::server::install`](modules/install.md#mozcserverinstall) | Install the Mozc server, defaulting to the newest version for the running release. |
| [`mozc::ibus::versions`](modules/install.md#mozcibusversions) | Write IBus Mozc versions provided for the running operating-system release. |
| [`mozc::ibus::install`](modules/install.md#mozcibusinstall) | Install IBus Mozc and the Mozc server of the same version. |
| [`mozc::tool::versions`](modules/install.md#mozctoolversions) | Write Mozc GUI tool versions provided for the running operating-system release. |
| [`mozc::tool::install`](modules/install.md#mozctoolinstall) | Install the Mozc GUI tools. |
| [`ssh-server::versions`](modules/install.md#ssh-serverversions) | Write OpenSSH server versions available to the current platform. |
| [`ssh-server::install`](modules/install.md#ssh-serverinstall) | Install the OpenSSH server, enable it at boot, and start it. |
| [`vscode::versions`](modules/install.md#vscodeversions) | Write VS Code versions available to the current platform. |
| [`vscode::install`](modules/install.md#vscodeinstall) | Install VS Code from the Microsoft repository or Homebrew. |
| [`gh::install`](modules/install.md#ghinstall) | Install GitHub CLI from its official Ubuntu APT repository. |
| [`brave::versions`](modules/install.md#braveversions) | Write Brave versions available to the current platform. |
| [`brave::install`](modules/install.md#braveinstall) | Install Brave from its official repository or Homebrew. |
| [`chrome::versions`](modules/install.md#chromeversions) | Write Google Chrome versions available to the current platform. |
| [`chrome::install`](modules/install.md#chromeinstall) | Install Google Chrome from the Google repository or Homebrew. |
| [`claude-desktop::install`](modules/install.md#claude-desktopinstall) | Install the newest Claude Desktop, the app that also runs Claude Code sessions. |
| [`claude-code::install`](modules/install.md#claude-codeinstall) | Install the newest Claude Code CLI. |
| [`codex::install`](modules/install.md#codexinstall) | Install the newest OpenAI Codex CLI. |
| [`chatgpt::install`](modules/install.md#chatgptinstall) | Install the newest ChatGPT desktop app, which also runs Codex. |
| [`thunderbird::versions`](modules/install.md#thunderbirdversions) | Write Thunderbird versions available to the current platform. |
| [`thunderbird::install`](modules/install.md#thunderbirdinstall) | Install the Thunderbird email client. |
| [`gimp::versions`](modules/install.md#gimpversions) | Write GIMP versions available to the current platform. |
| [`gimp::install`](modules/install.md#gimpinstall) | Install GIMP, and on Linux the G'MIC plugin from the selected source. |
| [`gimp::gmic::versions`](modules/install.md#gimpgmicversions) | Write G'MIC GIMP plugin versions available from the selected source. |
| [`gimp::gmic::install`](modules/install.md#gimpgmicinstall) | Install the G'MIC GIMP plugin. |
| [`microsoft-edge::versions`](modules/install.md#microsoft-edgeversions) | Write Microsoft Edge versions available to the current platform. |
| [`microsoft-edge::install`](modules/install.md#microsoft-edgeinstall) | Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew. |
| [`xcode::command-line-tools::upgrade`](modules/install.md#xcodecommand-line-toolsupgrade) | Update Xcode Command Line Tools without removing the installed tools. |
| [`qmk::toolbox::install`](modules/install.md#qmktoolboxinstall) | Install QMK Toolbox with Homebrew on macOS. |
| [`qmk::cli::install`](modules/install.md#qmkcliinstall) | Install the QMK CLI with the official installer and diagnose the environment. |
| [`supabase::versions`](modules/install.md#supabaseversions) | Write Supabase CLI versions available to the current platform. |
| [`supabase::install`](modules/install.md#supabaseinstall) | Install the Supabase CLI from its Homebrew tap or release packages. |

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

## [`android-avd`](modules/android-avd.md)

| 関数 | 説明 |
|---|---|
| [`android::avd::list`](modules/android-avd.md#androidavdlist) | List AVD names in the selected Android SDK environment. |
| [`android::avd::profiles`](modules/android-avd.md#androidavdprofiles) | List hardware profiles available to avdmanager. |
| [`android::system-images::versions`](modules/android-avd.md#androidsystem-imagesversions) | List stable system images as API, tag, ABI, and revision values. |
| [`android::avd::create`](modules/android-avd.md#androidavdcreate) | Create one AVD from a stable Google APIs image without starting it. |
| [`android::avd::port::available`](modules/android-avd.md#androidavdportavailable) | Report whether an even emulator console port and its ADB port are both free. |
| [`android::avd::port::first`](modules/android-avd.md#androidavdportfirst) | Write the first free emulator console port. |
| [`android::avd::start`](modules/android-avd.md#androidavdstart) | Start one AVD and wait for Android to finish booting. |
| [`android::avd::stop`](modules/android-avd.md#androidavdstop) | Stop the named AVD, or the only running AVD when no name is given. |
| [`android::avd::delete`](modules/android-avd.md#androidavddelete) | Delete one named AVD without changing other AVDs. |

## [`desktop`](modules/desktop.md)

| 関数 | 説明 |
|---|---|
| [`gsettings::string-array::add`](modules/desktop.md#gsettingsstring-arrayadd) | Add a literal value to a GSettings string array when it is absent. |
| [`gsettings::string-array::remove`](modules/desktop.md#gsettingsstring-arrayremove) | Remove every element equal to a literal value from a GSettings string array. |
| [`gnome::keybinding::set-custom`](modules/desktop.md#gnomekeybindingset-custom) | Register a GNOME custom keyboard shortcut after removing conflicting shortcuts. |
| [`gnome::input-source::set-layout`](modules/desktop.md#gnomeinput-sourceset-layout) | Set GNOME input sources to Mozc followed by one XKB layout. |
| [`keyboard::system-layout::set`](modules/desktop.md#keyboardsystem-layoutset) | Set the system keyboard layout. |
| [`gnome::keyboard-layout::set-us`](modules/desktop.md#gnomekeyboard-layoutset-us) | Set GNOME input sources and the system keyboard layout to Mozc and US. |
| [`gnome::keyboard-layout::set-jp`](modules/desktop.md#gnomekeyboard-layoutset-jp) | Set GNOME input sources and the system keyboard layout to Mozc and JP. |
| [`gnome::input-source::set-shortcuts`](modules/desktop.md#gnomeinput-sourceset-shortcuts) | Set GNOME input-source switching shortcuts and direct US and Mozc shortcuts. |
| [`gnome::input-source::set-mozc-first`](modules/desktop.md#gnomeinput-sourceset-mozc-first) | Put Mozc first in GNOME input sources while keeping the current XKB layout. |
| [`gnome::window::set-button-layout`](modules/desktop.md#gnomewindowset-button-layout) | Set the GNOME window title-bar button layout. |
| [`mozc::ibus::set-hiragana-as-default`](modules/desktop.md#mozcibusset-hiragana-as-default) | Start Mozc in Hiragana mode and restart IBus. |
| [`keyboard::setup-ime-keys`](modules/desktop.md#keyboardsetup-ime-keys) | Map the Convert and Nonconvert keys of USB keyboards to henkan and muhenkan. |
| [`ubuntu::setup`](modules/desktop.md#ubuntusetup) | Apply the common Ubuntu user configuration, stopping at the first failure. |
| [`ubuntu::setup-external`](modules/desktop.md#ubuntusetup-external) | Install GnuPG and GitHub CLI when they are not already available. |
| [`ubuntu::setup-desktop`](modules/desktop.md#ubuntusetup-desktop) | Apply the Ubuntu user configuration and desktop settings, stopping at the first failure. |
| [`ubuntu::setup-desktop-22`](modules/desktop.md#ubuntusetup-desktop-22) | Install the newest Mozc for Ubuntu 22.04 and apply the desktop settings. |
| [`homebrew::install`](modules/desktop.md#homebrewinstall) | Install Homebrew with the official installer when it is missing. |
| [`homebrew::cask::disable-quarantine`](modules/desktop.md#homebrewcaskdisable-quarantine) | Install Homebrew casks without the quarantine attribute from now on. |
| [`shell::zsh::enable-interactive-comments`](modules/desktop.md#shellzshenable-interactive-comments) | Allow comments that start with # in interactive Zsh sessions. |
| [`mac::wake-on-lan::enable`](modules/desktop.md#macwake-on-lanenable) | Let the Mac wake from sleep through the network (Wake on LAN). |
| [`mac::sleep::disable-automatic`](modules/desktop.md#macsleepdisable-automatic) | Disable automatic system sleep while preserving display sleep timers. |
| [`mac::sleep::enable-automatic`](modules/desktop.md#macsleepenable-automatic) | Enable automatic system sleep after ten minutes while preserving display sleep timers. |
| [`mac::keyboard::use-function-keys`](modules/desktop.md#mackeyboarduse-function-keys) | Make F1 to F12 act as function keys without the fn key. |
| [`mac::keyboard::set-repeat`](modules/desktop.md#mackeyboardset-repeat) | Set the delay before key repeat starts and the repeat interval. |
| [`mac::trackpad::disable-smart-zoom`](modules/desktop.md#mactrackpaddisable-smart-zoom) | Turn off smart zoom, the two-finger double tap, on built-in and external trackpads. |
| [`mac::dock::set-autohide-instant`](modules/desktop.md#macdockset-autohide-instant) | Show and hide the Dock immediately, without a delay or an animation. |
| [`mac::dock::hide-recent-applications`](modules/desktop.md#macdockhide-recent-applications) | Hide recently used applications in the Dock. |
| [`mac::dock::set-minimize-effect`](modules/desktop.md#macdockset-minimize-effect) | Set the effect used when a window is minimized into the Dock. |
| [`mac::dock::set-position`](modules/desktop.md#macdockset-position) | Place the Dock on one edge of the screen. |
| [`mac::applications::remove-bundled`](modules/desktop.md#macapplicationsremove-bundled) | Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications. |
| [`mac::quarantine::remove-applications`](modules/desktop.md#macquarantineremove-applications) | Remove the quarantine attribute from everything below /Applications. |
| [`mac::full-disk-access::target-paths`](modules/desktop.md#macfull-disk-accesstarget-paths) | Write the programs that Full Disk Access must list for a command, a path, or an application. |
| [`mac::full-disk-access::open`](modules/desktop.md#macfull-disk-accessopen) | Open Full Disk Access in System Settings and show the programs to add in Finder. |
| [`mac::full-disk-access::is-granted`](modules/desktop.md#macfull-disk-accessis-granted) | Test whether the application that runs the current shell has Full Disk Access. |
| [`mac::gatekeeper::disable`](modules/desktop.md#macgatekeeperdisable) | Ask macOS to allow applications from anywhere and open Privacy & Security. |
| [`mac::setup`](modules/desktop.md#macsetup) | Apply the complete macOS setup, continuing after failed steps. |
