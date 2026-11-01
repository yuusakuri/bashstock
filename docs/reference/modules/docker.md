# docker

Docker installation, containers, and volumes.

## Overview

Container functions wrap one docker command each and return 69 when docker is unavailable.

## Index

* [docker::container::list-running](#dockercontainerlist-running)
* [docker::container::list](#dockercontainerlist)
* [docker::container::pull](#dockercontainerpull)
* [docker::container::push](#dockercontainerpush)
* [docker::container::shell](#dockercontainershell)
* [docker::container::logs](#dockercontainerlogs)
* [docker::container::stop](#dockercontainerstop)
* [docker::container::start](#dockercontainerstart)
* [docker::container::stop-all](#dockercontainerstop-all)
* [docker::container::remove-all](#dockercontainerremove-all)
* [docker::volume::remove-all](#dockervolumeremove-all)
* [docker::remove-all](#dockerremove-all)
* [docker::login-artifactory](#dockerlogin-artifactory)
* [docker::versions](#dockerversions)
* [docker::install](#dockerinstall)

### docker::container::list-running

List running Docker containers.

#### Example

```bash
docker::container::list-running
```

_Function has no arguments._

#### Exit codes

* **0**: The containers were written.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of docker ps.

#### Output on stdout

* The output of docker ps.

### docker::container::list

List Docker containers.

#### Example

```bash
docker::container::list
```

_Function has no arguments._

#### Exit codes

* **0**: The containers were written.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of docker ps.

#### Output on stdout

* The output of docker ps -a.

### docker::container::pull

Copy files between a Docker container and the host.

#### Example

```bash
docker::container::pull web /var/log/nginx ./logs
```

#### Arguments

* **$1** (string): Container name or ID.
* **$2** (string): Path in the container.
* **$3** (string): Optional host destination. Defaults to the current directory.

#### Exit codes

* **0**: The files were copied.
* **64**: The argument count is not two or three.
* **69**: docker is unavailable.
* other The status of docker cp.

### docker::container::push

Copy a host path into a container.

#### Example

```bash
docker::container::push web ./nginx.conf /etc/nginx/nginx.conf
```

#### Arguments

* **$1** (string): Container name or ID.
* **$2** (string): Path on the host.
* **$3** (string): Optional destination in the container. Defaults to its working directory.

#### Exit codes

* **0**: The files were copied.
* **64**: The argument count is not two or three.
* **69**: docker is unavailable.
* other The status of docker cp.

### docker::container::shell

Run an interactive shell or a command in a container.

Without COMMAND, Bash is used when the container has it and sh otherwise,
with a terminal attached. A COMMAND receives standard input without a
terminal, so it also works from scripts and CI.

#### Example

```bash
docker::container::shell web
docker::container::shell web nginx -t
```

#### Arguments

* **$1** (string): Container name or ID.
* **...** (string): Optional command and its arguments.

#### Exit codes

* **0**: The shell or command exited successfully.
* **64**: No container was given.
* **69**: docker is unavailable.
* other The status of docker exec.

### docker::container::logs

Follow the log of a container.

#### Example

```bash
docker::container::logs web
```

#### Arguments

* **$1** (string): Container name or ID.

#### Exit codes

* **0**: docker logs ended successfully.
* **64**: The argument count is not one.
* **69**: docker is unavailable.
* other The status of docker logs.

#### Output on stdout

* The container log, followed until interrupted.

### docker::container::stop

Stop a container.

#### Example

```bash
docker::container::stop web
```

#### Arguments

* **$1** (string): Container name or ID.

#### Exit codes

* **0**: The container stopped.
* **64**: The argument count is not one.
* **69**: docker is unavailable.
* other The status of docker stop.

### docker::container::start

Start a container.

#### Example

```bash
docker::container::start web
```

#### Arguments

* **$1** (string): Container name or ID.

#### Exit codes

* **0**: The container started.
* **64**: The argument count is not one.
* **69**: docker is unavailable.
* other The status of docker start.

### docker::container::stop-all

Stop every running container; having none is a success.

#### Example

```bash
docker::container::stop-all
```

_Function has no arguments._

#### Exit codes

* **0**: No container is running.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::container::remove-all

Remove every container, running or not.

#### Example

```bash
docker::container::remove-all
```

_Function has no arguments._

#### Exit codes

* **0**: No container remains.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::volume::remove-all

Remove every Docker volume.

#### Example

```bash
docker::volume::remove-all
```

_Function has no arguments._

#### Exit codes

* **0**: No volume remains.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::remove-all

Remove every container and then every volume, stopping at the first failure.

#### Example

```bash
docker::remove-all
```

_Function has no arguments._

#### Exit codes

* **0**: No container or volume remains.
* **64**: An argument was given.
* **69**: docker is unavailable.
* other The status of the docker command that failed.

### docker::login-artifactory

Log in to an Artifactory Docker registry using a token on standard input.

The token is passed to docker on standard input, never as an argument.

#### Example

```bash
docker::login-artifactory example.jfrog.io builder "$(pass show jfrog/token)"
```

#### Arguments

* **$1** (string): Registry host.
* **$2** (string): User name.
* **$3** (string): Access token.

#### Exit codes

* **0**: The login succeeded.
* **64**: The argument count is not three or an argument is empty.
* **69**: docker is unavailable.
* other The status of docker login.

### docker::versions

Write Docker Engine or Docker CLI versions available to the current platform.

#### Example

```bash
docker::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported, or Docker publishes nothing for this release.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Docker Engine versions on Linux, or Docker CLI versions from Homebrew on macOS, one per line.

### docker::install

Install the Docker CLI, and Docker Engine on Linux.

On macOS, Colima or Rancher Desktop must already be installed and running.
On Ubuntu and Fedora, the official Docker repository is registered and the
docker service is enabled and started. Conflicting packages such as
docker.io are removed only after the repository is ready, and are installed
again when Docker cannot be installed.

#### Example

```bash
docker::install
docker run --rm hello-world
```

#### Arguments

* **$1** (string): Optional version from docker::versions. Defaults to the newest stable version.

#### Exit codes

* **0**: Docker is installed, and on Linux the service is enabled and running.
* **64**: The argument count is wrong.
* **69**: The platform or version is unsupported, or on macOS neither Colima nor Rancher Desktop is running.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager or systemctl.

#### Output on stderr

* A message on macOS when no container runtime is running.

