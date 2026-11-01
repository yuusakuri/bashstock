#!/usr/bin/env bash
# @file env
# @brief Environment variables, PATH entries, and dotenv files.
# @description Persistent settings are written once to the startup files of each shell.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Import the variables of a dotenv file into the current process.
#
# The file is parsed as data and never executed. Every line is validated
# before any variable changes; see env::dotenv::_entries for the syntax.
#
# @arg $1 string Regular dotenv file. A symbolic link is refused.
# @set Each variable of the file is set and exported.
# @exitcode 0 The variables were imported.
# @exitcode 64 The argument is not one regular file.
# @exitcode 65 A line is not valid dotenv syntax, or a variable is readonly; no variable changes.
# @exitcode 74 A variable could not be set or exported.
# @exitcode other The status of the parser.
# @example
#   env::dotenv::import .env && printf '%s\n' "${DATABASE_URL}"
env::dotenv::import() {
  [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64
  env::dotenv::_entries "$1" >/dev/null || return "$?"
  local __bashstock_dotenv_key='' __bashstock_dotenv_value=''
  # A readonly variable such as UID cannot be assigned, so the whole file is
  # refused before any variable changes. unset in a subshell fails only then.
  while IFS= read -r -d '' __bashstock_dotenv_key && IFS= read -r -d '' __bashstock_dotenv_value; do
    if ! ( unset -v "${__bashstock_dotenv_key}" ) 2>/dev/null; then
      console::_write-error "${__bashstock_dotenv_key} in $1 is readonly; no variable was imported."
      return 65
    fi
  done < <(env::dotenv::_entries "$1")
  while IFS= read -r -d '' __bashstock_dotenv_key && IFS= read -r -d '' __bashstock_dotenv_value; do
    printf -v "${__bashstock_dotenv_key}" '%s' "${__bashstock_dotenv_value}" 2>/dev/null || return 74
    export "${__bashstock_dotenv_key?}" || return 74
  done < <(env::dotenv::_entries "$1")
}

# @description Write export commands for a dotenv file that Bash and Zsh can evaluate.
# @internal
env::dotenv::_export-commands() {
  [[ "$#" -eq 1 ]] || return 64
  env::dotenv::_entries "$1" >/dev/null || return "$?"
  local key='' value='' quoted=''
  while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    printf -v quoted '%q' "${value}"
    printf 'export %s=%s\n' "${key}" "${quoted}"
  done < <(env::dotenv::_entries "$1")
}

# @description Write the KEY and VALUE of every assignment in a dotenv file as NUL-separated pairs.
#
# Blank lines and lines starting with # are skipped, and an assignment may
# start with export. Unquoted values end at an unescaped # preceded by a
# blank and lose surrounding blanks. Single-quoted values are literal.
# Double-quoted values accept the escapes \n, \t, \r, \", \\, and \$. The
# whole file is validated before anything is written; a malformed line
# returns 65 and writes nothing. The body runs in a subshell, so its regex
# captures do not reach the caller's BASH_REMATCH.
# @internal
env::dotenv::_entries() (
  [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64
  local line='' key='' rest='' value='' character='' quote='' index=0 length=0 number=0
  local entry_keys=() entry_values=()
  while IFS= read -r line || [[ -n "${line}" ]]; do
    number=$((number + 1))
    line="${line%$'\r'}"
    rest="${line#"${line%%[![:space:]]*}"}"
    [[ -z "${rest}" || "${rest}" == \#* ]] && continue
    [[ "${rest}" =~ ^export[[:space:]]+ ]] && rest="${rest#"${BASH_REMATCH[0]}"}"
    if [[ ! "${rest}" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]* ]]; then
      console::_write-error "Invalid dotenv assignment on line ${number} of $1."
      return 65
    fi
    key="${BASH_REMATCH[1]}"
    rest="${rest#"${BASH_REMATCH[0]}"}"
    value=''
    quote="${rest:0:1}"
    if [[ "${quote}" == "'" || "${quote}" == '"' ]]; then
      length="${#rest}"
      index=1
      while ((index < length)); do
        character="${rest:index:1}"
        if [[ "${character}" == "${quote}" ]]; then
          break
        fi
        if [[ "${quote}" == '"' && "${character}" == "\\" ]] && ((index + 1 < length)); then
          index=$((index + 1))
          case "${rest:index:1}" in
            n) character=$'\n' ;;
            t) character=$'\t' ;;
            r) character=$'\r' ;;
            '"' | "\\" | '$') character="${rest:index:1}" ;;
            *) character="\\${rest:index:1}" ;;
          esac
        fi
        value+="${character}"
        index=$((index + 1))
      done
      rest="${rest:index+1}"
      rest="${rest#"${rest%%[![:space:]]*}"}"
      if ((index >= length)) || [[ -n "${rest}" && "${rest}" != \#* ]]; then
        console::_write-error "Unterminated or trailing text in the dotenv value on line ${number} of $1."
        return 65
      fi
    else
      [[ "${rest}" =~ ^(.*[^[:space:]])?[[:space:]]+# ]] && rest="${BASH_REMATCH[1]}"
      value="${rest%"${rest##*[![:space:]]}"}"
    fi
    entry_keys+=("${key}")
    entry_values+=("${value}")
  done <"$1"
  for index in "${!entry_keys[@]}"; do
    printf '%s\0%s\0' "${entry_keys[index]}" "${entry_values[index]}"
  done
)

# @description Set an environment variable for the current shell.
#
# The export line is written to the startup file of each shell, replacing an earlier export of the same name.
#
# @arg $1 string Variable name.
# @arg $2 string Value.
# @arg $3 string Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.
# @set The variable is exported in the current shell.
# @exitcode 0 The variable was set and saved.
# @exitcode 64 The name or the shell list is invalid.
# @exitcode other The status of the file operation that failed.
# @example
#   env::set-variable EDITOR vim bash
env::set-variable() {
  ( [[ "$#" -ge 2 && "$#" -le 3 && "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] ) || return 64
  local name="$1" value="$2" shells="${3:-bash,zsh}" shell='' rc='' quoted=''
  ( [[ "$shells" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] ) || return 64
  printf -v quoted '%q' "$value"
  local _util_shells=()
  IFS=',' read -r -a _util_shells <<<"$shells"
  for shell in "${_util_shells[@]}"; do
    case "$shell" in bash) rc="$HOME/.bashrc" ;; zsh) rc="$HOME/.zshrc" ;; esac
    if [[ ! -e "$rc" ]]; then file::write-text "$rc" '' || return "$?"; fi
    file::replace-text-or-append "$rc" "^export ${name}=.*$" "export ${name}=${quoted}" || return "$?"
  done
  export "${name}=${value}"
}

# @description Add a directory to PATH without creating duplicates.
#
# A line that adds the directory once is written to the startup file of each shell.
#
# @arg $1 string Existing directory.
# @arg $2 string Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.
# @set PATH gains the directory in the current shell when it is missing.
# @exitcode 0 PATH was updated and saved.
# @exitcode 64 The directory does not exist or the shell list is invalid.
# @exitcode other The status of the file operation that failed.
# @example
#   env::add-path "${HOME}/.local/bin"
env::add-path() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" ]] || return 64
  local path="$1" shells="${2:-bash,zsh}" shell='' rc='' quoted='' line=''
  ( [[ "$shells" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] ) || return 64
  printf -v quoted '%q' "$path"
  line="__bashstock_path=${quoted}; case \":\$PATH:\" in *\":\$__bashstock_path:\"*) ;; *) if [ -n \"\$PATH\" ]; then PATH=\"\$PATH:\$__bashstock_path\"; else PATH=\"\$__bashstock_path\"; fi; export PATH ;; esac; unset __bashstock_path"
  local _util_shells=()
  IFS=',' read -r -a _util_shells <<<"$shells"
  for shell in "${_util_shells[@]}"; do
    case "$shell" in bash) rc="$HOME/.bashrc" ;; zsh) rc="$HOME/.zshrc" ;; esac
    if [[ ! -f "$rc" ]] || ! grep -Fqx -- "$line" "$rc"; then
      file::append-text "$rc" "${line}"$'\n' || return "$?"
    fi
  done
  case ":${PATH:-}:" in *":$path:"*) ;; *) PATH="${PATH:+${PATH}:}${path}"; export PATH ;; esac
}

# @description Load a dotenv file in every new Bash and Zsh session.
#
# Bash startup files load BashStock and call env::dotenv::import. Zsh cannot
# load a Bash library, so its startup file asks Bash for the parsed values
# and evaluates the resulting export commands. Each startup file receives the
# line once, and the file is always read as data.
#
# @arg $1 string Regular dotenv file. A relative path is stored as an absolute path.
# @arg $2 string Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.
# @exitcode 0 The startup files load the file.
# @exitcode 64 The file is not a regular file or the shell list is invalid.
# @exitcode other The status of the file operation that failed.
# @example
#   env::dotenv::register "${HOME}/.config/app/.env" zsh
env::dotenv::register() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" && ! -L "$1" ]] || return 64
  local file="$1" shells="${2:-bash,zsh}" shell='' rc='' line='' library='' quoted_file=''
  ( [[ "${shells}" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] ) || return 64
  [[ "${file}" == /* ]] || file="${PWD}/${file}"
  file="$(path::normalize "${file}")" || return "$?"
  printf -v quoted_file '%q' "${file}"
  printf -v library '%q' "${_BASHSTOCK_FILE}"
  local _util_shells=()
  IFS=',' read -r -a _util_shells <<<"${shells}"
  for shell in "${_util_shells[@]}"; do
    case "${shell}" in
      bash)
        rc="${HOME}/.bashrc"
        line="[ -r ${library} ] && . ${library} && env::dotenv::import ${quoted_file}"
        ;;
      zsh)
        rc="${HOME}/.zshrc"
        line="[ -r ${library} ] && eval \"\$(bash -c '. \"\$1\" && env::dotenv::_export-commands \"\$2\"' bashstock ${library} ${quoted_file})\""
        ;;
    esac
    if [[ ! -f "${rc}" ]] || ! grep -Fqx -- "${line}" "${rc}"; then
      file::append-text "${rc}" "${line}"$'\n' || return "$?"
    fi
  done
}
