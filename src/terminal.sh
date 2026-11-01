#!/usr/bin/env bash
# @file terminal
# @brief The controlling terminal and terminal emulator windows.
# @description terminal::is-available lets interactive functions fail instead of blocking when no terminal is available.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Test whether the controlling terminal is readable and writable.
#
# @noargs
# @exitcode 0 /dev/tty can be read and written.
# @exitcode 1 There is no usable controlling terminal, as in CI or cron.
# @exitcode 64 An argument was given.
# @example
#   terminal::is-available && shell::confirm 'Continue?'
terminal::is-available() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi

  [[ -c /dev/tty && -r /dev/tty && -w /dev/tty ]]
}

# @description Open a new window of the desktop's default terminal application.
#
# macOS uses Terminal. Linux uses the first available of xdg-terminal-exec,
# x-terminal-emulator, gnome-terminal, ptyxis, konsole, and xterm, so the
# terminal that the desktop or the user selected comes first. Without COMMAND
# the window starts the user's login shell. With COMMAND, Bash runs it with its
# arguments and then stays open as an interactive shell.
#
# @arg $@ string Optional command and arguments to run in the new window.
# @exitcode 0 The terminal application opened the window.
# @exitcode 69 No supported terminal application is available, or the operating system is unsupported.
# @exitcode other The status of the terminal application.
# @example
#   terminal::open
#   terminal::open make watch
terminal::open() {
  local command_line=() quoted=''
  [[ "$#" -eq 0 ]] || command_line=(bash -c '"$@"; exec bash -i' bash "$@")
  case "$(system::operating-system)" in
    darwin)
      command::require osascript || return "$?"
      [[ "$#" -eq 0 ]] || quoted="$(printf '%q ' "${command_line[@]}")"
      osascript -e 'on run argv' -e 'tell application "Terminal"' -e 'activate' \
        -e 'do script (item 1 of argv)' -e 'end tell' -e 'end run' "${quoted% }" >/dev/null
      ;;
    linux)
      if command -v xdg-terminal-exec >/dev/null 2>&1; then
        xdg-terminal-exec ${command_line[@]+"${command_line[@]}"}
      elif command -v x-terminal-emulator >/dev/null 2>&1; then
        x-terminal-emulator ${command_line[@]+-e "${command_line[@]}"}
      elif command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal ${command_line[@]+-- "${command_line[@]}"}
      elif command -v ptyxis >/dev/null 2>&1; then
        ptyxis ${command_line[@]+-- "${command_line[@]}"}
      elif command -v konsole >/dev/null 2>&1; then
        konsole ${command_line[@]+-e "${command_line[@]}"}
      elif command -v xterm >/dev/null 2>&1; then
        xterm ${command_line[@]+-e "${command_line[@]}"}
      else
        console::_write-error 'No supported terminal application is available.'
        return 69
      fi
      ;;
    *) return 69 ;;
  esac
}
