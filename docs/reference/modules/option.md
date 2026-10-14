# option

Checks for groups of named options.

## Overview

option::require-single reports an error unless exactly one option of a group has a value.

## Index

* [option::require-single](#optionrequire-single)

### option::require-single

Require exactly one named option value to be non-empty.

Use it when mutually exclusive options were parsed into separate variables.

#### Example

```bash
option::require-single --file "${file}" --url "${url}" || return "$?"
```

#### Arguments

* **...** (string): Pairs of option name and value; at least two pairs.

#### Exit codes

* **0**: Exactly one value is non-empty.
* **64**: None or several values are set, or the pairs are invalid.

#### Output on stderr

* A message listing the options when none or more than one is set.

