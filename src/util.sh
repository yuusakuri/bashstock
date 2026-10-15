#!/usr/bin/env bash
# @file util
# @brief Everyday commands for storage, Git, SSH, Docker, Android devices, debugging, and system settings.
# @description Most functions wrap one external command with argument checks and documented exit codes.

# shellcheck disable=SC2034,SC2046,SC2119,SC2120,SC2317,SC2319,SC2015,SC2155,SC2163,SC2329

# @description Wait for one line from the controlling terminal.
#
# @arg $1 string Optional message. Defaults to "Press Enter to continue.".
# @exitcode 0 A line was read.
# @exitcode 64 More than one argument was given.
# @exitcode 69 No controlling terminal is available.
# @exitcode 74 The terminal could not be read.
# @example
#   prompt::pause 'Connect the device, then press Enter.'
prompt::pause() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local message="${1:-Press Enter to continue.}"
  terminal::is-available || return 69
  local line=''
  IFS= read -r -p "${message}" line </dev/tty || return 74
}

# @description Sleep for a non-negative integer number of hours.
#
# @arg $1 integer Number of hours, 0 or more.
# @exitcode 0 The time passed.
# @exitcode 64 The value is not a non-negative integer.
# @exitcode 69 sleep is unavailable.
# @example
#   time::sleep-hours 2 && make release
time::sleep-hours() {
  if [[ "$#" -ne 1 || ! "$1" =~ ^(0|[1-9][0-9]*)$ ]]; then return 64; fi
  command -v sleep >/dev/null 2>&1 || return 69
  sleep "$((10#$1 * 3600))"
}

# @description Show human-readable filesystem usage for a path.
#
# @arg $1 string Optional path. Defaults to the current directory.
# @stdout The df -h report for the file system that holds the path.
# @exitcode 0 The report was written.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The path does not exist.
# @exitcode 69 df is unavailable.
# @example
#   storage::usage "${HOME}"
storage::usage() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local path="${1:-.}"
  [[ -e "$path" || -d "$path" ]] || return 66
  command -v df >/dev/null 2>&1 || return 69
  df -h "$path"
}

# @description Write the largest entries of a directory, including the directory itself, in human-readable sizes.
#
# Directory sizes include everything below them.
#
# @arg $1 string Optional directory to inspect. Defaults to the current directory.
# @arg $2 integer Optional number of entries to write. Defaults to 10.
# @stdout Lines of size and path, largest first.
# @exitcode 0 The entries were written.
# @exitcode 64 The directory does not exist or the count is not a positive integer.
# @exitcode 69 du or sort is unavailable.
# @example
#   storage::largest-entries "${HOME}/Library/Caches" 5
storage::largest-entries() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${1:-.}" max="${2:-10}"
  [[ -d "${directory}" && "${max}" =~ ^[1-9][0-9]*$ ]] || return 64
  command::require du || return "$?"
  command::require sort || return "$?"
  du -h -a -d 1 -- "${directory}" 2>/dev/null | sort -hr | head -n "${max}"
}

# @description Write the total physical memory in bytes.
#
# @noargs
# @stdout The total physical memory in bytes.
# @exitcode 0 The size was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported, or sysctl is missing on macOS.
# @exitcode 74 The memory size could not be read.
# @example
#   mem::physical-total-bytes
mem::physical-total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
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
#   mem::physical-total-gibibytes
mem::physical-total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem::physical-total-bytes)" || return "$?"
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
#   [[ "$(mem::swap-total-bytes)" -gt 0 ]] || swap::create 4
mem::swap-total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
    darwin) command -v sysctl >/dev/null 2>&1 || return 69; sysctl -n vm.swapusage 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="total") {gsub("M","",$(i+1)); print $(i+1)*1048576; exit}}' ;;
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
#   mem::swap-total-gibibytes
mem::swap-total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem::swap-total-bytes)" || return "$?"
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
#   mem::total-bytes
mem::total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  local a='' b=''; a="$(mem::physical-total-bytes)" || return "$?"; b="$(mem::swap-total-bytes)" || return "$?"; printf '%s\n' "$((a+b))"
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
#   printf 'Memory and swap: %s GiB\n' "$(mem::total-gibibytes)"
mem::total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem::total-bytes)" || return "$?"; awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

# @description Write text to a regular file using an atomic replacement.
#
# New files use 0666 filtered by the caller's umask; existing metadata is preserved.
#
# @arg $1 string File path; a symbolic link is refused.
# @arg $2 string Text to write exactly; include a trailing newline when one is needed.
# @exitcode 0 The file holds the text.
# @exitcode 64 The path is empty or a symbolic link, or the argument count is not two.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 74 The temporary file could not be written or moved into place.
# @exitcode other The status of the root helper when elevation was needed.
# @example
#   file::write-text /etc/udev/rules.d/90-device.rules $'SUBSYSTEM=="usb", MODE="0666"\n'
file::write-text() {
  if [[ "$#" -ne 2 || -z "$1" || -L "$1" ]]; then return 64; fi
  local file="$1" text="$2" temporary='' mode='' mask=''
  if [[ -e "$file" && ! -f "$file" ]]; then return 66; fi
  mask="$(umask)"
  if file::_requires-root "$file"; then
    bashstock::_run-as-root write-text "$@" "${mask}"
    return
  fi
  temporary="$(umask 077 && file::_temporary-path "$file")" || return "$?"
  if [[ -e "$file" ]]; then
    file::_copy-metadata-and-content "$file" "$temporary" || { rm -f -- "$temporary"; return 74; }
  else
    printf -v mode '%04o' "$((0666 & ~8#${mask}))"
  fi
  if ! printf '%s' "$text" >"$temporary"; then rm -f -- "$temporary"; return 74; fi
  if [[ -n "${mode}" ]] && ! chmod "${mode}" "${temporary}"; then
    rm -f -- "${temporary}"
    return 74
  fi
  if ! mv -f -- "$temporary" "$file"; then rm -f -- "$temporary"; return 74; fi
}

# @description Write the regular files below a directory whose content matches an ERE, separated by NUL.
#
# The files are searched in parallel by grep -E.
#
# @arg $1 string Extended regular expression evaluated by grep -E.
# @arg $2 string Optional directory to search. Defaults to the current directory.
# @arg $3 integer Optional number of parallel grep processes. Defaults to the number of online CPUs.
# @arg $4 string Optional binary mode: skip (default) ignores binary files; include searches them as text.
# @stdout NUL-separated paths of the matching files.
# @exitcode 0 At least one file matches.
# @exitcode 1 No file matches.
# @exitcode 64 The expression is invalid, or a mode or count is malformed.
# @exitcode 66 The directory does not exist.
# @exitcode 69 find, xargs, or grep is unavailable.
# @exitcode 74 A file could not be searched.
# @example
#   file::find-by-content 'FIXME|XXX' src | xargs -0 grep -nE 'FIXME|XXX'
file::find-by-content() {
  [[ "$#" -ge 1 && "$#" -le 4 && -n "$1" ]] || return 64
  local expression="$1" directory="${2:-.}" processes="${3:-}" binary="${4:-skip}" output='' status=0
  local binary_option=''
  [[ -d "${directory}" ]] || return 66
  case "${binary}" in
    skip) binary_option='-I' ;;
    include) binary_option='-a' ;;
    *) return 64 ;;
  esac
  command::require grep || return "$?"
  command::require xargs || return "$?"
  if [[ -z "${processes}" ]]; then
    processes="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" || processes=1
  fi
  [[ "${processes}" =~ ^[1-9][0-9]*$ ]] || return 64
  grep -E -e "${expression}" </dev/null >/dev/null 2>&1 || status="$?"
  [[ "${status}" -ne 2 ]] || return 64
  output="$(mktemp "${TMPDIR:-/tmp}/bashstock-find.XXXXXX")" || return 74
  status=0
  find "${directory}" -type f -print0 |
    xargs -0 -P "${processes}" -n 64 grep -E -l --null "${binary_option}" -e "${expression}" -- >"${output}" 2>/dev/null ||
    status="$?"
  # GNU xargs reports 123 and BSD xargs 1 when a grep found nothing in its
  # batch or could not read a file.
  case "${status}" in
    0 | 1 | 123) ;;
    127) rm -f -- "${output}"; return 69 ;;
    *) rm -f -- "${output}"; return 74 ;;
  esac
  if [[ ! -s "${output}" ]]; then
    rm -f -- "${output}"
    return 1
  fi
  cat -- "${output}"
  rm -f -- "${output}"
}

# @description Write the most recently modified regular file whose base name matches a Bash ERE.
#
# Files modified at the same second are ordered by their path bytes, and the
# first one is written.
#
# @arg $1 string Extended regular expression matched against base names.
# @arg $2 string Optional directory to search recursively. Defaults to the current directory.
# @stdout The path of the newest matching file.
# @exitcode 0 A file was written.
# @exitcode 1 No file matches.
# @exitcode 64 The argument count is wrong.
# @exitcode 66 The directory does not exist.
# @example
#   file::latest-by-name '^backup-.*\.tar\.gz$' /var/backups
file::latest-by-name() {
  [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64
  local expression="$1" directory="${2:-.}" path='' newest='' newest_time=0 current_time='' LC_ALL=C
  [[ -d "${directory}" ]] || return 66
  while IFS= read -r -d '' path; do
    [[ "${path##*/}" =~ ${expression} ]] || continue
    current_time="$(file::modified-time-unix-seconds "${path}" 2>/dev/null)" || continue
    if [[ -z "${newest}" ]] || ((current_time > newest_time)) ||
      { ((current_time == newest_time)) && [[ "${path}" < "${newest}" ]]; }; then
      newest="${path}"
      newest_time="${current_time}"
    fi
  done < <(find "${directory}" -type f -print0)
  [[ -n "${newest}" ]] || return 1
  printf '%s\n' "${newest}"
}

# @description Create or replace a symbolic link that points to the absolute path of an existing SOURCE.
#
# An existing symbolic link at LINK is replaced; a file or directory there is
# kept and returns 73. Administrator execution is used only when the parent
# directory of LINK is not writable.
#
# @arg $1 string SOURCE Existing path the link points to.
# @arg $2 string LINK Path of the link.
# @exitcode 0 LINK points to the absolute path of SOURCE.
# @exitcode 64 An argument is empty, or the argument count is not two.
# @exitcode 66 SOURCE does not exist.
# @exitcode 73 LINK exists and is not a symbolic link.
# @exitcode 74 The link could not be created.
# @example
#   symlink::create ./dotfiles/.vimrc "${HOME}/.vimrc"
symlink::create() {
  [[ "$#" -eq 2 && -n "$1" && -n "$2" ]] || return 64
  local source="$1" link="${2%/}" parent=''
  [[ -e "${source}" || -L "${source}" ]] || return 66
  [[ "${source}" == /* ]] || source="${PWD}/${source}"
  source="$(path::normalize "${source}")" || return "$?"
  if [[ -e "${link}" && ! -L "${link}" ]]; then
    console::_write-error "${link} exists and is not a symbolic link."
    return 73
  fi
  parent="$(path::directory-name "${link}")" || return "$?"
  [[ -d "${parent}" ]] || return 66
  if [[ -w "${parent}" ]]; then
    ln -sfn -- "${source}" "${link}" || return 74
  else
    command::run-as-root ln -sfn -- "${source}" "${link}" || return 74
  fi
}

# @description Remove a symbolic link, using administrator execution only when its directory is not writable.
#
# @arg $1 string Path of an existing symbolic link; its target is not touched.
# @exitcode 0 The link was removed.
# @exitcode 64 The path is not a symbolic link, or the argument count is not one.
# @exitcode 74 The link could not be removed.
# @example
#   symlink::remove "${HOME}/.vimrc"
symlink::remove() {
  [[ "$#" -eq 1 && -L "${1%/}" ]] || return 64
  local link="${1%/}" parent=''
  parent="$(path::directory-name "${link}")" || return "$?"
  if [[ -w "${parent}" ]]; then
    rm -f -- "${link}" || return 74
  else
    command::run-as-root rm -f -- "${link}" || return 74
  fi
}

# @description Write the first default-route interface.
#
# @noargs
# @stdout The interface name, such as eth0 or en0.
# @exitcode 0 The name was written.
# @exitcode 64 An argument was given.
# @exitcode 69 No default route exists, or the routing tool is unavailable.
# @example
#   net::ip::private-v4 "$(net::interface::default)"
net::interface::default() { [[ "$#" -eq 0 ]] || return 64; net::_default-interface; }

# @description Write the first default-route gateway.
#
# @noargs
# @stdout The gateway address.
# @exitcode 0 The address was written.
# @exitcode 64 An argument was given.
# @exitcode 69 No default route exists, or the routing tool is unavailable.
# @example
#   net::ping "$(net::gateway::default)"
net::gateway::default() { [[ "$#" -eq 0 ]] || return 64; net::_default-gateway; }

# @description Write the primary RFC 1918 IPv4 address of an interface.
#
# @arg $1 string INTERFACE Interface name. Defaults to the interface of the default route.
# @stdout The address without a prefix length, such as 192.168.1.20.
# @exitcode 0 The address was written.
# @exitcode 1 The interface has no private IPv4 address.
# @exitcode 64 More than one argument was given.
# @exitcode 69 No interface was given and there is no default route, or the address tool is unavailable.
# @example
#   net::ip::private-v4 eth0
net::ip::private-v4() {
  [[ "$#" -le 1 ]] || return 64
  local interface="${1:-}" address='' candidate='' cidr=''
  if [[ -z "${interface}" ]]; then
    if [[ "$(system::operating-system)" == darwin ]]; then
      interface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2; exit}')"
    else
      interface="$(net::_default-interface)"
    fi
  fi
  [[ -n "${interface}" ]] || return 69
  while IFS= read -r candidate; do
    case "${candidate}" in
      10.* | 192.168.* | 172.1[6-9].* | 172.2[0-9].* | 172.3[01].*)
        address="${candidate}"
        break
        ;;
    esac
  done < <(
    if [[ "$(system::operating-system)" == darwin ]]; then
      ifconfig "${interface}" 2>/dev/null | awk '$1 == "inet" {print $2}'
    else
      cidr="$(net::_interface-ipv4-cidr "${interface}" 2>/dev/null)" && printf '%s\n' "${cidr%/*}"
      ip -o -4 addr show dev "${interface}" 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4}'
    fi
  )
  [[ -n "${address}" ]] || return 1
  printf '%s\n' "${address}"
}

# @description Write the primary unique local IPv6 address of an interface.
#
# Only addresses in fc00::/7 are considered, in the order the operating
# system lists them, after removing the excluded prefixes.
#
# @arg $1 string INTERFACE Interface name. Defaults to the interface of the default route.
# @arg $2 string EXCLUDED_PREFIXES Comma-separated address prefixes to skip. Defaults to fe80,fda6: link-local addresses and the auxiliary ULA of the reference network.
# @stdout The address without a prefix length.
# @exitcode 0 The address was written.
# @exitcode 1 No address remains after the exclusions.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 No interface was given and there is no default route, or the address tool is unavailable.
# @example
#   net::ip::private-v6 en0 fe80
net::ip::private-v6() {
  [[ "$#" -le 2 ]] || return 64
  local interface="${1:-}" excluded="${2-fe80,fda6}" candidate='' prefix='' skip='' lower=''
  local prefixes=()
  [[ -n "${interface}" ]] || interface="$(net::_default-interface)"
  [[ -n "${interface}" ]] || return 69
  IFS=',' read -r -a prefixes <<<"${excluded}"
  while IFS= read -r candidate; do
    candidate="${candidate%%%*}"
    lower="$(string::lower "${candidate}")" || return "$?"
    [[ "${lower}" == fc* || "${lower}" == fd* ]] || continue
    skip=0
    for prefix in "${prefixes[@]}"; do
      [[ -n "${prefix}" && "${lower}" == "$(string::lower "${prefix}")"* ]] && skip=1
    done
    [[ "${skip}" -eq 0 ]] || continue
    printf '%s\n' "${candidate}"
    return 0
  done < <(
    if [[ "$(system::operating-system)" == darwin ]]; then
      ifconfig "${interface}" 2>/dev/null | awk '$1 == "inet6" {print $2}'
    else
      ip -o -6 addr show dev "${interface}" 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4}'
    fi
  )
  return 1
}

# @description Write the public IP address reported by ifconfig.me.
#
# curl is preferred and wget is used when curl is missing. The response
# must be one IPv4 or IPv6 address; anything else returns 74.
#
# @noargs
# @stdout One IPv4 or IPv6 address.
# @stderr A message when neither curl nor wget is available.
# @exitcode 0 The address was written.
# @exitcode 64 An argument was given.
# @exitcode 69 Neither curl nor wget is available.
# @exitcode 74 The request failed or the response is not an address.
# @example
#   net::ip::public
net::ip::public() {
  [[ "$#" -eq 0 ]] || return 64
  local address=''
  if command -v curl >/dev/null 2>&1; then
    address="$(curl -fsS --max-time 10 https://ifconfig.me)" || return 74
  elif command -v wget >/dev/null 2>&1; then
    address="$(wget -qO- --timeout=10 https://ifconfig.me)" || return 74
  else
    console::_write-error 'curl or wget is required.'
    return 69
  fi
  if ! net::_is-ip-address "${address}"; then
    console::_write-error 'ifconfig.me did not return an IP address.'
    return 74
  fi
  printf '%s\n' "${address}"
}

# @description Test whether a DNS name resolves.
#
# @arg $1 string Host name to resolve.
# @exitcode 0 The name resolves.
# @exitcode 1 The name does not resolve.
# @exitcode 64 The name is empty, or the argument count is not one.
# @exitcode 69 Neither getent nor dscacheutil is available.
# @example
#   net::dns::test github.com || net::dns::use-google
net::dns::test() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  if command -v getent >/dev/null 2>&1; then
    getent ahosts "$1" >/dev/null 2>&1
    return
  fi
  command -v dscacheutil >/dev/null 2>&1 || return 69
  dscacheutil -q host -a name "$1" >/dev/null 2>&1
}

# @description Add a user to a supplementary group through administrator execution.
#
# @arg $1 string Group name.
# @arg $2 string Optional user name. Defaults to the current user.
# @exitcode 0 The user is in the group; it applies to new login sessions.
# @exitcode 64 The group name is invalid, or the argument count is wrong.
# @exitcode 69 The operating system is unsupported, or usermod or dseditgroup is unavailable.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of usermod or dseditgroup.
# @example
#   user::add-to-group dialout
user::add-to-group() {
  if [[ "$#" -lt 1 || "$#" -gt 2 || ! "$1" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]]; then return 64; fi
  local user="${2:-}"
  [[ -n "${user}" ]] || user="$(user::name)" || return "$?"
  case "$(system::operating-system)" in
    darwin) command::require dseditgroup || return "$?"; command::run-as-root dseditgroup -o edit -a "${user}" -t user "$1" ;;
    linux) command::require usermod || return "$?"; command::run-as-root usermod -a -G "$1" "${user}" ;;
    *) return 69 ;;
  esac
}

# @description Write the kernel name.
#
# @noargs
# @stdout The output of uname -s, such as Linux or Darwin.
# @exitcode 0 The name was written.
# @exitcode 64 An argument was given.
# @exitcode 69 uname is unavailable.
# @example
#   system::kernel-name
system::kernel-name() { [[ "$#" -eq 0 ]] || return 64; command -v uname >/dev/null 2>&1 || return 69; uname -s; }

# @description Write the distribution name.
#
# @noargs
# @stdout darwin, ubuntu, fedora, or the ID from /etc/os-release.
# @exitcode 0 The name was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The distribution cannot be identified.
# @example
#   [[ "$(system::distribution-name)" == ubuntu ]] && sudo apt-get update
system::distribution-name() { [[ "$#" -eq 0 ]] || return 64; platform::_identifier; }

# @description Enable system sleep.
#
# @noargs
# @exitcode 0 Sleep is enabled again.
# @exitcode 64 An argument was given.
# @exitcode 69 A required command is missing, or the operating system is unsupported.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of pmset or systemctl.
# @example
#   system::enable-sleep
system::enable-sleep() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
    darwin)
      command::require pmset || return "$?"
      command::run-as-root pmset -a sleep 1
      ;;
    linux)
      command::require systemctl || return "$?"
      command::run-as-root systemctl unmask \
        sleep.target suspend.target hibernate.target hybrid-sleep.target
      ;;
    *) return 69 ;;
  esac
}

# @description Disable system sleep.
#
# On Linux the sleep, suspend, hibernate, and hybrid-sleep targets are masked; on macOS pmset sets sleep to 0.
#
# @noargs
# @exitcode 0 Sleep is disabled until system::enable-sleep.
# @exitcode 64 An argument was given.
# @exitcode 69 A required command is missing, or the operating system is unsupported.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of pmset or systemctl.
# @example
#   system::disable-sleep
system::disable-sleep() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
    darwin)
      command::require pmset || return "$?"
      command::run-as-root pmset -a sleep 0
      ;;
    linux)
      command::require systemctl || return "$?"
      command::run-as-root systemctl mask \
        sleep.target suspend.target hibernate.target hybrid-sleep.target
      ;;
    *) return 69 ;;
  esac
}

# @description Disable automatic screen locking for the current user.
#
# Linux changes GNOME's lock-enabled setting. macOS disables the password prompt
# after the screen saver or display turns off. Neither changes system sleep or
# whether the screen saver starts.
#
# @noargs
# @exitcode 0 Automatic screen locking is disabled.
# @exitcode 64 An argument was given.
# @exitcode 69 The operating system is unsupported, or a required command is missing.
# @exitcode 74 The screen-lock setting could not be changed.
# @example
#   system::disable-auto-lock
system::disable-auto-lock() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
    linux)
      command::require gsettings || return "$?"
      gsettings set org.gnome.desktop.screensaver lock-enabled false || return 74
      ;;
    darwin)
      command::require defaults || return "$?"
      defaults write com.apple.screensaver askForPassword -bool false || return 74
      ;;
    *) return 69 ;;
  esac
}

# @description Write the POSIX TZ string for a UTC offset.
#
# POSIX TZ offsets have the opposite sign of ISO 8601 offsets, so +09:30
# becomes UTC-9:30 and -05:00 becomes UTC+5.
#
# @arg $1 string OFFSET Z or an offset in the form +HH:MM or -HH:MM, with HH up to 23 and MM up to 59.
# @stdout The TZ value, such as UTC-9 or UTC+5:30.
# @exitcode 0 The value was written.
# @exitcode 64 The offset is malformed or out of range.
# @example
#   time::posix-timezone +09:00
#   # UTC-9
time::posix-timezone() {
  [[ "$#" -eq 1 ]] || return 64
  local sign='' hours=0 minutes=0 text=''
  if [[ "$1" == Z ]]; then
    printf 'UTC0\n'
    return 0
  fi
  [[ "$1" =~ ^([+-])([0-9]{2}):([0-9]{2})$ ]] || return 64
  sign="${BASH_REMATCH[1]}"
  hours=$((10#${BASH_REMATCH[2]}))
  minutes=$((10#${BASH_REMATCH[3]}))
  ((hours <= 23 && minutes <= 59)) || return 64
  if ((hours == 0 && minutes == 0)); then
    printf 'UTC0\n'
    return 0
  fi
  if [[ "${sign}" == + ]]; then sign='-'; else sign='+'; fi
  text="UTC${sign}${hours}"
  ((minutes == 0)) || text+="$(printf ':%02d' "${minutes}")"
  printf '%s\n' "${text}"
}

# @description Merge every entry of SOURCE into DESTINATION by moving it, then remove SOURCE.
#
# Directories are merged recursively. A file or symbolic link in SOURCE
# replaces the entry with the same name in DESTINATION. Symbolic links are
# never followed. The first failure stops the merge.
#
# @arg $1 string SOURCE Directory to empty and remove.
# @arg $2 string DESTINATION Directory to receive the entries; created when missing.
# @exitcode 0 SOURCE was merged into DESTINATION and removed.
# @exitcode 64 SOURCE is not a directory, or DESTINATION is a symbolic link or a file.
# @exitcode 74 An entry could not be moved, or SOURCE could not be removed.
# @example
#   directory::merge "${HOME}/デスクトップ" "${HOME}/Desktop"
directory::merge() {
  [[ "$#" -eq 2 && -d "$1" && ! -L "$1" && -n "$2" ]] || return 64
  local source="$1" destination="$2" entry='' name='' target=''
  if [[ -L "${destination}" || (-e "${destination}" && ! -d "${destination}") ]]; then return 64; fi
  mkdir -p -- "${destination}" || return 74
  while IFS= read -r -d '' entry; do
    name="${entry##*/}"
    target="${destination}/${name}"
    if [[ -d "${entry}" && ! -L "${entry}" && -d "${target}" && ! -L "${target}" ]]; then
      directory::merge "${entry}" "${target}" || return "$?"
      continue
    fi
    if [[ -e "${target}" || -L "${target}" ]]; then
      rm -rf -- "${target}" || return 74
    fi
    mv -- "${entry}" "${target}" || return 74
  done < <(find "${source}" -mindepth 1 -maxdepth 1 -print0)
  rmdir -- "${source}" || return 74
}

# @description Create a directory named with the local date and time and write its path.
#
# The name has the form YYYYMMDDTHHMMSS. When that name exists, a suffix
# counting from -2 is added.
#
# @arg $1 string DIRECTORY Parent directory. Defaults to the current directory.
# @stdout The path of the new directory, such as ./20261014T120405.
# @exitcode 0 The directory was created.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The parent directory does not exist.
# @exitcode 69 The clock provider is unavailable.
# @exitcode 74 The directory could not be created.
# @example
#   backup="$(directory::create-with-date-time /var/backups)"
directory::create-with-date-time() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-.}" name='' path='' index=2
  [[ -d "${directory}" ]] || return 66
  name="$(time::local-date-time-seconds-basic)" || return "$?"
  path="${directory%/}/${name}"
  until mkdir -- "${path}" 2>/dev/null; do
    [[ -e "${path}" || -L "${path}" ]] || return 74
    path="${directory%/}/${name}-${index}"
    index=$((index + 1))
  done
  printf '%s\n' "${path}"
}

# @description Remove every entry of a directory, including hidden ones, and keep the directory.
#
# An empty name, the file system root, the home directory, and a symbolic
# link are refused, because a link would empty the directory it points to.
#
# @arg $1 string DIRECTORY Directory to empty. Defaults to the current directory.
# @stderr A message when the directory is refused.
# @exitcode 0 The directory is empty.
# @exitcode 64 The directory is missing, a symbolic link, the root, or the home directory.
# @exitcode 66 The directory cannot be entered.
# @exitcode 74 An entry could not be removed.
# @example
#   directory::clear ./build
directory::clear() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1-.}" physical='' home=''
  [[ -n "${directory}" && -d "${directory}" && ! -L "${directory%/}" ]] || return 64
  physical="$(cd -P -- "${directory}" && pwd -P)" || return 66
  home="$(cd -P -- "${HOME:-/}" 2>/dev/null && pwd -P)" || home=''
  if [[ "${physical}" == / || "${physical}" == "${home}" ]]; then
    console::_write-error "Refusing to clear ${physical}."
    return 64
  fi
  find "${physical}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + || return 74
}

# @description Write the elapsed time since boot and the local time every three seconds until stopped.
#
# @noargs
# @stdout Two lines every three seconds: the seconds since boot and the local date and time.
# @exitcode 64 An argument was given.
# @exitcode 74 sleep failed.
# @exitcode other The status of the clock function that failed.
# @example
#   time::status-continuous   # Stop with Ctrl-C.
time::status-continuous() {
  [[ "$#" -eq 0 ]] || return 64
  local milliseconds='' now=''
  while :; do
    milliseconds="$(time::boot-time-milliseconds)" || return "$?"
    now="$(time::local-date-time-seconds-extended)" || return "$?"
    printf 'Seconds since boot: %d.%03d\nLocal date and time: %s\n' \
      "$((milliseconds / 1000))" "$((milliseconds % 1000))" "${now}"
    sleep 3 || return 74
  done
}

# @description Open an editor for a file, using sudoedit only when required.
#
# @arg $1 string File to edit. A missing file is created by the editor.
# @exitcode 0 The editor exited successfully.
# @exitcode 64 The argument count is not one or the path is empty.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 69 The file is not writable and sudoedit is unavailable.
# @exitcode other The status of the editor.
# @example
#   EDITOR=nano file::edit /etc/hosts
file::edit() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; if [[ -e "$1" && ! -f "$1" ]]; then return 66; fi; if [[ -w "$1" || (! -e "$1" && -w "$(path::directory-name "$1")") ]]; then "${EDITOR:-vi}" "$1"; else command -v sudoedit >/dev/null 2>&1 || return 69; sudoedit "$1"; fi; }

# @description Release a file held by other processes.
#
# Each holder receives SIGTERM, and holders left after the timeout receive
# SIGKILL. A signal the current user may not send is sent through
# administrator execution.
#
# @arg $1 string File to release.
# @arg $2 integer Optional seconds to wait after SIGTERM. Defaults to 2.
# @exitcode 0 No process holds the file.
# @exitcode 64 The arguments are invalid or the file does not exist.
# @exitcode 69 lsof is unavailable.
# @exitcode 74 The clock could not be read.
# @exitcode 75 The file is still open after SIGKILL.
# @example
#   file::release "${HOME}/.local/share/app/database.lock" 5
file::release() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  command -v lsof >/dev/null 2>&1 || return 69
  local timeout="${2:-2}" start='' pid=''
  start="$(date +%s)" || return 74
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    kill -TERM "$pid" 2>/dev/null || command::run-as-root kill -TERM "$pid" 2>/dev/null || true
  done < <(lsof -t -- "$1" 2>/dev/null)
  while (( $(date +%s) - start < timeout )); do
    lsof -t -- "$1" >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  while read -r pid; do
    kill -KILL "$pid" 2>/dev/null || command::run-as-root kill -KILL "$pid" 2>/dev/null || true
  done < <(lsof -t -- "$1" 2>/dev/null)
  lsof -t -- "$1" >/dev/null 2>&1 && return 75
}

# @description Open a GNU Screen session.
#
# @arg $1 string Optional session name. Defaults to default.
# @exitcode 0 The session ended successfully.
# @exitcode 64 More than one argument was given.
# @exitcode 69 screen is unavailable.
# @exitcode other The status of screen.
# @example
#   screen::open build
screen::open() { if [[ "$#" -gt 1 ]]; then return 64; fi; command -v screen >/dev/null 2>&1 || return 69; screen "${1:-default}"; }

# @description Write the format and the matched extension of an archive file name.
#
# The formats are tar, tar.gz, tar.xz, tar.bz2, tar.zst, zip, 7z, and the
# single compressed files gz, xz, bz2, and zst.
#
# @internal
archive::_format() {
  [[ "$#" -eq 1 ]] || return 64
  case "$1" in
    *.tar.gz) printf '%s %s\n' tar.gz .tar.gz ;;
    *.tgz) printf '%s %s\n' tar.gz .tgz ;;
    *.tar.xz) printf '%s %s\n' tar.xz .tar.xz ;;
    *.txz) printf '%s %s\n' tar.xz .txz ;;
    *.tar.bz2) printf '%s %s\n' tar.bz2 .tar.bz2 ;;
    *.tbz2) printf '%s %s\n' tar.bz2 .tbz2 ;;
    *.tbz) printf '%s %s\n' tar.bz2 .tbz ;;
    *.tar.zst) printf '%s %s\n' tar.zst .tar.zst ;;
    *.tzst) printf '%s %s\n' tar.zst .tzst ;;
    *.tar) printf '%s %s\n' tar .tar ;;
    *.zip) printf '%s %s\n' zip .zip ;;
    *.7z) printf '%s %s\n' 7z .7z ;;
    *.gz) printf '%s %s\n' gz .gz ;;
    *.xz) printf '%s %s\n' xz .xz ;;
    *.bz2) printf '%s %s\n' bz2 .bz2 ;;
    *.zst) printf '%s %s\n' zst .zst ;;
    *) return 64 ;;
  esac
}

# @description Write the compression command of a compressed tar or single compressed format.
# @internal
archive::_compressor() {
  [[ "$#" -eq 1 ]] || return 64
  case "$1" in
    tar.gz | gz) printf 'gzip\n' ;;
    tar.xz | xz) printf 'xz\n' ;;
    tar.bz2 | bz2) printf 'bzip2\n' ;;
    tar.zst | zst) printf 'zstd\n' ;;
    *) return 64 ;;
  esac
}

# @description Write the 7-Zip command: 7zz or 7z.
# @internal
archive::_7zip() {
  [[ "$#" -eq 0 ]] || return 64
  local name=''
  for name in 7zz 7z; do
    if command -v "${name}" >/dev/null 2>&1; then
      printf '%s\n' "${name}"
      return 0
    fi
  done
  console::_write-error '7-Zip is required: install 7zz or 7z.'
  return 69
}

# @description Write the entry names of an archive, one per line.
#
# The compressed stream is tested in full before tar reads it. An encrypted
# archive whose names 7-Zip or unzip cannot read without the password
# returns 69.
#
# @internal
archive::_list() {
  [[ "$#" -eq 2 && -f "$1" ]] || return 64
  local file="$1" format="$2" compressor='' seven='' listing=''
  case "${format}" in
    tar)
      command::require tar || return "$?"
      tar -tf "${file}" 2>/dev/null || return 65
      ;;
    tar.*)
      compressor="$(archive::_compressor "${format}")" || return "$?"
      command::require "${compressor}" || return "$?"
      command::require tar || return "$?"
      "${compressor}" -tq -- "${file}" >/dev/null 2>&1 || return 65
      # tar may stop at the end-of-archive blocks, so only its status counts here.
      (
        set +o pipefail
        "${compressor}" -dc -- "${file}" 2>/dev/null | tar -tf - 2>/dev/null
      ) || return 65
      ;;
    zip)
      command::require unzip || return "$?"
      unzip -Z1 "${file}" 2>/dev/null || return 65
      ;;
    7z)
      seven="$(archive::_7zip)" || return "$?"
      if ! listing="$("${seven}" l -slt -p -- "${file}" </dev/null 2>&1)"; then
        if [[ "${listing}" == *'Wrong password'* ]]; then
          console::_write-error "${file} is encrypted; its contents cannot be read without the password."
          return 69
        fi
        return 65
      fi
      # Entries follow the dashed separator; the Path before it is the archive itself.
      printf '%s\n' "${listing}" | awk 'entries && /^Path = / { print substr($0, 8) } /^----------$/ { entries = 1 }'
      ;;
    *) return 64 ;;
  esac
}

# @description Verify one archive file.
#
# Returns 0 for a valid archive and 1 for a broken one. An archive that
# cannot be verified, because a tool is missing, the archive is encrypted,
# or the file cannot be read, returns 69 or 66 and is never reported as
# broken.
#
# @internal
archive::_verify-file() {
  [[ "$#" -eq 1 && -f "$1" ]] || return 64
  local file="$1" format='' suffix='' compressor='' seven='' information='' status=0
  read -r format suffix <<<"$(archive::_format "${file}")" || return 64
  [[ -n "${format}" ]] || return 64
  if [[ ! -r "${file}" ]]; then
    console::_write-error "${file} cannot be read."
    return 66
  fi
  case "${format}" in
    gz | xz | bz2 | zst)
      compressor="$(archive::_compressor "${format}")" || return "$?"
      command::require "${compressor}" || return "$?"
      "${compressor}" -tq -- "${file}" >/dev/null 2>&1 || return 1
      ;;
    zip)
      command::require unzip || return "$?"
      information="$(unzip -Zv "${file}" 2>/dev/null)" || return 1
      if grep -Eq 'file security status:[[:space:]]+encrypted' <<<"${information}"; then
        console::_write-error "${file} is encrypted; it cannot be verified without the password."
        return 69
      fi
      unzip -tqq "${file}" </dev/null >/dev/null 2>&1 || return 1
      ;;
    7z)
      archive::_list "${file}" 7z >/dev/null || status="$?"
      case "${status}" in
        0) ;;
        65) return 1 ;;
        *) return "${status}" ;;
      esac
      seven="$(archive::_7zip)" || return "$?"
      information="$("${seven}" l -slt -p -- "${file}" </dev/null 2>/dev/null)" || return 1
      if [[ "${information}" == *'Encrypted = +'* ]]; then
        console::_write-error "${file} is encrypted; it cannot be verified without the password."
        return 69
      fi
      "${seven}" t -p -bd -- "${file}" </dev/null >/dev/null 2>&1 || return 1
      ;;
    *)
      archive::_list "${file}" "${format}" >/dev/null || status="$?"
      case "${status}" in
        0) ;;
        65) return 1 ;;
        *) return "${status}" ;;
      esac
      ;;
  esac
}

# @description Verify all recognized archives below a path.
#
# The recognized extensions are .tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2,
# .tbz2, .tbz, .tar.zst, .tzst, .zip, .7z, .gz, .xz, .bz2, and .zst.
# Compressed data is tested in full, and tar archives are read to the end of
# their entries; the bytes of the files inside a tar archive are covered only
# by the compression checksum. An archive that cannot be verified, because
# its tool is missing, it is encrypted, or it cannot be read, is reported on
# standard error but not counted as broken, and does not change the status.
#
# @arg $1 string Optional archive file or directory to search. Defaults to the current directory.
# @stderr The path of each broken archive, and a message for each archive that cannot be verified.
# @exitcode 0 Every archive is valid.
# @exitcode 1 At least one archive is broken.
# @exitcode 64 More than one argument was given.
# @example
#   archive::verify "${HOME}/Downloads"
archive::verify() {
  [[ "$#" -le 1 ]] || return 64
  local file='' result=0 broken=0
  while IFS= read -r -d '' file; do
    result=0
    archive::_verify-file "${file}" || result="$?"
    # Other statuses mean the archive could not be verified; the reason is already reported.
    [[ "${result}" -ne 1 ]] || { printf '%s\n' "${file}" >&2; broken=1; }
  done < <(archive::_find "${1:-.}")
  [[ "${broken}" -eq 0 ]] || return 1
}

# @description Remove archives that fail verification.
#
# Only archives that archive::verify reports as broken are removed. An
# archive that cannot be verified is kept and does not change the status.
#
# @arg $1 string Optional archive file or directory to search. Defaults to the current directory.
# @stderr The path of each removed archive, and a message for each archive that cannot be verified.
# @exitcode 0 No archive was broken.
# @exitcode 1 At least one broken archive was removed.
# @exitcode 64 More than one argument was given.
# @exitcode 74 A broken archive could not be removed.
# @example
#   archive::remove-broken "${HOME}/Downloads"
archive::remove-broken() {
  [[ "$#" -le 1 ]] || return 64
  local file='' result=0 removed=0
  while IFS= read -r -d '' file; do
    result=0
    archive::_verify-file "${file}" || result="$?"
    # Other statuses mean the archive could not be verified; it is kept.
    [[ "${result}" -eq 1 ]] || continue
    rm -f -- "${file}" || return 74
    printf '%s\n' "${file}" >&2
    removed=1
  done < <(archive::_find "${1:-.}")
  [[ "${removed}" -eq 0 ]] || return 1
}

# @description List recognized archive files below a directory as NUL-separated paths.
# @internal
archive::_find() {
  [[ "$#" -le 1 ]] || return 64
  find "${1:-.}" -type f \( -name '*.tar' -o -name '*.tgz' -o -name '*.gz' -o -name '*.txz' -o -name '*.xz' \
    -o -name '*.tbz2' -o -name '*.tbz' -o -name '*.bz2' -o -name '*.tzst' -o -name '*.zst' \
    -o -name '*.zip' -o -name '*.7z' \) -print0
}

# @description Decompress one single compressed file, such as notes.txt.gz.
# @internal
archive::_extract-stream() {
  [[ "$#" -eq 4 && -f "$1" ]] || return 64
  local file="$1" format="$2" suffix="$3" directory="$4" compressor='' name='' output='' temporary=''
  compressor="$(archive::_compressor "${format}")" || return "$?"
  command::require "${compressor}" || return "$?"
  name="${file##*/}"
  name="${name%"${suffix}"}"
  [[ -n "${name}" ]] || return 64
  [[ -n "${directory}" ]] || directory="$(path::directory-name "${file}")" || return "$?"
  output="${directory%/}/${name}"
  if [[ -d "${output}" ]]; then
    console::_write-error "Not replacing the directory ${output}."
    return 73
  fi
  "${compressor}" -tq -- "${file}" >/dev/null 2>&1 || return 65
  mkdir -p -- "${directory}" || return 74
  temporary="$(mktemp "${directory%/}/.bashstock-extract.XXXXXX")" || return 74
  if ! "${compressor}" -dc -- "${file}" >"${temporary}" 2>/dev/null; then
    rm -f -- "${temporary}"
    return 65
  fi
  # mktemp creates the file with mode 600; give it the mode a new file gets.
  if ! chmod "$(printf '%o' "$((0666 & ~$(umask)))")" "${temporary}" || ! mv -f -- "${temporary}" "${output}"; then
    rm -f -- "${temporary}"
    return 74
  fi
}

# @description Unpack an archive into an empty staging directory.
# @internal
archive::_unpack() {
  [[ "$#" -eq 3 && -f "$1" && -d "$3" ]] || return 64
  local file="$1" format="$2" staging="$3" compressor='' seven=''
  case "${format}" in
    tar) tar -xf "${file}" -C "${staging}" || return 65 ;;
    tar.*)
      compressor="$(archive::_compressor "${format}")" || return "$?"
      (
        set +o pipefail
        "${compressor}" -dc -- "${file}" 2>/dev/null | tar -xf - -C "${staging}"
      ) || return 65
      ;;
    zip) unzip -oq "${file}" -d "${staging}" || return 65 ;;
    7z)
      seven="$(archive::_7zip)" || return "$?"
      "${seven}" x -y -bd "-o${staging}" -- "${file}" >/dev/null || return 65
      ;;
    *) return 64 ;;
  esac
}

# @description Extract one archive or decompress one compressed file.
#
# Archives (.tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2, .tbz2, .tbz,
# .tar.zst, .tzst, .zip, .7z) are extracted into a directory. Entry names that
# are absolute or climb with .. are refused before extraction. The archive is
# extracted into a staging directory inside the destination, and a symbolic
# link that points outside the destination discards the extraction with 65.
# A single compressed file (.gz, .xz, .bz2, .zst) is decompressed into one
# file named without the extension. Existing files are overwritten.
#
# @arg $1 string Archive or compressed file.
# @arg $2 string Optional output directory. Defaults to the archive path without its extension, or to the directory of a single compressed file.
# @stderr The rejected entry or symbolic link when the archive is refused.
# @exitcode 0 The archive was extracted.
# @exitcode 64 The arguments are invalid or the extension is not recognized.
# @exitcode 65 The archive is corrupt or contains an entry outside the destination.
# @exitcode 69 A required tool is unavailable, or the entry names of an encrypted 7z archive cannot be read.
# @exitcode 73 A single compressed file would replace a directory.
# @exitcode 74 The destination could not be written.
# @example
#   archive::extract-file release.tar.xz /opt/release
#   archive::extract-file access.log.gz
archive::extract-file() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  local file="$1" destination="${2:-}" format='' suffix='' listing='' entry='' staging='' link='' target='' resolved='' status=0
  read -r format suffix <<<"$(archive::_format "${file}")" || return 64
  [[ -n "${format}" ]] || return 64
  case "${format}" in
    gz | xz | bz2 | zst)
      archive::_extract-stream "${file}" "${format}" "${suffix}" "${destination}"
      return "$?"
      ;;
  esac
  destination="${destination:-${file%"${suffix}"}}"
  listing="$(archive::_list "${file}" "${format}")" || return "$?"
  while IFS= read -r entry; do
    if [[ "${entry}" == /* || "${entry}" == .. || "${entry}" == ../* || "${entry}" == */../* || "${entry}" == */.. ]]; then
      console::_write-error "Refusing archive entry outside the destination: ${entry}"
      return 65
    fi
  done <<<"${listing}"
  mkdir -p -- "${destination}" || return 74
  staging="$(mktemp -d "${destination%/}/.bashstock-extract.XXXXXX")" || return 74
  archive::_unpack "${file}" "${format}" "${staging}" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    while IFS= read -r -d '' link; do
      target="$(readlink -- "${link}")" || { status=74; break; }
      resolved="$(path::normalize "$(path::directory-name "${link#"${staging}"/}")/${target}")" || { status=74; break; }
      if [[ "${target}" == /* || "${resolved}" == .. || "${resolved}" == ../* ]]; then
        console::_write-error "Refusing symbolic link outside the destination: ${link#"${staging}"/} -> ${target}"
        status=65
        break
      fi
    done < <(find "${staging}" -type l -print0)
  fi
  if [[ "${status}" -ne 0 ]]; then
    rm -rf -- "${staging}"
    return "${status}"
  fi
  directory::merge "${staging}" "${destination}"
}

# @description Compress paths into a gzip-compressed tar archive.
#
# @arg $@ string Paths to add to the archive.
# @option --output <FILE> Archive to write. Defaults to the first path with .tar.gz appended.
# @exitcode 0 The archive was written.
# @exitcode 64 No path was given or --output has no value.
# @exitcode 69 tar is unavailable.
# @exitcode other The status of tar.
# @example
#   archive::compress-tar-gzip --output backup.tar.gz Documents Pictures
archive::compress-tar-gzip() { [[ "$#" -ge 1 ]] || return 64; local output='' paths=() path=''; while [[ "$#" -gt 0 ]]; do if [[ "$1" == '--output' ]]; then [[ "$#" -ge 2 ]] || return 64; output="$2"; shift 2; else paths+=("$1"); shift; fi; done; [[ "${#paths[@]}" -gt 0 ]] || return 64; [[ -n "$output" ]] || output="${paths[0]}.tar.gz"; command -v tar >/dev/null 2>&1 || return 69; tar -czf "$output" "${paths[@]}"; }

# @description List the named arguments of archive::compress-tar-gzip.
# @internal
archive::_compress-tar-gzip-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --output; fi
}

# @description Run diff for two directories.
#
# @arg $1 string Original directory.
# @arg $2 string Changed directory.
# @stdout A unified diff that includes new files.
# @exitcode 0 The directories are identical.
# @exitcode 1 The directories differ.
# @exitcode 64 The argument count is not two or a directory does not exist.
# @exitcode 69 diff is unavailable.
# @exitcode 2 diff failed.
# @example
#   diff::directories config.orig config > config.patch
diff::directories() { [[ "$#" -eq 2 && -d "$1" && -d "$2" ]] || return 64; command -v diff >/dev/null 2>&1 || return 69; diff -uprN -- "$1" "$2"; }

# @description Run a Git command in a working directory.
# @internal
git::_run-in-directory() { [[ "$#" -ge 2 && -d "$1" ]] || return 64; local directory="$1"; shift; command git -C "$directory" "$@"; }

# @description Clone a repository with depth one.
#
# @arg $1 string Repository URL.
# @arg $2 string Optional output directory. Defaults to the name Git derives from the URL.
# @option --branch <BRANCH> Branch or tag to check out.
# @exitcode 0 The repository was cloned.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of git clone.
# @example
#   git::clone-shallow https://github.com/reconquest/shdoc.git --branch v1.4 vendor/shdoc
git::clone-shallow() { [[ "$#" -ge 1 && "$#" -le 4 ]] || return 64; local url="$1" dir='' branch='' args=(); shift; while [[ "$#" -gt 0 ]]; do case "$1" in --branch) [[ "$#" -ge 2 ]] || return 64; branch="$2"; shift 2 ;; *) [[ -z "$dir" ]] || return 64; dir="$1"; shift ;; esac; done; args=(clone --depth 1); [[ -n "$branch" ]] && args+=(--branch "$branch"); args+=("$url"); [[ -n "$dir" ]] && args+=("$dir"); command git "${args[@]}"; }

# @description List the named arguments of git::clone-shallow.
# @internal
git::_clone-shallow-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --branch; fi
}

# @description Abort an in-progress rebase.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The rebase was aborted.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git rebase.
# @example
#   git::rebase-abort "${HOME}/src/project"
git::rebase-abort() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" rebase --abort; }

# @description Continue an in-progress rebase.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The rebase continued.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git rebase.
# @example
#   git add README.md && git::rebase-continue
git::rebase-continue() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" rebase --continue; }

# @description Amend the last commit without changing its message.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was amended.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git commit.
# @example
#   git add README.md && git::commit::amend
git::commit::amend() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" commit --amend --no-edit; }

# @description Create a commit with a message.
#
# @arg $1 string Commit message.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was created.
# @exitcode 64 The argument count is not one or two.
# @exitcode other The status of git commit.
# @example
#   git add README.md && git::commit::create 'docs: describe the installer'
git::commit::create() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" commit -m "$1"; }

# @description Remove the last commit while keeping its changes staged.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was removed.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git reset.
# @example
#   git::commit::uncommit
git::commit::uncommit() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" reset --soft HEAD^; }

# @description Write the current branch name.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The short name of the checked-out branch.
# @exitcode 0 The branch name was written.
# @exitcode 1 HEAD is detached or the directory is not a repository.
# @exitcode 64 More than one argument was given.
# @example
#   branch="$(git::branch::current)"
git::branch::current() { [[ "$#" -le 1 ]] || return 64; local branch=''; branch="$(git::_run-in-directory "${1:-.}" symbolic-ref --quiet --short HEAD 2>/dev/null)" || return 1; [[ -n "$branch" ]] && printf '%s\n' "$branch"; }

# @description Create a branch at a starting revision.
#
# @arg $1 string New branch name.
# @arg $2 string Optional starting revision. Defaults to HEAD.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was created.
# @exitcode 64 The argument count is not one to three.
# @exitcode other The status of git branch.
# @example
#   git::branch::create release/1.2 v1.2.0
git::branch::create() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" branch "$1" "${2:-HEAD}"; }

# @description List local and remote-tracking branches.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The output of git branch -a.
# @exitcode 0 The branches were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git branch.
# @example
#   git::branch::list
git::branch::list() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" branch -a; }

# @description Show file names changed between two revisions.
#
# @arg $1 string Base revision.
# @arg $2 string Optional target revision. Defaults to HEAD.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @stdout One changed path per line.
# @exitcode 0 The paths were written.
# @exitcode 64 The argument count is not one to three.
# @exitcode other The status of git diff.
# @example
#   git::diff::files origin/main
git::diff::files() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" diff --name-only "$1" "${2:-HEAD}"; }

# @description Show a patch between two revisions.
#
# @arg $1 string Base revision.
# @arg $2 string Optional target revision. Defaults to HEAD.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff.
# @exitcode 0 The patch was written.
# @exitcode 64 The argument count is not one to three.
# @exitcode other The status of git diff.
# @example
#   git::diff::patch v1.0.0 v1.1.0 > changes.patch
git::diff::patch() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" diff "$1" "${2:-HEAD}"; }

# @description Show the patch for uncommitted tracked changes.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of staged and unstaged tracked changes.
# @exitcode 0 The patch was written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git diff.
# @example
#   git::diff::uncommitted-patch > work.patch
git::diff::uncommitted-patch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" diff HEAD; }

# @description Show file names changed by uncommitted tracked changes.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout One changed path per line.
# @exitcode 0 The paths were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git diff.
# @example
#   git::diff::uncommitted-files
git::diff::uncommitted-files() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" diff --name-only HEAD; }

# @description Show the patch introduced by the latest commit.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of HEAD.
# @exitcode 0 The patch was written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git show.
# @example
#   git::diff::latest-patch > latest.patch
git::diff::latest-patch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" show --format= --patch HEAD; }

# @description Show file names changed by the latest commit.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout One changed path per line.
# @exitcode 0 The paths were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git show.
# @example
#   git::diff::latest-files
git::diff::latest-files() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" show --format= --name-only HEAD; }

# @description Write the unified diff that one commit introduced.
#
# The commit is fetched from REMOTE only when the repository lacks it, and it
# is compared with its first parent, or with the empty tree for a root commit.
#
# @arg $1 string Commit to show.
# @arg $2 string Optional remote to fetch a missing commit from. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of the commit.
# @exitcode 0 The patch was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The empty tree could not be computed.
# @exitcode other The status of the git command that failed.
# @example
#   git::commit::patch 3ce3b61 > fix.patch
git::commit::patch() {
  [[ "$#" -ge 1 && "$#" -le 3 && -n "$1" ]] || return 64
  local revision="$1" remote="${2:-origin}" directory="${3:-.}" parent='' empty_tree=''
  git::_require-commit "${revision}" "${remote}" "${directory}" || return "$?"
  parent="$(git::_run-in-directory "${directory}" rev-parse --verify --quiet "${revision}^1")" || parent=''
  if [[ -z "${parent}" ]]; then
    empty_tree="$(git::_run-in-directory "${directory}" hash-object -t tree /dev/null)" || return 74
    parent="${empty_tree}"
  fi
  git::_run-in-directory "${directory}" diff "${parent}" "${revision}"
}

# @description Make a commit available locally, fetching it from a remote only when it is missing.
# @internal
# @exitcode 1 The remote does not provide the commit either.
# @exitcode 69 The fetch from the remote failed.
git::_require-commit() {
  [[ "$#" -eq 3 ]] || return 64
  local revision="$1" remote="$2" directory="$3"
  git::_run-in-directory "${directory}" cat-file -e "${revision}^{commit}" 2>/dev/null && return 0
  git::_run-in-directory "${directory}" fetch "${remote}" "${revision}" || return 69
  if ! git::_run-in-directory "${directory}" cat-file -e "${revision}^{commit}" 2>/dev/null; then
    console::_write-error "Commit ${revision} is not available from ${remote}."
    return 1
  fi
}

# @description Revert a commit without creating a commit.
#
# @arg $1 string Optional commit to revert. Defaults to HEAD.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The changes were reverted in the working tree and index.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git revert.
# @example
#   git::commit::revert-without-commit 3ce3b61
git::commit::revert-without-commit() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" revert --no-commit "${1:-HEAD}"; }

# @description Revert a commit and create the revert commit.
#
# @arg $1 string Optional commit to revert. Defaults to HEAD.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The revert commit was created.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git revert.
# @example
#   git::commit::revert 3ce3b61
git::commit::revert() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" revert "${1:-HEAD}"; }

# @description Fetch one remote or all remotes.
#
# @arg $1 string Optional remote. Defaults to every remote.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The fetch finished.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git fetch.
# @example
#   git::fetch upstream
git::fetch() { [[ "$#" -le 2 ]] || return 64; local remote="${1:-}" directory="${2:-.}"; if [[ -n "$remote" ]]; then git::_run-in-directory "$directory" fetch "$remote"; else git::_run-in-directory "$directory" fetch --all; fi; }

# @description Convert a shallow clone into a complete history.
#
# @arg $1 string Optional remote to fetch. Defaults to every remote.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The history is complete.
# @exitcode 64 More than two arguments were given.
# @exitcode 66 The repository has no remote.
# @exitcode other The status of the git command that failed.
# @example
#   git::fetch-unshallow origin
git::fetch-unshallow() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${2:-.}" remote='' remotes=''
  if [[ -n "${1:-}" ]]; then
    remotes="$1"
  else
    remotes="$(git::_run-in-directory "${directory}" remote)" || return "$?"
    [[ -n "${remotes}" ]] || return 66
  fi
  while IFS= read -r remote; do
    # Only the first fetch can unshallow; later remotes complete normally.
    if [[ "$(git::_run-in-directory "${directory}" rev-parse --is-shallow-repository)" == true ]]; then
      git::_run-in-directory "${directory}" fetch --unshallow "${remote}" || return "$?"
    else
      git::_run-in-directory "${directory}" fetch "${remote}" || return "$?"
    fi
  done <<<"${remotes}"
}

# @description Show a stash patch.
#
# @arg $1 string Optional stash. Defaults to stash@{0}.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @stdout The unified diff of the stash.
# @exitcode 0 The patch was written.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::patch 'stash@{1}'
git::stash::patch() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash show --patch "${1:-stash@{0}}"; }

# @description Save tracked changes and untracked files in a new stash.
#
# @arg $1 string Optional stash message.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The changes were stashed.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::push 'before rebase'
git::stash::push() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${2:-.}"
  local arguments=(stash push --include-untracked)
  [[ -z "${1:-}" ]] || arguments+=(-m "$1")
  git::_run-in-directory "${directory}" "${arguments[@]}"
}

# @description Apply and remove a stash.
#
# @arg $1 string Optional stash. Defaults to stash@{0}.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The stash was applied and removed.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::pop
git::stash::pop() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash pop "${1:-stash@{0}}"; }

# @description Delete a stash.
#
# @arg $1 string Optional stash. Defaults to stash@{0}.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The stash was deleted.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of git stash.
# @example
#   git::stash::drop 'stash@{2}'
git::stash::drop() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash drop "${1:-stash@{0}}"; }

# @description Reset a working tree to a revision.
#
# @arg $1 string Revision to reset to.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The working tree and index match the revision.
# @exitcode 64 The argument count is not one or two.
# @exitcode other The status of git reset.
# @example
#   git::fetch origin && git::reset origin/main
git::reset() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" reset --hard "$1"; }

# @description Update a branch from a remote with rebase.
#
# @arg $1 string Optional remote branch to pull. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was updated.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git pull.
# @example
#   git::pull-rebase main upstream
git::pull-rebase() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_run-in-directory "${directory}" pull --rebase "${remote}" "${branch}"
}

# @description Apply one commit, fetching it from a remote only when the repository lacks it.
#
# @arg $1 string Commit to apply.
# @arg $2 string Optional remote to fetch a missing commit from. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The commit was applied.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of the git command that failed.
# @example
#   git::cherry-pick 3ce3b61 upstream
git::cherry-pick() {
  [[ "$#" -ge 1 && "$#" -le 3 && -n "$1" ]] || return 64
  local revision="$1" remote="${2:-origin}" directory="${3:-.}"
  git::_require-commit "${revision}" "${remote}" "${directory}" || return "$?"
  git::_run-in-directory "${directory}" cherry-pick "${revision}"
}

# @description Continue an in-progress cherry-pick.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The cherry-pick continued.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git cherry-pick.
# @example
#   git add src/util.sh && git::cherry-pick-continue
git::cherry-pick-continue() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" cherry-pick --continue; }

# @description Abort an in-progress cherry-pick.
#
# Untracked files left by the cherry-pick are stashed, or removed when stashing fails.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The cherry-pick was aborted.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of the git command that failed.
# @example
#   git::cherry-pick-abort
git::cherry-pick-abort() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-.}" path=''
  local untracked=()
  git::_run-in-directory "$directory" cherry-pick --abort || return "$?"
  while IFS= read -r -d '' path; do untracked+=("$path"); done \
    < <(git::_run-in-directory "$directory" ls-files --others --exclude-standard -z)
  [[ "${#untracked[@]}" -gt 0 ]] || return 0
  git::_run-in-directory "$directory" stash push --include-untracked -- "${untracked[@]}" && return 0
  git::_run-in-directory "$directory" clean -fd
}

# @description Push a branch to a remote.
#
# @arg $1 string Optional branch. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   git::push feature/login
git::push() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "$branch" ]] || branch="$(git::branch::current "$directory")" || return "$?"
  git::_run-in-directory "$directory" push "$remote" "$branch"
}

# @description Push a branch without overwriting a remote update.
#
# @arg $1 string Optional branch. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   git rebase origin/main && git::push::force-with-lease
git::push::force-with-lease() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "$branch" ]] || branch="$(git::branch::current "$directory")" || return "$?"
  git::_run-in-directory "$directory" push --force-with-lease "$remote" "$branch"
}

# @description Push the current HEAD to a Gerrit review reference.
#
# @arg $1 string Optional target branch of the review. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The review was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   gerrit::push-review main
gerrit::push-review() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_run-in-directory "${directory}" push "${remote}" "HEAD:refs/for/${branch}"
}

# @description Push the current HEAD to a Gerrit review reference as work in progress.
#
# @arg $1 string Optional target branch of the review. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The review was pushed.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   gerrit::push-review-wip main
gerrit::push-review-wip() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_run-in-directory "${directory}" push "${remote}" "HEAD:refs/for/${branch}%wip"
}

# @description Delete a branch on a remote.
#
# @arg $1 string Optional branch to delete. Defaults to the current branch.
# @arg $2 string Optional remote. Defaults to origin.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The remote branch was deleted.
# @exitcode 1 No branch was given and HEAD is detached.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of git push.
# @example
#   git::remote::delete-branch feature/login
git::remote::delete-branch() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-}" remote="${2:-origin}" directory="${3:-.}"
  [[ -n "${branch}" ]] || branch="$(git::branch::current "${directory}")" || return "$?"
  git::_run-in-directory "${directory}" push "${remote}" --delete "${branch}"
}

# @description Update all submodules recursively.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 Every submodule was initialized and updated.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git submodule.
# @example
#   git::submodule::update-all
git::submodule::update-all() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" submodule update --init --recursive; }

# @description Discard all changes in a working tree.
#
# The changes, including untracked files, are first saved in a stash, and the branch is reset to the parent of HEAD.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The changes were stashed and the latest commit was removed.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of the git command that failed, including when HEAD has no parent.
# @example
#   git::commit::discard
git::commit::discard() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-.}"
  git::_run-in-directory "$directory" rev-parse --verify 'HEAD^' >/dev/null || return "$?"
  git::_run-in-directory "$directory" stash push --include-untracked || return "$?"
  git::_run-in-directory "$directory" reset --hard HEAD^
}

# @description Hard reset the current branch to the branch with the same name on a remote.
#
# @arg $1 string Optional remote. Defaults to origin.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch matches the remote branch.
# @exitcode 1 HEAD is detached.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of the git command that failed.
# @example
#   git::reset-remote upstream
git::reset-remote() {
  [[ "$#" -le 2 ]] || return 64
  local remote="${1:-origin}" directory="${2:-.}" branch=''
  branch="$(git::branch::current "${directory}")" || return "$?"
  git::_run-in-directory "${directory}" fetch "${remote}" || return "$?"
  git::_run-in-directory "${directory}" reset --hard "${remote}/${branch}"
}

# @description Pull the configured base branch with fast-forward-only semantics.
#
# The base branch is checked out and fast-forwarded from origin, and the original branch is then rebased onto it.
#
# @arg $1 string Optional base branch. Defaults to main.
# @arg $2 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The base branch was updated and the current branch was rebased.
# @exitcode 64 More than two arguments were given.
# @exitcode 65 HEAD is detached.
# @exitcode 75 The base branch could not be fast-forwarded, or the original branch could not be checked out again.
# @exitcode other The status of git checkout or git rebase.
# @example
#   git::pull-base-branch develop
git::pull-base-branch() { [[ "$#" -le 2 ]] || return 64; local base="${1:-main}" directory="${2:-.}" current=''; current="$(git::branch::current "$directory")" || return 65; git::_run-in-directory "$directory" checkout "$base" -- || return "$?"; if ! git::_run-in-directory "$directory" pull --ff-only origin "$base"; then git::_run-in-directory "$directory" checkout "$current" -- >/dev/null 2>&1 || true; return 75; fi; git::_run-in-directory "$directory" checkout "$current" -- || return 75; git::_run-in-directory "$directory" rebase "$base"; }

# @description Import the variables of a dotenv file into the current process.
#
# The file is parsed as data and never executed. Every line is validated
# before any variable changes; see env::dotenv::_entries for the syntax.
#
# @arg $1 string Regular dotenv file. A symbolic link is refused.
# @set Each variable of the file is set and exported.
# @exitcode 0 The variables were imported.
# @exitcode 64 The argument is not one regular file.
# @exitcode 65 A line is not valid dotenv syntax; no variable changes.
# @exitcode other The status of the parser.
# @example
#   env::dotenv::import .env && printf '%s\n' "${DATABASE_URL}"
env::dotenv::import() {
  [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64
  env::dotenv::_entries "$1" >/dev/null || return "$?"
  local __bashstock_dotenv_key='' __bashstock_dotenv_value=''
  while IFS= read -r -d '' __bashstock_dotenv_key && IFS= read -r -d '' __bashstock_dotenv_value; do
    printf -v "${__bashstock_dotenv_key}" '%s' "${__bashstock_dotenv_value}"
    export "${__bashstock_dotenv_key?}"
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
# returns 65 and writes nothing.
# @internal
env::dotenv::_entries() {
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
}

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
  [[ "$#" -ge 2 && "$#" -le 3 && "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 64
  local name="$1" value="$2" shells="${3:-bash,zsh}" shell='' rc='' quoted=''
  [[ "$shells" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] || return 64
  printf -v quoted '%q' "$value"
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
  [[ "$shells" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] || return 64
  printf -v quoted '%q' "$path"
  line="__bashstock_path=${quoted}; case \":\$PATH:\" in *\":\$__bashstock_path:\"*) ;; *) if [ -n \"\$PATH\" ]; then PATH=\"\$PATH:\$__bashstock_path\"; else PATH=\"\$__bashstock_path\"; fi; export PATH ;; esac; unset __bashstock_path"
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
  [[ "${shells}" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] || return 64
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

# @description Create a symbolic link in a user's local bin directory.
#
# @arg $1 string Existing file or directory to link to.
# @arg $2 string Optional link name. Defaults to the base name of the source.
# @arg $3 string Optional bin directory. Defaults to $HOME/.local/bin.
# @exitcode 0 The link was created.
# @exitcode 64 The arguments are invalid or the source does not exist.
# @exitcode 74 The bin directory could not be created.
# @exitcode other The status of symlink::create.
# @example
#   symlink::create-in-local-bin /opt/flutter/bin/flutter
symlink::create-in-local-bin() { [[ "$#" -ge 1 && "$#" -le 3 && -e "$1" ]] || return 64; local source="$1" name="${2:-$(basename -- "$1")}" directory="${3:-$HOME/.local/bin}"; mkdir -p -- "$directory" || return 74; symlink::create "$source" "$directory/$name"; }

# @description Create $HOME/.ssh and give it and its files the modes SSH expects.
#
# Entries owned by another user are first given back to the current user
# through administrator execution. Directories become 700 and files 644,
# except private keys, config, and authorized_keys, which become 600. A
# private key is recognized by its PEM or OpenSSH header, so no passphrase
# is ever requested.
#
# @noargs
# @exitcode 0 The directory and its files have the expected modes.
# @exitcode 64 An argument was given.
# @exitcode 74 A mode or owner could not be changed.
# @example
#   ssh::setup-directory
ssh::setup-directory() {
  [[ "$#" -eq 0 ]] || return 64
  local directory="${HOME}/.ssh" path='' header=''
  mkdir -p -- "${directory}" || return 74
  if [[ -n "$(find "${directory}" ! -user "$(id -u)" -print 2>/dev/null | head -n 1)" ]]; then
    command::run-as-root chown -R "$(id -u):$(id -g)" "${directory}" || return 74
  fi
  find "${directory}" -type d -exec chmod 700 {} + || return 74
  while IFS= read -r -d '' path; do
    header=''
    IFS= read -r header <"${path}" 2>/dev/null || true
    case "${path##*/}:${header}" in
      config:* | authorized_keys:* | *:'-----BEGIN '*'PRIVATE KEY-----') chmod 600 "${path}" || return 74 ;;
      *) chmod 644 "${path}" || return 74 ;;
    esac
  done < <(find "${directory}" -type f -print0)
}

# @description Replace one marker-managed SSH Host block and validate the resulting configuration.
# @internal
ssh::config::_write-block() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  local file="$1" pattern="$2" options="$3" begin='' end='' line='' content='' preserved='' old_content='' keys='' option='' key='' validation_host='localhost' token=''
  [[ -f "$file" && ! -L "$file" ]] || return 66
  [[ "$pattern" != *$'\n'* && "$pattern" != *$'\r'* ]] || return 64
  [[ "$options" != *$'\r'* ]] || return 64
  command -v ssh >/dev/null 2>&1 || return 69
  old_content="$(<"$file")"
  while IFS= read -r option || [[ -n "$option" ]]; do
    [[ "$option" == '  '* ]] || continue
    key="${option#  }"
    key="${key%% *}"
    keys+="|$key|"
  done <<<"$options"
  begin="# bashstock: begin $pattern"
  end='# bashstock: end'
  local in_block=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$begin" ]]; then
      in_block=1
      continue
    fi
    if ((in_block)); then
      [[ "$line" == "$end" ]] && in_block=0
      if ((in_block)) && [[ "$line" == '  '* ]]; then
        key="${line#  }"
        key="${key%% *}"
        [[ "$keys" == *"|$key|"* ]] && continue
        preserved+="$line"$'\n'
      fi
      continue
    fi
    content+="$line"$'\n'
  done <"$file"
  local block=''
  block="$begin"$'\n'"Host $pattern"$'\n'
  block+="$preserved$options"$'\n'"$end"$'\n'
  file::write-text "$file" "$block$content" || return "$?"
  local pattern_parts=()
  read -r -a pattern_parts <<<"$pattern"
  for token in "${pattern_parts[@]}"; do
    [[ "$token" == '!'* ]] && continue
    validation_host="$token"
    break
  done
  if ! ssh -G -F "$file" "$validation_host" >/dev/null 2>&1; then
    file::write-text "$file" "$old_content" >/dev/null 2>&1 || true
    return 65
  fi
}

# @description Update one key in a marker-managed SSH Host block.
#
# The Host block is created when missing. Only blocks written by BashStock are changed.
#
# @arg $1 string SSH configuration file.
# @arg $2 string Host pattern.
# @arg $3 string Key, such as IdentityFile.
# @arg $4 string Value on one line.
# @exitcode 0 The key was written.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of the file update.
# @example
#   ssh::config::update "${HOME}/.ssh/config" github.com IdentityFile '~/.ssh/github'
ssh::config::update() {
  [[ "$#" -eq 4 && -n "$1" && -n "$2" && "$3" =~ ^[A-Za-z][A-Za-z0-9]*$ && -n "$4" ]] || return 64
  [[ "$4" != *$'\n'* && "$4" != *$'\r'* ]] || return 64
  ssh::config::_write-block "$1" "$2" "  $3 $4"
}

# @description Create an SSH configuration file when necessary and update one key.
#
# @arg $1 string SSH configuration file. It and its directory are created when missing.
# @arg $2 string Host pattern.
# @arg $3 string Key, such as User.
# @arg $4 string Value on one line.
# @exitcode 0 The key was written.
# @exitcode 64 The arguments are invalid or the file is a symbolic link.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 74 The file could not be created.
# @exitcode other The status of ssh::config::update.
# @example
#   ssh::config::set "${HOME}/.ssh/config" 'build-*' User builder
ssh::config::set() {
  [[ "$#" -eq 4 && -n "$1" ]] || return 64
  [[ ! -L "$1" ]] || return 64
  if [[ -e "$1" && ! -f "$1" ]]; then return 66; fi
  if [[ ! -e "$1" ]]; then
    mkdir -p -- "$(path::directory-name "$1")" || return 74
    : >"$1" || return 74
  fi
  ssh::config::update "$@"
}

# @description Enable AddKeysToAgent for an optional SSH Host pattern.
#
# @arg $1 string Optional SSH configuration file. Defaults to $HOME/.ssh/config.
# @arg $2 string Optional Host pattern. Defaults to *.
# @exitcode 0 AddKeysToAgent is enabled.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of ssh::config::set.
# @example
#   ssh::config::enable-auto-add-keys
ssh::config::enable-auto-add-keys() {
  [[ "$#" -le 2 ]] || return 64
  local file='' pattern=''
  if [[ "$#" -ge 1 ]]; then file="$1"; else file="$HOME/.ssh/config"; fi
  if [[ "$#" -ge 2 ]]; then pattern="$2"; else pattern='*'; fi
  ssh::config::set "$file" "$pattern" AddKeysToAgent yes
}

# @description Disable SSH host-key checks for an optional Host pattern.
#
# Normal use should register the correct host key in known_hosts instead.
#
# @arg $1 string Optional SSH configuration file. Defaults to $HOME/.ssh/config.
# @arg $2 string Optional Host pattern. Defaults to *.
# @exitcode 0 Host-key checks are disabled for the pattern.
# @exitcode 64 More than two arguments were given or the file is a symbolic link.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 74 The file could not be created.
# @exitcode other The status of the file update.
# @example
#   ssh::config::disable-host-key-checking "${HOME}/.ssh/config" '192.168.56.*'
ssh::config::disable-host-key-checking() {
  [[ "$#" -le 2 ]] || return 64
  local file='' pattern=''
  if [[ "$#" -ge 1 ]]; then file="$1"; else file="$HOME/.ssh/config"; fi
  if [[ "$#" -ge 2 ]]; then pattern="$2"; else pattern='*'; fi
  [[ ! -L "$file" ]] || return 64
  if [[ -e "$file" && ! -f "$file" ]]; then return 66; fi
  if [[ ! -e "$file" ]]; then
    mkdir -p -- "$(path::directory-name "$file")" || return 74
    : >"$file" || return 74
  fi
  ssh::config::_write-block "$file" "$pattern" $'  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null'
}

# @description List regular files that ssh-keygen can read as private keys.
#
# @arg $1 string Optional directory. Defaults to $HOME/.ssh.
# @stdout One private key path per line.
# @exitcode 0 The paths were written; none may match.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode 69 ssh-keygen is unavailable.
# @example
#   ssh::key::private-files
ssh::key::private-files() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' path=''
  if [[ "$#" -ge 1 ]]; then directory="$1"; else directory="$HOME/.ssh"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  command -v ssh-keygen >/dev/null 2>&1 || return 69
  (
    shopt -s nullglob dotglob
    for path in "$directory"/*; do
      [[ -f "$path" && ! -L "$path" ]] || continue
      ssh-keygen -y -f "$path" </dev/null >/dev/null 2>&1 && printf '%s\n' "$path"
    done
    :
  )
}

# @description Add one private key to ssh-agent.
#
# @arg $1 string Private key file.
# @exitcode 0 The key was added.
# @exitcode 64 The argument is not one regular file.
# @exitcode 69 ssh-add is unavailable.
# @exitcode other The status of ssh-add.
# @example
#   ssh::key::add "${HOME}/.ssh/id_ed25519"
ssh::key::add() {
  [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64
  command -v ssh-add >/dev/null 2>&1 || return 69
  ssh-add "$1"
}

# @description Add every detected private key in a directory to ssh-agent.
#
# @arg $1 string Optional directory. Defaults to $HOME/.ssh.
# @exitcode 0 Every key was added.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode 69 ssh-add or ssh-keygen is unavailable.
# @exitcode other The status of the last ssh-add that failed.
# @example
#   ssh::key::add-all
ssh::key::add-all() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' path='' status=0
  if [[ "$#" -ge 1 ]]; then directory="$1"; else directory="$HOME/.ssh"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  command -v ssh-add >/dev/null 2>&1 || return 69
  while IFS= read -r path; do
    ssh::key::add "$path" || status="$?"
  done < <(ssh::key::private-files "$directory") || return "$?"
  return "$status"
}

# @description Add every detected private key in a directory to ssh-agent.
#
# This is an alias of ssh::key::add-all.
#
# @arg $1 string Optional directory. Defaults to $HOME/.ssh.
# @exitcode 0 Every key was added.
# @exitcode other The status of ssh::key::add-all.
# @example
#   ssh::key::add-all-private-keys
ssh::key::add-all-private-keys() { ssh::key::add-all "$@"; }

# @description Send ICMP echo requests to a host.
#
# @arg $1 string Optional host name or address. Defaults to google.com.
# @arg $2 integer Optional number of requests. Defaults to 3.
# @arg $3 integer Optional seconds to wait for each reply. Defaults to 5.
# @stdout The output of ping.
# @exitcode 0 A reply was received.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 ping is unavailable or the operating system is unsupported.
# @exitcode other The status of ping.
# @example
#   net::ping 192.168.1.1 1 2
net::ping() {
  [[ "$#" -le 3 ]] || return 64
  local host="${1:-google.com}" attempts="${2:-3}" timeout="${3:-5}"
  [[ -n "${host}" && "${attempts}" =~ ^[1-9][0-9]*$ && "${timeout}" =~ ^[1-9][0-9]*$ ]] || return 64
  command::require ping || return "$?"
  case "$(system::operating-system)" in
    # BSD ping takes the reply timeout in milliseconds.
    darwin) ping -c "${attempts}" -W "$((timeout * 1000))" "${host}" ;;
    linux) ping -c "${attempts}" -W "${timeout}" "${host}" ;;
    *) return 69 ;;
  esac
}

# @description Test whether a string is one IPv4 or IPv6 address.
# @internal
net::_is-ip-address() {
  [[ "$#" -eq 1 ]] || return 64
  local octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
  [[ "$1" =~ ^${octet}\.${octet}\.${octet}\.${octet}$ ]] && return 0
  [[ "$1" =~ ^[0-9A-Fa-f:.]+$ && "$1" == *:*:* && "$1" != *:::* ]]
}

# @description Disable every active swap area through administrator execution.
#
# @noargs
# @exitcode 0 Every swap area is disabled.
# @exitcode 64 An argument was given.
# @exitcode 69 swapoff is unavailable.
# @exitcode other The status of swapoff.
# @example
#   swap::disable-all
swap::disable-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require swapoff || return "$?"
  command::run-as-root swapoff --all
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
#   swap::remove-all-files && swap::create 4294967296
swap::remove-all-files() {
  [[ "$#" -eq 0 ]] || return 64
  [[ -r /proc/swaps ]] || return 69
  local path='' content=''
  while IFS= read -r path; do
    # /proc/swaps escapes spaces in paths as \040.
    path="${path//\\040/ }"
    command::run-as-root swapoff "${path}" || { console::_write-error "Could not disable ${path}."; return 74; }
    if [[ -f /etc/fstab ]]; then
      content="$(awk -v path="${path}" '$1 != path || $3 != "swap"' /etc/fstab)" || return 74
      file::write-text /etc/fstab "${content}"$'\n' || { console::_write-error "Could not update /etc/fstab for ${path}."; return 74; }
    fi
    command::run-as-root rm -f -- "${path}" || { console::_write-error "Could not delete ${path}."; return 74; }
  done < <(awk 'NR > 1 && $2 == "file" {print $1}' /proc/swaps)
}

# @description Create a swap file, enable it, and register it in /etc/fstab.
#
# The file is created and enabled through administrator execution.
#
# @arg $1 integer Optional size in bytes. Defaults to 8589934592 (8 GiB).
# @arg $2 string Optional absolute swap file path. Defaults to /swapfile.
# @stderr A message when the path already exists.
# @exitcode 0 The swap file is enabled and registered.
# @exitcode 64 The size or path is invalid.
# @exitcode 69 The system is not Linux or mkswap is unavailable.
# @exitcode 73 The path already exists.
# @exitcode 74 The file could not be created or enabled.
# @exitcode other The status of the /etc/fstab update.
# @example
#   swap::create 4294967296
swap::create() {
  [[ "$#" -le 2 ]] || return 64
  local size="${1:-8589934592}" path="${2:-/swapfile}"
  [[ "${size}" =~ ^[1-9][0-9]*$ && "${path}" == /* ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require mkswap || return "$?"
  if [[ -e "${path}" || -L "${path}" ]]; then
    console::_write-error "${path} already exists."
    return 73
  fi
  if ! command::run-as-root fallocate -l "${size}" "${path}" 2>/dev/null; then
    # Some file systems cannot preallocate; write zeros instead.
    command::run-as-root dd if=/dev/zero of="${path}" bs=1M count="$(((size + 1048575) / 1048576))" status=none || {
      command::run-as-root rm -f -- "${path}"
      return 74
    }
  fi
  command::run-as-root chmod 600 "${path}" || return 74
  command::run-as-root mkswap "${path}" >/dev/null || return 74
  command::run-as-root swapon "${path}" || return 74
  if ! awk -v path="${path}" '$1 == path && $3 == "swap" {found = 1} END {exit !found}' /etc/fstab 2>/dev/null; then
    file::append-text /etc/fstab "${path} none swap sw 0 0"$'\n' || return "$?"
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
#   swap::list
swap::list() { [[ "$#" -eq 0 ]] || return 64; command -v swapon >/dev/null 2>&1 || return 69; swapon --show; }

# @description Write the paths below a directory that match a case-insensitive Bash ERE, separated by NUL.
#
# @arg $1 string Extended regular expression evaluated by Bash on each path.
# @arg $2 string Optional directory to search. Defaults to the current directory.
# @stdout NUL-separated matching paths.
# @exitcode 0 At least one path matches.
# @exitcode 1 No path matches.
# @exitcode 64 The arguments are invalid or the expression is not valid.
# @exitcode 66 The directory does not exist.
# @example
#   path::find '\.(jpe?g|png)$' "${HOME}/Pictures" | xargs -0 ls -l
path::find() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  local expression="$1" directory="${2:-.}" path='' found=1 status=0
  [[ -d "${directory}" ]] || return 66
  # [[ =~ ]] returns 2 for an invalid expression.
  # shellcheck disable=SC2319
  [[ '' =~ ${expression} ]] || status="$?"
  [[ "${status}" -ne 2 ]] || return 64
  (
    shopt -s nocasematch
    while IFS= read -r -d '' path; do
      if [[ "${path}" =~ ${expression} ]]; then
        printf '%s\0' "${path}"
        found=0
      fi
    done < <(find "${directory}" -print0)
    exit "${found}"
  )
}

# @description Write the directories and text files below a path, with the contents of each text file.
#
# Directories are written as paths. Regular files whose MIME type is text/*
# are written by file::_print-text; other files are skipped.
#
# @arg $1 string Optional starting path. Defaults to the current directory.
# @arg $2 integer Optional minimum depth. Defaults to 1.
# @arg $3 integer Optional maximum depth. Unlimited when omitted.
# @stdout Directory paths and the contents of text files.
# @exitcode 0 The tree was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 66 The path does not exist.
# @exitcode 69 file is unavailable.
# @exitcode other The status of the file that could not be written.
# @example
#   file::tree-with-contents src 1 2 > context.txt
file::tree-with-contents() {
  [[ "$#" -le 3 ]] || return 64
  local path="${1:-.}" minimum="${2:-1}" maximum="${3:-}" entry=''
  [[ -e "${path}" ]] || return 66
  [[ "${minimum}" =~ ^[0-9]+$ && ( -z "${maximum}" || "${maximum}" =~ ^[0-9]+$ ) ]] || return 64
  command::require file || return "$?"
  local arguments=("${path}" -mindepth "${minimum}")
  [[ -z "${maximum}" ]] || arguments+=(-maxdepth "${maximum}")
  while IFS= read -r -d '' entry; do
    if [[ -d "${entry}" && ! -L "${entry}" ]]; then
      printf '%s\n' "${entry}"
    elif [[ -f "${entry}" && ! -L "${entry}" ]]; then
      file::_print-text "${entry}" || return "$?"
    fi
  done < <(find "${arguments[@]}" -print0)
}

# @description Write a text file between header lines; files of other MIME types write nothing.
# @internal
file::_print-text() {
  [[ "$#" -eq 1 && -f "$1" ]] || return 64
  local type=''
  type="$(file --brief --mime-type -- "$1")" || return 74
  [[ "${type}" == text/* ]] || return 0
  printf '==> %s <==\n' "$1"
  cat -- "$1" || return 74
  [[ -z "$(tail -c 1 -- "$1")" ]] || printf '\n'
}

# @description Test whether a TCP connection to HOST and PORT succeeds, without output.
#
# @arg $1 string Host name or address.
# @arg $2 integer TCP port.
# @arg $3 integer Optional connection timeout in seconds. Defaults to 10.
# @exitcode 0 The connection succeeded.
# @exitcode 1 The connection failed.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 nc is unavailable.
# @example
#   net::tcp::test github.com 22 5 && git::fetch
# shellcheck disable=SC2329
net::tcp::test() {
  [[ "$#" -ge 2 && "$#" -le 3 && -n "$1" && "$2" =~ ^[0-9]+$ ]] || return 64
  local timeout="${3:-10}"
  [[ "${timeout}" =~ ^[1-9][0-9]*$ ]] || return 64
  command::require nc || return "$?"
  nc -z -w "${timeout}" "$1" "$2" >/dev/null 2>&1
}

# @description Open a serial device with a configured baud rate.
#
# @arg $1 string Serial device.
# @arg $2 integer Optional baud rate. Defaults to 115200.
# @exitcode 0 The baud rate was set.
# @exitcode 64 The arguments are invalid or the device does not exist.
# @exitcode 69 stty is unavailable.
# @exitcode other The status of stty.
# @example
#   serial::configure /dev/ttyUSB0 9600
serial::configure() { [[ "$#" -ge 1 && "$#" -le 2 && -e "$1" ]] || return 64; local device="$1" baud="${2:-115200}"; command -v stty >/dev/null 2>&1 || return 69; stty -F "$device" "$baud" 2>/dev/null || stty -f "$device" "$baud"; }

# @description Write literal data to a serial device.
#
# @arg $1 string Serial device.
# @arg $2 string Data to write without a terminator.
# @exitcode 0 The data was written.
# @exitcode 1 The device could not be written.
# @exitcode 64 The argument count is not two or the device does not exist.
# @example
#   serial::write /dev/ttyUSB0 'AT'
serial::write() { [[ "$#" -eq 2 && -e "$1" ]] || return 64; printf '%s' "$2" >"$1"; }

# @description Write a command and terminator to a serial device.
#
# @arg $1 string Serial device.
# @arg $2 string Command to write.
# @arg $3 string Optional terminator: none, cr, lf, or crlf. Defaults to cr.
# @arg $4 number Optional seconds to wait after writing. Defaults to 0.
# @exitcode 0 The command was written.
# @exitcode 64 The arguments, terminator, or wait time are invalid.
# @exitcode 74 The device could not be written.
# @example
#   serial::write-command /dev/ttyUSB0 'AT+GMR' crlf 0.5
serial::write-command() { [[ "$#" -ge 2 && "$#" -le 4 && -e "$1" ]] || return 64; local device="$1" data="$2" terminator="${3:-cr}" wait="${4:-0}" suffix=''; case "$terminator" in none) suffix='' ;; cr) suffix=$'\r' ;; lf) suffix=$'\n' ;; crlf) suffix=$'\r\n' ;; *) return 64 ;; esac; printf '%s%s' "$data" "$suffix" >"$device" || return 74; [[ "$wait" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 64; [[ "$wait" == 0 ]] || sleep "$wait"; }

# @description Open a serial device in GNU Screen through administrator execution and log the session.
#
# @arg $1 string Serial device path.
# @arg $2 integer Optional baud rate. Defaults to 115200.
# @arg $3 string Optional log file. Defaults to a file named with the date and time in ${TTY_LOG_DIR:-.}.
# @exitcode 0 The session ended successfully.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 screen is unavailable.
# @exitcode 74 The log directory could not be created.
# @exitcode other The status of screen.
# @example
#   TTY_LOG_DIR="${HOME}/logs" screen::open-serial /dev/ttyUSB0
screen::open-serial() {
  [[ "$#" -ge 1 && "$#" -le 3 && -e "$1" ]] || return 64
  local device="$1" baud="${2:-115200}" log="${3:-}" stamp=''
  [[ "${baud}" =~ ^[1-9][0-9]*$ ]] || return 64
  command::require screen || return "$?"
  if [[ -z "${log}" ]]; then
    stamp="$(time::local-date-time-seconds-basic)" || return "$?"
    log="${TTY_LOG_DIR:-.}/${stamp}-screen.log"
  fi
  mkdir -p -- "$(path::directory-name "${log}")" || return 74
  command::run-as-root screen -L -Logfile "${log}" "${device}" "${baud}"
}

# @description End every GNU Screen process of every user through administrator execution.
#
# Having no Screen process is a success.
#
# @noargs
# @exitcode 0 No Screen process remains.
# @exitcode 64 An argument was given.
# @exitcode 69 pkill is unavailable.
# @exitcode other The status of pkill.
# @example
#   screen::kill-all
screen::kill-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require pkill || return "$?"
  local status=0
  command::run-as-root pkill screen || status="$?"
  # pkill returns 1 when no process matched.
  [[ "${status}" -eq 1 ]] && return 0
  return "${status}"
}

# @description Run an external command while preserving its output and status.
# @internal
util::_run-command() { [[ "$#" -ge 1 ]] || return 64; command -v "$1" >/dev/null 2>&1 || return 69; local command_name="$1"; shift; command "$command_name" "$@"; }

# @description Capture packets addressed to a host.
#
# tcpdump is retried through sudo when it fails without administrator rights.
#
# @arg $1 string Host name or address.
# @arg $2 string Optional interface. Defaults to any.
# @stdout The packets that tcpdump captures.
# @exitcode 0 The capture ended successfully.
# @exitcode 64 The argument count is not one or two.
# @exitcode 69 The capture failed and sudo is unavailable.
# @exitcode other The status of tcpdump.
# @example
#   net::capture-host 192.168.1.20 eth0
net::capture-host() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; local host="$1" interface="${2:-any}"; if tcpdump -i "$interface" host "$host" 2>/dev/null; then return 0; fi; command -v sudo >/dev/null 2>&1 || return 69; sudo tcpdump -i "$interface" host "$host"; }

# @description Write a TCP port number the operating system reports as unused.
#
# A socket is bound to port 0 on the loopback address, and the port the
# system assigned is written before the socket closes.
#
# @noargs
# @stdout The port number.
# @exitcode 0 The port was written.
# @exitcode 64 An argument was given.
# @exitcode 69 perl is unavailable or the socket could not be bound.
# @example
#   port="$(net::unused-port)" && python3 -m http.server "${port}"
net::unused-port() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  perl -MSocket -e '
    socket(my $socket, PF_INET, SOCK_STREAM, getprotobyname("tcp")) or exit 69;
    bind($socket, pack_sockaddr_in(0, inet_aton("127.0.0.1"))) or exit 69;
    my ($port) = unpack_sockaddr_in(getsockname($socket));
    print "$port\n";
  '
}

# @description Release a serial device so another process, such as a Python tool, can open it.
#
# The reference implementation called file-close on the device, which
# killed every holder at once; this follows file::release instead: SIGTERM
# first, SIGKILL only for holders left after the timeout.
#
# @arg $1 string Serial device path.
# @arg $2 integer Optional seconds to wait after SIGTERM. Defaults to 2.
# @exitcode 0 No process holds the device.
# @exitcode 64 The arguments are invalid or the device does not exist.
# @exitcode other The status of file::release.
# @example
#   serial::release /dev/ttyACM0 && esptool.py --port /dev/ttyACM0 chip_id
serial::release() {
  [[ "$#" -ge 1 && "$#" -le 2 && -e "$1" ]] || return 64
  file::release "$@"
}

# @description Initialize a Google Repo workspace with shallow history.
#
# @arg $1 string Manifest repository URL.
# @arg $2 string Manifest branch.
# @arg $3 string Manifest file name.
# @arg $4 string Optional workspace directory, created when missing. Defaults to the current directory.
# @exitcode 0 The workspace was initialized.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 repo is unavailable.
# @exitcode 74 The directory could not be created.
# @exitcode other The status of repo init.
# @example
#   repo::init https://android.googlesource.com/platform/manifest android-14.0.0_r1 default.xml aosp
repo::init() {
  [[ "$#" -ge 3 && "$#" -le 4 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  local directory="${4:-.}"
  command::require repo || return "$?"
  mkdir -p -- "${directory}" || return 74
  (cd -- "${directory}" && repo init --depth=1 -u "$1" -b "$2" -m "$3")
}

# @description Synchronize one path of a Google Repo workspace, forcing the sync.
#
# @arg $1 string Project path to synchronize.
# @arg $2 integer Optional parallel jobs. Defaults to 4.
# @arg $3 string Optional workspace directory. Defaults to the current directory.
# @exitcode 0 The project was synchronized.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo sync.
# @example
#   repo::sync frameworks/base 8 aosp
repo::sync() {
  [[ "$#" -ge 1 && "$#" -le 3 && -n "$1" ]] || return 64
  local jobs="${2:-4}" directory="${3:-.}"
  [[ "${jobs}" =~ ^[1-9][0-9]*$ ]] || return 64
  command::require repo || return "$?"
  (cd -- "${directory}" && repo sync --force-sync -j "${jobs}" "$1")
}

# @description Write the current Google Repo manifest with revisions to a file.
#
# @arg $1 string Optional output file. Defaults to ./manifest.xml.
# @arg $2 string Optional workspace directory. Defaults to the current directory.
# @exitcode 0 The manifest was written.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo manifest.
# @example
#   repo::write-manifest pinned.xml aosp
repo::write-manifest() {
  [[ "$#" -le 2 ]] || return 64
  local output="${1:-./manifest.xml}" directory="${2:-.}"
  command::require repo || return "$?"
  [[ "${output}" == /* ]] || output="${PWD}/${output}"
  (cd -- "${directory}" && repo manifest -r -o "${output}")
}

# @description Run git fsck in every project of a Google Repo workspace.
#
# @arg $1 string Optional workspace directory. Defaults to the current directory.
# @stdout The output of git fsck for each project.
# @exitcode 0 Every project passed.
# @exitcode 64 More than one argument was given.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo forall.
# @example
#   repo::check aosp
repo::check() {
  [[ "$#" -le 1 ]] || return 64
  command::require repo || return "$?"
  (cd -- "${1:-.}" && repo forall -c 'git fsck')
}

# @description List running Docker containers.
#
# @noargs
# @stdout The output of docker ps.
# @exitcode 0 The containers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker ps.
# @example
#   docker::container::list-running
docker::container::list-running() { [[ "$#" -eq 0 ]] || return 64; util::_run-command docker ps; }

# @description List Docker containers.
#
# @noargs
# @stdout The output of docker ps -a.
# @exitcode 0 The containers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker ps.
# @example
#   docker::container::list
docker::container::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command docker ps -a; }

# @description Copy files between a Docker container and the host.
#
# @arg $1 string Container name or ID.
# @arg $2 string Path in the container.
# @arg $3 string Optional host destination. Defaults to the current directory.
# @exitcode 0 The files were copied.
# @exitcode 64 The argument count is not two or three.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker cp.
# @example
#   docker::container::pull web /var/log/nginx ./logs
docker::container::pull() { [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64; local container="$1" source="$2" destination="${3:-.}"; util::_run-command docker cp "$container:$source" "$destination"; }

# @description Copy a host path into a container.
#
# @arg $1 string Container name or ID.
# @arg $2 string Path on the host.
# @arg $3 string Optional destination in the container. Defaults to its working directory.
# @exitcode 0 The files were copied.
# @exitcode 64 The argument count is not two or three.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker cp.
# @example
#   docker::container::push web ./nginx.conf /etc/nginx/nginx.conf
docker::container::push() {
  [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64
  util::_run-command docker cp "$2" "$1:${3:-.}"
}

# @description Run an interactive shell or a command in a container.
#
# Without COMMAND, Bash is used when the container has it and sh otherwise.
#
# @arg $1 string Container name or ID.
# @arg $@ string Optional command and its arguments.
# @exitcode 0 The shell or command exited successfully.
# @exitcode 64 No container was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker exec.
# @example
#   docker::container::shell web
#   docker::container::shell web nginx -t
docker::container::shell() {
  [[ "$#" -ge 1 && -n "$1" ]] || return 64
  local container="$1"
  shift
  if [[ "$#" -eq 0 ]]; then
    util::_run-command docker exec -it "${container}" sh -c 'if command -v bash >/dev/null 2>&1; then exec bash; fi; exec sh'
  else
    util::_run-command docker exec -it "${container}" "$@"
  fi
}

# @description Follow the log of a container.
#
# @arg $1 string Container name or ID.
# @stdout The container log, followed until interrupted.
# @exitcode 0 docker logs ended successfully.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker logs.
# @example
#   docker::container::logs web
docker::container::logs() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  util::_run-command docker logs --follow "$1"
}

# @description Stop a container.
#
# @arg $1 string Container name or ID.
# @exitcode 0 The container stopped.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker stop.
# @example
#   docker::container::stop web
docker::container::stop() { [[ "$#" -eq 1 ]] || return 64; util::_run-command docker stop "$1"; }

# @description Start a container.
#
# @arg $1 string Container name or ID.
# @exitcode 0 The container started.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker start.
# @example
#   docker::container::start web
docker::container::start() { [[ "$#" -eq 1 ]] || return 64; util::_run-command docker start "$1"; }

# @description Stop every running container; having none is a success.
#
# @noargs
# @exitcode 0 No container is running.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::container::stop-all
docker::container::stop-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require docker || return "$?"
  local identifier='' identifiers=''
  identifiers="$(docker ps -q)" || return "$?"
  while IFS= read -r identifier; do
    [[ -n "${identifier}" ]] || continue
    docker stop "${identifier}" >/dev/null || return "$?"
  done <<<"${identifiers}"
}

# @description Remove every container, running or not.
#
# @noargs
# @exitcode 0 No container remains.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::container::remove-all
docker::container::remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require docker || return "$?"
  local identifier='' identifiers=''
  identifiers="$(docker ps -aq)" || return "$?"
  while IFS= read -r identifier; do
    [[ -n "${identifier}" ]] || continue
    docker rm --force "${identifier}" >/dev/null || return "$?"
  done <<<"${identifiers}"
}

# @description Remove every Docker volume.
#
# @noargs
# @exitcode 0 No volume remains.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::volume::remove-all
docker::volume::remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require docker || return "$?"
  local volume='' volumes=''
  volumes="$(docker volume ls -q)" || return "$?"
  while IFS= read -r volume; do
    [[ -n "${volume}" ]] || continue
    docker volume rm --force "${volume}" >/dev/null || return "$?"
  done <<<"${volumes}"
}

# @description Remove every container and then every volume, stopping at the first failure.
#
# @noargs
# @exitcode 0 No container or volume remains.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::remove-all
docker::remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  docker::container::remove-all || return "$?"
  docker::volume::remove-all
}

# @description Run an ADB command with an optional serial number.
# @internal
adb::_run() {
  [[ "$#" -ge 1 ]] || return 64
  local serial='' seen_serial=0
  local args=()
  while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == '--serial' ]]; then
      [[ "$#" -ge 2 && -n "$2" && "$seen_serial" -eq 0 ]] || return 64
      serial="$2"
      seen_serial=1
      shift 2
    else
      args+=("$1")
      shift
    fi
  done
  [[ "$seen_serial" -eq 0 ]] || args=(-s "$serial" "${args[@]}")
  util::_run-command adb "${args[@]}"
}

# @description List --serial and, after it, the serials of the connected devices for Tab completion.
# @internal
adb::_complete-serial() {
  case "${1-}" in
    --serial) adb::device::list 2>/dev/null || true ;;
    '') printf '%s\n' --serial ;;
  esac
}

# @description List the named arguments and value candidates of adb::device::wait.
# @internal
adb::device::_wait-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::pull.
# @internal
adb::device::_pull-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::push.
# @internal
adb::device::_push-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::logcat::clear.
# @internal
adb::logcat::_clear-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::logcat::once.
# @internal
adb::logcat::_once-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::logcat::continuous.
# @internal
adb::logcat::_continuous-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::reboot.
# @internal
adb::device::_reboot-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::wait-for-path.
# @internal
adb::device::_wait-for-path-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::screen::capture-once.
# @internal
adb::device::screen::_capture-once-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::bootloader::enter.
# @internal
adb::device::bootloader::_enter-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::bootloader::unlock.
# @internal
adb::device::bootloader::_unlock-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::verity::disable.
# @internal
adb::device::verity::_disable-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::partition::remount.
# @internal
adb::device::partition::_remount-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::build::fingerprint.
# @internal
adb::device::build::_fingerprint-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::build::date.
# @internal
adb::device::build::_date-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::slot::suffix.
# @internal
adb::device::slot::_suffix-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::build::kernel-version.
# @internal
adb::device::build::_kernel-version-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::screen::capture-continuous.
# @internal
adb::device::screen::_capture-continuous-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::partition::sha256.
# @internal
adb::device::partition::_sha256-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::wake::lock.
# @internal
adb::wake::_lock-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::wake::unlock.
# @internal
adb::wake::_unlock-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::wake::list.
# @internal
adb::wake::_list-args() { adb::_complete-serial "$@"; }

# @description List the named arguments and value candidates of adb::device::select-and-pull.
# @internal
adb::device::_select-and-pull-args() {
  case "${1-}" in
    --serial) adb::device::list 2>/dev/null || true ;;
    '') printf '%s\n' --output-directory --serial ;;
  esac
}

# @description Wait for an ADB device to connect, optionally selected with --serial.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The device is connected.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb wait-for-device.
# @example
#   adb::device::wait --serial emulator-5554
adb::device::wait() { adb::_run wait-for-device "$@"; }

# @description Copy files from an ADB device to the host.
#
# @arg $@ string Device paths followed by an optional host destination.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The files were copied.
# @exitcode 64 No path was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb pull.
# @example
#   adb::device::pull /sdcard/DCIM/Camera ./camera --serial emulator-5554
adb::device::pull() { [[ "$#" -ge 1 ]] || return 64; adb::_run pull "$@"; }

# @description Copy files from the host to an ADB device.
#
# @arg $@ string Host paths followed by the device destination.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The files were copied.
# @exitcode 64 No path was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb push.
# @example
#   adb::device::push app-debug.apk /data/local/tmp/
adb::device::push() { [[ "$#" -ge 1 ]] || return 64; adb::_run push "$@"; }

# @description Clear the selected device log buffers.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The log buffers were cleared.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb logcat.
# @example
#   adb::logcat::clear --serial emulator-5554
adb::logcat::clear() { adb::_run logcat -c "$@"; }

# @description Write the selected device log buffers once.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The current log buffers.
# @exitcode 0 The log was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb logcat.
# @example
#   adb::logcat::once > device.log
adb::logcat::once() { adb::_run logcat -d "$@"; }

# @description Stream logs from the selected device.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The device log, streamed until interrupted.
# @exitcode 0 adb logcat ended successfully.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb logcat.
# @example
#   adb::logcat::continuous | grep -i crash
adb::logcat::continuous() { adb::_run logcat "$@"; }

# @description Reboot the selected device.
#
# The function returns after the device has disconnected and connected again.
#
# @arg $1 integer Optional seconds to wait for the device to come back. Defaults to 60.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The device rebooted and reconnected.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb is unavailable.
# @exitcode 74 The clock or sleep failed.
# @exitcode 75 The device did not reconnect in time.
# @exitcode other The status of adb reboot.
# @example
#   adb::device::reboot 120 --serial emulator-5554
adb::device::reboot() {
  [[ "$#" -le 3 ]] || return 64
  local timeout=60 serial='' start='' state='' disconnected=0
  local serial_args=()
  if [[ "$#" -ge 1 && "$1" != '--serial' ]]; then timeout="$1"; shift; fi
  [[ "$timeout" =~ ^[1-9][0-9]*$ ]] || return 64
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial="$2"
    serial_args=(--serial "$serial")
  fi
  adb::_run reboot "${serial_args[@]}" || return "$?"
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    state="$(adb::_run get-state "${serial_args[@]}" 2>/dev/null)" || state=''
    if [[ "$state" == device ]]; then
      [[ "$disconnected" -eq 0 ]] || return 0
    else
      disconnected=1
    fi
    sleep 1 || return 74
  done
  return 75
}

# @description Write the first connected ADB device serial.
#
# @noargs
# @stdout The serial of the first connected device.
# @exitcode 0 The serial was written.
# @exitcode 1 No device is connected.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb devices.
# @example
#   serial="$(adb::device::first)"
adb::device::first() {
  [[ "$#" -eq 0 ]] || return 64
  local devices=''
  devices="$(adb::device::list)" || return "$?"
  [[ -n "$devices" ]] || return 1
  printf '%s\n' "${devices%%$'\n'*}"
}

# @description List connected ADB device serials.
#
# @noargs
# @stdout One serial per line for devices in the device state.
# @exitcode 0 The serials were written; there may be none.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb devices.
# @example
#   adb::device::list
adb::device::list() {
  [[ "$#" -eq 0 ]] || return 64
  local devices=''
  devices="$(adb::_run devices)" || return "$?"
  printf '%s\n' "$devices" | awk 'NR>1 && $2=="device" {print $1}'
}

# @description Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout.
#
# @arg $1 string Path on the device.
# @arg $2 integer Optional seconds to wait. Defaults to 30.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The path exists.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The clock or sleep failed.
# @exitcode 75 The path did not appear in time.
# @example
#   adb::device::wait-for-path /sdcard/Download/report.json 60
adb::device::wait-for-path() {
  [[ "$#" -ge 1 && "$#" -le 4 && -n "$1" ]] || return 64
  local path="$1" timeout=30 start='' quoted=''
  local serial_args=()
  shift
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then timeout="$1"; shift; fi
  [[ "$timeout" =~ ^[1-9][0-9]*$ ]] || return 64
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial_args=(--serial "$2")
  fi
  [[ "$path" != *$'\n'* && "$path" != *$'\r'* ]] || return 64
  printf -v quoted '%q' "$path"
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    adb::_run shell "test -e $quoted" "${serial_args[@]}" >/dev/null 2>&1 && return 0
    sleep 1 || return 74
  done
  return 75
}

# @description Save one screenshot atomically and print its path.
#
# @arg $1 string Optional output PNG file. Defaults to ${WORK_DIR:-.}/STAMP/STAMP-adb-image.png.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The path of the saved screenshot.
# @exitcode 0 The screenshot was saved.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The file could not be written.
# @exitcode 75 The device returned no image.
# @example
#   adb::device::screen::capture-once ./screen.png --serial emulator-5554
adb::device::screen::capture-once() {
  [[ "$#" -le 3 ]] || return 64
  local output='' stamp='' directory='' temporary=''
  local serial_args=()
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then output="$1"; shift; fi
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial_args=(--serial "$2")
  fi
  if [[ -z "$output" ]]; then
    stamp="$(date +%Y%m%dT%H%M%S)" || return 74
    output="${WORK_DIR:-.}/$stamp/$stamp-adb-image.png"
  fi
  directory="$(dirname -- "$output")" || return 74
  mkdir -p -- "$directory" || return 74
  temporary="$(mktemp "$directory/.bashstock-image.XXXXXX")" || return 74
  if ! adb::_run exec-out screencap -p "${serial_args[@]}" >"$temporary" || [[ ! -s "$temporary" ]]; then
    rm -f -- "$temporary"
    return 75
  fi
  mv -f -- "$temporary" "$output" || { rm -f -- "$temporary"; return 74; }
  printf '%s\n' "$output"
}

# @description Select one requested device path and pull it to the host.
#
# @arg $@ string Device paths to choose from.
# @option --output-directory <DIRECTORY> Host directory to copy to. Defaults to the current directory.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The selected path was copied.
# @exitcode 64 No path was given or an option has no value.
# @exitcode 74 The output directory could not be created.
# @exitcode other The status of the prompt or of adb pull.
# @example
#   adb::device::select-and-pull /sdcard/Download /sdcard/DCIM --output-directory ./device
adb::device::select-and-pull() {
  [[ "$#" -ge 1 ]] || return 64
  local output='.' serial='' selected=''
  local paths=() serial_args=()
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --output-directory) [[ "$#" -ge 2 && -n "$2" ]] || return 64; output="$2"; shift 2 ;;
      --serial) [[ "$#" -ge 2 && -n "$2" && -z "$serial" ]] || return 64; serial="$2"; shift 2 ;;
      --) shift; paths+=("$@"); break ;;
      *) paths+=("$1"); shift ;;
    esac
  done
  [[ "${#paths[@]}" -gt 0 ]] || return 64
  [[ -z "$serial" ]] || serial_args=(--serial "$serial")
  selected="$(prompt::select-one 'Select a device path' "${paths[@]}")" || return "$?"
  mkdir -p -- "$output" || return 74
  adb::_run pull "$selected" "$output" "${serial_args[@]}"
}

# @description Reboot the selected device into its bootloader.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The device is rebooting into its bootloader.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb reboot.
# @example
#   adb::device::bootloader::enter --serial 0123456789ABCDEF
# shellcheck disable=SC2329
adb::device::bootloader::enter() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::_run reboot bootloader "$@"
}

# @description Request bootloader unlocking and wait for the device to reconnect.
#
# The unlock must be confirmed on the device. Unlocking erases user data.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The bootloader was unlocked and ADB reconnected.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 fastboot or adb is unavailable.
# @exitcode 74 The clock or sleep failed.
# @exitcode 75 The device did not reach fastboot or ADB in time.
# @exitcode other The status of the adb or fastboot command that failed.
# @example
#   adb::device::bootloader::unlock --serial 0123456789ABCDEF
adb::device::bootloader::unlock() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  command -v fastboot >/dev/null 2>&1 || return 69
  local start='' ready=0
  local fastboot_args=()
  [[ "$#" -eq 0 ]] || fastboot_args=(-s "$2")
  adb::device::bootloader::enter "$@" || return "$?"
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < 30 )); do
    if fastboot "${fastboot_args[@]}" getvar version >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 0.25 || return 74
  done
  [[ "$ready" -eq 1 ]] || return 75
  fastboot "${fastboot_args[@]}" flashing unlock || return "$?"
  adb::_wait-device 60 "$@"
}

# @description Wait for the selected device to return to the connected state.
# @internal
adb::_wait-device() {
  [[ "$#" -eq 1 || ( "$#" -eq 3 && "$2" == '--serial' && -n "$3" ) ]] || return 64
  local timeout="$1" start='' state=''
  [[ "$timeout" =~ ^[1-9][0-9]*$ ]] || return 64
  shift
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    state="$(adb::_run get-state "$@" 2>/dev/null)" || state=''
    [[ "$state" != device ]] || return 0
    sleep 1 || return 74
  done
  return 75
}

# @description Disable dm-verity on a rooted device, reboot it, and wait until ADB reconnects.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 dm-verity is disabled and ADB reconnected.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 sleep failed.
# @exitcode 75 The device did not reconnect in time.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::device::verity::disable && adb::device::partition::remount
adb::device::verity::disable() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::_run root "$@" || return "$?"
  adb::_wait-device 60 "$@" || return "$?"
  adb::_run disable-verity "$@" || return "$?"
  adb::_run reboot "$@" || return "$?"
  sleep 5 || return 74
  adb::_wait-device 180 "$@"
}

# @description Make the system partitions of a rooted device writable.
#
# adb root and adb remount run first, and the root file system is then
# remounted read-write.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The partitions are writable.
# @exitcode 64 The arguments are invalid.
# @exitcode 75 The device did not reconnect in time.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::device::partition::remount --serial emulator-5554
adb::device::partition::remount() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::_run root "$@" || return "$?"
  adb::_wait-device 60 "$@" || return "$?"
  adb::_run remount "$@" || return "$?"
  adb::_run shell 'mount -o rw,remount /' "$@"
}

# @description Write the selected device build fingerprint.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The value of ro.build.fingerprint.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::build::fingerprint
adb::device::build::fingerprint() { adb::_run shell getprop ro.build.fingerprint "$@"; }

# @description Write the selected device build timestamp as Unix seconds.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The value of ro.build.date.utc.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   date -d "@$(adb::device::build::date)"
adb::device::build::date() { adb::_run shell getprop ro.build.date.utc "$@"; }

# @description Write the selected device active slot suffix.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The value of ro.boot.slot_suffix, such as _a; empty on devices without slots.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::slot::suffix
adb::device::slot::suffix() { adb::_run shell getprop ro.boot.slot_suffix "$@"; }

# @description Write the selected device kernel release.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The output of uname -r on the device.
# @exitcode 0 The value was written.
# @exitcode 64 --serial is repeated or has no value.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::build::kernel-version
adb::device::build::kernel-version() { adb::_run shell uname -r "$@"; }

# @description Save repeated screenshots; MAX_COUNT of zero runs until interrupted.
#
# @arg $1 string Optional output directory. Defaults to ./screencap-loop.
# @arg $2 number Optional seconds between screenshots. Defaults to 1.
# @arg $3 integer Optional number of screenshots; 0 runs until interrupted. Defaults to 0.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The path of each saved screenshot.
# @exitcode 0 The requested screenshots were saved.
# @exitcode 64 The arguments are invalid.
# @exitcode 74 The directory could not be created or sleep failed.
# @exitcode other The status of adb::device::screen::capture-once.
# @example
#   adb::device::screen::capture-continuous ./frames 0.5 20
adb::device::screen::capture-continuous() {
  [[ "$#" -le 5 ]] || return 64
  local directory='./screencap-loop' interval=1 max=0 index=0
  local serial_args=()
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then directory="$1"; shift; fi
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then interval="$1"; shift; fi
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then max="$1"; shift; fi
  [[ "$interval" =~ ^[0-9]+([.][0-9]+)?$ && "$interval" =~ [1-9] ]] || return 64
  [[ "$max" =~ ^[0-9]+$ ]] || return 64
  if [[ "$#" -gt 0 ]]; then
    [[ "$#" -eq 2 && "$1" == '--serial' && -n "$2" ]] || return 64
    serial_args=(--serial "$2")
  fi
  mkdir -p -- "$directory" || return 74
  while [[ "$max" -eq 0 || "$index" -lt "$max" ]]; do
    adb::device::screen::capture-once "$directory/screen-${index}.png" "${serial_args[@]}" || return "$?"
    index=$((index+1))
    [[ "$max" -ne 0 && "$index" -ge "$max" ]] && break
    sleep "$interval" || return 74
  done
}

# @description Write a device partition SHA-256 checksum.
#
# @arg $1 string Partition path below /dev/block.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The output of sha256sum on the device.
# @exitcode 0 The checksum was written.
# @exitcode 64 The path or options are invalid.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb shell.
# @example
#   adb::device::partition::sha256 /dev/block/by-name/boot_a
adb::device::partition::sha256() {
  [[ "$#" -eq 1 || "$#" -eq 3 ]] || return 64
  local path="$1"
  [[ "$path" =~ ^/dev/block/[A-Za-z0-9._/-]+$ && "$path" != *'..'* ]] || return 64
  shift
  if [[ "$#" -gt 0 ]]; then
    [[ "$1" == '--serial' && -n "$2" ]] || return 64
  fi
  adb::_run shell sha256sum "$path" "$@"
}

# @description Require a rooted ADB device for sysfs wake lock operations.
# @internal
adb::wake::_require-root() {
  adb::_run root "$@" || return "$?"
  adb::_wait-device 30 "$@" || return "$?"
  local user_id=''
  user_id="$(adb::_run shell id -u "$@")" || return "$?"
  [[ "$user_id" == 0 ]] || return 69
}

# @description Hold a kernel wake lock using a tag, defaulting to debug.
#
# The device must allow adb root.
#
# @arg $1 string Optional wake lock tag. Defaults to debug.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The wake lock is held.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb root is unavailable or /sys/power/wake_lock is not writable.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::wake::lock benchmark
adb::wake::lock() {
  [[ "$#" -le 3 ]] || return 64
  local tag=debug
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then tag="$1"; shift; fi
  [[ "$tag" =~ ^[A-Za-z0-9_.-]+$ ]] || return 64
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::wake::_require-root "$@" || return "$?"
  adb::_run shell "test -w /sys/power/wake_lock" "$@" || return 69
  adb::_run shell "printf '%s' '$tag' > /sys/power/wake_lock" "$@"
}

# @description Release a kernel wake lock using the same tag.
#
# The device must allow adb root.
#
# @arg $1 string Optional wake lock tag. Defaults to debug.
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @exitcode 0 The wake lock was released.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb root is unavailable or /sys/power/wake_unlock is not writable.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::wake::unlock benchmark
adb::wake::unlock() {
  [[ "$#" -le 3 ]] || return 64
  local tag=debug
  if [[ "$#" -gt 0 && "$1" != '--serial' ]]; then tag="$1"; shift; fi
  [[ "$tag" =~ ^[A-Za-z0-9_.-]+$ ]] || return 64
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::wake::_require-root "$@" || return "$?"
  adb::_run shell "test -w /sys/power/wake_unlock" "$@" || return 69
  adb::_run shell "printf '%s' '$tag' > /sys/power/wake_unlock" "$@"
}

# @description Print active kernel wake locks.
#
# @option --serial <SERIAL> Device serial. ADB chooses the device when omitted.
# @stdout The active wake lock tags.
# @exitcode 0 The tags were written.
# @exitcode 64 The arguments are invalid.
# @exitcode 69 adb root is unavailable or /sys/power/wake_lock is not readable.
# @exitcode other The status of the adb command that failed.
# @example
#   adb::wake::list
adb::wake::list() {
  [[ "$#" -eq 0 || ( "$#" -eq 2 && "$1" == '--serial' && -n "$2" ) ]] || return 64
  adb::wake::_require-root "$@" || return "$?"
  adb::_run shell "test -r /sys/power/wake_lock" "$@" || return 69
  adb::_run shell "cat /sys/power/wake_lock" "$@"
}

# @description Write the IDs of the processes whose executable name is exactly NAME, one per line.
#
# @arg $1 string Executable name.
# @stdout One process ID per line.
# @exitcode 0 At least one process matches.
# @exitcode 1 No process matches.
# @exitcode 64 The argument count is not one.
# @exitcode 69 pgrep is unavailable.
# @example
#   process::ids-by-name sshd
process::ids-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; util::_run-command pgrep -x "$1"; }

# @description Write the IDs of the processes whose command line matches an ERE evaluated by pgrep -f.
#
# @arg $1 string Extended regular expression matched against the full command line.
# @stdout One process ID per line.
# @exitcode 0 At least one process matches.
# @exitcode 1 No process matches.
# @exitcode 64 The argument count is not one.
# @exitcode 69 pgrep is unavailable.
# @example
#   process::ids-by-name-regex 'python3 .*manage\.py runserver'
process::ids-by-name-regex() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; util::_run-command pgrep -f "$1"; }

# @description Write the threads of one process.
#
# Linux uses ps -T and macOS ps -M.
#
# @arg $1 integer Process ID.
# @stdout The ps listing of the threads.
# @exitcode 0 The threads were written.
# @exitcode 1 No process has the ID.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 ps is unavailable or the operating system is unsupported.
# @example
#   process::threads-by-pid "$$"
process::threads-by-pid() {
  [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64
  command::require ps || return "$?"
  case "$(system::operating-system)" in
    darwin) ps -M -p "$1" ;;
    linux) ps -T -p "$1" ;;
    *) return 69 ;;
  esac
}

# @description Write the first process ID whose executable name is NAME.
# @internal
process::_first-id-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local process_ids=''
  process_ids="$(process::ids-by-name "$1")" || return 1
  [[ -n "${process_ids}" ]] || return 1
  printf '%s\n' "${process_ids%%$'\n'*}"
}

# @description Write the threads of the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stdout The ps listing of the threads.
# @exitcode 0 The threads were written.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of process::threads-by-pid.
# @example
#   process::threads-by-name java
process::threads-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  process::threads-by-pid "${id}"
}

# @description Test whether tracing a process needs administrator execution.
#
# Tracing needs it when another user owns the process, or when Yama allows
# tracing only of descendants.
# @internal
process::_trace-needs-root() {
  [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64
  local owner='' scope=0
  [[ "${EUID}" -eq 0 ]] && return 1
  owner="$(ps -o uid= -p "$1" 2>/dev/null | tr -d ' ')"
  [[ -n "${owner}" && "${owner}" != "${EUID}" ]] && return 0
  [[ -r /proc/sys/kernel/yama/ptrace_scope ]] && scope="$(</proc/sys/kernel/yama/ptrace_scope)"
  [[ "${scope}" != 0 ]]
}

# @description Attach strace to a process on Linux.
#
# Administrator execution is used only when the process cannot be traced
# with the current permissions.
#
# @arg $1 integer Process ID.
# @stderr The system calls that strace reports.
# @exitcode 0 strace ended successfully.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 The system is not Linux or strace is unavailable.
# @exitcode other The status of strace.
# @example
#   syscall::trace-by-pid "$(pgrep -x nginx | head -n 1)"
syscall::trace-by-pid() {
  [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require strace || return "$?"
  if process::_trace-needs-root "$1"; then
    command::run-as-root strace -p "$1"
  else
    strace -p "$1"
  fi
}

# @description Attach ltrace to a process on Linux.
#
# Administrator execution is used only when the process cannot be traced
# with the current permissions.
#
# @arg $1 integer Process ID.
# @stderr The library calls that ltrace reports.
# @exitcode 0 ltrace ended successfully.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 The system is not Linux or ltrace is unavailable.
# @exitcode other The status of ltrace.
# @example
#   lib::trace-by-pid 4242
lib::trace-by-pid() {
  [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require ltrace || return "$?"
  if process::_trace-needs-root "$1"; then
    command::run-as-root ltrace -p "$1"
  else
    ltrace -p "$1"
  fi
}

# @description Attach GDB in batch mode to a process and write the backtrace of every thread.
#
# @arg $1 integer Process ID.
# @stdout The backtrace of every thread.
# @exitcode 0 The backtrace was written.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::attach-pid 4242 > backtrace.txt
gdb::attach-pid() {
  [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64
  command::require gdb || return "$?"
  gdb -q -batch -p "$1" -ex 'thread apply all bt'
}

# @description Start COMMAND with its arguments under gdbserver listening on PORT.
#
# @arg $1 integer TCP port to listen on.
# @arg $2 string Command to run.
# @arg $@ string Optional arguments of the command.
# @exitcode 0 gdbserver ended successfully.
# @exitcode 64 The port or command is invalid.
# @exitcode 69 gdbserver is unavailable.
# @exitcode other The status of gdbserver.
# @example
#   gdb::server::start 2345 ./build/app --verbose
gdb::server::start() { [[ "$#" -ge 2 && "$1" =~ ^[0-9]+$ && -n "$2" ]] || return 64; util::_run-command gdbserver ":$1" "${@:2}"; }

# @description Load ELF in GDB and connect to the GDB server at HOST and PORT.
#
# @arg $1 string ELF file with symbols.
# @arg $2 string Host of the GDB server.
# @arg $3 integer Port of the GDB server.
# @exitcode 0 GDB ended successfully.
# @exitcode 64 The arguments are invalid or the ELF file does not exist.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::connect ./build/app 192.168.1.50 2345
gdb::connect() { [[ "$#" -eq 3 && -f "$1" && "$3" =~ ^[0-9]+$ ]] || return 64; util::_run-command gdb "$1" -ex "target remote $2:$3"; }

# @description Run ELF in GDB with optional program arguments and stop at SYMBOL.
#
# @arg $1 string ELF file to run.
# @arg $2 string Symbol or location to break at.
# @arg $@ string Optional program arguments.
# @exitcode 0 GDB ended successfully.
# @exitcode 64 The ELF file does not exist or no symbol was given.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::run-until ./build/app parse_config --config test.ini
gdb::run-until() { [[ "$#" -ge 2 && -f "$1" && -n "$2" ]] || return 64; util::_run-command gdb -ex "break $2" -ex run --args "$1" "${@:3}"; }

# @description Open ELF and a core dump in GDB.
#
# @arg $1 string ELF file that produced the core dump.
# @arg $2 string Core dump file.
# @exitcode 0 GDB ended successfully.
# @exitcode 64 The argument count is not two or a file does not exist.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::core::open ./build/app core.4242
gdb::core::open() { [[ "$#" -eq 2 && -f "$1" && -f "$2" ]] || return 64; util::_run-command gdb "$1" "$2"; }

# @description Write the node paths of the Linux device tree.
#
# @noargs
# @stdout One node path per line below /sys/firmware/devicetree/base.
# @exitcode 0 The nodes were written.
# @exitcode 64 An argument was given.
# @exitcode 66 The system has no device tree.
# @example
#   device-tree::node::list | grep -i i2c
device-tree::node::list() { [[ "$#" -eq 0 ]] || return 64; [[ -d /sys/firmware/devicetree/base ]] || return 66; find /sys/firmware/devicetree/base -mindepth 1 -print; }

# @description Write the I2C buses with i2cdetect -l.
#
# @noargs
# @stdout The output of i2cdetect -l.
# @exitcode 0 The buses were written.
# @exitcode 64 An argument was given.
# @exitcode 69 i2cdetect is unavailable.
# @exitcode other The status of i2cdetect.
# @example
#   i2c::bus::list
i2c::bus::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command i2cdetect -l; }

# @description Write the devices on one I2C bus with i2cdetect -y.
#
# @arg $1 integer I2C bus number.
# @stdout The address map that i2cdetect writes.
# @exitcode 0 The devices were written.
# @exitcode 64 The argument is not one bus number.
# @exitcode 69 i2cdetect is unavailable.
# @exitcode other The status of i2cdetect.
# @example
#   i2c::device::list 1
i2c::device::list() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; util::_run-command i2cdetect -y "$1"; }

# @description Write the GPIO chips with gpiodetect.
#
# @noargs
# @stdout The output of gpiodetect.
# @exitcode 0 The chips were written.
# @exitcode 64 An argument was given.
# @exitcode 69 gpiodetect is unavailable.
# @exitcode other The status of gpiodetect.
# @example
#   gpio::chip::list
gpio::chip::list() {
  [[ "$#" -eq 0 ]] || return 64
  util::_run-command gpiodetect
}

# @description Write the GPIO lines of one chip, or of every chip, with gpioinfo.
#
# @arg $1 string Optional chip name or number. Defaults to every chip.
# @stdout The output of gpioinfo.
# @exitcode 0 The lines were written.
# @exitcode 64 More than one argument was given.
# @exitcode 69 gpioinfo is unavailable.
# @exitcode other The status of gpioinfo.
# @example
#   gpio::line::list gpiochip0
gpio::line::list() {
  [[ "$#" -le 1 ]] || return 64
  local arguments=()
  [[ -z "${1:-}" ]] || arguments+=("$1")
  util::_run-command gpioinfo "${arguments[@]}"
}

# @description Write the USB devices with lsusb.
#
# @noargs
# @stdout The output of lsusb.
# @exitcode 0 The devices were written.
# @exitcode 64 An argument was given.
# @exitcode 69 lsusb is unavailable.
# @exitcode other The status of lsusb.
# @example
#   usb::device::list
usb::device::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command lsusb; }

# @description Write the PCI devices with lspci.
#
# @noargs
# @stdout The output of lspci.
# @exitcode 0 The devices were written.
# @exitcode 64 An argument was given.
# @exitcode 69 lspci is unavailable.
# @exitcode other The status of lspci.
# @example
#   pci::device::list
pci::device::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command lspci; }

# @description Convert AsciiDoc to HTML with diagram support.
#
# @arg $1 string AsciiDoc file.
# @arg $2 string Optional directory for the HTML. Defaults to the current directory.
# @exitcode 0 The HTML was written.
# @exitcode 64 The arguments are invalid or the file does not exist.
# @exitcode 69 asciidoctor is unavailable.
# @exitcode other The status of asciidoctor.
# @example
#   asciidoc::html docs/design.adoc build/html
asciidoc::html() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  util::_run-command asciidoctor -r asciidoctor-diagram -b html5 -D "${2:-.}" "$1"
}

# @description Run a Flutter project in Chrome in release mode.
#
# @arg $1 string Optional Flutter project directory. Defaults to the current directory.
# @exitcode 0 The application ended successfully.
# @exitcode 64 More than one argument was given.
# @exitcode 69 flutter is unavailable.
# @exitcode other The status of flutter run or cd.
# @example
#   flutter::run-chrome-release apps/mobile
flutter::run-chrome-release() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && util::_run-command flutter run --release -d chrome); }

# @description Run a Flutter project as a Linux desktop application in release mode.
#
# @arg $1 string Optional Flutter project directory. Defaults to the current directory.
# @exitcode 0 The application ended successfully.
# @exitcode 64 More than one argument was given.
# @exitcode 69 flutter is unavailable.
# @exitcode other The status of flutter run or cd.
# @example
#   flutter::run-linux-release apps/desktop
flutter::run-linux-release() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && util::_run-command flutter run --release -d linux); }

# @description Run the Flutter tests of a project with optional flutter test arguments.
#
# @arg $1 string Optional Flutter project directory, used when it is an existing directory. Defaults to the current directory.
# @arg $@ string Optional arguments of flutter test.
# @exitcode 0 The tests passed.
# @exitcode 69 flutter is unavailable.
# @exitcode other The status of flutter test or cd.
# @example
#   flutter::test apps/mobile --name 'login'
flutter::test() { [[ "$#" -ge 0 ]] || return 64; local directory='.'; [[ "$#" -gt 0 && -d "$1" ]] && { directory="$1"; shift; }; (cd "$directory" && util::_run-command flutter test "$@"); }

# @description Run the Flutter tests with coverage and write the LCOV HTML report.
#
# @arg $1 string Optional report directory. Defaults to coverage/html below the project directory.
# @arg $2 string Optional Flutter project directory. Defaults to the current directory.
# @exitcode 0 The tests passed and the report was written.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 flutter or genhtml is unavailable.
# @exitcode other The status of flutter test or genhtml.
# @example
#   flutter::coverage '' apps/mobile
flutter::coverage() {
  [[ "$#" -le 2 ]] || return 64
  local directory="${2:-.}" output="${1:-}"
  command::require flutter || return "$?"
  command::require genhtml || return "$?"
  [[ -n "${output}" ]] || output="${directory%/}/coverage/html"
  (cd -- "${directory}" && flutter test --coverage) || return "$?"
  genhtml "${directory%/}/coverage/lcov.info" -o "${output}"
}

# @description Write the path of the file that defines a systemd unit.
#
# @arg $1 string Unit name, such as ssh.service.
# @stdout The path of the unit file; empty for a unit without a file.
# @exitcode 0 The path was written.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::file ssh.service
systemd::file() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  systemctl show --property=FragmentPath --value -- "$1"
}

# @description Require Linux with systemctl and a valid unit name.
# @internal
systemd::_require-unit() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9@._:\\-]+$ ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require systemctl
}

# @description Write the After, Requires, and Wants dependencies of a systemd unit as KEY=VALUE lines.
#
# @arg $1 string Unit name.
# @stdout After=, Requires=, and Wants= lines.
# @exitcode 0 The dependencies were written.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::dependencies docker.service
systemd::dependencies() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  systemctl show --property=After --property=Requires --property=Wants -- "$1"
}

# @description Restart a systemd unit through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was restarted.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::restart nginx.service
systemd::restart() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl restart -- "$1"
}

# @description Start a systemd unit through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was started.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::start docker.service
systemd::start() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl start -- "$1"
}

# @description Stop a systemd unit through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was stopped.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::stop docker.service
systemd::stop() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl stop -- "$1"
}

# @description Enable a systemd unit at boot through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was enabled.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::enable ssh.service
systemd::enable() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl enable -- "$1"
}

# @description Disable a systemd unit at boot through administrator execution.
#
# @arg $1 string Unit name.
# @exitcode 0 The unit was disabled.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::disable cups.service
systemd::disable() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  command::run-as-root systemctl disable -- "$1"
}

# @description Write the current state of a systemd unit and return the status of systemctl status.
#
# @arg $1 string Unit name.
# @stdout The output of systemctl status.
# @exitcode 0 The unit is active.
# @exitcode 64 The argument is not one valid unit name.
# @exitcode 69 The system is not Linux or systemctl is unavailable.
# @exitcode other The status of systemctl status, such as 3 for an inactive unit.
# @example
#   systemd::status ssh.service
systemd::status() {
  [[ "$#" -eq 1 ]] || return 64
  systemd::_require-unit "$1" || return "$?"
  systemctl status --no-pager -- "$1"
}

# @description Write every loaded systemd service, including stopped ones.
#
# @noargs
# @stdout The output of systemctl list-units --type=service.
# @exitcode 0 The services were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list
systemd::service::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-units --type=service; }

# @description Write the running systemd services.
#
# @noargs
# @stdout The running services.
# @exitcode 0 The services were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list-running
systemd::service::list-running() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-units --type=service --state=running; }

# @description Write the failed systemd services.
#
# @noargs
# @stdout The failed services.
# @exitcode 0 The services were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list-failed
systemd::service::list-failed() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-units --type=service --state=failed; }

# @description Write every systemd service unit file and its enablement state.
#
# @noargs
# @stdout The service unit files and their states.
# @exitcode 0 The files were written.
# @exitcode 64 An argument was given.
# @exitcode 69 systemctl is unavailable.
# @exitcode other The status of systemctl.
# @example
#   systemd::service::list-files | grep enabled
systemd::service::list-files() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-unit-files --type=service; }

# @description Decrypt a GPG file to standard output without adding a newline.
#
# @arg $1 string Encrypted file.
# @stdout The decrypted content.
# @exitcode 0 The file was decrypted.
# @exitcode 64 The argument is not one existing file.
# @exitcode 69 gpg is unavailable.
# @exitcode other The status of gpg.
# @example
#   gpg::decrypt secrets.env.gpg > .env
gpg::decrypt() { [[ "$#" -eq 1 && -f "$1" ]] || return 64; util::_run-command gpg --decrypt "$1"; }

# @description Write a public GPG key in ASCII armor.
#
# @arg $1 string Optional key fingerprint. Defaults to the first secret key.
# @stdout The ASCII-armored public key.
# @exitcode 0 The key was written.
# @exitcode 1 No fingerprint was given and no secret key exists.
# @exitcode 64 More than one argument was given.
# @exitcode 69 gpg is unavailable.
# @exitcode other The status of gpg.
# @example
#   gpg::public-key::armor > public.asc
gpg::public-key::armor() {
  [[ "$#" -le 1 ]] || return 64
  local fingerprint="${1:-}" fingerprints=''
  command::require gpg || return "$?"
  if [[ -z "${fingerprint}" ]]; then
    fingerprints="$(gpg::secret-key::fingerprints)" || return "$?"
    fingerprint="${fingerprints%%$'\n'*}"
  fi
  gpg --armor --export -- "${fingerprint}"
}

# @description Write the fingerprints of every primary secret GPG key, one per line.
#
# @noargs
# @stdout One fingerprint per line.
# @exitcode 0 The fingerprints were written.
# @exitcode 1 No secret key exists.
# @exitcode 64 An argument was given.
# @exitcode 69 gpg is unavailable.
# @example
#   gpg::secret-key::fingerprints
gpg::secret-key::fingerprints() {
  [[ "$#" -eq 0 ]] || return 64
  command::require gpg || return "$?"
  local listing='' fingerprints=''
  listing="$(gpg --batch --list-secret-keys --with-colons 2>/dev/null)" || return 1
  # Each sec record is followed by the fpr record of the primary key.
  fingerprints="$(printf '%s\n' "${listing}" | awk -F: '$1 == "sec" {primary = 1; next} $1 == "fpr" && primary {print $10; primary = 0}')"
  [[ -n "${fingerprints}" ]] || return 1
  printf '%s\n' "${fingerprints}"
}

# @description Write the secret GPG keys in the human-readable GPG format.
#
# @noargs
# @stdout The output of gpg --list-secret-keys.
# @exitcode 0 The keys were written.
# @exitcode 64 An argument was given.
# @exitcode 69 gpg is unavailable.
# @exitcode other The status of gpg.
# @example
#   gpg::secret-key::list
gpg::secret-key::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command gpg --list-secret-keys; }

# @description Link the English XDG user directory names to the directories of the current locale.
#
# Each standard XDG directory is resolved with xdg-user-dir. A localized
# directory that does not exist is skipped and never created. An existing
# English directory is merged into the localized one, overwriting entries
# with the same name, and then replaced by the link.
#
# @arg $1 string Optional home directory to update. Defaults to $HOME.
# @stderr A message for each English name that is not a directory.
# @exitcode 0 Every link was created or already existed.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The home directory does not exist.
# @exitcode 69 xdg-user-dir is unavailable.
# @exitcode 73 An English name is held by something other than a directory or link.
# @exitcode 74 A directory could not be resolved, removed, or linked.
# @exitcode other The status of directory::merge.
# @example
#   user::directory::create-english-links
user::directory::create-english-links() {
  [[ "$#" -le 1 ]] || return 64
  local home="${1:-${HOME}}" pair='' key='' name='' localized='' english='' status=0
  [[ -d "${home}" ]] || return 66
  command::require xdg-user-dir || return "$?"
  for pair in DESKTOP:Desktop DOWNLOAD:Downloads TEMPLATES:Templates PUBLICSHARE:Public \
    DOCUMENTS:Documents MUSIC:Music PICTURES:Pictures VIDEOS:Videos; do
    key="${pair%%:*}"
    name="${pair#*:}"
    localized="$(HOME="${home}" XDG_CONFIG_HOME="${home}/.config" xdg-user-dir "${key}")" || return 74
    english="${home}/${name}"
    [[ -d "${localized}" && ! -L "${localized}" ]] || continue
    [[ "${localized%/}" != "${home%/}" && "${localized}" != "${english}" ]] || continue
    if [[ -L "${english}" ]]; then
      [[ "$(readlink -- "${english}")" != "${localized}" ]] || continue
      rm -f -- "${english}" || return 74
    elif [[ -d "${english}" ]]; then
      directory::merge "${english}" "${localized}" || return "$?"
    elif [[ -e "${english}" ]]; then
      console::_write-error "Not linking ${english}: it is not a directory."
      status=73
      continue
    fi
    ln -s -- "${localized}" "${english}" || return 74
  done
  return "${status}"
}

# @description Write available stable Android Build Tools versions in ascending order.
#
# Use Android CLI when available, otherwise use sdkmanager.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 1 No stable version was found.
# @exitcode 64 An argument was given.
# @exitcode 69 perl, or both android and sdkmanager, are unavailable.
# @exitcode other The status of the SDK command that failed.
# @example
#   android::build-tools::versions | tail -n 3
android::build-tools::versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local listing='' versions=''
  local arguments=(--no-metrics)
  if command -v android >/dev/null 2>&1; then
    [[ -z "${ANDROID_HOME:-}" ]] || arguments+=("--sdk=${ANDROID_HOME}")
    listing="$(android "${arguments[@]}" sdk list 'build-tools/*' --all --all-versions)" || return "$?"
  else
    command::require sdkmanager || return "$?"
    listing="$(sdkmanager --list --channel=0)" || return "$?"
  fi
  versions="$(printf '%s\n' "${listing}" | perl -ne '
    print "$1\n" if /^\s*build-tools;([0-9]+\.[0-9]+\.[0-9]+)\s*\|/
      || /^\s*build-tools\/([0-9]+\.[0-9]+\.[0-9]+)\s+[0-9]+\.[0-9]+\.[0-9]+(?=\s|$)/;
  ' | package::_sort-versions)" || return "$?"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}

# @description Write the newest available stable Android Build Tools version.
#
# @noargs
# @stdout The newest version, such as 35.0.0.
# @exitcode 0 The version was written.
# @exitcode 1 No stable version was found.
# @exitcode 64 An argument was given.
# @exitcode other The status of android::build-tools::versions.
# @example
#   sdkmanager "build-tools;$(android::build-tools::latest-version)"
android::build-tools::latest-version() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(android::build-tools::versions)" || return "$?"
  printf '%s\n' "${versions##*$'\n'}"
}

# @description Write the stable Go versions the platform package source offers, oldest first.
#
# Ubuntu lists the versioned golang-X.Y packages, Fedora the golang package,
# and macOS the Homebrew go formulae. Each value is accepted by go::install.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 1 No version was found.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform or its package tool is unsupported or unavailable.
# @exitcode other The status of the package query that failed.
# @example
#   go::version::list
go::version::list() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' versions=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      command::require apt-cache || return "$?"
      versions="$(apt-cache pkgnames golang- 2>/dev/null | sed -n 's/^golang-\([0-9][0-9]*\.[0-9][0-9]*\)$/\1/p')"
      ;;
    fedora)
      versions="$(package::_versions golang)" || return "$?"
      versions="$(printf '%s\n' "${versions}" | sed -n 's/^\([0-9][0-9]*\.[0-9][0-9.]*\)-.*$/\1/p')"
      ;;
    darwin)
      versions="$(package::_brew-formula-versions go)" || return "$?"
      ;;
  esac
  versions="$(printf '%s\n' "${versions}" | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | package::_sort-versions)"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}

# @description Write the newest stable Go version from go::version::list.
#
# @noargs
# @stdout The newest version, such as 1.23.
# @exitcode 0 The version was written.
# @exitcode 1 No version was found.
# @exitcode 64 An argument was given.
# @exitcode other The status of go::version::list.
# @example
#   go::install "$(go::version::latest)"
go::version::latest() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(go::version::list)" || return "$?"
  printf '%s\n' "${versions##*$'\n'}"
}

# @description Write stable Ruby versions that rbenv can install in ascending order.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 rbenv is unavailable.
# @exitcode 74 rbenv could not list the versions.
# @example
#   ruby::version::list | tail -n 5
ruby::version::list() {
  [[ "$#" -eq 0 ]] || return 64
  local rbenv='' versions='' version=''
  rbenv="$(ruby::_rbenv-command)" || return "$?"
  versions="$("${rbenv}" install --list-all 2>/dev/null)" || return 74
  while IFS= read -r version; do
    version="${version#"${version%%[![:space:]]*}"}"
    # if keeps a non-version last line from becoming the loop's status under pipefail.
    if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then printf '%s\n' "${version}"; fi
  done <<<"${versions}" | package::_sort-versions
}

# @description Write the newest stable Ruby version that rbenv can install.
#
# @noargs
# @stdout The newest version, such as 3.3.5.
# @exitcode 0 The version was written.
# @exitcode 1 No stable version was found.
# @exitcode 64 An argument was given.
# @example
#   ruby::version::latest
ruby::version::latest() {
  [[ "$#" -eq 0 ]] || return 64
  ruby::version::list | package::_latest-stable-version
}

# @description Install Rosetta on Apple silicon when it is missing, accepting its license.
#
# Intel Macs and Macs that already run x86_64 code succeed without changes.
#
# @noargs
# @exitcode 0 Rosetta is installed or not needed.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS or softwareupdate is unavailable.
# @exitcode other The status of softwareupdate.
# @example
#   rosetta::install
rosetta::install() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == darwin ]] || return 69
  [[ "$(uname -m)" == arm64 ]] || return 0
  if /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
    return 0
  fi
  util::_run-command softwareupdate --install-rosetta --agree-to-license
}

# @description Write the configured IPv4 and IPv6 DNS servers, one per line.
#
# Linux uses the servers of systemd-resolved when resolvectl answers, and
# otherwise the nameserver lines of /etc/resolv.conf. macOS uses scutil --dns.
#
# @noargs
# @stdout One server address per line without duplicates.
# @exitcode 0 The servers were written.
# @exitcode 64 An argument was given.
# @exitcode 66 /etc/resolv.conf cannot be read.
# @exitcode 69 The operating system is unsupported or scutil is unavailable.
# @exitcode 74 scutil failed.
# @example
#   net::dns::servers
net::dns::servers() {
  [[ "$#" -eq 0 ]] || return 64
  local servers=''
  case "$(system::operating-system)" in
    darwin)
      command::require scutil || return "$?"
      servers="$(scutil --dns | awk '$1 ~ /^nameserver\[/ {print $3}')" || return 74
      ;;
    linux)
      if command -v resolvectl >/dev/null 2>&1 && servers="$(resolvectl dns 2>/dev/null)"; then
        servers="$(printf '%s\n' "${servers}" | awk '{sub(/^[^:]*: */, ""); for (i = 1; i <= NF; i++) {sub(/#.*/, "", $i); sub(/%.*/, "", $i); if ($i != "") print $i}}')"
      else
        [[ -r /etc/resolv.conf ]] || return 66
        servers="$(awk '$1 == "nameserver" {print $2}' /etc/resolv.conf)"
      fi
      ;;
    *) return 69 ;;
  esac
  printf '%s\n' "${servers}" | awk 'NF && !seen[$0]++'
}

# @description Open the UTM application on macOS.
#
# @noargs
# @exitcode 0 UTM was opened.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of open.
# @example
#   utm::open
utm::open() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == darwin ]] || return 69
  open -a UTM
}

# @description Open the Mozc settings dialog on a Linux desktop.
#
# @noargs
# @exitcode 0 The dialog was closed.
# @exitcode 64 An argument was given.
# @exitcode 69 mozc_tool is unavailable.
# @exitcode other The status of mozc_tool.
# @example
#   mozc::config::open
mozc::config::open() {
  [[ "$#" -eq 0 ]] || return 64
  local tool=''
  for tool in /usr/lib/mozc/mozc_tool /usr/libexec/mozc/mozc_tool /usr/lib64/mozc/mozc_tool; do
    if [[ -x "${tool}" ]]; then
      "${tool}" --mode=config_dialog
      return
    fi
  done
  command::require mozc_tool || return "$?"
  mozc_tool --mode=config_dialog
}

# @description Extract one archive, or every recognized archive below a directory, next to itself.
#
# @arg $1 string Optional archive file or directory to search. Defaults to the current directory.
# @exitcode 0 Every archive was extracted.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of archive::extract-file for the first archive that failed.
# @example
#   archive::extract "${HOME}/Downloads"
archive::extract() { [[ "$#" -le 1 ]] || return 64; local path="${1:-.}" file; if [[ -f "$path" ]]; then archive::extract-file "$path"; else while IFS= read -r -d '' file; do archive::extract-file "$file" || return "$?"; done < <(archive::_find "$path"); fi; }

# @description Attach strace to the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stderr The system calls that strace reports.
# @exitcode 0 strace ended successfully.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of syscall::trace-by-pid.
# @example
#   syscall::trace-by-name nginx
syscall::trace-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  syscall::trace-by-pid "${id}"
}

# @description Attach ltrace to the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stderr The library calls that ltrace reports.
# @exitcode 0 ltrace ended successfully.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of lib::trace-by-pid.
# @example
#   lib::trace-by-name myapp
lib::trace-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  lib::trace-by-pid "${id}"
}

# @description Attach GDB to the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stdout The backtrace of every thread.
# @exitcode 0 The backtrace was written.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of gdb::attach-pid.
# @example
#   gdb::attach-by-name myapp > backtrace.txt
gdb::attach-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  gdb::attach-pid "${id}"
}

# @description Restart the Jenkins service through administrator execution.
#
# @noargs
# @exitcode 0 Jenkins was restarted.
# @exitcode 64 An argument was given.
# @exitcode other The status of systemd::restart.
# @example
#   jenkins::restart
jenkins::restart() {
  [[ "$#" -eq 0 ]] || return 64
  systemd::restart jenkins.service
}

# @description Keep the sudo credentials of the calling process fresh in the background.
#
# sudo is authenticated once, and a background process renews the
# credentials every 60 seconds until the calling process exits.
#
# @noargs
# @exitcode 0 The credentials are fresh and the renewal runs in the background.
# @exitcode 64 An argument was given.
# @exitcode 69 sudo is unavailable.
# @exitcode 77 sudo authentication failed.
# @example
#   sudo::start-keep-alive && go::install && rust::install
sudo::start-keep-alive() {
  [[ "$#" -eq 0 ]] || return 64
  command::require sudo || return "$?"
  local parent="$$"
  sudo -v || return 77
  (
    while kill -0 "${parent}" 2>/dev/null; do
      sleep 60
      sudo -n -v 2>/dev/null || exit 0
    done
  ) >/dev/null 2>&1 &
}

# @description Write the named user, or the user who invoked sudo, or the current user.
# @internal
sudo::passwordless::_user() {
  [[ "$#" -le 1 ]] || return 64
  local user="${1:-${SUDO_USER:-}}"
  if [[ -z "${user}" ]]; then
    user="$(user::name)" || return "$?"
  fi
  [[ "${user}" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]] || return 64
  printf '%s\n' "${user}"
}

# @description Write the drop-in file that holds the passwordless sudo rule of a user.
# @internal
sudo::passwordless::_file() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  # sudo skips drop-in files whose names contain a dot.
  printf '/etc/sudoers.d/zz-bashstock-passwordless-%s\n' "${1//./_}"
}

# @description Let a user run every command through sudo without entering a password.
#
# The rule `USER ALL=(ALL) NOPASSWD: ALL` is written to its own file in
# /etc/sudoers.d without opening an editor. visudo checks the rule before it
# is installed and the whole configuration afterwards. sudo applies the last
# matching rule, so the file name sorts after other drop-in files, and the
# main sudoers file of macOS, Ubuntu, and Fedora reads the directory after
# its group rules. If sudo still asks the user for a password, the file is
# removed and the function fails. Running it again rewrites the same file.
#
# @arg $1 string Optional login name. Defaults to the user who invoked sudo, or the current user.
# @stderr A message when the user does not exist or sudo does not apply the rule.
# @exitcode 0 The user can run sudo without a password.
# @exitcode 64 More than one argument was given or the user does not exist.
# @exitcode 69 sudo still asks for a password; the file was removed.
# @exitcode 74 The rule could not be written, checked, or installed.
# @exitcode other The status of the user lookup.
# @example
#   sudo::passwordless::enable "$(id -un)"
sudo::passwordless::enable() {
  [[ "$#" -le 1 ]] || return 64
  local user='' file='' directory='' status=0
  user="$(sudo::passwordless::_user "$@")" || return "$?"
  if ! user::exists "${user}"; then
    console::_write-error "User does not exist: ${user}"
    return 64
  fi
  file="$(sudo::passwordless::_file "${user}")"
  directory="$(mktemp -d "${TMPDIR:-/tmp}/bashstock-sudoers.XXXXXX")" || return 74
  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "${user}" >"${directory}/rule" || status=74
  if [[ "${status}" -eq 0 ]] && ! command::run-as-root visudo -c -q -f "${directory}/rule"; then
    status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /etc/sudoers.d || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0440 "${directory}/rule" "${file}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  # -k ignores the user's cached credentials, so only the rule can let sudo through.
  if ! command::run-as-root visudo -c -q ||
    ! command::run-as-root sudo -n -u "${user}" -- sudo -n -k true 2>/dev/null; then
    command::run-as-root rm -f -- "${file}"
    console::_write-error "sudo does not apply ${file}; the file was removed."
    return 69
  fi
}

# @description Remove the passwordless sudo rule that sudo::passwordless::enable added.
#
# Only the BashStock drop-in file of the user is removed, so sudo asks for
# the password again unless another sudoers rule also grants NOPASSWD. The
# function succeeds when the file does not exist.
#
# @arg $1 string Optional login name. Defaults to the user who invoked sudo, or the current user.
# @exitcode 0 The rule file does not exist.
# @exitcode 64 More than one argument was given.
# @exitcode 74 The file could not be removed.
# @exitcode other The status of the user lookup.
# @example
#   sudo::passwordless::disable
sudo::passwordless::disable() {
  [[ "$#" -le 1 ]] || return 64
  local user='' file=''
  user="$(sudo::passwordless::_user "$@")" || return "$?"
  file="$(sudo::passwordless::_file "${user}")" || return "$?"
  # /etc/sudoers.d is often unreadable to other users, so remove the file as root.
  command::run-as-root rm -f -- "${file}" || return 74
}

# @description Empty the Linux desktop trash of the current user through administrator execution.
#
# The entries directly under Trash/files and Trash/info are removed.
#
# @noargs
# @exitcode 0 The trash is empty.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Linux.
# @exitcode 74 An entry could not be removed.
# @example
#   storage::clear-trash
storage::clear-trash() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  local trash="${XDG_DATA_HOME:-${HOME}/.local/share}/Trash" part=''
  for part in files info; do
    [[ -d "${trash}/${part}" ]] || continue
    command::run-as-root find "${trash}/${part}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + || return 74
  done
}

# @description Select a USB partition, or a USB disk without partitions, and write its device path.
#
# One candidate is selected automatically; several are offered for
# interactive selection with their size, file system, and label.
#
# @noargs
# @stdout The device path, such as /dev/sdb1.
# @exitcode 0 The path was written.
# @exitcode 1 No USB block device is connected.
# @exitcode 64 An argument was given.
# @exitcode other The status of lsblk or the prompt.
# @example
#   device="$(usb::partition::select)"
usb::partition::select() {
  [[ "$#" -eq 0 ]] || return 64
  local candidates='' line='' selected=''
  local choices=()
  candidates="$(usb::_candidates)" || return "$?"
  [[ -n "${candidates}" ]] || return 1
  if [[ "${candidates}" != *$'\n'* ]]; then
    printf '%s\n' "${candidates%%$'\t'*}"
    return 0
  fi
  while IFS= read -r line; do
    choices+=("${line//$'\t'/ }")
  done <<<"${candidates}"
  selected="$(prompt::select-one 'Select a USB device' "${choices[@]}")" || return "$?"
  printf '%s\n' "${selected%% *}"
}

# @description Unmount every mount point of a block device through administrator execution.
# @internal
usb::_unmount() {
  [[ "$#" -eq 1 && -b "$1" ]] || return 64
  local mount_point=''
  while IFS= read -r mount_point; do
    [[ -n "${mount_point}" ]] || continue
    command::run-as-root umount -- "${mount_point}" || return 74
  done < <(lsblk -nro MOUNTPOINT "$1")
}

# @description Write the USB block devices that can be selected: partitions, or disks without partitions.
#
# Each line holds the device path, the size, the file system type, and the label, separated by tabs.
# @internal
usb::_candidates() {
  [[ "$#" -eq 0 ]] || return 64
  [[ "$(system::operating-system)" == linux ]] || return 69
  command::require lsblk || return "$?"
  local disk='' name='' type='' fstype='' size='' label='' found=0
  while IFS= read -r disk; do
    found=0
    while IFS=$'\t' read -r name type size fstype label; do
      [[ "${type}" == part ]] || continue
      found=1
      printf '%s\t%s\t%s\t%s\n' "${name}" "${size}" "${fstype}" "${label}"
    done < <(lsblk -lnpo NAME,TYPE,SIZE,FSTYPE,LABEL "${disk}" | awk 'BEGIN {OFS = "\t"} {print $1, $2, $3, $4, $5}')
    if [[ "${found}" -eq 0 ]]; then
      lsblk -dnpo NAME,SIZE,FSTYPE,LABEL "${disk}" | awk 'BEGIN {OFS = "\t"} {print $1, $2, $3, $4}'
    fi
  done < <(lsblk -dnpo NAME,TRAN | awk '$2 == "usb" {print $1}')
}

# @description Select a USB file system, unmount it, and repair it through administrator execution.
#
# FAT uses fsck.fat -a, exFAT fsck.exfat -a, and other types fsck -y.
#
# @noargs
# @exitcode 0 The file system was repaired or is clean.
# @exitcode 1 No USB block device is connected.
# @exitcode 64 An argument was given.
# @exitcode 74 The file system type could not be read.
# @exitcode other The status of the unmount or of fsck.
# @example
#   usb::filesystem::repair
usb::filesystem::repair() {
  [[ "$#" -eq 0 ]] || return 64
  local device='' type=''
  device="$(usb::partition::select)" || return "$?"
  type="$(lsblk -no FSTYPE "${device}" | head -n 1)" || return 74
  usb::_unmount "${device}" || return "$?"
  case "${type}" in
    vfat | fat | msdos) command::run-as-root fsck.fat -a "${device}" ;;
    exfat) command::run-as-root fsck.exfat -a "${device}" ;;
    *) command::run-as-root fsck -y "${device}" ;;
  esac
}

# @description Select a USB partition, unmount it, and format it as FAT32 through administrator execution.
#
# Everything on the selected partition is erased.
#
# @noargs
# @exitcode 0 The partition was formatted.
# @exitcode 1 No USB block device is connected.
# @exitcode 64 An argument was given.
# @exitcode other The status of the unmount or of mkfs.vfat.
# @example
#   usb::filesystem::format-fat32
usb::filesystem::format-fat32() {
  [[ "$#" -eq 0 ]] || return 64
  local device=''
  device="$(usb::partition::select)" || return "$?"
  usb::_unmount "${device}" || return "$?"
  command::run-as-root mkfs.vfat -F 32 "${device}"
}

# @description Fetch a remote base branch, switch to the local branch, and rebase it onto the remote one.
#
# @arg $1 string Optional base branch. Defaults to main.
# @arg $2 string Optional remote. Defaults to upstream.
# @arg $3 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The branch was rebased.
# @exitcode 64 More than three arguments were given.
# @exitcode other The status of the git command that failed.
# @example
#   git::rebase-base-branch develop origin
git::rebase-base-branch() {
  [[ "$#" -le 3 ]] || return 64
  local branch="${1:-main}" remote="${2:-upstream}" directory="${3:-.}"
  git::_run-in-directory "${directory}" fetch "${remote}" || return "$?"
  git::_run-in-directory "${directory}" checkout "${branch}" -- || return "$?"
  git::_run-in-directory "${directory}" rebase "${remote}/${branch}"
}

# @description Hard reset every project of a Google Repo workspace and remove untracked files.
#
# Every uncommitted change in every project is discarded. Ignored files are kept.
#
# @arg $1 string Optional workspace directory. Defaults to the current directory.
# @exitcode 0 Every project was reset.
# @exitcode 64 More than one argument was given.
# @exitcode 69 repo is unavailable.
# @exitcode other The status of repo forall.
# @example
#   repo::reset aosp
repo::reset() {
  [[ "$#" -le 1 ]] || return 64
  command::require repo || return "$?"
  (cd -- "${1:-.}" && repo forall -c 'git reset --hard && git clean -fd')
}

# @description Generate SELinux allow rules from the AVC denials of an audit log.
#
# @arg $1 string Audit log, such as /var/log/audit/audit.log.
# @arg $2 string Optional rule file. Defaults to selinux.txt next to the audit log.
# @stderr A message when the log has no AVC denial.
# @exitcode 0 The rules were written.
# @exitcode 1 The log has no AVC denial.
# @exitcode 64 The arguments are invalid or the log does not exist.
# @exitcode 69 audit2allow is unavailable.
# @exitcode other The status of audit2allow.
# @example
#   selinux::generate-rule /var/log/audit/audit.log ./allow.te
selinux::generate-rule() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  local output="${2:-$(path::directory-name "$1")/selinux.txt}" denials=''
  command::require audit2allow || return "$?"
  denials="$(grep -F 'avc:' -- "$1")" || {
    console::_write-error "No AVC denial in $1."
    return 1
  }
  printf '%s\n' "${denials}" | audit2allow >"${output}"
}

# @description Start an interactive Bash in a new GNOME Terminal window.
#
# When COMMAND is given, it runs with its arguments first, and the
# interactive shell starts after it ends.
#
# @arg $@ string Optional command and arguments to run before the interactive shell.
# @exitcode 0 GNOME Terminal opened the window.
# @exitcode 69 gnome-terminal is unavailable.
# @exitcode other The status of gnome-terminal.
# @example
#   terminal::gnome-bash make watch
terminal::gnome-bash() {
  command::require gnome-terminal || return "$?"
  if [[ "$#" -eq 0 ]]; then
    gnome-terminal -- bash -i
  else
    gnome-terminal -- bash -c '"$@"; exec bash -i' bash "$@"
  fi
}

# @description Set the default editor of new Bash and Zsh sessions and the current process.
#
# @arg $1 string Optional editor command. Defaults to code --wait.
# @arg $2 string Optional comma-separated shells, bash and zsh. Defaults to bash.
# @set EDITOR is exported in the current process.
# @exitcode 0 The editor was set.
# @exitcode 64 More than two arguments were given or the shell list is invalid.
# @exitcode other The status of env::set-variable.
# @example
#   shell::editor::set-default vim bash,zsh
shell::editor::set-default() {
  [[ "$#" -le 2 ]] || return 64
  env::set-variable EDITOR "${1:-code --wait}" "${2:-bash}"
}

# @description Set a string value for one top-level key in a macOS property list.
#
# The file is created as an empty dictionary when it does not exist and is
# validated with plutil before and after the change.
#
# @arg $1 string Property list file. A symbolic link is refused.
# @arg $2 string Top-level key without a dot.
# @arg $3 string String value.
# @exitcode 0 The value was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 65 The file is not a valid property list.
# @exitcode 66 The path is not a regular file.
# @exitcode 69 plutil is unavailable.
# @exitcode 74 The file could not be created or changed.
# @example
#   plist::set "${HOME}/Library/Preferences/com.example.app.plist" Theme dark
plist::set() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && "$2" != *.* && ! -L "$1" ]] || return 64
  command::require plutil || return "$?"
  if [[ ! -e "$1" ]]; then
    mkdir -p -- "$(path::directory-name "$1")" || return 74
    file::write-text "$1" '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
' || return "$?"
  fi
  [[ -f "$1" ]] || return 66
  plutil -lint -s "$1" || return 65
  plutil -replace "$2" -string "$3" "$1" || return 74
  plutil -lint -s "$1" || return 65
}

# @description Replace or append one top-level scalar field in a textproto file.
#
# The file is read with its comments, quoted strings, and nested messages
# taken into account, so only a FIELD at the top level is changed. An
# existing field line is replaced; a missing field is appended. A field that
# occurs more than once at the top level, a field that holds a message, and
# unbalanced braces or strings in the result return 65 without a change.
#
# @arg $1 string Existing textproto file. A symbolic link is refused.
# @arg $2 string Field name.
# @arg $3 string Literal scalar value on one line, quoted when it is a string.
# @exitcode 0 The field was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 65 The field is ambiguous or holds a message, or the file is unbalanced.
# @exitcode 66 The file cannot be read.
# @exitcode 69 perl is unavailable.
# @exitcode other The status of file::write-text.
# @example
#   textproto::set-scalar config.textproto timeout_seconds 30
#   textproto::set-scalar config.textproto name '"production"'
textproto::set-scalar() {
  [[ "$#" -eq 3 && -f "$1" && ! -L "$1" && "$2" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && -n "$3" ]] || return 64
  string::_require-one-line "$3" || return "$?"
  command::require perl || return "$?"
  local content=''
  content="$(perl -e '
    my ($path, $field, $value) = @ARGV;
    open(my $handle, "<", $path) or exit 66;
    my @lines = <$handle>;
    close($handle);
    # Scan text, returning the depth after it, or undef for an unterminated string.
    sub scan {
      my ($text, $depth) = @_;
      my $quote = "";
      for (my $i = 0; $i < length($text); $i++) {
        my $c = substr($text, $i, 1);
        if ($quote ne "") {
          if ($c eq "\\") { $i++; next; }
          $quote = "" if $c eq $quote;
          next;
        }
        last if $c eq "#";
        if ($c eq "\"" || $c eq "\x27") { $quote = $c; next; }
        $depth++ if $c eq "{" || $c eq "<";
        $depth-- if $c eq "}" || $c eq ">";
        return undef if $depth < 0;
      }
      return $quote eq "" ? $depth : undef;
    }
    my ($depth, @matches) = (0);
    for my $index (0 .. $#lines) {
      if ($depth == 0 && $lines[$index] =~ /^\s*\Q$field\E\s*(:|\{|<)/) {
        exit 65 if $1 ne ":" || $lines[$index] =~ /^\s*\Q$field\E\s*:\s*[{<]/;
        push @matches, $index;
      }
      $depth = scan($lines[$index], $depth);
      exit 65 unless defined $depth;
    }
    exit 65 if $depth != 0 || @matches > 1;
    if (@matches) {
      $lines[$matches[0]] = "$field: $value\n";
    } else {
      $lines[-1] .= "\n" if @lines && $lines[-1] !~ /\n\z/;
      push @lines, "$field: $value\n";
    }
    $depth = 0;
    for my $line (@lines) {
      $depth = scan($line, $depth);
      exit 65 unless defined $depth;
    }
    exit 65 if $depth != 0;
    print @lines;
    print "x";
  ' "$1" "$2" "$3")" || return "$?"
  # The trailing x keeps the final newline through command substitution.
  file::write-text "$1" "${content%x}"
}

# @description Make Bash and Zsh completion ignore letter case.
#
# Bash reads the setting from $HOME/.inputrc. A new .inputrc first includes
# /etc/inputrc, because Readline stops reading the system file once a
# personal one exists. Zsh receives a matcher-list zstyle in $HOME/.zshrc.
#
# @arg $1 string Optional comma-separated shells, bash and zsh. Defaults to bash,zsh.
# @exitcode 0 The setting was written.
# @exitcode 64 More than one argument was given or the shell list is invalid.
# @exitcode other The status of the file operation that failed.
# @example
#   shell::completion::enable-ignore-case bash
shell::completion::enable-ignore-case() {
  [[ "$#" -le 1 ]] || return 64
  local shells="${1:-bash,zsh}" shell='' line=''
  [[ "${shells}" =~ ^(bash|zsh)(,(bash|zsh))*$ ]] || return 64
  local _util_shells=()
  IFS=',' read -r -a _util_shells <<<"${shells}"
  for shell in "${_util_shells[@]}"; do
    case "${shell}" in
      bash)
        if [[ ! -e "${HOME}/.inputrc" ]]; then
          if [[ -r /etc/inputrc ]]; then line=$'$include /etc/inputrc\n'; else line=''; fi
          file::write-text "${HOME}/.inputrc" "${line}" || return "$?"
        fi
        file::replace-text-or-append "${HOME}/.inputrc" '^set[[:space:]]+completion-ignore-case[[:space:]].*$' \
          'set completion-ignore-case on' || return "$?"
        ;;
      zsh)
        line="zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'"
        if [[ ! -f "${HOME}/.zshrc" ]] || ! grep -Fqx -- "${line}" "${HOME}/.zshrc"; then
          file::append-text "${HOME}/.zshrc" "${line}"$'\n' || return "$?"
        fi
        ;;
    esac
  done
}

# @description Remove $HOME/.git-credentials and the global credential.helper; both may be absent.
#
# @noargs
# @exitcode 0 Neither the file nor the helper remains.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config or rm.
# @example
#   git::credentials::remove
git::credentials::remove() {
  [[ "$#" -eq 0 ]] || return 64
  if git config --global --get-all credential.helper >/dev/null 2>&1; then
    git config --global --unset-all credential.helper || return "$?"
  fi
  rm -f -- "$HOME/.git-credentials"
}

# @description Make origin fetch every branch in a repository.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @exitcode 0 The refspec was set.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::enable-origin-all-fetch && git::fetch origin
git::config::enable-origin-all-fetch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; }

# @description Enable pruning on fetch in the global Git configuration.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::enable-prune-fetch
git::config::enable-prune-fetch() { [[ "$#" -eq 0 ]] || return 64; git config --global fetch.prune true; }

# @description Set the default branch name of new repositories.
#
# @arg $1 string Optional branch name. Defaults to main.
# @exitcode 0 The setting was written.
# @exitcode 64 More than one argument was given or the name is not a valid branch name.
# @exitcode other The status of git config.
# @example
#   git::config::set-default-branch trunk
git::config::set-default-branch() {
  [[ "$#" -le 1 ]] || return 64
  local branch="${1:-main}"
  git check-ref-format --branch "${branch}" >/dev/null 2>&1 || return 64
  git config --global init.defaultBranch "${branch}"
}

# @description Enable rebase on pull in the global Git configuration.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::enable-rebase-on-pull
git::config::enable-rebase-on-pull() { [[ "$#" -eq 0 ]] || return 64; git config --global pull.rebase true; }

# @description Set the global Git email address.
#
# @arg $1 string Optional email address. Defaults to GIT_EMAIL, then to input from the controlling terminal.
# @exitcode 0 The address was set, or an existing one was kept.
# @exitcode 64 More than one argument was given or the value has several lines.
# @exitcode 66 No address is available and none is configured.
# @exitcode 74 The terminal could not be read.
# @exitcode other The status of git config.
# @example
#   git::config::set-email developer@example.com
git::config::set-email() {
  [[ "$#" -le 1 ]] || return 64
  git::config::_set-identity user.email "${1:-}" GIT_EMAIL 'email address'
}

# @description Read a Git identity value from an argument, an environment variable, or the terminal.
#
# The current global value is kept when none of these sources is available.
# @internal
git::config::_set-identity() {
  [[ "$#" -eq 4 ]] || return 64
  local key="$1" value="$2" variable="$3" label="$4"
  [[ -n "${value}" ]] || value="${!variable:-}"
  if [[ -z "${value}" ]] && terminal::is-available; then
    printf 'Git %s: ' "${label}" >/dev/tty
    IFS= read -r value </dev/tty || return 74
  fi
  if [[ -z "${value}" ]]; then
    git config --global --get "${key}" >/dev/null && return 0
    console::_write-error "Set the Git ${label} with an argument or ${variable}."
    return 66
  fi
  string::_require-one-line "${value}" || return "$?"
  git config --global "${key}" "${value}"
}

# @description Set the global Git user name.
#
# @arg $1 string Optional display name. Defaults to GIT_USERNAME, then to input from the controlling terminal.
# @exitcode 0 The name was set, or an existing one was kept.
# @exitcode 64 More than one argument was given or the value has several lines.
# @exitcode 66 No name is available and none is configured.
# @exitcode 74 The terminal could not be read.
# @exitcode other The status of git config.
# @example
#   git::config::set-username 'Alex Example'
git::config::set-username() {
  [[ "$#" -le 1 ]] || return 64
  git::config::_set-identity user.name "${1:-}" GIT_USERNAME 'user name'
}

# @description Set the global Git HTTP post buffer.
#
# @arg $1 integer Optional buffer size in bytes. Defaults to 524288000 (500 MiB).
# @exitcode 0 The setting was written.
# @exitcode 64 More than one argument was given or the size is not an integer.
# @exitcode other The status of git config.
# @example
#   git::config::set-http-buffer 1048576000
git::config::set-http-buffer() {
  [[ "$#" -le 1 ]] || return 64
  local size="${1:-524288000}"
  [[ "${size}" =~ ^(0|[1-9][0-9]*)$ ]] || return 64
  git config --global http.postBuffer "${size}"
}

# @description Make Git Credential Manager store credentials with GPG and pass.
#
# The guidance for initializing the pass store is written to standard error.
#
# @noargs
# @stderr How to initialize the pass store.
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git::config::use-gpg-credential-store && pass::store::init
git::config::use-gpg-credential-store() {
  [[ "$#" -eq 0 ]] || return 64
  git config --global credential.credentialStore gpg || return "$?"
  console::_write-error 'Git Credential Manager now stores credentials with pass; initialize it with pass::store::init FINGERPRINT.'
}

# @description Use Git Credential Manager as the global credential helper.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode other The status of git config.
# @example
#   git-credential-manager::install && git::config::use-credential-manager
git::config::use-credential-manager() { [[ "$#" -eq 0 ]] || return 64; git config --global credential.helper manager; }

# @description Remove a pass store and everything in it.
#
# @arg $1 string Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.
# @exitcode 0 The store was removed.
# @exitcode 64 More than one argument was given, or the directory is / or a symbolic link.
# @exitcode 66 The store does not exist.
# @exitcode 74 The store could not be removed.
# @example
#   pass::store::remove "${HOME}/.password-store-old"
pass::store::remove() {
  [[ "$#" -le 1 ]] || return 64
  local directory=''
  directory="$(pass::store::_directory "$@")" || return "$?"
  [[ -n "${directory}" && "${directory}" != / && ! -L "${directory}" ]] || return 64
  [[ -d "${directory}" ]] || return 66
  rm -rf -- "${directory}" || return 74
}

# @description Write the pass store directory: the argument, PASSWORD_STORE_DIR, or $HOME/.password-store.
# @internal
pass::store::_directory() {
  [[ "$#" -le 1 ]] || return 64
  printf '%s\n' "${1:-${PASSWORD_STORE_DIR:-${HOME}/.password-store}}"
}

# @description Initialize a pass store for a GPG key without removing an existing store.
#
# @arg $1 string Optional GPG key fingerprint. Defaults to the first secret key.
# @arg $2 string Optional store directory. Defaults to PASSWORD_STORE_DIR, then $HOME/.password-store.
# @exitcode 0 The store was initialized.
# @exitcode 1 No fingerprint was given and no secret key exists.
# @exitcode 64 More than two arguments were given.
# @exitcode 69 pass is unavailable.
# @exitcode other The status of pass init.
# @example
#   pass::store::init "$(gpg::secret-key::fingerprints | head -n 1)"
pass::store::init() {
  [[ "$#" -le 2 ]] || return 64
  local fingerprint="${1:-}" directory='' fingerprints=''
  command::require pass || return "$?"
  directory="$(pass::store::_directory "${2:-}")" || return "$?"
  if [[ -z "${fingerprint}" ]]; then
    fingerprints="$(gpg::secret-key::fingerprints)" || return "$?"
    fingerprint="${fingerprints%%$'\n'*}"
  fi
  PASSWORD_STORE_DIR="${directory}" pass init "${fingerprint}"
}

# @description Create a GPG key and use it for pass, Git credentials, and Git commit signing.
#
# The options are passed to gpg::key::generate. pass is installed and its
# store initialized with the new key, Git Credential Manager stores
# credentials with GPG, Git signs commits with the key, and the public key is
# written in ASCII armor. The first failing step stops the setup.
#
# @arg $@ string Options of gpg::key::generate, such as --user-id and --passphrase-fd.
# @stdout The ASCII-armored public key of the new key.
# @exitcode 0 Every step finished.
# @exitcode 74 The new key could not be identified.
# @exitcode other The status of the step that failed.
# @example
#   gpg::setup --user-id 'Alex Example <developer@example.com>' --passphrase-fd 3 3<passphrase.txt
gpg::setup() {
  local before='' after='' fingerprint='' candidate=''
  before="$(gpg::secret-key::fingerprints 2>/dev/null)" || before=''
  gpg::key::generate "$@" || return "$?"
  after="$(gpg::secret-key::fingerprints)" || return "$?"
  while IFS= read -r candidate; do
    grep -Fqx -- "${candidate}" <<<"${before}" || fingerprint="${candidate}"
  done <<<"${after}"
  [[ -n "${fingerprint}" ]] || return 74
  pass::install || return "$?"
  pass::store::init "${fingerprint}" || return "$?"
  git::config::use-gpg-credential-store || return "$?"
  git config --global user.signingkey "${fingerprint}" || return "$?"
  git config --global commit.gpgsign true || return "$?"
  gpg::public-key::armor "${fingerprint}"
}

# @description Generate a 4096-bit RSA SSH key and write its public key.
#
# An existing key is replaced only after confirmation on the controlling
# terminal; without a terminal it is kept and 73 is returned.
#
# @option --comment <COMMENT> Key comment. Defaults to an empty comment.
# @option --output <FILE> Private key path. Defaults to $HOME/.ssh/id_rsa.
# @option --passphrase-fd <FD> File descriptor to read the passphrase from. Defaults to no passphrase.
# @stdout The public key.
# @exitcode 0 The key was generated.
# @exitcode 64 An option is unknown or has an invalid value.
# @exitcode 66 The passphrase could not be read.
# @exitcode 69 ssh-keygen is unavailable.
# @exitcode 73 The key exists and was kept.
# @exitcode 74 The directory could not be created or the old key removed.
# @exitcode other The status of ssh-keygen.
# @example
#   ssh::key::generate-rsa4096 --comment 'build server' --output "${HOME}/.ssh/build_rsa"
ssh::key::generate-rsa4096() {
  ssh::key::_generate rsa id_rsa "$@"
}

# @description List the named arguments of ssh::key::generate-rsa4096.
# @internal
ssh::key::_generate-rsa4096-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --comment --output --passphrase-fd; fi
}

# @description Generate an SSH key and write its public key.
# @internal
ssh::key::_generate() {
  local type="$1" default_name="$2" comment='' output='' passphrase_fd='' passphrase=''
  local arguments=()
  shift 2
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --comment | --output | --passphrase-fd)
        arg::require-next "$#" "$1" || return "$?"
        case "$1" in
          --comment) comment="$2" ;;
          --output) output="$2" ;;
          --passphrase-fd) passphrase_fd="$2" ;;
        esac
        shift 2
        ;;
      *) arg::unknown "$1" || return "$?" ;;
    esac
  done
  [[ -z "${passphrase_fd}" || "${passphrase_fd}" =~ ^[0-9]+$ ]] || return 64
  command::require ssh-keygen || return "$?"
  output="${output:-${HOME}/.ssh/${default_name}}"
  mkdir -p -- "$(path::directory-name "${output}")" || return 74
  if [[ -e "${output}" || -e "${output}.pub" ]]; then
    if ! terminal::is-available; then
      console::_write-error "${output} exists; run in a terminal to confirm overwriting it."
      return 73
    fi
    [[ "$(prompt::confirm "Overwrite ${output}?" no </dev/tty)" == yes ]] || return 73
    rm -f -- "${output}" "${output}.pub" || return 74
  fi
  case "${type}" in
    rsa) arguments=(-t rsa -b 4096) ;;
    ed25519) arguments=(-t ed25519) ;;
  esac
  if [[ -n "${passphrase_fd}" ]]; then
    IFS= read -r -u "${passphrase_fd}" passphrase || [[ -n "${passphrase}" ]] || return 66
    # ssh-keygen reads the passphrase and its confirmation from a standard input that is not a terminal.
    printf '%s\n%s\n' "${passphrase}" "${passphrase}" |
      ssh-keygen "${arguments[@]}" -C "${comment}" -f "${output}" -q || return "$?"
    passphrase=''
  else
    ssh-keygen "${arguments[@]}" -C "${comment}" -f "${output}" -N '' -q </dev/null || return "$?"
  fi
  cat -- "${output}.pub"
}

# @description Generate an Ed25519 SSH key and write its public key.
#
# An existing key is replaced only after confirmation on the controlling
# terminal; without a terminal it is kept and 73 is returned.
#
# @option --comment <COMMENT> Key comment. Defaults to an empty comment.
# @option --output <FILE> Private key path. Defaults to $HOME/.ssh/id_ed25519.
# @option --passphrase-fd <FD> File descriptor to read the passphrase from. Defaults to no passphrase.
# @stdout The public key.
# @exitcode 0 The key was generated.
# @exitcode 64 An option is unknown or has an invalid value.
# @exitcode 66 The passphrase could not be read.
# @exitcode 69 ssh-keygen is unavailable.
# @exitcode 73 The key exists and was kept.
# @exitcode 74 The directory could not be created or the old key removed.
# @exitcode other The status of ssh-keygen.
# @example
#   ssh::key::generate-ed25519 --comment "$(id -un)@$(hostname)" --passphrase-fd 3 3<passphrase.txt
ssh::key::generate-ed25519() {
  ssh::key::_generate ed25519 id_ed25519 "$@"
}

# @description List the named arguments of ssh::key::generate-ed25519.
# @internal
ssh::key::_generate-ed25519-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --comment --output --passphrase-fd; fi
}

# @description End every SSH process of the current user.
#
# @noargs
# @exitcode 0 At least one SSH process was signaled.
# @exitcode 1 No SSH process was running.
# @exitcode 64 An argument was given.
# @exitcode 69 pkill is unavailable.
# @example
#   ssh::kill-all
ssh::kill-all() {
  [[ "$#" -eq 0 ]] || return 64
  command -v pkill >/dev/null 2>&1 || return 69
  pkill -u "$(id -un)" ssh
}

# @description Use the macOS Keychain as the global Git credential helper.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of git config.
# @example
#   git::config::use-osx-keychain
git::config::use-osx-keychain() { [[ "$#" -eq 0 ]] || return 64; [[ "$(system::operating-system)" == darwin ]] || return 69; git config --global credential.helper osxkeychain; }

# @description Write the installed Git Credential Manager version.
#
# @noargs
# @stdout The installed version.
# @exitcode 0 The version was written.
# @exitcode 64 An argument was given.
# @exitcode 69 git-credential-manager is unavailable.
# @exitcode other The status of git-credential-manager.
# @example
#   git-credential-manager::version::list
git-credential-manager::version::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command git-credential-manager --version; }

# @description Write the release asset names that may hold one Git Credential Manager version.
#
# Releases before 2.7 name the Linux x64 archive gcm-linux_amd64.VERSION.tar.gz.
# @internal
git-credential-manager::_asset-names() {
  [[ "$#" -eq 3 ]] || return 64
  printf 'gcm-%s-%s-%s.tar.gz\n' "$1" "$2" "$3"
  [[ "$1" != linux || "$2" != x64 ]] || printf 'gcm-linux_amd64.%s.tar.gz\n' "$3"
}

# @description Download one Git Credential Manager version and keep it when it starts on this system.
# @internal
# @arg $1 string PLATFORM osx or linux.
# @arg $2 string ARCHITECTURE x64 or arm64.
# @arg $3 string VERSION Release version.
git-credential-manager::_install-version() {
  [[ "$#" -eq 3 ]] || return 64
  local version="$3" destination='' temporary='' asset='' downloaded=0 actual_version=''
  destination="${HOME}/.local/lib/git-credential-manager/${version}"
  [[ ! -x "${destination}/git-credential-manager" ]] || return 0
  temporary="$(package::_temporary-directory)" || return "$?"
  while IFS= read -r asset; do
    if package::_download \
      "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${version}/${asset}" \
      "${temporary}/gcm.tar.gz" 2>/dev/null; then
      downloaded=1
      break
    fi
  done < <(git-credential-manager::_asset-names "$1" "$2" "${version}")
  if [[ "${downloaded}" -eq 0 ]]; then
    rm -rf -- "${temporary}"
    return 69
  fi
  mkdir -p -- "${temporary}/unpacked" || { rm -rf -- "${temporary}"; return 74; }
  tar -xzf "${temporary}/gcm.tar.gz" -C "${temporary}/unpacked" || { rm -rf -- "${temporary}"; return 74; }
  # A build for a newer C library fails here, before anything is installed.
  actual_version="$("${temporary}/unpacked/git-credential-manager" --version 2>/dev/null)" ||
    { rm -rf -- "${temporary}"; return 69; }
  [[ "${actual_version}" == "${version}" || "${actual_version}" == "${version}"+* ]] ||
    { rm -rf -- "${temporary}"; return 69; }
  mkdir -p -- "${HOME}/.local/lib/git-credential-manager" || { rm -rf -- "${temporary}"; return 74; }
  mv -- "${temporary}/unpacked" "${destination}" || { rm -rf -- "${temporary}"; return 74; }
  rm -rf -- "${temporary}"
}

# @description Install the ICU library that Git Credential Manager, a .NET program, needs on Linux.
# @internal
git-credential-manager::_install-icu() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' name=''
  if command -v ldconfig >/dev/null 2>&1 && ldconfig -p 2>/dev/null | grep -q 'libicuuc\.so'; then
    return 0
  fi
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_refresh || return "$?"
      # The package name carries the ICU major version, such as libicu60 on Ubuntu 18.04.
      name="$(apt-cache pkgnames libicu 2>/dev/null | grep -E '^libicu[0-9]+$' | sort -V | tail -n 1)"
      [[ -n "${name}" ]] || return 69
      package::_install "${name}"
      ;;
    fedora)
      package::_install libicu
      ;;
  esac
}

# @description Install an official Git Credential Manager release for this OS and CPU.
#
# Each release is built for a minimum C library: 3.0 needs glibc 2.34, so
# Ubuntu 18.04 and 20.04 run 2.9. On Linux the ICU library is installed
# first, because the program does not start without it. Without VERSION, releases are tried from
# the newest until one starts on this system. A requested VERSION that does
# not start returns 69 without installing anything.
#
# @arg $1 string Optional major.minor.patch release. Defaults to the newest release that starts.
# @stderr A message when no release starts on this system.
# @exitcode 0 Git Credential Manager was installed and configured.
# @exitcode 64 More than one argument was given or the version is malformed.
# @exitcode 69 The platform or CPU is unsupported, or no release starts.
# @exitcode 74 A download or file operation failed.
# @exitcode other The status of the step that failed.
# @example
#   git-credential-manager::install 2.6.1
git-credential-manager::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' architecture='' candidates='' candidate='' status=69
  [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 64
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) platform='osx' ;;
    ubuntu | fedora) platform='linux' ;;
  esac
  architecture="$(uname -m)" || return 74
  case "${architecture}" in
    x86_64 | amd64) architecture='x64' ;;
    aarch64 | arm64) architecture='arm64' ;;
    *) return 69 ;;
  esac
  if [[ "${platform}" == linux ]]; then
    git-credential-manager::_install-icu || return "$?"
  fi
  if [[ -n "${version}" ]]; then
    git-credential-manager::_install-version "${platform}" "${architecture}" "${version}" || return "$?"
  else
    candidates="$(package::_github-release-versions git-ecosystem/git-credential-manager)" || return "$?"
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] || continue
      status=0
      git-credential-manager::_install-version "${platform}" "${architecture}" "${candidate}" || status="$?"
      [[ "${status}" -eq 69 ]] || break
    done < <(printf '%s\n' "${candidates}" | sed '1!G;h;$!d')
    if [[ "${status}" -ne 0 ]]; then
      [[ "${status}" -ne 69 ]] || console::_write-error 'No Git Credential Manager release starts on this system.'
      return "${status}"
    fi
    version="${candidate}"
  fi
  mkdir -p -- "${HOME}/.local/bin" || return 74
  ln -sfn -- "${HOME}/.local/lib/git-credential-manager/${version}/git-credential-manager" \
    "${HOME}/.local/bin/git-credential-manager" || return 74
  env::add-path "${HOME}/.local/bin" || return "$?"
  "${HOME}/.local/bin/git-credential-manager" configure
}

# @description Apply the user identity and the standard global Git settings.
#
# @arg $1 string Optional email address passed to git::config::set-email.
# @arg $2 string Optional display name passed to git::config::set-username.
# @exitcode 0 Every setting was applied.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of the setting that failed.
# @example
#   git::config::setup developer@example.com 'Alex Example'
git::config::setup() {
  [[ "$#" -le 2 ]] || return 64
  git::config::set-email "${1:-}" || return "$?"
  git::config::set-username "${2:-}" || return "$?"
  git::config::set-default-branch main || return "$?"
  git::config::enable-rebase-on-pull || return "$?"
  git::config::enable-prune-fetch
}

# @description Register the official Go package source for the current platform.
#
# Go comes from the distribution or Homebrew, so this only checks that the package tool is available.
#
# @noargs
# @exitcode 0 The package source is available.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported or its package tool is unavailable.
# @example
#   go::repository::register
go::repository::register() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(package::_platform)" in
    darwin) command::require brew ;;
    ubuntu) command::require apt-get ;;
    fedora) command::require dnf ;;
    *) return 69 ;;
  esac
}

# @description Install Go from the platform package source.
#
# @arg $1 string Optional version from go::version::list. Defaults to the package source default.
# @exitcode 0 Go was installed.
# @exitcode 64 More than one argument was given.
# @exitcode 69 The platform is unsupported or the version is not offered.
# @exitcode other The status of the package installation.
# @example
#   go::install "$(go::version::latest)"
go::install() {
  [[ "$#" -le 1 ]] || return 64
  go::repository::register || return "$?"
  local platform='' version="${1:-}"
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) package::_install-version go "${version}" ;;
    ubuntu)
      if [[ -n "${version}" ]]; then
        package::_install "golang-${version}"
      else
        package::_install golang
      fi
      ;;
    fedora) package::_install-version golang "${version}" ;;
  esac
}

# @description Install Rust using rustup and an optional toolchain version.
#
# @arg $1 string Optional toolchain, such as 1.81.0 or nightly. Defaults to stable.
# @exitcode 0 Rust was installed and $HOME/.cargo/bin was added to PATH.
# @exitcode 64 More than one argument was given.
# @exitcode 69 curl or a C compiler is unavailable, or the platform is unsupported.
# @exitcode 74 rustup could not be downloaded.
# @exitcode other The status of the rustup installer.
# @example
#   rust::install 1.81.0
rust::install() {
  [[ "$#" -le 1 ]] || return 64
  command -v curl >/dev/null 2>&1 || return 69
  local temporary='' platform=''
  local toolchain='stable'
  [[ "$#" -eq 1 ]] && toolchain="$1"
  platform="$(package::_platform)" || return "$?"
  case "$platform" in
    ubuntu) package::_install build-essential || return "$?" ;;
    fedora) package::_install gcc || return "$?" ;;
    darwin) command -v cc >/dev/null 2>&1 || return 69 ;;
    *) return 69 ;;
  esac
  temporary="$(mktemp)" || return 74
  if ! curl -fsSL https://sh.rustup.rs -o "$temporary"; then
    rm -f -- "$temporary"
    return 74
  fi
  sh "$temporary" -y --default-toolchain "$toolchain"
  local status="$?"
  rm -f -- "$temporary"
  [[ "$status" -eq 0 ]] || return "$status"
  env::add-path "$HOME/.cargo/bin"
}

# @description Write the stable Rust versions, oldest first, from the rust-lang/rust releases.
#
# @noargs
# @stdout One version per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 1 No version was found.
# @exitcode 64 An argument was given.
# @exitcode other The status of the GitHub query.
# @example
#   rust::versions | tail -n 1
rust::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(package::_github-release-versions rust-lang/rust)" || return "$?"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}

# @description Keep Flutter SDK changes in a retrievable stash and switch versions.
#
# @arg $1 string Optional tag to check out. Defaults to the newest stable version.
# @arg $2 string Optional Flutter SDK directory. Defaults to $HOME/.local/flutter.
# @exitcode 0 The SDK is at the version.
# @exitcode 64 More than two arguments were given.
# @exitcode 66 The directory is not a Git checkout.
# @exitcode other The status of the git command that failed.
# @example
#   flutter::use-version 3.24.3
flutter::use-version() {
  [[ "$#" -le 2 ]] || return 64
  local version='' directory=''
  if [[ "$#" -ge 1 ]]; then version="$1"; fi
  if [[ "$#" -ge 2 ]]; then directory="$2"; else directory="$HOME/.local/flutter"; fi
  [[ -d "$directory/.git" ]] || return 66
  [[ -n "$version" ]] || version="$(flutter::versions | package::_latest-stable-version)" || return "$?"
  git -C "$directory" fetch --tags origin || return "$?"
  if ! git -C "$directory" stash push --include-untracked; then
    git -C "$directory" reset --hard HEAD || return "$?"
    git -C "$directory" clean -fd || return "$?"
  fi
  # checkout instead of switch keeps Git 2.17 on Ubuntu 18.04 working.
  git -C "$directory" -c advice.detachedHead=false checkout --detach "$version"
}

# @description Remove one JFrog CLI server configuration.
#
# @arg $1 string Server ID.
# @exitcode 0 The configuration was removed.
# @exitcode 64 The argument count is not one.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config remove.
# @example
#   jfrog::config::clear artifactory-prod
jfrog::config::clear() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; util::_run-command jf config remove "$1"; }

# @description Remove every JFrog CLI server configuration.
#
# @noargs
# @exitcode 0 Every configuration was removed.
# @exitcode 64 An argument was given.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config clean.
# @example
#   jfrog::config::clear-all
jfrog::config::clear-all() { [[ "$#" -eq 0 ]] || return 64; util::_run-command jf config clean; }

# @description Display JFrog CLI server configurations.
#
# @noargs
# @stdout The output of jf config show.
# @exitcode 0 The configurations were written.
# @exitcode 64 An argument was given.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config show.
# @example
#   jfrog::config::list
jfrog::config::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command jf config show; }

# @description Register and verify a JFrog CLI server.
#
# The access token is read from JFROG_ACCESS_TOKEN and passed to jf on standard input, never as an argument.
#
# @arg $1 string Server ID.
# @arg $2 string Platform URL, such as https://example.jfrog.io.
# @arg $3 string User name.
# @exitcode 0 The server was registered and answered ping.
# @exitcode 64 An argument is empty or JFROG_ACCESS_TOKEN is unset.
# @exitcode 69 jf is unavailable.
# @exitcode other The status of jf config add or jf rt ping.
# @example
#   JFROG_ACCESS_TOKEN="$(pass show jfrog/token)" jfrog::setup prod https://example.jfrog.io builder
jfrog::setup() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" && -n "${JFROG_ACCESS_TOKEN:-}" ]] || return 64
  command -v jf >/dev/null 2>&1 || return 69
  printf '%s\n' "$JFROG_ACCESS_TOKEN" |
    env -u JFROG_ACCESS_TOKEN jf config add "$1" \
      --url "$2" --user "$3" --access-token-stdin --interactive=false || return "$?"
  env -u JFROG_ACCESS_TOKEN jf rt ping --server-id "$1"
}

# @description Install the newest OpenCode command-line application.
#
# macOS uses the Homebrew tap. Linux installs the official opencode-ai npm
# package into $HOME/.local; its installer picks the build for the CPU and C
# library, and the glibc builds run on Ubuntu 18.04 and later. Linux needs
# npm: the Ubuntu nodejs package does not provide it, so install Node.js with
# `node::install VERSION official` first there.
#
# @noargs
# @stdout The installed version.
# @exitcode 0 OpenCode was installed.
# @exitcode 64 An argument was given.
# @exitcode 69 npm is unavailable.
# @exitcode 74 $HOME/.local could not be created.
# @exitcode other The status of the installation.
# @example
#   opencode::install
opencode::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == darwin ]]; then
    package::_install anomalyco/tap/opencode || return "$?"
    opencode --version
  else
    command::require npm || return "$?"
    mkdir -p -- "${HOME}/.local" || return 74
    npm install --global --prefix "${HOME}/.local" opencode-ai || return "$?"
    env::add-path "${HOME}/.local/bin" || return "$?"
    "${HOME}/.local/bin/opencode" --version
  fi
}

# @description Log in to an Artifactory Docker registry using a token on standard input.
#
# The token is passed to docker on standard input, never as an argument.
#
# @arg $1 string Registry host.
# @arg $2 string User name.
# @arg $3 string Access token.
# @exitcode 0 The login succeeded.
# @exitcode 64 The argument count is not three or an argument is empty.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker login.
# @example
#   docker::login-artifactory example.jfrog.io builder "$(pass show jfrog/token)"
docker::login-artifactory() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  command -v docker >/dev/null 2>&1 || return 69
  printf '%s\n' "$3" | docker login "$1" --username "$2" --password-stdin
}

# @description Export a Chrome profile's Bookmarks file.
#
# @arg $1 string Chrome profile directory.
# @arg $2 string Optional output file. Defaults to ./bookmarks.json.
# @exitcode 0 The file was copied.
# @exitcode 64 The arguments are invalid or the profile is not a directory.
# @exitcode 66 The profile has no Bookmarks file.
# @exitcode other The status of cp.
# @example
#   chrome::profile::export-bookmarks "${HOME}/.config/google-chrome/Default" backup/bookmarks.json
chrome::profile::export-bookmarks() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" && ! -L "$1" ]] || return 64
  local output=''
  if [[ "$#" -eq 2 ]]; then output="$2"; else output='./bookmarks.json'; fi
  [[ -f "$1/Bookmarks" && ! -L "$1/Bookmarks" ]] || return 66
  cp -- "$1/Bookmarks" "$output"
}

# @description Export a Chrome profile's Preferences file.
#
# @arg $1 string Chrome profile directory.
# @arg $2 string Optional output file. Defaults to ./preferences.json.
# @exitcode 0 The file was copied.
# @exitcode 64 The arguments are invalid or the profile is not a directory.
# @exitcode 66 The profile has no Preferences file.
# @exitcode other The status of cp.
# @example
#   chrome::profile::export-preferences "${HOME}/.config/google-chrome/Profile 1"
chrome::profile::export-preferences() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" && ! -L "$1" ]] || return 64
  local output=''
  if [[ "$#" -eq 2 ]]; then output="$2"; else output='./preferences.json'; fi
  [[ -f "$1/Preferences" && ! -L "$1/Preferences" ]] || return 66
  cp -- "$1/Preferences" "$output"
}

# @description Write the first known email address from a Chrome profile.
#
# @arg $1 string Chrome profile directory.
# @stdout The email address.
# @exitcode 0 The address was written.
# @exitcode 1 The profile has no email address.
# @exitcode 64 The argument is not a profile with a Preferences file.
# @exitcode 69 jq is unavailable.
# @exitcode 74 Preferences could not be read.
# @example
#   chrome::profile::email "${HOME}/.config/google-chrome/Default"
chrome::profile::email() {
  [[ "$#" -eq 1 && -d "$1" && -f "$1/Preferences" && ! -L "$1/Preferences" ]] || return 64
  command -v jq >/dev/null 2>&1 || return 69
  local email=''
  email="$(jq -r '.. | objects | (.email? // .user_name? // empty) | select(type == "string")' "$1/Preferences" 2>/dev/null | head -n 1)" || return 74
  [[ "$email" == *@*.* ]] || return 1
  printf '%s\n' "$email"
}

# @description Find Chrome profiles whose known email matches literally.
#
# @arg $1 string Email address.
# @arg $2 string Optional Chrome user data directory. Defaults to the standard directory of the platform.
# @stdout One matching profile directory per line.
# @exitcode 0 At least one profile matches.
# @exitcode 1 No profile matches.
# @exitcode 64 The arguments are invalid.
# @exitcode 66 The user data directory does not exist.
# @example
#   chrome::profile::find-by-email developer@example.com
chrome::profile::find-by-email() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  local email="$1" root='' path=''
  if [[ "$#" -eq 2 ]]; then root="$2"; elif [[ "$(system::operating-system)" == darwin ]]; then root="$HOME/Library/Application Support/Google/Chrome"; else root="$HOME/.config/google-chrome"; fi
  [[ -d "$root" ]] || return 66
  (
    shopt -s nullglob
    found=1
    for path in "$root"/Default "$root"/Profile\ *; do
      [[ -d "$path" ]] || continue
      if [[ "$(chrome::profile::email "$path" 2>/dev/null)" == "$email" ]]; then
        printf '%s\n' "$path"
        found=0
      fi
    done
    # Succeed when any profile matched, not only when the last one did.
    exit "$found"
  )
}

# @description Extend swap capacity up to a target size.
#
# @arg $1 integer Target total swap size in bytes.
# @arg $2 integer Optional largest size to add in bytes. Defaults to the target.
# @arg $3 string Optional swap file path for the addition. Defaults to /swapfile.
# @exitcode 0 The swap capacity reaches the target, or the allowed addition was made.
# @exitcode 64 The arguments are invalid.
# @exitcode other The status of mem::swap-total-bytes or swap::create.
# @example
#   swap::ensure-total-size 8589934592
swap::ensure-total-size() {
  [[ "$#" -ge 1 && "$#" -le 3 && "$1" =~ ^[1-9][0-9]*$ ]] || return 64
  local target="$1" max='' path='' current='' add=''
  if [[ "$#" -ge 2 ]]; then max="$2"; else max="$target"; fi
  if [[ "$#" -ge 3 ]]; then path="$3"; else path='/swapfile'; fi
  [[ "$max" =~ ^[0-9]+$ ]] || return 64
  current="$(mem::swap-total-bytes)" || return "$?"
  (( current >= target )) && return 0
  add=$((target - current))
  (( add > max )) && add="$max"
  swap::create "$add" "$path"
}

# @description Remove the VS Code user data directory.
#
# VS Code is not checked for running instances.
#
# @arg $1 string Optional directory to remove. Defaults to the standard user data directory.
# @exitcode 0 The directory was removed.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist, is /, or is a symbolic link.
# @exitcode 74 The directory could not be removed.
# @example
#   vscode::remove-user-data
vscode::remove-user-data() {
  [[ "$#" -le 1 ]] || return 64
  local directory=''
  if [[ "$#" -eq 1 ]]; then
    directory="$1"
  elif [[ "$(system::operating-system)" == darwin ]]; then
    directory="${HOME}/Library/Application Support/Code"
  else
    directory="${HOME}/.config/Code"
  fi
  [[ -n "${directory}" && "${directory}" != / && -d "${directory}" && ! -L "${directory}" ]] || return 66
  rm -rf -- "${directory}" || return 74
}

# @description Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL.
#
# @arg $1 string Device serial.
# @set ANDROID_SERIAL is exported in the current shell.
# @exitcode 0 The variable was set.
# @exitcode 64 The argument is not one valid serial.
# @example
#   adb::device::set-default "$(adb::device::first)"
adb::device::set-default() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._:-]+$ ]] || return 64
  export ANDROID_SERIAL="$1"
}

# @description Start the host ADB server.
#
# @noargs
# @exitcode 0 The server is running.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb start-server.
# @example
#   adb::server::start
adb::server::start() { [[ "$#" -eq 0 ]] || return 64; util::_run-command adb start-server; }

# @description Stop the host ADB server.
#
# @noargs
# @exitcode 0 The server stopped.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb kill-server.
# @example
#   adb::server::stop
adb::server::stop() { [[ "$#" -eq 0 ]] || return 64; util::_run-command adb kill-server; }

# @description Stop and then start the host ADB server.
#
# @noargs
# @exitcode 0 The server was restarted.
# @exitcode 64 An argument was given.
# @exitcode 69 adb is unavailable.
# @exitcode other The status of adb.
# @example
#   adb::server::restart
adb::server::restart() { [[ "$#" -eq 0 ]] || return 64; adb::server::stop || return "$?"; adb::server::start; }

# @description List stashes.
#
# @arg $1 string Optional repository directory. Defaults to the current directory.
# @stdout The output of git stash list.
# @exitcode 0 The stashes were written.
# @exitcode 64 More than one argument was given.
# @exitcode other The status of git stash.
# @example
#   git::stash::list
git::stash::list() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" stash list; }

# @description Write the last modification time of a file as Unix seconds.
#
# @arg $1 string File or symbolic link.
# @stdout The modification time in seconds since 1970-01-01 UTC.
# @exitcode 0 The time was written.
# @exitcode 64 The argument count is not one or the path is empty.
# @exitcode 66 The path does not exist.
# @exitcode 69 stat is unavailable or the operating system is unsupported.
# @exitcode 74 stat failed.
# @example
#   file::modified-time-unix-seconds /etc/hosts
file::modified-time-unix-seconds() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  [[ -e "$1" || -L "$1" ]] || return 66
  command::require stat || return "$?"
  case "$(system::operating-system)" in
    darwin) stat -f '%m' -- "$1" || return 74 ;;
    linux) stat -c '%Y' -- "$1" || return 74 ;;
    *) return 69 ;;
  esac
}

# @description List the named arguments and value candidates for gpg::key::generate.
# @internal
gpg::key::_generate-args() {
  case "${1-}" in
    --usage)
      printf '%s\n' sign cert auth sign,auth
      ;;
    --algorithm)
      printf '%s\n' ed25519 rsa3072 rsa4096
      ;;
    '')
      printf '%s\n' --usage --algorithm --expires --user-id --pinentry --passphrase-fd
      ;;
  esac
}

# @description Generate a GPG primary key and an encryption subkey in one operation.
#
# @option --usage <USAGE> Primary key usage: sign, cert, auth, or a comma-separated combination. Defaults to sign.
# @option --algorithm <ALGORITHM> ed25519, rsa3072, or rsa4096. Defaults to ed25519, which pairs an Ed25519 primary key with a Curve25519 encryption subkey.
# @option --expires <EXPIRES> GnuPG expiration such as 5y, 12m, or 0. Defaults to 5y.
# @option --user-id <USER_ID> "Name <email>". Defaults to the Git user name and email.
# @option --pinentry Ask for the passphrase through pinentry.
# @option --passphrase-fd <FD> Read the passphrase from a file descriptor.
# @exitcode 0 The key was generated.
# @exitcode 64 An option is unknown or invalid, or no user ID is available.
# @exitcode 69 gpg is unavailable.
# @exitcode 74 The parameter file could not be written.
# @exitcode other The status of gpg.
# @example
#   gpg::key::generate --user-id 'Alex Example <developer@example.com>' --pinentry
#   gpg::key::generate --algorithm rsa4096 --expires 2y --passphrase-fd 3 3<passphrase.txt
gpg::key::generate() {
  local usage='sign' algorithm='ed25519' expires='5y' user_id='' pinentry='false' passphrase_fd=''
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --usage | --algorithm | --expires | --user-id | --passphrase-fd)
        arg::require-next "$#" "$1" || return "$?"
        case "$1" in
          --usage) usage="$2" ;;
          --algorithm) algorithm="$2" ;;
          --expires) expires="$2" ;;
          --user-id) user_id="$2" ;;
          --passphrase-fd) passphrase_fd="$2" ;;
        esac
        shift 2
        ;;
      --pinentry)
        pinentry='true'
        shift
        ;;
      *)
        arg::unknown "$1" || return "$?"
        ;;
    esac
  done
  [[ "${usage}" =~ ^(sign|cert|auth)(,(sign|cert|auth))*$ ]] || return 64
  arg::one-of --algorithm "${algorithm}" ed25519 rsa3072 rsa4096 || return "$?"
  [[ "${expires}" =~ ^(0|[1-9][0-9]*[dwmy]?)$ ]] || return 64
  [[ -z "${passphrase_fd}" || "${passphrase_fd}" =~ ^[0-9]+$ ]] || return 64
  [[ "${pinentry}" == 'false' || -z "${passphrase_fd}" ]] || return 64
  command::require gpg || return "$?"
  if [[ -z "${user_id}" ]]; then
    local name='' email=''
    name="$(git config --get user.name 2>/dev/null)"
    email="$(git config --get user.email 2>/dev/null)"
    [[ -n "${name}" && -n "${email}" ]] || return 64
    user_id="${name} <${email}>"
  fi
  local user_id_pattern='^([^<>]+) <([^<>@[:space:]]+@[^<>[:space:]]+)>$'
  [[ "${user_id}" =~ ${user_id_pattern} ]] || return 64
  local real_name="${BASH_REMATCH[1]}" email_address="${BASH_REMATCH[2]}" parameters='' directory='' status=0
  case "${algorithm}" in
    ed25519)
      parameters="Key-Type: eddsa"$'\n'"Key-Curve: ed25519"$'\n'
      parameters+="Subkey-Type: ecdh"$'\n'"Subkey-Curve: cv25519"$'\n'
      ;;
    rsa*)
      parameters="Key-Type: RSA"$'\n'"Key-Length: ${algorithm#rsa}"$'\n'
      parameters+="Subkey-Type: RSA"$'\n'"Subkey-Length: ${algorithm#rsa}"$'\n'
      ;;
  esac
  parameters+="Key-Usage: ${usage//,/ }"$'\n'"Subkey-Usage: encrypt"$'\n'
  parameters+="Name-Real: ${real_name}"$'\n'"Name-Email: ${email_address}"$'\n'
  parameters+="Expire-Date: ${expires}"$'\n'
  [[ "${pinentry}" == 'true' || -n "${passphrase_fd}" ]] || parameters+='%no-protection'$'\n'
  parameters+='%commit'$'\n'
  directory="$(package::_temporary-directory)" || return "$?"
  chmod 0700 "${directory}" || status=74
  if [[ "${status}" -eq 0 ]]; then
    (umask 077 && printf '%s' "${parameters}" >"${directory}/parameters") || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    if [[ -n "${passphrase_fd}" ]]; then
      gpg --batch --pinentry-mode loopback --passphrase-fd "${passphrase_fd}" \
        --generate-key "${directory}/parameters" || status="$?"
    elif [[ "${pinentry}" == 'true' ]]; then
      gpg --generate-key "${directory}/parameters" || status="$?"
    else
      gpg --batch --generate-key "${directory}/parameters" || status="$?"
    fi
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

# @description Write the current DNS manager: systemd-resolved, network-manager, or unknown.
#
# @noargs
# @stdout systemd-resolved, network-manager, or unknown.
# @exitcode 0 The manager was written.
# @exitcode 64 An argument was given.
# @example
#   [[ "$(net::dns::manager)" == systemd-resolved ]] && resolvectl status
net::dns::manager() { [[ "$#" -eq 0 ]] || return 64; net::dns::_manager; }

# @description Write one setting from the effective NetworkManager configuration.
# @internal
net::dns::_network-manager-setting() {
  [[ "$#" -eq 1 && "$1" =~ ^[a-z-]+$ ]] || return 64
  command -v NetworkManager >/dev/null 2>&1 || return 1
  NetworkManager --print-config 2>/dev/null |
    awk -F= -v key="$1" '/^\[/ {section=$0} section == "[main]" && $1 == key {print $2; exit}'
}

# @description Write the current DNS manager by inspecting resolv.conf and NetworkManager settings.
# @internal
net::dns::_manager() {
  [[ "$#" -eq 0 ]] || return 64
  local target='' dns=''
  if [[ -L /etc/resolv.conf ]]; then
    target="$(readlink /etc/resolv.conf)" || target=''
  fi
  dns="$(net::dns::_network-manager-setting dns)" || dns=''
  case "${target}" in
    */run/NetworkManager/resolv.conf)
      printf 'network-manager\n'
      return 0
      ;;
    */run/systemd/resolve/stub-resolv.conf | */run/systemd/resolve/resolv.conf)
      printf 'systemd-resolved\n'
      return 0
      ;;
  esac
  case "${dns}" in
    systemd-resolved) printf 'systemd-resolved\n' ;;
    default | dnsmasq) printf 'network-manager\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

# @description Back up /etc/resolv.conf when it differs from the link that will replace it.
# @internal
net::dns::_backup-resolv-conf() {
  [[ "$#" -eq 1 && "$1" == /* ]] || return 64
  [[ -e /etc/resolv.conf || -L /etc/resolv.conf ]] || return 0
  # Ubuntu links resolv.conf relatively, so compare the resolved paths.
  if [[ -L /etc/resolv.conf && "$(readlink -f /etc/resolv.conf)" == "$(readlink -f "$1")" ]]; then
    return 0
  fi
  local stamp=''
  stamp="$(time::local-date-time-seconds-basic)" || return "$?"
  command::run-as-root cp -P -- /etc/resolv.conf "/etc/resolv.conf.bashstock-${stamp}" || return 74
}

# @description Write UUIDs of active connections that NetworkManager itself manages, excluding VPNs.
#
# Connections on devices that another program configures, such as the docker0
# bridge, are reported as "connected (externally)" and are left alone.
# @internal
net::dns::_active-network-manager-connections() {
  [[ "$#" -eq 0 ]] || return 64
  command::require nmcli || return "$?"
  local uuid='' type='' device='' state=''
  while IFS=: read -r uuid type device; do
    [[ -n "${uuid}" && "${type}" != vpn && "${type}" != wireguard && "${type}" != loopback ]] || continue
    if [[ -n "${device}" ]]; then
      state="$(nmcli -g GENERAL.STATE device show "${device}" 2>/dev/null)" || state=''
      [[ "${state}" != *externally* ]] || continue
    fi
    printf '%s\n' "${uuid}"
  done < <(nmcli -t -f UUID,TYPE,DEVICE connection show --active 2>/dev/null)
}

# @description Restart systemd-resolved and confirm that it is active.
# @internal
net::dns::_restart-systemd-resolved() {
  [[ "$#" -eq 0 ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl restart systemd-resolved || return 75
  systemctl is-active --quiet systemd-resolved || return 75
}

# @description Restart NetworkManager and wait until it writes its runtime resolv.conf.
# @internal
net::dns::_restart-network-manager() {
  [[ "$#" -eq 0 ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl restart NetworkManager || return 75
  systemctl is-active --quiet NetworkManager || return 75
  local attempt=0
  while [[ ! -f /run/NetworkManager/resolv.conf ]]; do
    attempt=$((attempt + 1))
    [[ "${attempt}" -le 20 ]] || return 75
    sleep 0.5 || return 74
  done
}

# @description Verify the DNS manager, configured servers, resolv.conf link, and name resolution.
# @internal
# @arg $1 string MANAGER Expected DNS manager.
# @arg $2 string SERVER... DNS servers that must be configured.
net::dns::_verify() {
  [[ "$#" -ge 1 ]] || return 64
  local manager="$1" actual='' configured='' server=''
  shift
  actual="$(net::dns::_manager)" || return "$?"
  if [[ "${actual}" != "${manager}" ]]; then
    console::_write-error "DNS manager is ${actual}, expected ${manager}."
    return 75
  fi
  case "${manager}" in
    systemd-resolved)
      [[ "$(readlink /etc/resolv.conf 2>/dev/null)" == */run/systemd/resolve/*resolv.conf ]] || return 75
      command::require resolvectl || return "$?"
      configured="$(resolvectl dns 2>/dev/null)"
      ;;
    network-manager)
      [[ "$(readlink /etc/resolv.conf 2>/dev/null)" == */run/NetworkManager/resolv.conf ]] || return 75
      configured="$(<"/etc/resolv.conf")"
      ;;
  esac
  for server in "$@"; do
    if [[ "${configured}" != *"${server}"* ]]; then
      console::_write-error "DNS server is not configured: ${server}"
      return 75
    fi
  done
  net::dns::test example.com || return 75
}

# @description Make systemd-resolved manage DNS and /etc/resolv.conf.
#
# The previous /etc/resolv.conf is kept as a backup.
#
# @noargs
# @exitcode 0 systemd-resolved manages DNS.
# @exitcode 64 An argument was given.
# @exitcode 74 /etc/resolv.conf could not be linked.
# @exitcode other The status of the service, backup, or verification step that failed.
# @example
#   net::dns::use-systemd-resolved
net::dns::use-systemd-resolved() {
  [[ "$#" -eq 0 ]] || return 64
  local link='/run/systemd/resolve/stub-resolv.conf'
  package::_enable-service systemd-resolved || return "$?"
  net::dns::_backup-resolv-conf "${link}" || return "$?"
  command::run-as-root ln -sfn "${link}" /etc/resolv.conf || return 74
  net::dns::_restart-systemd-resolved || return "$?"
  net::dns::_verify systemd-resolved
}

# @description Make NetworkManager manage DNS and /etc/resolv.conf directly.
#
# The previous /etc/resolv.conf is kept as a backup.
#
# @noargs
# @exitcode 0 NetworkManager manages DNS.
# @exitcode 64 An argument was given.
# @exitcode 69 NetworkManager is unavailable.
# @exitcode 74 The configuration or link could not be written.
# @exitcode other The status of the restart, backup, or verification step that failed.
# @example
#   net::dns::use-network-manager
net::dns::use-network-manager() {
  [[ "$#" -eq 0 ]] || return 64
  local link='/run/NetworkManager/resolv.conf'
  command::require NetworkManager || return "$?"
  command::run-as-root install -d -m 0755 /etc/NetworkManager/conf.d || return 74
  file::write-text /etc/NetworkManager/conf.d/90-bashstock-dns.conf \
    $'[main]\ndns=default\nrc-manager=symlink\n' || return "$?"
  net::dns::_restart-network-manager || return "$?"
  net::dns::_backup-resolv-conf "${link}" || return "$?"
  command::run-as-root ln -sfn "${link}" /etc/resolv.conf || return 74
  net::dns::_verify network-manager
}

# @description Configure Google Public DNS while keeping the current DNS manager.
#
# systemd-resolved receives a drop-in file, and NetworkManager receives the servers on every active connection. IPv6 servers are added only to connections with IPv6 configured.
#
# @noargs
# @stderr A message when the DNS manager is unknown.
# @exitcode 0 Google Public DNS is in use.
# @exitcode 64 An argument was given.
# @exitcode 69 The DNS manager is unknown or NetworkManager has no active connection.
# @exitcode 74 A configuration could not be written.
# @exitcode 75 A connection could not be reactivated.
# @exitcode other The status of the restart or verification step that failed.
# @example
#   net::dns::use-google && net::dns::servers
net::dns::use-google() {
  [[ "$#" -eq 0 ]] || return 64
  local manager='' connection='' connections=''
  manager="$(net::dns::_manager)" || return "$?"
  case "${manager}" in
    systemd-resolved)
      command::run-as-root install -d -m 0755 /etc/systemd/resolved.conf.d || return 74
      file::write-text /etc/systemd/resolved.conf.d/90-bashstock-google.conf \
        $'[Resolve]\nDNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844\n' || return "$?"
      net::dns::_restart-systemd-resolved || return "$?"
      ;;
    network-manager)
      connections="$(net::dns::_active-network-manager-connections)" || return "$?"
      [[ -n "${connections}" ]] || return 69
      while IFS= read -r connection; do
        local settings=(ipv4.dns '8.8.8.8 8.8.4.4' ipv4.ignore-auto-dns yes)
        # NetworkManager rejects IPv6 DNS servers unless IPv6 is configured with addresses.
        case "$(nmcli -g ipv6.method connection show "${connection}" 2>/dev/null)" in
          auto | dhcp | manual)
            settings+=(ipv6.dns '2001:4860:4860::8888 2001:4860:4860::8844' ipv6.ignore-auto-dns yes)
            ;;
        esac
        command::run-as-root nmcli connection modify "${connection}" "${settings[@]}" || return 74
        command::run-as-root nmcli connection up "${connection}" >/dev/null || return 75
      done <<<"${connections}"
      ;;
    *)
      console::_write-error 'The DNS manager is unknown; no change was made.'
      return 69
      ;;
  esac
  net::dns::_verify "${manager}" 8.8.8.8 8.8.4.4
}
