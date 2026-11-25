# string

String transformation, splitting, and comparison.

## Overview

Each function reads its input from arguments and writes the result to standard output.

## Index

* [string__trim](#string__trim)
* [string__collapse-whitespace](#string__collapse-whitespace)
* [string__split](#string__split)
* [string__lower](#string__lower)
* [string__upper](#string__upper)
* [string__swap-case](#string__swap-case)
* [string__lower-first](#string__lower-first)
* [string__upper-first](#string__upper-first)
* [string__strip-surrounding-quotes](#string__strip-surrounding-quotes)
* [string__remove-all-matches](#string__remove-all-matches)
* [string__remove-first-match](#string__remove-first-match)
* [string__remove-prefix](#string__remove-prefix)
* [string__remove-suffix](#string__remove-suffix)
* [string__encode-url](#string__encode-url)
* [string__decode-url](#string__decode-url)
* [string__contains](#string__contains)
* [string__starts-with](#string__starts-with)
* [string__ends-with](#string__ends-with)
* [string__join](#string__join)
* [string__byte-length](#string__byte-length)
* [string__length](#string__length)
* [string__replace-first](#string__replace-first)
* [string__replace-all](#string__replace-all)
* [string__replace-last](#string__replace-last)
* [string__require-non-empty](#string__require-non-empty)
* [string__require-empty](#string__require-empty)
* [string__require-allowed](#string__require-allowed)
* [string__slice](#string__slice)

### string__trim

Remove leading and trailing whitespace.

#### Example

```bash
string__trim '  hello world  '
# hello world
```

#### Arguments

* **$1** (string): Value to trim.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value without leading and trailing whitespace.

### string__collapse-whitespace

Trim whitespace and collapse each interior run to one ASCII space.

#### Example

```bash
string__collapse-whitespace $'  a\t b   c '
# a b c
```

#### Arguments

* **$1** (string): Value to normalize.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The trimmed value with single spaces between words.

### string__split

Split a value by a non-empty literal delimiter and preserve empty fields.

#### Example

```bash
string__split 'a,,b' ','
# a
#
# b
```

#### Arguments

* **$1** (string): Value without newlines.
* **$2** (string): Literal delimiter; it must not be empty.

#### Exit codes

* **0**: The fields were written.
* **64**: The delimiter is empty, or a value contains a newline.

#### Output on stdout

* Each field on its own line, including empty fields.

### string__lower

Convert ASCII uppercase letters to lowercase.

Letters outside ASCII are left unchanged, whatever the locale.

#### Example

```bash
string__lower 'Hello World'
# hello world
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The converted value.

### string__upper

Convert ASCII lowercase letters to uppercase.

Letters outside ASCII are left unchanged, whatever the locale.

#### Example

```bash
string__upper 'Hello World'
# HELLO WORLD
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The converted value.

### string__swap-case

Swap the case of every ASCII letter.

#### Example

```bash
string__swap-case 'Hello World'
# hELLO wORLD
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value with uppercase and lowercase ASCII letters swapped.

### string__lower-first

Convert the first ASCII letter to lowercase when applicable.

#### Example

```bash
string__lower-first 'Hello'
# hello
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value with its first character lowercased when it is an ASCII letter.

### string__upper-first

Convert the first ASCII letter to uppercase when applicable.

#### Example

```bash
string__upper-first 'hello'
# Hello
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value with its first character uppercased when it is an ASCII letter.

### string__strip-surrounding-quotes

Remove one matching pair of surrounding single or double quotes.

#### Example

```bash
string__strip-surrounding-quotes '"/opt/my app"'
# /opt/my app
```

#### Arguments

* **$1** (string): Value that may be quoted.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value without the surrounding pair, or the value unchanged.

### string__remove-all-matches

Remove every substring that matches a Bash pattern.

#### Example

```bash
string__remove-all-matches 'a1b2c3' '[0-9]'
# abc
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern, such as [0-9] or a literal text.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not two.

#### Output on stdout

* The value without the matching substrings.

### string__remove-first-match

Remove the first substring that matches a Bash pattern.

#### Example

```bash
string__remove-first-match 'a-b-c' '-'
# ab-c
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not two.

#### Output on stdout

* The value without the first matching substring.

### string__remove-prefix

Remove the longest prefix that matches a Bash pattern.

#### Example

```bash
string__remove-prefix '/usr/local/bin/node' '*/'
# node
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern for the prefix.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not two.

#### Output on stdout

* The value without the longest matching prefix.

### string__remove-suffix

Remove the longest suffix that matches a Bash pattern.

#### Example

```bash
string__remove-suffix 'archive.tar.gz' '.*'
# archive
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern for the suffix.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not two.

#### Output on stdout

* The value without the longest matching suffix.

### string__encode-url

Percent-encode a UTF-8 string byte by byte.

Unreserved characters (letters, digits, -, ., _, ~) are kept; every other byte is encoded.

#### Example

```bash
string__encode-url 'a b&c'
# a%20b%26c
```

#### Arguments

* **$1** (string): Value to encode.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The percent-encoded value.

### string__decode-url

Decode percent-encoded bytes without translating plus signs.

#### Example

```bash
string__decode-url 'a%20b%26c'
# a b&c
```

#### Arguments

* **$1** (string): Percent-encoded value.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one, or an escape is malformed.

#### Output on stdout

* The decoded value.

### string__contains

Test whether a value contains a literal substring.

#### Example

```bash
string__contains "${PATH}" /usr/local/bin && printf 'on PATH\n'
```

#### Arguments

* **$1** (string): Value to search.
* **$2** (string): Literal substring.

#### Exit codes

* **0**: The value contains the substring.
* **1**: The value does not contain the substring.
* **64**: The argument count is not two.

### string__starts-with

Test whether a value starts with a literal prefix.

#### Example

```bash
string__starts-with "${url}" https:// || return 64
```

#### Arguments

* **$1** (string): Value to test.
* **$2** (string): Literal prefix.

#### Exit codes

* **0**: The value starts with the prefix.
* **1**: The value does not start with the prefix.
* **64**: The argument count is not two.

### string__ends-with

Test whether a value ends with a literal suffix.

#### Example

```bash
string__ends-with "${file}" .tar.gz && tar -xzf "${file}"
```

#### Arguments

* **$1** (string): Value to test.
* **$2** (string): Literal suffix; an empty suffix always matches.

#### Exit codes

* **0**: The value ends with the suffix.
* **1**: The value does not end with the suffix.
* **64**: The argument count is not two.

### string__join

Join values with a literal delimiter.

#### Example

```bash
string__join , a b c
# a,b,c
```

#### Arguments

* **$1** (string): Delimiter.
* **...** (string): Values to join.

#### Exit codes

* **0**: The joined value was written.
* **64**: No delimiter was given.

#### Output on stdout

* The values joined by the delimiter, followed by a newline.

### string__byte-length

Write the byte length of a value.

#### Example

```bash
string__byte-length 'あ'
# 3
```

#### Arguments

* **$1** (string): Value to measure.

#### Exit codes

* **0**: The length was written.
* **64**: The argument count is not one.

#### Output on stdout

* The number of bytes.

### string__length

Write the character length of a value in a UTF-8 locale.

#### Example

```bash
LC_ALL=C.UTF-8 string__length 'あい'
# 2
```

#### Arguments

* **$1** (string): Value to measure.

#### Exit codes

* **0**: The length was written.
* **64**: The argument count is not one.
* **69**: The current locale does not use UTF-8.

#### Output on stdout

* The number of characters.

### string__replace-first

Replace the first substring that matches a Bash pattern.

Backslashes and ampersands in the replacement are literal, also in Bash 5.2
where patsub_replacement is enabled.

#### Example

```bash
string__replace-first 'a-b-c' '-' '+'
# a+b-c
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern; it must not be empty.
* **$3** (string): Literal replacement.

#### Exit codes

* **0**: The value was written.
* **64**: The pattern is empty, or the argument count is not three.

#### Output on stdout

* The value with the first match replaced.

### string__replace-all

Replace every substring that matches a Bash pattern.

Backslashes and ampersands in the replacement are literal.

#### Example

```bash
string__replace-all 'a-b-c' '-' '+'
# a+b+c
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern; it must not be empty.
* **$3** (string): Literal replacement.

#### Exit codes

* **0**: The value was written.
* **64**: The pattern is empty, or the argument count is not three.

#### Output on stdout

* The value with every match replaced.

### string__replace-last

Replace the rightmost non-empty substring that matches a Bash pattern.

#### Example

```bash
string__replace-last 'a-b-c' '-' '+'
# a-b+c
```

#### Arguments

* **$1** (string): Value to edit.
* **$2** (string): Bash pattern; it must not be empty.
* **$3** (string): Literal replacement.

#### Exit codes

* **0**: The value was written.
* **64**: The pattern is empty, or the argument count is not three.

#### Output on stdout

* The value with the last match replaced.

### string__require-non-empty

Require a named value to be non-empty.

#### Example

```bash
string__require-non-empty USER_NAME "${user_name}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the value for the message.
* **$2** (string): Value to check.

#### Exit codes

* **0**: The value is not empty.
* **64**: The value is empty, or the name is invalid.

#### Output on stderr

* A message naming the value when it is empty.

### string__require-empty

Require a named value to be empty.

#### Example

```bash
string__require-empty REMAINDER "${remainder}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the value for the message.
* **$2** (string): Value to check.

#### Exit codes

* **0**: The value is empty.
* **64**: The value is not empty, or the name is invalid.

#### Output on stderr

* A message naming the value when it is not empty.

### string__require-allowed

Require a named value to equal one of the allowed values.

#### Example

```bash
string__require-allowed SOURCE "${source}" os official || return "$?"
```

#### Arguments

* **$1** (string): Name of the value for the message.
* **$2** (string): Value to check.
* **...** (string): Allowed values; at least one is required.

#### Exit codes

* **0**: The value equals an allowed value.
* **64**: The value is not allowed, or the arguments are invalid.

#### Output on stderr

* A message listing the allowed values when the value is not one of them.

### string__slice

Write a validated character range from a UTF-8 string.

#### Example

```bash
LC_ALL=C.UTF-8 string__slice 'こんにちは' 1 3
# んに
```

#### Arguments

* **$1** (string): Value to slice.
* **$2** (integer): Start index, counted in characters from 0.
* **$3** (integer): Optional end index, exclusive. Defaults to the length.

#### Exit codes

* **0**: The range was written.
* **64**: An index is not a non-negative integer, START is after END, or END exceeds the length.
* **69**: The current locale does not use UTF-8.

#### Output on stdout

* The characters from START up to, but not including, END.

