#!/usr/bin/env bash
# @file colima
# @brief Colima installation.
# @description Colima is installed with Homebrew on macOS.

# shellcheck disable=SC2119,SC2120

# @description Write Colima versions available from Homebrew.
#
# @noargs
# @stdout Colima versions from Homebrew, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of brew.
# @example
#   colima::versions
colima::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_versions colima
}

# @description Install Colima with Homebrew on macOS and start it.
#
# Colima's Docker runtime needs the docker command before it starts, so the
# Docker CLI formula is installed with it. Without Hypervisor.framework, as in
# a virtual machine without nested virtualization, the VM cannot boot, so the
# function returns 69 instead of starting it.
#
# @arg $1 string Optional Colima version; only the current Homebrew version is accepted.
# @stderr A message when Hypervisor.framework is unavailable.
# @exitcode 0 Colima is installed and running.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The system is not macOS, the version is not the current one, or Hypervisor.framework is unavailable.
# @exitcode other The status of brew or colima start.
# @example
#   colima::install
#   docker::install
colima::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_install-version colima "${1:-}" || return "$?"
  package::_install docker || return "$?"
  if colima status >/dev/null 2>&1; then
    return 0
  fi
  if [[ "$(sysctl -n kern.hv_support 2>/dev/null)" != 1 ]]; then
    console::_write-error 'Colima needs Hypervisor.framework, which this Mac does not provide.'
    return 69
  fi
  colima start
}
