#!/usr/bin/env bash
# @file symlink
# @brief Symbolic links.
# @description Links point to absolute paths and use administrator execution only when needed.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Create or replace a symbolic link that points to the absolute path of an existing SOURCE.
#
# An existing symbolic link at LINK is replaced; a file or directory there is
# kept and returns 73. Administrator execution is used only when the parent
# directory of LINK is not writable.
#
# @arg $1 string SOURCE Existing path the link points to.
# @arg $2 string LINK Path of the link.
# @exitcode 0 LINK points to the absolute path of SOURCE.
# @exitcode 64 An argument is empty, or the argument count is not two.
# @exitcode 66 SOURCE does not exist.
# @exitcode 73 LINK exists and is not a symbolic link.
# @exitcode 74 The link could not be created.
# @example
#   symlink::create ./dotfiles/.vimrc "${HOME}/.vimrc"
symlink::create() {
  [[ "$#" -eq 2 && -n "$1" && -n "$2" ]] || return 64
  local source="$1" link="${2%/}" parent=''
  [[ -e "${source}" || -L "${source}" ]] || return 66
  [[ "${source}" == /* ]] || source="${PWD}/${source}"
  source="$(path::normalize "${source}")" || return "$?"
  if [[ -e "${link}" && ! -L "${link}" ]]; then
    console::_write-error "${link} exists and is not a symbolic link."
    return 73
  fi
  parent="$(path::directory-name "${link}")" || return "$?"
  [[ -d "${parent}" ]] || return 66
  if [[ -w "${parent}" ]]; then
    ln -sfn -- "${source}" "${link}" || return 74
  else
    command::run-as-root ln -sfn -- "${source}" "${link}" || return 74
  fi
}

# @description Remove a symbolic link, using administrator execution only when its directory is not writable.
#
# @arg $1 string Path of an existing symbolic link; its target is not touched.
# @exitcode 0 The link was removed.
# @exitcode 64 The path is not a symbolic link, or the argument count is not one.
# @exitcode 74 The link could not be removed.
# @example
#   symlink::remove "${HOME}/.vimrc"
symlink::remove() {
  [[ "$#" -eq 1 && -L "${1%/}" ]] || return 64
  local link="${1%/}" parent=''
  parent="$(path::directory-name "${link}")" || return "$?"
  if [[ -w "${parent}" ]]; then
    rm -f -- "${link}" || return 74
  else
    command::run-as-root rm -f -- "${link}" || return 74
  fi
}

# @description Create a symbolic link in a user's local bin directory.
#
# @arg $1 string Existing file or directory to link to.
# @arg $2 string Optional link name. Defaults to the base name of the source.
# @arg $3 string Optional bin directory. Defaults to $HOME/.local/bin.
# @exitcode 0 The link was created.
# @exitcode 64 The arguments are invalid or the source does not exist.
# @exitcode 74 The bin directory could not be created.
# @exitcode other The status of symlink::create.
# @example
#   symlink::create-in-local-bin /opt/flutter/bin/flutter
symlink::create-in-local-bin() { [[ "$#" -ge 1 && "$#" -le 3 && -e "$1" ]] || return 64; local source="$1" name="${2:-$(basename -- "$1")}" directory="${3:-$HOME/.local/bin}"; mkdir -p -- "$directory" || return 74; symlink::create "$source" "$directory/$name"; }
