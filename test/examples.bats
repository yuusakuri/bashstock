#!/usr/bin/env bats

load test_helper

# @description Write the @example blocks of a module that state their output.
#
# Each record holds the function name, the example code, and the expected
# output, separated by the ASCII unit separator and ended by the record
# separator; BSD awk cannot write NUL. Example lines that start with # give
# the expected output.
#
# @arg $1 string Module source file.
examples_with_output() {
  awk '
    function flush() {
      if (in_example && expected != "") {
        records[++count] = code SUBSEP expected
      }
      in_example = 0
      code = ""
      expected = ""
    }
    /^[[:space:]]*# @example[[:space:]]*$/ { flush(); in_example = 1; next }
    in_example && /^[[:space:]]*#   / {
      line = $0
      sub(/^[[:space:]]*#   /, "", line)
      if (line ~ /^#/) {
        sub(/^# ?/, "", line)
        expected = expected line "\n"
      } else {
        code = code line "\n"
      }
      next
    }
    /^[[:space:]]*#/ { flush(); next }
    /^[[:space:]]*[a-z][a-z0-9:_-]*\(\)/ {
      flush()
      name = $0
      sub(/^[[:space:]]*/, "", name)
      sub(/\(\).*$/, "", name)
      for (index_ = 1; index_ <= count; index_++) {
        split(records[index_], parts, SUBSEP)
        printf "%s\037%s\037%s\036", name, parts[1], parts[2]
      }
      count = 0
      next
    }
    { flush(); count = 0 }
  ' "$1"
}

# @description Run the examples of a module and compare their standard output.
#
# @arg $1 string Module name.
check_examples() {
  local name='' code='' expected='' actual='' checked=0 failures=0
  while IFS=$'\037' read -r -d $'\036' name code expected; do
    actual="$(bash -c 'source "$1" && eval "$2"' _ "${PROJECT_ROOT}/dist/bashstock.sh" "${code}" 2>/dev/null)" || true
    checked=$((checked + 1))
    if [[ "${actual}" != "${expected%$'\n'}" ]]; then
      printf 'Example of %s\n%s\nexpected:\n%s\nactual:\n%s\n\n' "${name}" "${code}" "${expected}" "${actual}" >&2
      failures=$((failures + 1))
    fi
  done < <(examples_with_output "${PROJECT_ROOT}/src/$1.sh")
  [ "${checked}" -gt 0 ]
  [ "${failures}" -eq 0 ]
}

@test "string examples write the documented output" {
  check_examples string
}

@test "array examples write the documented output" {
  check_examples array
}

@test "regex examples write the documented output" {
  check_examples regex
}

@test "number examples write the documented output" {
  check_examples number
}

@test "path examples write the documented output" {
  check_examples path
}
