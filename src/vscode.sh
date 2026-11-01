#!/usr/bin/env bash
# @file vscode
# @brief Visual Studio Code installation and settings.
# @description VS Code is installed from Microsoft's package source.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Remove the VS Code user data directory.
#
# VS Code is not checked for running instances.
#
# @arg $1 string Optional directory to remove. Defaults to the standard user data directory.
# @exitcode 0 The directory was removed.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist, is /, or is a symbolic link.
# @exitcode 74 The directory could not be removed.
# @example
#   vscode::remove-user-data
vscode::remove-user-data() {
  [[ "$#" -le 1 ]] || return 64
  local directory=''
  if [[ "$#" -eq 1 ]]; then
    directory="$1"
  elif [[ "$(system::operating-system)" == darwin ]]; then
    directory="${HOME}/Library/Application Support/Code"
  else
    directory="${HOME}/.config/Code"
  fi
  [[ -n "${directory}" && "${directory}" != / && -d "${directory}" && ! -L "${directory}" ]] || return 66
  rm -rf -- "${directory}" || return 74
}

# @description Set one handler with duti, skipping a type that macOS does not know.
#
# An extension that no installed application declares has only a dynamic
# UTI, and a UTI that the running macOS does not define has no hierarchy;
# LaunchServices refuses both, so they are reported and skipped.
# @internal
vscode::_set-handler() {
  [[ "$#" -eq 2 ]] || return 64
  local output='' status=0
  output="$(duti -s "$1" "$2" all 2>&1)" || status="$?"
  [[ "${status}" -ne 0 ]] || return 0
  if [[ "${output}" == *' for dyn.'* || "${output}" == *'does not conform to any UTI hierarchy'* ]]; then
    console::_write-error "Skipped $2, which this macOS does not declare as a file type."
    return 0
  fi
  printf '%s\n' "${output}" >&2
  return "${status}"
}

# @description Set VS Code as the default application for text and source file types on macOS.
#
# Extensions and UTIs that this macOS does not declare are reported and
# skipped; any other failure returns its status.
#
# @noargs
# @stderr Each skipped extension or UTI.
# @exitcode 0 VS Code opens the listed types.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS, or duti is unavailable.
# @exitcode other The status of duti.
# @example
#   vscode::set-default-app
vscode::set-default-app() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require duti || return "$?"
  local bundle='com.microsoft.VSCode' type=''
  local extensions=(
    txt text md markdown mdown mkd json jsonc yaml yml toml ini conf config env log csv tsv
    xml html htm css scss sass js jsx ts tsx mjs cjs sh bash zsh fish py rb php java c h cpp
    hpp cs go rs sql graphql gql Dockerfile gitignore
  )
  local types=(
    public.plain-text public.text public.utf8-plain-text public.unix-executable
    public.shell-script net.daringfireball.markdown public.json public.yaml public.xml
    public.html public.css public.javascript public.comma-separated-values-text
    public.tab-separated-values-text public.source-code
  )
  for type in "${extensions[@]}"; do
    vscode::_set-handler "${bundle}" ".${type}" || return "$?"
  done
  for type in "${types[@]}"; do
    vscode::_set-handler "${bundle}" "${type}" || return "$?"
  done
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -kill -r -domain local -domain system -domain user >/dev/null 2>&1
  killall Finder >/dev/null 2>&1 || true
}

# @description Register the Microsoft VS Code repository for the current Linux platform.
# @internal
vscode::_register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local architecture=''
    architecture="$(package::_deb-architecture)" || return "$?"
    # The code package adds its own definition of this repository. Current
    # packages honor the debconf answer; older ones, such as the 1.85 series for
    # Ubuntu 18.04, keep an existing vscode.list. That file therefore holds only
    # comments, which also replaces an earlier entry that would duplicate ours.
    printf 'code code/add-microsoft-repo boolean false\n' |
      command::run-as-root debconf-set-selections || return 74
    file::write-text /etc/apt/sources.list.d/vscode.list \
      '# BashStock defines the VS Code repository in vscode.sources.'$'\n''# This file stops the code package from adding a second definition.'$'\n' || return "$?"
    package::_apt-register-repository vscode https://packages.microsoft.com/keys/microsoft.asc \
      https://packages.microsoft.com/repos/code stable main "${architecture}"
  else
    package::_dnf-register-repository vscode "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"
  fi
}

# @description Write VS Code versions available to the current platform.
#
# @noargs
# @stdout VS Code versions, one per line; on Ubuntu only builds that the installed C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   vscode::versions | tail -n 1
vscode::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions visual-studio-code
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      package::_deb-runnable-versions \
        "https://packages.microsoft.com/repos/code/dists/stable/main/binary-${architecture}/Packages.gz" \
        code
      ;;
    fedora)
      package::_rpm-repository-versions https://packages.microsoft.com/yumrepos/vscode code
      ;;
  esac
}

# @description Install VS Code from the Microsoft repository or Homebrew.
#
# On Ubuntu, a version is accepted only when the installed C library can run it,
# and an omitted version selects the newest such build.
#
# @arg $1 string Optional version from vscode::versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 VS Code is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable or cannot run here.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   vscode::install
#   code --version
vscode::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask visual-studio-code "${1:-}"
    return
  fi
  local version="${1:-}" versions=''
  if [[ "${platform}" == 'ubuntu' ]]; then
    # APT would pick the newest build even when the installed C library cannot run it.
    versions="$(vscode::versions)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" 'VS Code')" || return "$?"
  fi
  vscode::_register-repository "${platform}" || return "$?"
  package::_install-version code "${version}"
}
