#!/usr/bin/env bash
# @file node
# @brief Node.js installation.
# @description Node.js is installed through a version manager.

# shellcheck disable=SC2119,SC2120

# @description Write the artifact suffix used by official Node.js downloads.
# @internal
node::_official-platform() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) platform='darwin' ;;
    ubuntu | fedora) platform='linux' ;;
  esac
  architecture="$(uname -m)" || return 74
  case "${architecture}" in
    x86_64 | amd64) architecture='x64' ;;
    aarch64 | arm64) architecture='arm64' ;;
    *) return 69 ;;
  esac
  printf '%s-%s\n' "${platform}" "${architecture}"
}

# @description Write complete stable Node.js versions from the selected source.
#
# @arg $1 string Optional source: os for the system package manager (default) or official for nodejs.org.
# @stdout Complete versions such as 22.11.0, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The platform is unsupported, or Python 3 is missing for the official source.
# @exitcode 74 The release index could not be downloaded or read.
# @example
#   node::versions official | tail -n 3
node::versions() {
  [[ "$#" -le 1 ]] || return 64
  local source="${1:-os}" platform='' versions='' raw='' artifact='' json=''
  [[ "${source}" == os || "${source}" == official ]] || return 64
  platform="$(package::_platform)" || return "$?"
  if [[ "${source}" == official ]]; then
    artifact="$(node::_official-platform)" || return "$?"
    if [[ "${artifact}" == darwin-* ]]; then artifact="osx-${artifact#darwin-}-tar"; fi
    json="$(package::_fetch https://nodejs.org/dist/index.json)" || return "$?"
    versions="$(printf '%s' "${json}" | python::run -c '
import json
import re
import sys
artifact = sys.argv[1]
for release in json.load(sys.stdin):
    match = re.fullmatch(r"v([0-9]+\.[0-9]+\.[0-9]+)", release.get("version", ""))
    if match and artifact in release.get("files", []):
        print(match.group(1))
' "${artifact}")" || return "$?"
  elif [[ "${platform}" == darwin ]]; then
    versions="$(package::_brew-formula-stable-version node)" || return "$?"
    local formula='' versioned_formulae=''
    versioned_formulae="$(brew info --json=v2 --formula node |
      python::run -c 'import json, sys; print("\n".join(json.load(sys.stdin)["formulae"][0].get("versioned_formulae", [])))')" || return "$?"
    while IFS= read -r formula; do
      [[ -n "${formula}" ]] || continue
      raw="$(package::_brew-formula-stable-version "${formula}")" || return "$?"
      versions+=$'\n'"${raw}"
    done <<<"${versioned_formulae}"
  else
    versions="$(package::_versions nodejs)" || return "$?"
    while IFS= read -r raw; do
      [[ "${raw}" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]] &&
        printf '%s\n' "${BASH_REMATCH[1]}"
    done <<<"${versions}" | package::_sort-versions
    return
  fi
  [[ -n "${versions}" ]] || return 69
  printf '%s\n' "${versions}" | package::_sort-versions
}

# @description Install Node.js, enable Corepack, and set the pnpm store directory.
#
# Corepack is enabled with pnpm 8.15.9, installing Corepack through npm when the Node.js release no longer bundles it.
#
# @arg $1 string Optional complete version from node::versions. Defaults to the newest stable version of the source.
# @arg $2 string Optional source: os (default) or official.
# @stderr A message when the version is unavailable or too old for Corepack.
# @exitcode 0 Node.js, Corepack, and pnpm are ready.
# @exitcode 64 The version or source is malformed.
# @exitcode 69 The version is unavailable from the source, or older than 16.14.
# @exitcode 74 The official archive could not be downloaded or unpacked.
# @exitcode other The status of the package manager, npm, or Corepack.
# @example
#   node::install 22.11.0 official
#   pnpm --version
node::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" source="${2:-os}" platform='' available='' raw='' selected=''
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  [[ "${source}" == os || "${source}" == official ]] || return 64
  platform="$(package::_platform)" || return "$?"
  available="$(node::versions "${source}")" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(printf '%s\n' "${available}" | package::_latest-stable-version)" || return "$?"
  fi
  if ! grep -Fqx -- "${version}" <<<"${available}"; then
    console::_write-error "Node.js ${version} is unavailable from ${source}."
    return 69
  fi
  local major="${version%%.*}" minor="${version#*.}"
  minor="${minor%%.*}"
  if (( major < 16 || (major == 16 && minor < 14) )); then
    console::_write-error "Node.js ${version} cannot run the required Corepack and pnpm releases."
    return 69
  fi
  if [[ "${source}" == official ]]; then
    node::_install-official "${version}" || return "$?"
  elif [[ "${platform}" == darwin ]]; then
    local formula='node' stable='' versioned_formulae='' candidate=''
    stable="$(package::_brew-formula-stable-version node)" || return "$?"
    if [[ "${version}" != "${stable}" ]]; then
      formula=''
      versioned_formulae="$(brew info --json=v2 --formula node |
        python::run -c 'import json, sys; print("\n".join(json.load(sys.stdin)["formulae"][0].get("versioned_formulae", [])))')" || return "$?"
      while IFS= read -r candidate; do
        [[ -n "${candidate}" ]] || continue
        stable="$(package::_brew-formula-stable-version "${candidate}")" || return "$?"
        if [[ "${version}" == "${stable}" ]]; then formula="${candidate}"; break; fi
      done <<<"${versioned_formulae}"
      [[ -n "${formula}" ]] || return 69
    fi
    package::_install "${formula}" || return "$?"
    [[ "${formula}" == node ]] || brew link --overwrite --force "${formula}" || return "$?"
  else
    available="$(package::_versions nodejs)" || return "$?"
    while IFS= read -r raw; do
      if ( [[ "${raw}" =~ (^|[^0-9])${version}([^0-9]|$) ]] ); then selected="${raw}"; fi
    done <<<"${available}"
    [[ -n "${selected}" ]] || return 69
    if [[ "${platform}" == ubuntu ]]; then
      [[ -n "$(package::_versions npm)" ]] || return 69
    fi
    package::_install "nodejs=${selected}" npm || return "$?"
  fi
  node::_enable-corepack "${platform}" "${source}" || return "$?"
  COREPACK_ENABLE_DOWNLOAD_PROMPT=0 pnpm config set store-dir "${HOME}/.pnpm-store"
}

# @description Enable Corepack, installing it through npm when the Node.js release omits it.
#
# On macOS, Homebrew's pnpm formula can already own the pnpm link in the
# shared bin directory. Corepack replaces that link, as corepack enable does
# for a bundled Corepack, so npm is allowed to overwrite it there.
# @internal
node::_enable-corepack() {
  [[ "$#" -eq 2 ]] || return 64
  local runner=() options=()
  [[ "$1" == 'darwin' || "$2" == official ]] || runner=(command::run-as-root)
  [[ "$1" != 'darwin' || "$2" == official ]] || options=(--force)
  if ! command -v corepack >/dev/null 2>&1; then
    command::require npm || return "$?"
    ${runner[@]+"${runner[@]}"} npm install --global ${options[@]+"${options[@]}"} corepack@0.20.0 ||
      return "$?"
  fi
  ${runner[@]+"${runner[@]}"} corepack enable || return "$?"
  COREPACK_ENABLE_DOWNLOAD_PROMPT=0 corepack prepare pnpm@8.15.9 --activate
}

# @description Install an official Node.js archive after confirming that its executables start.
# @internal
node::_install-official() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  local version="$1" artifact='' temporary='' destination=''
  artifact="$(node::_official-platform)" || return "$?"
  destination="${HOME}/.local/lib/node/${version}"
  if [[ ! -x "${destination}/bin/node" ]]; then
    temporary="$(package::_temporary-directory)" || return "$?"
    # The gzip archive avoids requiring xz, which minimal systems do not install.
    package::_download \
      "https://nodejs.org/dist/v${version}/node-v${version}-${artifact}.tar.gz" \
      "${temporary}/node.tar.gz" || { rm -rf -- "${temporary}"; return 74; }
    mkdir -p -- "${temporary}/unpacked" || { rm -rf -- "${temporary}"; return 74; }
    tar -xzf "${temporary}/node.tar.gz" --strip-components=1 -C "${temporary}/unpacked" ||
      { rm -rf -- "${temporary}"; return 74; }
    [[ "$("${temporary}/unpacked/bin/node" --version)" == "v${version}" ]] ||
      { rm -rf -- "${temporary}"; return 69; }
    PATH="${temporary}/unpacked/bin:${PATH}" "${temporary}/unpacked/bin/npm" --version >/dev/null ||
      { rm -rf -- "${temporary}"; return 69; }
    mkdir -p -- "${HOME}/.local/lib/node" || { rm -rf -- "${temporary}"; return 74; }
    # A directory left by an interrupted installation has no working node; it
    # is replaced, because mv would otherwise move the new tree inside it.
    if [[ -e "${destination}" || -L "${destination}" ]]; then
      rm -rf -- "${destination}" || { rm -rf -- "${temporary}"; return 74; }
    fi
    mv -- "${temporary}/unpacked" "${destination}" ||
      { rm -rf -- "${temporary}"; return 74; }
    rm -rf -- "${temporary}"
  fi
  ln -sfn -- "${destination}" "${HOME}/.local/lib/node/current" || return 74
  local binary_directory="${HOME}/.local/lib/node/current/bin" escaped='' startup='' line=''
  printf -v escaped '%q' "${binary_directory}"
  line="__bashstock_node_bin=${escaped}; case \"\$PATH\" in \"\$__bashstock_node_bin\"|\"\$__bashstock_node_bin\":*) ;; *) PATH=\"\$__bashstock_node_bin:\$PATH\"; export PATH ;; esac; unset __bashstock_node_bin"
  for startup in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    [[ -e "${startup}" ]] || file::write-text "${startup}" '' || return "$?"
    file::replace-text-or-append "${startup}" \
      '^(__bashstock_node_bin=|__bashstock_path=.*\.local/lib/node/current/bin).*$' \
      "${line}" || return "$?"
  done
  if [[ "${PATH}" != "${binary_directory}" && "${PATH}" != "${binary_directory}":* ]]; then
    PATH="${binary_directory}:${PATH}"
    export PATH
    hash -r
  fi
}
