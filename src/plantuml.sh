#!/usr/bin/env bash
# @file plantuml
# @brief PlantUML installation.
# @description PlantUML is installed from its releases.

# shellcheck disable=SC2119,SC2120

# @description Write PlantUML versions available to the current platform.
#
# @noargs
# @stdout PlantUML versions from the platform package manager, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   plantuml::versions
plantuml::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions plantuml
}

# @description Install PlantUML from the platform package manager.
#
# @arg $1 string Optional version from plantuml::versions. Defaults to the newest one.
# @exitcode 0 PlantUML is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   plantuml::install
#   plantuml -tsvg diagram.puml
plantuml::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version plantuml "${1:-}"
}
