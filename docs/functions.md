# 関数一覧

BashStockが公開する関数の一覧。名前空間ごとにまとめる。各関数の設計判断は[設計](design.md)、名前付き引数とTab補完の正式仕様は[名前付き引数の仕様](argument-model.md)を参照する。

`-as-root`で終わる関数は、管理者権限が必要な操作を`libexec/bashstock-root`を通じて実行する。

## `number`

| 関数 | 説明 |
|---|---|
| `number::is-integer` | Test whether a value is a signed or unsigned decimal integer. |
| `number::is-decimal` | Test whether a value is a signed or unsigned decimal fraction. |
| `number::is-number` | Test whether a value is a decimal integer or fraction. |

## `string`

| 関数 | 説明 |
|---|---|
| `string::trim` | Remove leading and trailing whitespace. |
| `string::collapse-whitespace` | Trim whitespace and collapse each interior run to one ASCII space. |
| `string::split` | Split a value by a non-empty literal delimiter and preserve empty fields. |
| `string::lower` | Convert ASCII uppercase letters to lowercase. |
| `string::upper` | Convert ASCII lowercase letters to uppercase. |
| `string::swap-case` | Swap the case of every ASCII letter. |
| `string::lower-first` | Convert the first ASCII letter to lowercase when applicable. |
| `string::upper-first` | Convert the first ASCII letter to uppercase when applicable. |
| `string::strip-surrounding-quotes` | Remove one matching pair of surrounding single or double quotes. |
| `string::remove-all-matches` | Remove every substring that matches a Bash pattern. |
| `string::remove-first-match` | Remove the first substring that matches a Bash pattern. |
| `string::remove-prefix` | Remove the longest prefix that matches a Bash pattern. |
| `string::remove-suffix` | Remove the longest suffix that matches a Bash pattern. |
| `string::encode-url` | Percent-encode a UTF-8 string byte by byte. |
| `string::decode-url` | Decode percent-encoded bytes without translating plus signs. |
| `string::contains` | Test whether a value contains a literal substring. |
| `string::starts-with` | Test whether a value starts with a literal prefix. |
| `string::ends-with` | Test whether a value ends with a literal suffix. |
| `string::join` | Join values with a literal delimiter. |
| `string::byte-length` | Write the byte length of a value. |
| `string::length` | Write the character length of a value in a UTF-8 locale. |
| `string::replace-first` | Replace the first substring that matches a Bash pattern. |
| `string::replace-all` | Replace every substring that matches a Bash pattern. |
| `string::replace-last` | Replace the rightmost non-empty substring that matches a Bash pattern. |
| `string::require-non-empty` | Require a named value to be non-empty. |
| `string::require-empty` | Require a named value to be empty. |
| `string::require-allowed` | Require a named value to equal one of the allowed values. |
| `string::slice` | Write a validated character range from a UTF-8 string. |

## `regex`

| 関数 | 説明 |
|---|---|
| `regex::is-match` | Test a value against a Bash POSIX extended regular expression. |
| `regex::capture-group` | Write one capture group from a Bash POSIX extended regular expression. |
| `regex::capture-groups` | Write all capture groups from a Bash POSIX extended regular expression. |

## `array`

| 関数 | 説明 |
|---|---|
| `array::contains` | Test whether the remaining arguments contain the expected value. |
| `array::reverse` | Write the arguments in reverse order, one value per line. |
| `array::length` | Write the number of arguments. |
| `array::first` | Write the first argument when one is available. |
| `array::last` | Write the last argument when one is available. |
| `array::unique` | Write each distinct argument once in its original order. |
| `array::prepend-to-each` | Prefix every value and write one result per line. |

## `arg`

| 関数 | 説明 |
|---|---|
| `arg::require-next` | Require a value to follow the current named argument. |
| `arg::require` | Require a named argument to have a non-empty value. |
| `arg::integer` | Require a named argument value to be a decimal integer. |
| `arg::one-of` | Require a named argument value to match one candidate. |
| `arg::unknown` | Report a named argument that no case branch recognized. |

## `arg::completion`

| 関数 | 説明 |
|---|---|
| `arg::completion::dispatch` | Dispatch Tab completion to the target function's completion helper. Registered with `complete -F` for every function that has a matching `::_<action>-args` helper. Bash calls this with no arguments and reads COMP_WORDS, COMP_CWORD, and COMPREPLY. |
| `arg::completion::register-all` | Register Tab completion for every function that has a completion helper. Called once after every module has been loaded, so that functions defined later in the load order are still discovered. |

## `system`

| 関数 | 説明 |
|---|---|
| `system::operating-system` | Write the normalized operating-system family. |
| `system::host-name` | Write the current host name. |

## `command`

| 関数 | 説明 |
|---|---|
| `command::exists` | Test whether a command name resolves in the current environment. |
| `command::require` | Require a command name to resolve in the current environment. |
| `command::run-as-root` | Run a command directly as root or through validated sudo access. |

## `shell`

| 関数 | 説明 |
|---|---|
| `shell::is-function-defined` | Test whether a shell function is defined. |

## `terminal`

| 関数 | 説明 |
|---|---|
| `terminal::is-available` | Test whether the controlling terminal is readable and writable. |

## `path`

| 関数 | 説明 |
|---|---|
| `path::directory-name` | Write the lexical directory portion of a path. |
| `path::base-name` | Write the final component of a path with an optional suffix removed. |
| `path::is-directory` | Test whether a path names a directory. |
| `path::is-empty-directory` | Test whether a path names an empty directory. |
| `path::is-executable` | Test whether the current user may execute a path. |
| `path::is-executable-file` | Test whether a path names an executable regular file. |
| `path::is-regular-file` | Test whether a path names a regular file. |
| `path::is-symbolic-link` | Test whether a path names a symbolic link. |
| `path::is-readable` | Test whether the current user may read a path. |
| `path::is-writable` | Test whether the current user may write a path. |
| `path::extension` | Write the extension of the final path component. |
| `path::normalize` | Normalize a path lexically without accessing the file system. |
| `path::relative` | Write the lexical relative path from one path to another. |
| `path::config-home` | Write the absolute configuration-home directory. |
| `path::change-owner-recursively-as-root` | Change directory ownership recursively through the root helper. |

## `prompt`

| 関数 | 説明 |
|---|---|
| `prompt::confirm` | Read and normalize a yes-or-no answer. |
| `prompt::read-line-with-default` | Read one line and substitute a default only for empty input. |
| `prompt::confirm-or-cancel` | Read and normalize a yes, no, or cancel answer. |
| `prompt::select-one` | Display indexed choices and write the selected value. |

## `time`

| 関数 | 説明 |
|---|---|
| `time::monotonic-milliseconds` | Write monotonic milliseconds that exclude suspended time. |
| `time::boottime-milliseconds` | Write milliseconds since boot including suspended time. |
| `time::unix-milliseconds` | Write Unix-epoch milliseconds. |
| `time::unix-seconds` | Write Unix-epoch seconds rounded down. |
| `time::unix-days` | Write Unix-epoch days rounded down. |
| `time::utc-date-time-milliseconds` | Write the current UTC date and time with milliseconds. |
| `time::utc-date-time-seconds` | Write the current UTC date and time with seconds. |
| `time::utc-date` | Write the current UTC date. |
| `time::local-date-time-milliseconds` | Write the current local date and time with milliseconds and an offset. |
| `time::local-date-time-seconds` | Write the current local date and time with seconds and an offset. |
| `time::local-date` | Write the current local date. |

## `log`

| 関数 | 説明 |
|---|---|
| `log::info` | Write an informational log message. |
| `log::warn` | Write a warning log message. |
| `log::error` | Write an error log message without exiting. |

## `json`

| 関数 | 説明 |
|---|---|
| `json::require-present` | Require a named JSON-derived value to be neither empty nor null. |

## `option`

| 関数 | 説明 |
|---|---|
| `option::require-single` | Require exactly one named option value to be non-empty. |

## `file`

| 関数 | 説明 |
|---|---|
| `file::contains-match` | Test whether any file line matches a Perl regular expression. |
| `file::verify-sha256` | Test a file against an expected SHA-256 digest. |
| `file::append-text` | Append text without conversion using the current user's permissions. |
| `file::append-text-as-root` | Append text without conversion through the root helper. |
| `file::replace-text` | Replace the first Perl regular-expression match on every file line. |
| `file::replace-text-as-root` | Replace line matches through the root helper. |
| `file::replace-text-in-files` | Replace line matches across multiple files. |
| `file::replace-text-in-files-as-root` | Replace line matches across multiple files through the root helper. |
| `file::replace-or-append-text` | Replace line matches or append one line when no match exists. |
| `file::replace-or-append-text-as-root` | Replace line matches or append through the root helper. |

## `user`

| 関数 | 説明 |
|---|---|
| `user::name` | Write the effective user's name. |
| `user::primary-group` | Write the effective user's primary group name. |
| `user::is-root` | Test whether the effective user is root. |
| `user::exists` | Test whether a local user account exists. |
| `user::create-system-as-root` | Create a non-login system account through the root helper. |
| `user::create-login-as-root` | Create a local login account through the root helper. |

## `aws`

| 関数 | 説明 |
|---|---|
| `aws::is-ec2-instance` | Test whether IMDSv2 is available for the current instance. |
| `aws::instance-metadata` | Write one validated EC2 instance metadata value. |
| `aws::instance-id` | Write the current EC2 instance identifier. |
| `aws::instance-region` | Write the current EC2 instance region. |
| `aws::instance-availability-zone` | Write the current EC2 instance availability zone. |
| `aws::instance-private-ip` | Write the current EC2 instance private IPv4 address. |
| `aws::instance-tags` | Write all tags for one EC2 instance. |
| `aws::instance-tag` | Write one EC2 instance tag value. |
| `aws::wait-for-instance-tag` | Wait for one EC2 instance tag to become available. |
| `aws::instances-with-tag` | Write EC2 instances that have a requested tag. |
| `aws::auto-scaling-group` | Write the Auto Scaling group that contains an EC2 instance. |
| `aws::instances-in-auto-scaling-group` | Write running or pending instances in an Auto Scaling group. |
| `aws::auto-scaling-group-name` | Write the current instance's Auto Scaling group name. |
| `aws::auto-scaling-group-size` | Write the desired capacity of an Auto Scaling group. |
