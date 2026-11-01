# terminal

The controlling terminal and terminal emulator windows.

## Overview

terminal::is-available lets interactive functions fail instead of blocking when no terminal is available.

## Index

* [terminal::is-available](#terminalis-available)
* [terminal::open](#terminalopen)

### terminal::is-available

Test whether the controlling terminal is readable and writable.

#### Example

```bash
terminal::is-available && shell::confirm 'Continue?'
```

_Function has no arguments._

#### Exit codes

* **0**: /dev/tty can be read and written.
* **1**: There is no usable controlling terminal, as in CI or cron.
* **64**: An argument was given.

### terminal::open

Open a new window of the desktop's default terminal application.

macOS uses Terminal. Linux uses the first available of xdg-terminal-exec,
x-terminal-emulator, gnome-terminal, ptyxis, konsole, and xterm, so the
terminal that the desktop or the user selected comes first. Without COMMAND
the window starts the user's login shell. With COMMAND, Bash runs it with its
arguments and then stays open as an interactive shell.

#### Example

```bash
terminal::open
terminal::open make watch
```

#### Arguments

* **...** (string): Optional command and arguments to run in the new window.

#### Exit codes

* **0**: The terminal application opened the window.
* **69**: No supported terminal application is available, or the operating system is unsupported.
* other The status of the terminal application.

