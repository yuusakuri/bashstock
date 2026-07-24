#!/usr/bin/env bash

### Write a greeting a fixed number of times.
###
### Arguments
###
### * name - The name in the greeting.
### * times - The number of lines to write.
###
### Examples
###
### ```bash
### greeting::write 'Alice' 1
### ```
###
### The function writes `Hello, Alice!`.
greeting::write() {
  local name="${1}"
  local times="${2}"
  local index='0'

  while ((index < times)); do
    printf 'Hello, %s!\n' "${name}"
    index=$((index + 1))
  done
}
