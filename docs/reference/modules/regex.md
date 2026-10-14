# regex

Bash extended regular expression matching and capture groups.

## Overview

Expressions use the POSIX extended syntax of the Bash =~ operator.

## Index

* [regex::is-match](#regexis-match)
* [regex::capture-group](#regexcapture-group)
* [regex::capture-groups](#regexcapture-groups)

### regex::is-match

Test a value against a Bash POSIX extended regular expression.

#### Example

```bash
regex::is-match "${version}" '^[0-9]+\.[0-9]+\.[0-9]+$'
```

#### Arguments

* **$1** (string): Value to test.
* **$2** (string): Extended regular expression, as used by [[ =~ ]].

#### Exit codes

* **0**: The value matches.
* **1**: The value does not match.
* **64**: The expression is invalid, or the argument count is not two.

### regex::capture-group

Write one capture group from a Bash POSIX extended regular expression.

#### Example

```bash
regex::capture-group 'v1.22.3' '^v([0-9]+)\.([0-9]+)' 2
# 22
```

#### Arguments

* **$1** (string): Value to match.
* **$2** (string): Extended regular expression with capture groups.
* **$3** (integer): Group number; 0 is the whole match.

#### Exit codes

* **0**: The value matches and the group was written.
* **1**: The value does not match.
* **64**: The expression or group is invalid, or the captured text contains a newline.

#### Output on stdout

* The captured text.

### regex::capture-groups

Write all capture groups from a Bash POSIX extended regular expression.

#### Example

```bash
regex::capture-groups 'user@example.com' '^([^@]+)@(.+)$'
# user
# example.com
```

#### Arguments

* **$1** (string): Value to match.
* **$2** (string): Extended regular expression with capture groups.

#### Exit codes

* **0**: The value matches and the groups were written.
* **1**: The value does not match.
* **64**: The expression is invalid, or a captured text contains a newline.

#### Output on stdout

* Each capture group from the first, one per line.

