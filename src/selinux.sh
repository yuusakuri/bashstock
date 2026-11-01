#!/usr/bin/env bash
# @file selinux
# @brief SELinux rule generation.
# @description Rules are generated from audit log denials with audit2allow.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Generate SELinux allow rules from the AVC denials of an audit log.
#
# @arg $1 string Audit log, such as /var/log/audit/audit.log.
# @arg $2 string Optional rule file. Defaults to selinux.txt next to the audit log.
# @stderr A message when the log has no AVC denial.
# @exitcode 0 The rules were written.
# @exitcode 1 The log has no AVC denial.
# @exitcode 64 The arguments are invalid or the log does not exist.
# @exitcode 69 audit2allow is unavailable.
# @exitcode other The status of audit2allow.
# @example
#   selinux::generate-rule /var/log/audit/audit.log ./allow.te
selinux::generate-rule() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  local output="${2:-$(path::directory-name "$1")/selinux.txt}" denials=''
  command::require audit2allow || return "$?"
  denials="$(grep -F 'avc:' -- "$1")" || {
    console::_write-error "No AVC denial in $1."
    return 1
  }
  printf '%s\n' "${denials}" | audit2allow >"${output}"
}
