#!/usr/bin/env bash
# @file jdk
# @brief JDK installation and versions.
# @description The JDK is installed from the platform package source.

# shellcheck disable=SC2119,SC2120

# @description Write JDK feature release numbers available to the current platform.
#
# @noargs
# @stdout JDK feature release numbers such as 17 and 21, one per line, oldest first.
# @exitcode 0 The numbers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or the package tool is missing.
# @exitcode 74 The package list could not be read.
# @example
#   jdk__version__list
jdk__version__list() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' versions='' name=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    darwin)
      versions="$(_package__brew-formula-versions openjdk)" || return "$?"
      while IFS= read -r name; do
        if [[ -n "${name}" ]]; then printf '%s\n' "${name%%.*}"; fi
      done <<<"${versions}" | _package__sort-versions
      ;;
    ubuntu)
      command__require apt-cache || return "$?"
      versions="$(apt-cache pkgnames openjdk- 2>/dev/null)" || return 74
      while IFS= read -r name; do
        if [[ "${name}" =~ ^openjdk-([0-9]+)-jdk$ ]]; then
          printf '%s\n' "${BASH_REMATCH[1]}"
        fi
      done <<<"${versions}" | _package__sort-versions
      ;;
    fedora)
      command__require dnf || return "$?"
      versions="$(dnf repoquery --quiet --queryformat $'%{name} %{version}\n' \
        'java-*-openjdk-devel' 2>/dev/null)" || return 74
      while IFS=' ' read -r name _; do
        if [[ "${name}" =~ ^java-([0-9]+)-openjdk-devel$ ]]; then
          printf '%s\n' "${BASH_REMATCH[1]}"
        fi
      done <<<"${versions}" | _package__sort-versions
      ;;
  esac
}

# @description Write the newest JDK feature release number available to the current platform.
#
# @noargs
# @stdout The newest JDK feature release number.
# @exitcode 0 The number was written.
# @exitcode 1 No JDK is available.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or the package tool is missing.
# @example
#   jdk__install "$(jdk__version__latest)"
jdk__version__latest() {
  [[ "$#" -eq 0 ]] || return 64
  jdk__version__list | _package__latest-stable-version
}

# @description Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH.
#
# @arg $1 string Optional feature release number such as 21. Defaults to jdk__version__latest.
# @exitcode 0 The JDK is installed and JAVA_HOME and PATH point to it.
# @exitcode 64 The version is not a number.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode 74 java is missing from the selected JDK.
# @exitcode other The status of the package manager or the alternatives tool.
# @example
#   jdk__install 21
#   java -version
jdk__install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' home=''
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+$ ]] ) || return 64
  platform="$(_package__platform)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(jdk__version__latest)" || return "$?"
  fi
  case "${platform}" in
    darwin) home="$(_jdk__install-darwin "${version}")" || return "$?" ;;
    ubuntu) home="$(_jdk__install-ubuntu "${version}")" || return "$?" ;;
    fedora) home="$(_jdk__install-fedora "${version}")" || return "$?" ;;
  esac
  [[ -x "${home}/bin/java" ]] || return 74
  env__set-variable JAVA_HOME "${home}" || return "$?"
  env__add-path "${home}/bin"
}

# @description Install an OpenJDK formula on macOS and write its Java home.
# @internal
_jdk__install-darwin() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" stable='' formula='openjdk' prefix=''
  stable="$(_package__brew-formula-stable-version openjdk)" || return "$?"
  [[ "${stable%%.*}" == "${version}" ]] || formula="openjdk@${version}"
  _package__install "${formula}" >&2 || return "$?"
  prefix="$(brew --prefix)" || return 74
  command__run-as-root ln -sfn "${prefix}/opt/${formula}/libexec/openjdk.jdk" \
    "/Library/Java/JavaVirtualMachines/openjdk-${version}.jdk" >&2 || return 74
  command__require /usr/libexec/java_home || return "$?"
  /usr/libexec/java_home -v "${version}"
}

# @description Select the Java and Java compiler alternatives below a Java home.
# @internal
_jdk__select-alternatives() {
  [[ "$#" -eq 2 && -d "$2" ]] || return 64
  local tool=''
  command__require "$1" || return "$?"
  for tool in java javac; do
    [[ -x "$2/bin/${tool}" ]] || return 74
    command__run-as-root "$1" --set "${tool}" "$2/bin/${tool}" >&2 || return "$?"
  done
}

# @description Install an OpenJDK package on Ubuntu and write its Java home.
# @internal
_jdk__install-ubuntu() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" architecture='' home=''
  _package__install "openjdk-${version}-jdk" >&2 || return "$?"
  architecture="$(_package__deb-architecture)" || return "$?"
  home="/usr/lib/jvm/java-${version}-openjdk-${architecture}"
  _jdk__select-alternatives update-alternatives "${home}" || return "$?"
  printf '%s\n' "${home}"
}

# @description Install an OpenJDK package on Fedora and write its Java home.
# @internal
_jdk__install-fedora() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" home=''
  _package__install "java-${version}-openjdk-devel" >&2 || return "$?"
  command__require readlink || return "$?"
  home="$(readlink -f "/usr/lib/jvm/java-${version}-openjdk")" || return 74
  _jdk__select-alternatives alternatives "${home}" || return "$?"
  printf '%s\n' "${home}"
}
