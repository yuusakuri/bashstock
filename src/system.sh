#!/usr/bin/env bash
# @file system
# @brief Operating-system identity, sleep, and screen-lock settings.
# @description Values are normalized so that callers can branch on them without parsing uname output.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Write the normalized operating-system family.
#
# @noargs
# @stdout darwin, linux, or unknown.
# @exitcode 0 The family was written.
# @exitcode 64 An argument was given.
# @example
#   [[ "$(system::operating-system)" == darwin ]] && brew --version
system::operating-system() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  case "${OSTYPE:-}" in
    darwin*)
      printf 'darwin\n'
      ;;
    linux*)
      printf 'linux\n'
      ;;
    *)
      printf 'unknown\n'
      ;;
  esac
}

# @description Write the current host name.
#
# HOSTNAME is used when set; otherwise the hostname command is asked.
#
# @noargs
# @stdout The host name.
# @exitcode 0 The host name was written.
# @exitcode 1 The host name cannot be determined.
# @exitcode 64 An argument was given.
# @example
#   printf 'Running on %s\n' "$(system::host-name)"
system::host-name() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  if [[ -n "${HOSTNAME:-}" ]]; then
    printf '%s\n' "${HOSTNAME}"
    return 0
  fi

  local value=''
  if ! command -v hostname >/dev/null 2>&1; then
    return 1
  fi
  if ! value="$(hostname 2>/dev/null)" || [[ -z "${value}" ]]; then
    return 1
  fi
  printf '%s\n' "${value}"
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
