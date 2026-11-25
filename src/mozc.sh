#!/usr/bin/env bash
# @file mozc
# @brief Mozc input method installation and settings.
# @description Mozc is installed from the platform package source.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Open the Mozc settings dialog on a Linux desktop.
#
# @noargs
# @exitcode 0 The dialog was closed.
# @exitcode 64 An argument was given.
# @exitcode 69 mozc_tool is unavailable.
# @exitcode other The status of mozc_tool.
# @example
#   mozc__config__open
mozc__config__open() {
  [[ "$#" -eq 0 ]] || return 64
  local tool=''
  for tool in /usr/lib/mozc/mozc_tool /usr/libexec/mozc/mozc_tool /usr/lib64/mozc/mozc_tool; do
    if [[ -x "${tool}" ]]; then
      "${tool}" --mode=config_dialog
      return
    fi
  done
  command__require mozc_tool || return "$?"
  mozc_tool --mode=config_dialog
}

# @description Write the platform package name for a Mozc component.
# @internal
_mozc__package-name() {
  [[ "$#" -eq 1 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}:$1" in
    ubuntu:server) printf 'mozc-server\n' ;;
    ubuntu:ibus) printf 'ibus-mozc\n' ;;
    ubuntu:tool) printf 'mozc-utils-gui\n' ;;
    fedora:server) printf 'mozc\n' ;;
    fedora:ibus) printf 'ibus-mozc\n' ;;
    fedora:tool) printf 'mozc\n' ;;
    *)
      _console__write-error "Mozc packages are unavailable on ${platform}."
      return 69
      ;;
  esac
}

# @description Write Mozc server versions provided for the running operating-system release.
#
# @noargs
# @stdout Mozc server package versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   mozc__server__versions
mozc__server__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(_mozc__package-name server)" || return "$?"
  _package__versions "${package}"
}

# @description Install the Mozc server, defaulting to the newest version for the running release.
#
# @arg $1 string Optional version from mozc__server__versions. Defaults to the newest one.
# @exitcode 0 The Mozc server is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   mozc__server__install
mozc__server__install() {
  [[ "$#" -le 1 ]] || return 64
  local package='' version="${1:-}"
  package="$(_mozc__package-name server)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(_package__latest-version "${package}")" || return "$?"
  fi
  _package__install "${package}=${version}"
}

# @description Write IBus Mozc versions provided for the running operating-system release.
#
# @noargs
# @stdout IBus Mozc package versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   mozc__ibus__versions
mozc__ibus__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(_mozc__package-name ibus)" || return "$?"
  _package__versions "${package}"
}

# @description Install IBus Mozc and the Mozc server of the same version.
#
# @arg $1 string Optional version from mozc__ibus__versions. Defaults to the newest one.
# @exitcode 0 IBus Mozc, and the server of the same version when provided, are installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   mozc__ibus__install
mozc__ibus__install() {
  [[ "$#" -le 1 ]] || return 64
  local package='' server='' version="${1:-}"
  package="$(_mozc__package-name ibus)" || return "$?"
  server="$(_mozc__package-name server)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(_package__latest-version "${package}")" || return "$?"
  fi
  if _package__versions "${server}" 2>/dev/null | grep -Fqx -- "${version}"; then
    _package__install "${package}=${version}" "${server}=${version}"
  else
    _package__install "${package}=${version}"
  fi
}

# @description Install IBus Mozc on Ubuntu, or upgrade it when the release offers a newer version.
#
# The newest version from mozc__ibus__versions is installed through
# mozc__ibus__install, with the Mozc server of the same version when the
# release provides it. An installed version at least as new is kept, so a
# newer version is never downgraded. Fedora is not supported yet.
#
# @noargs
# @stderr A message when the release provides no IBus Mozc version.
# @exitcode 0 IBus Mozc was installed or upgraded, or is already up to date.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not Ubuntu, or the release provides no IBus Mozc version.
# @exitcode other The status of the package manager.
# @example
#   mozc__ibus__upgrade
mozc__ibus__upgrade() {
  [[ "$#" -eq 0 ]] || return 64
  _package__require-platform ubuntu || return "$?"
  local record='' installed='' versions='' latest=''
  record="$(dpkg-query -W -f='${Status}\t${Version}' ibus-mozc 2>/dev/null)" || record=''
  if [[ "${record}" == 'install ok installed'* ]]; then
    installed="${record#*$'\t'}"
  fi
  versions="$(mozc__ibus__versions)" || return "$?"
  latest="${versions##*$'\n'}"
  if [[ -z "${latest}" ]]; then
    _console__write-error 'This release provides no IBus Mozc version.'
    return 69
  fi
  if [[ -n "${installed}" ]] && dpkg --compare-versions "${installed}" ge "${latest}"; then
    return 0
  fi
  mozc__ibus__install "${latest}"
}

# @description Write Mozc GUI tool versions provided for the running operating-system release.
#
# @noargs
# @stdout Mozc GUI tool package versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   mozc__tool__versions
mozc__tool__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(_mozc__package-name tool)" || return "$?"
  _package__versions "${package}"
}

# @description Install the Mozc GUI tools.
#
# @arg $1 string Optional version from mozc__tool__versions. Defaults to the newest one.
# @exitcode 0 The Mozc GUI tools are installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   mozc__tool__install
#   mozc__config__open
mozc__tool__install() {
  [[ "$#" -le 1 ]] || return 64
  local package=''
  package="$(_mozc__package-name tool)" || return "$?"
  _package__install-version "${package}" "${1:-}"
}

# @description Make sure the Mozc IBus configuration lists Mozc's engines.
#
# Mozc 2.26 and later read their IBus engines from ibus_config.textproto, and
# a file without an engines block leaves IBus with no Mozc engine at all. Such
# a file, or a missing one, is replaced with the defaults that Mozc writes when
# its IBus component lists engines through a command, or with the same defaults
# for older Mozc, whose engines are fixed in the component and which has no
# such command.
# @internal
# @arg $1 string Configuration file.
# @arg $2 string Optional IBus component file. Defaults to /usr/share/ibus/component/mozc.xml.
_mozc__ibus__ensure-engines() {
  [[ ( "$#" -eq 1 || "$#" -eq 2 ) && -n "$1" ]] || return 64
  local file="$1" component="${2:-/usr/share/ibus/component/mozc.xml}" command=''
  local words=()
  # Text format allows engines {, engines: {, engines <, and engines: <.
  if [[ -f "${file}" ]] && grep -Eq '^[[:space:]]*engines[[:space:]]*:?[[:space:]]*[{<]' "${file}"; then
    return 0
  fi
  rm -f -- "${file}" || return 74
  # Older Mozc would start as an engine and wait instead of answering --xml.
  command="$(sed -n 's/.*<engines[[:space:]][[:space:]]*exec="\([^"]*\)".*/\1/p' "${component}" 2>/dev/null | head -n 1)"
  if [[ -n "${command}" ]]; then
    read -r -a words <<<"${command}"
    if [[ -x "${words[0]}" ]]; then
      "${words[@]}" >/dev/null 2>&1 || true
    fi
  fi
  [[ -f "${file}" ]] && return 0
  # shellcheck disable=SC2016 # Mozc's own comment quotes the commands literally.
  file__write-text "${file}" '# `ibus write-cache; ibus restart` might be necessary to apply changes.
engines {
  name : "mozc-jp"
  longname : "Mozc"
  layout : "default"
  layout_variant : ""
  layout_option : ""
  rank : 80
}
active_on_launch: False
'
}

# @description Start Mozc in Hiragana mode and restart IBus.
#
# active_on_launch is set to True in ~/.config/mozc/ibus_config.textproto. A
# missing file, or one without Mozc's engine list, first gets Mozc's defaults,
# because IBus offers no Mozc engine without that list. The IBus cache is then
# rewritten so that IBus reads the engine list again.
#
# @noargs
# @exitcode 0 Mozc starts in Hiragana mode from now on.
# @exitcode 64 An argument was given.
# @exitcode 69 Python 3 or ibus-daemon is unavailable.
# @exitcode 74 The configuration file could not be created.
# @exitcode other The status of the settings update or ibus-daemon.
# @example
#   mozc__ibus__set-hiragana-as-default
mozc__ibus__set-hiragana-as-default() {
  [[ "$#" -eq 0 ]] || return 64
  local file="${HOME}/.config/mozc/ibus_config.textproto"
  mkdir -p -- "$(path__directory-name "${file}")" || return 74
  _mozc__ibus__ensure-engines "${file}" || return "$?"
  textproto__set-scalar "${file}" active_on_launch True || return "$?"
  command__require ibus-daemon || return "$?"
  # IBus caches the engine list that Mozc reported, so a list read from an
  # incomplete configuration stays until the cache is written again.
  if command__exists ibus; then
    ibus write-cache >/dev/null 2>&1 || return "$?"
  fi
  ibus-daemon -rd
}
