#!/usr/bin/env bash
# @file apt
# @brief APT package versions and Debian package installation.
# @description Versions come from apt-cache policy; Debian packages are downloaded over HTTPS and installed with their dependencies.

# shellcheck disable=SC2119,SC2120

# @description Write APT packages whose names start with PREFIX followed by a digit, with candidate versions.
#
# Each line contains a package name and its candidate version separated by a tab.
#
# @arg $1 string Package name prefix, such as openjdk- or libstdc++-.
# @stdout Lines of package name and candidate version separated by a tab, ordered by version.
# @exitcode 0 The candidates were written; none is not an error.
# @exitcode 64 The prefix is not a valid package name start.
# @exitcode 69 The system is not Ubuntu, or apt-cache or Perl is missing.
# @exitcode 74 apt-cache policy failed.
# @example
#   apt::package::candidates gcc-
#   # gcc-12	12.3.0-1ubuntu1~22.04
apt::package::candidates() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[a-z0-9][a-z0-9.+-]*$ ]] ) || return 64
  package::_require-platform ubuntu || return "$?"
  command::require apt-cache || return "$?"
  command::require perl || return "$?"
  local prefix="$1" name='' policy=''
  local names=()
  while IFS= read -r name; do
    [[ "${name}" == "${prefix}"[0-9]* ]] && names+=("${name}")
  done < <(apt-cache pkgnames "${prefix}" 2>/dev/null)
  [[ "${#names[@]}" -gt 0 ]] || return 0
  policy="$(apt-cache policy "${names[@]}" 2>/dev/null)" || return 74
  printf '%s\n' "${policy}" | perl -e '
    my ($prefix) = @ARGV;
    my $name;
    while (<STDIN>) {
      if (/^(\S+):$/) { $name = $1; next; }
      if (defined $name && /^\s+Candidate:\s+(\S+)/) {
        print substr($name, length $prefix), "\t$name\t$1\n" unless $1 eq "(none)";
        undef $name;
      }
    }
  ' "${prefix}" | package::_sort-by-first-field
}

# @description Write the APT package name with the newest version suffix after PREFIX.
#
# @arg $1 string Package name prefix followed by a version number in the package names.
# @stdout The package name with the newest version, such as gcc-14.
# @exitcode 0 The name was written.
# @exitcode 1 No package name starts with the prefix and a digit.
# @exitcode 64 The prefix is invalid.
# @exitcode 69 The system is not Ubuntu, or apt-cache or Perl is missing.
# @exitcode 74 apt-cache policy failed.
# @example
#   package::_install "$(apt::package::latest gcc-)"
apt::package::latest() {
  [[ "$#" -eq 1 ]] || return 64
  local candidates='' line=''
  candidates="$(apt::package::candidates "$1")" || return "$?"
  [[ -n "${candidates}" ]] || return 1
  line="${candidates##*$'\n'}"
  printf '%s\n' "${line%%$'\t'*}"
}

# @description Download a Debian package and install it with its dependencies through APT.
#
# @arg $1 string HTTPS URL of the Debian package.
# @arg $2 string Optional accepted architecture. Defaults to the system architecture; packages for all architectures are also accepted.
# @exitcode 0 The package and its dependencies are installed.
# @exitcode 64 The URL is not HTTPS, or the argument count is wrong.
# @exitcode 65 The package is for another architecture or is not a valid Debian package.
# @exitcode 69 The system is not Ubuntu, or curl, dpkg, or apt-get is missing.
# @exitcode 74 The download failed.
# @exitcode other The status of apt-get.
# @example
#   apt::deb::install-from-url https://example.com/tool_1.2.3_amd64.deb
apt::deb::install-from-url() {
  [[ "$#" -ge 1 && "$#" -le 2 && "$1" == https://* ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local required_command=''
  for required_command in curl dpkg dpkg-deb apt-get chmod; do
    command::require "${required_command}" || return "$?"
  done
  local url="$1" expected="${2:-}" directory='' file='' architecture='' status=0
  if [[ -z "${expected}" ]]; then
    expected="$(package::_deb-architecture)" || return "$?"
  fi
  directory="$(package::_temporary-directory)" || return "$?"
  file="${directory}/package.deb"
  package::_download "${url}" "${file}" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    architecture="$(dpkg-deb --field "${file}" Architecture 2>/dev/null)" || status=65
  fi
  if [[ "${status}" -eq 0 && "${architecture}" != "${expected}" && "${architecture}" != 'all' ]]; then
    console::_write-error "Package architecture ${architecture} does not match ${expected}."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    chmod 0755 "${directory}" && chmod 0644 "${file}" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    package::_refresh || status="$?"
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${file}" || status="$?"
  fi
  rm -rf -- "${directory}"
  return "${status}"
}
