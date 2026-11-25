# systemd

systemd units, services, and logs.

## Overview

Functions wrap systemctl and journalctl.

## Index

* [systemd__file](#systemd__file)
* [systemd__dependencies](#systemd__dependencies)
* [systemd__restart](#systemd__restart)
* [systemd__start](#systemd__start)
* [systemd__stop](#systemd__stop)
* [systemd__enable](#systemd__enable)
* [systemd__disable](#systemd__disable)
* [systemd__status](#systemd__status)
* [systemd__service__list](#systemd__service__list)
* [systemd__service__list-running](#systemd__service__list-running)
* [systemd__service__list-failed](#systemd__service__list-failed)
* [systemd__service__list-files](#systemd__service__list-files)

### systemd__file

Write the path of the file that defines a systemd unit.

#### Example

```bash
systemd__file ssh.service
```

#### Arguments

* **$1** (string): Unit name, such as ssh.service.

#### Exit codes

* **0**: The path was written.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The path of the unit file; empty for a unit without a file.

### systemd__dependencies

Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines.

#### Example

```bash
systemd__dependencies docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The dependencies were written.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* After=, Requires=, and Wants= lines.

### systemd__restart

Restart a systemd unit through administrator execution.

#### Example

```bash
systemd__restart nginx.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was restarted.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd__start

Start a systemd unit through administrator execution.

#### Example

```bash
systemd__start docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was started.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd__stop

Stop a systemd unit through administrator execution.

#### Example

```bash
systemd__stop docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was stopped.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd__enable

Enable a systemd unit at boot through administrator execution.

#### Example

```bash
systemd__enable ssh.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was enabled.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd__disable

Disable a systemd unit at boot through administrator execution.

#### Example

```bash
systemd__disable cups.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was disabled.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd__status

Write the current state of a systemd unit and return the status of systemctl status.

#### Example

```bash
systemd__status ssh.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit is active.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl status, such as **3**: for an inactive unit.

#### Output on stdout

* The output of systemctl status.

### systemd__service__list

Write every loaded systemd service, including stopped ones.

#### Example

```bash
systemd__service__list
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The output of systemctl list-units --type=service.

### systemd__service__list-running

Write the running systemd services.

#### Example

```bash
systemd__service__list-running
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The running services.

### systemd__service__list-failed

Write the failed systemd services.

#### Example

```bash
systemd__service__list-failed
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The failed services.

### systemd__service__list-files

Write every systemd service unit file and its enablement state.

#### Example

```bash
systemd__service__list-files | grep enabled
```

_Function has no arguments._

#### Exit codes

* **0**: The files were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The service unit files and their states.

