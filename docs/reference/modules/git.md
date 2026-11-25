# git

Git repositories, history, configuration, and remotes.

## Overview

Functions wrap one git command each; git__commit__edit-via-rebase stops an interactive rebase at one commit without an editor.

## Index

* [git__commit__edit-via-rebase](#git__commit__edit-via-rebase)
* [git__clone-shallow](#git__clone-shallow)
* [git__rebase-abort](#git__rebase-abort)
* [git__rebase-continue](#git__rebase-continue)
* [git__commit__amend](#git__commit__amend)
* [git__commit__create](#git__commit__create)
* [git__commit__uncommit](#git__commit__uncommit)
* [git__branch__current](#git__branch__current)
* [git__branch__create](#git__branch__create)
* [git__branch__list](#git__branch__list)
* [git__diff__files](#git__diff__files)
* [git__diff__patch](#git__diff__patch)
* [git__diff__uncommitted-patch](#git__diff__uncommitted-patch)
* [git__diff__uncommitted-files](#git__diff__uncommitted-files)
* [git__diff__latest-patch](#git__diff__latest-patch)
* [git__diff__latest-files](#git__diff__latest-files)
* [git__commit__patch](#git__commit__patch)
* [git__commit__revert-without-commit](#git__commit__revert-without-commit)
* [git__commit__revert](#git__commit__revert)
* [git__fetch](#git__fetch)
* [git__fetch-unshallow](#git__fetch-unshallow)
* [git__stash__patch](#git__stash__patch)
* [git__stash__push](#git__stash__push)
* [git__stash__pop](#git__stash__pop)
* [git__stash__drop](#git__stash__drop)
* [git__reset](#git__reset)
* [git__pull-rebase](#git__pull-rebase)
* [git__cherry-pick](#git__cherry-pick)
* [git__cherry-pick-continue](#git__cherry-pick-continue)
* [git__cherry-pick-abort](#git__cherry-pick-abort)
* [git__push](#git__push)
* [git__push__force-with-lease](#git__push__force-with-lease)
* [git__remote__delete-branch](#git__remote__delete-branch)
* [git__submodule__update-all](#git__submodule__update-all)
* [git__commit__discard](#git__commit__discard)
* [git__reset-remote](#git__reset-remote)
* [git__pull-base-branch](#git__pull-base-branch)
* [git__rebase-base-branch](#git__rebase-base-branch)
* [git__credentials__remove](#git__credentials__remove)
* [git__config__enable-origin-all-fetch](#git__config__enable-origin-all-fetch)
* [git__config__enable-prune-fetch](#git__config__enable-prune-fetch)
* [git__config__set-default-branch](#git__config__set-default-branch)
* [git__config__enable-rebase-on-pull](#git__config__enable-rebase-on-pull)
* [git__config__set-email](#git__config__set-email)
* [git__config__set-username](#git__config__set-username)
* [git__config__set-http-buffer](#git__config__set-http-buffer)
* [git__config__use-gpg-credential-store](#git__config__use-gpg-credential-store)
* [git__config__use-credential-manager](#git__config__use-credential-manager)
* [git__config__use-osx-keychain](#git__config__use-osx-keychain)
* [git__config__setup](#git__config__setup)
* [git__stash__list](#git__stash__list)

### git__commit__edit-via-rebase

Start an interactive rebase that stops at one non-merge commit for editing.

The todo list is prepared automatically, so Git stops at the commit without
opening an editor. Amend it and run git rebase --continue afterwards.

A commit followed by a merge commit is refused, because the rebase would
flatten that merge.

#### Example

```bash
git__commit__edit-via-rebase HEAD~3
git commit --amend --no-edit --author 'Alice <alice@example.com>'
git rebase --continue
```

#### Arguments

* **$1** (string): Root or single-parent commit that is an ancestor of HEAD, with no merge commit after it.
* **$2** (string): Optional Git working tree. Defaults to the current directory.

#### Exit codes

* **0**: The rebase stopped at the commit.
* **64**: The revision is empty, starts with a dash, or the argument count is wrong.
* **65**: The revision is not a commit, not an ancestor of HEAD, a merge commit, or followed by a merge commit.
* **66**: The directory is not a Git working tree.
* **69**: Git is unavailable.
* **75**: Git could not read the commit's parents.
* other The status of git rebase.

### git__clone-shallow

Clone a repository with depth one.

#### Example

```bash
git__clone-shallow https://github.com/reconquest/shdoc.git --branch v1.4 vendor/shdoc
```

#### Options

* **--branch \<BRANCH\>**

  Branch or tag to check out.

#### Arguments

* **$1** (string): Repository URL.
* **$2** (string): Optional output directory. Defaults to the name Git derives from the URL.

#### Exit codes

* **0**: The repository was cloned.
* **64**: The arguments are invalid.
* other The status of git clone.

### git__rebase-abort

Abort an in-progress rebase.

#### Example

```bash
git__rebase-abort "${HOME}/src/project"
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The rebase was aborted.
* **64**: More than one argument was given.
* other The status of git rebase.

### git__rebase-continue

Continue an in-progress rebase.

#### Example

```bash
git add README.md && git__rebase-continue
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The rebase continued.
* **64**: More than one argument was given.
* other The status of git rebase.

### git__commit__amend

Amend the last commit without changing its message.

#### Example

```bash
git add README.md && git__commit__amend
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was amended.
* **64**: More than one argument was given.
* other The status of git commit.

### git__commit__create

Create a commit with a message.

#### Example

```bash
git add README.md && git__commit__create 'docs: describe the installer'
```

#### Arguments

* **$1** (string): Commit message.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was created.
* **64**: The argument count is not one or two.
* other The status of git commit.

### git__commit__uncommit

Remove the last commit while keeping its changes staged.

#### Example

```bash
git__commit__uncommit
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was removed.
* **64**: More than one argument was given.
* other The status of git reset.

### git__branch__current

Write the current branch name.

#### Example

```bash
branch="$(git__branch__current)"
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch name was written.
* **1**: HEAD is detached or the directory is not a repository.
* **64**: More than one argument was given.

#### Output on stdout

* The short name of the checked-out branch.

### git__branch__create

Create a branch at a starting revision.

#### Example

```bash
git__branch__create release/1.2 v1.2.0
```

#### Arguments

* **$1** (string): New branch name that git check-ref-format --branch accepts.
* **$2** (string): Optional starting revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was created.
* **64**: The argument count is not one to three, the name is invalid, or a value starts with -.
* other The status of git branch.

### git__branch__list

List local and remote-tracking branches.

#### Example

```bash
git__branch__list
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branches were written.
* **64**: More than one argument was given.
* other The status of git branch.

#### Output on stdout

* The output of git branch -a.

### git__diff__files

Show file names changed between two revisions.

#### Example

```bash
git__diff__files origin/main
```

#### Arguments

* **$1** (string): Base revision.
* **$2** (string): Optional target revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: The argument count is not one to three.
* other The status of git diff.

#### Output on stdout

* One changed path per line.

### git__diff__patch

Show a patch between two revisions.

#### Example

```bash
git__diff__patch v1.0.0 v1.1.0 > changes.patch
```

#### Arguments

* **$1** (string): Base revision.
* **$2** (string): Optional target revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: The argument count is not one to three.
* other The status of git diff.

#### Output on stdout

* The unified diff.

### git__diff__uncommitted-patch

Show the patch for uncommitted tracked changes.

#### Example

```bash
git__diff__uncommitted-patch > work.patch
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than one argument was given.
* other The status of git diff.

#### Output on stdout

* The unified diff of staged and unstaged tracked changes.

### git__diff__uncommitted-files

Show file names changed by uncommitted tracked changes.

#### Example

```bash
git__diff__uncommitted-files
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* other The status of git diff.

#### Output on stdout

* One changed path per line.

### git__diff__latest-patch

Show the patch introduced by the latest commit.

#### Example

```bash
git__diff__latest-patch > latest.patch
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than one argument was given.
* other The status of git show.

#### Output on stdout

* The unified diff of HEAD.

### git__diff__latest-files

Show file names changed by the latest commit.

#### Example

```bash
git__diff__latest-files
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* other The status of git show.

#### Output on stdout

* One changed path per line.

### git__commit__patch

Write the unified diff that one commit introduced.

The commit is fetched from REMOTE only when the repository lacks it, and it
is compared with its first parent, or with the empty tree for a root commit.
In a shallow clone, a parent beyond the shallow boundary is fetched as well.

#### Example

```bash
git__commit__patch 3ce3b61 > fix.patch
```

#### Arguments

* **$1** (string): Commit to show.
* **$2** (string): Optional remote to fetch a missing commit from. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: The arguments are invalid.
* **74**: The empty tree could not be computed.
* other The status of the git command that failed.

#### Output on stdout

* The unified diff of the commit.

### git__commit__revert-without-commit

Revert a commit without creating a commit.

#### Example

```bash
git__commit__revert-without-commit 3ce3b61
```

#### Arguments

* **$1** (string): Optional commit to revert. Defaults to HEAD.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were reverted in the working tree and index.
* **64**: More than two arguments were given.
* other The status of git revert.

### git__commit__revert

Revert a commit and create the revert commit.

#### Example

```bash
git__commit__revert 3ce3b61
```

#### Arguments

* **$1** (string): Optional commit to revert. Defaults to HEAD.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The revert commit was created.
* **64**: More than two arguments were given.
* other The status of git revert.

### git__fetch

Fetch one remote or all remotes.

#### Example

```bash
git__fetch upstream
```

#### Arguments

* **$1** (string): Optional remote. Defaults to every remote.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The fetch finished.
* **64**: More than two arguments were given.
* other The status of git fetch.

### git__fetch-unshallow

Convert a shallow clone into a complete history.

#### Example

```bash
git__fetch-unshallow origin
```

#### Arguments

* **$1** (string): Optional remote to fetch. Defaults to every remote.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The history is complete.
* **64**: More than two arguments were given.
* **66**: The repository has no remote.
* other The status of the git command that failed.

### git__stash__patch

Show a stash patch.

#### Example

```bash
git__stash__patch 'stash@{1}'
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than two arguments were given.
* other The status of git stash.

#### Output on stdout

* The unified diff of the stash.

### git__stash__push

Save tracked changes and untracked files in a new stash.

#### Example

```bash
git__stash__push 'before rebase'
```

#### Arguments

* **$1** (string): Optional stash message.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were stashed.
* **64**: More than two arguments were given.
* other The status of git stash.

### git__stash__pop

Apply and remove a stash.

#### Example

```bash
git__stash__pop
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stash was applied and removed.
* **64**: More than two arguments were given.
* other The status of git stash.

### git__stash__drop

Delete a stash.

#### Example

```bash
git__stash__drop 'stash@{2}'
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stash was deleted.
* **64**: More than two arguments were given.
* other The status of git stash.

### git__reset

Reset a working tree to a revision.

#### Example

```bash
git__fetch origin && git__reset origin/main
```

#### Arguments

* **$1** (string): Revision to reset to.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The working tree and index match the revision.
* **64**: The argument count is not one or two.
* other The status of git reset.

### git__pull-rebase

Update a branch from a remote with rebase.

#### Example

```bash
git__pull-rebase main upstream
```

#### Arguments

* **$1** (string): Optional remote branch to pull. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was updated.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git pull.

### git__cherry-pick

Apply one commit, fetching it from a remote only when the repository lacks it.

#### Example

```bash
git__cherry-pick 3ce3b61 upstream
```

#### Arguments

* **$1** (string): Commit to apply.
* **$2** (string): Optional remote to fetch a missing commit from. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was applied.
* **64**: The arguments are invalid.
* other The status of the git command that failed.

### git__cherry-pick-continue

Continue an in-progress cherry-pick.

#### Example

```bash
git add src/util.sh && git__cherry-pick-continue
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The cherry-pick continued.
* **64**: More than one argument was given.
* other The status of git cherry-pick.

### git__cherry-pick-abort

Abort an in-progress cherry-pick.

Untracked files left by the cherry-pick are stashed, or removed when stashing fails.

#### Example

```bash
git__cherry-pick-abort
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The cherry-pick was aborted.
* **64**: More than one argument was given.
* other The status of the git command that failed.

### git__push

Push a branch to a remote.

#### Example

```bash
git__push feature/login
```

#### Arguments

* **$1** (string): Optional branch. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### git__push__force-with-lease

Push a branch without overwriting a remote update.

#### Example

```bash
git rebase origin/main && git__push__force-with-lease
```

#### Arguments

* **$1** (string): Optional branch. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### git__remote__delete-branch

Delete a branch on a remote.

#### Example

```bash
git__remote__delete-branch feature/login
```

#### Arguments

* **$1** (string): Optional branch to delete. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The remote branch was deleted.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### git__submodule__update-all

Update all submodules recursively.

#### Example

```bash
git__submodule__update-all
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: Every submodule was initialized and updated.
* **64**: More than one argument was given.
* other The status of git submodule.

### git__commit__discard

Discard all changes in a working tree.

The changes, including untracked files, are first saved in a stash, and the branch is reset to the parent of HEAD.

#### Example

```bash
git__commit__discard
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were stashed and the latest commit was removed.
* **64**: More than one argument was given.
* other The status of the git command that failed, including when HEAD has no parent.

### git__reset-remote

Hard reset the current branch to the branch with the same name on a remote.

#### Example

```bash
git__reset-remote upstream
```

#### Arguments

* **$1** (string): Optional remote. Defaults to origin.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch matches the remote branch.
* **1**: HEAD is detached.
* **64**: More than two arguments were given.
* other The status of the git command that failed.

### git__pull-base-branch

Pull the configured base branch with fast-forward-only semantics.

The base branch is checked out and fast-forwarded from origin, and the original branch is then rebased onto it.

#### Example

```bash
git__pull-base-branch develop
```

#### Arguments

* **$1** (string): Optional base branch. Defaults to main.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The base branch was updated and the current branch was rebased.
* **64**: More than two arguments were given.
* **65**: HEAD is detached.
* **75**: The base branch could not be fast-forwarded, or the original branch could not be checked out again.
* other The status of git checkout or git rebase.

### git__rebase-base-branch

Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one.

#### Example

```bash
git__rebase-base-branch develop origin
```

#### Arguments

* **$1** (string): Optional base branch. Defaults to main.
* **$2** (string): Optional remote. Defaults to upstream.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was rebased.
* **64**: More than three arguments were given.
* other The status of the git command that failed.

### git__credentials__remove

Remove $HOME/.git-credentials and the global credential.helper; both may be absent.

#### Example

```bash
git__credentials__remove
```

_Function has no arguments._

#### Exit codes

* **0**: Neither the file nor the helper remains.
* **64**: An argument was given.
* other The status of git config or rm.

### git__config__enable-origin-all-fetch

Make origin fetch every branch in a repository.

#### Example

```bash
git__config__enable-origin-all-fetch && git__fetch origin
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The refspec was set.
* **64**: More than one argument was given.
* other The status of git config.

### git__config__enable-prune-fetch

Enable pruning on fetch in the global Git configuration.

#### Example

```bash
git__config__enable-prune-fetch
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git__config__set-default-branch

Set the default branch name of new repositories.

#### Example

```bash
git__config__set-default-branch trunk
```

#### Arguments

* **$1** (string): Optional branch name. Defaults to main.

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the name is not a valid branch name.
* other The status of git config.

### git__config__enable-rebase-on-pull

Enable rebase on pull in the global Git configuration.

#### Example

```bash
git__config__enable-rebase-on-pull
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git__config__set-email

Set the global Git email address.

#### Example

```bash
git__config__set-email developer@example.com
```

#### Arguments

* **$1** (string): Optional email address. Defaults to GIT_EMAIL, then to input from the controlling terminal.

#### Exit codes

* **0**: The address was set, or an existing one was kept.
* **64**: More than one argument was given or the value has several lines.
* **66**: No address is available and none is configured.
* **74**: The terminal could not be read.
* other The status of git config.

### git__config__set-username

Set the global Git user name.

#### Example

```bash
git__config__set-username 'Alex Example'
```

#### Arguments

* **$1** (string): Optional display name. Defaults to GIT_USERNAME, then to input from the controlling terminal.

#### Exit codes

* **0**: The name was set, or an existing one was kept.
* **64**: More than one argument was given or the value has several lines.
* **66**: No name is available and none is configured.
* **74**: The terminal could not be read.
* other The status of git config.

### git__config__set-http-buffer

Set the global Git HTTP post buffer.

#### Example

```bash
git__config__set-http-buffer 1048576000
```

#### Arguments

* **$1** (integer): Optional buffer size in bytes. Defaults to 524288000 (500 MiB).

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the size is not an integer.
* other The status of git config.

### git__config__use-gpg-credential-store

Make Git Credential Manager store credentials with GPG and pass.

The guidance for initializing the pass store is written to standard error.

#### Example

```bash
git__config__use-gpg-credential-store && pass__store__init
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

#### Output on stderr

* How to initialize the pass store.

### git__config__use-credential-manager

Use Git Credential Manager as the global credential helper.

Every existing credential.helper value is replaced, because
git-credential-manager configure adds an empty value and its own path, and
git config refuses to overwrite several values with one.

#### Example

```bash
git-credential-manager__install && git__config__use-credential-manager
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git__config__use-osx-keychain

Use the macOS Keychain as the global Git credential helper.

#### Example

```bash
git__config__use-osx-keychain
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of git config.

### git__config__setup

Apply the user identity and the standard global Git settings.

#### Example

```bash
git__config__setup developer@example.com 'Alex Example'
```

#### Arguments

* **$1** (string): Optional email address passed to git__config__set-email.
* **$2** (string): Optional display name passed to git__config__set-username.

#### Exit codes

* **0**: Every setting was applied.
* **64**: More than two arguments were given.
* other The status of the setting that failed.

### git__stash__list

List stashes.

#### Example

```bash
git__stash__list
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stashes were written.
* **64**: More than one argument was given.
* other The status of git stash.

#### Output on stdout

* The output of git stash list.

