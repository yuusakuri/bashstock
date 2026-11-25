#!/usr/bin/env bats

load test_helper
bats_require_minimum_version 1.5.0

demo__create() {
  local name=''
  local shell='/bin/bash'
  local force='false'

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        arg__require-next "$#" "$1" || return 1
        name=$2
        shift 2
        ;;
      --shell)
        arg__require-next "$#" "$1" || return 1
        shell=$2
        shift 2
        ;;
      --force)
        force='true'
        shift
        ;;
      *)
        arg__unknown "$1" || return 1
        ;;
    esac
  done

  arg__require --name "${name}" || return "$?"
  printf 'name=%s shell=%s force=%s\n' "${name}" "${shell}" "${force}"
}

_demo__create-args() {
  case "${1-}" in
    --shell)
      printf '%s\n' /bin/bash /bin/zsh
      ;;
    '')
      printf '%s\n' --name --shell --force
      ;;
  esac
}

@test "arg__require-next accepts a value and rejects a trailing flag" {
  run arg__require-next 2 --name
  [ "${status}" -eq 0 ]

  run --separate-stderr arg__require-next 1 --name
  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'bashstock: Option --name requires a value.' ]
}

@test "arg__require rejects an empty value" {
  run arg__require --name ''
  [ "${status}" -eq 64 ]

  run arg__require --name alice
  [ "${status}" -eq 0 ]
}

@test "arg__integer accepts integers and rejects other values" {
  run arg__integer --count '3'
  [ "${status}" -eq 0 ]

  run arg__integer --count '-3'
  [ "${status}" -eq 0 ]

  run arg__integer --count '3.5'
  [ "${status}" -eq 64 ]
}

@test "arg__one-of accepts a listed candidate and rejects others" {
  run arg__one-of -Level info info warn error
  [ "${status}" -eq 0 ]

  run arg__one-of -Level debug info warn error
  [ "${status}" -eq 64 ]
}

@test "arg__unknown always fails" {
  run --separate-stderr arg__unknown '--bogus'
  [ "${status}" -eq 64 ]
  [ "${stderr}" = 'bashstock: Unknown option: --bogus' ]
}

@test "a while/case function built on arg__ accepts named arguments" {
  run demo__create --name alice --shell /bin/zsh --force
  [ "${status}" -eq 0 ]
  [ "${output}" = 'name=alice shell=/bin/zsh force=true' ]

  run demo__create --shell /bin/zsh
  [ "${status}" -ne 0 ]

  run demo__create -Unsupported value
  [ "${status}" -ne 0 ]
}

@test "the completion helper name derives from the public function name" {
  run _arg__completion__helper-name demo__create
  [ "${output}" = '_demo__create-args' ]

  run _arg__completion__helper-name 'git__stash__patch'
  [ "${output}" = '_git__stash__patch-args' ]

  run _arg__completion__helper-name 'noNamespace'
  [ "${status}" -eq 64 ]
}

@test "the completion target name derives from the helper name" {
  run _arg__completion__target-name '_demo__create-args'
  [ "${output}" = 'demo__create' ]

  run _arg__completion__target-name '_git__stash__patch-args'
  [ "${output}" = 'git__stash__patch' ]

  run _arg__completion__target-name 'demo__create'
  [ "${status}" -eq 64 ]
}

@test "dispatch writes flag names after the function name" {
  COMP_WORDS=(demo__create '')
  COMP_CWORD=1

  arg__completion__dispatch

  [ "${#COMPREPLY[@]}" -eq 3 ]
  [ "${COMPREPLY[0]}" = '--name' ]
  [ "${COMPREPLY[1]}" = '--shell' ]
  [ "${COMPREPLY[2]}" = '--force' ]
}

@test "dispatch writes value candidates only right after their flag" {
  COMP_WORDS=(demo__create --shell '')
  COMP_CWORD=2

  arg__completion__dispatch

  [ "${#COMPREPLY[@]}" -eq 2 ]
  [ "${COMPREPLY[0]}" = '/bin/bash' ]
  [ "${COMPREPLY[1]}" = '/bin/zsh' ]
}

@test "dispatch filters candidates by the current partial word" {
  COMP_WORDS=(demo__create --s)
  COMP_CWORD=1

  arg__completion__dispatch

  [ "${#COMPREPLY[@]}" -eq 1 ]
  [ "${COMPREPLY[0]}" = '--shell' ]
}

@test "dispatch does nothing for functions without a completion helper" {
  COMP_WORDS=(string__upper '')
  COMP_CWORD=1
  COMPREPLY=()

  arg__completion__dispatch

  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "register-all registers the dispatcher for every completion helper" {
  arg__completion__register-all

  run complete -p demo__create
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'arg__completion__dispatch'* ]]
}

@test "every library completion helper completes an existing public function and accepts its arguments" {
  local helper='' target='' option='' missing=()
  while IFS= read -r helper; do
    target="$(_arg__completion__target-name "${helper}")" || continue
    declare -F "${target}" >/dev/null || missing+=("${helper} has no ${target}")
    while IFS= read -r option; do
      # help__show completes function names; every other helper lists named arguments.
      [[ "${option}" == --* ]] || continue
      # Each listed argument must appear in the function or in the parser it delegates to.
      [[ "$(declare -f "${target}" _ssh__key__generate _adb__run)" == *"${option}"* ]] || missing+=("${target} ${option}")
    done < <("${helper}")
  done < <(declare -F | awk '{ print $3 }' | grep -E '^_[a-z][a-z0-9-]*(__[a-z0-9-]+)+-args$' | grep -v '^_demo__')
  [ "${#missing[@]}" -eq 0 ] || { printf '%s\n' "${missing[@]}" >&2; false; }
}

@test "ADB functions complete --serial with the connected devices" {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  printf '#!/bin/sh\nprintf "List of devices attached\\nemulator-5554\\tdevice\\nR58M\\tunauthorized\\n"\n' >"${BATS_TEST_TMPDIR}/bin/adb"
  chmod +x "${BATS_TEST_TMPDIR}/bin/adb"
  PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
  COMP_WORDS=(adb__device__reboot --serial '')
  COMP_CWORD=2
  arg__completion__dispatch
  [ "${#COMPREPLY[@]}" -eq 1 ]
  [ "${COMPREPLY[0]}" = emulator-5554 ]

  COMP_WORDS=(adb__device__select-and-pull --)
  COMP_CWORD=1
  arg__completion__dispatch
  [ "${COMPREPLY[*]}" = '--output-directory --serial' ]

  # Without adb there is no candidate; compgen then reports status 1, which Bash ignores.
  # PATH holds only an empty directory, because a real adb would start a server
  # that outlives the test.
  local saved_path="${PATH}"
  rm "${BATS_TEST_TMPDIR}/bin/adb"
  PATH="${BATS_TEST_TMPDIR}/bin"
  COMP_WORDS=(adb__wake__lock --serial '')
  COMP_CWORD=2
  arg__completion__dispatch || true
  PATH="${saved_path}"
  [ "${#COMPREPLY[@]}" -eq 0 ]
}
