#!/usr/bin/env bash
# @file plist
# @brief macOS property lists.
# @description Values are written with PlistBuddy.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Set a string value for one top-level key in a macOS property list.
#
# The file is created as an empty dictionary when it does not exist and is
# validated with plutil before and after the change.
#
# @arg $1 string Property list file. A symbolic link is refused.
# @arg $2 string Top-level key without a dot.
# @arg $3 string String value.
# @exitcode 0 The value was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 65 The file is not a valid property list.
# @exitcode 66 The path is not a regular file.
# @exitcode 69 plutil is unavailable.
# @exitcode 74 The file could not be created or changed.
# @example
#   plist::set "${HOME}/Library/Preferences/com.example.app.plist" Theme dark
plist::set() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && "$2" != *.* && ! -L "$1" ]] || return 64
  command::require plutil || return "$?"
  if [[ ! -e "$1" ]]; then
    mkdir -p -- "$(path::directory-name "$1")" || return 74
    file::write-text "$1" '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
' || return "$?"
  fi
  [[ -f "$1" ]] || return 66
  plutil -lint -s "$1" || return 65
  plutil -replace "$2" -string "$3" "$1" || return 74
  plutil -lint -s "$1" || return 65
}
