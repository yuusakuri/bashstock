# arg

Validation and Tab completion of named function arguments.

## Overview

Functions that take --kebab-case named arguments use these helpers to report missing or invalid values with status 64 and to complete names with Tab.

## Index

* [arg::require-next](#argrequire-next)
* [arg::require](#argrequire)
* [arg::integer](#arginteger)
* [arg::one-of](#argone-of)
* [arg::unknown](#argunknown)
* [arg::completion::dispatch](#argcompletiondispatch)
* [arg::completion::register-all](#argcompletionregister-all)

### arg::require-next

Require a value to follow the current named argument.

Call it in a case branch of a named argument that takes a value, before
reading $2.

#### Example

```bash
case "$1" in
  --name)
    arg::require-next "$#" "$1" || return "$?"
    name="$2"
    shift 2
    ;;
esac
```

#### Arguments

* **$1** (integer): Number of arguments that remain, usually "$#".
* **$2** (string): Name of the current argument, such as --name.

#### Exit codes

* **0**: A value follows the argument.
* **64**: No value follows the argument, or the arguments are invalid.

#### Output on stderr

* A message naming the argument when its value is missing.

### arg::require

Require a named argument to have a non-empty value.

#### Example

```bash
arg::require --name "${name}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the argument for the message, such as --name.
* **$2** (string): Value that was given.

#### Exit codes

* **0**: The value is not empty.
* **64**: The value is empty, or the arguments are invalid.

#### Output on stderr

* A message naming the argument when the value is empty.

### arg::integer

Require a named argument value to be a decimal integer.

#### Example

```bash
arg::integer --count "${count}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the argument for the message, such as --count.
* **$2** (string): Value that was given.

#### Exit codes

* **0**: The value is a decimal integer.
* **64**: The value is not an integer, or the arguments are invalid.

#### Output on stderr

* A message naming the argument and the value when it is not an integer.

### arg::one-of

Require a named argument value to match one candidate.

#### Example

```bash
arg::one-of --algorithm "${algorithm}" ed25519 rsa3072 rsa4096 || return "$?"
```

#### Arguments

* **$1** (string): Name of the argument for the message, such as --mode.
* **$2** (string): Value that was given.
* **...** (string): Accepted values; at least one is required.

#### Exit codes

* **0**: The value equals one candidate.
* **64**: The value matches no candidate, or the arguments are invalid.

#### Output on stderr

* A message listing the accepted values when the value is not one of them.

### arg::unknown

Report a named argument that no case branch recognized.

Use it in the default branch of the case statement that parses named arguments.

#### Example

```bash
case "$1" in
  *) arg::unknown "$1" || return "$?" ;;
esac
```

#### Arguments

* **$1** (string): The unrecognized argument.

#### Exit codes

* **64**: Always, so the caller can return the status.

#### Output on stderr

* A message naming the argument.

### arg::completion::dispatch

Dispatch Tab completion to the target function's completion helper.

Registered with `complete -F` for every function that has a matching
`::_<action>-args` helper. Bash calls this with no arguments and reads
COMP_WORDS and COMP_CWORD. When the previous word is a named argument, the
helper receives it and writes the values for that argument; otherwise it
writes the argument names.

#### Example

```bash
example::run() { :; }
example::_run-args() {
  case "${1:-}" in
    --mode) printf '%s\n' fast safe ;;
    *) printf '%s\n' --mode ;;
  esac
}
complete -F arg::completion::dispatch example::run
```

_Function has no arguments._

#### Variables set

* **COMPREPLY** (The): candidates that start with the current word.

#### Exit codes

* **0**: Always, also when the function has no helper.

### arg::completion::register-all

Register Tab completion for every function that has a completion helper.

Registered automatically when the library is sourced in an interactive shell.
Call again after defining additional completion helpers.

#### Example

```bash
source my-functions.sh
arg::completion::register-all
```

_Function has no arguments._

#### Exit codes

* **0**: The completions were registered, or complete is unavailable.
* **64**: An argument was given.

