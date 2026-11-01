#!/usr/bin/env bash
# @file user
# @brief User and group lookup, account creation, and home directories.
# @description Account creation runs through administrator execution and works on macOS, Ubuntu, and Fedora.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2234,SC2317,SC2319,SC2329

# @description Write the effective user's name.
#
# @noargs
# @stdout The user name.
# @exitcode 0 The name was written.
# @exitcode 64 An argument was given.
# @exitcode 74 id could not report the name.
# @example
#   printf 'Installing for %s\n' "$(user::name)"
user::name() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  id -un 2>/dev/null || return 74
}

# @description Write the effective user's primary group name.
#
# @noargs
# @stdout The group name.
# @exitcode 0 The group was written.
# @exitcode 64 An argument was given.
# @exitcode 74 id could not report the group.
# @example
#   chown "$(user::name):$(user::primary-group)" "${file}"
user::primary-group() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  id -gn 2>/dev/null || return 74
}

# @description Test whether the effective user is root.
#
# @noargs
# @exitcode 0 The effective user ID is 0.
# @exitcode 1 The user is not root.
# @exitcode 64 An argument was given.
# @example
#   user::is-root || printf 'Run this with sudo.\n' >&2
user::is-root() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  [[ "${EUID}" -eq 0 ]]
}

# @description Test whether a local user account exists.
#
# @arg $1 string User name.
# @exitcode 0 The account exists.
# @exitcode 1 No account has that name.
# @exitcode 64 The name is empty, starts with a dash, or contains a newline.
# @example
#   user::exists deploy || user::create-system _deploy
user::exists() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == -* ]] ||
    ! string::_require-one-line "$1"; then
    return 64
  fi
  id -u "$1" >/dev/null 2>&1
}

# @description Validate a system account name and reject an existing account.
# @internal
user::_validate-system-creation() {
  if [[ "$#" -ne 1 ]] || ! ( [[ "$1" =~ ^_[a-z][a-z0-9_-]*$ ]] ); then
    return 64
  fi
  if user::exists "$1"; then
    return 73
  fi
}

# @description Create a non-login system account in a separate root process.
#
# @arg $1 string Account name that starts with an underscore, such as _backup.
# @exitcode 0 The account was created.
# @exitcode 64 The name is not an underscore-prefixed lowercase name.
# @exitcode 73 The account already exists or cannot be created.
# @exitcode other The status of the root helper.
# @example
#   user::create-system-as-root _backup
user::create-system-as-root() {
  user::_validate-system-creation "$@" || return "$?"
  bashstock::_run-as-root create-system-user "$@"
}

# @description Validate login account arguments and require password input through a terminal.
# @internal
user::_validate-login-creation() {
  if [[ "$#" -ne 2 ]] ||
    ! ( [[ "$1" =~ ^[a-z][a-z0-9_-]*$ ]] ) ||
    [[ -z "$2" || "$2" == *:* || "$2" == *[[:cntrl:]]* ]]; then
    return 64
  fi
  if user::exists "$1"; then
    return 73
  fi
  if ! terminal::is-available; then
    console::_write-error 'A controlling terminal is required to set the password.'
    return 66
  fi
}

# @description Create a local login account in a separate root process.
#
# The new password is read from the controlling terminal; a failed password
# entry removes the new account again.
#
# @arg $1 string Account name: a lowercase letter followed by lowercase letters, digits, - or _.
# @arg $2 string Full name; it must not contain : or control characters.
# @exitcode 0 The account was created.
# @exitcode 64 The name or full name is invalid.
# @exitcode 66 No controlling terminal is available for the password.
# @exitcode 73 The account already exists or cannot be created.
# @exitcode other The status of the root helper.
# @example
#   user::create-login-as-root alice 'Alice Example'
user::create-login-as-root() {
  user::_validate-login-creation "$@" || return "$?"
  bashstock::_run-as-root create-login-user "$@"
}

# @description Create a non-login system account.
#
# @arg $1 string Account name that starts with an underscore, such as _backup.
# @exitcode 0 The account was created.
# @exitcode 64 The name is not an underscore-prefixed lowercase name.
# @exitcode 73 The account already exists or cannot be created.
# @exitcode other The status of the root helper.
# @example
#   user::create-system _backup
user::create-system() {
  user::_validate-system-creation "$@" || return "$?"
  bashstock::_run-as-root create-system-user "$@"
}

# @description Create a local login account.
#
# The new password is read from the controlling terminal; a failed password
# entry removes the new account again.
#
# @arg $1 string Account name: a lowercase letter followed by lowercase letters, digits, - or _.
# @arg $2 string Full name; it must not contain : or control characters.
# @exitcode 0 The account was created.
# @exitcode 64 The name or full name is invalid.
# @exitcode 66 No controlling terminal is available for the password.
# @exitcode 73 The account already exists or cannot be created.
# @exitcode other The status of the root helper.
# @example
#   user::create-login alice 'Alice Example'
user::create-login() {
  user::_validate-login-creation "$@" || return "$?"
  bashstock::_run-as-root create-login-user "$@"
}

# @description Add a user to a supplementary group through administrator execution.
#
# @arg $1 string Group name.
# @arg $2 string Optional user name. Defaults to the current user.
# @exitcode 0 The user is in the group; it applies to new login sessions.
# @exitcode 64 The group name is invalid, or the argument count is wrong.
# @exitcode 69 The operating system is unsupported, or usermod or dseditgroup is unavailable.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of usermod or dseditgroup.
# @example
#   user::add-to-group dialout
user::add-to-group() {
  if ( [[ "$#" -lt 1 || "$#" -gt 2 || ! "$1" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] ); then return 64; fi
  local user="${2:-}"
  [[ -n "${user}" ]] || user="$(user::name)" || return "$?"
  case "$(system::operating-system)" in
    darwin) command::require dseditgroup || return "$?"; command::run-as-root dseditgroup -o edit -a "${user}" -t user "$1" ;;
    linux) command::require usermod || return "$?"; command::run-as-root usermod -a -G "$1" "${user}" ;;
    *) return 69 ;;
  esac
}

# @description Link the English XDG user directory names to the directories of the current locale.
#
# Each standard XDG directory is resolved with xdg-user-dir. A localized
# directory that does not exist is skipped and never created. An existing
# English directory is merged into the localized one, overwriting entries
# with the same name, and then replaced by the link.
#
# @arg $1 string Optional home directory to update. Defaults to $HOME.
# @stderr A message for each English name that is not a directory.
# @exitcode 0 Every link was created or already existed.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The home directory does not exist.
# @exitcode 69 xdg-user-dir is unavailable.
# @exitcode 73 An English name is held by something other than a directory or link.
# @exitcode 74 A directory could not be resolved, removed, or linked.
# @exitcode other The status of dir::merge.
# @example
#   user::directory::create-english-links
user::directory::create-english-links() {
  [[ "$#" -le 1 ]] || return 64
  local home="${1:-${HOME}}" pair='' key='' name='' localized='' english='' status=0
  [[ -d "${home}" ]] || return 66
  command::require xdg-user-dir || return "$?"
  for pair in DESKTOP:Desktop DOWNLOAD:Downloads TEMPLATES:Templates PUBLICSHARE:Public \
    DOCUMENTS:Documents MUSIC:Music PICTURES:Pictures VIDEOS:Videos; do
    key="${pair%%:*}"
    name="${pair#*:}"
    localized="$(HOME="${home}" XDG_CONFIG_HOME="${home}/.config" xdg-user-dir "${key}")" || return 74
    english="${home}/${name}"
    [[ -d "${localized}" && ! -L "${localized}" ]] || continue
    [[ "${localized%/}" != "${home%/}" && "${localized}" != "${english}" ]] || continue
    if [[ -L "${english}" ]]; then
      [[ "$(readlink -- "${english}")" != "${localized}" ]] || continue
      rm -f -- "${english}" || return 74
    elif [[ -d "${english}" ]]; then
      dir::merge "${english}" "${localized}" || return "$?"
    elif [[ -e "${english}" ]]; then
      console::_write-error "Not linking ${english}: it is not a directory."
      status=73
      continue
    fi
    ln -s -- "${localized}" "${english}" || return 74
  done
  return "${status}"
}
