#!/usr/bin/env bash
# @file sudo
# @brief sudo credentials and passwordless rules.
# @description Rules are written as sudoers drop-in files after validation with visudo.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Keep the sudo credentials of the calling process fresh in the background.
#
# sudo is authenticated once, and a background process renews the
# credentials every 60 seconds until the calling process exits.
#
# @noargs
# @exitcode 0 The credentials are fresh and the renewal runs in the background.
# @exitcode 64 An argument was given.
# @exitcode 69 sudo is unavailable.
# @exitcode 77 sudo authentication failed.
# @example
#   sudo::start-keep-alive && go::install && rust::install
sudo::start-keep-alive() {
  [[ "$#" -eq 0 ]] || return 64
  command::require sudo || return "$?"
  local parent="$$"
  sudo -v || return 77
  (
    while kill -0 "${parent}" 2>/dev/null; do
      sleep 60
      sudo -n -v 2>/dev/null || exit 0
    done
  ) >/dev/null 2>&1 &
}

# @description Write the named user, or the user who invoked sudo, or the current user.
# @internal
sudo::passwordless::_user() {
  [[ "$#" -le 1 ]] || return 64
  local user="${1:-${SUDO_USER:-}}"
  if [[ -z "${user}" ]]; then
    user="$(user::name)" || return "$?"
  fi
  ( [[ "${user}" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]] ) || return 64
  printf '%s\n' "${user}"
}

# @description Write the drop-in file that holds the passwordless sudo rule of a user.
# @internal
sudo::passwordless::_file() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  # sudo skips drop-in files whose names contain a dot. Writing _ as __ and
  # . as _- keeps the names of first.last and first_last apart.
  local name="${1//_/__}"
  name="${name//./_-}"
  printf '/etc/sudoers.d/zz-bashstock-passwordless-%s\n' "${name}"
}

# @description Let a user run every command through sudo without entering a password.
#
# The rule `USER ALL=(ALL) NOPASSWD: ALL` is written to its own file in
# /etc/sudoers.d without opening an editor. visudo checks the rule before it
# is installed and the whole configuration afterwards. sudo applies the last
# matching rule, so the file name sorts after other drop-in files, and the
# main sudoers file of macOS, Ubuntu, and Fedora reads the directory after
# its group rules. If sudo still asks the user for a password, the file is
# removed and the function fails. Running it again rewrites the same file.
#
# @arg $1 string Optional login name. Defaults to the user who invoked sudo, or the current user.
# @stderr A message when the user does not exist or sudo does not apply the rule.
# @exitcode 0 The user can run sudo without a password.
# @exitcode 64 More than one argument was given or the user does not exist.
# @exitcode 69 sudo still asks for a password; the file was removed.
# @exitcode 74 The rule could not be written, checked, or installed.
# @exitcode other The status of the user lookup.
# @example
#   sudo::passwordless::enable "$(id -un)"
sudo::passwordless::enable() {
  [[ "$#" -le 1 ]] || return 64
  local user='' file='' directory='' status=0
  user="$(sudo::passwordless::_user "$@")" || return "$?"
  if ! user::exists "${user}"; then
    console::_write-error "User does not exist: ${user}"
    return 64
  fi
  file="$(sudo::passwordless::_file "${user}")"
  directory="$(mktemp -d "${TMPDIR:-/tmp}/bashstock-sudoers.XXXXXX")" || return 74
  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "${user}" >"${directory}/rule" || status=74
  if [[ "${status}" -eq 0 ]] && ! command::run-as-root visudo -c -q -f "${directory}/rule"; then
    status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /etc/sudoers.d || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0440 "${directory}/rule" "${file}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  # -k ignores the user's cached credentials, so only the rule can let sudo through.
  if ! command::run-as-root visudo -c -q ||
    ! command::run-as-root sudo -n -u "${user}" -- sudo -n -k true 2>/dev/null; then
    command::run-as-root rm -f -- "${file}"
    console::_write-error "sudo does not apply ${file}; the file was removed."
    return 69
  fi
}

# @description Remove the passwordless sudo rule that sudo::passwordless::enable added.
#
# Only the BashStock drop-in file of the user is removed, so sudo asks for
# the password again unless another sudoers rule also grants NOPASSWD. The
# function succeeds when the file does not exist.
#
# @arg $1 string Optional login name. Defaults to the user who invoked sudo, or the current user.
# @exitcode 0 The rule file does not exist.
# @exitcode 64 More than one argument was given.
# @exitcode 74 The file could not be removed.
# @exitcode other The status of the user lookup.
# @example
#   sudo::passwordless::disable
sudo::passwordless::disable() {
  [[ "$#" -le 1 ]] || return 64
  local user='' file=''
  user="$(sudo::passwordless::_user "$@")" || return "$?"
  file="$(sudo::passwordless::_file "${user}")" || return "$?"
  # /etc/sudoers.d is often unreadable to other users, so remove the file as root.
  command::run-as-root rm -f -- "${file}" || return 74
}
