#!/usr/bin/env bash

path::directory-name() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local path="$1"
  if [[ -z "${path}" ]]; then
    printf '.\n'
    return 0
  fi

  while [[ "${path}" != '/' && "${path}" == */ ]]; do
    path="${path%/}"
  done
  if [[ "${path}" != */* ]]; then
    printf '.\n'
    return 0
  fi

  path="${path%/*}"
  while [[ "${path}" != '/' && "${path}" == */ ]]; do
    path="${path%/}"
  done
  if [[ -z "${path}" ]]; then
    path='/'
  fi
  printf '%s\n' "${path}"
}

path::base-name() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
    return 64
  fi

  local path="$1"
  local suffix="${2-}"
  local name=''

  if [[ -z "${path}" ]]; then
    printf '\n'
    return 0
  fi
  while [[ "${path}" != '/' && "${path}" == */ ]]; do
    path="${path%/}"
  done
  if [[ "${path}" == '/' ]]; then
    name='/'
  else
    name="${path##*/}"
  fi

  if [[ "$#" -eq 2 && -n "${suffix}" ]] && string::ends-with "${name}" "${suffix}"; then
    name="${name:0:$((${#name} - ${#suffix}))}"
  fi
  printf '%s\n' "${name}"
}

path::is-directory() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -d "$1" ]]
}

path::is-empty-directory() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  if [[ ! -d "$1" ]]; then
    return 1
  fi

  (
    local entries=()
    shopt -s dotglob nullglob
    entries=("$1"/*)
    [[ "${#entries[@]}" -eq 0 ]]
  )
}

path::is-executable() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -x "$1" ]]
}

path::is-executable-file() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -f "$1" && -x "$1" ]]
}

path::is-regular-file() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -f "$1" ]]
}

path::is-symbolic-link() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -L "$1" ]]
}

path::is-readable() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -r "$1" ]]
}

path::is-writable() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -w "$1" ]]
}

path::extension() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local name=''
  name="$(path::base-name "$1")" || return "$?"

  case "${name}" in
    '' | '/' | '.' | '..')
      printf '\n'
      ;;
    .*)
      if [[ "${name:1}" != *.* ]]; then
        printf '\n'
      else
        printf '.%s\n' "${name##*.}"
      fi
      ;;
    *.*)
      printf '.%s\n' "${name##*.}"
      ;;
    *)
      printf '\n'
      ;;
  esac
}

path::normalize() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local path="$1"
  local remaining="$1"
  local absolute='0'
  local part=''
  local parts=()
  local index=''
  local result=''

  if [[ "${path}" == /* ]]; then
    absolute='1'
  fi

  while :; do
    if [[ "${remaining}" == */* ]]; then
      part="${remaining%%/*}"
      remaining="${remaining#*/}"
    else
      part="${remaining}"
      remaining=''
    fi

    case "${part}" in
      '' | '.')
        ;;
      '..')
        if [[ "${#parts[@]}" -gt 0 && "${parts[${#parts[@]}-1]}" != '..' ]]; then
          unset 'parts[${#parts[@]}-1]'
        elif [[ "${absolute}" -eq 0 ]]; then
          parts[${#parts[@]}]='..'
        fi
        ;;
      *)
        parts[${#parts[@]}]="${part}"
        ;;
    esac

    if [[ -z "${remaining}" ]]; then
      break
    fi
  done

  if [[ "${absolute}" -eq 1 ]]; then
    result='/'
  fi
  for ((index = 0; index < ${#parts[@]}; index++)); do
    if [[ -n "${result}" && "${result}" != '/' ]]; then
      result+='/'
    fi
    result+="${parts[index]}"
  done

  if [[ -z "${result}" ]]; then
    result='.'
  fi
  printf '%s\n' "${result}"
}

path::relative() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local from=''
  local to=''
  local from_absolute='0'
  local to_absolute='0'
  local remaining=''
  local part=''
  local from_parts=()
  local to_parts=()
  local common='0'
  local index=''
  local result=''

  from="$(path::normalize "$1")" || return "$?"
  to="$(path::normalize "$2")" || return "$?"
  [[ "${from}" == /* ]] && from_absolute='1'
  [[ "${to}" == /* ]] && to_absolute='1'
  if [[ "${from_absolute}" -ne "${to_absolute}" ]]; then
    return 64
  fi

  remaining="${from#/}"
  if [[ "${remaining}" != '.' ]]; then
    while :; do
      if [[ "${remaining}" == */* ]]; then
        part="${remaining%%/*}"
        remaining="${remaining#*/}"
      else
        part="${remaining}"
        remaining=''
      fi
      from_parts[${#from_parts[@]}]="${part}"
      [[ -z "${remaining}" ]] && break
    done
  fi

  remaining="${to#/}"
  if [[ "${remaining}" != '.' ]]; then
    while :; do
      if [[ "${remaining}" == */* ]]; then
        part="${remaining%%/*}"
        remaining="${remaining#*/}"
      else
        part="${remaining}"
        remaining=''
      fi
      to_parts[${#to_parts[@]}]="${part}"
      [[ -z "${remaining}" ]] && break
    done
  fi

  while ((common < ${#from_parts[@]} && common < ${#to_parts[@]})); do
    if [[ "${from_parts[common]}" != "${to_parts[common]}" ]]; then
      break
    fi
    common=$((common + 1))
  done

  for ((index = common; index < ${#from_parts[@]}; index++)); do
    if [[ -n "${result}" ]]; then
      result+='/'
    fi
    result+='..'
  done
  for ((index = common; index < ${#to_parts[@]}; index++)); do
    if [[ -n "${result}" ]]; then
      result+='/'
    fi
    result+="${to_parts[index]}"
  done

  if [[ -z "${result}" ]]; then
    result='.'
  fi
  printf '%s\n' "${result}"
}

path::config-home() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    if [[ "${XDG_CONFIG_HOME}" != /* ]] || core::__has-newline "${XDG_CONFIG_HOME}"; then
      return 64
    fi
    printf '%s\n' "${XDG_CONFIG_HOME}"
    return 0
  fi

  if [[ -z "${HOME:-}" || "${HOME}" != /* ]] || core::__has-newline "${HOME:-}"; then
    return 64
  fi
  printf '%s/.config\n' "${HOME%/}"
}

path::change-owner-recursively-as-root() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    return 64
  fi
  if [[ ! -d "$1" || -L "$1" ]]; then
    return 66
  fi
  if ! core::__require-non-empty-line "$2"; then
    return 64
  fi
  if [[ "$#" -eq 3 ]] && ! core::__require-non-empty-line "$3"; then
    return 64
  fi

  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    change-owner-recursively "$@"
}
