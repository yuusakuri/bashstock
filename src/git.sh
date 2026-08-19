#!/usr/bin/env bash
# shellcheck disable=SC2234

### Start an interactive rebase that stops at one non-merge commit for editing.
###
### Arguments
###
### * REVISION - Root or single-parent commit that is an ancestor of HEAD.
### * DIRECTORY - Git working tree. Defaults to the current directory.
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
      PATH="${BASHSTOCK_ROOT}/libexec:${PATH}" \
        BASHSTOCK_GIT_EDIT_COMMIT="${commit}" \
        GIT_SEQUENCE_EDITOR='bashstock-git-sequence-editor' \
        command git -C "${directory}" rebase -i --root
      ;;
    2)
      parent="${parts[1]}"
      PATH="${BASHSTOCK_ROOT}/libexec:${PATH}" \
        BASHSTOCK_GIT_EDIT_COMMIT="${commit}" \
        GIT_SEQUENCE_EDITOR='bashstock-git-sequence-editor' \
        command git -C "${directory}" rebase -i "${parent}"
      ;;
    *)
      return 65
      ;;
  esac
}
