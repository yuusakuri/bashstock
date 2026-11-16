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
# @exitcode 69 Python 3 is unavailable.
# @exitcode other The status of file::write-text.
# @example
#   textproto::set-scalar config.textproto timeout_seconds 30
#   textproto::set-scalar config.textproto name '"production"'
textproto::set-scalar() {
  ( [[ "$#" -eq 3 && -f "$1" && ! -L "$1" && "$2" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && -n "$3" ]] ) || return 64
  string::_require-one-line "$3" || return "$?"
  local content=''
  content="$(python::run -c '
import re
import sys
path, field, value = sys.argv[1:]
try:
    with open(path, encoding="utf-8", errors="surrogateescape", newline="") as handle:
        lines = handle.readlines()
except OSError:
    sys.exit(66)

def scan(text, depth):
    quote = None
    index = 0
    while index < len(text):
        char = text[index]
        if quote is not None:
            if char == chr(92):
                index += 2
                continue
            if char == quote:
                quote = None
            index += 1
            continue
        if char == "#":
            break
        if char in (chr(34), chr(39)):
            quote = char
        elif char in ("{", "<"):
            depth += 1
        elif char in ("}", ">"):
            depth -= 1
            if depth < 0:
                return None
        index += 1
    return None if quote is not None else depth

field_expression = re.compile(r"^\s*" + re.escape(field) + r"\s*(:|\{|<)")
scalar_message = re.compile(r"^\s*" + re.escape(field) + r"\s*:\s*[{<]")
depth = 0
matches = []
for index, line in enumerate(lines):
    match = field_expression.search(line) if depth == 0 else None
    if match:
        if match.group(1) != ":" or scalar_message.search(line):
            sys.exit(65)
        matches.append(index)
    depth = scan(line, depth)
    if depth is None:
        sys.exit(65)
if depth != 0 or len(matches) > 1:
    sys.exit(65)
replacement = field + ": " + value + "\n"
if matches:
    lines[matches[0]] = replacement
else:
    if lines and not lines[-1].endswith("\n"):
        lines[-1] += "\n"
    lines.append(replacement)
depth = 0
for line in lines:
    depth = scan(line, depth)
    if depth is None:
        sys.exit(65)
if depth != 0:
    sys.exit(65)
sys.stdout.write("".join(lines) + "x")
' "$1" "$2" "$3")" || return "$?"
  # The trailing x keeps the final newline through command substitution.
  file::write-text "$1" "${content%x}"
}
