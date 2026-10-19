# shell

Inspection of the current shell.

## Overview

Tests return 0 or 1 without output.

## Index

* [shell::is-function-defined](#shellis-function-defined)

### shell::is-function-defined

Test whether a shell function is defined.

#### Example

```bash
shell::is-function-defined node::install && node::install
```

#### Arguments

* **$1** (string): Function name.

#### Exit codes

* **0**: The function is defined.
* **1**: No function has that name.
* **64**: The name is empty, starts with a dash, or contains a newline.

