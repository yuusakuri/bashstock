#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

@test "write-text creates files with the caller's umask and preserves shell state" {
  local mask='' expected='' file='' actual=''
  for mask in 0022 0002 0077 0777; do
    file="${BATS_TEST_TMPDIR}/mode-${mask}"
    run bash -c 'source "$1"; umask "$2"; before="$(umask)"; file::write-text "$3" "literal text" && test "$(umask)" = "$before"' _ "${PROJECT_ROOT}/dist/bashstock.sh" "${mask}" "${file}"
    [ "${status}" -eq 0 ]
    case "$(uname -s)" in
      Darwin) actual="$(stat -f '%Lp' "${file}")" ;;
      *) actual="$(stat -c '%a' "${file}")" ;;
    esac
    case "${mask}" in
      0022) expected=644 ;;
      0002) expected=664 ;;
      0077) expected=600 ;;
      0777) expected=0 ;;
    esac
    [ "${actual}" = "${expected}" ]
  done
}

@test "write-text preserves existing file permissions and accepts empty text" {
  local file="${BATS_TEST_TMPDIR}/private"
  printf 'previous' >"${file}"
  chmod 640 "${file}"
  run bash -c 'source "$1"; umask 077; file::write-text "$2" ""' _ "${PROJECT_ROOT}/dist/bashstock.sh" "${file}"
  [ "${status}" -eq 0 ]
  [ ! -s "${file}" ]
  case "$(uname -s)" in
    Darwin) [ "$(stat -f '%Lp' "${file}")" = 640 ] ;;
    *) [ "$(stat -c '%a' "${file}")" = 640 ] ;;
  esac
}

@test "write-text rejects symbolic links and retains their targets" {
  local target="${BATS_TEST_TMPDIR}/target" link="${BATS_TEST_TMPDIR}/link"
  printf 'original' >"${target}"
  ln -s "${target}" "${link}"
  run file::write-text "${link}" 'replacement'
  [ "${status}" -eq 64 ]
  [ -L "${link}" ]
  [ "$(<"${target}")" = original ]
}

@test "utility file and environment functions preserve literal values" {
  local file="${BATS_TEST_TMPDIR}/value file"
  run file::write-text "$file" 'a$HOME\nvalue'
  [ "${status}" -eq 0 ]
  [ "$(<"$file")" = 'a$HOME\nvalue' ]

  run file::replace-text-or-append "$file" '^missing=' 'missing=value'
  [ "${status}" -eq 0 ]
  [[ "$(<"$file")" == *'missing=value'* ]]

  local dotenv="${BATS_TEST_TMPDIR}/env"
  printf 'BASHSTOCK_TEST_VALUE="literal value"\n' >"$dotenv"
  env::dotenv::import "$dotenv"
  [ "${BASHSTOCK_TEST_VALUE}" = 'literal value' ]
}

@test "utility time and memory functions return documented forms" {
  run time::sleep-hours -1
  [ "${status}" -eq 64 ]
  run mem::physical-total-bytes
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+$ ]]
  run mem::physical-total-gibibytes
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]{2}$ ]]
}

@test "utility symlink and directory functions are safe" {
  local source="${BATS_TEST_TMPDIR}/source" link="${BATS_TEST_TMPDIR}/link" directory="${BATS_TEST_TMPDIR}/directory"
  printf 'source' >"$source"
  run symlink::create "$source" "$link"
  [ "${status}" -eq 0 ]
  [ -L "$link" ]
  run symlink::remove "$link"
  [ "${status}" -eq 0 ]
  mkdir -p "$directory/sub"
  printf 'x' >"$directory/sub/file"
  run directory::clear "$directory"
  [ "${status}" -eq 0 ]
  [ -d "$directory" ]
  [ ! -e "$directory/sub" ]
}

@test "selected git utility functions use the requested repository" {
  local repository="${BATS_TEST_TMPDIR}/repository"
  mkdir "$repository"
  git -C "$repository" init -q
  git -C "$repository" -c user.name=test -c user.email=test@example.invalid commit --allow-empty -m initial -q
  run git::branch::current "$repository"
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(git -C "$repository" branch --show-current)" ]
  run git::branch::create topic HEAD "$repository"
  [ "${status}" -eq 0 ]
  git -C "$repository" show-ref --verify --quiet refs/heads/topic
}

@test "managed SSH configuration preserves unrelated directives" {
  command -v ssh >/dev/null 2>&1 || skip 'the OpenSSH client is not installed'
  local config="${BATS_TEST_TMPDIR}/ssh-config" include="${BATS_TEST_TMPDIR}/included-config"
  : >"$include"
  chmod 600 "$include"
  printf 'Include %s\nMatch all\n  ForwardAgent no\n' "$include" >"$config"

  run ssh::config::set "$config" '*.example' User alice
  [ "${status}" -eq 0 ]
  run ssh::config::enable-auto-add-keys "$config" '*.example'
  [ "${status}" -eq 0 ]
  run ssh::config::disable-host-key-checking "$config" '*.example'
  [ "${status}" -eq 0 ]
  run ssh::config::set "$config" 'foo.example bar.example !bad.example' ProxyJump none
  [ "${status}" -eq 0 ]
  [ "$(grep -F -c '# bashstock: begin *.example' "$config")" -eq 1 ]
  grep -Fq '  User alice' "$config"
  grep -Fq '  AddKeysToAgent yes' "$config"
  grep -Fq '  StrictHostKeyChecking no' "$config"
  grep -Fq '  UserKnownHostsFile /dev/null' "$config"
  grep -Fq "Include $include" "$config"
  grep -Fq 'Match all' "$config"
  grep -Fq '  ForwardAgent no' "$config"
  run ssh -G -F "$config" host.example
  [ "${status}" -eq 0 ]
}

@test "managed SSH configuration keeps global directives global" {
  command -v ssh >/dev/null 2>&1 || skip 'the OpenSSH client is not installed'
  local config="${BATS_TEST_TMPDIR}/ssh-config"
  printf 'User alice\nPort 2222\n' >"$config"

  run ssh::config::set "$config" managed.example User bob
  [ "${status}" -eq 0 ]
  [ "$(ssh -G -F "$config" other.example | grep '^user ')" = 'user alice' ]
  [ "$(ssh -G -F "$config" other.example | grep '^port ')" = 'port 2222' ]
  [ "$(ssh -G -F "$config" managed.example | grep '^user ')" = 'user bob' ]
  [ "$(ssh -G -F "$config" managed.example | grep '^port ')" = 'port 2222' ]

  run ssh::config::set "$config" second.example User carol
  [ "${status}" -eq 0 ]
  run ssh::config::set "$config" managed.example Port 22
  [ "${status}" -eq 0 ]
  [ "$(ssh -G -F "$config" other.example | grep '^user ')" = 'user alice' ]
  [ "$(ssh -G -F "$config" managed.example | grep '^port ')" = 'port 22' ]
  [ "$(ssh -G -F "$config" second.example | grep '^user ')" = 'user carol' ]
}

@test "managed SSH configuration replaces option names case-insensitively" {
  command -v ssh >/dev/null 2>&1 || skip 'the OpenSSH client is not installed'
  local config="${BATS_TEST_TMPDIR}/ssh-config"
  printf '# bashstock: begin managed.example\nHost managed.example\n  user alice\n# bashstock: end\n' >"$config"

  run ssh::config::set "$config" managed.example User bob
  [ "${status}" -eq 0 ]
  [ "$(ssh -G -F "$config" managed.example | grep '^user ')" = 'user bob' ]
  ! grep -Fq 'user alice' "$config"
}

@test "managed SSH configuration refuses a block without an end marker" {
  command -v ssh >/dev/null 2>&1 || skip 'the OpenSSH client is not installed'
  local config="${BATS_TEST_TMPDIR}/ssh-config" before=''
  printf '# bashstock: begin managed.example\nHost managed.example\n  User alice\nHost other.example\n  Port 2222\n' >"$config"
  before="$(<"$config")"
  run --separate-stderr ssh::config::set "$config" managed.example User bob
  [ "${status}" -eq 65 ]
  [ "$(<"$config")" = "${before}" ]
}

@test "SSH private-key listing delegates key detection to ssh-keygen" {
  command -v ssh-keygen >/dev/null 2>&1 || skip 'the OpenSSH client is not installed'
  local directory="${BATS_TEST_TMPDIR}/keys" key="${BATS_TEST_TMPDIR}/keys/id_ed25519"
  mkdir -p "$directory"
  ssh-keygen -q -t ed25519 -N '' -f "$key"
  printf 'not a key\n' >"${directory}/notes.txt"
  run ssh::key::private-files "$directory"
  [ "${status}" -eq 0 ]
  [ "${output}" = "$key" ]
}

@test "dotenv import parses quoting and comments as data and validates before exporting" {
  local file="${BATS_TEST_TMPDIR}/values.env"
  printf '%s\n' \
    '# comment' \
    '' \
    'export BASHSTOCK_PLAIN=plain value   # trailing comment' \
    "BASHSTOCK_SINGLE='a \$HOME \\n literal'" \
    'BASHSTOCK_DOUBLE="tab\there \"quoted\" \$HOME" # comment' \
    'BASHSTOCK_HASH=a#b' \
    'BASHSTOCK_EMPTY=' >"$file"
  printf 'BASHSTOCK_CRLF=value\r\n' >>"$file"
  env::dotenv::import "$file"
  [ "$BASHSTOCK_PLAIN" = 'plain value' ]
  [ "$BASHSTOCK_SINGLE" = 'a $HOME \n literal' ]
  [ "$BASHSTOCK_DOUBLE" = $'tab\there "quoted" $HOME' ]
  [ "$BASHSTOCK_HASH" = 'a#b' ]
  [ -z "$BASHSTOCK_EMPTY" ]
  [ "$BASHSTOCK_CRLF" = value ]
  run bash -c 'printf "%s" "$BASHSTOCK_DOUBLE"'
  [ "$output" = $'tab\there "quoted" $HOME' ]

  local invalid="${BATS_TEST_TMPDIR}/invalid.env"
  printf 'BASHSTOCK_FIRST=changed\nBASHSTOCK_SECOND="unterminated\n' >"$invalid"
  BASHSTOCK_FIRST=original
  run --separate-stderr env::dotenv::import "$invalid"
  [ "$status" -eq 65 ]
  [[ "$stderr" == *'line 2'* ]]
  env::dotenv::import "$invalid" 2>/dev/null || true
  [ "$BASHSTOCK_FIRST" = original ]
  printf '1BAD=value\n' >"$invalid"
  run env::dotenv::import "$invalid"
  [ "$status" -eq 65 ]
}

@test "dotenv registration loads the file in new Bash and Zsh sessions once" {
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME/project"
  printf 'BASHSTOCK_REGISTERED="from dotenv"\n' >"$HOME/project/my values.env"
  cd "$HOME/project"
  env::dotenv::register 'my values.env'
  env::dotenv::register "$HOME/project/./my values.env"
  [ "$(grep -c 'env::dotenv::import' "$HOME/.bashrc")" -eq 1 ]
  [ "$(grep -c 'env::dotenv::_export-commands' "$HOME/.zshrc")" -eq 1 ]
  grep -Fq "$(printf '%q' "$HOME/project/my values.env")" "$HOME/.bashrc"
  run env -i HOME="$HOME" PATH="$PATH" bash -c 'source "$HOME/.bashrc"; printf "%s" "$BASHSTOCK_REGISTERED"'
  [ "$output" = 'from dotenv' ]
  if command -v zsh >/dev/null 2>&1; then
    run env -i HOME="$HOME" PATH="$PATH" zsh -c 'source "$HOME/.zshrc"; printf "%s" "$BASHSTOCK_REGISTERED"'
    [ "$output" = 'from dotenv' ]
  fi
  run env::dotenv::register "$HOME/project/my values.env" fish
  [ "$status" -eq 64 ]
}

@test "editor and completion settings reach new shells without duplicates" {
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  shell::editor::set-default
  shell::editor::set-default
  [ "$EDITOR" = 'code --wait' ]
  [ "$(grep -c '^export EDITOR=' "$HOME/.bashrc")" -eq 1 ]
  [ ! -e "$HOME/.zshrc" ]
  shell::editor::set-default 'code --wait' bash,zsh
  [ "$(grep -c '^export EDITOR=' "$HOME/.zshrc")" -eq 1 ]
  run env -i HOME="$HOME" bash -c 'source "$HOME/.bashrc"; printf "%s" "$EDITOR"' </dev/null
  [ "$output" = 'code --wait' ]
  shell::editor::set-default vim bash
  run env -i HOME="$HOME" bash -c 'source "$HOME/.bashrc"; printf "%s" "$EDITOR"' </dev/null
  [ "$output" = vim ]

  shell::completion::enable-ignore-case
  shell::completion::enable-ignore-case
  [ "$(grep -c '^set completion-ignore-case on$' "$HOME/.inputrc")" -eq 1 ]
  if [[ -r /etc/inputrc ]]; then [ "$(head -n 1 "$HOME/.inputrc")" = '$include /etc/inputrc' ]; fi
  [ "$(grep -cF "zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'" "$HOME/.zshrc")" -eq 1 ]
  [ "$(INPUTRC="$HOME/.inputrc" bash -ic 'bind -v' 2>/dev/null | grep 'completion-ignore-case')" = 'set completion-ignore-case on' ]
}

@test "English user directory links point to the localized XDG directories" {
  local home="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$home/デスクトップ" "$home/ドキュメント/kept" "$home/Documents/.hidden-dir" "$home/画像" "$home/Music"
  printf 'english\n' >"$home/Documents/report.txt"
  printf 'old\n' >"$home/ドキュメント/report.txt"
  printf 'hidden\n' >"$home/Documents/.hidden-dir/file"
  printf 'not a directory\n' >"$home/Pictures"
  xdg-user-dir() {
    case "$1" in
      DESKTOP) printf '%s\n' "$HOME/デスクトップ" ;;
      DOCUMENTS) printf '%s\n' "$HOME/ドキュメント" ;;
      PICTURES) printf '%s\n' "$HOME/画像" ;;
      MUSIC) printf '%s\n' "$HOME/Music" ;;
      VIDEOS) printf '%s\n' "$HOME/ビデオ" ;;
      *) printf '%s\n' "$HOME" ;;
    esac
  }
  run --separate-stderr user::directory::create-english-links "$home"
  [ "$status" -eq 73 ]
  [[ "$stderr" == *"$home/Pictures"* ]]
  [ "$(readlink "$home/Desktop")" = "$home/デスクトップ" ]
  [ "$(readlink "$home/Documents")" = "$home/ドキュメント" ]
  [ "$(<"$home/ドキュメント/report.txt")" = english ]
  [ -d "$home/ドキュメント/kept" ]
  [ "$(<"$home/ドキュメント/.hidden-dir/file")" = hidden ]
  [ -f "$home/Pictures" ]
  [ -d "$home/Music" ] && [ ! -L "$home/Music" ]
  [ ! -e "$home/Videos" ] && [ ! -e "$home/ビデオ" ]

  rm -f "$home/Pictures"
  run user::directory::create-english-links "$home"
  [ "$status" -eq 0 ]
  [ "$(readlink "$home/Pictures")" = "$home/画像" ]
}

@test "SSH directory setup applies the modes SSH expects" {
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME/.ssh/sockets"
  printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nkey\n' >"$HOME/.ssh/id_ed25519"
  printf -- '-----BEGIN RSA PRIVATE KEY-----\nkey\n' >"$HOME/.ssh/legacy"
  printf 'ssh-ed25519 AAAA user\n' >"$HOME/.ssh/id_ed25519.pub"
  : >"$HOME/.ssh/config"
  : >"$HOME/.ssh/authorized_keys"
  : >"$HOME/.ssh/known_hosts"
  chmod 777 "$HOME/.ssh" "$HOME/.ssh/sockets" "$HOME/.ssh"/*
  ssh::setup-directory
  mode() { case "$(uname -s)" in Darwin) stat -f '%Lp' "$1" ;; *) stat -c '%a' "$1" ;; esac; }
  [ "$(mode "$HOME/.ssh")" = 700 ]
  [ "$(mode "$HOME/.ssh/sockets")" = 700 ]
  [ "$(mode "$HOME/.ssh/id_ed25519")" = 600 ]
  [ "$(mode "$HOME/.ssh/legacy")" = 600 ]
  [ "$(mode "$HOME/.ssh/config")" = 600 ]
  [ "$(mode "$HOME/.ssh/authorized_keys")" = 600 ]
  [ "$(mode "$HOME/.ssh/id_ed25519.pub")" = 644 ]
  [ "$(mode "$HOME/.ssh/known_hosts")" = 644 ]
}

@test "Git identity comes from arguments, the environment, or the existing value" {
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  unset GIT_CONFIG_GLOBAL GIT_EMAIL GIT_USERNAME
  terminal::is-available() { return 1; }
  run --separate-stderr git::config::set-email
  [ "$status" -eq 66 ]
  [[ "$stderr" == *GIT_EMAIL* ]]
  git::config::set-email first@example.invalid
  [ "$(git config --global user.email)" = first@example.invalid ]
  GIT_EMAIL=second@example.invalid git::config::set-email
  [ "$(git config --global user.email)" = second@example.invalid ]
  git::config::set-email
  [ "$(git config --global user.email)" = second@example.invalid ]
  run git::config::set-email $'two\nlines'
  [ "$status" -eq 64 ]

  GIT_USERNAME='Test User' git::config::setup
  [ "$(git config --global user.name)" = 'Test User' ]
  [ "$(git config --global init.defaultBranch)" = main ]
  [ "$(git config --global pull.rebase)" = true ]
  [ "$(git config --global fetch.prune)" = true ]
  git::config::set-http-buffer
  [ "$(git config --global http.postBuffer)" = 524288000 ]
  run git::config::set-default-branch 'bad..name'
  [ "$status" -eq 64 ]
  run --separate-stderr git::config::use-gpg-credential-store
  [ "$status" -eq 0 ]
  [ "$(git config --global credential.credentialStore)" = gpg ]
  [[ "$stderr" == *pass::store::init* ]]
}

@test "directory merge moves every entry, overwrites conflicts, and removes the source" {
  local source="${BATS_TEST_TMPDIR}/source" destination="${BATS_TEST_TMPDIR}/destination"
  mkdir -p "$source/nested" "$destination/nested"
  printf 'new\n' >"$source/nested/same"
  printf 'old\n' >"$destination/nested/same"
  printf 'kept\n' >"$destination/nested/other"
  printf 'hidden\n' >"$source/.hidden"
  ln -s /nonexistent "$source/link"
  run directory::merge "$source" "$destination"
  [ "$status" -eq 0 ]
  [ ! -e "$source" ]
  [ "$(<"$destination/nested/same")" = new ]
  [ "$(<"$destination/nested/other")" = kept ]
  [ "$(<"$destination/.hidden")" = hidden ]
  [ "$(readlink "$destination/link")" = /nonexistent ]
  run directory::merge "${BATS_TEST_TMPDIR}/missing" "$destination"
  [ "$status" -eq 64 ]
}

@test "POSIX time zones invert the ISO offset sign and keep minutes" {
  local offset='' expected=''
  while read -r offset expected; do
    run time::posix-timezone "$offset"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
  done <<'TABLE'
Z UTC0
+00:00 UTC0
-00:00 UTC0
+09:00 UTC-9
+09:30 UTC-9:30
-05:00 UTC+5
-03:45 UTC+3:45
TABLE
  for offset in 3600 +24:00 +09:60 +9:00 UTC; do
    run time::posix-timezone "$offset"
    [ "$status" -eq 64 ]
  done
}

@test "date-time directories get a numbered suffix when the name exists" {
  local parent="${BATS_TEST_TMPDIR}/parent"
  mkdir -p "$parent"
  time::local-date-time-seconds-basic() { printf '20260102T030405\n'; }
  run directory::create-with-date-time "$parent"
  [ "$output" = "$parent/20260102T030405" ]
  run directory::create-with-date-time "$parent"
  [ "$output" = "$parent/20260102T030405-2" ]
  run directory::create-with-date-time "$parent"
  [ "$output" = "$parent/20260102T030405-3" ]
  [ -d "$parent/20260102T030405-3" ]
}

@test "directory clear refuses the root, the home directory, empty names, and links" {
  HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME/data/.hidden" "${BATS_TEST_TMPDIR}/target"
  printf 'kept\n' >"${BATS_TEST_TMPDIR}/target/file"
  ln -s "${BATS_TEST_TMPDIR}/target" "${BATS_TEST_TMPDIR}/link"
  run directory::clear /
  [ "$status" -eq 64 ]
  run directory::clear "$HOME"
  [ "$status" -eq 64 ]
  run directory::clear "$HOME/data/.."
  [ "$status" -eq 64 ]
  run directory::clear ''
  [ "$status" -eq 64 ]
  run directory::clear "${BATS_TEST_TMPDIR}/link"
  [ "$status" -eq 64 ]
  [ -f "${BATS_TEST_TMPDIR}/target/file" ]
  run directory::clear "$HOME/data"
  [ "$status" -eq 0 ]
  [ -d "$HOME/data" ] && [ -z "$(ls -A "$HOME/data")" ]
}

@test "archive extraction uses the archive name and refuses escaping links" {
  local work="${BATS_TEST_TMPDIR}/work"
  mkdir -p "$work/content/dir" "$work/evil"
  printf 'value\n' >"$work/content/dir/file"
  ln -s file "$work/content/dir/inner-link"
  tar -czf "$work/good.tgz" -C "$work/content" .
  run archive::extract-file "$work/good.tgz"
  [ "$status" -eq 0 ]
  [ "$(<"$work/good/dir/file")" = value ]
  [ "$(readlink "$work/good/dir/inner-link")" = file ]
  [ -z "$(find "$work/good" -name '.bashstock-extract.*')" ]
  printf 'old\n' >"$work/good/dir/file"
  run archive::extract-file "$work/good.tgz" "$work/good"
  [ "$(<"$work/good/dir/file")" = value ]

  ln -s ../../outside "$work/evil/escape"
  tar -czf "$work/bad.tar.gz" -C "$work/evil" .
  run --separate-stderr archive::extract-file "$work/bad.tar.gz"
  [ "$status" -eq 65 ]
  [[ "$stderr" == *escape* ]]
  [ -d "$work/bad" ] && [ -z "$(ls -A "$work/bad")" ]
  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    (cd "$work/content" && zip -qry "$work/good.zip" .)
    run archive::extract-file "$work/good.zip"
    [ "$status" -eq 0 ]
    [ "$(<"$work/good/dir/file")" = value ]
  fi
}

@test "archive verification covers tar, compressed, zip, and 7z formats" {
  local work="${BATS_TEST_TMPDIR}/formats" format='' file='' seven=''
  mkdir -p "$work/content/dir" "$work/single"
  printf 'value\n' >"$work/content/dir/file"
  ln -s file "$work/content/dir/link"
  printf 'line\n' >"$work/single/note.txt"
  tar -cf "$work/sample.tar" -C "$work/content" .
  for format in gzip:tgz:gz xz:txz:xz bzip2:tbz2:bz2 zstd:tzst:zst; do
    command -v "${format%%:*}" >/dev/null 2>&1 || continue
    tar -cf - -C "$work/content" . | "${format%%:*}" -c >"$work/sample.$(cut -d: -f2 <<<"$format")"
    "${format%%:*}" -c "$work/single/note.txt" >"$work/note.txt.${format##*:}"
  done
  seven="$(archive::_7zip 2>/dev/null)" || seven=''
  if [[ -n "$seven" ]]; then
    (cd "$work/content" && "$seven" a -snl "$work/sample.7z" . >/dev/null)
  fi
  rm -rf "$work/single"

  run archive::verify "$work"
  [ "$status" -eq 0 ]
  for file in "$work"/sample.* "$work"/note.txt.*; do
    run archive::extract-file "$file" "$work/out/${file##*/}"
    [ "$status" -eq 0 ]
    case "$file" in
      */note.txt.*) [ "$(<"$work/out/${file##*/}/note.txt")" = line ] ;;
      *)
        [ "$(<"$work/out/${file##*/}/dir/file")" = value ]
        [ "$(readlink "$work/out/${file##*/}/dir/link")" = file ]
        ;;
    esac
  done

  run archive::extract-file "$work/note.txt.gz"
  [ "$status" -eq 0 ]
  [ "$(<"$work/note.txt")" = line ]
  mkdir "$work/blocked" "$work/blocked/note.txt"
  cp "$work/note.txt.gz" "$work/blocked/"
  run archive::extract-file "$work/blocked/note.txt.gz"
  [ "$status" -eq 73 ]
}

@test "archive removal deletes broken archives only and keeps archives it cannot verify" {
  local work="${BATS_TEST_TMPDIR}/broken" limited="${BATS_TEST_TMPDIR}/limited-bin"
  mkdir -p "$work/content" "$limited"
  printf 'value\n' >"$work/content/file"
  tar -czf "$work/good.tar.gz" -C "$work/content" .
  head -c 40 "$work/good.tar.gz" >"$work/truncated.tgz"
  printf 'not gzip' >"$work/plain.gz"
  printf 'not a tar archive' >"$work/random.tar"

  run --separate-stderr archive::verify "$work"
  [ "$status" -eq 1 ]
  [[ "$stderr" == *truncated.tgz* && "$stderr" == *plain.gz* && "$stderr" == *random.tar* ]]
  [[ "$stderr" != *good.tar.gz* ]]
  [ -f "$work/truncated.tgz" ]

  run archive::remove-broken "$work"
  [ "$status" -eq 1 ]
  [ -f "$work/good.tar.gz" ]
  [ ! -e "$work/truncated.tgz" ] && [ ! -e "$work/plain.gz" ] && [ ! -e "$work/random.tar" ]
  run archive::remove-broken "$work"
  [ "$status" -eq 0 ]

  # Without zstd and 7-Zip the archives cannot be verified, so they stay.
  printf 'unknown' >"$work/data.zst"
  printf 'unknown' >"$work/data.7z"
  ln -s "$(command -v find)" "$limited/find"
  ln -s "$(command -v tar)" "$limited/tar"
  ln -s "$(command -v gzip)" "$limited/gzip"
  ln -s "$(command -v mktemp)" "$limited/mktemp"
  ln -s "$(command -v rm)" "$limited/rm"
  status=0
  (PATH="$limited" && archive::remove-broken "$work") 2>"$work.err" || status="$?"
  [ "$status" -eq 0 ]
  [ -f "$work/data.zst" ] && [ -f "$work/data.7z" ] && [ -f "$work/good.tar.gz" ]
  [[ "$(<"$work.err")" == *zstd* && "$(<"$work.err")" == *7-Zip* ]]
  rm -f "$work/data.zst" "$work/data.7z"

  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    (cd "$work/content" && zip -q -P secret "$work/encrypted.zip" file)
    run --separate-stderr archive::remove-broken "$work"
    [ "$status" -eq 0 ]
    [ -f "$work/encrypted.zip" ]
    [[ "$stderr" == *'encrypted.zip is encrypted'* ]]
  fi
}

@test "path and content searches write NUL-separated matches" {
  local root="${BATS_TEST_TMPDIR}/search"
  mkdir -p "$root/Sub Dir"
  printf 'needle here\n' >"$root/Sub Dir/Match.TXT"
  printf 'nothing\n' >"$root/other.txt"
  printf 'needle\0binary' >"$root/binary.bin"
  [ "$(path::find '\.txt$' "$root" | tr '\0' '\n' | LC_ALL=C sort)" = "$(printf '%s\n%s' "$root/Sub Dir/Match.TXT" "$root/other.txt")" ]
  run path::find 'absent' "$root"
  [ "$status" -eq 1 ]
  run path::find '(' "$root"
  [ "$status" -eq 64 ]

  [ "$(file::find-by-content 'need+le' "$root" 2 | tr '\0' '\n')" = "$root/Sub Dir/Match.TXT" ]
  [ "$(file::find-by-content 'needle' "$root" 1 include | tr '\0' '\n' | wc -l | tr -d ' ')" -eq 2 ]
  run file::find-by-content 'absent' "$root"
  [ "$status" -eq 1 ]
  # A grep that cannot read a file reports status 2; the search must not pass as complete.
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  printf '#!/bin/sh\ncase "$*" in *other.txt*) exit 2 ;; esac\nexec %s "$@"\n' "$(command -v grep)" >"${BATS_TEST_TMPDIR}/bin/grep"
  chmod +x "${BATS_TEST_TMPDIR}/bin/grep"
  PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run file::find-by-content 'needle' "$root" 1
  [ "$status" -eq 74 ]
  rm "${BATS_TEST_TMPDIR}/bin/grep"
  # find lists the readable files but fails for a directory it cannot read.
  printf '#!/bin/sh\n%s "$@"\nexit 1\n' "$(command -v find)" >"${BATS_TEST_TMPDIR}/bin/find"
  chmod +x "${BATS_TEST_TMPDIR}/bin/find"
  PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run file::find-by-content 'needle' "$root" 1
  [ "$status" -eq 74 ]
  rm "${BATS_TEST_TMPDIR}/bin/find"
  run file::find-by-content 'needle' "$root" 1 maybe
  [ "$status" -eq 64 ]
}

@test "latest file by name breaks ties by path bytes" {
  local root="${BATS_TEST_TMPDIR}/latest"
  mkdir -p "$root"
  printf 'a\n' >"$root/b.log"
  printf 'a\n' >"$root/a.log"
  printf 'a\n' >"$root/old.log"
  touch -t 202601010000 "$root/a.log" "$root/b.log"
  touch -t 202501010000 "$root/old.log"
  run file::latest-by-name '\.log$' "$root"
  [ "$output" = "$root/a.log" ]
  touch -t 202602010000 "$root/b.log"
  run file::latest-by-name '\.log$' "$root"
  [ "$output" = "$root/b.log" ]
}

@test "symbolic links point to absolute paths and replace only links" {
  local work="${BATS_TEST_TMPDIR}/links"
  mkdir -p "$work/first" "$work/second"
  cd "$work"
  run symlink::create first current
  [ "$status" -eq 0 ]
  [ "$(readlink "$work/current")" = "$work/first" ]
  run symlink::create "$work/second" current
  [ "$status" -eq 0 ]
  [ "$(readlink "$work/current")" = "$work/second" ]
  [ ! -e "$work/second/second" ]
  run symlink::create first second
  [ "$status" -eq 73 ]
  run symlink::create missing other
  [ "$status" -eq 66 ]
}

@test "tree with contents writes directories and text files only" {
  local root="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "$root/sub/deeper"
  printf 'top text' >"$root/top.txt"
  printf 'deep text\n' >"$root/sub/deeper/deep.txt"
  printf '\x00\x01\x02\x03' >"$root/sub/data.bin"
  command -v file >/dev/null 2>&1 || skip 'file is not installed'
  run file::tree-with-contents "$root"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$root/sub"* ]]
  [[ "$output" == *"==> $root/top.txt <=="$'\n''top text'* ]]
  [[ "$output" == *'deep text'* ]]
  [[ "$output" != *data.bin* ]]
  run file::tree-with-contents "$root" 1 1
  [[ "$output" != *'deep text'* ]]
  [[ "$output" == *'top text'* ]]
}

@test "file editing runs a multiword EDITOR as a command with arguments" {
  local file="${BATS_TEST_TMPDIR}/note.txt"
  fake-editor() {
    printf '%s\n' "$@" >"${BATS_TEST_TMPDIR}/editor.args"
  }
  EDITOR='fake-editor --wait --new-window' run file::edit "${file}"
  [ "${status}" -eq 0 ]
  [ "$(cat "${BATS_TEST_TMPDIR}/editor.args")" = $'--wait\n--new-window\n'"${file}" ]

  run file::edit "${BATS_TEST_TMPDIR}"
  [ "${status}" -eq 66 ]
}

@test "startup file updates keep the shell-list array local" {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}/bin"
  _util_shells=(keep me)
  env::set-variable BASHSTOCK_TEST_VALUE yes bash
  env::add-path "${HOME}/bin" bash
  [ "${_util_shells[*]}" = 'keep me' ]
}

@test "archive functions report a path that cannot be searched" {
  local missing="${BATS_TEST_TMPDIR}/missing"
  run --separate-stderr archive::verify "${missing}"
  [ "${status}" -eq 66 ]
  [[ "${stderr}" == *'cannot be searched for archives'* ]]
  run --separate-stderr archive::remove-broken "${missing}"
  [ "${status}" -eq 66 ]
  run --separate-stderr archive::extract "${missing}"
  [ "${status}" -eq 66 ]
}

@test "directory merge refuses a destination that is the source or inside it" {
  local source="${BATS_TEST_TMPDIR}/source"
  mkdir -p "${source}/keep"
  printf 'data\n' >"${source}/file"
  run directory::merge "${source}" "${source}"
  [ "${status}" -eq 64 ]
  run directory::merge "${source}" "${source}/."
  [ "${status}" -eq 64 ]
  run directory::merge "${source}" "${source}/keep/inner"
  [ "${status}" -eq 64 ]
  [ ! -e "${source}/keep/inner" ]
  [ "$(<"${source}/file")" = data ]

  # An entry named like SOURCE would replace SOURCE in its parent.
  mkdir -p "${source}/source"
  run directory::merge "${source}" "${BATS_TEST_TMPDIR}"
  [ "${status}" -eq 64 ]
  [ "$(<"${source}/file")" = data ]
}

@test "tar.gz compression treats option-like paths as files" {
  local work="${BATS_TEST_TMPDIR}/compress"
  mkdir -p "${work}"
  cd "${work}"
  printf 'data\n' >./--checkpoint=1
  printf 'plain\n' >plain.txt
  run archive::compress-tar-gzip --output archive.tar.gz --checkpoint=1 plain.txt
  [ "${status}" -eq 0 ]
  [ "$(tar -tzf archive.tar.gz | sort | tr '\n' ' ')" = '--checkpoint=1 plain.txt ' ]
}

@test "dotenv import refuses readonly variables before changing any" {
  local dotenv="${BATS_TEST_TMPDIR}/readonly.env"
  printf 'BASHSTOCK_FIRST=1\nUID=0\n' >"${dotenv}"
  unset BASHSTOCK_FIRST
  run --separate-stderr env::dotenv::import "${dotenv}"
  [ "${status}" -eq 65 ]
  [[ "${stderr}" == *'UID'*'readonly'* ]]
  env::dotenv::import "${dotenv}" 2>/dev/null || true
  [ -z "${BASHSTOCK_FIRST+set}" ]
}
