#!/usr/bin/env bash
# @file qmk
# @brief QMK firmware tools installation.
# @description The CLI uses the official installer; QMK Toolbox uses Homebrew on macOS.

# shellcheck disable=SC2119,SC2120

# @description Install QMK Toolbox with Homebrew on macOS.
#
# @arg $1 string Optional QMK Toolbox version; only the current Homebrew version is accepted.
# @exitcode 0 QMK Toolbox is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The system is not macOS, or the version is not the current one.
# @exitcode other The status of brew.
# @example
#   qmk::toolbox::install
qmk::toolbox::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-cask qmk-toolbox "${1:-}"
}

# @description Install the QMK CLI with the official installer and diagnose the environment.
#
# `qmk --version` always confirms the installation. The CLI offers
# `qmk doctor` only after `qmk setup` has prepared the firmware tree, so the
# diagnosis also runs when that tree exists. Warnings from the diagnosis are
# reported without failing; errors return its status.
#
# @arg $1 string Optional QMK CLI version; only the newest stable version from PyPI is accepted.
# @stdout The output of qmk --version, and of qmk doctor when the firmware tree exists.
# @exitcode 0 The QMK CLI is installed and starts; doctor found at most warnings.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The version is not the newest one, or sh is unavailable.
# @exitcode 74 The installer could not be downloaded.
# @exitcode other The status of the installer, qmk --version, or qmk doctor.
# @example
#   qmk::cli::install
#   qmk setup -y
qmk::cli::install() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' status=0
  if [[ -n "${1:-}" ]]; then
    local latest=''
    latest="$(qmk::cli::_latest-version)" || return "$?"
    if [[ "$1" != "${latest}" ]]; then
      console::_write-error "The QMK installer provides only version ${latest}."
      return 69
    fi
  fi
  command::require sh || return "$?"
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://install.qmk.fm "${directory}/install.sh" || status="$?"
  [[ "${status}" -ne 0 ]] || sh "${directory}/install.sh" || status="$?"
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  # The installer puts qmk in $HOME/.local/bin and asks for a new shell otherwise.
  env::add-path "${HOME}/.local/bin" || return "$?"
  command::require qmk || return "$?"
  qmk --version || return "$?"
  # qmk doctor exists only once `qmk setup` has prepared the firmware tree.
  if qmk doctor --help >/dev/null 2>&1; then
    # doctor exits 1 when it found only warnings, such as missing udev rules.
    qmk doctor || [[ "$?" -eq 1 ]]
  fi
}

# @description Write the newest QMK CLI version published on PyPI.
# @internal
qmk::cli::_latest-version() {
  [[ "$#" -eq 0 ]] || return 64
  local json=''
  json="$(package::_fetch https://pypi.org/pypi/qmk/json)" || return "$?"
  printf '%s' "${json}" | python::run -c 'import json, sys; print(json.load(sys.stdin)["info"]["version"])'
}
