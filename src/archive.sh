#!/usr/bin/env bash
# @file archive
# @brief Archive creation, extraction, and verification.
# @description The archive format is chosen from the file extension.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the format and the matched extension of an archive file name.
#
# The formats are tar, tar.gz, tar.xz, tar.bz2, tar.zst, zip, 7z, and the
# single compressed files gz, xz, bz2, and zst.
#
# @internal
archive::_format() {
  [[ "$#" -eq 1 ]] || return 64
  case "$1" in
    *.tar.gz) printf '%s %s\n' tar.gz .tar.gz ;;
    *.tgz) printf '%s %s\n' tar.gz .tgz ;;
    *.tar.xz) printf '%s %s\n' tar.xz .tar.xz ;;
    *.txz) printf '%s %s\n' tar.xz .txz ;;
    *.tar.bz2) printf '%s %s\n' tar.bz2 .tar.bz2 ;;
    *.tbz2) printf '%s %s\n' tar.bz2 .tbz2 ;;
    *.tbz) printf '%s %s\n' tar.bz2 .tbz ;;
    *.tar.zst) printf '%s %s\n' tar.zst .tar.zst ;;
    *.tzst) printf '%s %s\n' tar.zst .tzst ;;
    *.tar) printf '%s %s\n' tar .tar ;;
    *.zip) printf '%s %s\n' zip .zip ;;
    *.7z) printf '%s %s\n' 7z .7z ;;
    *.gz) printf '%s %s\n' gz .gz ;;
    *.xz) printf '%s %s\n' xz .xz ;;
    *.bz2) printf '%s %s\n' bz2 .bz2 ;;
    *.zst) printf '%s %s\n' zst .zst ;;
    *) return 64 ;;
  esac
}

# @description Write the compression command of a compressed tar or single compressed format.
# @internal
archive::_compressor() {
  [[ "$#" -eq 1 ]] || return 64
  case "$1" in
    tar.gz | gz) printf 'gzip\n' ;;
    tar.xz | xz) printf 'xz\n' ;;
    tar.bz2 | bz2) printf 'bzip2\n' ;;
    tar.zst | zst) printf 'zstd\n' ;;
    *) return 64 ;;
  esac
}

# @description Write the 7-Zip command: 7zz or 7z.
# @internal
archive::_7zip() {
  [[ "$#" -eq 0 ]] || return 64
  local name=''
  for name in 7zz 7z; do
    if command -v "${name}" >/dev/null 2>&1; then
      printf '%s\n' "${name}"
      return 0
    fi
  done
  console::_write-error '7-Zip is required: install 7zz or 7z.'
  return 69
}

# @description Write the entry names of an archive, one per line.
#
# The compressed stream is tested in full before tar reads it. An encrypted
# archive whose names 7-Zip or unzip cannot read without the password
# returns 69.
#
# @internal
archive::_list() {
  [[ "$#" -eq 2 && -f "$1" ]] || return 64
  local file="$1" format="$2" compressor='' seven='' listing=''
  case "${format}" in
    tar)
      command::require tar || return "$?"
      tar -tf "${file}" 2>/dev/null || return 65
      ;;
    tar.*)
      compressor="$(archive::_compressor "${format}")" || return "$?"
      command::require "${compressor}" || return "$?"
      command::require tar || return "$?"
      "${compressor}" -tq -- "${file}" >/dev/null 2>&1 || return 65
      # tar may stop at the end-of-archive blocks, so only its status counts here.
      (
        set +o pipefail
        "${compressor}" -dc -- "${file}" 2>/dev/null | tar -tf - 2>/dev/null
      ) || return 65
      ;;
    zip)
      command::require unzip || return "$?"
      unzip -Z1 "${file}" 2>/dev/null || return 65
      ;;
    7z)
      seven="$(archive::_7zip)" || return "$?"
      if ! listing="$("${seven}" l -slt -p -- "${file}" </dev/null 2>&1)"; then
        if [[ "${listing}" == *'Wrong password'* ]]; then
          console::_write-error "${file} is encrypted; its contents cannot be read without the password."
          return 69
        fi
        return 65
      fi
      # Entries follow the dashed separator; the Path before it is the archive itself.
      printf '%s\n' "${listing}" | awk 'entries && /^Path = / { print substr($0, 8) } /^----------$/ { entries = 1 }'
      ;;
    *) return 64 ;;
  esac
}

# @description Verify one archive file.
#
# Returns 0 for a valid archive and 1 for a broken one. An archive that
# cannot be verified, because a tool is missing, the archive is encrypted,
# or the file cannot be read, returns 69 or 66 and is never reported as
# broken.
#
# @internal
archive::_verify-file() {
  [[ "$#" -eq 1 && -f "$1" ]] || return 64
  local file="$1" format='' suffix='' compressor='' seven='' information='' status=0
  read -r format suffix <<<"$(archive::_format "${file}")" || return 64
  [[ -n "${format}" ]] || return 64
  if [[ ! -r "${file}" ]]; then
    console::_write-error "${file} cannot be read."
    return 66
  fi
  case "${format}" in
    gz | xz | bz2 | zst)
      compressor="$(archive::_compressor "${format}")" || return "$?"
      command::require "${compressor}" || return "$?"
      "${compressor}" -tq -- "${file}" >/dev/null 2>&1 || return 1
      ;;
    zip)
      command::require unzip || return "$?"
      information="$(unzip -Zv "${file}" 2>/dev/null)" || return 1
      if grep -Eq 'file security status:[[:space:]]+encrypted' <<<"${information}"; then
        console::_write-error "${file} is encrypted; it cannot be verified without the password."
        return 69
      fi
      unzip -tqq "${file}" </dev/null >/dev/null 2>&1 || return 1
      ;;
    7z)
      archive::_list "${file}" 7z >/dev/null || status="$?"
      case "${status}" in
        0) ;;
        65) return 1 ;;
        *) return "${status}" ;;
      esac
      seven="$(archive::_7zip)" || return "$?"
      information="$("${seven}" l -slt -p -- "${file}" </dev/null 2>/dev/null)" || return 1
      if [[ "${information}" == *'Encrypted = +'* ]]; then
        console::_write-error "${file} is encrypted; it cannot be verified without the password."
        return 69
      fi
      "${seven}" t -p -bd -- "${file}" </dev/null >/dev/null 2>&1 || return 1
      ;;
    *)
      archive::_list "${file}" "${format}" >/dev/null || status="$?"
      case "${status}" in
        0) ;;
        65) return 1 ;;
        *) return "${status}" ;;
      esac
      ;;
  esac
}

# @description Verify all recognized archives below a path.
#
# The recognized extensions are .tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2,
# .tbz2, .tbz, .tar.zst, .tzst, .zip, .7z, .gz, .xz, .bz2, and .zst.
# Compressed data is tested in full, and tar archives are read to the end of
# their entries; the bytes of the files inside a tar archive are covered only
# by the compression checksum. An archive that cannot be verified, because
# its tool is missing, it is encrypted, or it cannot be read, is reported on
# standard error but not counted as broken, and does not change the status.
#
# @arg $1 string Optional archive file or directory to search. Defaults to the current directory.
# @stderr The path of each broken archive, and a message for each archive that cannot be verified.
# @exitcode 0 Every archive is valid.
# @exitcode 1 At least one archive is broken.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The path does not exist or cannot be searched.
# @exitcode 74 The temporary list could not be created.
# @example
#   archive::verify "${HOME}/Downloads"
archive::verify() {
  [[ "$#" -le 1 ]] || return 64
  local file='' list='' result=0 broken=0
  list="$(archive::_found-list "${1:-.}")" || return "$?"
  while IFS= read -r -d '' file; do
    result=0
    archive::_verify-file "${file}" || result="$?"
    # Other statuses mean the archive could not be verified; the reason is already reported.
    [[ "${result}" -ne 1 ]] || { printf '%s\n' "${file}" >&2; broken=1; }
  done <"${list}"
  rm -f -- "${list}"
  [[ "${broken}" -eq 0 ]] || return 1
}

# @description Remove archives that fail verification.
#
# Only archives that archive::verify reports as broken are removed. An
# archive that cannot be verified is kept and does not change the status.
#
# @arg $1 string Optional archive file or directory to search. Defaults to the current directory.
# @stderr The path of each removed archive, and a message for each archive that cannot be verified.
# @exitcode 0 No archive was broken.
# @exitcode 1 At least one broken archive was removed.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The path does not exist or cannot be searched.
# @exitcode 74 A broken archive or the temporary list could not be removed or created.
# @example
#   archive::remove-broken "${HOME}/Downloads"
archive::remove-broken() {
  [[ "$#" -le 1 ]] || return 64
  local file='' list='' result=0 removed=0 status=0
  list="$(archive::_found-list "${1:-.}")" || return "$?"
  while IFS= read -r -d '' file; do
    result=0
    archive::_verify-file "${file}" || result="$?"
    # Other statuses mean the archive could not be verified; it is kept.
    [[ "${result}" -eq 1 ]] || continue
    rm -f -- "${file}" || { status=74; break; }
    printf '%s\n' "${file}" >&2
    removed=1
  done <"${list}"
  rm -f -- "${list}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  [[ "${removed}" -eq 0 ]] || return 1
}

# @description List recognized archive files below a directory as NUL-separated paths.
# @internal
archive::_find() {
  [[ "$#" -le 1 ]] || return 64
  find "${1:-.}" -type f \( -name '*.tar' -o -name '*.tgz' -o -name '*.gz' -o -name '*.txz' -o -name '*.xz' \
    -o -name '*.tbz2' -o -name '*.tbz' -o -name '*.bz2' -o -name '*.tzst' -o -name '*.zst' \
    -o -name '*.zip' -o -name '*.7z' \) -print0
}

# @description Write the recognized archives below a path to a new temporary file and write that file's path.
#
# The list is collected before the archives are read, so a path that does
# not exist or cannot be searched returns 66 instead of an empty result.
# @internal
archive::_found-list() {
  [[ "$#" -eq 1 ]] || return 64
  local list=''
  list="$(mktemp "${TMPDIR:-/tmp}/bashstock-archives.XXXXXX")" || return 74
  if ! archive::_find "$1" >"${list}"; then
    rm -f -- "${list}"
    console::_write-error "$1 cannot be searched for archives."
    return 66
  fi
  printf '%s\n' "${list}"
}

# @description Decompress one single compressed file, such as notes.txt.gz.
# @internal
archive::_extract-stream() {
  [[ "$#" -eq 4 && -f "$1" ]] || return 64
  local file="$1" format="$2" suffix="$3" directory="$4" compressor='' name='' output='' temporary=''
  compressor="$(archive::_compressor "${format}")" || return "$?"
  command::require "${compressor}" || return "$?"
  name="${file##*/}"
  name="${name%"${suffix}"}"
  [[ -n "${name}" ]] || return 64
  [[ -n "${directory}" ]] || directory="$(path::directory-name "${file}")" || return "$?"
  output="${directory%/}/${name}"
  if [[ -d "${output}" ]]; then
    console::_write-error "Not replacing the directory ${output}."
    return 73
  fi
  "${compressor}" -tq -- "${file}" >/dev/null 2>&1 || return 65
  mkdir -p -- "${directory}" || return 74
  temporary="$(mktemp "${directory%/}/.bashstock-extract.XXXXXX")" || return 74
  if ! "${compressor}" -dc -- "${file}" >"${temporary}" 2>/dev/null; then
    rm -f -- "${temporary}"
    return 65
  fi
  # mktemp creates the file with mode 600; give it the mode a new file gets.
  if ! chmod "$(printf '%o' "$((0666 & ~$(umask)))")" "${temporary}" || ! mv -f -- "${temporary}" "${output}"; then
    rm -f -- "${temporary}"
    return 74
  fi
}

# @description Unpack an archive into an empty staging directory.
# @internal
archive::_unpack() {
  [[ "$#" -eq 3 && -f "$1" && -d "$3" ]] || return 64
  local file="$1" format="$2" staging="$3" compressor='' seven=''
  case "${format}" in
    tar) tar -xf "${file}" -C "${staging}" || return 65 ;;
    tar.*)
      compressor="$(archive::_compressor "${format}")" || return "$?"
      (
        set +o pipefail
        "${compressor}" -dc -- "${file}" 2>/dev/null | tar -xf - -C "${staging}"
      ) || return 65
      ;;
    zip) unzip -oq "${file}" -d "${staging}" || return 65 ;;
    7z)
      seven="$(archive::_7zip)" || return "$?"
      "${seven}" x -y -bd "-o${staging}" -- "${file}" >/dev/null || return 65
      ;;
    *) return 64 ;;
  esac
}

# @description Extract one archive or decompress one compressed file.
#
# Archives (.tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2, .tbz2, .tbz,
# .tar.zst, .tzst, .zip, .7z) are extracted into a directory. Entry names that
# are absolute or climb with .. are refused before extraction. The archive is
# extracted into a staging directory inside the destination, and a symbolic
# link that points outside the destination discards the extraction with 65.
# A single compressed file (.gz, .xz, .bz2, .zst) is decompressed into one
# file named without the extension. Existing files are overwritten.
#
# @arg $1 string Archive or compressed file.
# @arg $2 string Optional output directory. Defaults to the archive path without its extension, or to the directory of a single compressed file.
# @stderr The rejected entry or symbolic link when the archive is refused.
# @exitcode 0 The archive was extracted.
# @exitcode 64 The arguments are invalid or the extension is not recognized.
# @exitcode 65 The archive is corrupt or contains an entry outside the destination.
# @exitcode 69 A required tool is unavailable, or the entry names of an encrypted 7z archive cannot be read.
# @exitcode 73 A single compressed file would replace a directory.
# @exitcode 74 The destination could not be written.
# @example
#   archive::extract-file release.tar.xz /opt/release
#   archive::extract-file access.log.gz
archive::extract-file() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  local file="$1" destination="${2:-}" format='' suffix='' listing='' entry='' staging='' link='' target='' resolved='' status=0
  read -r format suffix <<<"$(archive::_format "${file}")" || return 64
  [[ -n "${format}" ]] || return 64
  case "${format}" in
    gz | xz | bz2 | zst)
      archive::_extract-stream "${file}" "${format}" "${suffix}" "${destination}"
      return "$?"
      ;;
  esac
  destination="${destination:-${file%"${suffix}"}}"
  listing="$(archive::_list "${file}" "${format}")" || return "$?"
  while IFS= read -r entry; do
    if [[ "${entry}" == /* || "${entry}" == .. || "${entry}" == ../* || "${entry}" == */../* || "${entry}" == */.. ]]; then
      console::_write-error "Refusing archive entry outside the destination: ${entry}"
      return 65
    fi
  done <<<"${listing}"
  mkdir -p -- "${destination}" || return 74
  staging="$(mktemp -d "${destination%/}/.bashstock-extract.XXXXXX")" || return 74
  archive::_unpack "${file}" "${format}" "${staging}" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    while IFS= read -r -d '' link; do
      target="$(readlink -- "${link}")" || { status=74; break; }
      resolved="$(path::normalize "$(path::directory-name "${link#"${staging}"/}")/${target}")" || { status=74; break; }
      if [[ "${target}" == /* || "${resolved}" == .. || "${resolved}" == ../* ]]; then
        console::_write-error "Refusing symbolic link outside the destination: ${link#"${staging}"/} -> ${target}"
        status=65
        break
      fi
    done < <(find "${staging}" -type l -print0)
  fi
  if [[ "${status}" -ne 0 ]]; then
    rm -rf -- "${staging}"
    return "${status}"
  fi
  dir::merge "${staging}" "${destination}"
}

# @description Compress paths into a gzip-compressed tar archive.
#
# @arg $@ string Paths to add to the archive.
# @option --output <FILE> Archive to write. Defaults to the first path with .tar.gz appended.
# @exitcode 0 The archive was written.
# @exitcode 64 No path was given or --output has no value.
# @exitcode 69 tar is unavailable.
# @exitcode other The status of tar.
# @example
#   archive::compress-tar-gzip --output backup.tar.gz Documents Pictures
archive::compress-tar-gzip() { [[ "$#" -ge 1 ]] || return 64; local output='' paths=() path=''; while [[ "$#" -gt 0 ]]; do if [[ "$1" == '--output' ]]; then [[ "$#" -ge 2 ]] || return 64; output="$2"; shift 2; else paths+=("$1"); shift; fi; done; [[ "${#paths[@]}" -gt 0 ]] || return 64; [[ -n "$output" ]] || output="${paths[0]}.tar.gz"; command -v tar >/dev/null 2>&1 || return 69; tar -czf "$output" -- "${paths[@]}"; }

# @description List the named arguments of archive::compress-tar-gzip.
# @internal
archive::_compress-tar-gzip-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --output; fi
}

# @description Extract one archive, or every recognized archive below a directory, next to itself.
#
# @arg $1 string Optional archive file or directory to search. Defaults to the current directory.
# @exitcode 0 Every archive was extracted.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or cannot be searched.
# @exitcode 74 The temporary list could not be created.
# @exitcode other The status of archive::extract-file for the first archive that failed.
# @example
#   archive::extract "${HOME}/Downloads"
archive::extract() {
  [[ "$#" -le 1 ]] || return 64
  local path="${1:-.}" file='' list='' status=0
  if [[ -f "${path}" ]]; then
    archive::extract-file "${path}"
    return
  fi
  list="$(archive::_found-list "${path}")" || return "$?"
  while IFS= read -r -d '' file; do
    archive::extract-file "${file}" || { status="$?"; break; }
  done <"${list}"
  rm -f -- "${list}"
  return "${status}"
}
