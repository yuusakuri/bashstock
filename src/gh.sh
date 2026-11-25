#!/usr/bin/env bash
# @file gh
# @brief GitHub CLI installation.
# @description gh is installed from GitHub's official package source.

# shellcheck disable=SC2119,SC2120

# @description Register GitHub CLI's official APT or DNF repository after checking its key.
# @internal
_gh__register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  command__require gpg || return "$?"
  local platform='' key_url='' keyring='' directory='' status=0 fingerprints='' architecture=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      key_url=https://cli.github.com/packages/githubcli-archive-keyring.gpg
      keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
      ;;
    fedora)
      key_url=https://cli.github.com/packages/githubcli-archive-keyring.asc
      keyring=/etc/pki/rpm-gpg/RPM-GPG-KEY-gh-cli
      ;;
    *) return 69 ;;
  esac
  directory="$(_package__temporary-directory)" || return "$?"
  _package__download "${key_url}" "${directory}/key" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    mkdir -m 0700 -- "${directory}/gnupg" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    # GnuPG 2.2.4 on Ubuntu 18.04 predates --show-keys, so list the keys with show-only.
    GNUPGHOME="${directory}/gnupg" gpg --batch --with-colons --import-options show-only --import \
      "${directory}/key" >"${directory}/key-info" 2>/dev/null || status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    fingerprints="$(awk -F: '$1 == "pub" { primary = 1; next } primary && $1 == "fpr" { print $10; primary = 0 }' \
      "${directory}/key-info")" || status=65
  fi
  if [[ "${status}" -eq 0 && "${fingerprints}" != $'2C6106201985B60E6C7AC87323F3D4EA75716059\n7F38BBB59D064DBCB3D84D725612B36462313325' ]]; then
    _console__write-error "The GitHub CLI repository key does not match GitHub's published fingerprints."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -d -m 0755 "${keyring%/*}" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -m 0644 "${directory}/key" "${keyring}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  if [[ "${platform}" == ubuntu ]]; then
    architecture="$(_package__deb-architecture)" || return "$?"
    file__write-text /etc/apt/sources.list.d/github-cli.sources \
      $'Types: deb\nURIs: https://cli.github.com/packages\nSuites: stable\nComponents: main\nArchitectures: '"${architecture}"$'\nSigned-By: '"${keyring}"$'\n' || return "$?"
    _package__refresh
  else
    _package__dnf-register-repository gh-cli "[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=file://${keyring}
"
  fi
}

# @description Install GitHub CLI from its official Ubuntu APT or Fedora DNF repository.
#
# The downloaded key must contain both fingerprints published by GitHub. It is
# installed in /etc/apt/keyrings on Ubuntu or /etc/pki/rpm-gpg on Fedora and
# referenced from the repository definition before gh is installed.
#
# @noargs
# @exitcode 0 GitHub CLI is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key does not match GitHub's fingerprints.
# @exitcode 69 The system is not Ubuntu or Fedora, or gpg is missing.
# @exitcode 74 The key download or repository configuration failed.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of the package manager.
# @example
#   gh__install
gh__install() {
  [[ "$#" -eq 0 ]] || return 64
  _package__require-platform ubuntu fedora || return "$?"
  _gh__register-repository || return "$?"
  _package__install gh
}
