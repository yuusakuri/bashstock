# jfrog

JFrog CLI installation and configuration.

## Overview

Server configurations are managed with jf config.

## Index

* [jfrog::config::clear](#jfrogconfigclear)
* [jfrog::config::clear-all](#jfrogconfigclear-all)
* [jfrog::config::list](#jfrogconfiglist)
* [jfrog::setup](#jfrogsetup)

### jfrog::config::clear

Remove one JFrog CLI server configuration.

#### Example

```bash
jfrog::config::clear artifactory-prod
```

#### Arguments

* **$1** (string): Server ID.

#### Exit codes

* **0**: The configuration was removed.
* **64**: The argument count is not one.
* **69**: jf is unavailable.
* other The status of jf config remove.

### jfrog::config::clear-all

Remove every JFrog CLI server configuration.

#### Example

```bash
jfrog::config::clear-all
```

_Function has no arguments._

#### Exit codes

* **0**: Every configuration was removed.
* **64**: An argument was given.
* **69**: jf is unavailable.
* other The status of jf config clean.

### jfrog::config::list

Display JFrog CLI server configurations.

#### Example

```bash
jfrog::config::list
```

_Function has no arguments._

#### Exit codes

* **0**: The configurations were written.
* **64**: An argument was given.
* **69**: jf is unavailable.
* other The status of jf config show.

#### Output on stdout

* The output of jf config show.

### jfrog::setup

Register and verify a JFrog CLI server.

The access token is read from JFROG_ACCESS_TOKEN and passed to jf on standard input, never as an argument.

#### Example

```bash
JFROG_ACCESS_TOKEN="$(pass show jfrog/token)" jfrog::setup prod https://example.jfrog.io builder
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

