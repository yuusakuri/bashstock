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
  command::require perl || return "$?"
  local json='' versions=''
  json="$(package::_fetch https://pypi.org/pypi/pipx/json)" || return "$?"
  versions="$(printf '%s' "${json}" | perl -MJSON::PP -e '
    my @python = split /\./, shift;
    sub compare {
      my ($left, $right) = @_;
      for my $index (0 .. ($#$left > $#$right ? $#$left : $#$right)) {
        my $difference = ($left->[$index] // 0) <=> ($right->[$index] // 0);
        return $difference if $difference;
      }
      return 0;
    }
    # Accepts the PEP 440 operators that Requires-Python uses; anything else rejects the release.
    sub accepts {
      my ($specifiers) = @_;
      for my $specifier (split /\s*,\s*/, $specifiers) {
        next if $specifier eq "";
        $specifier =~ /^(~=|==|!=|<=|>=|<|>)\s*([0-9]+(?:\.[0-9]+)*)(\.\*)?$/ or return 0;
        my ($operator, $wildcard) = ($1, $3);
        my @version = split /\./, $2;
        if ($wildcard) {
          my $same = compare([@python[0 .. $#version]], \@version) == 0;
          return 0 if ($operator eq "==" && !$same) || ($operator eq "!=" && $same);
          return 0 if $operator ne "==" && $operator ne "!=";
          next;
        }
        my $order = compare(\@python, \@version);
        return 0 if $operator eq ">=" && $order < 0;
        return 0 if $operator eq ">" && $order <= 0;
        return 0 if $operator eq "<=" && $order > 0;
        return 0 if $operator eq "<" && $order >= 0;
        return 0 if $operator eq "==" && $order != 0;
        return 0 if $operator eq "!=" && $order == 0;
        if ($operator eq "~=") {
          return 0 if $order < 0 || @version < 2;
          return 0 if compare([@python[0 .. $#version - 1]], [@version[0 .. $#version - 1]]) != 0;
        }
      }
      return 1;
    }
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    while (my ($release, $files) = each %{$data->{releases} || {}}) {
      my @files = grep { !$_->{yanked} } @$files;
      next unless @files && $release =~ /^[0-9]+(?:\.[0-9]+)*$/;
      print "$release\n" if accepts($files[0]{requires_python} // "");
    }
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

# @description Install pipx and add the pipx application directory to PATH.
#
# The os source installs the package of the system package manager. The
# official source installs the release from PyPI for the current user with
# pip, as the pipx documentation describes for systems without a package.
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
    python3 -m pip install --user "pipx==${version}" || return "$?"
    installed="$("${HOME}/.local/bin/pipx" --version)" || return 69
    if [[ "${installed}" != "${version}" ]]; then
      console::_write-error "pip installed pipx ${installed} instead of ${version}."
      return 69
    fi
  fi
  mkdir -p -- "${HOME}/.local/bin" || return 74
  env::add-path "${HOME}/.local/bin"
}
