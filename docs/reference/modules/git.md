# git

Git history editing.

## Overview

git::commit::edit-via-rebase starts an interactive rebase that stops at one commit, without opening an editor for the todo list.

## Index

* [git::commit::edit-via-rebase](#gitcommitedit-via-rebase)

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

