#!/usr/bin/env bash
# @file repo
# @brief Google Repo workspaces.
# @description Workspaces are initialized and synchronized with the repo tool.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Initialize a Google Repo workspace with shallow history.
#
# @arg $1 string Manifest repository URL.
# @arg $2 string Manifest branch.
# @arg $3 string Manifest file name.
# @arg $4 string Optional workspace directory, created when missing. Defaults to the current directory.
# @exitcode 0 The workspace was initialized.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 repo is unavailable.
# @exitcode 74 The directory could not be created.
# @exitcode other The status of repo init.
# @example
#   repo::init https://android.googlesource.com/platform/manifest android-14.0.0_r1 default.xml aosp
repo::init() {
  [[ "$#" -ge 3 && "$#" -le 4 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  local directory="${4:-.}"
  command::require repo || return "$?"
  mkdir -p -- "${directory}" || return 74
  (cd -- "${directory}" && repo init --depth=1 -u "$1" -b "$2" -m "$3")
}

# @description Synchronize one path of a Google Repo workspace, forcing the sync.
#
# @arg $1 string Project path to synchronize.
# @arg $2 integer Optional parallel jobs. Defaults to 4.
# @arg $3 string Optional workspace directory. Defaults to the current directory.
# @exitcode 0 The project was synchronized.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo sync.
# @example
#   repo::sync frameworks/base 8 aosp
repo::sync() {
  [[ "$#" -ge 1 && "$#" -le 3 && -n "$1" ]] || return 64
  local jobs="${2:-4}" directory="${3:-.}"
  ( [[ "${jobs}" =~ ^[1-9][0-9]*$ ]] ) || return 64
  command::require repo || return "$?"
  (cd -- "${directory}" && repo sync --force-sync -j "${jobs}" "$1")
}

# @description Write the current Google Repo manifest with revisions to a file.
#
# @arg $1 string Optional output file. Defaults to ./manifest.xml.
# @arg $2 string Optional workspace directory. Defaults to the current directory.
# @exitcode 0 The manifest was written.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo manifest.
# @example
#   repo::write-manifest pinned.xml aosp
repo::write-manifest() {
  [[ "$#" -le 2 ]] || return 64
  local output="${1:-./manifest.xml}" directory="${2:-.}"
  command::require repo || return "$?"
  [[ "${output}" == /* ]] || output="${PWD}/${output}"
  (cd -- "${directory}" && repo manifest -r -o "${output}")
}

# @description Run git fsck in every project of a Google Repo workspace.
#
# @arg $1 string Optional workspace directory. Defaults to the current directory.
# @stdout The output of git fsck for each project.
# @exitcode 0 Every project passed.
# @exitcode 64 More than one argument was given.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo forall.
# @example
#   repo::check aosp
repo::check() {
  [[ "$#" -le 1 ]] || return 64
  command::require repo || return "$?"
  (cd -- "${1:-.}" && repo forall -c 'git fsck')
}

# @description Hard reset every project of a Google Repo workspace and remove untracked files.
#
# Every uncommitted change in every project is discarded. Ignored files are kept.
#
# @arg $1 string Optional workspace directory. Defaults to the current directory.
# @exitcode 0 Every project was reset.
# @exitcode 64 More than one argument was given.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo forall.
# @example
#   repo::reset aosp
repo::reset() {
  [[ "$#" -le 1 ]] || return 64
  command::require repo || return "$?"
  (cd -- "${1:-.}" && repo forall -c 'git reset --hard && git clean -fd')
}
