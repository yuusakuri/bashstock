#!/usr/bin/env bash
# @file iina
# @brief IINA installation.
# @description IINA is installed with Homebrew on macOS.

# shellcheck disable=SC2119,SC2120

# @description Set IINA as the default application for video file extensions on macOS.
#
# duti is installed with Homebrew when it is missing.
#
# @noargs
# @exitcode 0 IINA opens the listed video types.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of brew or duti.
# @example
#   iina::set-default-app
iina::set-default-app() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  local bundle='com.colliderli.iina' extension=''
  local extensions=(
    mp4 mkv mov avi wmv flv webm m4v mpg mpeg 3gp ts m2ts mts ogv vob asf f4v rmvb divx
  )
  if ! command -v duti >/dev/null 2>&1; then
    package::_install duti || return "$?"
  fi
  for extension in "${extensions[@]}"; do
    duti -s "${bundle}" "${extension}" all || return "$?"
  done
}
