# completion

Tab completion of named arguments for public functions.

## Overview

A public function NAME is completed by the helper NAME-args with its last :: segment prefixed by an underscore.

## Index

* [arg::completion::dispatch](#argcompletiondispatch)
* [arg::completion::register-all](#argcompletionregister-all)

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

