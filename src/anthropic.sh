#!/usr/bin/env bash
# @file anthropic
# @brief Shared Anthropic package signing.
# @description The module defines internal functions that the Claude installers share.

# shellcheck disable=SC2119,SC2120

# @description Download Anthropic's package signing key and verify its published fingerprint.
# @internal
anthropic::_download-signing-key() {
  [[ "$#" -eq 2 && "$1" == https://* && -n "$2" ]] || return 64
  package::_download-signing-key "$1" 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE "$2"
}
