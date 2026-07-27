#!/usr/bin/env bash
# shellcheck disable=SC2119

if [[ "${MODERN_BASH_CLI_LOADED:-0}" == '1' ]]; then
  return 0
fi

if [[ -z "${MODERN_BASH_CLI_ROOT:-}" ]]; then
  MODERN_BASH_CLI_ROOT="$(
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P
  )"
fi

source "${MODERN_BASH_CLI_ROOT}/src/core/core.sh"
source "${MODERN_BASH_CLI_ROOT}/src/array/array.sh"
source "${MODERN_BASH_CLI_ROOT}/src/number/number.sh"
source "${MODERN_BASH_CLI_ROOT}/src/string/string.sh"
source "${MODERN_BASH_CLI_ROOT}/src/system/system.sh"
source "${MODERN_BASH_CLI_ROOT}/src/command/command.sh"
source "${MODERN_BASH_CLI_ROOT}/src/shell/shell.sh"
source "${MODERN_BASH_CLI_ROOT}/src/terminal/terminal.sh"
source "${MODERN_BASH_CLI_ROOT}/src/path/path.sh"
source "${MODERN_BASH_CLI_ROOT}/src/prompt/prompt.sh"
source "${MODERN_BASH_CLI_ROOT}/src/time/time.sh"
source "${MODERN_BASH_CLI_ROOT}/src/log/log.sh"
source "${MODERN_BASH_CLI_ROOT}/src/json/json.sh"
source "${MODERN_BASH_CLI_ROOT}/src/option/option.sh"
source "${MODERN_BASH_CLI_ROOT}/src/file/file.sh"
source "${MODERN_BASH_CLI_ROOT}/src/platform/platform.sh"

case "$(platform::__identifier)" in
  darwin)
    source "${MODERN_BASH_CLI_ROOT}/src/platform/darwin.sh"
    ;;
  ubuntu)
    source "${MODERN_BASH_CLI_ROOT}/src/platform/ubuntu.sh"
    ;;
  fedora)
    source "${MODERN_BASH_CLI_ROOT}/src/platform/fedora.sh"
    ;;
esac

source "${MODERN_BASH_CLI_ROOT}/src/user/user.sh"

MODERN_BASH_CLI_LOADED='1'
