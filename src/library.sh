#!/usr/bin/env bash
# shellcheck disable=SC2119

if [[ "${BASHSTOCK_LOADED:-0}" == '1' ]]; then
  return 0
fi

if [[ -z "${BASHSTOCK_ROOT:-}" ]]; then
  BASHSTOCK_ROOT="$(
    CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P
  )"
fi

source "${BASHSTOCK_ROOT}/src/core/core.sh"
source "${BASHSTOCK_ROOT}/src/array/array.sh"
source "${BASHSTOCK_ROOT}/src/number/number.sh"
source "${BASHSTOCK_ROOT}/src/string/string.sh"
source "${BASHSTOCK_ROOT}/src/system/system.sh"
source "${BASHSTOCK_ROOT}/src/command/command.sh"
source "${BASHSTOCK_ROOT}/src/shell/shell.sh"
source "${BASHSTOCK_ROOT}/src/terminal/terminal.sh"
source "${BASHSTOCK_ROOT}/src/path/path.sh"
source "${BASHSTOCK_ROOT}/src/prompt/prompt.sh"
source "${BASHSTOCK_ROOT}/src/time/time.sh"
source "${BASHSTOCK_ROOT}/src/log/log.sh"
source "${BASHSTOCK_ROOT}/src/json/json.sh"
source "${BASHSTOCK_ROOT}/src/option/option.sh"
source "${BASHSTOCK_ROOT}/src/file/file.sh"
source "${BASHSTOCK_ROOT}/src/platform/platform.sh"

case "$(platform::__identifier)" in
  darwin)
    source "${BASHSTOCK_ROOT}/src/platform/darwin.sh"
    ;;
  ubuntu)
    source "${BASHSTOCK_ROOT}/src/platform/ubuntu.sh"
    ;;
  fedora)
    source "${BASHSTOCK_ROOT}/src/platform/fedora.sh"
    ;;
esac

source "${BASHSTOCK_ROOT}/src/user/user.sh"

BASHSTOCK_LOADED='1'
