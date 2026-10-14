#!/usr/bin/env bash
# @file git
# @brief Git history editing.
# @description git::commit::edit-via-rebase starts an interactive rebase that stops at one commit, without opening an editor for the todo list.

# shellcheck disable=SC2234


# @description Mark exactly one requested commit for editing in a Git rebase todo file.
# @internal
git::_sequence-editor() {
  if [[ "$#" -ne 1 || -z "${BASHSTOCK_GIT_EDIT_COMMIT:-}" ]] ||
    ! [[ "${BASHSTOCK_GIT_EDIT_COMMIT}" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]]; then
    return 64
  fi
  local file="$1" line='' candidate='' selected='' matches='0'
  file::_require-existing "${file}" || return "$?"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^(pick|p)[[:space:]]+([0-9a-f]+)([[:space:]]|$) ]]; then
      candidate="${BASH_REMATCH[2]}"
      if [[ "${BASHSTOCK_GIT_EDIT_COMMIT:0:${#candidate}}" == "${candidate}" ]]; then
        selected="${candidate}"
        matches=$((matches + 1))
      fi
    fi
  done <"${file}"
  [[ "${matches}" -eq 1 ]] || return 65
  file::replace-text "${file}" "^(pick|p)[[:space:]]+${selected}" "edit ${selected}"
}

# @description Start an interactive rebase that stops at one non-merge commit for editing.
#
# The todo list is prepared automatically, so Git stops at the commit without
# opening an editor. Amend it and run git rebase --continue afterwards.
#
# @arg $1 string Root or single-parent commit that is an ancestor of HEAD.
# @arg $2 string Optional Git working tree. Defaults to the current directory.
# @exitcode 0 The rebase stopped at the commit.
# @exitcode 64 The revision is empty, starts with a dash, or the argument count is wrong.
# @exitcode 65 The revision is not a commit, not an ancestor of HEAD, or a merge commit.
# @exitcode 66 The directory is not a Git working tree.
# @exitcode 69 Git is unavailable.
# @exitcode 75 Git could not read the commit's parents.
# @exitcode other The status of git rebase.
# @example
#   git::commit::edit-via-rebase HEAD~3
#   git commit --amend --no-edit --author 'Alice <alice@example.com>'
#   git rebase --continue
git::commit::edit-via-rebase() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]] ||
    ! string::_require-non-empty-line "$1" ||
    [[ "$1" == -* ]]; then
    return 64
  fi

  local revision="$1"
  local directory="${2:-.}"
  local commit=''
  local record=''
  local parts=()
  local parent=''
  local editor=''
  printf -v editor '%q %q --internal-git-sequence-editor' "${BASH}" "${_BASHSTOCK_FILE}"

  command::require git || return "$?"
  if [[ -z "${directory}" || ! -d "${directory}" ]]; then
    return 66
  fi
  if [[ "$(command git -C "${directory}" rev-parse \
    --is-inside-work-tree 2>/dev/null)" != 'true' ]]; then
    return 66
  fi

  commit="$(command git -C "${directory}" rev-parse \
    --verify "${revision}^{commit}" 2>/dev/null)" || return 65
  if ! ( [[ "${commit}" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] ); then
    return 65
  fi
  command git -C "${directory}" merge-base \
    --is-ancestor "${commit}" HEAD >/dev/null 2>&1 || return 65

  record="$(command git -C "${directory}" rev-list \
    --parents -n 1 "${commit}" 2>/dev/null)" || return 75
  IFS=' ' read -r -a parts <<<"${record}"
  case "${#parts[@]}" in
    1)
      BASHSTOCK_GIT_EDIT_COMMIT="${commit}" \
        GIT_SEQUENCE_EDITOR="${editor}" \
        command git -C "${directory}" rebase -i --root
      ;;
    2)
      parent="${parts[1]}"
      BASHSTOCK_GIT_EDIT_COMMIT="${commit}" \
        GIT_SEQUENCE_EDITOR="${editor}" \
        command git -C "${directory}" rebase -i "${parent}"
      ;;
    *)
      return 65
      ;;
  esac
}
