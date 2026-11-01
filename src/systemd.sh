#!/usr/bin/env bash
# @file systemd
# @brief systemd units, services, and logs.
# @description Functions wrap systemctl and journalctl.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the path of the file that defines a systemd unit.
#
# @arg $1 string Unit name, such as ssh.service.
# @stdout The path of the unit file; empty for a unit without a file.
# @exitcode 0 The path was written.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::file ssh.service
systemd::file() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  systemctl show --property=FragmentPath --value -- "$1"
}

# @description Require Linux with systemctl and a valid unit name.
# @internal
systemd::_require-unit() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9@._:\\-]+$ ]] ) || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require systemctl
}

# @description Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines.
#
# @arg $1 string Unit name.
# @stdout After=, Requires=, and Wants= lines.
# @exitcode 0 The dependencies were written.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::dependencies docker.service
systemd::dependencies() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  systemctl show --property=After --property=Requires --property=Wants -- "$1"
}

# @description Restart a systemd unit through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was restarted.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::restart nginx.service
systemd::restart() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl restart -- "$1"
}

# @description Start a systemd unit through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was started.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::start docker.service
systemd::start() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl start -- "$1"
}

# @description Stop a systemd unit through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was stopped.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::stop docker.service
systemd::stop() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl stop -- "$1"
}

# @description Enable a systemd unit at boot through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was enabled.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::enable ssh.service
systemd::enable() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl enable -- "$1"
}

# @description Disable a systemd unit at boot through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was disabled.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::disable cups.service
systemd::disable() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl disable -- "$1"
}

# @description Write the current state of a systemd unit and return the status of systemctl status.
#
# @arg $1 string Unit name.
# @stdout The output of systemctl status.
# @exitcode 0 The unit is active.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl status, such as 3 for an inactive unit.
# @example
#   systemd::status ssh.service
systemd::status() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  systemctl status --no-pager -- "$1"
}

# @description Write every loaded systemd service, including stopped ones.
#
# @noargs
# @stdout The output of systemctl list-units --type=service.
# @exitcode 0 The services were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list
systemd::service::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command systemctl list-units --type=service; }

# @description Write the running systemd services.
#
# @noargs
# @stdout The running services.
# @exitcode 0 The services were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list-running
systemd::service::list-running() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command systemctl list-units --type=service --state=running; }

# @description Write the failed systemd services.
#
# @noargs
# @stdout The failed services.
# @exitcode 0 The services were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list-failed
systemd::service::list-failed() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command systemctl list-units --type=service --state=failed; }

# @description Write every systemd service unit file and its enablement state.
#
# @noargs
# @stdout The service unit files and their states.
# @exitcode 0 The files were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list-files | grep enabled
systemd::service::list-files() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command systemctl list-unit-files --type=service; }
