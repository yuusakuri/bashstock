# shell

Inspection, startup settings, and interactive prompts of the current shell.

## Overview

Tests return 0 or 1 without output; prompts read from the controlling terminal and write the answer to standard output.

## Index

* [shell::is-function-defined](#shellis-function-defined)
* [shell::editor::set-default](#shelleditorset-default)
* [shell::completion::enable-ignore-case](#shellcompletionenable-ignore-case)
* [shell::zsh::enable-interactive-comments](#shellzshenable-interactive-comments)
* [shell::confirm](#shellconfirm)
* [shell::read-line](#shellread-line)
* [shell::confirm-or-cancel](#shellconfirm-or-cancel)
* [shell::choose-one](#shellchoose-one)
* [shell::wait-for-enter](#shellwait-for-enter)

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

### shell::editor::set-default

Set the default editor of new Bash and Zsh sessions and the current process.

#### Example

```bash
shell::editor::set-default vim bash,zsh
```

#### Arguments

* **$1** (string): Optional editor command. Defaults to code --wait.
* **$2** (string): Optional comma-separated shells, bash and zsh. Defaults to bash.

#### Variables set

* **EDITOR** (is): exported in the current process.

#### Exit codes

* **0**: The editor was set.
* **64**: More than two arguments were given or the shell list is invalid.
* other The status of env::set-variable.

### shell::completion::enable-ignore-case

Make Bash and Zsh completion ignore letter case.

Bash reads the setting from $HOME/.inputrc. A new .inputrc first includes
/etc/inputrc, because Readline stops reading the system file once a
personal one exists. Zsh receives a matcher-list zstyle in $HOME/.zshrc.

#### Example

```bash
shell::completion::enable-ignore-case bash
```

#### Arguments

* **$1** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the shell list is invalid.
* other The status of the file operation that failed.

### shell::zsh::enable-interactive-comments

Allow comments that start with # in interactive Zsh sessions.

setopt interactivecomments is written to ~/.zshrc once.

#### Example

```bash
shell::zsh::enable-interactive-comments
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **74**: ~/.zshrc could not be written.

### shell::confirm

Read and normalize a yes-or-no answer.

The question goes to standard error and the answer is read from standard input.
y and n are accepted as abbreviations, without regard to case.

#### Example

```bash
if [[ "$(shell::confirm 'Remove the cache?' no)" == yes ]]; then
  rm -rf -- "${cache}"
fi
```

#### Arguments

* **$1** (string): Question without newlines.
* **$2** (string): Optional default for an empty answer: yes or no. Without it an empty answer is invalid.

#### Exit codes

* **0**: An answer was written.
* **64**: The answer or the default is invalid.
* **66**: Standard input ended before an answer.

#### Output on stdout

* yes or no.

#### Output on stderr

* The question followed by [yes/no].

### shell::read-line

Read one line and substitute a default only for empty input.

#### Example

```bash
name="$(shell::read-line 'Branch' main)"
```

#### Arguments

* **$1** (string): Prompt without newlines.
* **$2** (string): Value to use when the line is empty.

#### Exit codes

* **0**: A value was written.
* **64**: The prompt contains a newline, or the argument count is not two.
* **66**: Standard input ended before a line.

#### Output on stdout

* The line that was read, or the default.

#### Output on stderr

* The prompt followed by a colon.

### shell::confirm-or-cancel

Read and normalize a yes, no, or cancel answer.

y, n, and c are accepted as abbreviations, without regard to case.

#### Example

```bash
case "$(shell::confirm-or-cancel 'Overwrite settings.json?' cancel)" in
  yes) cp new.json settings.json ;;
  cancel) return 1 ;;
esac
```

#### Arguments

* **$1** (string): Question without newlines.
* **$2** (string): Optional default for an empty answer: yes, no, or cancel.

#### Exit codes

* **0**: An answer was written.
* **64**: The answer or the default is invalid.
* **66**: Standard input ended before an answer.

#### Output on stdout

* yes, no, or cancel.

#### Output on stderr

* The question followed by [yes/no/cancel].

### shell::choose-one

Display indexed choices and write the selected value.

#### Example

```bash
version="$(shell::choose-one 'Node.js version' 20.18.0 22.11.0)"
```

#### Arguments

* **$1** (string): Message shown above the choices.
* **...** (string): Choices without newlines; at least one.

#### Exit codes

* **0**: A choice was written.
* **64**: The selection is not a listed number, or an argument is invalid.
* **66**: Standard input ended before a selection.

#### Output on stdout

* The chosen value.

#### Output on stderr

* The message, the numbered choices, and a Selection: prompt.

### shell::wait-for-enter

Wait for one line from the controlling terminal.

#### Example

```bash
shell::wait-for-enter 'Connect the device, then press Enter.'
```

#### Arguments

* **$1** (string): Optional message. Defaults to "Press Enter to continue.".

#### Exit codes

* **0**: A line was read.
* **64**: More than one argument was given.
* **69**: No controlling terminal is available.
* **74**: The terminal could not be read.

