# array

Operations on the elements of a Bash array passed as arguments.

## Overview

Bash 3.2 cannot pass arrays by reference, so the elements are passed as separate arguments.

## Index

* [array__contains](#array__contains)
* [array__reverse](#array__reverse)
* [array__length](#array__length)
* [array__first](#array__first)
* [array__last](#array__last)
* [array__unique](#array__unique)
* [array__prepend-to-each](#array__prepend-to-each)

### array__contains

Test whether the remaining arguments contain the expected value.

#### Example

```bash
array__contains main "${branches[@]}" && printf 'main exists\n'
```

#### Arguments

* **$1** (string): Value to look for.
* **...** (string): Values to search.

#### Exit codes

* **0**: One of the values equals the expected value.
* **1**: No value equals the expected value.
* **64**: No expected value was given.

### array__reverse

Write the arguments in reverse order, one value per line.

#### Example

```bash
array__reverse a b c
# c
# b
# a
```

#### Arguments

* **...** (string): Values without newlines.

#### Exit codes

* **0**: The values were written.
* **64**: A value contains a newline.

#### Output on stdout

* The values from last to first, one per line.

### array__length

Write the number of arguments.

#### Example

```bash
array__length "${files[@]}"
```

#### Arguments

* **...** (string): Values to count.

#### Exit codes

* **0**: Always.

#### Output on stdout

* The number of values.

### array__first

Write the first argument when one is available.

#### Example

```bash
array__first "${hosts[@]}"
```

#### Arguments

* **...** (string): Values; the first one must not contain a newline.

#### Exit codes

* **0**: The first value was written.
* **1**: No value was given.
* **64**: The first value contains a newline.

#### Output on stdout

* The first value.

### array__last

Write the last argument when one is available.

#### Example

```bash
array__last "${versions[@]}"
```

#### Arguments

* **...** (string): Values; the last one must not contain a newline.

#### Exit codes

* **0**: The last value was written.
* **1**: No value was given.
* **64**: The last value contains a newline.

#### Output on stdout

* The last value.

### array__unique

Write each distinct argument once in its original order.

#### Example

```bash
array__unique b a b c a
# b
# a
# c
```

#### Arguments

* **...** (string): Values without newlines.

#### Exit codes

* **0**: The values were written.
* **64**: A value contains a newline.

#### Output on stdout

* Each distinct value once, one per line, in the order it first appeared.

### array__prepend-to-each

Prefix every value and write one result per line.

#### Example

```bash
array__prepend-to-each --exclude= .git node_modules
# --exclude=.git
# --exclude=node_modules
```

#### Arguments

* **$1** (string): Prefix without newlines.
* **...** (string): Values without newlines.

#### Exit codes

* **0**: The values were written.
* **64**: No prefix was given, or a value contains a newline.

#### Output on stdout

* Each value with the prefix, one per line.

