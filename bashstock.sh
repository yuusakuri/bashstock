#!/usr/bin/env bash
# shellcheck disable=SC2119 # The called functions take no arguments.

# BashStock library entry point. Source this file to define every public function.

if [ -n "${_BASHSTOCK_LOADED:-}" ]; then
  return 0
fi
_BASHSTOCK_LOADED=1

if [ -z "${BASHSTOCK_ROOT:-}" ]; then
  BASHSTOCK_ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
fi

# Product identity, diagnostics, values, named arguments, and completion.
source "${BASHSTOCK_ROOT}/src/settings.sh"
source "${BASHSTOCK_ROOT}/src/console.sh"
source "${BASHSTOCK_ROOT}/src/number.sh"
source "${BASHSTOCK_ROOT}/src/string.sh"
source "${BASHSTOCK_ROOT}/src/regex.sh"
source "${BASHSTOCK_ROOT}/src/array.sh"
source "${BASHSTOCK_ROOT}/src/arguments.sh"
source "${BASHSTOCK_ROOT}/src/completion.sh"

# Execution environment, commands, shell, terminal, and paths.
source "${BASHSTOCK_ROOT}/src/system.sh"
source "${BASHSTOCK_ROOT}/src/command.sh"
source "${BASHSTOCK_ROOT}/src/shell.sh"
source "${BASHSTOCK_ROOT}/src/terminal.sh"
source "${BASHSTOCK_ROOT}/src/path.sh"

# Interactive input, clocks, and logs.
source "${BASHSTOCK_ROOT}/src/prompt.sh"
source "${BASHSTOCK_ROOT}/src/time.sh"
source "${BASHSTOCK_ROOT}/src/log.sh"

# Value conditions, option conditions, and file updates.
source "${BASHSTOCK_ROOT}/src/json.sh"
source "${BASHSTOCK_ROOT}/src/option.sh"
source "${BASHSTOCK_ROOT}/src/file.sh"

# Operating-system differences and the provider for the running system.
source "${BASHSTOCK_ROOT}/src/os.sh"
case "$(platform::_identifier)" in
  darwin)
    source "${BASHSTOCK_ROOT}/src/os-darwin.sh"
    ;;
  ubuntu)
    source "${BASHSTOCK_ROOT}/src/os-ubuntu.sh"
    ;;
  fedora)
    source "${BASHSTOCK_ROOT}/src/os-fedora.sh"
    ;;
  *) ;;
esac

# Users, owners, and AWS operations.
source "${BASHSTOCK_ROOT}/src/user.sh"
source "${BASHSTOCK_ROOT}/src/aws.sh"

arg::completion::register-all
