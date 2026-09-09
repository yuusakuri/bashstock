#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

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
