#!/usr/bin/env bash
# @file mac
# @brief macOS system, Dock, keyboard, and security settings.
# @description Settings are written with defaults and take effect after the related process restarts.

# shellcheck disable=SC2119,SC2120

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
    duti sqlite postgresql rustup ffmpeg pnpm tree ripgrep fd gh shellcheck shfmt font-udev-gothic
  )
  local casks=(
    google-chrome brave-browser obs zoom webex visual-studio-code android-studio thunderbird discord
    google-drive dropbox megasync onedrive gimp adobe-acrobat-reader iina karabiner-elements marta
    antigravity antigravity-ide
  )

  setup::_run-step sudo::passwordless::enable || status="${status/#0/$?}"
  file::ensure-exists "${HOME}/.env" 0600 || status="${status/#0/$?}"
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
  setup::_run-step mac::keyboard::disable-option-t || status="${status/#0/$?}"
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
  setup::_run-step brew install python || status="${status/#0/$?}"
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

# @description Disable the Option+T key binding on macOS.
#
# @noargs
# @exitcode 0 Option+T no longer types a character.
# @exitcode 64 An argument was given.
# @exitcode 65 The existing DefaultKeyBinding.dict is not a valid property list.
# @exitcode 69 The system is not macOS, or plutil is unavailable.
# @exitcode 74 The property list could not be written.
# @example
#   mac::keyboard::disable-option-t
mac::keyboard::disable-option-t() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  plist::set "${HOME}/Library/KeyBindings/DefaultKeyBinding.dict" '~t' 'noop:'
}
