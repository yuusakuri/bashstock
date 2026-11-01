# gerrit

Gerrit code review uploads.

## Overview

Changes are pushed from the current HEAD to refs/for.

## Index

* [gerrit::push-review](#gerritpush-review)
* [gerrit::push-review-wip](#gerritpush-review-wip)

### gerrit::push-review

Push the current HEAD to a Gerrit review reference.

#### Example

```bash
gerrit::push-review main
```

#### Arguments

* **$1** (string): Optional target branch of the review. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The review was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

### gerrit::push-review-wip

Push the current HEAD to a Gerrit review reference as work in progress.

#### Example

```bash
gerrit::push-review-wip main
```

#### Arguments

* **$1** (string): Optional target branch of the review. Defaults to the current branch.
* **$2** (string): Optional remote. Defaults to origin.
* **$3** (string): Optional repository directory. Defaults to the current directory.

#### Exit codes

* **0**: The review was pushed.
* **1**: No branch was given and HEAD is detached.
* **64**: More than three arguments were given.
* other The status of git push.

