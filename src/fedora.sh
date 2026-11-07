#!/usr/bin/env bash
# @file fedora
# @brief Fedora setup.
# @description Setup functions configure a fresh Fedora installation.

# shellcheck disable=SC2119,SC2120

# @description Apply the common Fedora user configuration, stopping at the first failure.
#
# The same steps as ubuntu::setup run on Fedora: missing curl, Git, and Perl
# modules that bashstock uses are installed, ~/.env is registered, the editor
# of Bash and Zsh is set to code --wait, completion ignores case, English
# names are linked to localized user directories, the user joins dialout, Git
# uses Git Credential Manager, ~/.ssh permissions are fixed, and external
# tools are installed. In supported Wayland sessions, Electron applications
# also prefer native Wayland rendering.
#
# @noargs
# @stderr The step that failed.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Fedora.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of the first step that failed.
# @example
#   GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' fedora::setup
fedora::setup() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform fedora || return "$?"
  setup::_apply-linux-user-configuration || return "$?"
  fedora::setup-external
}

# @description Install GnuPG, GitHub CLI, and Git Credential Manager on Fedora when they are not already available.
#
# GitHub CLI is installed from its official DNF repository after checking the
# repository key against GitHub's published fingerprints.
#
# @noargs
# @exitcode 0 The missing tools were installed or were already available.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Fedora, or a required command is missing.
# @exitcode 77 sudo refused the credentials.
# @exitcode other A package installation or repository setup failed.
# @example
#   fedora::setup-external
fedora::setup-external() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform fedora || return "$?"
  setup::_install-external gnupg2
}
