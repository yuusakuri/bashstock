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

@test "SSH private-key listing delegates key detection to ssh-keygen" {
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

@test "path and content searches write NUL-separated matches" {
  local root="${BATS_TEST_TMPDIR}/search"
  mkdir -p "$root/Sub Dir"
  printf 'needle here\n' >"$root/Sub Dir/Match.TXT"
  printf 'nothing\n' >"$root/other.txt"
  printf 'needle\0binary' >"$root/binary.bin"
  [ "$(path::find '\.txt$' "$root" | tr '\0' '\n' | sort)" = "$(printf '%s\n%s' "$root/Sub Dir/Match.TXT" "$root/other.txt")" ]
  run path::find 'absent' "$root"
  [ "$status" -eq 1 ]
  run path::find '(' "$root"
  [ "$status" -eq 64 ]

  [ "$(file::find-by-content 'need+le' "$root" 2 | tr '\0' '\n')" = "$root/Sub Dir/Match.TXT" ]
  [ "$(file::find-by-content 'needle' "$root" 1 include | tr '\0' '\n' | wc -l | tr -d ' ')" -eq 2 ]
  run file::find-by-content 'absent' "$root"
  [ "$status" -eq 1 ]
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
