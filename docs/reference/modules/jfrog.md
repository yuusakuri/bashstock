# jfrog

JFrog CLI installation and configuration.

## Overview

Server configurations are managed with jf config.

## Index

* [jfrog__config__clear](#jfrog__config__clear)
* [jfrog__config__clear-all](#jfrog__config__clear-all)
* [jfrog__config__list](#jfrog__config__list)
* [jfrog__setup](#jfrog__setup)

### jfrog__config__clear

Remove one JFrog CLI server configuration.

#### Example

```bash
jfrog__config__clear artifactory-prod
```

#### Arguments

* **$1** (string): Server ID.

#### Exit codes

* **0**: The configuration was removed.
* **64**: The argument count is not one.
* **69**: jf is unavailable.
* other The status of jf config remove.

### jfrog__config__clear-all

Remove every JFrog CLI server configuration.

#### Example

```bash
jfrog__config__clear-all
```

_Function has no arguments._

#### Exit codes

* **0**: Every configuration was removed.
* **64**: An argument was given.
* **69**: jf is unavailable.
* other The status of jf config clean.

### jfrog__config__list

Display JFrog CLI server configurations.

#### Example

```bash
jfrog__config__list
```

_Function has no arguments._

#### Exit codes

* **0**: The configurations were written.
* **64**: An argument was given.
* **69**: jf is unavailable.
* other The status of jf config show.

#### Output on stdout

* The output of jf config show.

### jfrog__setup

Register and verify a JFrog CLI server.

The access token is read from JFROG_ACCESS_TOKEN and passed to jf on standard input, never as an argument.

#### Example

```bash
JFROG_ACCESS_TOKEN="$(pass show jfrog/token)" jfrog__setup prod https://example.jfrog.io builder
```

#### Arguments

* **$1** (string): Server ID.
* **$2** (string): Platform URL, such as https://example.jfrog.io.
* **$3** (string): User name.

#### Exit codes

* **0**: The server was registered and answered ping.
* **64**: An argument is empty or JFROG_ACCESS_TOKEN is unset.
* **69**: jf is unavailable.
* other The status of jf config add or jf rt ping.

