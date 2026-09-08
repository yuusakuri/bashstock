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
