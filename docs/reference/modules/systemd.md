# systemd

systemd units, services, and logs.

## Overview

Functions wrap systemctl and journalctl.

## Index

* [systemd::file](#systemdfile)
* [systemd::dependencies](#systemddependencies)
* [systemd::restart](#systemdrestart)
* [systemd::start](#systemdstart)
* [systemd::stop](#systemdstop)
* [systemd::enable](#systemdenable)
* [systemd::disable](#systemddisable)
* [systemd::status](#systemdstatus)
* [systemd::service::list](#systemdservicelist)
* [systemd::service::list-running](#systemdservicelist-running)
* [systemd::service::list-failed](#systemdservicelist-failed)
* [systemd::service::list-files](#systemdservicelist-files)

### systemd::file

Write the path of the file that defines a systemd unit.

#### Example

```bash
systemd::file ssh.service
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

### systemd::dependencies

Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines.

#### Example

```bash
systemd::dependencies docker.service
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

### systemd::restart

Restart a systemd unit through administrator execution.

#### Example

```bash
systemd::restart nginx.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was restarted.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::start

Start a systemd unit through administrator execution.

#### Example

```bash
systemd::start docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was started.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::stop

Stop a systemd unit through administrator execution.

#### Example

```bash
systemd::stop docker.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was stopped.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::enable

Enable a systemd unit at boot through administrator execution.

#### Example

```bash
systemd::enable ssh.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was enabled.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::disable

Disable a systemd unit at boot through administrator execution.

#### Example

```bash
systemd::disable cups.service
```

#### Arguments

* **$1** (string): Unit name.

#### Exit codes

* **0**: The unit was disabled.
* **64**: The argument is not one valid unit name.
* **69**: The system is not Linux or systemctl is unavailable.
* other The status of systemctl.

### systemd::status

Write the current state of a systemd unit and return the status of systemctl status.

#### Example

```bash
systemd::status ssh.service
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

### systemd::service::list

Write every loaded systemd service, including stopped ones.

#### Example

```bash
systemd::service::list
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The output of systemctl list-units --type=service.

### systemd::service::list-running

Write the running systemd services.

#### Example

```bash
systemd::service::list-running
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The running services.

### systemd::service::list-failed

Write the failed systemd services.

#### Example

```bash
systemd::service::list-failed
```

_Function has no arguments._

#### Exit codes

* **0**: The services were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The failed services.

### systemd::service::list-files

Write every systemd service unit file and its enablement state.

#### Example

```bash
systemd::service::list-files | grep enabled
```

_Function has no arguments._

#### Exit codes

* **0**: The files were written.
* **64**: An argument was given.
* **69**: systemctl is unavailable.
* other The status of systemctl.

#### Output on stdout

* The service unit files and their states.

