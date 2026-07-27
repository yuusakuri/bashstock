#!/usr/bin/env bash
# shellcheck disable=SC2234

number::is-integer() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?[0-9]+$ ]] )
}

number::is-decimal() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?([0-9]+\.[0-9]*|\.[0-9]+)$ ]] )
}

number::is-number() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi

  ( [[ "$1" =~ ^[+-]?([0-9]+|[0-9]+\.[0-9]*|\.[0-9]+)$ ]] )
}
