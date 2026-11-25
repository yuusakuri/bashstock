# number

Tests for integer, decimal, and numeric values.

## Overview

Each test reads one argument and returns 0 or 1 without output.

## Index

* [number__is-integer](#number__is-integer)
* [number__is-decimal](#number__is-decimal)
* [number__is-number](#number__is-number)

### number__is-integer

Test whether a value is a signed or unsigned decimal integer.

#### Example

```bash
number__is-integer -7 && printf 'integer\n'
# integer
```

#### Arguments

* **$1** (string): Value to test.

#### Exit codes

* **0**: The value is an integer such as 42, -7, or +3.
* **1**: The value is not an integer.
* **64**: The argument count is not one.

### number__is-decimal

Test whether a value is a signed or unsigned decimal fraction.

#### Example

```bash
number__is-decimal 1.5 && printf 'decimal\n'
# decimal
number__is-decimal 15 || printf 'not a fraction\n'
# not a fraction
```

#### Arguments

* **$1** (string): Value to test.

#### Exit codes

* **0**: The value has a decimal point, such as 1.5, -0.25, or .5.
* **1**: The value is not a decimal fraction.
* **64**: The argument count is not one.

### number__is-number

Test whether a value is a decimal integer or fraction.

#### Example

```bash
number__is-number abc || printf 'not a number\n'
# not a number
```

#### Arguments

* **$1** (string): Value to test.

#### Exit codes

* **0**: The value is an integer or a decimal fraction.
* **1**: The value is not a number.
* **64**: The argument count is not one.

