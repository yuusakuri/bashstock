#!/usr/bin/env bash
# @file gsettings
# @brief GSettings string-array values.
# @description Values are parsed as GVariant text, so quoted commas and escapes are kept.

# shellcheck disable=SC2119,SC2120

# @description Write the elements of a GVariant string array, one per line.
#
# The value is parsed as GVariant text, so quoted commas and escapes are kept.
# @internal
gsettings::_parse-string-array() {
  [[ "$#" -eq 1 ]] || return 64
  command::require perl || return "$?"
  perl -e '
    my $text = shift;
    $text =~ s/^\s*\@as\s+//;
    $text =~ s/^\s+|\s+$//g;
    exit 65 unless $text =~ s/^\[// && $text =~ s/\]$//;
    my @values;
    while (length $text) {
      $text =~ s/^\s+//;
      last unless length $text;
      if ($text =~ s/^(["\x27])((?:\\.|(?!\1).)*)\1//s) {
        my $value = $2;
        $value =~ s/\\(.)/$1/g;
        exit 65 if $value =~ /\n/;
        push @values, $value;
      } else {
        exit 65;
      }
      $text =~ s/^\s*//;
      last unless length $text;
      exit 65 unless $text =~ s/^,//;
    }
    print "$_\n" for @values;
  ' "$1"
}

# @description Write one value as a single-quoted GVariant string literal.
# @internal
gsettings::_quote() {
  [[ "$#" -eq 1 && "$1" != *$'\n'* ]] || return 64
  command::require perl || return "$?"
  perl -e 'my $value = shift; $value =~ s/([\\\x27])/\\$1/g; print "\x27$value\x27\n";' "$1"
}

# @description Write lines from standard input as a GVariant string array.
# @internal
gsettings::_format-string-array() {
  [[ "$#" -eq 0 ]] || return 64
  local line='' quoted='' result='' separator=''
  while IFS= read -r line; do
    quoted="$(gsettings::_quote "${line}")" || return "$?"
    result+="${separator}${quoted}"
    separator=', '
  done
  printf '[%s]\n' "${result}"
}

# @description Require a GSettings key to hold a string array.
# @internal
gsettings::_require-string-array() {
  [[ "$#" -eq 2 && -n "$1" && -n "$2" ]] || return 64
  command::require gsettings || return "$?"
  local range=''
  range="$(gsettings range "$1" "$2" 2>/dev/null)" || return 66
  [[ "${range}" == 'type as' ]] || return 65
}

# @description Write the elements of a GSettings string array, one per line.
# @internal
gsettings::_string-array-values() {
  [[ "$#" -eq 2 ]] || return 64
  gsettings::_require-string-array "$1" "$2" || return "$?"
  local value=''
  value="$(gsettings get "$1" "$2")" || return 74
  gsettings::_parse-string-array "${value}"
}

# @description Add a literal value to a GSettings string array when it is absent.
#
# @arg $1 string GSettings schema, such as org.gnome.shell.
# @arg $2 string Key that holds a string array.
# @arg $3 string Value to add; it must not be empty or contain a newline.
# @exitcode 0 The value is in the array.
# @exitcode 64 The value is empty or contains a newline, or the argument count is not three.
# @exitcode other The status of gsettings.
# @example
#   gsettings::string-array::add org.gnome.shell favorite-apps code.desktop
gsettings::string-array::add() {
  [[ "$#" -eq 3 && -n "$3" && "$3" != *$'\n'* ]] || return 64
  local array_values='' array=''
  array_values="$(gsettings::_string-array-values "$1" "$2")" || return "$?"
  if [[ -n "${array_values}" ]] && printf '%s\n' "${array_values}" | grep -Fqx -- "$3"; then
    return 0
  fi
  array="$( (
    [[ -z "${array_values}" ]] || printf '%s\n' "${array_values}"
    printf '%s\n' "$3"
  ) | gsettings::_format-string-array)" || return "$?"
  gsettings set "$1" "$2" "${array}"
}

# @description Remove every element equal to a literal value from a GSettings string array.
#
# @arg $1 string GSettings schema.
# @arg $2 string Key that holds a string array.
# @arg $3 string Value to remove.
# @exitcode 0 The value is no longer in the array.
# @exitcode 64 The value is empty or contains a newline, or the argument count is not three.
# @exitcode other The status of gsettings.
# @example
#   gsettings::string-array::remove org.gnome.shell favorite-apps firefox.desktop
gsettings::string-array::remove() {
  [[ "$#" -eq 3 && -n "$3" && "$3" != *$'\n'* ]] || return 64
  local array_values='' value='' array=''
  array_values="$(gsettings::_string-array-values "$1" "$2")" || return "$?"
  array="$(while IFS= read -r value; do
    [[ -z "${array_values}" || "${value}" == "$3" ]] || printf '%s\n' "${value}"
  done <<<"${array_values}" | gsettings::_format-string-array)" || return "$?"
  gsettings set "$1" "$2" "${array}"
}

# @description Write the GSettings string value of one key without GVariant quotes.
# @internal
gsettings::_string-value() {
  [[ "$#" -eq 2 ]] || return 64
  command::require gsettings || return "$?"
  local value=''
  value="$(gsettings get "$1" "$2")" || return 74
  gsettings::_parse-string-array "[${value}]"
}
