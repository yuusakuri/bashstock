#!/usr/bin/env bash
# @file desktop
# @brief GNOME and macOS desktop and keyboard settings.
# @description GNOME settings use gsettings and macOS settings use defaults.

# shellcheck disable=SC2119,SC2120

# @description Write the elements of a GVariant string array, one per line.
#
# The value is parsed as GVariant text, so quoted commas and escapes are kept.
# @internal
gsettings::_parse-string-array() {
  [[ "$#" -eq 1 ]] || return 64
  command::require perl || return "$?"
  perl -e '
    my $text = shift;
    $text =~ s/^\s*\@as\s+//;
    $text =~ s/^\s+|\s+$//g;
    exit 65 unless $text =~ s/^\[// && $text =~ s/\]$//;
    my @values;
    while (length $text) {
      $text =~ s/^\s+//;
      last unless length $text;
      if ($text =~ s/^(["\x27])((?:\\.|(?!\1).)*)\1//s) {
        my $value = $2;
        $value =~ s/\\(.)/$1/g;
        exit 65 if $value =~ /\n/;
        push @values, $value;
      } else {
        exit 65;
      }
      $text =~ s/^\s*//;
      last unless length $text;
      exit 65 unless $text =~ s/^,//;
    }
    print "$_\n" for @values;
  ' "$1"
}

# @description Write one value as a single-quoted GVariant string literal.
# @internal
gsettings::_quote() {
  [[ "$#" -eq 1 && "$1" != *$'\n'* ]] || return 64
  command::require perl || return "$?"
  perl -e 'my $value = shift; $value =~ s/([\\\x27])/\\$1/g; print "\x27$value\x27\n";' "$1"
}

# @description Write lines from standard input as a GVariant string array.
# @internal
gsettings::_format-string-array() {
  [[ "$#" -eq 0 ]] || return 64
  local line='' quoted='' result='' separator=''
  while IFS= read -r line; do
    quoted="$(gsettings::_quote "${line}")" || return "$?"
    result+="${separator}${quoted}"
    separator=', '
  done
  printf '[%s]\n' "${result}"
}

# @description Require a GSettings key to hold a string array.
# @internal
gsettings::_require-string-array() {
  [[ "$#" -eq 2 && -n "$1" && -n "$2" ]] || return 64
  command::require gsettings || return "$?"
  local range=''
  range="$(gsettings range "$1" "$2" 2>/dev/null)" || return 66
  [[ "${range}" == 'type as' ]] || return 65
}

# @description Write the elements of a GSettings string array, one per line.
# @internal
gsettings::_string-array-values() {
  [[ "$#" -eq 2 ]] || return 64
  gsettings::_require-string-array "$1" "$2" || return "$?"
  local value=''
  value="$(gsettings get "$1" "$2")" || return 74
  gsettings::_parse-string-array "${value}"
}

# @description Add a literal value to a GSettings string array when it is absent.
#
# @arg $1 string GSettings schema, such as org.gnome.shell.
# @arg $2 string Key that holds a string array.
# @arg $3 string Value to add; it must not be empty or contain a newline.
# @exitcode 0 The value is in the array.
# @exitcode 64 The value is empty or contains a newline, or the argument count is not three.
# @exitcode other The status of gsettings.
# @example
#   gsettings::string-array::add org.gnome.shell favorite-apps code.desktop
gsettings::string-array::add() {
  [[ "$#" -eq 3 && -n "$3" && "$3" != *$'\n'* ]] || return 64
  local array_values='' array=''
  array_values="$(gsettings::_string-array-values "$1" "$2")" || return "$?"
  if [[ -n "${array_values}" ]] && printf '%s\n' "${array_values}" | grep -Fqx -- "$3"; then
    return 0
  fi
  array="$( (
    [[ -z "${array_values}" ]] || printf '%s\n' "${array_values}"
    printf '%s\n' "$3"
  ) | gsettings::_format-string-array)" || return "$?"
  gsettings set "$1" "$2" "${array}"
}

# @description Remove every element equal to a literal value from a GSettings string array.
#
# @arg $1 string GSettings schema.
# @arg $2 string Key that holds a string array.
# @arg $3 string Value to remove.
# @exitcode 0 The value is no longer in the array.
# @exitcode 64 The value is empty or contains a newline, or the argument count is not three.
# @exitcode other The status of gsettings.
# @example
#   gsettings::string-array::remove org.gnome.shell favorite-apps firefox.desktop
gsettings::string-array::remove() {
  [[ "$#" -eq 3 && -n "$3" && "$3" != *$'\n'* ]] || return 64
  local array_values='' value='' array=''
  array_values="$(gsettings::_string-array-values "$1" "$2")" || return "$?"
  array="$(while IFS= read -r value; do
    [[ -z "${array_values}" || "${value}" == "$3" ]] || printf '%s\n' "${value}"
  done <<<"${array_values}" | gsettings::_format-string-array)" || return "$?"
  gsettings set "$1" "$2" "${array}"
}

# @description Write the GSettings string value of one key without GVariant quotes.
# @internal
gsettings::_string-value() {
  [[ "$#" -eq 2 ]] || return 64
  command::require gsettings || return "$?"
  local value=''
  value="$(gsettings get "$1" "$2")" || return 74
  gsettings::_parse-string-array "[${value}]"
}

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

# @description Require a keyboard layout name accepted by XKB.
# @internal
keyboard::_require-layout() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[a-z][a-z0-9_]*(\+[A-Za-z0-9_-]+)?$ ]] ) || return 64
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

# @description Set the system keyboard layout.
#
# Ubuntu replaces or appends XKBLAYOUT in /etc/default/keyboard. Other systems
# use localectl.
#
# @arg $1 string XKB layout, such as us or jp.
# @exitcode 0 The layout was set.
# @exitcode 64 The layout is malformed, or the argument count is not one.
# @exitcode 69 Neither /etc/default/keyboard nor localectl is available.
# @exitcode other The status of the file update or localectl.
# @example
#   keyboard::system-layout::set us
keyboard::system-layout::set() {
  [[ "$#" -eq 1 ]] || return 64
  keyboard::_require-layout "$1" || return "$?"
  if [[ -f /etc/default/keyboard ]]; then
    file::replace-text-or-append /etc/default/keyboard '^XKBLAYOUT=.*$' "XKBLAYOUT=\"$1\""
    return
  fi
  command::require localectl || return "$?"
  command::run-as-root localectl set-x11-keymap "$1"
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

# @description Start Mozc in Hiragana mode and restart IBus.
#
# active_on_launch is set to True in ~/.config/mozc/ibus_config.textproto.
#
# @noargs
# @exitcode 0 Mozc starts in Hiragana mode from now on.
# @exitcode 64 An argument was given.
# @exitcode 69 Perl or ibus-daemon is unavailable.
# @exitcode 74 The configuration file could not be created.
# @exitcode other The status of the settings update or ibus-daemon.
# @example
#   mozc::ibus::set-hiragana-as-default
mozc::ibus::set-hiragana-as-default() {
  [[ "$#" -eq 0 ]] || return 64
  local file="${HOME}/.config/mozc/ibus_config.textproto"
  mkdir -p -- "$(path::directory-name "${file}")" || return 74
  [[ -e "${file}" ]] || : >"${file}" || return 74
  textproto::set-scalar "${file}" active_on_launch True || return "$?"
  command::require ibus-daemon || return "$?"
  ibus-daemon -rd
}

# @description Map the Convert and Nonconvert keys of USB keyboards to henkan and muhenkan.
#
# KC_INT4 (HID usage 0x7008A, Convert) becomes henkan and KC_INT5 (HID usage
# 0x7008B, Nonconvert) becomes muhenkan, as in the reference script. The input
# method handles the keys; this function does not change IME settings. The
# hwdb entry applies to every USB keyboard, or only to the keyboard identified
# by VENDOR_ID and PRODUCT_ID.
#
# @arg $1 string Optional vendor ID as four hexadecimal digits. Requires PRODUCT_ID.
# @arg $2 string Optional product ID as four hexadecimal digits. Requires VENDOR_ID.
# @exitcode 0 The hwdb entry was written and applied.
# @exitcode 64 An ID is malformed, or only one ID was given.
# @exitcode 69 The system is not Linux, or systemd-hwdb or udevadm is unavailable.
# @exitcode other The status of the file write, systemd-hwdb, or udevadm.
# @example
#   keyboard::setup-ime-keys 4653 0001
keyboard::setup-ime-keys() {
  [[ "$#" -eq 0 || "$#" -eq 2 ]] || return 64
  local match='evdev:input:b0003v*p*' content=''
  if [[ "$#" -eq 2 ]]; then
    ( [[ "$1" =~ ^[0-9A-Fa-f]{4}$ && "$2" =~ ^[0-9A-Fa-f]{4}$ ]] ) || return 64
    match="evdev:input:b0003v$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')p$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')*"
  fi
  [[ "$(system::operating-system)" == 'linux' ]] || return 69
  command::require systemd-hwdb || return "$?"
  command::require udevadm || return "$?"
  content='# Managed by BashStock keyboard::setup-ime-keys.'$'\n'"${match}"$'\n'
  content+=' KEYBOARD_KEY_7008a=henkan'$'\n'' KEYBOARD_KEY_7008b=muhenkan'$'\n'
  file::write-text /etc/udev/hwdb.d/90-bashstock-ime-keys.hwdb "${content}" || return "$?"
  command::run-as-root systemd-hwdb update || return "$?"
  command::run-as-root udevadm trigger --subsystem-match=input --action=change
}

# @description Run one setup step, report a failure, and return its status.
# @internal
setup::_run-step() {
  [[ "$#" -ge 1 ]] || return 64
  "$@"
  local status="$?"
  [[ "${status}" -eq 0 ]] || console::_write-error "Setup step failed with status ${status}: $*"
  return "${status}"
}

# @description Create an empty file when it does not exist.
#
# The new file gets the given mode whatever the caller's umask is.
# @internal
# @arg $1 string File path.
# @arg $2 string Optional octal mode of a new file. Defaults to 0644.
setup::_ensure-file() {
  [[ ( "$#" -eq 1 || "$#" -eq 2 ) && -n "$1" && "${2:-0644}" =~ ^0[0-7]{3}$ ]] || return 64
  if [[ ! -e "$1" ]]; then
    (umask 077 && : >"$1") && chmod "${2:-0644}" "$1" || return 74
  fi
  [[ -f "$1" ]] || return 66
}

# @description Apply the common Ubuntu user configuration, stopping at the first failure.
#
# Missing curl and Git are installed first. The steps then register ~/.env, set
# the editor to code --wait, ignore case in completion, link English names to
# localized user directories, add the user to dialout, configure Git with Git
# Credential Manager, fix ~/.ssh permissions, and install external tools.
#
# @noargs
# @stderr The step that failed.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of the first step that failed.
# @example
#   GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' ubuntu::setup
ubuntu::setup() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local missing_packages=()
  command::exists curl || missing_packages+=(curl)
  command::exists git || missing_packages+=(git)
  if [[ "${#missing_packages[@]}" -gt 0 ]]; then
    setup::_run-step package::_install "${missing_packages[@]}" || return "$?"
  fi
  # ~/.env holds secrets, so only the user may read a new one.
  setup::_ensure-file "${HOME}/.env" 0600 || return "$?"
  setup::_run-step env::dotenv::register "${HOME}/.env" || return "$?"
  setup::_run-step shell::editor::set-default 'code --wait' || return "$?"
  setup::_run-step shell::completion::enable-ignore-case || return "$?"
  setup::_run-step user::directory::create-english-links || return "$?"
  setup::_run-step user::add-to-group dialout || return "$?"
  setup::_run-step git::config::setup || return "$?"
  setup::_run-step git::config::use-credential-manager || return "$?"
  setup::_run-step ssh::setup-directory || return "$?"
  ubuntu::setup-external
}

# @description Install GnuPG and GitHub CLI when they are not already available.
#
# GitHub CLI is installed from its official Ubuntu APT repository after checking
# the repository key against GitHub's published fingerprints.
#
# @noargs
# @exitcode 0 The missing tools were installed or were already available.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu, or a required command is missing.
# @exitcode 77 sudo refused the credentials.
# @exitcode other A package installation or repository setup failed.
# @example
#   ubuntu::setup-external
ubuntu::setup-external() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  if ! command::exists gpg; then
    setup::_run-step package::_install gnupg || return "$?"
  fi
  if ! command::exists gh; then
    setup::_run-step gh::install || return "$?"
  fi
}

# @description Apply the Ubuntu user configuration and desktop settings, stopping at the first failure.
#
# After ubuntu::setup, the IME keys, Mozc and US input sources, Hiragana
# start, and VLC as the video application are set.
#
# @noargs
# @stderr The step that failed.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu.
# @exitcode other The status of the first step that failed.
# @example
#   ubuntu::setup-desktop
ubuntu::setup-desktop() {
  [[ "$#" -eq 0 ]] || return 64
  ubuntu::setup || return "$?"
  setup::_run-step keyboard::setup-ime-keys || return "$?"
  setup::_run-step gnome::input-source::set-mozc-first || return "$?"
  setup::_run-step gnome::keyboard-layout::set-us || return "$?"
  setup::_run-step mozc::ibus::set-hiragana-as-default || return "$?"
  setup::_run-step vlc::set-default-app
}

# @description Install the newest Mozc for Ubuntu 22.04 and apply the desktop settings.
#
# The window button layout is also set as on Ubuntu 22.04's reference setup.
#
# @noargs
# @stderr The step that failed, or a message on other releases.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu 22.04.
# @exitcode other The status of the first step that failed.
# @example
#   ubuntu::setup-desktop-22
ubuntu::setup-desktop-22() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local version=''
  version="$(platform::_os-release-value VERSION_ID)" || return "$?"
  if [[ "${version}" != '22.04' ]]; then
    console::_write-error 'This setup supports only Ubuntu 22.04.'
    return 69
  fi
  setup::_run-step mozc::server::install || return "$?"
  setup::_run-step mozc::ibus::install || return "$?"
  ubuntu::setup-desktop || return "$?"
  setup::_run-step gnome::window::set-button-layout
}

# @description Install Homebrew with the official installer when it is missing.
#
# The new Zsh sessions read brew shellenv from .zshrc, and the current
# process finds brew on PATH afterwards. The prefix is /opt/homebrew on Apple
# silicon and /usr/local on Intel Macs.
#
# @noargs
# @exitcode 0 Homebrew is installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode 74 The installer could not be downloaded.
# @exitcode other The status of the official installer.
# @example
#   homebrew::install
#   brew --version
homebrew::install() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command -v brew >/dev/null 2>&1 && return 0
  local directory='' status=0
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
    "${directory}/install.sh" || status="$?"
  [[ "${status}" -ne 0 ]] || /bin/bash "${directory}/install.sh" || status="$?"
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  local prefix=/opt/homebrew
  [[ -x "${prefix}/bin/brew" ]] || prefix=/usr/local
  setup::_ensure-file "${HOME}/.zshrc" || return "$?"
  file::replace-text-or-append "${HOME}/.zshrc" '^.*brew shellenv.*$' \
    "eval \"\$(${prefix}/bin/brew shellenv)\"" || return "$?"
  PATH="${prefix}/bin:${prefix}/sbin:${PATH}"
  export PATH
}

# @description Install Homebrew casks without the quarantine attribute from now on.
#
# HOMEBREW_CASK_OPTS=--no-quarantine is written to the Bash and Zsh startup files
# and exported to the current process.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 74 A startup file could not be written.
# @example
#   homebrew::cask::disable-quarantine
homebrew::cask::disable-quarantine() {
  [[ "$#" -eq 0 ]] || return 64
  env::set-variable HOMEBREW_CASK_OPTS --no-quarantine
}

# @description Allow comments that start with # in interactive Zsh sessions.
#
# setopt interactivecomments is written to ~/.zshrc once.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 74 ~/.zshrc could not be written.
# @example
#   shell::zsh::enable-interactive-comments
shell::zsh::enable-interactive-comments() {
  [[ "$#" -eq 0 ]] || return 64
  setup::_ensure-file "${HOME}/.zshrc" || return "$?"
  file::replace-text-or-append "${HOME}/.zshrc" '^setopt interactivecomments.*$' 'setopt interactivecomments'
}

# @description Let the Mac wake from sleep through the network (Wake on LAN).
#
# @noargs
# @exitcode 0 Wake on LAN is enabled.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of pmset.
# @example
#   mac::wake-on-lan::enable
mac::wake-on-lan::enable() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root pmset -a womp 1
}

# @description Disable automatic system sleep while preserving display sleep timers.
#
# @noargs
# @exitcode 0 Automatic system sleep is disabled.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS or pmset is unavailable.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of pmset.
# @example
#   mac::sleep::disable-automatic
mac::sleep::disable-automatic() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require pmset || return "$?"
  command::run-as-root pmset -a sleep 0
}

# @description Enable automatic system sleep after ten minutes while preserving display sleep timers.
#
# @noargs
# @exitcode 0 Automatic system sleep is enabled with a ten-minute timer.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS or pmset is unavailable.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of pmset.
# @example
#   mac::sleep::enable-automatic
mac::sleep::enable-automatic() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require pmset || return "$?"
  command::run-as-root pmset -a sleep 10
}

# @description Let macOS updates install automatically.
#
# Automatic downloads and system data and security update settings stay unchanged.
# The automatic macOS installation preference is enabled for all users.
#
# @noargs
# @exitcode 0 Automatic macOS installation is enabled.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults or the root command.
# @example
#   mac::software-update::enable-automatic-install
mac::software-update::enable-automatic-install() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root defaults write /Library/Preferences/com.apple.SoftwareUpdate \
    AutomaticallyInstallMacOSUpdates -bool true
}

# @description Keep macOS updates downloading but stop their automatic installation.
#
# Automatic downloads and system data and security update settings stay unchanged.
# The automatic macOS installation preference is disabled for all users.
#
# @noargs
# @exitcode 0 Automatic macOS installation is disabled.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults or the root command.
# @example
#   mac::software-update::disable-automatic-install
mac::software-update::disable-automatic-install() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root defaults write /Library/Preferences/com.apple.SoftwareUpdate \
    AutomaticallyInstallMacOSUpdates -bool false
}

# @description Make F1 to F12 act as function keys without the fn key.
#
# @noargs
# @exitcode 0 The setting was written.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::keyboard::use-function-keys
mac::keyboard::use-function-keys() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
}

# @description Set the delay before key repeat starts and the repeat interval.
#
# The new values apply after logging in again.
#
# @arg $1 integer Optional delay before repeating, in units of 15 ms. Defaults to 30.
# @arg $2 integer Optional interval between repeats, in units of 15 ms. Defaults to 1.
# @exitcode 0 The settings were written.
# @exitcode 64 A value is not a non-negative integer.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::keyboard::set-repeat 15 2
mac::keyboard::set-repeat() {
  [[ "$#" -le 2 ]] || return 64
  local initial="${1:-30}" repeat="${2:-1}"
  ( [[ "${initial}" =~ ^[0-9]+$ && "${repeat}" =~ ^[0-9]+$ ]] ) || return 64
  package::_require-platform darwin || return "$?"
  defaults write NSGlobalDomain InitialKeyRepeat -int "${initial}" || return "$?"
  defaults write NSGlobalDomain KeyRepeat -int "${repeat}"
}

# @description Turn off smart zoom, the two-finger double tap, on built-in and external trackpads.
#
# @noargs
# @exitcode 0 The settings were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::trackpad::disable-smart-zoom
mac::trackpad::disable-smart-zoom() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 0 ||
    return "$?"
  defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 0 || return "$?"
  defaults write NSGlobalDomain com.apple.trackpad.twoFingerDoubleTapGesture -int 0
}

# @description Restart the Dock so that it reads changed preferences.
# @internal
mac::dock::_restart() {
  [[ "$#" -eq 0 ]] || return 64
  killall Dock >/dev/null 2>&1 || true
}

# @description Show and hide the Dock immediately, without a delay or an animation.
#
# The Dock restarts to apply the change.
#
# @noargs
# @exitcode 0 The settings were applied.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::dock::set-autohide-instant
mac::dock::set-autohide-instant() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock autohide-time-modifier -float 0 || return "$?"
  defaults write com.apple.dock autohide-delay -float 0 || return "$?"
  mac::dock::_restart
}

# @description Hide recently used applications in the Dock.
#
# @noargs
# @exitcode 0 The setting was applied.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::dock::hide-recent-applications
mac::dock::hide-recent-applications() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock show-recents -bool false || return "$?"
  mac::dock::_restart
}

# @description Set the effect used when a window is minimized into the Dock.
#
# @arg $1 string Optional effect: genie, scale, or suck. Defaults to scale.
# @exitcode 0 The setting was applied.
# @exitcode 64 The effect is not genie, scale, or suck.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::dock::set-minimize-effect genie
mac::dock::set-minimize-effect() {
  [[ "$#" -le 1 ]] || return 64
  local effect="${1:-scale}"
  [[ "${effect}" == genie || "${effect}" == scale || "${effect}" == suck ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock mineffect -string "${effect}" || return "$?"
  mac::dock::_restart
}

# @description Place the Dock on one edge of the screen.
#
# @arg $1 string Optional position: left, bottom, or right. Defaults to left.
# @exitcode 0 The setting was applied.
# @exitcode 64 The position is not left, bottom, or right.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of defaults.
# @example
#   mac::dock::set-position bottom
mac::dock::set-position() {
  [[ "$#" -le 1 ]] || return 64
  local position="${1:-left}"
  [[ "${position}" == left || "${position}" == bottom || "${position}" == right ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock orientation -string "${position}" || return "$?"
  mac::dock::_restart
}

# @description Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications.
#
# GarageBand's sound library is removed with it. Missing applications are skipped.
#
# @noargs
# @exitcode 0 The applications are gone.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of rm.
# @example
#   mac::applications::remove-bundled
mac::applications::remove-bundled() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root rm -rf -- \
    /Applications/iMovie.app \
    /Applications/Pages.app \
    /Applications/GarageBand.app \
    '/Library/Application Support/GarageBand' \
    '/Library/Audio/Apple Loops/Apple/Apple Loops for GarageBand' \
    "${HOME}/Library/Application Support/GarageBand" \
    '/Library/Audio/Apple Loops' \
    /Applications/Keynote.app \
    /Applications/Numbers.app
}

# @description Remove the quarantine attribute from everything below /Applications.
#
# Errors for files without the attribute are ignored.
#
# @noargs
# @exitcode 0 The attributes were removed.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @example
#   mac::quarantine::remove-applications
mac::quarantine::remove-applications() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  # Files without the attribute make xattr report errors, which are not failures here.
  command::run-as-root xattr -r -d com.apple.quarantine /Applications 2>/dev/null || true
}

# @description Write the programs that Full Disk Access must list for a command, a path, or an application.
#
# Symbolic links are resolved, and a file inside an application bundle is
# written as the bundle, because System Settings lists bundles. A Python
# framework build re-executes as Python.app, so that bundle is written too.
# A name that is neither a path nor a command is looked up as an application
# in /Applications, /System/Applications, their Utilities folders, and
# ~/Applications.
#
# @arg $1 string A command name, a path, or an application name such as Terminal.
# @stdout The absolute paths to add to Full Disk Access, one per line.
# @exitcode 0 The paths were written.
# @exitcode 1 No command or application has the name.
# @exitcode 64 The argument count is not one or the argument is empty.
# @exitcode 66 The path does not exist.
# @exitcode 69 readlink is unavailable.
# @example
#   mac::full-disk-access::target-paths python3.12
#   mac::full-disk-access::target-paths Terminal
mac::full-disk-access::target-paths() {
  [[ "$#" -eq 1 && -n "$1" && "$1" != *$'\n'* ]] || return 64
  local target='' directory='' bundle=''
  if [[ "$1" == */* ]]; then
    target="$1"
  elif ! target="$(type -P -- "$1")"; then
    target=''
    for directory in /Applications /Applications/Utilities /System/Applications \
      /System/Applications/Utilities "${HOME}/Applications"; do
      if [[ -d "${directory}/${1%.app}.app" ]]; then
        target="${directory}/${1%.app}.app"
        break
      fi
    done
    [[ -n "${target}" ]] || return 1
  fi
  [[ -e "${target}" ]] || return 66
  command::require readlink || return "$?"
  target="$(readlink -f -- "${target}")" || return 66

  case "${target}" in
    *.app/*)
      target="${target%%.app/*}.app"
      ;;
    */Python.framework/Versions/*/bin/*)
      bundle="${target%/bin/*}/Resources/Python.app"
      [[ -d "${bundle}" ]] || bundle=''
      ;;
  esac
  printf '%s\n' "${target}"
  [[ -z "${bundle}" ]] || printf '%s\n' "${bundle}"
}

# @description Test whether a program has an ad hoc code signature.
# @internal
mac::full-disk-access::_is-ad-hoc-signed() {
  [[ "$#" -eq 1 ]] || return 64
  command -v codesign >/dev/null 2>&1 || return 1
  local details=''
  details="$(codesign -dv "$1" 2>&1)" || return 1
  [[ $'\n'"${details}" == *$'\nSignature=adhoc'* ]]
}

# @description Open Full Disk Access in System Settings and show the programs to add in Finder.
#
# macOS grants Full Disk Access only through System Settings, so the function
# opens the list and reveals each program for dragging into it. A program with
# an ad hoc signature, such as a Homebrew build, loses the access when an
# update replaces it, which the function reports.
#
# @arg $@ string Optional command names, paths, or application names.
# @stderr Each program to add and a note for each ad hoc signed program.
# @exitcode 0 System Settings opened.
# @exitcode 1 No command or application has one of the names.
# @exitcode 64 An argument is empty.
# @exitcode 66 A path does not exist.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of open.
# @example
#   mac::full-disk-access::open python3.12 Terminal
mac::full-disk-access::open() {
  package::_require-platform darwin || return "$?"
  local name='' output='' path=''
  local paths=()
  for name in "$@"; do
    output="$(mac::full-disk-access::target-paths "${name}")" || return "$?"
    while IFS= read -r path; do
      paths+=("${path}")
    done <<<"${output}"
  done

  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles' || return "$?"
  for path in ${paths[@]+"${paths[@]}"}; do
    console::_write-error "Add to Full Disk Access: ${path}"
    if mac::full-disk-access::_is-ad-hoc-signed "${path}"; then
      console::_write-error "Ad hoc signed, so an update removes the access: ${path}"
    fi
    open -R "${path}" || return "$?"
  done
}

# @description Test whether the application that runs the current shell has Full Disk Access.
#
# macOS usually checks the application that started the shell, such as
# Terminal, so the result also applies to the programs the shell starts. The
# test opens the user's privacy database, which only Full Disk Access permits.
#
# @noargs
# @exitcode 0 Full Disk Access is granted.
# @exitcode 1 Full Disk Access is not granted.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @example
#   mac::full-disk-access::is-granted || mac::full-disk-access::open Terminal
mac::full-disk-access::is-granted() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  { : <"${HOME}/Library/Application Support/com.apple.TCC/TCC.db"; } 2>/dev/null
}

# @description Ask macOS to allow applications from anywhere and open Privacy & Security.
#
# Recent macOS releases apply spctl --master-disable only after the user
# selects "Allow applications from anywhere" in System Settings, so a refusal
# from spctl is not a failure; the function opens the settings for that step.
#
# @noargs
# @stderr The step to take in System Settings.
# @exitcode 0 System Settings opened at Privacy & Security.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of open.
# @example
#   mac::gatekeeper::disable
mac::gatekeeper::disable() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root spctl --master-disable 2>/dev/null || true
  console::_write-error 'Select "Allow applications from anywhere" in Privacy & Security.'
  killall 'System Settings' >/dev/null 2>&1 || true
  sleep 1
  open 'x-apple.systempreferences:com.apple.settings.PrivacySecurity'
}

# @description Apply the complete macOS setup, continuing after failed steps.
#
# sudo is first made passwordless for the current user and stays so after
# the setup. The setup removes bundled applications, removes quarantine
# attributes below /Applications, and disables Gatekeeper. It returns the
# status of the first failed step after every step has run.
#
# @noargs
# @stderr Each step that failed and the steps to take in System Settings.
# @exitcode 0 Every step succeeded.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of the first step that failed.
# @example
#   GIT_EMAIL=alice@example.com GIT_USERNAME='Alice Example' mac::setup
mac::setup() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  # Each failed step replaces status only while it is still 0.
  local status=0 formula='' cask=''
  local formulae=(
    duti sqlite postgresql rustup ffmpeg pnpm tree ripgrep fd gh python shellcheck shfmt font-udev-gothic
  )
  local casks=(
    google-chrome brave-browser obs zoom webex visual-studio-code android-studio thunderbird discord
    google-drive dropbox megasync onedrive gimp adobe-acrobat-reader iina karabiner-elements marta
    antigravity antigravity-ide
  )

  setup::_run-step sudo::passwordless::enable || status="${status/#0/$?}"
  setup::_ensure-file "${HOME}/.env" 0600 || status="${status/#0/$?}"
  setup::_run-step env::dotenv::register "${HOME}/.env" || status="${status/#0/$?}"
  # Zsh is the default macOS shell, so the editor also goes into .zshrc.
  setup::_run-step shell::editor::set-default 'code --wait' bash,zsh || status="${status/#0/$?}"
  setup::_run-step shell::zsh::enable-interactive-comments || status="${status/#0/$?}"
  setup::_run-step homebrew::cask::disable-quarantine || status="${status/#0/$?}"
  mkdir -p -- "${HOME}/.local/bin" || status="${status/#0/$?}"
  setup::_run-step env::add-path "${HOME}/.local/bin" || status="${status/#0/$?}"
  setup::_run-step shell::completion::enable-ignore-case || status="${status/#0/$?}"
  setup::_run-step mac::wake-on-lan::enable || status="${status/#0/$?}"
  setup::_run-step mac::keyboard::use-function-keys || status="${status/#0/$?}"
  setup::_run-step key-binding::disable-option-t || status="${status/#0/$?}"
  setup::_run-step mac::keyboard::set-repeat || status="${status/#0/$?}"
  setup::_run-step mac::dock::set-autohide-instant || status="${status/#0/$?}"
  setup::_run-step mac::trackpad::disable-smart-zoom || status="${status/#0/$?}"
  setup::_run-step mac::dock::hide-recent-applications || status="${status/#0/$?}"
  setup::_run-step mac::dock::set-minimize-effect || status="${status/#0/$?}"
  setup::_run-step mac::dock::set-position || status="${status/#0/$?}"
  setup::_run-step mac::applications::remove-bundled || status="${status/#0/$?}"
  setup::_run-step homebrew::install || status="${status/#0/$?}"
  setup::_run-step brew update || status="${status/#0/$?}"
  setup::_run-step brew upgrade || status="${status/#0/$?}"
  for formula in "${formulae[@]}"; do
    setup::_run-step brew install "${formula}" || status="${status/#0/$?}"
  done
  setup::_run-step pipx::install || status="${status/#0/$?}"
  setup::_run-step node::install || status="${status/#0/$?}"
  setup::_run-step jdk::install || status="${status/#0/$?}"
  setup::_run-step ruby::install || status="${status/#0/$?}"
  setup::_run-step colima::install || status="${status/#0/$?}"
  setup::_run-step docker::install || status="${status/#0/$?}"
  setup::_run-step rancher-desktop::install || status="${status/#0/$?}"
  for cask in "${casks[@]}"; do
    setup::_run-step brew install --cask "${cask}" || status="${status/#0/$?}"
  done
  setup::_run-step opencode::install || status="${status/#0/$?}"
  setup::_run-step qmk::toolbox::install || status="${status/#0/$?}"
  setup::_run-step qmk::cli::install || status="${status/#0/$?}"
  setup::_run-step supabase::install || status="${status/#0/$?}"
  setup::_run-step mac::quarantine::remove-applications || status="${status/#0/$?}"
  console::_write-error 'Enable Full Disk Access for Visual Studio Code and Terminal in Privacy & Security.'
  setup::_run-step mac::gatekeeper::disable || status="${status/#0/$?}"
  setup::_run-step git::config::setup || status="${status/#0/$?}"
  setup::_run-step git::config::use-osx-keychain || status="${status/#0/$?}"
  setup::_run-step code --command workbench.view.extensions || status="${status/#0/$?}"
  setup::_run-step vscode::set-default-app || status="${status/#0/$?}"
  setup::_run-step iina::set-default-app || status="${status/#0/$?}"
  return "${status}"
}
