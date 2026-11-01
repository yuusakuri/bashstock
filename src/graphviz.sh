#!/usr/bin/env bash
# @file graphviz
# @brief Graphviz installation.
# @description Graphviz is installed from the platform package source.

# shellcheck disable=SC2119,SC2120

# @description Write Graphviz versions available to the current platform.
#
# @noargs
# @stdout Graphviz versions from the platform package manager, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   graphviz::versions
graphviz::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions graphviz
}

# @description Install Graphviz from the platform package manager.
#
# @arg $1 string Optional version from graphviz::versions. Defaults to the newest one.
# @exitcode 0 Graphviz is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   graphviz::install
#   dot -Tpng graph.dot -o graph.png
graphviz::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version graphviz "${1:-}"
}
