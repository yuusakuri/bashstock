#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### Write the elements of a GVariant string array, one per line.
###
### The value is parsed as GVariant text, so quoted commas and escapes are kept.
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

### Write one value as a single-quoted GVariant string literal.
gsettings::_quote() {
  [[ "$#" -eq 1 && "$1" != *$'\n'* ]] || return 64
  command::require perl || return "$?"
  perl -e 'my $value = shift; $value =~ s/([\\\x27])/\\$1/g; print "\x27$value\x27\n";' "$1"
}

### Write lines from standard input as a GVariant string array.
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

### Require a GSettings key to hold a string array.
gsettings::_require-string-array() {
  [[ "$#" -eq 2 && -n "$1" && -n "$2" ]] || return 64
  command::require gsettings || return "$?"
  local range=''
  range="$(gsettings range "$1" "$2" 2>/dev/null)" || return 66
  [[ "${range}" == 'type as' ]] || return 65
}

### Write the elements of a GSettings string array, one per line.
gsettings::_string-array-values() {
  [[ "$#" -eq 2 ]] || return 64
  gsettings::_require-string-array "$1" "$2" || return "$?"
  local value=''
  value="$(gsettings get "$1" "$2")" || return 74
  gsettings::_parse-string-array "${value}"
}

### Add a literal value to a GSettings string array when it is absent.
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

### Remove every element equal to a literal value from a GSettings string array.
gsettings::string-array::remove() {
  [[ "$#" -eq 3 && -n "$3" && "$3" != *$'\n'* ]] || return 64
  local array_values='' value='' array=''
  array_values="$(gsettings::_string-array-values "$1" "$2")" || return "$?"
  array="$(while IFS= read -r value; do
    [[ -z "${array_values}" || "${value}" == "$3" ]] || printf '%s\n' "${value}"
  done <<<"${array_values}" | gsettings::_format-string-array)" || return "$?"
  gsettings set "$1" "$2" "${array}"
}

### Write the GSettings string value of one key without GVariant quotes.
gsettings::_string-value() {
  [[ "$#" -eq 2 ]] || return 64
  command::require gsettings || return "$?"
  local value=''
  value="$(gsettings get "$1" "$2")" || return 74
  gsettings::_parse-string-array "[${value}]"
}

### Register a GNOME custom keyboard shortcut after removing conflicting shortcuts.
###
### Conflicts are shortcuts with the same name, or with the same command and binding.
###
### Arguments
###
### * ID - Identifier used in the shortcut path, such as custom100.
### * NAME - Descriptive shortcut name.
### * COMMAND - Command that GNOME runs.
### * BINDING - Key combination, such as <Alt>a.
gnome::keybinding::set-custom() {
  [[ "$#" -eq 4 && "$1" =~ ^[A-Za-z0-9_-]+$ && -n "$2" && -n "$3" && -n "$4" ]] || return 64
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

### Require a keyboard layout name accepted by XKB.
keyboard::_require-layout() {
  [[ "$#" -eq 1 && "$1" =~ ^[a-z][a-z0-9_]*(\+[A-Za-z0-9_-]+)?$ ]] || return 64
}

### Set GNOME input sources to Mozc followed by one XKB layout.
gnome::input-source::set-layout() {
  [[ "$#" -eq 1 ]] || return 64
  keyboard::_require-layout "$1" || return "$?"
  command::require gsettings || return "$?"
  gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'mozc-jp'), ('xkb', '$1')]"
}

### Set the system keyboard layout.
###
### Ubuntu updates XKBLAYOUT in /etc/default/keyboard. Other systems use localectl.
keyboard::system-layout::set() {
  [[ "$#" -eq 1 ]] || return 64
  keyboard::_require-layout "$1" || return "$?"
  if [[ -f /etc/default/keyboard ]]; then
    file::replace-text /etc/default/keyboard 'XKBLAYOUT="[^"]*"' "XKBLAYOUT=\"$1\""
    return
  fi
  command::require localectl || return "$?"
  command::run-as-root localectl set-x11-keymap "$1"
}

### Set GNOME input sources and the system keyboard layout to Mozc and US.
gnome::keyboard-layout::set-us() {
  [[ "$#" -eq 0 ]] || return 64
  gnome::input-source::set-layout us || return "$?"
  keyboard::system-layout::set us
}

### Set GNOME input sources and the system keyboard layout to Mozc and JP.
gnome::keyboard-layout::set-jp() {
  [[ "$#" -eq 0 ]] || return 64
  gnome::input-source::set-layout jp || return "$?"
  keyboard::system-layout::set jp
}

### List the named arguments for gnome::input-source::set-shortcuts.
gnome::input-source::_set-shortcuts-args() {
  case "${1-}" in
    '')
      printf '%s\n' --next --previous --us --mozc
      ;;
  esac
}

### Set GNOME input-source switching shortcuts and direct US and Mozc shortcuts.
###
### Options
###
### * --next BINDING - Next input source. Defaults to <Alt>grave.
### * --previous BINDING - Previous input source. Defaults to <Shift><Alt>grave.
### * --us BINDING - Switch to the US layout. Defaults to <Alt>semicolon.
### * --mozc BINDING - Switch to Mozc. Defaults to <Alt>a.
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

### Write the first XKB layout from GNOME input sources.
gnome::input-source::_first-layout() {
  [[ "$#" -eq 0 ]] || return 64
  command::require gsettings || return "$?"
  local sources='' pattern="\('xkb', '([^']+)'\)"
  sources="$(gsettings get org.gnome.desktop.input-sources sources)" || return 74
  [[ "${sources}" =~ ${pattern} ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

### Put Mozc first in GNOME input sources while keeping the current XKB layout.
gnome::input-source::set-mozc-first() {
  [[ "$#" -eq 0 ]] || return 64
  local layout=''
  layout="$(gnome::input-source::_first-layout)" || return "$?"
  gnome::input-source::set-layout "${layout}"
}

### Set the GNOME window title-bar button layout.
###
### Arguments
###
### * LAYOUT - Button layout. Defaults to appmenu:minimize,maximize,close.
gnome::window::set-button-layout() {
  [[ "$#" -le 1 ]] || return 64
  local layout="${1:-appmenu:minimize,maximize,close}"
  [[ "${layout}" =~ ^[a-z,:]*$ ]] || return 64
  command::require gsettings || return "$?"
  gsettings set org.gnome.desktop.wm.preferences button-layout "${layout}"
}

### Start Mozc in Hiragana mode and restart IBus.
mozc::ibus::set-hiragana-as-default() {
  [[ "$#" -eq 0 ]] || return 64
  local file="${HOME}/.config/mozc/ibus_config.textproto"
  mkdir -p -- "$(path::directory-name "${file}")" || return 74
  [[ -e "${file}" ]] || : >"${file}" || return 74
  textproto::set-scalar "${file}" active_on_launch True || return "$?"
  command::require ibus-daemon || return "$?"
  ibus-daemon -rd
}

### Map the Convert and Nonconvert keys of USB keyboards to henkan and muhenkan.
###
### KC_INT4 (HID usage 0x7008A, Convert) becomes henkan and KC_INT5 (HID usage
### 0x7008B, Nonconvert) becomes muhenkan, as in the reference script. The input
### method handles the keys; this function does not change IME settings. The
### hwdb entry applies to every USB keyboard, or only to the keyboard identified
### by VENDOR_ID and PRODUCT_ID.
###
### Arguments
###
### * VENDOR_ID - Four hexadecimal digits. Requires PRODUCT_ID.
### * PRODUCT_ID - Four hexadecimal digits. Requires VENDOR_ID.
keyboard::setup-ime-keys() {
  [[ "$#" -eq 0 || "$#" -eq 2 ]] || return 64
  local match='evdev:input:b0003v*p*' content=''
  if [[ "$#" -eq 2 ]]; then
    [[ "$1" =~ ^[0-9A-Fa-f]{4}$ && "$2" =~ ^[0-9A-Fa-f]{4}$ ]] || return 64
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

### Run one setup step, report a failure, and return its status.
setup::_run-step() {
  [[ "$#" -ge 1 ]] || return 64
  "$@"
  local status="$?"
  [[ "${status}" -eq 0 ]] || console::_write-error "Setup step failed with status ${status}: $*"
  return "${status}"
}

### Create an empty file when it does not exist.
setup::_ensure-file() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  [[ -e "$1" ]] || : >"$1" || return 74
  [[ -f "$1" ]] || return 66
}

### Apply the common Ubuntu user configuration, stopping at the first failure.
ubuntu::setup() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  setup::_ensure-file "${HOME}/.env" || return "$?"
  setup::_run-step env::dotenv::register "${HOME}/.env" || return "$?"
  setup::_run-step shell::editor::set-default 'code --wait' || return "$?"
  setup::_run-step shell::completion::enable-ignore-case || return "$?"
  setup::_run-step user::directory::create-english-links || return "$?"
  setup::_run-step user::add-to-group dialout || return "$?"
  setup::_run-step git::config::setup || return "$?"
  setup::_run-step git::config::use-credential-manager || return "$?"
  setup::_run-step ssh::setup-directory
}

### Apply the Ubuntu user configuration and desktop settings, stopping at the first failure.
ubuntu::setup-desktop() {
  [[ "$#" -eq 0 ]] || return 64
  ubuntu::setup || return "$?"
  setup::_run-step keyboard::setup-ime-keys || return "$?"
  setup::_run-step gnome::input-source::set-mozc-first || return "$?"
  setup::_run-step gnome::keyboard-layout::set-us || return "$?"
  setup::_run-step mozc::ibus::set-hiragana-as-default || return "$?"
  setup::_run-step vlc::set-default-app
}

### Install the newest Mozc for Ubuntu 22.04 and apply the desktop settings.
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

### Install Homebrew with the official installer when it is missing.
###
### The new Zsh sessions read brew shellenv from .zshrc, and the current
### process finds brew on PATH afterwards.
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
  setup::_ensure-file "${HOME}/.zshrc" || return "$?"
  # shellcheck disable=SC2016 # The startup file evaluates brew shellenv later.
  file::replace-text-or-append "${HOME}/.zshrc" '^.*brew shellenv.*$' 'eval "$(/opt/homebrew/bin/brew shellenv)"' || return "$?"
  PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
  export PATH
}

### Install Homebrew casks without the quarantine attribute from now on.
homebrew::cask::disable-quarantine() {
  [[ "$#" -eq 0 ]] || return 64
  env::set-variable HOMEBREW_CASK_OPTS --no-quarantine
}

### Allow comments that start with # in interactive Zsh sessions.
shell::zsh::enable-interactive-comments() {
  [[ "$#" -eq 0 ]] || return 64
  setup::_ensure-file "${HOME}/.zshrc" || return "$?"
  file::replace-text-or-append "${HOME}/.zshrc" '^setopt interactivecomments.*$' 'setopt interactivecomments'
}

### Let the Mac wake from sleep through the network (Wake on LAN).
mac::wake-on-lan::enable() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root pmset -a womp 1
}

### Make F1 to F12 act as function keys without the fn key.
mac::keyboard::use-function-keys() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
}

### Set the delay before key repeat starts and the repeat interval.
###
### Arguments
###
### * INITIAL - Delay before repeating, in units of 15 ms. Defaults to 30.
### * REPEAT - Interval between repeats, in units of 15 ms. Defaults to 1.
mac::keyboard::set-repeat() {
  [[ "$#" -le 2 ]] || return 64
  local initial="${1:-30}" repeat="${2:-1}"
  [[ "${initial}" =~ ^[0-9]+$ && "${repeat}" =~ ^[0-9]+$ ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write NSGlobalDomain InitialKeyRepeat -int "${initial}" || return "$?"
  defaults write NSGlobalDomain KeyRepeat -int "${repeat}"
}

### Turn off smart zoom, the two-finger double tap, on built-in and external trackpads.
mac::trackpad::disable-smart-zoom() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 0 ||
    return "$?"
  defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 0 || return "$?"
  defaults write NSGlobalDomain com.apple.trackpad.twoFingerDoubleTapGesture -int 0
}

### Restart the Dock so that it reads changed preferences.
mac::dock::_restart() {
  [[ "$#" -eq 0 ]] || return 64
  killall Dock >/dev/null 2>&1 || true
}

### Show and hide the Dock immediately, without a delay or an animation.
mac::dock::set-autohide-instant() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock autohide-time-modifier -float 0 || return "$?"
  defaults write com.apple.dock autohide-delay -float 0 || return "$?"
  mac::dock::_restart
}

### Hide recently used applications in the Dock.
mac::dock::hide-recent-applications() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock show-recents -bool false || return "$?"
  mac::dock::_restart
}

### Set the effect used when a window is minimized into the Dock.
###
### Arguments
###
### * EFFECT - genie, scale, or suck. Defaults to scale.
mac::dock::set-minimize-effect() {
  [[ "$#" -le 1 ]] || return 64
  local effect="${1:-scale}"
  [[ "${effect}" == genie || "${effect}" == scale || "${effect}" == suck ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock mineffect -string "${effect}" || return "$?"
  mac::dock::_restart
}

### Place the Dock on one edge of the screen.
###
### Arguments
###
### * POSITION - left, bottom, or right. Defaults to left.
mac::dock::set-position() {
  [[ "$#" -le 1 ]] || return 64
  local position="${1:-left}"
  [[ "${position}" == left || "${position}" == bottom || "${position}" == right ]] || return 64
  package::_require-platform darwin || return "$?"
  defaults write com.apple.dock orientation -string "${position}" || return "$?"
  mac::dock::_restart
}

### Remove the bundled iMovie, Pages, GarageBand, Keynote, and Numbers applications.
###
### GarageBand's sound library is removed with it. Missing applications are skipped.
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

### Remove the quarantine attribute from everything below /Applications.
mac::quarantine::remove-applications() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  # Files without the attribute make xattr report errors, which are not failures here.
  command::run-as-root xattr -r -d com.apple.quarantine /Applications 2>/dev/null || true
}

### Ask macOS to allow applications from anywhere and open Privacy & Security.
###
### Recent macOS releases apply spctl --master-disable only after the user
### selects "Allow applications from anywhere" in System Settings, so a refusal
### from spctl is not a failure; the function opens the settings for that step.
mac::gatekeeper::disable() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::run-as-root spctl --master-disable 2>/dev/null || true
  console::_write-error 'Select "Allow applications from anywhere" in Privacy & Security.'
  killall 'System Settings' >/dev/null 2>&1 || true
  sleep 1
  open 'x-apple.systempreferences:com.apple.settings.PrivacySecurity'
}

### Apply the complete macOS setup, continuing after failed steps.
###
### sudo is first made passwordless for the current user and stays so after
### the setup. The setup removes bundled applications, removes quarantine
### attributes below /Applications, and disables Gatekeeper. It returns the
### status of the first failed step after every step has run.
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
  setup::_ensure-file "${HOME}/.env" || status="${status/#0/$?}"
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
