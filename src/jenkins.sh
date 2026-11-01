#!/usr/bin/env bash
# @file jenkins
# @brief Jenkins service control.
# @description The service is controlled through administrator execution.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Restart the Jenkins service through administrator execution.
#
# @noargs
# @exitcode 0 Jenkins was restarted.
# @exitcode 64 An argument was given.
# @exitcode other The status of systemd::restart.
# @example
#   jenkins::restart
jenkins::restart() {
  [[ "$#" -eq 0 ]] || return 64
  systemd::restart jenkins.service
}
