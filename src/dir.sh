#!/usr/bin/env bash
# @file dir
# @brief Directory creation, comparison, merging, and clearing.
# @description Operations keep the directory itself and act on its entries.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Run diff for two directories.
#
# @arg $1 string Original directory.
# @arg $2 string Changed directory.
# @stdout A unified diff that includes new files.
# @exitcode 0 The directories are identical.
# @exitcode 1 The directories differ.
# @exitcode 64 The argument count is not two or a directory does not exist.
# @exitcode 69 diff is unavailable.
# @exitcode 2 diff failed.
# @example
#   dir::diff config.orig config > config.patch
dir::diff() { [[ "$#" -eq 2 && -d "$1" && -d "$2" ]] || return 64; command -v diff >/dev/null 2>&1 || return 69; diff -uprN -- "$1" "$2"; }

# @description Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE.
#
# Directories are merged recursively. A file or symbolic link in SOURCE
# replaces the entry with the same name in DESTINATION. Symbolic links are
# never followed. The first failure stops the merge.
#
# @arg $1 string SOURCE Directory to empty and remove.
# @arg $2 string DESTINATION Directory to receive the entries; created when missing.
# @exitcode 0 SOURCE was merged into DESTINATION and removed.
# @exitcode 64 SOURCE is not a directory, DESTINATION is a symbolic link or a file, DESTINATION is SOURCE or inside it, or SOURCE holds an entry that would replace SOURCE itself.
# @exitcode 74 An entry could not be moved, or SOURCE could not be removed.
# @example
#   dir::merge "${HOME}/デスクトップ" "${HOME}/Desktop"
dir::merge() {
  [[ "$#" -eq 2 && -d "$1" && ! -L "$1" && -n "$2" ]] || return 64
  local source="$1" destination="$2" entry='' name='' target=''
  local source_path='' destination_path='' created=0
  if [[ -L "${destination}" || (-e "${destination}" && ! -d "${destination}") ]]; then return 64; fi
  [[ -e "${destination}" ]] || created=1
  mkdir -p -- "${destination}" || return 74
  source_path="$(cd -P -- "${source}" && pwd -P)" || return 74
  destination_path="$(cd -P -- "${destination}" && pwd -P)" || return 74
  # Merging a directory into itself or into its own subdirectory would delete
  # the entries being moved, and so would an entry named like SOURCE when
  # DESTINATION is its parent.
  case "${destination_path%/}/" in
    "${source_path%/}/"*)
      [[ "${created}" -eq 0 ]] || rmdir -- "${destination}" 2>/dev/null
      return 64
      ;;
  esac
  if [[ "${destination_path%/}/${source_path##*/}" == "${source_path}" &&
    ( -e "${source}/${source_path##*/}" || -L "${source}/${source_path##*/}" ) ]]; then
    return 64
  fi
  while IFS= read -r -d '' entry; do
    name="${entry##*/}"
    target="${destination}/${name}"
    if [[ -d "${entry}" && ! -L "${entry}" && -d "${target}" && ! -L "${target}" ]]; then
      dir::merge "${entry}" "${target}" || return "$?"
      continue
    fi
    if [[ -e "${target}" || -L "${target}" ]]; then
      rm -rf -- "${target}" || return 74
    fi
    mv -- "${entry}" "${target}" || return 74
  done < <(find "${source}" -mindepth 1 -maxdepth 1 -print0)
  rmdir -- "${source}" || return 74
}

# @description Create a directory named with the local date and time and write its path.
#
# The name has the form YYYYMMDDTHHMMSS. When that name exists, a suffix
# counting from -2 is added.
#
# @arg $1 string DIRECTORY Parent directory. Defaults to the current directory.
# @stdout The path of the new directory, such as ./20261014T120405.
# @exitcode 0 The directory was created.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The parent directory does not exist.
# @exitcode 69 The clock provider is unavailable.
# @exitcode 74 The directory could not be created.
# @example
#   backup="$(dir::create-with-date-time /var/backups)"
dir::create-with-date-time() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-.}" name='' path='' index=2
  [[ -d "${directory}" ]] || return 66
  name="$(time::local-date-time-seconds-basic)" || return "$?"
  path="${directory%/}/${name}"
  until mkdir -- "${path}" 2>/dev/null; do
    [[ -e "${path}" || -L "${path}" ]] || return 74
    path="${directory%/}/${name}-${index}"
    index=$((index + 1))
  done
  printf '%s\n' "${path}"
}

# @description Remove every entry of a directory, including hidden ones, and keep the directory.
#
# An empty name, the file system root, the home directory, and a symbolic
# link are refused, because a link would empty the directory it points to.
#
# @arg $1 string DIRECTORY Directory to empty. Defaults to the current directory.
# @stderr A message when the directory is refused.
# @exitcode 0 The directory is empty.
# @exitcode 64 The directory is missing, a symbolic link, the root, or the home directory.
# @exitcode 66 The directory cannot be entered.
# @exitcode 74 An entry could not be removed.
# @example
#   dir::clear ./build
dir::clear() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1-.}" physical='' home=''
  [[ -n "${directory}" && -d "${directory}" && ! -L "${directory%/}" ]] || return 64
  physical="$(cd -P -- "${directory}" && pwd -P)" || return 66
  home="$(cd -P -- "${HOME:-/}" 2>/dev/null && pwd -P)" || home=''
  if [[ "${physical}" == / || "${physical}" == "${home}" ]]; then
    console::_write-error "Refusing to clear ${physical}."
    return 64
  fi
  find "${physical}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + || return 74
}
