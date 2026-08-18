#!/usr/bin/env bash
# shellcheck disable=SC2234

### Require a readable regular file that is not a symbolic link.
file::_require-existing() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi
  if [[ -L "$1" || ! -f "$1" || ! -r "$1" ]]; then
    return 66
  fi
}

### Require a one-line expression that compiles as a Perl regular expression.
file::_require-expression() {
  if [[ "$#" -ne 1 ]] || ! string::_require-one-line "$1"; then
    return 64
  fi
  command -v perl >/dev/null 2>&1 || return 69
  perl -e 'my $expression = shift; eval { qr/$expression/ }; exit($@ ? 64 : 0)' \
    -- "$1" 2>/dev/null
}

### Copy file content and metadata to another path.
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

### Create a temporary path beside the target file.
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

### Prepare a metadata-preserving replacement file.
file::_prepare-replacement() {
  if [[ "$#" -ne 4 ]]; then
    return 64
  fi

  local source="$1"
  local expression="$2"
  local replacement="$3"
  local append_when_missing="$4"
  local temporary=''
  local status=''

  temporary="$(file::_temporary-path "${source}")" || return "$?"
  if ! file::_copy-metadata-and-content "${source}" "${temporary}"; then
    rm -f -- "${temporary}"
    return 74
  fi

  if perl -e '
    use strict;
    use warnings;
    my ($source, $target, $expression, $replacement, $append_when_missing) = @ARGV;
    my $regex = eval { qr/$expression/ };
    exit 64 if $@;
    open my $input, "<", $source or exit 74;
    open my $output, ">", $target or exit 74;
    binmode $input;
    binmode $output;
    my $changed = 0;
    my $saw_bytes = 0;
    my $last_byte = "";
    while (defined(my $line = <$input>)) {
      $saw_bytes = 1 if length $line;
      my $count = ($line =~ s/$regex/$replacement/);
      $changed = 1 if $count;
      $last_byte = substr($line, -1, 1) if length $line;
      print {$output} $line or exit 74;
    }
    close $input or exit 74;
    if (!$changed && $append_when_missing) {
      print {$output} "\n" if $saw_bytes && $last_byte ne "\n";
      print {$output} $replacement, "\n" or exit 74;
      $changed = 1;
    }
    close $output or exit 74;
    exit($changed ? 0 : 1);
  ' -- "${source}" "${temporary}" "${expression}" "${replacement}" \
    "${append_when_missing}"; then
    printf '%s\n' "${temporary}"
    return 0
  else
    status="$?"
  fi

  rm -f -- "${temporary}"
  case "${status}" in
    1 | 64 | 69 | 74)
      return "${status}"
      ;;
    *)
      return 74
      ;;
  esac
}

### Test whether any file line matches a Perl regular expression.
file::contains-match() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  file::_require-existing "$1" || return "$?"
  file::_require-expression "$2" || return "$?"

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

### Test a file against an expected SHA-256 digest.
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

### Append text without conversion using the current user's permissions.
file::append-text() {
  if [[ "$#" -ne 2 || -z "$1" || -L "$1" ]]; then
    return 64
  fi
  if [[ -e "$1" && ! -f "$1" ]]; then
    return 66
  fi

  printf '%s' "$2" >>"$1" 2>/dev/null || return 74
}

### Append text without conversion through the root helper.
file::append-text-as-root() {
  if [[ "$#" -ne 2 || -z "$1" || -L "$1" ]]; then
    return 64
  fi
  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    append-text "$1" "$2"
}

### Replace the first Perl regular-expression match on every file line.
file::replace-text() {
  if [[ "$#" -ne 3 ]] ||
    ! string::_require-one-line "$2" ||
    ! string::_require-one-line "$3"; then
    return 64
  fi
  file::_require-existing "$1" || return "$?"
  file::_require-expression "$2" || return "$?"

  local temporary=''
  temporary="$(file::_prepare-replacement "$1" "$2" "$3" 0)" || return "$?"
  if ! mv -f -- "${temporary}" "$1" 2>/dev/null; then
    rm -f -- "${temporary}"
    return 74
  fi
}

### Replace line matches through the root helper.
file::replace-text-as-root() {
  if [[ "$#" -ne 3 ]] ||
    ! string::_require-one-line "$2" ||
    ! string::_require-one-line "$3"; then
    return 64
  fi
  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    replace-text "$@"
}

### Replace line matches across files with rollback on failure.
file::_replace-text-in-files() {
  if [[ "$#" -lt 3 ]]; then
    return 64
  fi

  local expression="$1"
  local replacement="$2"
  local paths=()
  local prepared=()
  local backups=()
  local path=''
  local temporary=''
  local backup=''
  local status=''
  local index=''
  local restore_status='0'
  shift 2
  paths=("$@")

  if ! string::_require-one-line "${expression}" ||
    ! string::_require-one-line "${replacement}"; then
    return 64
  fi
  file::_require-expression "${expression}" || return "$?"
  for path in "${paths[@]}"; do
    file::_require-existing "${path}" || return "$?"
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

    temporary="$(file::_prepare-replacement "${path}" "${expression}" "${replacement}" 0)" || {
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

### Replace line matches across multiple files.
file::replace-text-in-files() {
  file::_replace-text-in-files "$@"
}

### Replace line matches across multiple files through the root helper.
file::replace-text-in-files-as-root() {
  if [[ "$#" -lt 3 ]]; then
    return 64
  fi
  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    replace-text-in-files "$@"
}

### Replace line matches or append one line when no match exists.
file::replace-or-append-text() {
  if [[ "$#" -ne 3 ]] ||
    ! string::_require-one-line "$2" ||
    ! string::_require-one-line "$3"; then
    return 64
  fi
  file::_require-existing "$1" || return "$?"
  file::_require-expression "$2" || return "$?"

  local temporary=''
  temporary="$(file::_prepare-replacement "$1" "$2" "$3" 1)" || return "$?"
  if ! mv -f -- "${temporary}" "$1" 2>/dev/null; then
    rm -f -- "${temporary}"
    return 74
  fi
}

### Replace line matches or append through the root helper.
file::replace-or-append-text-as-root() {
  if [[ "$#" -ne 3 ]] ||
    ! string::_require-one-line "$2" ||
    ! string::_require-one-line "$3"; then
    return 64
  fi
  command::run-as-root "${BASHSTOCK_ROOT}/libexec/bashstock-root" \
    replace-or-append-text "$@"
}
