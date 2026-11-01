#!/usr/bin/env bash
# @file pass
# @brief pass installation and password stores.
# @description Stores are initialized for a GPG key.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Remove a pass store and everything in it.
#
# @arg $1 string Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.
# @exitcode 0 The store was removed.
# @exitcode 64 More than one argument was given, or the directory is / or a symbolic link.
# @exitcode 66 The store does not exist.
# @exitcode 74 The store could not be removed.
# @example
#   pass::store::remove "${HOME}/.password-store-old"
pass::store::remove() {
  [[ "$#" -le 1 ]] || return 64
  local directory=''
  directory="$(pass::store::_directory "$@")" || return "$?"
  [[ -n "${directory}" && "${directory}" != / && ! -L "${directory}" ]] || return 64
  [[ -d "${directory}" ]] || return 66
  rm -rf -- "${directory}" || return 74
}

# @description Write the pass store directory: the argument, PASSWORD_STORE_DIR, or $HOME/.password-store.
# @internal
pass::store::_directory() {
  [[ "$#" -le 1 ]] || return 64
  printf '%s\n' "${1:-${PASSWORD_STORE_DIR:-${HOME}/.password-store}}"
}

# @description Initialize a pass store for a GPG key without removing an existing store.
#
# @arg $1 string Optional GPG key fingerprint. Defaults to the first secret key.
# @arg $2 string Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.
# @exitcode 0 The store was initialized.
# @exitcode 1 No fingerprint was given and no secret key exists.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 pass is unavailable.
# @exitcode other The status of pass init.
# @example
#   pass::store::init "$(gpg::secret-key::fingerprints | head -n 1)"
pass::store::init() {
  [[ "$#" -le 2 ]] || return 64
  local fingerprint="${1:-}" directory='' fingerprints=''
  command::require pass || return "$?"
  directory="$(pass::store::_directory "${2:-}")" || return "$?"
  if [[ -z "${fingerprint}" ]]; then
    fingerprints="$(gpg::secret-key::fingerprints)" || return "$?"
    fingerprint="${fingerprints%%$'\n'*}"
  fi
  PASSWORD_STORE_DIR="${directory}" pass init "${fingerprint}"
}

# @description Write pass versions available to the current platform.
#
# @noargs
# @stdout pass versions from the platform package manager, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   pass::versions
pass::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions pass
}

# @description Install pass from the platform package manager.
#
# @arg $1 string Optional version from pass::versions. Defaults to the newest one.
# @exitcode 0 pass is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   pass::install
#   pass init "$(gpg::secret-key::fingerprints | head -n 1)"
pass::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version pass "${1:-}"
}
