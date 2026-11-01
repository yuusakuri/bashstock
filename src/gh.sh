#!/usr/bin/env bash
# @file gh
# @brief GitHub CLI installation.
# @description gh is installed from GitHub's official package source.

# shellcheck disable=SC2119,SC2120

# @description Register GitHub CLI's official Ubuntu APT repository after checking its key.
# @internal
gh::_register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  command::require gpg || return "$?"
  local directory='' status=0 fingerprints='' architecture=''
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "${directory}/githubcli-archive-keyring.gpg" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    mkdir -m 0700 -- "${directory}/gnupg" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    GNUPGHOME="${directory}/gnupg" gpg --batch --with-colons --show-keys \
      "${directory}/githubcli-archive-keyring.gpg" >"${directory}/key-info" 2>/dev/null || status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    fingerprints="$(awk -F: '$1 == "pub" { primary = 1; next } primary && $1 == "fpr" { print $10; primary = 0 }' \
      "${directory}/key-info")" || status=65
  fi
  if [[ "${status}" -eq 0 && "${fingerprints}" != $'2C6106201985B60E6C7AC87323F3D4EA75716059\n7F38BBB59D064DBCB3D84D725612B36462313325' ]]; then
    console::_write-error "The GitHub CLI repository key does not match GitHub's published fingerprints."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /etc/apt/keyrings || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0644 "${directory}/githubcli-archive-keyring.gpg" \
      /etc/apt/keyrings/githubcli-archive-keyring.gpg || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  architecture="$(package::_deb-architecture)" || return "$?"
  file::write-text /etc/apt/sources.list.d/github-cli.sources \
    $'Types: deb\nURIs: https://cli.github.com/packages\nSuites: stable\nComponents: main\nArchitectures: '"${architecture}"$'\nSigned-By: /etc/apt/keyrings/githubcli-archive-keyring.gpg\n' || return "$?"
  package::_refresh
}

# @description Install GitHub CLI from its official Ubuntu APT repository.
#
# The downloaded keyring must contain both fingerprints published by GitHub.
# The keyring is installed in /etc/apt/keyrings and referenced from a deb822
# source file before APT indexes are refreshed and gh is installed.
#
# @noargs
# @exitcode 0 GitHub CLI is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key does not match GitHub's fingerprints.
# @exitcode 69 The system is not Ubuntu, or gpg is missing.
# @exitcode 74 The key download or repository configuration failed.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of APT.
# @example
#   gh::install
gh::install() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  gh::_register-repository || return "$?"
  package::_install gh
}
