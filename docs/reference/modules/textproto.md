# textproto

textproto files.

## Overview

Top-level scalar fields are replaced or appended.

## Index

* [textproto::set-scalar](#textprotoset-scalar)

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

