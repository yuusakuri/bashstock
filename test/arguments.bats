#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

demo::create() {
  local name=''
  local shell='/bin/bash'
  local force='false'

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -Name)
        arg::require-next "$#" "$1" || return 1
        name=$2
        shift 2
        ;;
      -Shell)
        arg::require-next "$#" "$1" || return 1
        shell=$2
        shift 2
        ;;
      -Force)
        force='true'
        shift
        ;;
      *)
        arg::unknown "$1" || return 1
        ;;
    esac
  done

  arg::require -Name "${name}" || return "$?"
  printf 'name=%s shell=%s force=%s\n' "${name}" "${shell}" "${force}"
}

demo::_create-args() {
  case "${1-}" in
    -Shell)
      printf '%s\n' /bin/bash /bin/zsh
      ;;
    '')
      printf '%s\n' -Name -Shell -Force
      ;;
  esac
}

@test "arg::require-next accepts a value and rejects a trailing flag" {
  run arg::require-next 2 -Name
  [ "${status}" -eq 0 ]

  run --separate-stderr arg::require-next 1 -Name
  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'bashstock: Option -Name requires a value.' ]
}

@test "arg::require rejects an empty value" {
  run arg::require -Name ''
  [ "${status}" -eq 64 ]

  run arg::require -Name alice
  [ "${status}" -eq 0 ]
}

@test "arg::integer accepts integers and rejects other values" {
  run arg::integer -Count '3'
  [ "${status}" -eq 0 ]

  run arg::integer -Count '-3'
  [ "${status}" -eq 0 ]

  run arg::integer -Count '3.5'
  [ "${status}" -eq 64 ]
}

@test "arg::one-of accepts a listed candidate and rejects others" {
  run arg::one-of -Level info info warn error
  [ "${status}" -eq 0 ]

  run arg::one-of -Level debug info warn error
  [ "${status}" -eq 64 ]
}

@test "arg::unknown always fails" {
  run --separate-stderr arg::unknown '--bogus'
  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'bashstock: Unknown option: --bogus' ]
}

@test "a while/case function built on arg:: accepts named arguments" {
  run demo::create -Name alice -Shell /bin/zsh -Force
  [ "${status}" -eq 0 ]
  [ "${output}" = 'name=alice shell=/bin/zsh force=true' ]

  run demo::create -Shell /bin/zsh
  [ "${status}" -ne 0 ]

  run demo::create -Unsupported value
  [ "${status}" -ne 0 ]
}

@test "the completion helper name derives from the public function name" {
  run arg::completion::_helper-name demo::create
  [ "${output}" = 'demo::_create-args' ]

  run arg::completion::_helper-name 'git::stash::patch'
  [ "${output}" = 'git::stash::_patch-args' ]

  run arg::completion::_helper-name 'noNamespace'
  [ "${status}" -eq 64 ]
}

@test "the completion target name derives from the helper name" {
  run arg::completion::_target-name 'demo::_create-args'
  [ "${output}" = 'demo::create' ]

  run arg::completion::_target-name 'git::stash::_patch-args'
  [ "${output}" = 'git::stash::patch' ]

  run arg::completion::_target-name 'demo::create'
  [ "${status}" -eq 64 ]
}

@test "dispatch writes flag names after the function name" {
  COMP_WORDS=(demo::create '')
  COMP_CWORD=1

  arg::completion::dispatch

  [ "${#COMPREPLY[@]}" -eq 3 ]
  [ "${COMPREPLY[0]}" = '-Name' ]
  [ "${COMPREPLY[1]}" = '-Shell' ]
  [ "${COMPREPLY[2]}" = '-Force' ]
}

@test "dispatch writes value candidates only right after their flag" {
  COMP_WORDS=(demo::create -Shell '')
  COMP_CWORD=2

  arg::completion::dispatch

  [ "${#COMPREPLY[@]}" -eq 2 ]
  [ "${COMPREPLY[0]}" = '/bin/bash' ]
  [ "${COMPREPLY[1]}" = '/bin/zsh' ]
}

@test "dispatch filters candidates by the current partial word" {
  COMP_WORDS=(demo::create -S)
  COMP_CWORD=1

  arg::completion::dispatch

  [ "${#COMPREPLY[@]}" -eq 1 ]
  [ "${COMPREPLY[0]}" = '-Shell' ]
}

@test "dispatch does nothing for functions without a completion helper" {
  COMP_WORDS=(string::upper '')
  COMP_CWORD=1
  COMPREPLY=()

  arg::completion::dispatch

  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "register-all registers the dispatcher for every completion helper" {
  arg::completion::register-all

  run complete -p demo::create
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'arg::completion::dispatch'* ]]
}
