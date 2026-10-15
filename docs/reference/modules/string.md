# string

String transformation, splitting, and comparison.

## Overview

Each function reads its input from arguments and writes the result to standard output.

## Index

* [string::trim](#stringtrim)
* [string::collapse-whitespace](#stringcollapse-whitespace)
* [string::split](#stringsplit)
* [string::lower](#stringlower)
* [string::upper](#stringupper)
* [string::swap-case](#stringswap-case)
* [string::lower-first](#stringlower-first)
* [string::upper-first](#stringupper-first)
* [string::strip-surrounding-quotes](#stringstrip-surrounding-quotes)
* [string::remove-all-matches](#stringremove-all-matches)
* [string::remove-first-match](#stringremove-first-match)
* [string::remove-prefix](#stringremove-prefix)
* [string::remove-suffix](#stringremove-suffix)
* [string::encode-url](#stringencode-url)
* [string::decode-url](#stringdecode-url)
* [string::contains](#stringcontains)
* [string::starts-with](#stringstarts-with)
* [string::ends-with](#stringends-with)
* [string::join](#stringjoin)
* [string::byte-length](#stringbyte-length)
* [string::length](#stringlength)
* [string::replace-first](#stringreplace-first)
* [string::replace-all](#stringreplace-all)
* [string::replace-last](#stringreplace-last)
* [string::require-non-empty](#stringrequire-non-empty)
* [string::require-empty](#stringrequire-empty)
* [string::require-allowed](#stringrequire-allowed)
* [string::slice](#stringslice)

### string::trim

Remove leading and trailing whitespace.

#### Example

```bash
string::trim '  hello world  '
# hello world
```

#### Arguments

* **$1** (string): Value to trim.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value without leading and trailing whitespace.

### string::collapse-whitespace

Trim whitespace and collapse each interior run to one ASCII space.

#### Example

```bash
string::collapse-whitespace $'  a\t b   c '
# a b c
```

#### Arguments

* **$1** (string): Value to normalize.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The trimmed value with single spaces between words.

### string::split

Split a value by a non-empty literal delimiter and preserve empty fields.

#### Example

```bash
string::split 'a,,b' ','
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

### string::lower

Convert ASCII uppercase letters to lowercase.

Letters outside ASCII are left unchanged, whatever the locale.

#### Example

```bash
string::lower 'Hello World'
# hello world
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The converted value.

### string::upper

Convert ASCII lowercase letters to uppercase.

Letters outside ASCII are left unchanged, whatever the locale.

#### Example

```bash
string::upper 'Hello World'
# HELLO WORLD
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The converted value.

### string::swap-case

Swap the case of every ASCII letter.

#### Example

```bash
string::swap-case 'Hello World'
# hELLO wORLD
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value with uppercase and lowercase ASCII letters swapped.

### string::lower-first

Convert the first ASCII letter to lowercase when applicable.

#### Example

```bash
string::lower-first 'Hello'
# hello
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value with its first character lowercased when it is an ASCII letter.

### string::upper-first

Convert the first ASCII letter to uppercase when applicable.

#### Example

```bash
string::upper-first 'hello'
# Hello
```

#### Arguments

* **$1** (string): Value to convert.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value with its first character uppercased when it is an ASCII letter.

### string::strip-surrounding-quotes

Remove one matching pair of surrounding single or double quotes.

#### Example

```bash
string::strip-surrounding-quotes '"/opt/my app"'
# /opt/my app
```

#### Arguments

* **$1** (string): Value that may be quoted.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The value without the surrounding pair, or the value unchanged.

### string::remove-all-matches

Remove every substring that matches a Bash pattern.

#### Example

```bash
string::remove-all-matches 'a1b2c3' '[0-9]'
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

### string::remove-first-match

Remove the first substring that matches a Bash pattern.

#### Example

```bash
string::remove-first-match 'a-b-c' '-'
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

### string::remove-prefix

Remove the longest prefix that matches a Bash pattern.

#### Example

```bash
string::remove-prefix '/usr/local/bin/node' '*/'
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

### string::remove-suffix

Remove the longest suffix that matches a Bash pattern.

#### Example

```bash
string::remove-suffix 'archive.tar.gz' '.*'
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

### string::encode-url

Percent-encode a UTF-8 string byte by byte.

Unreserved characters (letters, digits, -, ., _, ~) are kept; every other byte is encoded.

#### Example

```bash
string::encode-url 'a b&c'
# a%20b%26c
```

#### Arguments

* **$1** (string): Value to encode.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one.

#### Output on stdout

* The percent-encoded value.

### string::decode-url

Decode percent-encoded bytes without translating plus signs.

#### Example

```bash
string::decode-url 'a%20b%26c'
# a b&c
```

#### Arguments

* **$1** (string): Percent-encoded value.

#### Exit codes

* **0**: The value was written.
* **64**: The argument count is not one, or an escape is malformed.

#### Output on stdout

* The decoded value.

### string::contains

Test whether a value contains a literal substring.

#### Example

```bash
string::contains "${PATH}" /usr/local/bin && printf 'on PATH\n'
```

#### Arguments

* **$1** (string): Value to search.
* **$2** (string): Literal substring.

#### Exit codes

* **0**: The value contains the substring.
* **1**: The value does not contain the substring.
* **64**: The argument count is not two.

### string::starts-with

Test whether a value starts with a literal prefix.

#### Example

```bash
string::starts-with "${url}" https:// || return 64
```

#### Arguments

* **$1** (string): Value to test.
* **$2** (string): Literal prefix.

#### Exit codes

* **0**: The value starts with the prefix.
* **1**: The value does not start with the prefix.
* **64**: The argument count is not two.

### string::ends-with

Test whether a value ends with a literal suffix.

#### Example

```bash
string::ends-with "${file}" .tar.gz && tar -xzf "${file}"
```

#### Arguments

* **$1** (string): Value to test.
* **$2** (string): Literal suffix; an empty suffix always matches.

#### Exit codes

* **0**: The value ends with the suffix.
* **1**: The value does not end with the suffix.
* **64**: The argument count is not two.

### string::join

Join values with a literal delimiter.

#### Example

```bash
string::join , a b c
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

### string::byte-length

Write the byte length of a value.

#### Example

```bash
string::byte-length 'あ'
# 3
```

#### Arguments

* **$1** (string): Value to measure.

#### Exit codes

* **0**: The length was written.
* **64**: The argument count is not one.

#### Output on stdout

* The number of bytes.

### string::length

Write the character length of a value in a UTF-8 locale.

#### Example

```bash
LC_ALL=C.UTF-8 string::length 'あい'
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

### string::replace-first

Replace the first substring that matches a Bash pattern.

Backslashes and ampersands in the replacement are literal, also in Bash 5.2
where patsub_replacement is enabled.

#### Example

```bash
string::replace-first 'a-b-c' '-' '+'
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

### string::replace-all

Replace every substring that matches a Bash pattern.

Backslashes and ampersands in the replacement are literal.

#### Example

```bash
string::replace-all 'a-b-c' '-' '+'
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

### string::replace-last

Replace the rightmost non-empty substring that matches a Bash pattern.

#### Example

```bash
string::replace-last 'a-b-c' '-' '+'
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

### string::require-non-empty

Require a named value to be non-empty.

#### Example

```bash
string::require-non-empty USER_NAME "${user_name}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the value for the message.
* **$2** (string): Value to check.

#### Exit codes

* **0**: The value is not empty.
* **64**: The value is empty, or the name is invalid.

#### Output on stderr

* A message naming the value when it is empty.

### string::require-empty

Require a named value to be empty.

#### Example

```bash
string::require-empty REMAINDER "${remainder}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the value for the message.
* **$2** (string): Value to check.

#### Exit codes

* **0**: The value is empty.
* **64**: The value is not empty, or the name is invalid.

#### Output on stderr

* A message naming the value when it is not empty.

### string::require-allowed

Require a named value to equal one of the allowed values.

#### Example

```bash
string::require-allowed SOURCE "${source}" os official || return "$?"
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

### string::slice

Write a validated character range from a UTF-8 string.

#### Example

```bash
LC_ALL=C.UTF-8 string::slice 'こんにちは' 1 3
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

