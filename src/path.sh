#!/usr/bin/env bash
# @file path
# @brief Lexical path operations and file-type tests.
# @description Lexical functions never touch the file system; tests follow the Bash test semantics.

# @description Write the lexical directory portion of a path.
#
# Like dirname, but without running a command or reading the file system.
#
# @arg $1 string Path.
# @stdout The directory part; . for a bare name and / for the root.
# @exitcode 0 The directory was written.
# @exitcode 64 The argument count is not one.
# @example
#   path::directory-name /usr/local/bin/node
#   # /usr/local/bin
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

# @description Write the final component of a path with an optional suffix removed.
#
# @arg $1 string Path.
# @arg $2 string Optional suffix to remove from the final component.
# @stdout The final component.
# @exitcode 0 The name was written.
# @exitcode 64 The argument count is not one or two.
# @example
#   path::base-name /tmp/archive.tar.gz .tar.gz
#   # archive
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

# @description Test whether a path names a directory.
#
# A symbolic link to a directory counts.
#
# @arg $1 string Path.
# @exitcode 0 The path is a directory.
# @exitcode 1 The path is not a directory or does not exist.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-directory "${HOME}/.ssh" || mkdir -m 700 "${HOME}/.ssh"
path::is-directory() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -d "$1" ]]
}

# @description Test whether a path names an empty directory.
#
# Hidden entries count, so a directory with only .gitkeep is not empty.
#
# @arg $1 string Path.
# @exitcode 0 The path is a directory without entries.
# @exitcode 1 The path is not a directory or has entries.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-empty-directory build && rmdir build
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

# @description Test whether the current user may execute a path.
#
# @arg $1 string Path.
# @exitcode 0 The path is executable, or searchable for a directory.
# @exitcode 1 The path cannot be executed or does not exist.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-executable "${HOME}/.local/bin/android"
path::is-executable() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -x "$1" ]]
}

# @description Test whether a path names an executable regular file.
#
# @arg $1 string Path.
# @exitcode 0 The path is a regular file that the current user may execute.
# @exitcode 1 The path is not an executable regular file.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-executable-file ./gradlew && ./gradlew build
path::is-executable-file() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -f "$1" && -x "$1" ]]
}

# @description Test whether a path names a regular file.
#
# @arg $1 string Path.
# @exitcode 0 The path is a regular file.
# @exitcode 1 The path is not a regular file or does not exist.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-regular-file "${HOME}/.env" && env::dotenv::import "${HOME}/.env"
path::is-regular-file() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -f "$1" ]]
}

# @description Test whether a path names a symbolic link.
#
# @arg $1 string Path.
# @exitcode 0 The path is a symbolic link, even a broken one.
# @exitcode 1 The path is not a symbolic link.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-symbolic-link "${HOME}/Desktop" && readlink "${HOME}/Desktop"
path::is-symbolic-link() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -L "$1" ]]
}

# @description Test whether the current user may read a path.
#
# @arg $1 string Path.
# @exitcode 0 The path is readable.
# @exitcode 1 The path is not readable or does not exist.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-readable /etc/os-release && . /etc/os-release
path::is-readable() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -r "$1" ]]
}

# @description Test whether the current user may write a path.
#
# @arg $1 string Path.
# @exitcode 0 The path is writable.
# @exitcode 1 The path is not writable or does not exist.
# @exitcode 64 The argument count is not one.
# @example
#   path::is-writable /etc/hosts || command::run-as-root cp hosts /etc/hosts
path::is-writable() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  [[ -w "$1" ]]
}

# @description Write a path's permission mode as an octal number.
#
# A symbolic link reports the mode of the link itself.
#
# @arg $1 string Existing path.
# @stdout The mode, such as 644 or 4755.
# @exitcode 0 The mode was written.
# @exitcode 64 The path is empty, or the argument count is not one.
# @exitcode 66 The path does not exist.
# @example
#   [[ "$(path::mode "${HOME}/.ssh")" == 700 ]] || chmod 700 "${HOME}/.ssh"
path::mode() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi
  if [[ ! -e "$1" && ! -L "$1" ]]; then
    return 66
  fi

  platform::_path-mode "$1"
}

# @description Write the extension of the final path component.
#
# A leading dot does not start an extension, so .bashrc has none.
#
# @arg $1 string Path.
# @stdout The extension with its dot, or an empty line when there is none.
# @exitcode 0 The extension was written.
# @exitcode 64 The argument count is not one.
# @example
#   path::extension /tmp/archive.tar.gz
#   # .gz
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

# @description Normalize a path lexically without accessing the file system.
#
# Repeated slashes and . components are removed and .. removes the previous
# component. Leading .. components of a relative path are kept.
#
# @arg $1 string Path.
# @stdout The normalized path; . for an empty relative result.
# @exitcode 0 The path was written.
# @exitcode 64 The argument count is not one.
# @example
#   path::normalize /usr//local/./lib/../bin
#   # /usr/local/bin
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

# @description Write the lexical relative path from one path to another.
#
# Both paths are normalized first and must both be absolute or both be relative.
#
# @arg $1 string Starting directory.
# @arg $2 string Target path.
# @stdout The path that leads from the first path to the second.
# @exitcode 0 The relative path was written.
# @exitcode 64 One path is absolute and the other is relative, or the argument count is not two.
# @example
#   path::relative /usr/local/bin /usr/share/doc
#   # ../../share/doc
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

# @description Write the absolute configuration-home directory.
#
# XDG_CONFIG_HOME is used when set; otherwise $HOME/.config.
#
# @noargs
# @stdout The configuration directory.
# @exitcode 0 The directory was written.
# @exitcode 64 An argument was given, or XDG_CONFIG_HOME or HOME is not an absolute path.
# @example
#   mkdir -p "$(path::config-home)/mozc"
path::config-home() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    if [[ "${XDG_CONFIG_HOME}" != /* ]] ||
      ! string::_require-one-line "${XDG_CONFIG_HOME}"; then
      return 64
    fi
    printf '%s\n' "${XDG_CONFIG_HOME}"
    return 0
  fi

  if [[ -z "${HOME:-}" || "${HOME}" != /* ]] ||
    ! string::_require-one-line "${HOME:-}"; then
    return 64
  fi
  printf '%s/.config\n' "${HOME%/}"
}

# @description Change directory ownership recursively through the root helper.
#
# The ownership change runs in a separate root process of this library and does
# not follow symbolic links or cross file systems.
#
# @arg $1 string Existing directory; a symbolic link is refused.
# @arg $2 string New owner name.
# @arg $3 string Optional group. Defaults to the owner's primary group.
# @exitcode 0 The ownership was changed.
# @exitcode 64 An owner or group is empty or contains a newline, or the argument count is wrong.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode other The status of the root helper.
# @example
#   path::change-owner-recursively /srv/app deploy
path::change-owner-recursively() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    return 64
  fi
  if [[ ! -d "$1" || -L "$1" ]]; then
    return 66
  fi
  if ! string::_require-non-empty-line "$2"; then
    return 64
  fi
  if [[ "$#" -eq 3 ]] && ! string::_require-non-empty-line "$3"; then
    return 64
  fi

  path::_validate-ownership "$@" || return "$?"
  bashstock::_run-as-root change-owner-recursively "$@"
}


# @description Validate a directory and its requested owner and group.
# @internal
path::_validate-ownership() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then return 64; fi
  if [[ ! -d "$1" || -L "$1" ]]; then return 66; fi
  string::_require-non-empty-line "$2" || return "$?"
  if [[ "$#" -eq 3 ]]; then string::_require-non-empty-line "$3" || return "$?"; fi
}

# @description Change directory ownership recursively in a separate root process.
#
# Same as path::change-owner-recursively; the name states that root is used.
#
# @arg $1 string Existing directory; a symbolic link is refused.
# @arg $2 string New owner name.
# @arg $3 string Optional group. Defaults to the owner's primary group.
# @exitcode 0 The ownership was changed.
# @exitcode 64 An argument is invalid.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode other The status of the root helper.
# @example
#   path::change-owner-recursively-as-root /srv/app deploy www-data
path::change-owner-recursively-as-root() {
  path::_validate-ownership "$@" || return "$?"
  bashstock::_run-as-root change-owner-recursively "$@"
}
