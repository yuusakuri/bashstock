#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "discard saves local work before removing the latest commit" {
  local repo="$BATS_TEST_TMPDIR/repo" first=''
  git init -q "$repo"
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.invalid
  printf 'initial\n' >"$repo/tracked"
  git -C "$repo" add tracked
  git -C "$repo" commit -qm initial
  first="$(git -C "$repo" rev-parse HEAD)"
  printf 'second\n' >"$repo/tracked"
  git -C "$repo" commit -qam second
  printf 'local\n' >"$repo/tracked"
  printf 'untracked\n' >"$repo/new"

  run git::commit::discard "$repo"
  [ "$status" -eq 0 ]
  [ "$(git -C "$repo" rev-parse HEAD)" = "$first" ]
  [ "$(cat "$repo/tracked")" = initial ]
  [ ! -e "$repo/new" ]
  git -C "$repo" stash show --include-untracked --name-only 'stash@{0}' |
    grep -Fxq new
}

@test "hard reset removes tracked changes and leaves unrelated untracked files" {
  local repo="$BATS_TEST_TMPDIR/repo" first=''
  git init -q "$repo"
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.invalid
  printf 'initial\n' >"$repo/tracked"
  git -C "$repo" add tracked
  git -C "$repo" commit -qm initial
  first="$(git -C "$repo" rev-parse HEAD)"
  printf 'second\n' >"$repo/tracked"
  git -C "$repo" commit -qam second
  printf 'local\n' >"$repo/tracked"
  printf 'untracked\n' >"$repo/new"

  run git::reset "$first" "$repo"
  [ "$status" -eq 0 ]
  [ "$(cat "$repo/tracked")" = initial ]
  [ "$(cat "$repo/new")" = untracked ]
}

@test "environment settings survive new shells without duplicating PATH" {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME" "$HOME/path with spaces"
  env::set-variable BASHSTOCK_LITERAL 'a b $literal' bash
  env::add-path "$HOME/path with spaces" bash
  env::add-path "$HOME/path with spaces" bash

  run bash -c 'source "$1"; source "$1"; printf "%s\n%s\n" "$BASHSTOCK_LITERAL" "$PATH"' _ "$HOME/.bashrc"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'a b $literal' ]
  [[ ":${lines[1]}:" == *":$HOME/path with spaces:"* ]]
  local without_first="${lines[1]/"$HOME/path with spaces"/}"
  [[ "$without_first" != *"$HOME/path with spaces"* ]]
}

@test "JFrog setup receives the environment token only through standard input" {
  local bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin"
  export JFROG_TEST_ROOT="$BATS_TEST_TMPDIR"
  export JFROG_ACCESS_TOKEN='test-token-value'
  cat >"$bin/jf" <<'SCRIPT'
#!/usr/bin/env bash
[[ -z "${JFROG_ACCESS_TOKEN:-}" ]] || exit 80
printf '%s\n' "$@" >>"$JFROG_TEST_ROOT/args"
if [[ "$1" == config ]]; then cat >"$JFROG_TEST_ROOT/token"; fi
SCRIPT
  chmod +x "$bin/jf"
  PATH="$bin:$PATH"
  run jfrog::setup test-server https://example.invalid alice
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/token")" = test-token-value ]
  ! grep -Fq test-token-value "$BATS_TEST_TMPDIR/args"
  grep -Fxq -- '--access-token-stdin' "$BATS_TEST_TMPDIR/args"

  unset JFROG_ACCESS_TOKEN
  run jfrog::setup test-server https://example.invalid alice
  [ "$status" -eq 64 ]
}

@test "Flutter version switching retains a retrievable stash and ignored files" {
  local remote="$BATS_TEST_TMPDIR/remote.git" sdk="$BATS_TEST_TMPDIR/flutter"
  git init -q --bare "$remote"
  git clone -q "$remote" "$sdk"
  git -C "$sdk" config user.name test
  git -C "$sdk" config user.email test@example.invalid
  mkdir -p "$sdk/bin"
  printf '#!/bin/sh\n' >"$sdk/bin/flutter"
  chmod +x "$sdk/bin/flutter"
  printf 'ignored\n' >"$sdk/.gitignore"
  printf 'one\n' >"$sdk/version"
  git -C "$sdk" add .
  git -C "$sdk" commit -qm first
  git -C "$sdk" tag 1.0.0
  printf 'two\n' >"$sdk/version"
  git -C "$sdk" commit -qam second
  git -C "$sdk" tag 2.0.0
  git -C "$sdk" push -q origin HEAD --tags
  git -C "$sdk" switch --detach -q 1.0.0
  printf 'local\n' >"$sdk/version"
  printf 'extra\n' >"$sdk/extra"
  printf 'ignored\n' >"$sdk/ignored"

  run flutter::use-version 2.0.0 "$sdk"
  [ "$status" -eq 0 ]
  [ "$(cat "$sdk/version")" = two ]
  [ "$(cat "$sdk/ignored")" = ignored ]
  git -C "$sdk" stash show --include-untracked --name-only 'stash@{0}' |
    grep -Fxq extra
}

@test "normal push rejects stale history and force-with-lease requires a fresh fetch" {
  local remote="$BATS_TEST_TMPDIR/remote.git" first="$BATS_TEST_TMPDIR/first" second="$BATS_TEST_TMPDIR/second"
  git init -q --bare -b main "$remote"
  git clone -q "$remote" "$first"
  git -C "$first" config user.name test
  git -C "$first" config user.email test@example.invalid
  printf 'initial\n' >"$first/file"
  git -C "$first" add file
  git -C "$first" commit -qm initial
  git -C "$first" push -q origin main
  git clone -q "$remote" "$second"
  git -C "$second" config user.name test
  git -C "$second" config user.email test@example.invalid
  printf 'first\n' >"$first/file"
  git -C "$first" commit -qam first
  git::push main origin "$first" >/dev/null
  printf 'second\n' >"$second/file"
  git -C "$second" commit -qam second
  run git::push main origin "$second"
  [ "$status" -ne 0 ]
  run git::push::force-with-lease main origin "$second"
  [ "$status" -ne 0 ]
  git -C "$second" fetch -q origin
  run git::push::force-with-lease main origin "$second"
  [ "$status" -eq 0 ]
  [ "$(git --git-dir="$remote" rev-parse main)" = "$(git -C "$second" rev-parse main)" ]
}

@test "cherry-pick abort saves untracked files and leaves ignored files" {
  local repo="$BATS_TEST_TMPDIR/repo"
  git init -q -b main "$repo"
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.invalid
  printf 'base\n' >"$repo/file"
  printf 'ignored\n' >"$repo/.gitignore"
  git -C "$repo" add .
  git -C "$repo" commit -qm base
  git -C "$repo" switch -qc feature
  printf 'feature\n' >"$repo/file"
  git -C "$repo" commit -qam feature
  local feature_commit=''
  feature_commit="$(git -C "$repo" rev-parse HEAD)"
  git -C "$repo" switch -q main
  printf 'main\n' >"$repo/file"
  git -C "$repo" commit -qam main
  ! git -C "$repo" cherry-pick "$feature_commit" >/dev/null 2>&1
  printf 'untracked\n' >"$repo/new"
  printf 'ignored\n' >"$repo/ignored"
  run git::cherry-pick-abort "$repo"
  [ "$status" -eq 0 ]
  [ ! -e "$repo/new" ]
  [ -e "$repo/ignored" ]
  git -C "$repo" stash show --include-untracked --name-only 'stash@{0}' | grep -Fxq new
}

@test "OpenCode uses the vendor npm package in a user-local prefix" {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  platform::_identifier() { printf 'fedora\n'; }
  npm() {
    printf '%s\n' "$*" >"$BATS_TEST_TMPDIR/npm.args"
    mkdir -p "$HOME/.local/bin"
    printf '#!/bin/sh\nprintf "1.2.3\\n"\n' >"$HOME/.local/bin/opencode"
    chmod +x "$HOME/.local/bin/opencode"
  }
  run opencode::install 1.2.3
  [ "$status" -eq 0 ]
  [ "$output" = 1.2.3 ]
  [ "$(<"$BATS_TEST_TMPDIR/npm.args")" = "install --global --prefix $HOME/.local opencode-ai@1.2.3" ]
}
