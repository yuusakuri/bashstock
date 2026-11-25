#!/usr/bin/env bash
# @file flutter
# @brief Flutter SDK installation and projects.
# @description The SDK is installed from the official Flutter releases.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Run a Flutter project in Chrome in release mode.
#
# @arg $1 string Optional Flutter project directory. Defaults to the current directory.
# @exitcode 0 The application ended successfully.
# @exitcode 64 More than one argument was given.
# @exitcode 69 flutter is unavailable.
# @exitcode other The status of flutter run or cd.
# @example
#   flutter__run-chrome-release apps/mobile
flutter__run-chrome-release() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && _docker__run-command flutter run --release -d chrome); }

# @description Run a Flutter project as a Linux desktop application in release mode.
#
# @arg $1 string Optional Flutter project directory. Defaults to the current directory.
# @exitcode 0 The application ended successfully.
# @exitcode 64 More than one argument was given.
# @exitcode 69 flutter is unavailable.
# @exitcode other The status of flutter run or cd.
# @example
#   flutter__run-linux-release apps/desktop
flutter__run-linux-release() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && _docker__run-command flutter run --release -d linux); }

# @description Run the Flutter tests of a project with optional flutter test arguments.
#
# @arg $1 string Optional Flutter project directory, used when it is an existing directory. Defaults to the current directory.
# @arg $@ string Optional arguments of flutter test.
# @exitcode 0 The tests passed.
# @exitcode 69 flutter is unavailable.
# @exitcode other The status of flutter test or cd.
# @example
#   flutter__test apps/mobile --name 'login'
flutter__test() { [[ "$#" -ge 0 ]] || return 64; local directory='.'; [[ "$#" -gt 0 && -d "$1" ]] && { directory="$1"; shift; }; (cd "$directory" && _docker__run-command flutter test "$@"); }

# @description Run the Flutter tests with coverage and write the LCOV HTML report.
#
# @arg $1 string Optional report directory. Defaults to coverage/html below the project directory.
# @arg $2 string Optional Flutter project directory. Defaults to the current directory.
# @exitcode 0 The tests passed and the report was written.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 flutter or genhtml is unavailable.
# @exitcode other The status of flutter test or genhtml.
# @example
#   flutter__coverage '' apps/mobile
flutter__coverage() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${2:-.}" output="${1:-}"
  command__require flutter || return "$?"
  command__require genhtml || return "$?"
  [[ -n "${output}" ]] || output="${directory%/}/coverage/html"
  (cd -- "${directory}" && flutter test --coverage) || return "$?"
  genhtml "${directory%/}/coverage/lcov.info" -o "${output}"
}

# @description Keep Flutter SDK changes in a retrievable stash and switch versions.
#
# When the stash fails, changes other than ignored files are discarded before
# the switch, as decided for the SDK directory.
#
# @arg $1 string Optional tag to check out. Defaults to the newest stable version.
# @arg $2 string Optional Flutter SDK directory. Defaults to $HOME/.local/flutter.
# @exitcode 0 The SDK is at the version.
# @exitcode 64 More than two arguments were given.
# @exitcode 66 The directory is not a Git checkout.
# @exitcode other The status of the git command that failed.
# @example
#   flutter__use-version 3.24.3
flutter__use-version() {
  [[ "$#" -le 2 ]] || return 64
  local version='' directory=''
  if [[ "$#" -ge 1 ]]; then version="$1"; fi
  if [[ "$#" -ge 2 ]]; then directory="$2"; else directory="$HOME/.local/flutter"; fi
  [[ -d "$directory/.git" ]] || return 66
  [[ -n "$version" ]] || version="$(flutter__versions | _package__latest-stable-version)" || return "$?"
  git -C "$directory" fetch --tags origin || return "$?"
  if ! git -C "$directory" stash push --include-untracked; then
    git -C "$directory" reset --hard HEAD || return "$?"
    git -C "$directory" clean -fd || return "$?"
  fi
  # checkout instead of switch keeps Git 2.17 on Ubuntu 18.04 working.
  git -C "$directory" -c advice.detachedHead=false checkout --detach "$version"
}

# @description Write stable Flutter SDK versions for the current platform.
#
# @noargs
# @stdout Stable Flutter versions such as 3.35.7, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 is unavailable, or the platform is unsupported.
# @exitcode 74 The release index could not be downloaded or read.
# @example
#   flutter__versions | tail -n 1
flutter__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' index='linux' json='' versions=''
  platform="$(_package__platform)" || return "$?"
  [[ "${platform}" != 'darwin' ]] || index='macos'
  json="$(_package__fetch "https://storage.googleapis.com/flutter_infra_release/releases/releases_${index}.json")" || return "$?"
  versions="$(printf '%s' "${json}" | _python__run-json 74 '
import re
for release in data["releases"]:
    version = release.get("version") or ""
    if release.get("channel") == "stable" and re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        print(version)
')" || return "$?"
  printf '%s\n' "${versions}" | _package__sort-stable-versions
}

# @description Install packages required to build Flutter applications.
#
# @noargs
# @exitcode 0 The build dependencies are installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or git or curl is missing on macOS.
# @exitcode 74 The C++ development package could not be determined.
# @exitcode other The status of the package manager.
# @example
#   flutter__dependencies__install
flutter__dependencies__install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' library=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    darwin)
      command__require git || return "$?"
      command__require curl
      ;;
    ubuntu)
      _package__refresh || return "$?"
      command__require apt-cache || return "$?"
      library="$(apt-cache pkgnames 'libstdc++-' |
        awk '/^libstdc\+\+-[0-9]+-dev$/ {name=$0; sub(/^libstdc\+\+-/, "", $0); sub(/-dev$/, "", $0); print $0, name}' |
        sort -n | tail -n 1 | awk '{print $2}')" || return 74
      [[ -n "${library}" ]] || return 69
      _package__install curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build \
        pkg-config libgtk-3-dev "${library}"
      ;;
    fedora)
      _package__install curl git unzip xz zip mesa-libGLU clang cmake ninja-build \
        pkgconf-pkg-config gtk3-devel libstdc++-devel
      ;;
  esac
}

# @description Install dependencies and select a stable Flutter SDK version.
#
# An existing Flutter repository retains its stash and ignored files.
#
# Limitation: Flutter builds Linux desktop applications on Ubuntu 20.04 and
# later only. Ubuntu 18.04 installs the SDK and runs Dart code and tests,
# but `flutter build linux` stops there because it needs CMake 3.13 and the
# release provides 3.10.
#
# @arg $1 string Optional stable Flutter version. Defaults to the newest stable release.
# @arg $2 string Optional SDK directory. Defaults to $HOME/.local/flutter.
# @stderr A message when the directory holds something other than a Flutter SDK.
# @exitcode 0 The SDK is at the version and its bin directory is on PATH.
# @exitcode 64 The version is not major.minor.patch.
# @exitcode 69 The platform is unsupported.
# @exitcode 73 The directory is neither empty nor a Flutter SDK.
# @exitcode other The status of the dependency installation, git, or flutter.
# @example
#   flutter__install 3.35.7
#   flutter doctor
flutter__install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" directory="${2:-${HOME}/.local/flutter}"
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  flutter__dependencies__install || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(flutter__versions | _package__latest-stable-version)" || return "$?"
  fi
  if [[ -e "${directory}" ]]; then
    if [[ -x "${directory}/bin/flutter" && -d "${directory}/.git" ]]; then
      flutter__use-version "${version}" "${directory}" || return "$?"
    elif ! path__is-empty-directory "${directory}"; then
      _console__write-error "Directory is not a Flutter SDK: ${directory}"
      return 73
    fi
  fi
  mkdir -p -- "$(path__directory-name "${directory}")" || return 74
  if [[ ! -d "${directory}/.git" ]]; then
    git clone --branch "${version}" https://github.com/flutter/flutter.git "${directory}" ||
      return "$?"
  fi
  [[ -x "${directory}/bin/flutter" ]] || return 69
  env__add-path "${directory}/bin" || return "$?"
  "${directory}/bin/flutter" --version
}
