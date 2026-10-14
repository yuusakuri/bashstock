# file

Reading, writing, and replacing text in files.

## Overview

Text is written to a temporary file in the target directory and then moved into place.

## Index

* [file::contains-match](#filecontains-match)
* [file::verify-sha256](#fileverify-sha256)
* [file::append-text](#fileappend-text)
* [file::replace-text](#filereplace-text)
* [file::replace-all-text](#filereplace-all-text)
* [file::replace-text-in-files](#filereplace-text-in-files)
* [file::replace-all-text-in-files](#filereplace-all-text-in-files)
* [file::replace-text-or-append](#filereplace-text-or-append)
* [file::replace-or-append-text](#filereplace-or-append-text)
* [file::append-text-as-root](#fileappend-text-as-root)
* [file::replace-text-as-root](#filereplace-text-as-root)
* [file::replace-all-text-as-root](#filereplace-all-text-as-root)
* [file::replace-text-in-files-as-root](#filereplace-text-in-files-as-root)
* [file::replace-all-text-in-files-as-root](#filereplace-all-text-in-files-as-root)
* [file::replace-or-append-text-as-root](#filereplace-or-append-text-as-root)

### file::contains-match

Test whether any file line matches a Perl regular expression.

#### Example

```bash
file::contains-match /etc/hosts '^127\.0\.0\.1\s+localhost\b'
```

#### Arguments

* **$1** (string): Readable regular file; a symbolic link is refused.
* **$2** (string): Perl regular expression without newlines.

#### Exit codes

* **0**: At least one line matches.
* **1**: No line matches.
* **64**: The expression is invalid, or the argument count is not two.
* **66**: The file is missing, unreadable, or a symbolic link.
* **69**: Perl is unavailable.

### file::verify-sha256

Test a file against an expected SHA-256 digest.

sha256sum is used on Linux and shasum on macOS; the digest is compared without regard to case.

#### Example

```bash
file::verify-sha256 node.tar.gz "${expected_sha256}" || rm -f node.tar.gz
```

#### Arguments

* **$1** (string): Readable regular file.
* **$2** (string): Expected digest as 64 hexadecimal digits.

#### Exit codes

* **0**: The digest matches.
* **1**: The digest differs.
* **64**: The digest is not 64 hexadecimal digits, or the argument count is not two.
* **66**: The file is missing, unreadable, or a symbolic link.
* **69**: sha256sum or shasum is unavailable.
* **74**: The digest could not be computed.

### file::append-text

Append text without conversion, elevating only when permissions require it.

The text is written exactly, so include a trailing newline when one is needed.
A missing file is created.

#### Example

```bash
file::append-text "${HOME}/.bashrc" $'export EDITOR=vim\n'
```

#### Arguments

* **$1** (string): File path; a symbolic link is refused.
* **$2** (string): Text to append.

#### Exit codes

* **0**: The text was appended.
* **64**: The path is empty or a symbolic link, or the argument count is not two.
* **66**: The path exists but is not a regular file.
* **74**: The file could not be written.
* other The status of the root helper when elevation was needed.

### file::replace-text

Replace the first Bash ERE match on every file line.

The file is rewritten through a temporary file, and root is used only when
the current user cannot write it.

#### Example

```bash
file::replace-text /etc/ssh/sshd_config '^#?PasswordAuthentication .*$' 'PasswordAuthentication no'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Nonempty Bash extended regular expression without newlines.
* **$3** (string): Literal one-line replacement text.

#### Exit codes

* **0**: The file was processed, whether or not a line matched.
* **64**: The expression or replacement is invalid, or the argument count is not three.
* **66**: The file is missing, not a regular file, or a symbolic link.
* **74**: The file could not be rewritten.
* other The status of the root helper when elevation was needed.

### file::replace-all-text

Replace every nonempty Bash ERE match on every file line.

#### Example

```bash
file::replace-all-text settings.ini 'http://' 'https://'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Bash extended regular expression that cannot match an empty string.
* **$3** (string): Literal one-line replacement text.

#### Exit codes

* **0**: The file was processed, whether or not a line matched.
* **64**: The expression can match an empty string or is invalid, or the argument count is not three.
* **66**: The file is missing, not a regular file, or a symbolic link.
* **74**: The file could not be rewritten.
* other The status of the root helper when elevation was needed.

### file::replace-text-in-files

Replace line matches across multiple files.

Every file is checked before any is changed, and root is used only when one
of them cannot be written by the current user.

#### Example

```bash
file::replace-text-in-files '^version=.*$' 'version=2.0.0' app/a.properties app/b.properties
```

#### Arguments

* **$1** (string): Nonempty Bash extended regular expression without newlines.
* **$2** (string): Literal one-line replacement text.
* **...** (string): Regular text files to update; at least one.

#### Exit codes

* **0**: The files were processed.
* **64**: The expression or replacement is invalid, or fewer than three arguments were given.
* **66**: A file is missing, not a regular file, or a symbolic link.
* **74**: A file could not be rewritten.
* other The status of the root helper when elevation was needed.

### file::replace-all-text-in-files

Replace every line match across multiple files.

#### Example

```bash
file::replace-all-text-in-files 'example\.org' 'example.com' docs/*.md
```

#### Arguments

* **$1** (string): Bash extended regular expression that cannot match an empty string.
* **$2** (string): Literal one-line replacement text.
* **...** (string): Regular text files to update; at least one.

#### Exit codes

* **0**: The files were processed.
* **64**: The expression or replacement is invalid, or fewer than three arguments were given.
* **66**: A file is missing, not a regular file, or a symbolic link.
* **74**: A file could not be rewritten.
* other The status of the root helper when elevation was needed.

### file::replace-text-or-append

Replace every line match or append one line when no match exists.

Only the matched text is replaced, so anchor the expression with ^ and $ to
replace a whole line.

#### Example

```bash
file::replace-text-or-append "${HOME}/.zshrc" '^export EDITOR=.*$' 'export EDITOR=vim'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Bash extended regular expression that cannot match an empty string.
* **$3** (string): Literal one-line text used as the replacement and as the appended line.

#### Exit codes

* **0**: The file was updated.
* **64**: The expression or text is invalid, or the argument count is not three.
* **66**: The file is missing, not a regular file, or a symbolic link.
* **74**: The file could not be rewritten.
* other The status of the root helper when elevation was needed.

### file::replace-or-append-text

Replace matching text or append it using the established API name.

Same as file::replace-text-or-append.

#### Example

```bash
file::replace-or-append-text /etc/environment '^LANG=.*$' 'LANG=en_US.UTF-8'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Bash extended regular expression that cannot match an empty string.
* **$3** (string): Literal one-line text.

#### Exit codes

* **0**: The file was updated.
* **64**: An argument is invalid.
* **66**: The file is missing, not a regular file, or a symbolic link.
* **74**: The file could not be rewritten.

### file::append-text-as-root

Append text through the root execution dispatcher.

Same as file::append-text, but always in a separate root process.

#### Example

```bash
file::append-text-as-root /etc/hosts $'192.0.2.10 build-server\n'
```

#### Arguments

* **$1** (string): File path; a symbolic link is refused.
* **$2** (string): Text to append.

#### Exit codes

* **0**: The text was appended.
* **64**: The argument count is not two, or the path is invalid.
* **74**: The file could not be written.
* **77**: sudo refused the credentials.

### file::replace-text-as-root

Replace the first expression match through the root execution dispatcher.

Same as file::replace-text, but always in a separate root process.

#### Example

```bash
file::replace-text-as-root /etc/default/grub '^GRUB_TIMEOUT=.*$' 'GRUB_TIMEOUT=3'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Nonempty Bash extended regular expression.
* **$3** (string): Literal one-line replacement text.

#### Exit codes

* **0**: The file was processed.
* **64**: An argument is invalid.
* **66**: The file is missing or not a regular file.
* **74**: The file could not be rewritten.
* **77**: sudo refused the credentials.

### file::replace-all-text-as-root

Replace every expression match through the root execution dispatcher.

Same as file::replace-all-text, but always in a separate root process.

#### Example

```bash
file::replace-all-text-as-root /etc/apt/sources.list 'http://archive' 'https://archive'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Bash extended regular expression that cannot match an empty string.
* **$3** (string): Literal one-line replacement text.

#### Exit codes

* **0**: The file was processed.
* **64**: An argument is invalid.
* **66**: The file is missing or not a regular file.
* **74**: The file could not be rewritten.
* **77**: sudo refused the credentials.

### file::replace-text-in-files-as-root

Replace expression matches in files through the root execution dispatcher.

Same as file::replace-text-in-files, but always in a separate root process.

#### Example

```bash
file::replace-text-in-files-as-root '^Port .*$' 'Port 2222' /etc/ssh/sshd_config
```

#### Arguments

* **$1** (string): Nonempty Bash extended regular expression.
* **$2** (string): Literal one-line replacement text.
* **...** (string): Regular text files to update; at least one.

#### Exit codes

* **0**: The files were processed.
* **64**: An argument is invalid, or fewer than three arguments were given.
* **66**: A file is missing or not a regular file.
* **74**: A file could not be rewritten.
* **77**: sudo refused the credentials.

### file::replace-all-text-in-files-as-root

Replace all expression matches in files through the root execution dispatcher.

Same as file::replace-all-text-in-files, but always in a separate root process.

#### Example

```bash
file::replace-all-text-in-files-as-root 'old-mirror' 'new-mirror' /etc/apt/sources.list.d/*.list
```

#### Arguments

* **$1** (string): Bash extended regular expression that cannot match an empty string.
* **$2** (string): Literal one-line replacement text.
* **...** (string): Regular text files to update; at least one.

#### Exit codes

* **0**: The files were processed.
* **64**: An argument is invalid, or fewer than three arguments were given.
* **66**: A file is missing or not a regular file.
* **74**: A file could not be rewritten.
* **77**: sudo refused the credentials.

### file::replace-or-append-text-as-root

Replace matching text or append it through the root execution dispatcher.

Same as file::replace-text-or-append, but always in a separate root process.

#### Example

```bash
file::replace-or-append-text-as-root /etc/sysctl.conf '^vm\.swappiness=.*$' 'vm.swappiness=10'
```

#### Arguments

* **$1** (string): Regular text file to update.
* **$2** (string): Bash extended regular expression that cannot match an empty string.
* **$3** (string): Literal one-line text.

#### Exit codes

* **0**: The file was updated.
* **64**: An argument is invalid.
* **66**: The file is missing or not a regular file.
* **74**: The file could not be rewritten.
* **77**: sudo refused the credentials.

