# prompt

Interactive questions on the controlling terminal.

## Overview

Questions read from the controlling terminal and write the answer to standard output.

## Index

* [prompt::confirm](#promptconfirm)
* [prompt::read-line-with-default](#promptread-line-with-default)
* [prompt::confirm-or-cancel](#promptconfirm-or-cancel)
* [prompt::select-one](#promptselect-one)

### prompt::confirm

Read and normalize a yes-or-no answer.

The question goes to standard error and the answer is read from standard input.
y and n are accepted as abbreviations, without regard to case.

#### Example

```bash
if [[ "$(prompt::confirm 'Remove the cache?' no)" == yes ]]; then
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

### prompt::read-line-with-default

Read one line and substitute a default only for empty input.

#### Example

```bash
name="$(prompt::read-line-with-default 'Branch' main)"
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

### prompt::confirm-or-cancel

Read and normalize a yes, no, or cancel answer.

y, n, and c are accepted as abbreviations, without regard to case.

#### Example

```bash
case "$(prompt::confirm-or-cancel 'Overwrite settings.json?' cancel)" in
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

### prompt::select-one

Display indexed choices and write the selected value.

#### Example

```bash
version="$(prompt::select-one 'Node.js version' 20.18.0 22.11.0)"
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

