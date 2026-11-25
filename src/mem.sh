#!/usr/bin/env bash
# @file mem
# @brief Memory capacity and swap files.
# @description Capacities are written in bytes or gibibytes; swap files are managed through administrator execution on Linux.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the total physical memory in bytes.
#
# @noargs
# @stdout The total physical memory in bytes.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported, or sysctl is missing on macOS.
# @exitcode 74 The memory size could not be read.
# @example
#   mem__physical-total-bytes
mem__physical-total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system__operating-system)" in
    darwin) command -v sysctl >/dev/null 2>&1 || return 69; sysctl -n hw.memsize || return 74 ;;
    linux) awk '/^MemTotal:/ {print $2 * 1024; exit}' /proc/meminfo 2>/dev/null || return 74 ;;
    *) return 69 ;;
  esac
}

# @description Write the total physical memory in gibibytes.
#
# @noargs
# @stdout The total physical memory in GiB with two decimals, such as 15.53.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported.
# @exitcode 74 The memory size could not be read.
# @example
#   mem__physical-total-gibibytes
mem__physical-total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem__physical-total-bytes)" || return "$?"
  awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

# @description Write the total swap capacity in bytes.
#
# @noargs
# @stdout The total swap capacity in bytes; 0 without swap.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported, or sysctl is missing on macOS.
# @exitcode 74 The swap size could not be read.
# @example
#   [[ "$(mem__swap__total-bytes)" -gt 0 ]] || mem__swap__create 4
mem__swap__total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system__operating-system)" in
    darwin)
      # sysctl writes "total = 2048.00M  used = ...", so the size follows "=".
      command -v sysctl >/dev/null 2>&1 || return 69
      local usage=''
      usage="$(sysctl -n vm.swapusage 2>/dev/null)" || return 74
      awk '{
        for (i = 1; i < NF; i++) {
          if ($i != "total") continue
          value = ($(i + 1) == "=") ? $(i + 2) : $(i + 1)
          sub(/^=/, "", value)
          unit = substr(value, length(value), 1)
          scale = (unit == "K") ? 1024 : (unit == "M") ? 1048576 : (unit == "G") ? 1073741824 : 1
          printf "%.0f\n", value * scale
          exit
        }
        exit 1
      }' <<<"${usage}" || return 74
      ;;
    linux) awk '/^SwapTotal:/ {print $2 * 1024; exit}' /proc/meminfo 2>/dev/null || return 74 ;;
    *) return 69 ;;
  esac
}

# @description Write the total swap capacity in gibibytes.
#
# @noargs
# @stdout The total swap capacity in GiB with two decimals.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported.
# @exitcode 74 The swap size could not be read.
# @example
#   mem__swap__total-gibibytes
mem__swap__total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem__swap__total-bytes)" || return "$?"
  awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

# @description Write the total memory and swap capacity in bytes.
#
# @noargs
# @stdout The sum of physical memory and swap in bytes.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported.
# @exitcode 74 A size could not be read.
# @example
#   mem__total-bytes
mem__total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  local a='' b=''; a="$(mem__physical-total-bytes)" || return "$?"; b="$(mem__swap__total-bytes)" || return "$?"; printf '%s\n' "$((a+b))"
}

# @description Write the total memory and swap capacity in gibibytes.
#
# @noargs
# @stdout The sum of physical memory and swap in GiB with two decimals.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported.
# @exitcode 74 A size could not be read.
# @example
#   printf 'Memory and swap: %s GiB\n' "$(mem__total-gibibytes)"
mem__total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem__total-bytes)" || return "$?"; awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

# @description Disable every active swap area through administrator execution.
#
# @noargs
# @exitcode 0 Every swap area is disabled.
# @exitcode 64 An argument was given.
# @exitcode 69 swapoff is unavailable.
# @exitcode other The status of swapoff.
# @example
#   mem__swap__disable-all
mem__swap__disable-all() {
  [[ "$#" -eq 0 ]] || return 64
  command__require swapoff || return "$?"
  command__run-as-root swapoff --all
}

# @description Disable every swap file, remove its /etc/fstab entry, and delete it.
#
# Swap partitions are kept. The first failure stops the removal and is reported.
#
# @noargs
# @stderr The swap file and step that failed.
# @exitcode 0 Every swap file was removed.
# @exitcode 64 An argument was given.
# @exitcode 69 /proc/swaps cannot be read.
# @exitcode 74 A swap file could not be disabled, unregistered, or deleted.
# @example
#   mem__swap__remove-all-files && mem__swap__create 4294967296
mem__swap__remove-all-files() {
  [[ "$#" -eq 0 ]] || return 64
  [[ -r /proc/swaps ]] || return 69
  local path='' content=''
  while IFS= read -r path; do
    # /proc/swaps escapes spaces in paths as \040.
    path="${path//\\040/ }"
    command__run-as-root swapoff "${path}" || { _console__write-error "Could not disable ${path}."; return 74; }
    if [[ -f /etc/fstab ]]; then
      content="$(awk -v path="${path}" '$1 != path || $3 != "swap"' /etc/fstab)" || return 74
      file__write-text /etc/fstab "${content}"$'\n' || { _console__write-error "Could not update /etc/fstab for ${path}."; return 74; }
    fi
    command__run-as-root rm -f -- "${path}" || { _console__write-error "Could not delete ${path}."; return 74; }
  done < <(awk 'NR > 1 && $2 == "file" {print $1}' /proc/swaps)
}

# @description Create a swap file, enable it, and register it in /etc/fstab.
#
# The file is created and enabled through administrator execution. When a step
# fails, the swap file is disabled and removed again.
#
# @arg $1 integer Optional size in bytes. Defaults to 8589934592 (8 GiB).
# @arg $2 string Optional absolute swap file path without blanks or backslashes. Defaults to /swapfile.
# @stderr A message when the path already exists.
# @exitcode 0 The swap file is enabled and registered.
# @exitcode 64 The size or path is invalid, or the path has a blank or a backslash.
# @exitcode 69 The system is not Linux or mkswap is unavailable.
# @exitcode 73 The path already exists.
# @exitcode 74 The file could not be created or enabled.
# @exitcode other The status of the /etc/fstab update.
# @example
#   mem__swap__create 4294967296
mem__swap__create() {
  [[ "$#" -le 2 ]] || return 64
  local size="${1:-8589934592}" path="${2:-/swapfile}"
  ( [[ "${size}" =~ ^[1-9][0-9]*$ && "${path}" == /* ]] ) || return 64
  # /etc/fstab separates fields with blanks and escapes with backslashes.
  [[ "${path}" != *[[:space:]\\]* ]] || return 64
  [[ "$(system__operating-system)" == linux ]] || return 69
  command__require mkswap || return "$?"
  if [[ -e "${path}" || -L "${path}" ]]; then
    _console__write-error "${path} already exists."
    return 73
  fi
  if ! command__run-as-root fallocate -l "${size}" "${path}" 2>/dev/null; then
    # Some file systems cannot preallocate; write zeros instead.
    command__run-as-root dd if=/dev/zero of="${path}" bs=1M count="$(((size + 1048575) / 1048576))" status=none || {
      command__run-as-root rm -f -- "${path}"
      return 74
    }
  fi
  # A failed step undoes the earlier ones, so a retry does not find the path taken.
  local status=0 enabled=0
  command__run-as-root chmod 600 "${path}" || status=74
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root mkswap "${path}" >/dev/null || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    if command__run-as-root swapon "${path}"; then enabled=1; else status=74; fi
  fi
  if [[ "${status}" -eq 0 ]] &&
    ! awk -v path="${path}" '$1 == path && $3 == "swap" {found = 1} END {exit !found}' /etc/fstab 2>/dev/null; then
    file__append-text /etc/fstab "${path} none swap sw 0 0"$'\n' || status="$?"
  fi
  if [[ "${status}" -ne 0 ]]; then
    [[ "${enabled}" -eq 0 ]] || command__run-as-root swapoff "${path}" || true
    command__run-as-root rm -f -- "${path}" || true
    return "${status}"
  fi
}

# @description List active swap devices.
#
# @noargs
# @stdout The output of swapon --show.
# @exitcode 0 The swap areas were written.
# @exitcode 64 An argument was given.
# @exitcode 69 swapon is unavailable.
# @example
#   mem__swap__list
mem__swap__list() { [[ "$#" -eq 0 ]] || return 64; command -v swapon >/dev/null 2>&1 || return 69; swapon --show; }

# @description Extend swap capacity up to a target size.
#
# @arg $1 integer Target total swap size in bytes.
# @arg $2 integer Optional largest size to add in bytes. Defaults to the target.
# @arg $3 string Optional swap file path for the addition. Defaults to /swapfile.
# @exitcode 0 The swap capacity reaches the target, or the allowed addition was made.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of mem__swap__total-bytes or mem__swap__create.
# @example
#   mem__swap__ensure-total-size 8589934592
mem__swap__ensure-total-size() {
  ( [[ "$#" -ge 1 && "$#" -le 3 && "$1" =~ ^[1-9][0-9]*$ ]] ) || return 64
  local target="$1" max='' path='' current='' add=''
  if [[ "$#" -ge 2 ]]; then max="$2"; else max="$target"; fi
  if [[ "$#" -ge 3 ]]; then path="$3"; else path='/swapfile'; fi
  ( [[ "$max" =~ ^[0-9]+$ ]] ) || return 64
  current="$(mem__swap__total-bytes)" || return "$?"
  (( current >= target )) && return 0
  add=$((target - current))
  (( add > max )) && add="$max"
  mem__swap__create "$add" "$path"
}
