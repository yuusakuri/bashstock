#!/usr/bin/env bash
# @file git
# @brief Git repositories, history, configuration, and remotes.
# @description Functions wrap one git command each; git::commit::edit-via-rebase stops an interactive rebase at one commit without an editor.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2234,SC2317,SC2319,SC2329

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
# A commit followed by a merge commit is refused, because the rebase would
# flatten that merge.
#
# @arg $1 string Root or single-parent commit that is an ancestor of HEAD, with no merge commit after it.
# @arg $2 string Optional Git working tree. Defaults to the current directory.
# @exitcode 0 The rebase stopped at the commit.
# @exitcode 64 The revision is empty, starts with a dash, or the argument count is wrong.
# @exitcode 65 The revision is not a commit, not an ancestor of HEAD, a merge commit, or followed by a merge commit.
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
  # A plain rebase would flatten later merges, so such histories are refused.
  if [[ -n "$(command git -C "${directory}" rev-list \
    --merges -n 1 "${commit}..HEAD" 2>/dev/null)" ]]; then
    return 65
  fi

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

# @description Run a Git command in a working directory.
# @internal
git::_run-in-directory() { [[ "$#" -ge 2 && -d "$1" ]] || return 64; local directory="$1"; shift; command git -C "$directory" "$@"; }

# @description Require operands that Git cannot read as options: not empty and not starting with -.
# @internal
git::_require-operands() {
  local operand=''
  for operand in "$@"; do
    [[ -n "${operand}" && "${operand}" != -* ]] || return 64
  done
}

# @description Clone a repository with depth one.
#
# @arg $1 string Repository URL.
# @arg $2 string Optional output directory. Defaults to the name Git derives from the URL.
# @option --branch <BRANCH> Branch or tag to check out.
# @exitcode 0 The repository was cloned.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of git clone.
# @example
#   git::clone-shallow https://github.com/reconquest/shdoc.git --branch v1.4 vendor/shdoc
git::clone-shallow() { [[ "$#" -ge 1 && "$#" -le 4 ]] || return 64; local url="$1" dir='' branch='' args=(); shift; while [[ "$#" -gt 0 ]]; do case "$1" in --branch) [[ "$#" -ge 2 ]] || return 64; branch="$2"; shift 2 ;; *) [[ -z "$dir" ]] || return 64; dir="$1"; shift ;; esac; done; args=(clone --depth 1); [[ -n "$branch" ]] && args+=(--branch "$branch"); args+=("$url"); [[ -n "$dir" ]] && args+=("$dir"); command git "${args[@]}"; }

# @description List the named arguments of git::clone-shallow.
# @internal
git::_clone-shallow-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --branch; fi
}

# @description Abort an in-progress rebase.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The rebase was aborted.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git rebase.
# @example
#   git::rebase-abort "${HOME}/src/project"
git::rebase-abort() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" rebase --abort; }

# @description Continue an in-progress rebase.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The rebase continued.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git rebase.
# @example
#   git add README.md && git::rebase-continue
git::rebase-continue() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" rebase --continue; }

# @description Amend the last commit without changing its message.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was amended.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git commit.
# @example
#   git add README.md && git::commit::amend
git::commit::amend() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" commit --amend --no-edit; }

# @description Create a commit with a message.
#
# @arg $1 string Commit message.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was created.
# @exitcode 64 The argument count is not one or two.
# @exitcode other The status of git commit.
# @example
#   git add README.md && git::commit::create 'docs: describe the installer'
git::commit::create() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" commit -m "$1"; }

# @description Remove the last commit while keeping its changes staged.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was removed.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git reset.
# @example
#   git::commit::uncommit
git::commit::uncommit() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" reset --soft HEAD^; }

# @description Write the current branch name.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The short name of the checked-out branch.
# @exitcode 0 The branch name was written.
# @exitcode 1 HEAD is detached or the directory is not a repository.
# @exitcode 64 More than one argument was given.
# @example
#   branch="$(git::branch::current)"
git::branch::current() { [[ "$#" -le 1 ]] || return 64; local branch=''; branch="$(git::_run-in-directory "${1:-.}" symbolic-ref --quiet --short HEAD 2>/dev/null)" || return 1; [[ -n "$branch" ]] && printf '%s\n' "$branch"; }

# @description Create a branch at a starting revision.
#
# @arg $1 string New branch name that git check-ref-format --branch accepts.
# @arg $2 string Optional starting revision. Defaults to HEAD.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was created.
# @exitcode 64 The argument count is not one to three, the name is invalid, or a value starts with -.
# @exitcode other The status of git branch.
# @example
#   git::branch::create release/1.2 v1.2.0
git::branch::create() {
  [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64
  # A name such as -D would make git branch delete a branch instead.
  git::_require-operands "$1" "${2:-HEAD}" || return 64
  command git check-ref-format --branch "$1" >/dev/null 2>&1 || return 64
  git::_run-in-directory "${3:-.}" branch "$1" "${2:-HEAD}"
}

# @description List local and remote-tracking branches.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The output of git branch -a.
# @exitcode 0 The branches were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git branch.
# @example
#   git::branch::list
git::branch::list() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" branch -a; }

# @description Show file names changed between two revisions.
#
# @arg $1 string Base revision.
# @arg $2 string Optional target revision. Defaults to HEAD.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @stdout One changed path per line.
# @exitcode 0 The paths were written.
# @exitcode 64 The argument count is not one to three.
# @exitcode other The status of git diff.
# @example
#   git::diff::files origin/main
git::diff::files() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" diff --name-only "$1" "${2:-HEAD}"; }

# @description Show a patch between two revisions.
#
# @arg $1 string Base revision.
# @arg $2 string Optional target revision. Defaults to HEAD.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff.
# @exitcode 0 The patch was written.
# @exitcode 64 The argument count is not one to three.
# @exitcode other The status of git diff.
# @example
#   git::diff::patch v1.0.0 v1.1.0 > changes.patch
git::diff::patch() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" diff "$1" "${2:-HEAD}"; }

# @description Show the patch for uncommitted tracked changes.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of staged and unstaged tracked changes.
# @exitcode 0 The patch was written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git diff.
# @example
#   git::diff::uncommitted-patch > work.patch
git::diff::uncommitted-patch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" diff HEAD; }

# @description Show file names changed by uncommitted tracked changes.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout One changed path per line.
# @exitcode 0 The paths were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git diff.
# @example
#   git::diff::uncommitted-files
git::diff::uncommitted-files() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" diff --name-only HEAD; }

# @description Show the patch introduced by the latest commit.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of HEAD.
# @exitcode 0 The patch was written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git show.
# @example
#   git::diff::latest-patch > latest.patch
git::diff::latest-patch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" show --format= --patch HEAD; }

# @description Show file names changed by the latest commit.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout One changed path per line.
# @exitcode 0 The paths were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git show.
# @example
#   git::diff::latest-files
git::diff::latest-files() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" show --format= --name-only HEAD; }

# @description Write the unified diff that one commit introduced.
#
# The commit is fetched from REMOTE only when the repository lacks it, and it
# is compared with its first parent, or with the empty tree for a root commit.
# In a shallow clone, a parent beyond the shallow boundary is fetched as well.
#
# @arg $1 string Commit to show.
# @arg $2 string Optional remote to fetch a missing commit from. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of the commit.
# @exitcode 0 The patch was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The empty tree could not be computed.
# @exitcode other The status of the git command that failed.
# @example
#   git::commit::patch 3ce3b61 > fix.patch
git::commit::patch() {
  [[ "$#" -ge 1 && "$#" -le 3 && -n "$1" ]] || return 64
  local revision="$1" remote="${2:-origin}" directory="${3:-.}" parent='' empty_tree='' object=''
  git::_require-commit "${revision}" "${remote}" "${directory}" || return "$?"
  # The commit object names its parents even at a shallow boundary, where
  # rev-parse would report none.
  object="$(git::_run-in-directory "${directory}" cat-file commit "${revision}")" || return "$?"
  parent="$(awk '/^$/ { exit } $1 == "parent" { print $2; exit }' <<<"${object}")"
  if [[ -n "${parent}" ]]; then
    git::_require-commit "${parent}" "${remote}" "${directory}" || return "$?"
  else
    empty_tree="$(git::_run-in-directory "${directory}" hash-object -t tree /dev/null)" || return 74
    parent="${empty_tree}"
  fi
  git::_run-in-directory "${directory}" diff "${parent}" "${revision}"
}

# @description Make a commit available locally, fetching it from a remote only when it is missing.
# @internal
# @exitcode 1 The remote does not provide the commit either.
# @exitcode 69 The fetch from the remote failed.
git::_require-commit() {
  [[ "$#" -eq 3 ]] || return 64
  local revision="$1" remote="$2" directory="$3"
  git::_require-operands "${revision}" "${remote}" || return 64
  git::_run-in-directory "${directory}" cat-file -e "${revision}^{commit}" 2>/dev/null && return 0
  git::_run-in-directory "${directory}" fetch "${remote}" "${revision}" || return 69
  if ! git::_run-in-directory "${directory}" cat-file -e "${revision}^{commit}" 2>/dev/null; then
    console::_write-error "Commit ${revision} is not available from ${remote}."
    return 1
  fi
}

# @description Revert a commit without creating a commit.
#
# @arg $1 string Optional commit to revert. Defaults to HEAD.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The changes were reverted in the working tree and index.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git revert.
# @example
#   git::commit::revert-without-commit 3ce3b61
git::commit::revert-without-commit() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" revert --no-commit "${1:-HEAD}"; }

# @description Revert a commit and create the revert commit.
#
# @arg $1 string Optional commit to revert. Defaults to HEAD.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The revert commit was created.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git revert.
# @example
#   git::commit::revert 3ce3b61
git::commit::revert() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" revert "${1:-HEAD}"; }

# @description Fetch one remote or all remotes.
#
# @arg $1 string Optional remote. Defaults to every remote.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The fetch finished.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git fetch.
# @example
#   git::fetch upstream
git::fetch() { [[ "$#" -le 2 ]] || return 64; local remote="${1:-}" directory="${2:-.}"; if [[ -n "$remote" ]]; then git::_run-in-directory "$directory" fetch "$remote"; else git::_run-in-directory "$directory" fetch --all; fi; }

# @description Convert a shallow clone into a complete history.
#
# @arg $1 string Optional remote to fetch. Defaults to every remote.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The history is complete.
# @exitcode 64 More than two arguments were given.
# @exitcode 66 The repository has no remote.
# @exitcode other The status of the git command that failed.
# @example
#   git::fetch-unshallow origin
git::fetch-unshallow() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${2:-.}" remote='' remotes=''
  if [[ -n "${1:-}" ]]; then
    remotes="$1"
  else
    remotes="$(git::_run-in-directory "${directory}" remote)" || return "$?"
    [[ -n "${remotes}" ]] || return 66
  fi
  while IFS= read -r remote; do
    git::_require-operands "${remote}" || return 64
    # Only the first fetch can unshallow; later remotes complete normally.
    if [[ "$(git::_run-in-directory "${directory}" rev-parse --is-shallow-repository)" == true ]]; then
      git::_run-in-directory "${directory}" fetch --unshallow "${remote}" || return "$?"
    else
      git::_run-in-directory "${directory}" fetch "${remote}" || return "$?"
    fi
  done <<<"${remotes}"
}

# @description Show a stash patch.
#
# @arg $1 string Optional stash. Defaults to stash@{0}.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of the stash.
# @exitcode 0 The patch was written.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::patch 'stash@{1}'
git::stash::patch() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash show --patch "${1:-stash@{0}}"; }

# @description Save tracked changes and untracked files in a new stash.
#
# @arg $1 string Optional stash message.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The changes were stashed.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::push 'before rebase'
git::stash::push() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${2:-.}"
  local arguments=(stash push --include-untracked)
  [[ -z "${1:-}" ]] || arguments+=(-m "$1")
  git::_run-in-directory "${directory}" "${arguments[@]}"
}

# @description Apply and remove a stash.
#
# @arg $1 string Optional stash. Defaults to stash@{0}.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The stash was applied and removed.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::pop
git::stash::pop() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash pop "${1:-stash@{0}}"; }

# @description Delete a stash.
#
# @arg $1 string Optional stash. Defaults to stash@{0}.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The stash was deleted.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::drop 'stash@{2}'
git::stash::drop() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash drop "${1:-stash@{0}}"; }

# @description Reset a working tree to a revision.
#
# @arg $1 string Revision to reset to.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The working tree and index match the revision.
# @exitcode 64 The argument count is not one or two.
# @exitcode other The status of git reset.
# @example
#   git::fetch origin && git::reset origin/main
git::reset() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; git::_require-operands "$1" || return 64; git::_run-in-directory "${2:-.}" reset --hard "$1" --; }

# @description Update a branch from a remote with rebase.
#
# @arg $1 string Optional remote branch to pull. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was updated.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git pull.
# @example
#   git::pull-rebase main upstream
git::pull-rebase() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_require-operands "${remote}" "${branch}" || return 64
  git::_run-in-directory "${directory}" pull --rebase "${remote}" "${branch}"
}

# @description Apply one commit, fetching it from a remote only when the repository lacks it.
#
# @arg $1 string Commit to apply.
# @arg $2 string Optional remote to fetch a missing commit from. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was applied.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of the git command that failed.
# @example
#   git::cherry-pick 3ce3b61 upstream
git::cherry-pick() {
  [[ "$#" -ge 1 && "$#" -le 3 && -n "$1" ]] || return 64
  local revision="$1" remote="${2:-origin}" directory="${3:-.}"
  git::_require-commit "${revision}" "${remote}" "${directory}" || return "$?"
  git::_run-in-directory "${directory}" cherry-pick "${revision}"
}

# @description Continue an in-progress cherry-pick.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The cherry-pick continued.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git cherry-pick.
# @example
#   git add src/util.sh && git::cherry-pick-continue
git::cherry-pick-continue() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" cherry-pick --continue; }

# @description Abort an in-progress cherry-pick.
#
# Untracked files left by the cherry-pick are stashed, or removed when stashing fails.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The cherry-pick was aborted.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of the git command that failed.
# @example
#   git::cherry-pick-abort
git::cherry-pick-abort() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-.}" path=''
  local untracked=()
  git::_run-in-directory "$directory" cherry-pick --abort || return "$?"
  while IFS= read -r -d '' path; do untracked+=("$path"); done \
    < <(git::_run-in-directory "$directory" ls-files --others --exclude-standard -z)
  [[ "${#untracked[@]}" -gt 0 ]] || return 0
  git::_run-in-directory "$directory" stash push --include-untracked -- "${untracked[@]}" && return 0
  git::_run-in-directory "$directory" clean -fd
}

# @description Push a branch to a remote.
#
# @arg $1 string Optional branch. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   git::push feature/login
git::push() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "$branch" ]] || branch="$(git::branch::current "$directory")" || return "$?"
  git::_run-in-directory "$directory" push "$remote" "$branch"
}

# @description Push a branch without overwriting a remote update.
#
# @arg $1 string Optional branch. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   git rebase origin/main && git::push::force-with-lease
git::push::force-with-lease() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "$branch" ]] || branch="$(git::branch::current "$directory")" || return "$?"
  git::_run-in-directory "$directory" push --force-with-lease "$remote" "$branch"
}

# @description Delete a branch on a remote.
#
# @arg $1 string Optional branch to delete. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The remote branch was deleted.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   git::remote::delete-branch feature/login
git::remote::delete-branch() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_require-operands "${remote}" "${branch}" || return 64
  git::_run-in-directory "${directory}" push "${remote}" --delete "${branch}"
}

# @description Update all submodules recursively.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 Every submodule was initialized and updated.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git submodule.
# @example
#   git::submodule::update-all
git::submodule::update-all() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" submodule update --init --recursive; }

# @description Discard all changes in a working tree.
#
# The changes, including untracked files, are first saved in a stash, and the branch is reset to the parent of HEAD.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The changes were stashed and the latest commit was removed.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of the git command that failed, including when HEAD has no parent.
# @example
#   git::commit::discard
git::commit::discard() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-.}"
  git::_run-in-directory "$directory" rev-parse --verify 'HEAD^' >/dev/null || return "$?"
  git::_run-in-directory "$directory" stash push --include-untracked || return "$?"
  git::_run-in-directory "$directory" reset --hard HEAD^
}

# @description Hard reset the current branch to the branch with the same name on a remote.
#
# @arg $1 string Optional remote. Defaults to origin.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch matches the remote branch.
# @exitcode 1 HEAD is detached.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of the git command that failed.
# @example
#   git::reset-remote upstream
git::reset-remote() {
  [[ "$#" -le 2 ]] || return 64
  local remote="${1:-origin}" directory="${2:-.}" branch=''
  branch="$(git::branch::current "${directory}")" || return "$?"
  git::_require-operands "${remote}" || return 64
  git::_run-in-directory "${directory}" fetch "${remote}" || return "$?"
  git::_run-in-directory "${directory}" reset --hard "${remote}/${branch}" --
}

# @description Pull the configured base branch with fast-forward-only semantics.
#
# The base branch is checked out and fast-forwarded from origin, and the original branch is then rebased onto it.
#
# @arg $1 string Optional base branch. Defaults to main.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The base branch was updated and the current branch was rebased.
# @exitcode 64 More than two arguments were given.
# @exitcode 65 HEAD is detached.
# @exitcode 75 The base branch could not be fast-forwarded, or the original branch could not be checked out again.
# @exitcode other The status of git checkout or git rebase.
# @example
#   git::pull-base-branch develop
git::pull-base-branch() { [[ "$#" -le 2 ]] || return 64; local base="${1:-main}" directory="${2:-.}" current=''; current="$(git::branch::current "$directory")" || return 65; git::_run-in-directory "$directory" checkout "$base" -- || return "$?"; if ! git::_run-in-directory "$directory" pull --ff-only origin "$base"; then git::_run-in-directory "$directory" checkout "$current" -- >/dev/null 2>&1 || true; return 75; fi; git::_run-in-directory "$directory" checkout "$current" -- || return 75; git::_run-in-directory "$directory" rebase "$base"; }

# @description Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one.
#
# @arg $1 string Optional base branch. Defaults to main.
# @arg $2 string Optional remote. Defaults to upstream.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was rebased.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of the git command that failed.
# @example
#   git::rebase-base-branch develop origin
git::rebase-base-branch() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-main}" remote="${2:-upstream}" directory="${3:-.}"
  git::_require-operands "${branch}" "${remote}" || return 64
  git::_run-in-directory "${directory}" fetch "${remote}" || return "$?"
  git::_run-in-directory "${directory}" checkout "${branch}" -- || return "$?"
  git::_run-in-directory "${directory}" rebase "${remote}/${branch}"
}

# @description Remove $HOME/.git-credentials and the global credential.helper; both may be absent.
#
# @noargs
# @exitcode 0 Neither the file nor the helper remains.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config or rm.
# @example
#   git::credentials::remove
git::credentials::remove() {
  [[ "$#" -eq 0 ]] || return 64
  if git config --global --get-all credential.helper >/dev/null 2>&1; then
    git config --global --unset-all credential.helper || return "$?"
  fi
  rm -f -- "$HOME/.git-credentials"
}

# @description Make origin fetch every branch in a repository.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The refspec was set.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::enable-origin-all-fetch && git::fetch origin
git::config::enable-origin-all-fetch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; }

# @description Enable pruning on fetch in the global Git configuration.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::enable-prune-fetch
git::config::enable-prune-fetch() { [[ "$#" -eq 0 ]] || return 64; git config --global fetch.prune true; }

# @description Set the default branch name of new repositories.
#
# @arg $1 string Optional branch name. Defaults to main.
# @exitcode 0 The setting was written.
# @exitcode 64 More than one argument was given or the name is not a valid branch name.
# @exitcode other The status of git config.
# @example
#   git::config::set-default-branch trunk
git::config::set-default-branch() {
  [[ "$#" -le 1 ]] || return 64
  local branch="${1:-main}"
  git check-ref-format --branch "${branch}" >/dev/null 2>&1 || return 64
  git config --global init.defaultBranch "${branch}"
}

# @description Enable rebase on pull in the global Git configuration.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::enable-rebase-on-pull
git::config::enable-rebase-on-pull() { [[ "$#" -eq 0 ]] || return 64; git config --global pull.rebase true; }

# @description Set the global Git email address.
#
# @arg $1 string Optional email address. Defaults to GIT_EMAIL, then to input from the controlling terminal.
# @exitcode 0 The address was set, or an existing one was kept.
# @exitcode 64 More than one argument was given or the value has several lines.
# @exitcode 66 No address is available and none is configured.
# @exitcode 74 The terminal could not be read.
# @exitcode other The status of git config.
# @example
#   git::config::set-email developer@example.com
git::config::set-email() {
  [[ "$#" -le 1 ]] || return 64
  git::config::_set-identity user.email "${1:-}" GIT_EMAIL 'email address'
}

# @description Read a Git identity value from an argument, an environment variable, or the terminal.
#
# The current global value is kept when none of these sources is available.
# @internal
git::config::_set-identity() {
  [[ "$#" -eq 4 ]] || return 64
  local key="$1" value="$2" variable="$3" label="$4"
  [[ -n "${value}" ]] || value="${!variable:-}"
  if [[ -z "${value}" ]] && terminal::is-available; then
    printf 'Git %s: ' "${label}" >/dev/tty
    IFS= read -r value </dev/tty || return 74
  fi
  if [[ -z "${value}" ]]; then
    git config --global --get "${key}" >/dev/null && return 0
    console::_write-error "Set the Git ${label} with an argument or ${variable}."
    return 66
  fi
  string::_require-one-line "${value}" || return "$?"
  git config --global "${key}" "${value}"
}

# @description Set the global Git user name.
#
# @arg $1 string Optional display name. Defaults to GIT_USERNAME, then to input from the controlling terminal.
# @exitcode 0 The name was set, or an existing one was kept.
# @exitcode 64 More than one argument was given or the value has several lines.
# @exitcode 66 No name is available and none is configured.
# @exitcode 74 The terminal could not be read.
# @exitcode other The status of git config.
# @example
#   git::config::set-username 'Alex Example'
git::config::set-username() {
  [[ "$#" -le 1 ]] || return 64
  git::config::_set-identity user.name "${1:-}" GIT_USERNAME 'user name'
}

# @description Set the global Git HTTP post buffer.
#
# @arg $1 integer Optional buffer size in bytes. Defaults to 524288000 (500 MiB).
# @exitcode 0 The setting was written.
# @exitcode 64 More than one argument was given or the size is not an integer.
# @exitcode other The status of git config.
# @example
#   git::config::set-http-buffer 1048576000
git::config::set-http-buffer() {
  [[ "$#" -le 1 ]] || return 64
  local size="${1:-524288000}"
  ( [[ "${size}" =~ ^(0|[1-9][0-9]*)$ ]] ) || return 64
  git config --global http.postBuffer "${size}"
}

# @description Make Git Credential Manager store credentials with GPG and pass.
#
# The guidance for initializing the pass store is written to standard error.
#
# @noargs
# @stderr How to initialize the pass store.
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::use-gpg-credential-store && pass::store::init
git::config::use-gpg-credential-store() {
  [[ "$#" -eq 0 ]] || return 64
  git config --global credential.credentialStore gpg || return "$?"
  console::_write-error 'Git Credential Manager now stores credentials with pass; initialize it with pass::store::init FINGERPRINT.'
}

# @description Use Git Credential Manager as the global credential helper.
#
# Every existing credential.helper value is replaced, because
# git-credential-manager configure adds an empty value and its own path, and
# git config refuses to overwrite several values with one.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git-credential-manager::install && git::config::use-credential-manager
git::config::use-credential-manager() {
  [[ "$#" -eq 0 ]] || return 64
  git config --global --replace-all credential.helper manager
}

# @description Use the macOS Keychain as the global Git credential helper.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of git config.
# @example
#   git::config::use-osx-keychain
git::config::use-osx-keychain() { [[ "$#" -eq 0 ]] || return 64; [[ "$(system::operating-system)" == darwin ]] || return 69; git config --global credential.helper osxkeychain; }

# @description Apply the user identity and the standard global Git settings.
#
# @arg $1 string Optional email address passed to git::config::set-email.
# @arg $2 string Optional display name passed to git::config::set-username.
# @exitcode 0 Every setting was applied.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of the setting that failed.
# @example
#   git::config::setup developer@example.com 'Alex Example'
git::config::setup() {
  [[ "$#" -le 2 ]] || return 64
  git::config::set-email "${1:-}" || return "$?"
  git::config::set-username "${2:-}" || return "$?"
  git::config::set-default-branch main || return "$?"
  git::config::enable-rebase-on-pull || return "$?"
  git::config::enable-prune-fetch
}

# @description List stashes.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The output of git stash list.
# @exitcode 0 The stashes were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git stash.
# @example
#   git::stash::list
git::stash::list() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" stash list; }
