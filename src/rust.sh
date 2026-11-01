#!/usr/bin/env bash
# @file rust
# @brief Rust installation and versions.
# @description Rust is installed with rustup.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Install Rust using rustup and an optional toolchain version.
#
# @arg $1 string Optional toolchain, such as 1.81.0 or nightly. Defaults to stable.
# @exitcode 0 Rust was installed and $HOME/.cargo/bin was added to PATH.
# @exitcode 64 More than one argument was given.
# @exitcode 69 curl or a C compiler is unavailable, or the platform is unsupported.
# @exitcode 74 rustup could not be downloaded.
# @exitcode other The status of the rustup installer.
# @example
#   rust::install 1.81.0
rust::install() {
  [[ "$#" -le 1 ]] || return 64
  command -v curl >/dev/null 2>&1 || return 69
  local temporary='' platform=''
  local toolchain='stable'
  [[ "$#" -eq 1 ]] && toolchain="$1"
  platform="$(package::_platform)" || return "$?"
  case "$platform" in
    ubuntu) package::_install build-essential || return "$?" ;;
    fedora) package::_install gcc || return "$?" ;;
    darwin) command -v cc >/dev/null 2>&1 || return 69 ;;
    *) return 69 ;;
  esac
  temporary="$(mktemp)" || return 74
  if ! curl -fsSL https://sh.rustup.rs -o "$temporary"; then
    rm -f -- "$temporary"
    return 74
  fi
  sh "$temporary" -y --default-toolchain "$toolchain"
  local status="$?"
  rm -f -- "$temporary"
  [[ "$status" -eq 0 ]] || return "$status"
  env::add-path "$HOME/.cargo/bin"
}

# @description Write the stable Rust versions, oldest first, from the rust-lang/rust releases.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 1 No version was found.
# @exitcode 64 An argument was given.
# @exitcode other The status of the GitHub query.
# @example
#   rust::versions | tail -n 1
rust::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(package::_github-release-versions rust-lang/rust)" || return "$?"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}
