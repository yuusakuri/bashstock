#!/usr/bin/env bash
# @file textproto
# @brief textproto files.
# @description Top-level scalar fields are replaced or appended.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Replace or append one top-level scalar field in a textproto file.
#
# The file is read with its comments, quoted strings, and nested messages
# taken into account, so only a FIELD at the top level is changed. An
# existing field line is replaced; a missing field is appended. A field that
# occurs more than once at the top level, a field that holds a message, and
# unbalanced braces or strings in the result return 65 without a change.
#
# @arg $1 string Existing textproto file. A symbolic link is refused.
# @arg $2 string Field name.
# @arg $3 string Literal scalar value on one line, quoted when it is a string.
# @exitcode 0 The field was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 65 The field is ambiguous or holds a message, or the file is unbalanced.
# @exitcode 66 The file cannot be read.
# @exitcode 69 perl is unavailable.
# @exitcode other The status of file::write-text.
# @example
#   textproto::set-scalar config.textproto timeout_seconds 30
#   textproto::set-scalar config.textproto name '"production"'
textproto::set-scalar() {
  ( [[ "$#" -eq 3 && -f "$1" && ! -L "$1" && "$2" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && -n "$3" ]] ) || return 64
  string::_require-one-line "$3" || return "$?"
  command::require perl || return "$?"
  local content=''
  content="$(perl -e '
    my ($path, $field, $value) = @ARGV;
    open(my $handle, "<", $path) or exit 66;
    my @lines = <$handle>;
    close($handle);
    # Scan text, returning the depth after it, or undef for an unterminated string.
    sub scan {
      my ($text, $depth) = @_;
      my $quote = "";
      for (my $i = 0; $i < length($text); $i++) {
        my $c = substr($text, $i, 1);
        if ($quote ne "") {
          if ($c eq "\\") { $i++; next; }
          $quote = "" if $c eq $quote;
          next;
        }
        last if $c eq "#";
        if ($c eq "\"" || $c eq "\x27") { $quote = $c; next; }
        $depth++ if $c eq "{" || $c eq "<";
        $depth-- if $c eq "}" || $c eq ">";
        return undef if $depth < 0;
      }
      return $quote eq "" ? $depth : undef;
    }
    my ($depth, @matches) = (0);
    for my $index (0 .. $#lines) {
      if ($depth == 0 && $lines[$index] =~ /^\s*\Q$field\E\s*(:|\{|<)/) {
        exit 65 if $1 ne ":" || $lines[$index] =~ /^\s*\Q$field\E\s*:\s*[{<]/;
        push @matches, $index;
      }
      $depth = scan($lines[$index], $depth);
      exit 65 unless defined $depth;
    }
    exit 65 if $depth != 0 || @matches > 1;
    if (@matches) {
      $lines[$matches[0]] = "$field: $value\n";
    } else {
      $lines[-1] .= "\n" if @lines && $lines[-1] !~ /\n\z/;
      push @lines, "$field: $value\n";
    }
    $depth = 0;
    for my $line (@lines) {
      $depth = scan($line, $depth);
      exit 65 unless defined $depth;
    }
    exit 65 if $depth != 0;
    print @lines;
    print "x";
  ' "$1" "$2" "$3")" || return "$?"
  # The trailing x keeps the final newline through command substitution.
  file::write-text "$1" "${content%x}"
}
