#!/usr/bin/env bash
# @file gerrit
# @brief Gerrit code review uploads.
# @description Changes are pushed from the current HEAD to refs/for.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Push the current HEAD to a Gerrit review reference.
#
# @arg $1 string Optional target branch of the review. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The review was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   gerrit::push-review main
gerrit::push-review() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_require-operands "${remote}" "${branch}" || return 64
  git::_run-in-directory "${directory}" push "${remote}" "HEAD:refs/for/${branch}"
}

# @description Push the current HEAD to a Gerrit review reference as work in progress.
#
# @arg $1 string Optional target branch of the review. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The review was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   gerrit::push-review-wip main
gerrit::push-review-wip() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_require-operands "${remote}" "${branch}" || return 64
  git::_run-in-directory "${directory}" push "${remote}" "HEAD:refs/for/${branch}%wip"
}
