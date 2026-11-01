# git

Git repositories, history, configuration, and remotes.

## Overview

Functions wrap one git command each; git::commit::edit-via-rebase stops an interactive rebase at one commit without an editor.

## Index

* [git::commit::edit-via-rebase](#gitcommitedit-via-rebase)
* [git::clone-shallow](#gitclone-shallow)
* [git::rebase-abort](#gitrebase-abort)
* [git::rebase-continue](#gitrebase-continue)
* [git::commit::amend](#gitcommitamend)
* [git::commit::create](#gitcommitcreate)
* [git::commit::uncommit](#gitcommituncommit)
* [git::branch::current](#gitbranchcurrent)
* [git::branch::create](#gitbranchcreate)
* [git::branch::list](#gitbranchlist)
* [git::diff::files](#gitdifffiles)
* [git::diff::patch](#gitdiffpatch)
* [git::diff::uncommitted-patch](#gitdiffuncommitted-patch)
* [git::diff::uncommitted-files](#gitdiffuncommitted-files)
* [git::diff::latest-patch](#gitdifflatest-patch)
* [git::diff::latest-files](#gitdifflatest-files)
* [git::commit::patch](#gitcommitpatch)
* [git::commit::revert-without-commit](#gitcommitrevert-without-commit)
* [git::commit::revert](#gitcommitrevert)
* [git::fetch](#gitfetch)
* [git::fetch-unshallow](#gitfetch-unshallow)
* [git::stash::patch](#gitstashpatch)
* [git::stash::push](#gitstashpush)
* [git::stash::pop](#gitstashpop)
* [git::stash::drop](#gitstashdrop)
* [git::reset](#gitreset)
* [git::pull-rebase](#gitpull-rebase)
* [git::cherry-pick](#gitcherry-pick)
* [git::cherry-pick-continue](#gitcherry-pick-continue)
* [git::cherry-pick-abort](#gitcherry-pick-abort)
* [git::push](#gitpush)
* [git::push::force-with-lease](#gitpushforce-with-lease)
* [git::remote::delete-branch](#gitremotedelete-branch)
* [git::submodule::update-all](#gitsubmoduleupdate-all)
* [git::commit::discard](#gitcommitdiscard)
* [git::reset-remote](#gitreset-remote)
* [git::pull-base-branch](#gitpull-base-branch)
* [git::rebase-base-branch](#gitrebase-base-branch)
* [git::credentials::remove](#gitcredentialsremove)
* [git::config::enable-origin-all-fetch](#gitconfigenable-origin-all-fetch)
* [git::config::enable-prune-fetch](#gitconfigenable-prune-fetch)
* [git::config::set-default-branch](#gitconfigset-default-branch)
* [git::config::enable-rebase-on-pull](#gitconfigenable-rebase-on-pull)
* [git::config::set-email](#gitconfigset-email)
* [git::config::set-username](#gitconfigset-username)
* [git::config::set-http-buffer](#gitconfigset-http-buffer)
* [git::config::use-gpg-credential-store](#gitconfiguse-gpg-credential-store)
* [git::config::use-credential-manager](#gitconfiguse-credential-manager)
* [git::config::use-osx-keychain](#gitconfiguse-osx-keychain)
* [git::config::setup](#gitconfigsetup)
* [git::stash::list](#gitstashlist)

### git::commit::edit-via-rebase

Start an interactive rebase that stops at one non-merge commit for editing.

The todo list is prepared automatically, so Git stops at the commit without
opening an editor. Amend it and run git rebase --continue afterwards.

A commit followed by a merge commit is refused, because the rebase would
flatten that merge.

#### Example

```bash
git::commit::edit-via-rebase HEAD~3
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

### git::clone-shallow

Clone a repository with depth one.

#### Example

```bash
git::clone-shallow https://github.com/reconquest/shdoc.git --branch v1.4 vendor/shdoc
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

### git::rebase-abort

Abort an in-progress rebase.

#### Example

```bash
git::rebase-abort "${HOME}/src/project"
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The rebase was aborted.
* **64**: More than one argument was given.
* other The status of git rebase.

### git::rebase-continue

Continue an in-progress rebase.

#### Example

```bash
git add README.md && git::rebase-continue
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The rebase continued.
* **64**: More than one argument was given.
* other The status of git rebase.

### git::commit::amend

Amend the last commit without changing its message.

#### Example

```bash
git add README.md && git::commit::amend
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was amended.
* **64**: More than one argument was given.
* other The status of git commit.

### git::commit::create

Create a commit with a message.

#### Example

```bash
git add README.md && git::commit::create 'docs: describe the installer'
```

#### Arguments

* **$1** (string): Commit message.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was created.
* **64**: The argument count is not one or two.
* other The status of git commit.

### git::commit::uncommit

Remove the last commit while keeping its changes staged.

#### Example

```bash
git::commit::uncommit
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was removed.
* **64**: More than one argument was given.
* other The status of git reset.

### git::branch::current

Write the current branch name.

#### Example

```bash
branch="$(git::branch::current)"
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch name was written.
* **1**: HEAD is detached or the directory is not a repository.
* **64**: More than one argument was given.

#### Output on stdout

* The short name of the checked-out branch.

### git::branch::create

Create a branch at a starting revision.

#### Example

```bash
git::branch::create release/1.2 v1.2.0
```

#### Arguments

* **$1** (string): New branch name that git check-ref-format --branch accepts.
* **$2** (string): Optional starting revision. Defaults to HEAD.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was created.
* **64**: The argument count is not one to three, the name is invalid, or a value starts with -.
* other The status of git branch.

### git::branch::list

List local and remote-tracking branches.

#### Example

```bash
git::branch::list
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branches were written.
* **64**: More than one argument was given.
* other The status of git branch.

#### Output on stdout

* The output of git branch -a.

### git::diff::files

Show file names changed between two revisions.

#### Example

```bash
git::diff::files origin/main
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

### git::diff::patch

Show a patch between two revisions.

#### Example

```bash
git::diff::patch v1.0.0 v1.1.0 > changes.patch
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

### git::diff::uncommitted-patch

Show the patch for uncommitted tracked changes.

#### Example

```bash
git::diff::uncommitted-patch > work.patch
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than one argument was given.
* other The status of git diff.

#### Output on stdout

* The unified diff of staged and unstaged tracked changes.

### git::diff::uncommitted-files

Show file names changed by uncommitted tracked changes.

#### Example

```bash
git::diff::uncommitted-files
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* other The status of git diff.

#### Output on stdout

* One changed path per line.

### git::diff::latest-patch

Show the patch introduced by the latest commit.

#### Example

```bash
git::diff::latest-patch > latest.patch
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The patch was written.
* **64**: More than one argument was given.
* other The status of git show.

#### Output on stdout

* The unified diff of HEAD.

### git::diff::latest-files

Show file names changed by the latest commit.

#### Example

```bash
git::diff::latest-files
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* other The status of git show.

#### Output on stdout

* One changed path per line.

### git::commit::patch

Write the unified diff that one commit introduced.

The commit is fetched from REMOTE only when the repository lacks it, and it
is compared with its first parent, or with the empty tree for a root commit.
In a shallow clone, a parent beyond the shallow boundary is fetched as well.

#### Example

```bash
git::commit::patch 3ce3b61 > fix.patch
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

### git::commit::revert-without-commit

Revert a commit without creating a commit.

#### Example

```bash
git::commit::revert-without-commit 3ce3b61
```

#### Arguments

* **$1** (string): Optional commit to revert. Defaults to HEAD.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were reverted in the working tree and index.
* **64**: More than two arguments were given.
* other The status of git revert.

### git::commit::revert

Revert a commit and create the revert commit.

#### Example

```bash
git::commit::revert 3ce3b61
```

#### Arguments

* **$1** (string): Optional commit to revert. Defaults to HEAD.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The revert commit was created.
* **64**: More than two arguments were given.
* other The status of git revert.

### git::fetch

Fetch one remote or all remotes.

#### Example

```bash
git::fetch upstream
```

#### Arguments

* **$1** (string): Optional remote. Defaults to every remote.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The fetch finished.
* **64**: More than two arguments were given.
* other The status of git fetch.

### git::fetch-unshallow

Convert a shallow clone into a complete history.

#### Example

```bash
git::fetch-unshallow origin
```

#### Arguments

* **$1** (string): Optional remote to fetch. Defaults to every remote.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The history is complete.
* **64**: More than two arguments were given.
* **66**: The repository has no remote.
* other The status of the git command that failed.

### git::stash::patch

Show a stash patch.

#### Example

```bash
git::stash::patch 'stash@{1}'
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

### git::stash::push

Save tracked changes and untracked files in a new stash.

#### Example

```bash
git::stash::push 'before rebase'
```

#### Arguments

* **$1** (string): Optional stash message.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were stashed.
* **64**: More than two arguments were given.
* other The status of git stash.

### git::stash::pop

Apply and remove a stash.

#### Example

```bash
git::stash::pop
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stash was applied and removed.
* **64**: More than two arguments were given.
* other The status of git stash.

### git::stash::drop

Delete a stash.

#### Example

```bash
git::stash::drop 'stash@{2}'
```

#### Arguments

* **$1** (string): Optional stash. Defaults to stash@{0}.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stash was deleted.
* **64**: More than two arguments were given.
* other The status of git stash.

### git::reset

Reset a working tree to a revision.

#### Example

```bash
git::fetch origin && git::reset origin/main
```

#### Arguments

* **$1** (string): Revision to reset to.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The working tree and index match the revision.
* **64**: The argument count is not one or two.
* other The status of git reset.

### git::pull-rebase

Update a branch from a remote with rebase.

#### Example

```bash
git::pull-rebase main upstream
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

### git::cherry-pick

Apply one commit, fetching it from a remote only when the repository lacks it.

#### Example

```bash
git::cherry-pick 3ce3b61 upstream
```

#### Arguments

* **$1** (string): Commit to apply.
* **$2** (string): Optional remote to fetch a missing commit from. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The commit was applied.
* **64**: The arguments are invalid.
* other The status of the git command that failed.

### git::cherry-pick-continue

Continue an in-progress cherry-pick.

#### Example

```bash
git add src/util.sh && git::cherry-pick-continue
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The cherry-pick continued.
* **64**: More than one argument was given.
* other The status of git cherry-pick.

### git::cherry-pick-abort

Abort an in-progress cherry-pick.

Untracked files left by the cherry-pick are stashed, or removed when stashing fails.

#### Example

```bash
git::cherry-pick-abort
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The cherry-pick was aborted.
* **64**: More than one argument was given.
* other The status of the git command that failed.

### git::push

Push a branch to a remote.

#### Example

```bash
git::push feature/login
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

### git::push::force-with-lease

Push a branch without overwriting a remote update.

#### Example

```bash
git rebase origin/main && git::push::force-with-lease
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

### git::remote::delete-branch

Delete a branch on a remote.

#### Example

```bash
git::remote::delete-branch feature/login
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

### git::submodule::update-all

Update all submodules recursively.

#### Example

```bash
git::submodule::update-all
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: Every submodule was initialized and updated.
* **64**: More than one argument was given.
* other The status of git submodule.

### git::commit::discard

Discard all changes in a working tree.

The changes, including untracked files, are first saved in a stash, and the branch is reset to the parent of HEAD.

#### Example

```bash
git::commit::discard
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The changes were stashed and the latest commit was removed.
* **64**: More than one argument was given.
* other The status of the git command that failed, including when HEAD has no parent.

### git::reset-remote

Hard reset the current branch to the branch with the same name on a remote.

#### Example

```bash
git::reset-remote upstream
```

#### Arguments

* **$1** (string): Optional remote. Defaults to origin.
* **$2** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch matches the remote branch.
* **1**: HEAD is detached.
* **64**: More than two arguments were given.
* other The status of the git command that failed.

### git::pull-base-branch

Pull the configured base branch with fast-forward-only semantics.

The base branch is checked out and fast-forwarded from origin, and the original branch is then rebased onto it.

#### Example

```bash
git::pull-base-branch develop
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

### git::rebase-base-branch

Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one.

#### Example

```bash
git::rebase-base-branch develop origin
```

#### Arguments

* **$1** (string): Optional base branch. Defaults to main.
* **$2** (string): Optional remote. Defaults to upstream.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The branch was rebased.
* **64**: More than three arguments were given.
* other The status of the git command that failed.

### git::credentials::remove

Remove $HOME/.git-credentials and the global credential.helper; both may be absent.

#### Example

```bash
git::credentials::remove
```

_Function has no arguments._

#### Exit codes

* **0**: Neither the file nor the helper remains.
* **64**: An argument was given.
* other The status of git config or rm.

### git::config::enable-origin-all-fetch

Make origin fetch every branch in a repository.

#### Example

```bash
git::config::enable-origin-all-fetch && git::fetch origin
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The refspec was set.
* **64**: More than one argument was given.
* other The status of git config.

### git::config::enable-prune-fetch

Enable pruning on fetch in the global Git configuration.

#### Example

```bash
git::config::enable-prune-fetch
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git::config::set-default-branch

Set the default branch name of new repositories.

#### Example

```bash
git::config::set-default-branch trunk
```

#### Arguments

* **$1** (string): Optional branch name. Defaults to main.

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the name is not a valid branch name.
* other The status of git config.

### git::config::enable-rebase-on-pull

Enable rebase on pull in the global Git configuration.

#### Example

```bash
git::config::enable-rebase-on-pull
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git::config::set-email

Set the global Git email address.

#### Example

```bash
git::config::set-email developer@example.com
```

#### Arguments

* **$1** (string): Optional email address. Defaults to GIT_EMAIL, then to input from the controlling terminal.

#### Exit codes

* **0**: The address was set, or an existing one was kept.
* **64**: More than one argument was given or the value has several lines.
* **66**: No address is available and none is configured.
* **74**: The terminal could not be read.
* other The status of git config.

### git::config::set-username

Set the global Git user name.

#### Example

```bash
git::config::set-username 'Alex Example'
```

#### Arguments

* **$1** (string): Optional display name. Defaults to GIT_USERNAME, then to input from the controlling terminal.

#### Exit codes

* **0**: The name was set, or an existing one was kept.
* **64**: More than one argument was given or the value has several lines.
* **66**: No name is available and none is configured.
* **74**: The terminal could not be read.
* other The status of git config.

### git::config::set-http-buffer

Set the global Git HTTP post buffer.

#### Example

```bash
git::config::set-http-buffer 1048576000
```

#### Arguments

* **$1** (integer): Optional buffer size in bytes. Defaults to 524288000 (500 MiB).

#### Exit codes

* **0**: The setting was written.
* **64**: More than one argument was given or the size is not an integer.
* other The status of git config.

### git::config::use-gpg-credential-store

Make Git Credential Manager store credentials with GPG and pass.

The guidance for initializing the pass store is written to standard error.

#### Example

```bash
git::config::use-gpg-credential-store && pass::store::init
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

#### Output on stderr

* How to initialize the pass store.

### git::config::use-credential-manager

Use Git Credential Manager as the global credential helper.

#### Example

```bash
git-credential-manager::install && git::config::use-credential-manager
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* other The status of git config.

### git::config::use-osx-keychain

Use the macOS Keychain as the global Git credential helper.

#### Example

```bash
git::config::use-osx-keychain
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written.
* **64**: An argument was given.
* **69**: The system is not macOS.
* other The status of git config.

### git::config::setup

Apply the user identity and the standard global Git settings.

#### Example

```bash
git::config::setup developer@example.com 'Alex Example'
```

#### Arguments

* **$1** (string): Optional email address passed to git::config::set-email.
* **$2** (string): Optional display name passed to git::config::set-username.

#### Exit codes

* **0**: Every setting was applied.
* **64**: More than two arguments were given.
* other The status of the setting that failed.

### git::stash::list

List stashes.

#### Example

```bash
git::stash::list
```

#### Arguments

* **$1** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The stashes were written.
* **64**: More than one argument was given.
* other The status of git stash.

#### Output on stdout

* The output of git stash list.

