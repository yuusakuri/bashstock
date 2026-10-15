#!/usr/bin/env bash
# @file help
# @brief Show the documentation of BashStock functions in the terminal.
# @description The documentation is read from the shdoc comment block above each function.

# @description Write the line number and source file of a function, separated by a tab.
# @internal
help::_location() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local location=''
  location="$(
    shopt -s extdebug
    declare -F "$1"
  )" || return 1
  # declare -F with extdebug writes "NAME LINE FILE"; the file may contain spaces.
  location="${location#"$1" }"
  printf '%s\t%s\n' "${location%% *}" "${location#* }"
}

# @description Write the shdoc comment block directly above a line of a file.
# @internal
help::_comment-block() {
  [[ "$#" -eq 2 && "$1" =~ ^[0-9]+$ && -f "$2" ]] || return 64
  awk -v target="$1" '
    FNR >= target { exit }
    /^[[:space:]]*#/ { block[++count] = $0; next }
    { count = 0 }
    END { for (index_ = 1; index_ <= count; index_++) print block[index_] }
  ' "$2"
}

# @description Format a shdoc comment block as terminal help.
# @internal
help::_format() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  awk -v name="$1" '
    function add(key, text) { items[key] = items[key] text "\n" }
    {
      sub(/^[[:space:]]*#/, "")
      line = $0
      if (line ~ /^ @[a-z]+/) {
        tag = line
        sub(/^ @/, "", tag)
        text = tag
        sub(/^[a-z]+[[:space:]]*/, "", text)
        sub(/[[:space:]].*$/, "", tag)
        section = tag
        if (tag == "description") { add("description", text) }
        else if (tag == "example") { }
        else if (tag == "noargs") { add("arg", "This function takes no arguments.") }
        else if (tag == "arg" || tag == "option" || tag == "stdout" || tag == "stderr" ||
                 tag == "stdin" || tag == "exitcode" || tag == "see" || tag == "set") {
          add(tag, text)
        }
        next
      }
      sub(/^ /, "", line)
      if (section == "description") { add("description", line) }
      else if (section == "example") { sub(/^  /, "", line); add("example", line) }
      else if (section != "" && line != "") {
        # A continuation line belongs to the last item of the current tag.
        sub(/\n$/, "", items[section])
        add(section, " " line)
      }
    }
    function show(title, key, text) {
      text = items[key]
      sub(/\n+$/, "", text)
      if (text == "") return
      printf "\n%s\n", title
      gsub(/\n/, "\n    ", text)
      printf "    %s\n", text
    }
    END {
      printf "NAME\n    %s\n", name
      show("DESCRIPTION", "description")
      show("ARGUMENTS", "arg")
      show("OPTIONS", "option")
      show("STANDARD INPUT", "stdin")
      show("STANDARD OUTPUT", "stdout")
      show("STANDARD ERROR", "stderr")
      show("VARIABLES", "set")
      show("EXIT CODES", "exitcode")
      show("EXAMPLE", "example")
      show("SEE ALSO", "see")
    }
  '
}

# @description Show the documentation of a BashStock function, like Get-Help in PowerShell.
#
# The help is read from the shdoc comment block above the function definition,
# so it is the same text that docs/reference describes.
#
# @arg $1 string Name of a loaded function, such as string::trim.
# @stdout The function name, description, arguments, options, outputs, exit codes, and example.
# @exitcode 0 The help was written.
# @exitcode 1 No function has that name.
# @exitcode 64 The argument count is not one.
# @exitcode 66 The function has no documentation or its source file cannot be read.
# @example
#   help::show string::trim
help::show() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local location='' line='' file='' block=''
  if ! declare -F "$1" >/dev/null 2>&1; then
    console::_write-error "No function is named $1."
    return 1
  fi
  location="$(help::_location "$1")" || return 66
  line="${location%%$'\t'*}"
  file="${location#*$'\t'}"
  [[ -r "${file}" ]] || return 66
  block="$(help::_comment-block "${line}" "${file}")" || return 66
  if [[ "${block}" != *'@description'* ]]; then
    console::_write-error "$1 has no documentation."
    return 66
  fi
  printf '%s\n' "${block}" | help::_format "$1"
}

# @description Write public function names for Tab completion of help::show.
# @internal
help::_show-args() {
  declare -F | awk '{ print $3 }' | grep -E '^[a-z][a-z0-9-]*(::[a-z0-9][a-z0-9-]*)+$' | grep -v '::_'
}
