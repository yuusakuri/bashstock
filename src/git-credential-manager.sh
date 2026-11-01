#!/usr/bin/env bash
# @file git-credential-manager
# @brief Git Credential Manager installation.
# @description The manager is installed from its GitHub releases.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the installed Git Credential Manager version.
#
# @noargs
# @stdout The installed version.
# @exitcode 0 The version was written.
# @exitcode 64 An argument was given.
# @exitcode 69 git-credential-manager is unavailable.
# @exitcode other The status of git-credential-manager.
# @example
#   git-credential-manager::version::list
git-credential-manager::version::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command git-credential-manager --version; }

# @description Write the release asset names that may hold one Git Credential Manager version.
#
# Releases before 2.7 name the Linux x64 archive gcm-linux_amd64.VERSION.tar.gz.
# @internal
git-credential-manager::_asset-names() {
  [[ "$#" -eq 3 ]] || return 64
  printf 'gcm-%s-%s-%s.tar.gz\n' "$1" "$2" "$3"
  [[ "$1" != linux || "$2" != x64 ]] || printf 'gcm-linux_amd64.%s.tar.gz\n' "$3"
}

# @description Download one Git Credential Manager version and keep it when it starts on this system.
# @internal
# @arg $1 string PLATFORM osx or linux.
# @arg $2 string ARCHITECTURE x64 or arm64.
# @arg $3 string VERSION Release version.
git-credential-manager::_install-version() {
  [[ "$#" -eq 3 ]] || return 64
  local version="$3" destination='' temporary='' asset='' downloaded=0 actual_version=''
  destination="${HOME}/.local/lib/git-credential-manager/${version}"
  [[ ! -x "${destination}/git-credential-manager" ]] || return 0
  temporary="$(package::_temporary-directory)" || return "$?"
  while IFS= read -r asset; do
    if package::_download \
      "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${version}/${asset}" \
      "${temporary}/gcm.tar.gz" 2>/dev/null; then
      downloaded=1
      break
    fi
  done < <(git-credential-manager::_asset-names "$1" "$2" "${version}")
  if [[ "${downloaded}" -eq 0 ]]; then
    rm -rf -- "${temporary}"
    return 69
  fi
  mkdir -p -- "${temporary}/unpacked" || { rm -rf -- "${temporary}"; return 74; }
  tar -xzf "${temporary}/gcm.tar.gz" -C "${temporary}/unpacked" || { rm -rf -- "${temporary}"; return 74; }
  # A build for a newer C library fails here, before anything is installed.
  actual_version="$("${temporary}/unpacked/git-credential-manager" --version 2>/dev/null)" ||
    { rm -rf -- "${temporary}"; return 69; }
  [[ "${actual_version}" == "${version}" || "${actual_version}" == "${version}"+* ]] ||
    { rm -rf -- "${temporary}"; return 69; }
  mkdir -p -- "${HOME}/.local/lib/git-credential-manager" || { rm -rf -- "${temporary}"; return 74; }
  # A directory left by an interrupted installation is replaced, because mv
  # would otherwise move the new tree inside it.
  if [[ -e "${destination}" || -L "${destination}" ]]; then
    rm -rf -- "${destination}" || { rm -rf -- "${temporary}"; return 74; }
  fi
  mv -- "${temporary}/unpacked" "${destination}" || { rm -rf -- "${temporary}"; return 74; }
  rm -rf -- "${temporary}"
}

# @description Install the ICU library that Git Credential Manager, a .NET program, needs on Linux.
# @internal
git-credential-manager::_install-icu() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' name=''
  if command -v ldconfig >/dev/null 2>&1 && ldconfig -p 2>/dev/null | grep -q 'libicuuc\.so'; then
    return 0
  fi
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_refresh || return "$?"
      # The package name carries the ICU major version, such as libicu60 on Ubuntu 18.04.
      name="$(apt-cache pkgnames libicu 2>/dev/null | grep -E '^libicu[0-9]+$' | sort -V | tail -n 1)"
      [[ -n "${name}" ]] || return 69
      package::_install "${name}"
      ;;
    fedora)
      package::_install libicu
      ;;
  esac
}

# @description Install an official Git Credential Manager release for this OS and CPU.
#
# Each release is built for a minimum C library: 3.0 needs glibc 2.34, so
# Ubuntu 18.04 and 20.04 run 2.9. On Linux the ICU library is installed
# first, because the program does not start without it. Without VERSION, releases are tried from
# the newest until one starts on this system. A requested VERSION that does
# not start returns 69 without installing anything.
#
# @arg $1 string Optional major.minor.patch release. Defaults to the newest release that starts.
# @stderr A message when no release starts on this system.
# @exitcode 0 Git Credential Manager was installed and configured.
# @exitcode 64 More than one argument was given or the version is malformed.
# @exitcode 69 The platform or CPU is unsupported, or no release starts.
# @exitcode 74 A download or file operation failed.
# @exitcode other The status of the step that failed.
# @example
#   git-credential-manager::install 2.6.1
git-credential-manager::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' architecture='' candidates='' candidate='' status=69
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) platform='osx' ;;
    ubuntu | fedora) platform='linux' ;;
  esac
  architecture="$(uname -m)" || return 74
  case "${architecture}" in
    x86_64 | amd64) architecture='x64' ;;
    aarch64 | arm64) architecture='arm64' ;;
    *) return 69 ;;
  esac
  if [[ "${platform}" == linux ]]; then
    git-credential-manager::_install-icu || return "$?"
  fi
  if [[ -n "${version}" ]]; then
    git-credential-manager::_install-version "${platform}" "${architecture}" "${version}" || return "$?"
  else
    candidates="$(package::_github-release-versions git-ecosystem/git-credential-manager)" || return "$?"
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] || continue
      status=0
      git-credential-manager::_install-version "${platform}" "${architecture}" "${candidate}" || status="$?"
      [[ "${status}" -eq 69 ]] || break
    done < <(printf '%s\n' "${candidates}" | sed '1!G;h;$!d')
    if [[ "${status}" -ne 0 ]]; then
      [[ "${status}" -ne 69 ]] || console::_write-error 'No Git Credential Manager release starts on this system.'
      return "${status}"
    fi
    version="${candidate}"
  fi
  mkdir -p -- "${HOME}/.local/bin" || return 74
  ln -sfn -- "${HOME}/.local/lib/git-credential-manager/${version}/git-credential-manager" \
    "${HOME}/.local/bin/git-credential-manager" || return 74
  env::add-path "${HOME}/.local/bin" || return "$?"
  "${HOME}/.local/bin/git-credential-manager" configure
}
