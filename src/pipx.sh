#!/usr/bin/env bash
# @file pipx
# @brief pipx installation.
# @description pipx is installed from the platform package source.

# shellcheck disable=SC2119,SC2120

# @description Write the major.minor.patch version of the Python 3 interpreter.
# @internal
pipx::_python-version() {
  [[ "$#" -eq 0 ]] || return 64
  command::require python3 || return "$?"
  python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' || return 74
}

# @description Write pipx releases on PyPI whose Requires-Python accepts PYTHON_VERSION.
# @internal
pipx::_official-versions() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  local json='' versions=''
  json="$(package::_fetch https://pypi.org/pypi/pipx/json)" || return "$?"
  versions="$(printf '%s' "${json}" | python::run -c '
import json
import re
import sys
python_version = [int(part) for part in sys.argv[1].split(".")]

def compare(left, right):
    size = max(len(left), len(right))
    left = left + [0] * (size - len(left))
    right = right + [0] * (size - len(right))
    return (left > right) - (left < right)

def accepts(specifiers):
    for specifier in specifiers.split(","):
        specifier = specifier.strip()
        if not specifier:
            continue
        match = re.fullmatch(r"(~=|==|!=|<=|>=|<|>)\s*([0-9]+(?:\.[0-9]+)*)(\.\*)?", specifier)
        if not match:
            return False
        operator, raw_version, wildcard = match.groups()
        version = [int(part) for part in raw_version.split(".")]
        if wildcard:
            same = compare(python_version[:len(version)], version) == 0
            if (operator == "==" and not same) or (operator == "!=" and same):
                return False
            if operator not in ("==", "!="):
                return False
            continue
        order = compare(python_version, version)
        if operator == ">=" and order < 0:
            return False
        if operator == ">" and order <= 0:
            return False
        if operator == "<=" and order > 0:
            return False
        if operator == "<" and order >= 0:
            return False
        if operator == "==" and order != 0:
            return False
        if operator == "!=" and order == 0:
            return False
        if operator == "~=" and (order < 0 or len(version) < 2 or compare(python_version[:len(version) - 1], version[:-1]) != 0):
            return False
    return True

try:
    data = json.load(sys.stdin)
except (ValueError, TypeError):
    sys.exit(74)
for release, files in data.get("releases", {}).items():
    files = [file_info for file_info in files if not file_info.get("yanked")]
    if files and re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", release) and accepts(files[0].get("requires_python") or ""):
        print(release)
' "$1")" || return "$?"
  printf '%s\n' "${versions}" | package::_sort-stable-versions
}

# @description Write pipx versions available from the selected source.
#
# The official source lists the PyPI releases that the installed Python 3
# can run.
#
# @arg $1 string Optional source: os (default) or official.
# @stdout pipx versions, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 The source is not os or official.
# @exitcode 69 Python 3 is missing for the official source.
# @exitcode 74 The PyPI index could not be downloaded or read.
# @example
#   pipx::versions official | tail -n 1
pipx::versions() {
  [[ "$#" -le 1 ]] || return 64
  local source="${1:-os}" python_version=''
  [[ "${source}" == os || "${source}" == official ]] || return 64
  if [[ "${source}" == os ]]; then
    package::_versions pipx
    return
  fi
  python_version="$(pipx::_python-version)" || return "$?"
  pipx::_official-versions "${python_version}"
}

# @description Succeed when PEP 668 marks the Python 3 interpreter as managed by the system.
#
# Ubuntu 23.04 and later mark their Python this way, and pip then refuses
# pip install --user.
# @internal
pipx::_python-is-externally-managed() {
  [[ "$#" -eq 0 ]] || return 64
  python3 -c 'import os, sys, sysconfig
sys.exit(0 if os.path.isfile(os.path.join(sysconfig.get_path("stdlib"), "EXTERNALLY-MANAGED")) else 1)'
}

# @description Install a pipx release into its own virtual environment and link it from ~/.local/bin.
#
# Each installation gets a new environment, and the launcher moves to it only
# after pip succeeds, so a failed update leaves the working pipx in place.
# Environments that the launcher no longer uses are removed afterwards.
# @internal
# @arg $1 string pipx version.
pipx::_install-official-venv() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local root="${HOME}/.local/lib/pipx-official" venv='' old='' status=0
  mkdir -p -- "${root}" "${HOME}/.local/bin" || return 74
  venv="$(mktemp -d "${root}/$1.XXXXXX")" || return 74
  python3 -m venv "${venv}" || status=74
  if [[ "${status}" -eq 0 ]]; then
    "${venv}/bin/python" -m pip install "pipx==$1" || status="$?"
  fi
  if [[ "${status}" -eq 0 ]]; then
    ln -sfn "${venv}/bin/pipx" "${HOME}/.local/bin/pipx" || status=74
  fi
  if [[ "${status}" -ne 0 ]]; then
    rm -rf -- "${venv}"
    return "${status}"
  fi
  for old in "${root}"/*; do
    [[ "${old}" == "${venv}" ]] || rm -rf -- "${old}"
  done
}

# @description Install pipx and add the pipx application directory to PATH.
#
# The os source installs the package of the system package manager. The
# official source installs the release from PyPI for the current user with
# pip, as the pipx documentation describes for systems without a package.
# Where PEP 668 forbids pip install --user, as on Ubuntu 23.04 and later, the
# release goes into its own virtual environment under ~/.local/lib/pipx-official,
# linked from ~/.local/bin/pipx.
# A source that cannot provide pipx returns an error instead of switching to
# the other source. On Ubuntu, python3-venv is installed with either source,
# because pipx creates a virtual environment for every application.
#
# @arg $1 string Optional version from pipx::versions for the same source.
# @arg $2 string Optional source: os (default) or official.
# @stderr A message when the source cannot provide pipx.
# @exitcode 0 pipx is installed and ~/.local/bin is on PATH.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The source cannot provide pipx, or the installed version differs.
# @exitcode 74 The application directory could not be created.
# @exitcode other The status of the package manager or pip.
# @example
#   pipx::install
#   pipx install pycowsay
pipx::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" source="${2:-os}" platform='' versions='' installed=''
  [[ "${source}" == os || "${source}" == official ]] || return 64
  platform="$(package::_platform)" || return "$?"
  if [[ "${source}" == os ]]; then
    versions="$(pipx::versions os)" || return "$?"
    if [[ -z "${versions}" ]]; then
      console::_write-error 'The system packages do not provide pipx; use the official source.'
      return 69
    fi
    if [[ -n "${version}" ]]; then
      version="$(package::_select-listed-version "${versions}" "${version}" pipx)" || return "$?"
    fi
    package::_install-version pipx "${version}" || return "$?"
    if [[ "${platform}" == ubuntu ]]; then
      # Ubuntu ships venv separately, and the pipx package of 20.04 does not require it.
      package::_install python3-venv || return "$?"
    fi
  else
    case "${platform}" in
      ubuntu) package::_refresh && package::_install python3-pip python3-venv || return "$?" ;;
      fedora) package::_install python3-pip || return "$?" ;;
      *)
        console::_write-error 'Install pipx from Homebrew with the os source on macOS.'
        return 69
        ;;
    esac
    versions="$(pipx::versions official)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" pipx)" || return "$?"
    if pipx::_python-is-externally-managed; then
      pipx::_install-official-venv "${version}" || return "$?"
    else
      python3 -m pip install --user "pipx==${version}" || return "$?"
    fi
    installed="$("${HOME}/.local/bin/pipx" --version)" || return 69
    if [[ "${installed}" != "${version}" ]]; then
      console::_write-error "pip installed pipx ${installed} instead of ${version}."
      return 69
    fi
  fi
  mkdir -p -- "${HOME}/.local/bin" || return 74
  env::add-path "${HOME}/.local/bin"
}
