# env

Environment variables, PATH entries, and dotenv files.

## Overview

Persistent settings are written once to the startup files of each shell.

## Index

* [env::dotenv::import](#envdotenvimport)
* [env::set-variable](#envset-variable)
* [env::add-path](#envadd-path)
* [env::dotenv::register](#envdotenvregister)

### env::dotenv::import

Import the variables of a dotenv file into the current process.

The file is parsed as data and never executed. Every line is validated
before any variable changes; see env::dotenv::_entries for the syntax.

#### Example

```bash
env::dotenv::import .env && printf '%s\n' "${DATABASE_URL}"
```

#### Arguments

* **$1** (string): Regular dotenv file. A symbolic link is refused.

#### Variables set

* **Each** (variable): of the file is set and exported.

#### Exit codes

* **0**: The variables were imported.
* **64**: The argument is not one regular file.
* **65**: A line is not valid dotenv syntax, or a variable is readonly; no variable changes.
* **74**: A variable could not be set or exported.
* other The status of the parser.

### env::set-variable

Set an environment variable for the current shell.

The export line is written to the startup file of each shell, replacing an earlier export of the same name.

#### Example

```bash
env::set-variable EDITOR vim bash
```

#### Arguments

* **$1** (string): Variable name.
* **$2** (string): Value.
* **$3** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Variables set

* **The** (variable): is exported in the current shell.

#### Exit codes

* **0**: The variable was set and saved.
* **64**: The name or the shell list is invalid.
* other The status of the file operation that failed.

### env::add-path

Add a directory to PATH without creating duplicates.

A line that adds the directory once is written to the startup file of each shell.

#### Example

```bash
env::add-path "${HOME}/.local/bin"
```

#### Arguments

* **$1** (string): Existing directory.
* **$2** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Variables set

* **PATH** (gains): the directory in the current shell when it is missing.

#### Exit codes

* **0**: PATH was updated and saved.
* **64**: The directory does not exist or the shell list is invalid.
* other The status of the file operation that failed.

### env::dotenv::register

Load a dotenv file in every new Bash and Zsh session.

Bash startup files load BashStock and call env::dotenv::import. Zsh cannot
load a Bash library, so its startup file asks Bash for the parsed values
and evaluates the resulting export commands. Each startup file receives the
line once, and the file is always read as data.

#### Example

```bash
env::dotenv::register "${HOME}/.config/app/.env" zsh
```

#### Arguments

* **$1** (string): Regular dotenv file. A relative path is stored as an absolute path.
* **$2** (string): Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.

#### Exit codes

* **0**: The startup files load the file.
* **64**: The file is not a regular file or the shell list is invalid.
* other The status of the file operation that failed.

