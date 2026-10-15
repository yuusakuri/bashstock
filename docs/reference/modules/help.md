# help

Show the documentation of BashStock functions in the terminal.

## Overview

The documentation is read from the shdoc comment block above each function.

## Index

* [help::show](#helpshow)

### help::show

Show the documentation of a BashStock function, like Get-Help in PowerShell.

The help is read from the shdoc comment block above the function definition,
so it is the same text that docs/reference describes.

#### Example

```bash
help::show string::trim
```

#### Arguments

* **$1** (string): Name of a loaded function, such as string::trim.

#### Exit codes

* **0**: The help was written.
* **1**: No function has that name.
* **64**: The argument count is not one.
* **66**: The function has no documentation or its source file cannot be read.

#### Output on stdout

* The function name, description, arguments, options, outputs, exit codes, and example.

