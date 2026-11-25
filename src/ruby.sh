#!/usr/bin/env bash
# @file ruby
# @brief Ruby installation and versions.
# @description Ruby is installed with rbenv.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write stable Ruby versions that rbenv can install in ascending order.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 rbenv is unavailable.
# @exitcode 74 rbenv could not list the versions.
# @example
#   ruby__version__list | tail -n 5
ruby__version__list() {
  [[ "$#" -eq 0 ]] || return 64
  local rbenv='' versions='' version=''
  rbenv="$(_ruby__rbenv-command)" || return "$?"
  versions="$("${rbenv}" install --list-all 2>/dev/null)" || return 74
  while IFS= read -r version; do
    version="${version#"${version%%[![:space:]]*}"}"
    # if keeps a non-version last line from becoming the loop's status under pipefail.
    if ( [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ); then printf '%s\n' "${version}"; fi
  done <<<"${versions}" | _package__sort-versions
}

# @description Write the newest stable Ruby version that rbenv can install.
#
# @noargs
# @stdout The newest version, such as 3.3.5.
# @exitcode 0 The version was written.
# @exitcode 1 No stable version was found.
# @exitcode 64 An argument was given.
# @example
#   ruby__version__latest
ruby__version__latest() {
  [[ "$#" -eq 0 ]] || return 64
  ruby__version__list | _package__latest-stable-version
}

# @description Write the rbenv root directory.
# @internal
_ruby__rbenv-root() {
  [[ "$#" -eq 0 ]] || return 64
  printf '%s\n' "${RBENV_ROOT:-${HOME}/.rbenv}"
}

# @description Install rbenv and ruby-build.
# @internal
_ruby__install-rbenv() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' root=''
  platform="$(_package__platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    local outdated='' formula=''
    _package__install rbenv ruby-build || return "$?"
    # brew upgrade fails when a named formula is already current.
    outdated="$(brew outdated --formula --quiet rbenv ruby-build)" || return 74
    while IFS= read -r formula; do
      [[ -z "${formula}" ]] || brew upgrade "${formula}" || return "$?"
    done <<<"${outdated}"
    return 0
  fi
  command__require git || return "$?"
  root="$(_ruby__rbenv-root)"
  if [[ -d "${root}/.git" ]]; then
    git -C "${root}" pull --ff-only || return "$?"
  else
    git clone https://github.com/rbenv/rbenv.git "${root}" || return "$?"
  fi
  if [[ -d "${root}/plugins/ruby-build/.git" ]]; then
    git -C "${root}/plugins/ruby-build" pull --ff-only
  else
    git clone https://github.com/rbenv/ruby-build.git "${root}/plugins/ruby-build"
  fi
}

# @description Write the rbenv command path.
# @internal
_ruby__rbenv-command() {
  [[ "$#" -eq 0 ]] || return 64
  if command -v rbenv >/dev/null 2>&1; then
    command -v rbenv
    return 0
  fi
  local candidate=''
  candidate="$(_ruby__rbenv-root)/bin/rbenv"
  [[ -x "${candidate}" ]] || return 69
  printf '%s\n' "${candidate}"
}

# @description Configure Bash and Zsh startup files to initialize rbenv and apply it to this shell.
# @internal
_ruby__configure-shell() {
  [[ "$#" -eq 0 ]] || return 64
  local shell='' startup='' root=''
  root="$(_ruby__rbenv-root)"
  for shell in bash zsh; do
    startup="${HOME}/.${shell}rc"
    [[ -e "${startup}" ]] || : >"${startup}" || return 74
    if [[ -d "${root}/bin" ]]; then
      file__replace-text-or-append "${startup}" '^export PATH=.*\.rbenv/bin.*$' \
        "export PATH=\"${root}/bin:\${PATH}\"" || return "$?"
    fi
    file__replace-text-or-append "${startup}" '^.*rbenv init.*$' "eval \"\$(rbenv init - ${shell})\"" || return "$?"
  done
  [[ ! -d "${root}/bin" || ":${PATH}:" == *":${root}/bin:"* ]] || PATH="${root}/bin:${PATH}"
  [[ ":${PATH}:" == *":${root}/shims:"* ]] || PATH="${root}/shims:${PATH}"
  export PATH
}

# @description Install rbenv, configure the shell, and install a Ruby version globally.
#
# @arg $1 string Optional Ruby version such as 3.4.7. Defaults to ruby__version__latest.
# @exitcode 0 Ruby is installed and selected with rbenv global.
# @exitcode 64 The version is not major.minor.patch.
# @exitcode 69 rbenv is unavailable after installation.
# @exitcode other The status of the package manager, git, or rbenv install.
# @example
#   ruby__install 3.4.7
#   ruby --version
ruby__install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" rbenv='' platform=''
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      _package__install build-essential autoconf bison libssl-dev libreadline-dev \
        zlib1g-dev libyaml-dev libffi-dev || return "$?"
      ;;
    fedora)
      _package__install gcc gcc-c++ make autoconf bison openssl-devel readline-devel \
        zlib-devel libyaml-devel libffi-devel || return "$?"
      ;;
  esac
  _ruby__install-rbenv || return "$?"
  _ruby__configure-shell || return "$?"
  rbenv="$(_ruby__rbenv-command)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(ruby__version__latest)" || return "$?"
  fi
  "${rbenv}" install --skip-existing "${version}" || return "$?"
  "${rbenv}" global "${version}" || return "$?"
  "${rbenv}" rehash
}
