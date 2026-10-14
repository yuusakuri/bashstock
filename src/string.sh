#!/usr/bin/env bash
# @file string
# @brief String transformation, splitting, and comparison.
# @description Each function reads its input from arguments and writes the result to standard output.

# shellcheck disable=SC2119,SC2120,SC2233,SC2234

# @description Require one argument that contains no newline.
# @internal
string::_require-one-line() {
  if [[ "$#" -ne 1 || "$1" == *$'\n'* ]]; then
    return 64
  fi
}

# @description Require one non-empty argument that contains no newline.
# @internal
string::_require-non-empty-line() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    return 64
  fi

  string::_require-one-line "$1"
}

# @description Require the current locale to use UTF-8.
# @internal
string::_require-utf8-locale() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  if ! command -v locale >/dev/null 2>&1; then
    console::_write-error 'A UTF-8 locale is required.'
    return 69
  fi

  local character_map=''
  character_map="$(locale charmap 2>/dev/null)" || {
    console::_write-error 'A UTF-8 locale is required.'
    return 69
  }
  case "${character_map}" in
    UTF-8 | UTF8 | utf-8 | utf8)
      return 0
      ;;
    *)
      console::_write-error 'A UTF-8 locale is required.'
      return 69
      ;;
  esac
}

# @description Remove leading and trailing whitespace.
#
# @arg $1 string Value to trim.
# @stdout The value without leading and trailing whitespace.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::trim '  hello world  '
#   # hello world
string::trim() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local first=''
  local last=''

  while [[ -n "${value}" ]]; do
    first="${value:0:1}"
    if [[ "${first}" != [[:space:]] ]]; then
      break
    fi
    value="${value:1}"
  done

  while [[ -n "${value}" ]]; do
    last="${value:$((${#value} - 1)):1}"
    if [[ "${last}" != [[:space:]] ]]; then
      break
    fi
    value="${value:0:$((${#value} - 1))}"
  done

  printf '%s\n' "${value}"
}

# @description Trim whitespace and collapse each interior run to one ASCII space.
#
# @arg $1 string Value to normalize.
# @stdout The trimmed value with single spaces between words.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::collapse-whitespace $'  a\t b   c '
#   # a b c
string::collapse-whitespace() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local result=''
  local character=''
  local whitespace='1'
  local index=''

  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    if [[ "${character}" == [[:space:]] ]]; then
      whitespace='1'
    else
      if [[ "${whitespace}" -eq 1 && -n "${result}" ]]; then
        result+=' '
      fi
      result+="${character}"
      whitespace='0'
    fi
  done

  printf '%s\n' "${result}"
}

# @description Split a value by a non-empty literal delimiter and preserve empty fields.
#
# @arg $1 string Value without newlines.
# @arg $2 string Literal delimiter; it must not be empty.
# @stdout Each field on its own line, including empty fields.
# @exitcode 0 The fields were written.
# @exitcode 64 The delimiter is empty, or a value contains a newline.
# @example
#   string::split 'a,,b' ','
#   # a
#   #
#   # b
string::split() {
  if [[ "$#" -ne 2 || -z "$2" ]] ||
    ! string::_require-one-line "$1" ||
    ! string::_require-one-line "$2"; then
    return 64
  fi

  local value="$1"
  local delimiter="$2"
  local part=''

  while [[ "${value}" == *"${delimiter}"* ]]; do
    part="${value%%"${delimiter}"*}"
    printf '%s\n' "${part}"
    value="${value#*"${delimiter}"}"
  done
  printf '%s\n' "${value}"
}

# @description Translate ASCII letter case according to the requested mode.
# @internal
string::_translate-ascii() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi

  local value="$1"
  local mode="$2"
  local upper='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local lower='abcdefghijklmnopqrstuvwxyz'
  local character=''
  local prefix=''
  local index=''
  local result=''
  local position=''
  local LC_ALL=C

  for ((position = 0; position < ${#value}; position++)); do
    character="${value:position:1}"
    case "${mode}:${character}" in
      lower:[A-Z])
        prefix="${upper%%"${character}"*}"
        index="${#prefix}"
        result+="${lower:index:1}"
        ;;
      upper:[a-z])
        prefix="${lower%%"${character}"*}"
        index="${#prefix}"
        result+="${upper:index:1}"
        ;;
      swap:[A-Z])
        prefix="${upper%%"${character}"*}"
        index="${#prefix}"
        result+="${lower:index:1}"
        ;;
      swap:[a-z])
        prefix="${lower%%"${character}"*}"
        index="${#prefix}"
        result+="${upper:index:1}"
        ;;
      *)
        result+="${character}"
        ;;
    esac
  done

  printf '%s\n' "${result}"
}

# @description Convert ASCII uppercase letters to lowercase.
#
# Letters outside ASCII are left unchanged, whatever the locale.
#
# @arg $1 string Value to convert.
# @stdout The converted value.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::lower 'Hello World'
#   # hello world
string::lower() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::_translate-ascii "$1" lower
}

# @description Convert ASCII lowercase letters to uppercase.
#
# Letters outside ASCII are left unchanged, whatever the locale.
#
# @arg $1 string Value to convert.
# @stdout The converted value.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::upper 'Hello World'
#   # HELLO WORLD
string::upper() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::_translate-ascii "$1" upper
}

# @description Swap the case of every ASCII letter.
#
# @arg $1 string Value to convert.
# @stdout The value with uppercase and lowercase ASCII letters swapped.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::swap-case 'Hello World'
#   # hELLO wORLD
string::swap-case() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::_translate-ascii "$1" swap
}

# @description Convert the first ASCII letter to lowercase when applicable.
#
# @arg $1 string Value to convert.
# @stdout The value with its first character lowercased when it is an ASCII letter.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::lower-first 'Hello'
#   # hello
string::lower-first() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  if [[ -z "$1" ]]; then
    printf '\n'
    return 0
  fi

  local first=''
  first="$(string::lower "${1:0:1}")" || return "$?"
  printf '%s%s\n' "${first}" "${1:1}"
}

# @description Convert the first ASCII letter to uppercase when applicable.
#
# @arg $1 string Value to convert.
# @stdout The value with its first character uppercased when it is an ASCII letter.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::upper-first 'hello'
#   # Hello
string::upper-first() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  if [[ -z "$1" ]]; then
    printf '\n'
    return 0
  fi

  local first=''
  first="$(string::upper "${1:0:1}")" || return "$?"
  printf '%s%s\n' "${first}" "${1:1}"
}

# @description Remove one matching pair of surrounding single or double quotes.
#
# @arg $1 string Value that may be quoted.
# @stdout The value without the surrounding pair, or the value unchanged.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::strip-surrounding-quotes '"/opt/my app"'
#   # /opt/my app
string::strip-surrounding-quotes() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  if [[ "${#value}" -ge 2 ]]; then
    if [[ "${value:0:1}" == "'" && "${value:$((${#value} - 1)):1}" == "'" ]] ||
      [[ "${value:0:1}" == '"' && "${value:$((${#value} - 1)):1}" == '"' ]]; then
      value="${value:1:$((${#value} - 2))}"
    fi
  fi
  printf '%s\n' "${value}"
}

# @description Remove every substring that matches a Bash pattern.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern, such as [0-9] or a literal text.
# @stdout The value without the matching substrings.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not two.
# @example
#   string::remove-all-matches 'a1b2c3' '[0-9]'
#   # abc
string::remove-all-matches() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1//$2/}"
}

# @description Remove the first substring that matches a Bash pattern.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern.
# @stdout The value without the first matching substring.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not two.
# @example
#   string::remove-first-match 'a-b-c' '-'
#   # ab-c
string::remove-first-match() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1/$2/}"
}

# @description Remove the longest prefix that matches a Bash pattern.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern for the prefix.
# @stdout The value without the longest matching prefix.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not two.
# @example
#   string::remove-prefix '/usr/local/bin/node' '*/'
#   # node
string::remove-prefix() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1##$2}"
}

# @description Remove the longest suffix that matches a Bash pattern.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern for the suffix.
# @stdout The value without the longest matching suffix.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not two.
# @example
#   string::remove-suffix 'archive.tar.gz' '.*'
#   # archive
string::remove-suffix() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${1%%$2}"
}

# @description Percent-encode a UTF-8 string byte by byte.
#
# Unreserved characters (letters, digits, -, ., _, ~) are kept; every other byte is encoded.
#
# @arg $1 string Value to encode.
# @stdout The percent-encoded value.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::encode-url 'a b&c'
#   # a%20b%26c
string::encode-url() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local character=''
  local encoded=''
  local hex=''
  local code=''
  local index=''
  local LC_ALL=C

  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    case "${character}" in
      [a-zA-Z0-9.~_-])
        encoded+="${character}"
        ;;
      *)
        printf -v code '%d' "'${character}"
        code="$((code & 255))"
        printf -v hex '%02X' "${code}"
        encoded+="%${hex}"
        ;;
    esac
  done

  printf '%s\n' "${encoded}"
}

# @description Decode percent-encoded bytes without translating plus signs.
#
# @arg $1 string Percent-encoded value.
# @stdout The decoded value.
# @exitcode 0 The value was written.
# @exitcode 64 The argument count is not one, or an escape is malformed.
# @example
#   string::decode-url 'a%20b%26c'
#   # a b&c
string::decode-url() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  local value="$1"
  local decoded=''
  local byte=''
  local hex=''
  local index='0'
  local LC_ALL=C

  while ((index < ${#value})); do
    if [[ "${value:index:1}" == '%' ]]; then
      if ((index + 2 >= ${#value})); then
        return 64
      fi
      hex="${value:index+1:2}"
      if ! ( [[ "${hex}" =~ ^[0-9A-Fa-f]{2}$ ]] ) || [[ "${hex}" == '00' ]]; then
        return 64
      fi
      printf -v byte '%b' "\\x${hex}"
      decoded+="${byte}"
      index=$((index + 3))
    else
      decoded+="${value:index:1}"
      index=$((index + 1))
    fi
  done

  printf '%s\n' "${decoded}"
}

# @description Test whether a value contains a literal substring.
#
# @arg $1 string Value to search.
# @arg $2 string Literal substring.
# @exitcode 0 The value contains the substring.
# @exitcode 1 The value does not contain the substring.
# @exitcode 64 The argument count is not two.
# @example
#   string::contains "${PATH}" /usr/local/bin && printf 'on PATH\n'
string::contains() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  [[ "$1" == *"$2"* ]]
}

# @description Test whether a value starts with a literal prefix.
#
# @arg $1 string Value to test.
# @arg $2 string Literal prefix.
# @exitcode 0 The value starts with the prefix.
# @exitcode 1 The value does not start with the prefix.
# @exitcode 64 The argument count is not two.
# @example
#   string::starts-with "${url}" https:// || return 64
string::starts-with() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  [[ "${1:0:${#2}}" == "$2" ]]
}

# @description Test whether a value ends with a literal suffix.
#
# @arg $1 string Value to test.
# @arg $2 string Literal suffix; an empty suffix always matches.
# @exitcode 0 The value ends with the suffix.
# @exitcode 1 The value does not end with the suffix.
# @exitcode 64 The argument count is not two.
# @example
#   string::ends-with "${file}" .tar.gz && tar -xzf "${file}"
string::ends-with() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  if [[ -z "$2" ]]; then
    return 0
  fi
  if [[ "${#2}" -gt "${#1}" ]]; then
    return 1
  fi
  [[ "${1:$((${#1} - ${#2}))}" == "$2" ]]
}

# @description Join values with a literal delimiter.
#
# @arg $1 string Delimiter.
# @arg $@ string Values to join.
# @stdout The values joined by the delimiter, followed by a newline.
# @exitcode 0 The joined value was written.
# @exitcode 64 No delimiter was given.
# @example
#   string::join , a b c
#   # a,b,c
string::join() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi

  local delimiter="$1"
  local value=''
  local first='1'
  shift

  for value in "$@"; do
    if [[ "${first}" -eq 0 ]]; then
      printf '%s' "${delimiter}"
    fi
    printf '%s' "${value}"
    first='0'
  done
  printf '\n'
}

# @description Write the byte length of a value.
#
# @arg $1 string Value to measure.
# @stdout The number of bytes.
# @exitcode 0 The length was written.
# @exitcode 64 The argument count is not one.
# @example
#   string::byte-length 'あ'
#   # 3
string::byte-length() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  local LC_ALL=C
  printf '%s\n' "${#1}"
}

# @description Write the character length of a value in a UTF-8 locale.
#
# @arg $1 string Value to measure.
# @stdout The number of characters.
# @exitcode 0 The length was written.
# @exitcode 64 The argument count is not one.
# @exitcode 69 The current locale does not use UTF-8.
# @example
#   LC_ALL=C.UTF-8 string::length 'あい'
#   # 2
string::length() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  string::_require-utf8-locale || return "$?"
  printf '%s\n' "${#1}"
}

# @description Replace the first substring that matches a Bash pattern.
#
# Backslashes and ampersands in the replacement are literal, also in Bash 5.2
# where patsub_replacement is enabled.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern; it must not be empty.
# @arg $3 string Literal replacement.
# @stdout The value with the first match replaced.
# @exitcode 0 The value was written.
# @exitcode 64 The pattern is empty, or the argument count is not three.
# @example
#   string::replace-first 'a-b-c' '-' '+'
#   # a+b-c
string::replace-first() {
  if [[ "$#" -ne 3 || -z "$2" ]]; then
    return 64
  fi
  local value="$1"
  local pattern="$2"
  local replacement="$3"
  if shopt -q patsub_replacement 2>/dev/null; then
    replacement="${replacement//\\/\\\\}"
    replacement="${replacement//&/\\&}"
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${value/$pattern/$replacement}"
}

# @description Replace every substring that matches a Bash pattern.
#
# Backslashes and ampersands in the replacement are literal.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern; it must not be empty.
# @arg $3 string Literal replacement.
# @stdout The value with every match replaced.
# @exitcode 0 The value was written.
# @exitcode 64 The pattern is empty, or the argument count is not three.
# @example
#   string::replace-all 'a-b-c' '-' '+'
#   # a+b+c
string::replace-all() {
  if [[ "$#" -ne 3 || -z "$2" ]]; then
    return 64
  fi
  local value="$1"
  local pattern="$2"
  local replacement="$3"
  if shopt -q patsub_replacement 2>/dev/null; then
    replacement="${replacement//\\/\\\\}"
    replacement="${replacement//&/\\&}"
  fi
  # shellcheck disable=SC2295
  printf '%s\n' "${value//$pattern/$replacement}"
}

# @description Replace the rightmost non-empty substring that matches a Bash pattern.
#
# @arg $1 string Value to edit.
# @arg $2 string Bash pattern; it must not be empty.
# @arg $3 string Literal replacement.
# @stdout The value with the last match replaced.
# @exitcode 0 The value was written.
# @exitcode 64 The pattern is empty, or the argument count is not three.
# @example
#   string::replace-last 'a-b-c' '-' '+'
#   # a-b+c
string::replace-last() {
  if [[ "$#" -ne 3 || -z "$2" ]]; then
    return 64
  fi

  local value="$1"
  local pattern="$2"
  local replacement="$3"
  local candidate=''
  local matched=''
  local start=''
  local length=''

  for ((start = ${#value} - 1; start >= 0; start--)); do
    candidate="${value:start}"
    for ((length = ${#candidate}; length >= 1; length--)); do
      matched="${candidate:0:length}"
      # shellcheck disable=SC2053
      if [[ "${matched}" == ${pattern} ]]; then
        printf '%s%s%s\n' \
          "${value:0:start}" \
          "${replacement}" \
          "${candidate:length}"
        return 0
      fi
    done
  done

  printf '%s\n' "${value}"
}

# @description Require a named value to be non-empty.
#
# @arg $1 string Name of the value for the message.
# @arg $2 string Value to check.
# @stderr A message naming the value when it is empty.
# @exitcode 0 The value is not empty.
# @exitcode 64 The value is empty, or the name is invalid.
# @example
#   string::require-non-empty USER_NAME "${user_name}" || return "$?"
string::require-non-empty() {
  if [[ "$#" -ne 2 ]] || ! string::_require-non-empty-line "$1"; then
    return 64
  fi
  if [[ -n "$2" ]]; then
    return 0
  fi
  console::_write-error "$1 must not be empty."
  return 64
}

# @description Require a named value to be empty.
#
# @arg $1 string Name of the value for the message.
# @arg $2 string Value to check.
# @stderr A message naming the value when it is not empty.
# @exitcode 0 The value is empty.
# @exitcode 64 The value is not empty, or the name is invalid.
# @example
#   string::require-empty REMAINDER "${remainder}" || return "$?"
string::require-empty() {
  if [[ "$#" -ne 2 ]] || ! string::_require-non-empty-line "$1"; then
    return 64
  fi
  if [[ -z "$2" ]]; then
    return 0
  fi
  console::_write-error "$1 must be empty."
  return 64
}

# @description Require a named value to equal one of the allowed values.
#
# @arg $1 string Name of the value for the message.
# @arg $2 string Value to check.
# @arg $@ string Allowed values; at least one is required.
# @stderr A message listing the allowed values when the value is not one of them.
# @exitcode 0 The value equals an allowed value.
# @exitcode 64 The value is not allowed, or the arguments are invalid.
# @example
#   string::require-allowed SOURCE "${source}" os official || return "$?"
string::require-allowed() {
  if [[ "$#" -lt 3 ]] || ! string::_require-non-empty-line "$1"; then
    return 64
  fi

  local name="$1"
  local value="$2"
  local allowed=''
  shift 2

  for allowed in "$@"; do
    if [[ "${value}" == "${allowed}" ]]; then
      return 0
    fi
  done

  console::_write-error "${name} has an unsupported value."
  return 64
}

# @description Write a validated character range from a UTF-8 string.
#
# @arg $1 string Value to slice.
# @arg $2 integer Start index, counted in characters from 0.
# @arg $3 integer Optional end index, exclusive. Defaults to the length.
# @stdout The characters from START up to, but not including, END.
# @exitcode 0 The range was written.
# @exitcode 64 An index is not a non-negative integer, START is after END, or END exceeds the length.
# @exitcode 69 The current locale does not use UTF-8.
# @example
#   LC_ALL=C.UTF-8 string::slice 'こんにちは' 1 3
#   # んに
string::slice() {
  if [[ "$#" -lt 2 || "$#" -gt 3 ]] ||
    ! number::_is-non-negative-integer-at-most "$2" 2147483647; then
    return 64
  fi
  string::_require-utf8-locale || return "$?"

  local value="$1"
  local start="$2"
  local end="${3-${#1}}"
  local length="${#value}"

  if ! number::_is-non-negative-integer-at-most "${end}" 2147483647; then
    return 64
  fi
  if ((10#${start} > 10#${end} || 10#${end} > length)); then
    return 64
  fi
  printf '%s\n' "${value:10#${start}:10#${end}-10#${start}}"
}
