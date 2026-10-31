#!/usr/bin/env bash
# @file file
# @brief Reading, writing, and replacing text in files.
# @description Text is written to a temporary file in the target directory and then moved into place.

# shellcheck disable=SC2234

# @description Require a readable regular file that is not a symbolic link.
# @internal
file::_require-existing() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi
  if [[ -L "$1" || ! -f "$1" || ! -r "$1" ]]; then
    return 66
  fi
}

# @description Require an existing regular file without checking read permissions.
# @internal
file::_require-regular-target() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi
  if [[ -L "$1" || ! -f "$1" ]]; then
    return 66
  fi
}

# @description Require a text file without NUL bytes.
# @internal
file::_require-no-nul() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local chunk=''
  local status=''
  while :; do
    chunk=''
    IFS= read -r -n 8192 -d '' chunk <&3
    status="$?"
    if [[ "${status}" -ne 0 ]]; then
      return 0
    fi
    if [[ "${#chunk}" -lt 8192 ]]; then
      return 64
    fi
  done 3<"$1"
}

# @description Require a one-line expression that compiles as a Perl regular expression.
# @internal
file::_require-perl-expression() {
  if [[ "$#" -ne 1 ]] || ! string::_require-one-line "$1"; then
    return 64
  fi
  command -v perl >/dev/null 2>&1 || return 69
  perl -e 'my $expression = shift; eval { qr/$expression/ }; exit($@ ? 64 : 0)' \
    -- "$1" 2>/dev/null
}

# @description Require a one-line expression that compiles as a Bash extended regular expression.
# @internal
file::_require-bash-expression() {
  if [[ "$#" -ne 2 ]] ||
    [[ -z "$1" ]] ||
    ! string::_require-one-line "$1" ||
    ! ( [[ "$2" -eq 0 || "$2" -eq 1 ]] ); then
    return 64
  fi

  if ! (
    local status=''
    ( [[ '' =~ $1 ]] ) 2>/dev/null
    status="$?"
    if [[ "${status}" -eq 2 ]]; then
      return 1
    fi
    if [[ "$2" -eq 1 && "${status}" -eq 0 ]]; then
      return 1
    fi
  ); then
    return 64
  fi
}

# @description Copy file content and metadata to another path.
# @internal
file::_copy-metadata-and-content() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  case "$(system::operating-system)" in
    darwin)
      cp -p "$1" "$2" >/dev/null 2>&1
      ;;
    linux)
      cp --preserve=all "$1" "$2" >/dev/null 2>&1
      ;;
    *)
      return 69
      ;;
  esac
}

# @description Create a temporary path beside the target file.
# @internal
file::_temporary-path() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local directory=''
  local name=''
  directory="$(path::directory-name "$1")" || return "$?"
  name="$(path::base-name "$1")" || return "$?"
  command -v mktemp >/dev/null 2>&1 || return 69
  mktemp "${directory}/.${name}.bashstock.XXXXXX" 2>/dev/null || return 74
}

# @description Test whether the effective user can update a file atomically.
# @internal
file::_can-update() {
  if [[ "$#" -ne 1 || -z "$1" || -L "$1" ]]; then
    return 1
  fi

  local directory=''
  directory="$(path::directory-name "$1")" || return 1
  if [[ -e "$1" ]]; then
    [[ -f "$1" && -r "$1" && -w "$1" &&
      -d "${directory}" && -w "${directory}" && -x "${directory}" ]]
    return
  fi
  [[ -d "${directory}" && -w "${directory}" && -x "${directory}" ]]
}

# @description Test whether the effective user can append to a file.
# @internal
file::_can-append() {
  if [[ "$#" -ne 1 || -z "$1" || -L "$1" ]]; then
    return 1
  fi

  if [[ -e "$1" ]]; then
    [[ -f "$1" && -w "$1" ]]
    return
  fi

  local directory=''
  directory="$(path::directory-name "$1")" || return 1
  [[ -d "${directory}" && -w "${directory}" && -x "${directory}" ]]
}

# @description Test whether appending requires administrator permissions.
# @internal
file::_requires-root-to-append() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  if [[ "${EUID}" -eq 0 ]]; then
    return 1
  fi
  ! file::_can-append "$1"
}

# @description Test whether any target requires administrator permissions to update.
# @internal
file::_requires-root() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi
  if [[ "${EUID}" -eq 0 ]]; then
    return 1
  fi

  local path=''
  for path in "$@"; do
    if ! file::_can-update "${path}"; then
      return 0
    fi
  done
  return 1
}

# @description Replace regular-expression matches in one line using Bash.
# @internal
file::_replace-line() {
  if [[ "$#" -ne 4 ]]; then
    return 64
  fi

  local value="$1"
  local expression="$2"
  local replacement="$3"
  local replace_all="$4"
  local result=''
  local pattern=''
  local match=''
  local length="${#value}"
  local cursor='0'
  local index=''
  local match_start=''
  local match_length=''
  local found='0'
  local matched='0'

  if ! [[ "${value}" =~ ${expression} ]]; then
    FILE_REPLACED_LINE="${value}"
    return 1
  fi
  while [[ "${cursor}" -le "${length}" ]]; do
    found='0'
    for ((index = cursor; index <= length; index++)); do
      pattern="^(.{${index}})(${expression})"
      if [[ "${value}" =~ ${pattern} ]]; then
        match="${BASH_REMATCH[2]}"
        match_start="${#BASH_REMATCH[1]}"
        match_length="${#match}"
        found='1'
        break
      fi
    done

    if [[ "${found}" -eq 0 ]]; then
      result="${result}${value:cursor}"
      break
    fi

    matched='1'
    result="${result}${value:cursor:match_start-cursor}${replacement}"
    cursor=$((match_start + match_length))

    if [[ "${replace_all}" -eq 0 ]]; then
      result="${result}${value:cursor}"
      break
    fi

    if [[ "${match_length}" -eq 0 ]]; then
      if [[ "${cursor}" -ge "${length}" ]]; then
        break
      fi
      result="${result}${value:cursor:1}"
      cursor=$((cursor + 1))
    fi
  done

  FILE_REPLACED_LINE="${result}"
  [[ "${matched}" -eq 1 ]]
}

# @description Prepare a metadata-preserving replacement file.
# @internal
file::_prepare-replacement() {
  if [[ "$#" -ne 5 ]]; then
    return 64
  fi

  local source="$1"
  local expression="$2"
  local replacement="$3"
  local append_when_missing="$4"
  local replace_all="$5"
  local temporary=''
  local line=''
  local replaced=''
  local read_status=''
  local changed='0'
  local saw_bytes='0'
  local ended_with_newline='0'
  local FILE_REPLACED_LINE=''
  local status=''

  shopt -u nocasematch
  temporary="$(file::_temporary-path "${source}")" || return "$?"
  if ! file::_copy-metadata-and-content "${source}" "${temporary}"; then
    rm -f -- "${temporary}"
    return 74
  fi

  : >"${temporary}" || {
    rm -f -- "${temporary}"
    return 74
  }

  while :; do
    line=''
    IFS= read -r line <&3
    read_status="$?"
    if [[ "${read_status}" -ne 0 && -z "${line}" ]]; then
      break
    fi

    saw_bytes='1'
    if file::_replace-line \
      "${line}" "${expression}" "${replacement}" "${replace_all}"; then
      replaced="${FILE_REPLACED_LINE}"
      changed='1'
    else
      status="$?"
      if [[ "${status}" -ne 1 ]]; then
        rm -f -- "${temporary}"
        return "${status}"
      fi
      replaced="${FILE_REPLACED_LINE}"
    fi

    if [[ "${read_status}" -eq 0 ]]; then
      printf '%s\n' "${replaced}" >>"${temporary}" || {
        rm -f -- "${temporary}"
        return 74
      }
      ended_with_newline='1'
    else
      printf '%s' "${replaced}" >>"${temporary}" || {
        rm -f -- "${temporary}"
        return 74
      }
      ended_with_newline='0'
      break
    fi
  done 3<"${source}"

  if [[ "${changed}" -eq 0 && "${append_when_missing}" -eq 1 ]]; then
    if [[ "${saw_bytes}" -eq 1 && "${ended_with_newline}" -eq 0 ]]; then
      printf '\n' >>"${temporary}" || {
        rm -f -- "${temporary}"
        return 74
      }
    fi
    printf '%s\n' "${replacement}" >>"${temporary}" || {
      rm -f -- "${temporary}"
      return 74
    }
    changed='1'
  fi

  if [[ "${changed}" -eq 1 ]]; then
    printf '%s\n' "${temporary}"
    return 0
  fi

  rm -f -- "${temporary}"
  return 1
}

# @description Test whether any file line matches a Perl regular expression.
#
# @arg $1 string Readable regular file; a symbolic link is refused.
# @arg $2 string Perl regular expression without newlines.
# @exitcode 0 At least one line matches.
# @exitcode 1 No line matches.
# @exitcode 64 The expression is invalid, or the argument count is not two.
# @exitcode 66 The file is missing, unreadable, or a symbolic link.
# @exitcode 69 Perl is unavailable.
# @example
#   file::contains-match /etc/hosts '^127\.0\.0\.1\s+localhost\b'
file::contains-match() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  file::_require-existing "$1" || return "$?"
  file::_require-perl-expression "$2" || return "$?"

  perl -e '
    use strict;
    use warnings;
    my ($path, $expression) = @ARGV;
    my $regex = eval { qr/$expression/ };
    exit 64 if $@;
    open my $input, "<", $path or exit 66;
    while (defined(my $line = <$input>)) {
      exit 0 if $line =~ $regex;
    }
    exit 1;
  ' -- "$1" "$2" 2>/dev/null
}

# @description Test a file against an expected SHA-256 digest.
#
# sha256sum is used on Linux and shasum on macOS; the digest is compared without regard to case.
#
# @arg $1 string Readable regular file.
# @arg $2 string Expected digest as 64 hexadecimal digits.
# @exitcode 0 The digest matches.
# @exitcode 1 The digest differs.
# @exitcode 64 The digest is not 64 hexadecimal digits, or the argument count is not two.
# @exitcode 66 The file is missing, unreadable, or a symbolic link.
# @exitcode 69 sha256sum or shasum is unavailable.
# @exitcode 74 The digest could not be computed.
# @example
#   file::verify-sha256 node.tar.gz "${expected_sha256}" || rm -f node.tar.gz
file::verify-sha256() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  file::_require-existing "$1" || return "$?"
  if ! ( [[ "$2" =~ ^[0-9A-Fa-f]{64}$ ]] ); then
    return 64
  fi

  local output=''
  local actual=''
  case "$(system::operating-system)" in
    darwin)
      command -v shasum >/dev/null 2>&1 || return 69
      output="$(shasum -a 256 -- "$1" 2>/dev/null)" || return 74
      ;;
    linux)
      command -v sha256sum >/dev/null 2>&1 || return 69
      output="$(sha256sum -- "$1" 2>/dev/null)" || return 74
      ;;
    *)
      return 69
      ;;
  esac
  actual="${output%% *}"
  [[ "$(string::lower "${actual}")" == "$(string::lower "$2")" ]]
}

# @description Append text without conversion, elevating only when permissions require it.
#
# The text is written exactly, so include a trailing newline when one is needed.
# A missing file is created with mode 0644 whatever the caller's umask is.
#
# @arg $1 string File path; a symbolic link is refused.
# @arg $2 string Text to append.
# @exitcode 0 The text was appended.
# @exitcode 64 The path is empty or a symbolic link, or the argument count is not two.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 74 The file could not be written.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::append-text "${HOME}/.bashrc" $'export EDITOR=vim\n'
file::append-text() {
  if [[ "$#" -ne 2 || -z "$1" || -L "$1" ]]; then
    return 64
  fi
  if [[ -e "$1" && ! -f "$1" ]]; then
    return 66
  fi

  if file::_requires-root-to-append "$1"; then
    bashstock::_run-as-root append-text "$1" "$2"
    return
  fi
  if [[ ! -e "$1" ]]; then
    (umask 077 && : >"$1") 2>/dev/null && chmod 0644 "$1" || return 74
  fi
  printf '%s' "$2" >>"$1" 2>/dev/null || return 74
}

# @description Replace Bash extended-regular-expression matches on every file line.
# @internal
file::_replace-text() {
  if [[ "$#" -ne 4 ]] ||
    ! ( [[ "$4" -eq 0 || "$4" -eq 1 ]] ) ||
    ! string::_require-one-line "$2" ||
    ! string::_require-one-line "$3"; then
    return 64
  fi

  local file="$1"
  local replace_all="$4"
  local temporary=''
  file::_require-existing "${file}" || return "$?"
  file::_require-no-nul "${file}" || return "$?"
  file::_require-bash-expression "$2" "${replace_all}" || return "$?"

  temporary="$(file::_prepare-replacement \
    "${file}" "$2" "$3" 0 "${replace_all}")" || return "$?"
  if ! mv -f -- "${temporary}" "${file}" 2>/dev/null; then
    rm -f -- "${temporary}"
    return 74
  fi
}

# @description Replace the first Bash ERE match on every file line.
#
# The file is rewritten through a temporary file, and root is used only when
# the current user cannot write it.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Nonempty Bash extended regular expression without newlines.
# @arg $3 string Literal one-line replacement text.
# @exitcode 0 The file was processed, whether or not a line matched.
# @exitcode 64 The expression or replacement is invalid, or the argument count is not three.
# @exitcode 66 The file is missing, not a regular file, or a symbolic link.
# @exitcode 74 The file could not be rewritten.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::replace-text /etc/ssh/sshd_config '^#?PasswordAuthentication .*$' 'PasswordAuthentication no'
file::replace-text() {
  if [[ "$#" -ne 3 ]]; then
    return 64
  fi
  file::_require-regular-target "$1" || return "$?"
  file::_require-bash-expression "$2" 0 || return "$?"
  string::_require-one-line "$3" || return "$?"
  if file::_requires-root "$1"; then
    bashstock::_run-as-root replace-text "$@"
    return
  fi
  file::_replace-text "$@" 0
}

# @description Replace every nonempty Bash ERE match on every file line.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Bash extended regular expression that cannot match an empty string.
# @arg $3 string Literal one-line replacement text.
# @exitcode 0 The file was processed, whether or not a line matched.
# @exitcode 64 The expression can match an empty string or is invalid, or the argument count is not three.
# @exitcode 66 The file is missing, not a regular file, or a symbolic link.
# @exitcode 74 The file could not be rewritten.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::replace-all-text settings.ini 'http://' 'https://'
file::replace-all-text() {
  if [[ "$#" -ne 3 ]]; then
    return 64
  fi
  file::_require-regular-target "$1" || return "$?"
  file::_require-bash-expression "$2" 1 || return "$?"
  string::_require-one-line "$3" || return "$?"
  if file::_requires-root "$1"; then
    bashstock::_run-as-root replace-all-text "$@"
    return
  fi
  file::_replace-text "$@" 1
}

# @description Replace line matches across files with rollback on failure.
# @internal
file::_replace-text-in-files() {
  if [[ "$#" -lt 4 ]] ||
    ! ( [[ "$1" -eq 0 || "$1" -eq 1 ]] ); then
    return 64
  fi

  local replace_all="$1"
  local expression="$2"
  local replacement="$3"
  local paths=()
  local prepared=()
  local backups=()
  local path=''
  local temporary=''
  local backup=''
  local status=''
  local index=''
  local restore_status='0'
  shift 3
  paths=("$@")

  if ! string::_require-one-line "${expression}" ||
    ! string::_require-one-line "${replacement}"; then
    return 64
  fi
  file::_require-bash-expression \
    "${expression}" "${replace_all}" || return "$?"
  for path in "${paths[@]}"; do
    file::_require-existing "${path}" || return "$?"
    file::_require-no-nul "${path}" || return "$?"
  done

  for path in "${paths[@]}"; do
    backup="$(file::_temporary-path "${path}")" || {
      status="$?"
      break
    }
    if ! file::_copy-metadata-and-content "${path}" "${backup}"; then
      rm -f -- "${backup}"
      status='74'
      break
    fi
    backups[${#backups[@]}]="${backup}"

    temporary="$(file::_prepare-replacement \
      "${path}" "${expression}" "${replacement}" 0 "${replace_all}")" || {
      status="$?"
      break
    }
    prepared[${#prepared[@]}]="${temporary}"
  done

  if [[ -n "${status}" ]]; then
    for temporary in "${prepared[@]}" "${backups[@]}"; do
      [[ -n "${temporary}" ]] && rm -f -- "${temporary}"
    done
    return "${status}"
  fi

  for ((index = 0; index < ${#paths[@]}; index++)); do
    if ! mv -f -- "${prepared[index]}" "${paths[index]}" 2>/dev/null; then
      status='74'
      break
    fi
  done

  if [[ -n "${status}" ]]; then
    for ((index = 0; index < ${#backups[@]}; index++)); do
      if ! mv -f -- "${backups[index]}" "${paths[index]}" 2>/dev/null; then
        restore_status='74'
      fi
    done
    for temporary in "${prepared[@]}" "${backups[@]}"; do
      [[ -n "${temporary}" ]] && rm -f -- "${temporary}"
    done
    [[ "${restore_status}" -eq 0 ]] || return 74
    return "${status}"
  fi

  for backup in "${backups[@]}"; do
    rm -f -- "${backup}"
  done
}

# @description Replace line matches across multiple files.
#
# Every file is checked before any is changed, and root is used only when one
# of them cannot be written by the current user.
#
# @arg $1 string Nonempty Bash extended regular expression without newlines.
# @arg $2 string Literal one-line replacement text.
# @arg $@ string Regular text files to update; at least one.
# @exitcode 0 The files were processed.
# @exitcode 64 The expression or replacement is invalid, or fewer than three arguments were given.
# @exitcode 66 A file is missing, not a regular file, or a symbolic link.
# @exitcode 74 A file could not be rewritten.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::replace-text-in-files '^version=.*$' 'version=2.0.0' app/a.properties app/b.properties
file::replace-text-in-files() {
  if [[ "$#" -lt 3 ]]; then
    return 64
  fi
  local paths=("${@:3}")
  local path=''
  file::_require-bash-expression "$1" 0 || return "$?"
  string::_require-one-line "$2" || return "$?"
  for path in "${paths[@]}"; do
    file::_require-regular-target "${path}" || return "$?"
  done
  if file::_requires-root "${paths[@]}"; then
    bashstock::_run-as-root replace-text-in-files "$@"
    return
  fi
  file::_replace-text-in-files 0 "$@"
}

# @description Replace every line match across multiple files.
#
# @arg $1 string Bash extended regular expression that cannot match an empty string.
# @arg $2 string Literal one-line replacement text.
# @arg $@ string Regular text files to update; at least one.
# @exitcode 0 The files were processed.
# @exitcode 64 The expression or replacement is invalid, or fewer than three arguments were given.
# @exitcode 66 A file is missing, not a regular file, or a symbolic link.
# @exitcode 74 A file could not be rewritten.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::replace-all-text-in-files 'example\.org' 'example.com' docs/*.md
file::replace-all-text-in-files() {
  if [[ "$#" -lt 3 ]]; then
    return 64
  fi
  local paths=("${@:3}")
  local path=''
  file::_require-bash-expression "$1" 1 || return "$?"
  string::_require-one-line "$2" || return "$?"
  for path in "${paths[@]}"; do
    file::_require-regular-target "${path}" || return "$?"
  done
  if file::_requires-root "${paths[@]}"; then
    bashstock::_run-as-root replace-all-text-in-files "$@"
    return
  fi
  file::_replace-text-in-files 1 "$@"
}

# @description Replace line matches or append one line when no match exists.
# @internal
file::_replace-text-or-append() {
  if [[ "$#" -ne 4 ]] ||
    ! ( [[ "$4" -eq 0 || "$4" -eq 1 ]] ) ||
    ! string::_require-one-line "$2" ||
    ! string::_require-one-line "$3"; then
    return 64
  fi
  local replace_all="$4"
  file::_require-existing "$1" || return "$?"
  file::_require-no-nul "$1" || return "$?"
  file::_require-bash-expression "$2" "${replace_all}" || return "$?"

  local temporary=''
  temporary="$(file::_prepare-replacement \
    "$1" "$2" "$3" 1 "${replace_all}")" || return "$?"
  if ! mv -f -- "${temporary}" "$1" 2>/dev/null; then
    rm -f -- "${temporary}"
    return 74
  fi
}

# @description Replace every line match or append one line when no match exists.
#
# Only the matched text is replaced, so anchor the expression with ^ and $ to
# replace a whole line.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Bash extended regular expression that cannot match an empty string.
# @arg $3 string Literal one-line text used as the replacement and as the appended line.
# @exitcode 0 The file was updated.
# @exitcode 64 The expression or text is invalid, or the argument count is not three.
# @exitcode 66 The file is missing, not a regular file, or a symbolic link.
# @exitcode 74 The file could not be rewritten.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::replace-text-or-append "${HOME}/.zshrc" '^export EDITOR=.*$' 'export EDITOR=vim'
file::replace-text-or-append() {
  if [[ "$#" -ne 3 ]]; then
    return 64
  fi
  file::_require-regular-target "$1" || return "$?"
  file::_require-bash-expression "$2" 1 || return "$?"
  string::_require-one-line "$3" || return "$?"
  if file::_requires-root "$1"; then
    bashstock::_run-as-root replace-or-append-text "$@"
    return
  fi
  file::_replace-text-or-append "$@" 1
}

# @description Replace matching text or append it using the established API name.
#
# Same as file::replace-text-or-append.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Bash extended regular expression that cannot match an empty string.
# @arg $3 string Literal one-line text.
# @exitcode 0 The file was updated.
# @exitcode 64 An argument is invalid.
# @exitcode 66 The file is missing, not a regular file, or a symbolic link.
# @exitcode 74 The file could not be rewritten.
# @example
#   file::replace-or-append-text /etc/environment '^LANG=.*$' 'LANG=en_US.UTF-8'
file::replace-or-append-text() {
  file::replace-text-or-append "$@"
}


# @description Append text through the root execution dispatcher.
#
# Same as file::append-text, but always in a separate root process.
#
# @arg $1 string File path; a symbolic link is refused.
# @arg $2 string Text to append.
# @exitcode 0 The text was appended.
# @exitcode 64 The argument count is not two, or the path is invalid.
# @exitcode 74 The file could not be written.
# @exitcode 77 sudo refused the credentials.
# @example
#   file::append-text-as-root /etc/hosts $'192.0.2.10 build-server\n'
file::append-text-as-root() {
  [[ "$#" -eq 2 ]] || return 64
  bashstock::_run-as-root append-text "$@"
}

# @description Replace the first expression match through the root execution dispatcher.
#
# Same as file::replace-text, but always in a separate root process.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Nonempty Bash extended regular expression.
# @arg $3 string Literal one-line replacement text.
# @exitcode 0 The file was processed.
# @exitcode 64 An argument is invalid.
# @exitcode 66 The file is missing or not a regular file.
# @exitcode 74 The file could not be rewritten.
# @exitcode 77 sudo refused the credentials.
# @example
#   file::replace-text-as-root /etc/default/grub '^GRUB_TIMEOUT=.*$' 'GRUB_TIMEOUT=3'
file::replace-text-as-root() {
  [[ "$#" -eq 3 ]] || return 64
  bashstock::_run-as-root replace-text "$@"
}

# @description Replace every expression match through the root execution dispatcher.
#
# Same as file::replace-all-text, but always in a separate root process.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Bash extended regular expression that cannot match an empty string.
# @arg $3 string Literal one-line replacement text.
# @exitcode 0 The file was processed.
# @exitcode 64 An argument is invalid.
# @exitcode 66 The file is missing or not a regular file.
# @exitcode 74 The file could not be rewritten.
# @exitcode 77 sudo refused the credentials.
# @example
#   file::replace-all-text-as-root /etc/apt/sources.list 'http://archive' 'https://archive'
file::replace-all-text-as-root() {
  [[ "$#" -eq 3 ]] || return 64
  bashstock::_run-as-root replace-all-text "$@"
}

# @description Replace expression matches in files through the root execution dispatcher.
#
# Same as file::replace-text-in-files, but always in a separate root process.
#
# @arg $1 string Nonempty Bash extended regular expression.
# @arg $2 string Literal one-line replacement text.
# @arg $@ string Regular text files to update; at least one.
# @exitcode 0 The files were processed.
# @exitcode 64 An argument is invalid, or fewer than three arguments were given.
# @exitcode 66 A file is missing or not a regular file.
# @exitcode 74 A file could not be rewritten.
# @exitcode 77 sudo refused the credentials.
# @example
#   file::replace-text-in-files-as-root '^Port .*$' 'Port 2222' /etc/ssh/sshd_config
file::replace-text-in-files-as-root() {
  [[ "$#" -ge 3 ]] || return 64
  bashstock::_run-as-root replace-text-in-files "$@"
}

# @description Replace all expression matches in files through the root execution dispatcher.
#
# Same as file::replace-all-text-in-files, but always in a separate root process.
#
# @arg $1 string Bash extended regular expression that cannot match an empty string.
# @arg $2 string Literal one-line replacement text.
# @arg $@ string Regular text files to update; at least one.
# @exitcode 0 The files were processed.
# @exitcode 64 An argument is invalid, or fewer than three arguments were given.
# @exitcode 66 A file is missing or not a regular file.
# @exitcode 74 A file could not be rewritten.
# @exitcode 77 sudo refused the credentials.
# @example
#   file::replace-all-text-in-files-as-root 'old-mirror' 'new-mirror' /etc/apt/sources.list.d/*.list
file::replace-all-text-in-files-as-root() {
  [[ "$#" -ge 3 ]] || return 64
  bashstock::_run-as-root replace-all-text-in-files "$@"
}

# @description Replace matching text or append it through the root execution dispatcher.
#
# Same as file::replace-text-or-append, but always in a separate root process.
#
# @arg $1 string Regular text file to update.
# @arg $2 string Bash extended regular expression that cannot match an empty string.
# @arg $3 string Literal one-line text.
# @exitcode 0 The file was updated.
# @exitcode 64 An argument is invalid.
# @exitcode 66 The file is missing or not a regular file.
# @exitcode 74 The file could not be rewritten.
# @exitcode 77 sudo refused the credentials.
# @example
#   file::replace-or-append-text-as-root /etc/sysctl.conf '^vm\.swappiness=.*$' 'vm.swappiness=10'
file::replace-or-append-text-as-root() {
  [[ "$#" -eq 3 ]] || return 64
  bashstock::_run-as-root replace-or-append-text "$@"
}
