#!/usr/bin/env bash
# @file asciidoc
# @brief AsciiDoc conversion.
# @description Documents are converted with Asciidoctor and its diagram extension.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Convert AsciiDoc to HTML with diagram support.
#
# @arg $1 string AsciiDoc file.
# @arg $2 string Optional directory for the HTML. Defaults to the current directory.
# @exitcode 0 The HTML was written.
# @exitcode 64 The arguments are invalid or the file does not exist.
# @exitcode 69 asciidoctor is unavailable.
# @exitcode other The status of asciidoctor.
# @example
#   asciidoc::html docs/design.adoc build/html
asciidoc::html() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  docker::_run-command asciidoctor -r asciidoctor-diagram -b html5 -D "${2:-.}" "$1"
}
