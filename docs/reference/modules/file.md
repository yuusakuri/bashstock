# file

Reading, writing, finding, and replacing text in files.

## Overview

Text is written to a temporary file in the target directory and then moved into place.

## Index

* [file::ensure-exists](#fileensure-exists)
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
* [file::write-text](#filewrite-text)
* [file::find-by-content](#filefind-by-content)
* [file::latest-by-name](#filelatest-by-name)
* [file::edit](#fileedit)
* [file::release](#filerelease)
* [file::tree-with-contents](#filetree-with-contents)
* [file::modified-time-unix-seconds](#filemodified-time-unix-seconds)

### file::ensure-exists

Create an empty regular file when it does not exist.

The mode applies only to a newly created file and is independent of the
caller's umask. An existing regular file is left unchanged.

#### Example

```bash
file::ensure-exists "${HOME}/.env" 0600
```

#### Arguments

* **$1** (string): File path.
* **$2** (string): Optional octal mode for a new file. Defaults to 0644.

#### Exit codes

* **0**: The file exists or was created.
* **64**: The path is empty, the mode is invalid, or the argument count is wrong.
* **66**: The path is not a regular file.
* **74**: The file could not be created with the requested mode.

### file::contains-match

Test whether any file line matches a Python regular expression.

#### Example

```bash
file::contains-match /etc/hosts '^127\.0\.0\.1\s+localhost\b'
```

#### Arguments

* **$1** (string): Readable regular file; a symbolic link is refused.
* **$2** (string): Python regular expression without newlines.

#### Exit codes

* **0**: At least one line matches.
* **1**: No line matches.
* **64**: The expression is invalid, or the argument count is not two.
* **66**: The file is missing, unreadable, or a symbolic link.
* **69**: Python 3 is unavailable.

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
A missing file is created with mode 0644 whatever the caller's umask is.

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

### file::write-text

Write text to a regular file using an atomic replacement.

New files get mode 0644 whatever the caller's umask is and whether or not
root writes them; existing metadata is preserved.

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

