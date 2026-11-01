#!/usr/bin/env bash
# @file jfrog
# @brief JFrog CLI installation and configuration.
# @description Server configurations are managed with jf config.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Remove one JFrog CLI server configuration.
#
# @arg $1 string Server ID.
# @exitcode 0 The configuration was removed.
# @exitcode 64 The argument count is not one.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config remove.
# @example
#   jfrog::config::clear artifactory-prod
jfrog::config::clear() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; docker::_run-command jf config remove "$1"; }

# @description Remove every JFrog CLI server configuration.
#
# @noargs
# @exitcode 0 Every configuration was removed.
# @exitcode 64 An argument was given.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config clean.
# @example
#   jfrog::config::clear-all
jfrog::config::clear-all() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command jf config clean; }

# @description Display JFrog CLI server configurations.
#
# @noargs
# @stdout The output of jf config show.
# @exitcode 0 The configurations were written.
# @exitcode 64 An argument was given.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config show.
# @example
#   jfrog::config::list
jfrog::config::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command jf config show; }

# @description Register and verify a JFrog CLI server.
#
# The access token is read from JFROG_ACCESS_TOKEN and passed to jf on standard input, never as an argument.
#
# @arg $1 string Server ID.
# @arg $2 string Platform URL, such as https://example.jfrog.io.
# @arg $3 string User name.
# @exitcode 0 The server was registered and answered ping.
# @exitcode 64 An argument is empty or JFROG_ACCESS_TOKEN is unset.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config add or jf rt ping.
# @example
#   JFROG_ACCESS_TOKEN="$(pass show jfrog/token)" jfrog::setup prod https://example.jfrog.io builder
jfrog::setup() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" && -n "${JFROG_ACCESS_TOKEN:-}" ]] || return 64
  command -v jf >/dev/null 2>&1 || return 69
  printf '%s\n' "$JFROG_ACCESS_TOKEN" |
    env -u JFROG_ACCESS_TOKEN jf config add "$1" \
      --url "$2" --user "$3" --access-token-stdin --interactive=false || return "$?"
  env -u JFROG_ACCESS_TOKEN jf rt ping --server-id "$1"
}
