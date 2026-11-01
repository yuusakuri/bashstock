#!/usr/bin/env bash
# @file gnome
# @brief GNOME desktop settings.
# @description Settings are written with gsettings.

# shellcheck disable=SC2119,SC2120

# @description Register a GNOME custom keyboard shortcut after removing conflicting shortcuts.
#
# Conflicts are shortcuts with the same name, or with the same command and binding.
#
# @arg $1 string Identifier used in the shortcut path, such as custom100.
# @arg $2 string Descriptive shortcut name.
# @arg $3 string Command that GNOME runs.
# @arg $4 string Key combination, such as <Alt>a.
# @exitcode 0 The shortcut was registered.
# @exitcode 64 The identifier is malformed or another argument is empty.
# @exitcode 74 A value could not be quoted for gsettings.
# @exitcode other The status of gsettings.
# @example
#   gnome::keybinding::set-custom custom100 Terminal gnome-terminal '<Super>Return'
gnome::keybinding::set-custom() {
  ( [[ "$#" -eq 4 && "$1" =~ ^[A-Za-z0-9_-]+$ && -n "$2" && -n "$3" && -n "$4" ]] ) || return 64
  local schema='org.gnome.settings-daemon.plugins.media-keys'
  local item_schema="${schema}.custom-keybinding"
  local base='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'
  local binding_paths='' path='' name='' command='' binding='' target=''
  binding_paths="$(gsettings::_string-array-values "${schema}" custom-keybindings)" || return "$?"
  target="${base}$1/"
  while IFS= read -r path; do
    [[ -n "${path}" ]] || continue
    name="$(gsettings::_string-value "${item_schema}:${path}" name)" || return "$?"
    command="$(gsettings::_string-value "${item_schema}:${path}" command)" || return "$?"
    binding="$(gsettings::_string-value "${item_schema}:${path}" binding)" || return "$?"
    if [[ "${name}" == "$2" || ("${command}" == "$3" && "${binding}" == "$4") ]]; then
      gsettings::string-array::remove "${schema}" custom-keybindings "${path}" || return "$?"
    fi
  done <<<"${binding_paths}"
  local key='' value='' quoted=''
  for key in name command binding; do
    case "${key}" in
      name) value="$2" ;;
      command) value="$3" ;;
      binding) value="$4" ;;
    esac
    quoted="$(gsettings::_quote "${value}")" || return "$?"
    gsettings set "${item_schema}:${target}" "${key}" "${quoted}" || return 74
  done
  gsettings::string-array::add "${schema}" custom-keybindings "${target}"
}

# @description Set GNOME input sources to Mozc followed by one XKB layout.
#
# @arg $1 string XKB layout, such as us or jp.
# @exitcode 0 The input sources were set.
# @exitcode 64 The layout is malformed, or the argument count is not one.
# @exitcode 69 gsettings is unavailable.
# @exitcode other The status of gsettings.
# @example
#   gnome::input-source::set-layout us
gnome::input-source::set-layout() {
  [[ "$#" -eq 1 ]] || return 64
  keyboard::_require-layout "$1" || return "$?"
  command::require gsettings || return "$?"
  gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'mozc-jp'), ('xkb', '$1')]"
}

# @description Set GNOME input sources and the system keyboard layout to Mozc and US.
#
# @noargs
# @exitcode 0 The layouts were set.
# @exitcode 64 An argument was given.
# @exitcode 69 gsettings or the system layout tool is unavailable.
# @exitcode other The status of gsettings or the system layout update.
# @example
#   gnome::keyboard-layout::set-us
gnome::keyboard-layout::set-us() {
  [[ "$#" -eq 0 ]] || return 64
  gnome::input-source::set-layout us || return "$?"
  keyboard::system-layout::set us
}

# @description Set GNOME input sources and the system keyboard layout to Mozc and JP.
#
# @noargs
# @exitcode 0 The layouts were set.
# @exitcode 64 An argument was given.
# @exitcode 69 gsettings or the system layout tool is unavailable.
# @exitcode other The status of gsettings or the system layout update.
# @example
#   gnome::keyboard-layout::set-jp
gnome::keyboard-layout::set-jp() {
  [[ "$#" -eq 0 ]] || return 64
  gnome::input-source::set-layout jp || return "$?"
  keyboard::system-layout::set jp
}

# @description List the named arguments for gnome::input-source::set-shortcuts.
# @internal
gnome::input-source::_set-shortcuts-args() {
  case "${1-}" in
    '')
      printf '%s\n' --next --previous --us --mozc
      ;;
  esac
}

# @description Set GNOME input-source switching shortcuts and direct US and Mozc shortcuts.
#
# The direct shortcuts are custom keyboard shortcuts that activate the US layout
# or Mozc regardless of the current source.
#
# @option --next <BINDING> Next input source. Defaults to <Alt>grave.
# @option --previous <BINDING> Previous input source. Defaults to <Shift><Alt>grave.
# @option --us <BINDING> Switch to the US layout. Defaults to <Alt>semicolon.
# @option --mozc <BINDING> Switch to Mozc. Defaults to <Alt>a.
# @exitcode 0 The shortcuts were set.
# @exitcode 64 An option is unknown or has no value.
# @exitcode 74 A binding could not be quoted for gsettings.
# @exitcode other The status of gsettings.
# @example
#   gnome::input-source::set-shortcuts --us '<Alt>u' --mozc '<Alt>j'
gnome::input-source::set-shortcuts() {
  local next='<Alt>grave'
  local previous='<Shift><Alt>grave'
  local us='<Alt>semicolon'
  local mozc='<Alt>a'
  local quoted=''
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --next | --previous | --us | --mozc)
        arg::require-next "$#" "$1" || return "$?"
        case "$1" in
          --next) next="$2" ;;
          --previous) previous="$2" ;;
          --us) us="$2" ;;
          --mozc) mozc="$2" ;;
        esac
        shift 2
        ;;
      *)
        arg::unknown "$1" || return "$?"
        ;;
    esac
  done
  arg::require --next "${next}" || return "$?"
  arg::require --previous "${previous}" || return "$?"
  arg::require --us "${us}" || return "$?"
  arg::require --mozc "${mozc}" || return "$?"
  command::require gsettings || return "$?"
  quoted="$(gsettings::_quote "${next}")" || return "$?"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[${quoted}]" || return 74
  quoted="$(gsettings::_quote "${previous}")" || return "$?"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[${quoted}]" || return 74
  gnome::keybinding::set-custom custom100 'Disable IME (US Layout)' "ibus engine 'xkb:us::eng'" "${us}" || return "$?"
  gnome::keybinding::set-custom custom101 'Enable IME (Mozc)' "ibus engine 'mozc-jp'" "${mozc}"
}

# @description Write the first XKB layout from GNOME input sources.
# @internal
gnome::input-source::_first-layout() {
  [[ "$#" -eq 0 ]] || return 64
  command::require gsettings || return "$?"
  local sources='' pattern="\('xkb', '([^']+)'\)"
  sources="$(gsettings get org.gnome.desktop.input-sources sources)" || return 74
  # The capture is read in a subshell so that the caller's BASH_REMATCH is kept.
  ( [[ "${sources}" =~ ${pattern} ]] && printf '%s\n' "${BASH_REMATCH[1]}" )
}

# @description Put Mozc first in GNOME input sources while keeping the current XKB layout.
#
# @noargs
# @exitcode 0 The input sources were set.
# @exitcode 1 The current input sources have no XKB layout; nothing was changed.
# @exitcode 64 An argument was given.
# @exitcode 69 gsettings is unavailable.
# @exitcode 74 gsettings could not read the current input sources.
# @exitcode other The status of gsettings.
# @example
#   gnome::input-source::set-mozc-first
gnome::input-source::set-mozc-first() {
  [[ "$#" -eq 0 ]] || return 64
  local layout=''
  layout="$(gnome::input-source::_first-layout)" || return "$?"
  gnome::input-source::set-layout "${layout}"
}

# @description Set the GNOME window title-bar button layout.
#
# @arg $1 string Optional button layout. Defaults to appmenu:minimize,maximize,close.
# @exitcode 0 The layout was set.
# @exitcode 64 The layout has characters other than lowercase letters, commas, and colons.
# @exitcode 69 gsettings is unavailable.
# @exitcode other The status of gsettings.
# @example
#   gnome::window::set-button-layout close,minimize,maximize:
gnome::window::set-button-layout() {
  [[ "$#" -le 1 ]] || return 64
  local layout="${1:-appmenu:minimize,maximize,close}"
  ( [[ "${layout}" =~ ^[a-z,:]*$ ]] ) || return 64
  command::require gsettings || return "$?"
  gsettings set org.gnome.desktop.wm.preferences button-layout "${layout}"
}
