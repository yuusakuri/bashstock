#!/usr/bin/env bash
# @file install
# @brief Installers for development tools and desktop applications.
# @description Most installers accept an optional version; each function documents its default.

# shellcheck disable=SC2119,SC2120

# @description Download a Debian package and install it with its dependencies through APT.
#
# @arg $1 string HTTPS URL of the Debian package.
# @arg $2 string Optional accepted architecture. Defaults to the system architecture; packages for all architectures are also accepted.
# @exitcode 0 The package and its dependencies are installed.
# @exitcode 64 The URL is not HTTPS, or the argument count is wrong.
# @exitcode 65 The package is for another architecture or is not a valid Debian package.
# @exitcode 69 The system is not Ubuntu, or curl, dpkg, or apt-get is missing.
# @exitcode 74 The download failed.
# @exitcode other The status of apt-get.
# @example
#   deb::install-from-url https://example.com/tool_1.2.3_amd64.deb
deb::install-from-url() {
  [[ "$#" -ge 1 && "$#" -le 2 && "$1" == https://* ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local required_command=''
  for required_command in curl dpkg dpkg-deb apt-get chmod; do
    command::require "${required_command}" || return "$?"
  done
  local url="$1" expected="${2:-}" directory='' file='' architecture='' status=0
  if [[ -z "${expected}" ]]; then
    expected="$(package::_deb-architecture)" || return "$?"
  fi
  directory="$(package::_temporary-directory)" || return "$?"
  file="${directory}/package.deb"
  package::_download "${url}" "${file}" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    architecture="$(dpkg-deb --field "${file}" Architecture 2>/dev/null)" || status=65
  fi
  if [[ "${status}" -eq 0 && "${architecture}" != "${expected}" && "${architecture}" != 'all' ]]; then
    console::_write-error "Package architecture ${architecture} does not match ${expected}."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    chmod 0755 "${directory}" && chmod 0644 "${file}" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    package::_refresh || status="$?"
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${file}" || status="$?"
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

# @description Write APT packages whose names start with PREFIX followed by a digit, with candidate versions.
#
# Each line contains a package name and its candidate version separated by a tab.
#
# @arg $1 string Package name prefix, such as openjdk- or libstdc++-.
# @stdout Lines of package name and candidate version separated by a tab, ordered by version.
# @exitcode 0 The candidates were written; none is not an error.
# @exitcode 64 The prefix is not a valid package name start.
# @exitcode 69 The system is not Ubuntu, or apt-cache or Perl is missing.
# @exitcode 74 apt-cache policy failed.
# @example
#   apt::package::candidates gcc-
#   # gcc-12	12.3.0-1ubuntu1~22.04
apt::package::candidates() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[a-z0-9][a-z0-9.+-]*$ ]] ) || return 64
  package::_require-platform ubuntu || return "$?"
  command::require apt-cache || return "$?"
  command::require perl || return "$?"
  local prefix="$1" name='' policy=''
  local names=()
  while IFS= read -r name; do
    [[ "${name}" == "${prefix}"[0-9]* ]] && names+=("${name}")
  done < <(apt-cache pkgnames "${prefix}" 2>/dev/null)
  [[ "${#names[@]}" -gt 0 ]] || return 0
  policy="$(apt-cache policy "${names[@]}" 2>/dev/null)" || return 74
  printf '%s\n' "${policy}" | perl -e '
    my ($prefix) = @ARGV;
    my $name;
    while (<STDIN>) {
      if (/^(\S+):$/) { $name = $1; next; }
      if (defined $name && /^\s+Candidate:\s+(\S+)/) {
        print substr($name, length $prefix), "\t$name\t$1\n" unless $1 eq "(none)";
        undef $name;
      }
    }
  ' "${prefix}" | package::_sort-by-first-field
}

# @description Sort tab-separated lines by the version in their first field and drop that field.
# @internal
package::_sort-by-first-field() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  perl -e '
    sub compare_versions {
      my @left = split /([0-9]+)/, $_[0];
      my @right = split /([0-9]+)/, $_[1];
      while (@left || @right) {
        my $x = shift @left;
        my $y = shift @right;
        return -1 unless defined $x;
        return 1 unless defined $y;
        my $result = ($x =~ /^[0-9]+$/ && $y =~ /^[0-9]+$/) ? $x <=> $y : $x cmp $y;
        return $result if $result;
      }
      return 0;
    }
    my @lines = map { chomp; [split /\t/, $_, 2] } grep { /\t/ } <STDIN>;
    print "$_->[1]\n" for sort { compare_versions($a->[0], $b->[0]) } @lines;
  '
}

# @description Write the APT package name with the newest version suffix after PREFIX.
#
# @arg $1 string Package name prefix followed by a version number in the package names.
# @stdout The package name with the newest version, such as gcc-14.
# @exitcode 0 The name was written.
# @exitcode 1 No package name starts with the prefix and a digit.
# @exitcode 64 The prefix is invalid.
# @exitcode 69 The system is not Ubuntu, or apt-cache or Perl is missing.
# @exitcode 74 apt-cache policy failed.
# @example
#   package::_install "$(apt::package::latest gcc-)"
apt::package::latest() {
  [[ "$#" -eq 1 ]] || return 64
  local candidates='' line=''
  candidates="$(apt::package::candidates "$1")" || return "$?"
  [[ -n "${candidates}" ]] || return 1
  line="${candidates##*$'\n'}"
  printf '%s\n' "${line%%$'\t'*}"
}

# @description Export Chrome Preferences and Bookmarks for profiles whose email matches literally.
#
# @arg $1 string Email address of the Chrome profile, compared literally.
# @arg $2 string Optional destination directory. Defaults to the current directory.
# @exitcode 0 Preferences and Bookmarks of every matching profile were copied as PROFILE_preferences.json and PROFILE_bookmarks.json.
# @exitcode 1 No profile has that email address.
# @exitcode 64 The email address is empty, or the argument count is wrong.
# @exitcode 66 Chrome's user data directory does not exist.
# @exitcode 74 The destination could not be created or a file could not be copied.
# @example
#   chrome::profile::export-user-data-by-email alice@example.com "${HOME}/chrome-backup"
chrome::profile::export-user-data-by-email() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  local output="${2:-.}" profiles='' profile='' name='' status=0
  profiles="$(chrome::profile::find-by-email "$1")" || return "$?"
  [[ -n "${profiles}" ]] || return 1
  mkdir -p -- "${output}" || return 74
  while IFS= read -r profile; do
    name="$(path::base-name "${profile}")" || return "$?"
    chrome::profile::export-preferences "${profile}" "${output}/${name}_preferences.json" || status="$?"
    chrome::profile::export-bookmarks "${profile}" "${output}/${name}_bookmarks.json" || status="$?"
  done <<<"${profiles}"
  return "${status}"
}

# @description Write the default AWS VPN Client log directory.
# @internal
aws-vpn-client::log::_default-directory() {
  [[ "$#" -eq 0 ]] || return 64
  printf '%s\n' "${HOME}/.config/AWSVPNClient/logs"
}

# @description Write AWS VPN Client log files as NUL-separated paths.
#
# Files whose names contain aws_vpn_client_ and do not contain
# ovpn_aws_vpn_client are selected, as in the reference script.
#
# @arg $1 string Optional log directory. Defaults to the AWS VPN Client log directory of this OS.
# @stdout NUL-separated paths of the log files.
# @exitcode 0 The paths were written.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode 69 find is unavailable.
# @example
#   aws-vpn-client::log::files | xargs -0 tail -n 50
aws-vpn-client::log::files() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-}"
  [[ -n "${directory}" ]] || directory="$(aws-vpn-client::log::_default-directory)"
  [[ -d "${directory}" && ! -L "${directory}" ]] || return 66
  command::require find || return "$?"
  find "${directory}" -type f -name '*aws_vpn_client_*' ! -name '*ovpn_aws_vpn_client*' -print0
}

# @description Remove regular log files below the AWS VPN Client log directory.
#
# @arg $1 string Optional log directory. Defaults to the AWS VPN Client log directory of this OS.
# @exitcode 0 Every regular file below the directory was removed.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode 69 find is unavailable.
# @exitcode 74 A file could not be removed.
# @example
#   aws-vpn-client::log::clear
aws-vpn-client::log::clear() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-}"
  [[ -n "${directory}" ]] || directory="$(aws-vpn-client::log::_default-directory)"
  [[ -d "${directory}" && ! -L "${directory}" ]] || return 66
  command::require find || return "$?"
  find "${directory}" -type f -exec rm -f -- {} + || return 74
}

# @description Open log files with an editor command, passing each path as one argument.
#
# @arg $1 string Editor command, such as code.
# @arg $@ string Log files; at least one.
# @exitcode 0 The editor was started.
# @exitcode 64 The editor is empty, or no file was given.
# @exitcode 66 A path is not a regular file.
# @exitcode 69 The editor command is unavailable.
# @exitcode other The status of the editor.
# @example
#   files=()
#   while IFS= read -r -d '' file; do files+=("${file}"); done < <(aws-vpn-client::log::files)
#   aws-vpn-client::log::open code "${files[@]}"
aws-vpn-client::log::open() {
  [[ "$#" -ge 2 && -n "$1" ]] || return 64
  local editor="$1" path=''
  shift
  for path in "$@"; do
    [[ -f "${path}" ]] || return 66
  done
  command::require "${editor}" || return "$?"
  "${editor}" "$@"
}

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
# @exitcode 69 The platform is unsupported, or Perl is missing for the official source.
# @exitcode 74 The release index could not be downloaded or read.
# @example
#   node::versions official | tail -n 3
node::versions() {
  [[ "$#" -le 1 ]] || return 64
  local source="${1:-os}" platform='' versions='' raw='' artifact='' json=''
  [[ "${source}" == os || "${source}" == official ]] || return 64
  platform="$(package::_platform)" || return "$?"
  if [[ "${source}" == official ]]; then
    command::require perl || return "$?"
    artifact="$(node::_official-platform)" || return "$?"
    if [[ "${artifact}" == darwin-* ]]; then artifact="osx-${artifact#darwin-}-tar"; fi
    json="$(package::_fetch https://nodejs.org/dist/index.json)" || return "$?"
    versions="$(printf '%s' "${json}" | perl -MJSON::PP -e '
      my ($artifact) = @ARGV;
      local $/;
      my $data = eval { decode_json(<STDIN>) } or exit 74;
      for my $release (@$data) {
        next unless grep { $_ eq $artifact } @{$release->{files} || []};
        print "$1\n" if $release->{version} =~ /^v([0-9]+\.[0-9]+\.[0-9]+)$/;
      }
    ' "${artifact}")" || return "$?"
  elif [[ "${platform}" == darwin ]]; then
    versions="$(package::_brew-formula-stable-version node)" || return "$?"
    local formula='' formulae=''
    formulae="$(brew info --json=v2 --formula node |
      perl -MJSON::PP -e 'local $/; my $data = eval { decode_json(<STDIN>) } or exit 74; print "$_\n" for @{$data->{formulae}[0]{versioned_formulae} || []}')" || return "$?"
    while IFS= read -r formula; do
      [[ -n "${formula}" ]] || continue
      raw="$(package::_brew-formula-stable-version "${formula}")" || return "$?"
      versions+=$'\n'"${raw}"
    done <<<"${formulae}"
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
    local formula='node' stable='' formulae='' candidate=''
    stable="$(package::_brew-formula-stable-version node)" || return "$?"
    if [[ "${version}" != "${stable}" ]]; then
      formula=''
      formulae="$(brew info --json=v2 --formula node |
        perl -MJSON::PP -e 'local $/; my $data = eval { decode_json(<STDIN>) } or exit 74; print "$_\n" for @{$data->{formulae}[0]{versioned_formulae} || []}')" || return "$?"
      while IFS= read -r candidate; do
        [[ -n "${candidate}" ]] || continue
        stable="$(package::_brew-formula-stable-version "${candidate}")" || return "$?"
        if [[ "${version}" == "${stable}" ]]; then formula="${candidate}"; break; fi
      done <<<"${formulae}"
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

# @description Write Docker Engine or Docker CLI versions available to the current platform.
#
# @noargs
# @stdout Docker Engine versions on Linux, or Docker CLI versions from Homebrew on macOS, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or Docker publishes nothing for this release.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   docker::versions | tail -n 1
docker::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture='' codename='' index_entries=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_versions docker
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      codename="$(docker::_ubuntu-codename)" || return "$?"
      index_entries="$(package::_deb-index-entries \
        "https://download.docker.com/linux/ubuntu/dists/${codename}/stable/binary-${architecture}/Packages" \
        docker-ce)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | package::_sort-versions
      ;;
    fedora)
      architecture="$(package::_rpm-architecture)" || return "$?"
      local release=''
      release="$(platform::_os-release-value VERSION_ID)" || return "$?"
      package::_rpm-repository-versions \
        "https://download.docker.com/linux/fedora/${release}/${architecture}/stable" docker-ce
      ;;
  esac
}

# @description Write the Ubuntu codename used by the Docker repository.
# @internal
docker::_ubuntu-codename() {
  [[ "$#" -eq 0 ]] || return 64
  platform::_os-release-value UBUNTU_CODENAME 2>/dev/null ||
    platform::_os-release-value VERSION_CODENAME
}

# @description Install the Docker CLI, and Docker Engine on Linux.
#
# On macOS, Colima or Rancher Desktop must already be installed and running.
# On Ubuntu and Fedora, the official Docker repository is registered and the
# docker service is enabled and started. Conflicting packages such as
# docker.io are removed only after the repository is ready, and are installed
# again when Docker cannot be installed.
#
# @arg $1 string Optional version from docker::versions. Defaults to the newest stable version.
# @stderr A message on macOS when no container runtime is running.
# @exitcode 0 Docker is installed, and on Linux the service is enabled and running.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or version is unsupported, or on macOS neither Colima nor Rancher Desktop is running.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager or systemctl.
# @example
#   docker::install
#   docker run --rm hello-world
docker::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) docker::_install-darwin "${version}" ;;
    ubuntu) docker::_install-ubuntu "${version}" ;;
    fedora) docker::_install-fedora "${version}" ;;
  esac
}

# @description Test whether Colima or Rancher Desktop is running on macOS.
# @internal
docker::_container-runtime-is-running() {
  [[ "$#" -eq 0 ]] || return 64
  if command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then
    return 0
  fi
  command -v pgrep >/dev/null 2>&1 && pgrep -f 'Rancher Desktop' >/dev/null 2>&1
}

# @description Install the Docker CLI plugins with Homebrew on macOS.
# @internal
docker::_install-darwin() {
  [[ "$#" -eq 1 ]] || return 64
  if ! docker::_container-runtime-is-running; then
    console::_write-error 'Install and start Colima or Rancher Desktop before installing Docker.'
    return 69
  fi
  local plugin='' prefix=''
  package::_install "docker${1:+=$1}" docker-credential-helper docker-compose docker-buildx || return "$?"
  prefix="$(brew --prefix)" || return 74
  mkdir -p -- "${HOME}/.docker/cli-plugins" || return 74
  for plugin in docker-buildx docker-compose; do
    ln -sfn "${prefix}/opt/${plugin}/bin/${plugin}" "${HOME}/.docker/cli-plugins/${plugin}" || return 74
  done
}

# @description Install Docker Engine from the official repository on Ubuntu.
# @internal
docker::_install-ubuntu() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" codename='' architecture='' package=''
  codename="$(docker::_ubuntu-codename)" || return "$?"
  architecture="$(package::_deb-architecture)" || return "$?"
  command::require curl || return "$?"
  if ! curl -fsSI "https://download.docker.com/linux/ubuntu/dists/${codename}/Release" >/dev/null 2>&1; then
    console::_write-error "The Docker repository does not provide Ubuntu ${codename}."
    return 69
  fi
  package::_refresh || return "$?"
  package::_install ca-certificates curl || return "$?"
  package::_apt-register-repository docker https://download.docker.com/linux/ubuntu/gpg \
    https://download.docker.com/linux/ubuntu "${codename}" stable "${architecture}" || return "$?"
  if [[ -n "${version}" ]] && ! apt-cache show "docker-ce=${version}" >/dev/null 2>&1; then
    console::_write-error "The Docker repository does not provide docker-ce ${version}."
    return 69
  fi
  # Conflicting runtimes are removed only once the replacement is available,
  # and they are installed again when the replacement fails.
  local status=0 removed=()
  for package in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q 'install ok installed' || continue
    if command::run-as-root env DEBIAN_FRONTEND=noninteractive apt-get remove -y "${package}" >/dev/null 2>&1; then
      removed+=("${package}")
    fi
  done
  package::_install "docker-ce${version:+=${version}}" "docker-ce-cli${version:+=${version}}" \
    containerd.io docker-buildx-plugin docker-compose-plugin || status="$?"
  if [[ "${status}" -ne 0 ]]; then
    [[ "${#removed[@]}" -eq 0 ]] || package::_install "${removed[@]}" || true
    return "${status}"
  fi
  package::_enable-service docker || return "$?"
  package::_add-current-user-to-group docker
}

# @description Install Docker Engine from the official repository on Fedora.
# @internal
docker::_install-fedora() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" cli_version="${1#*:}" repository='' buildx_package='docker-buildx-plugin' package=''
  repository="$(package::_fetch https://download.docker.com/linux/fedora/docker-ce.repo)" || return "$?"
  package::_dnf-register-repository docker-ce "${repository}"$'\n' || return "$?"
  if ! dnf list --available docker-buildx-plugin >/dev/null 2>&1; then
    buildx_package=''
  fi
  # dnf remove also matches what docker-ce provides, so only packages installed
  # under these exact names are removed; otherwise a second run removes Docker.
  # They are removed only after the repository is ready, and installed again
  # when the replacement fails.
  local status=0 removed=()
  for package in docker docker-client docker-client-latest docker-common docker-latest \
    docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine; do
    rpm -q "${package}" >/dev/null 2>&1 || continue
    if command::run-as-root dnf remove -y "${package}" >/dev/null 2>&1; then
      removed+=("${package}")
    fi
  done
  package::_install "docker-ce${version:+=${version}}" "docker-ce-cli${cli_version:+=${cli_version}}" \
    containerd.io ${buildx_package:+"${buildx_package}"} docker-compose-plugin || status="$?"
  if [[ "${status}" -ne 0 ]]; then
    [[ "${#removed[@]}" -eq 0 ]] || package::_install "${removed[@]}" || true
    return "${status}"
  fi
  if [[ -z "${version}" ]]; then
    command::run-as-root dnf upgrade -y docker-ce docker-ce-cli containerd.io \
      ${buildx_package:+"${buildx_package}"} docker-compose-plugin || return "$?"
  fi
  if [[ -z "${buildx_package}" ]]; then
    docker::_install-buildx-plugin || return "$?"
  fi
  package::_enable-service docker || return "$?"
  package::_add-current-user-to-group docker
}

# @description Install the official Buildx CLI plugin when the Docker RPM repository does not package it.
# @internal
docker::_install-buildx-plugin() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture='' directory='' status=0
  architecture="$(package::_rpm-architecture)" || return "$?"
  case "${architecture}" in
    x86_64) architecture='amd64' ;;
    aarch64) architecture='arm64' ;;
    *) return 69 ;;
  esac
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download \
    "https://github.com/docker/buildx/releases/download/v0.10.5/buildx-v0.10.5.linux-${architecture}" \
    "${directory}/docker-buildx" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /usr/local/lib/docker/cli-plugins || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0755 "${directory}/docker-buildx" \
      /usr/local/lib/docker/cli-plugins/docker-buildx || status=74
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

# @description Write Colima versions available from Homebrew.
#
# @noargs
# @stdout Colima versions from Homebrew, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of brew.
# @example
#   colima::versions
colima::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_versions colima
}

# @description Install Colima with Homebrew on macOS and start it.
#
# Colima's Docker runtime needs the docker command before it starts, so the
# Docker CLI formula is installed with it. Without Hypervisor.framework, as in
# a virtual machine without nested virtualization, the VM cannot boot, so the
# function returns 69 instead of starting it.
#
# @arg $1 string Optional Colima version; only the current Homebrew version is accepted.
# @stderr A message when Hypervisor.framework is unavailable.
# @exitcode 0 Colima is installed and running.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The system is not macOS, the version is not the current one, or Hypervisor.framework is unavailable.
# @exitcode other The status of brew or colima start.
# @example
#   colima::install
#   docker::install
colima::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_install-version colima "${1:-}" || return "$?"
  package::_install docker || return "$?"
  if colima status >/dev/null 2>&1; then
    return 0
  fi
  if [[ "$(sysctl -n kern.hv_support 2>/dev/null)" != 1 ]]; then
    console::_write-error 'Colima needs Hypervisor.framework, which this Mac does not provide.'
    return 69
  fi
  colima start
}

# @description Write the rbenv root directory.
# @internal
ruby::_rbenv-root() {
  [[ "$#" -eq 0 ]] || return 64
  printf '%s\n' "${RBENV_ROOT:-${HOME}/.rbenv}"
}

# @description Install rbenv and ruby-build.
# @internal
ruby::_install-rbenv() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' root=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    local outdated='' formula=''
    package::_install rbenv ruby-build || return "$?"
    # brew upgrade fails when a named formula is already current.
    outdated="$(brew outdated --formula --quiet rbenv ruby-build)" || return 74
    while IFS= read -r formula; do
      [[ -z "${formula}" ]] || brew upgrade "${formula}" || return "$?"
    done <<<"${outdated}"
    return 0
  fi
  command::require git || return "$?"
  root="$(ruby::_rbenv-root)"
  if [[ -d "${root}/.git" ]]; then
    git -C "${root}" pull --ff-only || return "$?"
  else
    git clone https://github.com/rbenv/rbenv.git "${root}" || return "$?"
  fi
  if [[ -d "${root}/plugins/ruby-build/.git" ]]; then
    git -C "${root}/plugins/ruby-build" pull --ff-only
  else
    git clone https://github.com/rbenv/ruby-build.git "${root}/plugins/ruby-build"
  fi
}

# @description Write the rbenv command path.
# @internal
ruby::_rbenv-command() {
  [[ "$#" -eq 0 ]] || return 64
  if command -v rbenv >/dev/null 2>&1; then
    command -v rbenv
    return 0
  fi
  local candidate=''
  candidate="$(ruby::_rbenv-root)/bin/rbenv"
  [[ -x "${candidate}" ]] || return 69
  printf '%s\n' "${candidate}"
}

# @description Configure Bash and Zsh startup files to initialize rbenv and apply it to this shell.
# @internal
ruby::_configure-shell() {
  [[ "$#" -eq 0 ]] || return 64
  local shell='' startup='' root=''
  root="$(ruby::_rbenv-root)"
  for shell in bash zsh; do
    startup="${HOME}/.${shell}rc"
    [[ -e "${startup}" ]] || : >"${startup}" || return 74
    if [[ -d "${root}/bin" ]]; then
      file::replace-text-or-append "${startup}" '^export PATH=.*\.rbenv/bin.*$' \
        "export PATH=\"${root}/bin:\${PATH}\"" || return "$?"
    fi
    file::replace-text-or-append "${startup}" '^.*rbenv init.*$' "eval \"\$(rbenv init - ${shell})\"" || return "$?"
  done
  [[ ! -d "${root}/bin" || ":${PATH}:" == *":${root}/bin:"* ]] || PATH="${root}/bin:${PATH}"
  [[ ":${PATH}:" == *":${root}/shims:"* ]] || PATH="${root}/shims:${PATH}"
  export PATH
}

# @description Install rbenv, configure the shell, and install a Ruby version globally.
#
# @arg $1 string Optional Ruby version such as 3.4.7. Defaults to ruby::version::latest.
# @exitcode 0 Ruby is installed and selected with rbenv global.
# @exitcode 64 The version is not major.minor.patch.
# @exitcode 69 rbenv is unavailable after installation.
# @exitcode other The status of the package manager, git, or rbenv install.
# @example
#   ruby::install 3.4.7
#   ruby --version
ruby::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" rbenv='' platform=''
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_install build-essential autoconf bison libssl-dev libreadline-dev \
        zlib1g-dev libyaml-dev libffi-dev || return "$?"
      ;;
    fedora)
      package::_install gcc gcc-c++ make autoconf bison openssl-devel readline-devel \
        zlib-devel libyaml-devel libffi-devel || return "$?"
      ;;
  esac
  ruby::_install-rbenv || return "$?"
  ruby::_configure-shell || return "$?"
  rbenv="$(ruby::_rbenv-command)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(ruby::version::latest)" || return "$?"
  fi
  "${rbenv}" install --skip-existing "${version}" || return "$?"
  "${rbenv}" global "${version}" || return "$?"
  "${rbenv}" rehash
}

# @description Write JDK feature release numbers available to the current platform.
#
# @noargs
# @stdout JDK feature release numbers such as 17 and 21, one per line, oldest first.
# @exitcode 0 The numbers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or the package tool is missing.
# @exitcode 74 The package list could not be read.
# @example
#   jdk::version::list
jdk::version::list() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' versions='' name=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      versions="$(package::_brew-formula-versions openjdk)" || return "$?"
      while IFS= read -r name; do
        if [[ -n "${name}" ]]; then printf '%s\n' "${name%%.*}"; fi
      done <<<"${versions}" | package::_sort-versions
      ;;
    ubuntu)
      command::require apt-cache || return "$?"
      versions="$(apt-cache pkgnames openjdk- 2>/dev/null)" || return 74
      while IFS= read -r name; do
        if [[ "${name}" =~ ^openjdk-([0-9]+)-jdk$ ]]; then
          printf '%s\n' "${BASH_REMATCH[1]}"
        fi
      done <<<"${versions}" | package::_sort-versions
      ;;
    fedora)
      command::require dnf || return "$?"
      versions="$(dnf repoquery --quiet --queryformat $'%{name} %{version}\n' \
        'java-*-openjdk-devel' 2>/dev/null)" || return 74
      while IFS=' ' read -r name _; do
        if [[ "${name}" =~ ^java-([0-9]+)-openjdk-devel$ ]]; then
          printf '%s\n' "${BASH_REMATCH[1]}"
        fi
      done <<<"${versions}" | package::_sort-versions
      ;;
  esac
}

# @description Write the newest JDK feature release number available to the current platform.
#
# @noargs
# @stdout The newest JDK feature release number.
# @exitcode 0 The number was written.
# @exitcode 1 No JDK is available.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or the package tool is missing.
# @example
#   jdk::install "$(jdk::version::latest)"
jdk::version::latest() {
  [[ "$#" -eq 0 ]] || return 64
  jdk::version::list | package::_latest-stable-version
}

# @description Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH.
#
# @arg $1 string Optional feature release number such as 21. Defaults to jdk::version::latest.
# @exitcode 0 The JDK is installed and JAVA_HOME and PATH point to it.
# @exitcode 64 The version is not a number.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode 74 java is missing from the selected JDK.
# @exitcode other The status of the package manager or the alternatives tool.
# @example
#   jdk::install 21
#   java -version
jdk::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' home=''
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+$ ]] ) || return 64
  platform="$(package::_platform)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(jdk::version::latest)" || return "$?"
  fi
  case "${platform}" in
    darwin) home="$(jdk::_install-darwin "${version}")" || return "$?" ;;
    ubuntu) home="$(jdk::_install-ubuntu "${version}")" || return "$?" ;;
    fedora) home="$(jdk::_install-fedora "${version}")" || return "$?" ;;
  esac
  [[ -x "${home}/bin/java" ]] || return 74
  env::set-variable JAVA_HOME "${home}" || return "$?"
  env::add-path "${home}/bin"
}

# @description Install an OpenJDK formula on macOS and write its Java home.
# @internal
jdk::_install-darwin() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" stable='' formula='openjdk' prefix=''
  stable="$(package::_brew-formula-stable-version openjdk)" || return "$?"
  [[ "${stable%%.*}" == "${version}" ]] || formula="openjdk@${version}"
  package::_install "${formula}" >&2 || return "$?"
  prefix="$(brew --prefix)" || return 74
  command::run-as-root ln -sfn "${prefix}/opt/${formula}/libexec/openjdk.jdk" \
    "/Library/Java/JavaVirtualMachines/openjdk-${version}.jdk" >&2 || return 74
  command::require /usr/libexec/java_home || return "$?"
  /usr/libexec/java_home -v "${version}"
}

# @description Select the Java and Java compiler alternatives below a Java home.
# @internal
jdk::_select-alternatives() {
  [[ "$#" -eq 2 && -d "$2" ]] || return 64
  local tool=''
  command::require "$1" || return "$?"
  for tool in java javac; do
    [[ -x "$2/bin/${tool}" ]] || return 74
    command::run-as-root "$1" --set "${tool}" "$2/bin/${tool}" >&2 || return "$?"
  done
}

# @description Install an OpenJDK package on Ubuntu and write its Java home.
# @internal
jdk::_install-ubuntu() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" architecture='' home=''
  package::_install "openjdk-${version}-jdk" >&2 || return "$?"
  architecture="$(package::_deb-architecture)" || return "$?"
  home="/usr/lib/jvm/java-${version}-openjdk-${architecture}"
  jdk::_select-alternatives update-alternatives "${home}" || return "$?"
  printf '%s\n' "${home}"
}

# @description Install an OpenJDK package on Fedora and write its Java home.
# @internal
jdk::_install-fedora() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" home=''
  package::_install "java-${version}-openjdk-devel" >&2 || return "$?"
  command::require readlink || return "$?"
  home="$(readlink -f "/usr/lib/jvm/java-${version}-openjdk")" || return 74
  jdk::_select-alternatives alternatives "${home}" || return "$?"
  printf '%s\n' "${home}"
}

# @description Write the major.minor.patch version of the Python 3 interpreter.
# @internal
pipx::_python-version() {
  [[ "$#" -eq 0 ]] || return 64
  command::require python3 || return "$?"
  python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' || return 74
}

# @description Write pipx releases on PyPI whose Requires-Python accepts PYTHON_VERSION.
# @internal
pipx::_official-versions() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  command::require perl || return "$?"
  local json='' versions=''
  json="$(package::_fetch https://pypi.org/pypi/pipx/json)" || return "$?"
  versions="$(printf '%s' "${json}" | perl -MJSON::PP -e '
    my @python = split /\./, shift;
    sub compare {
      my ($left, $right) = @_;
      for my $index (0 .. ($#$left > $#$right ? $#$left : $#$right)) {
        my $difference = ($left->[$index] // 0) <=> ($right->[$index] // 0);
        return $difference if $difference;
      }
      return 0;
    }
    # Accepts the PEP 440 operators that Requires-Python uses; anything else rejects the release.
    sub accepts {
      my ($specifiers) = @_;
      for my $specifier (split /\s*,\s*/, $specifiers) {
        next if $specifier eq "";
        $specifier =~ /^(~=|==|!=|<=|>=|<|>)\s*([0-9]+(?:\.[0-9]+)*)(\.\*)?$/ or return 0;
        my ($operator, $wildcard) = ($1, $3);
        my @version = split /\./, $2;
        if ($wildcard) {
          my $same = compare([@python[0 .. $#version]], \@version) == 0;
          return 0 if ($operator eq "==" && !$same) || ($operator eq "!=" && $same);
          return 0 if $operator ne "==" && $operator ne "!=";
          next;
        }
        my $order = compare(\@python, \@version);
        return 0 if $operator eq ">=" && $order < 0;
        return 0 if $operator eq ">" && $order <= 0;
        return 0 if $operator eq "<=" && $order > 0;
        return 0 if $operator eq "<" && $order >= 0;
        return 0 if $operator eq "==" && $order != 0;
        return 0 if $operator eq "!=" && $order == 0;
        if ($operator eq "~=") {
          return 0 if $order < 0 || @version < 2;
          return 0 if compare([@python[0 .. $#version - 1]], [@version[0 .. $#version - 1]]) != 0;
        }
      }
      return 1;
    }
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    while (my ($release, $files) = each %{$data->{releases} || {}}) {
      my @files = grep { !$_->{yanked} } @$files;
      next unless @files && $release =~ /^[0-9]+(?:\.[0-9]+)*$/;
      print "$release\n" if accepts($files[0]{requires_python} // "");
    }
  ' "$1")" || return "$?"
  printf '%s\n' "${versions}" | package::_sort-stable-versions
}

# @description Write pipx versions available from the selected source.
#
# The official source lists the PyPI releases that the installed Python 3
# can run.
#
# @arg $1 string Optional source: os (default) or official.
# @stdout pipx versions, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 The source is not os or official.
# @exitcode 69 Python 3 is missing for the official source.
# @exitcode 74 The PyPI index could not be downloaded or read.
# @example
#   pipx::versions official | tail -n 1
pipx::versions() {
  [[ "$#" -le 1 ]] || return 64
  local source="${1:-os}" python_version=''
  [[ "${source}" == os || "${source}" == official ]] || return 64
  if [[ "${source}" == os ]]; then
    package::_versions pipx
    return
  fi
  python_version="$(pipx::_python-version)" || return "$?"
  pipx::_official-versions "${python_version}"
}

# @description Install pipx and add the pipx application directory to PATH.
#
# The os source installs the package of the system package manager. The
# official source installs the release from PyPI for the current user with
# pip, as the pipx documentation describes for systems without a package.
# A source that cannot provide pipx returns an error instead of switching to
# the other source. On Ubuntu, python3-venv is installed with either source,
# because pipx creates a virtual environment for every application.
#
# @arg $1 string Optional version from pipx::versions for the same source.
# @arg $2 string Optional source: os (default) or official.
# @stderr A message when the source cannot provide pipx.
# @exitcode 0 pipx is installed and ~/.local/bin is on PATH.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The source cannot provide pipx, or the installed version differs.
# @exitcode 74 The application directory could not be created.
# @exitcode other The status of the package manager or pip.
# @example
#   pipx::install
#   pipx install pycowsay
pipx::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" source="${2:-os}" platform='' versions='' installed=''
  [[ "${source}" == os || "${source}" == official ]] || return 64
  platform="$(package::_platform)" || return "$?"
  if [[ "${source}" == os ]]; then
    versions="$(pipx::versions os)" || return "$?"
    if [[ -z "${versions}" ]]; then
      console::_write-error 'The system packages do not provide pipx; use the official source.'
      return 69
    fi
    package::_install-version pipx "${version}" || return "$?"
    if [[ "${platform}" == ubuntu ]]; then
      # Ubuntu ships venv separately, and the pipx package of 20.04 does not require it.
      package::_install python3-venv || return "$?"
    fi
  else
    case "${platform}" in
      ubuntu) package::_refresh && package::_install python3-pip python3-venv || return "$?" ;;
      fedora) package::_install python3-pip || return "$?" ;;
      *)
        console::_write-error 'Install pipx from Homebrew with the os source on macOS.'
        return 69
        ;;
    esac
    versions="$(pipx::versions official)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" pipx)" || return "$?"
    python3 -m pip install --user "pipx==${version}" || return "$?"
    installed="$("${HOME}/.local/bin/pipx" --version)" || return 69
    if [[ "${installed}" != "${version}" ]]; then
      console::_write-error "pip installed pipx ${installed} instead of ${version}."
      return 69
    fi
  fi
  mkdir -p -- "${HOME}/.local/bin" || return 74
  env::add-path "${HOME}/.local/bin"
}

# @description Set one handler with duti, skipping a type that macOS does not know.
#
# An extension that no installed application declares has only a dynamic
# UTI, and a UTI that the running macOS does not define has no hierarchy;
# LaunchServices refuses both, so they are reported and skipped.
# @internal
vscode::_set-handler() {
  [[ "$#" -eq 2 ]] || return 64
  local output='' status=0
  output="$(duti -s "$1" "$2" all 2>&1)" || status="$?"
  [[ "${status}" -ne 0 ]] || return 0
  if [[ "${output}" == *' for dyn.'* || "${output}" == *'does not conform to any UTI hierarchy'* ]]; then
    console::_write-error "Skipped $2, which this macOS does not declare as a file type."
    return 0
  fi
  printf '%s\n' "${output}" >&2
  return "${status}"
}

# @description Set VS Code as the default application for text and source file types on macOS.
#
# Extensions and UTIs that this macOS does not declare are reported and
# skipped; any other failure returns its status.
#
# @noargs
# @stderr Each skipped extension or UTI.
# @exitcode 0 VS Code opens the listed types.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS, or duti is unavailable.
# @exitcode other The status of duti.
# @example
#   vscode::set-default-app
vscode::set-default-app() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require duti || return "$?"
  local bundle='com.microsoft.VSCode' type=''
  local extensions=(
    txt text md markdown mdown mkd json jsonc yaml yml toml ini conf config env log csv tsv
    xml html htm css scss sass js jsx ts tsx mjs cjs sh bash zsh fish py rb php java c h cpp
    hpp cs go rs sql graphql gql Dockerfile gitignore
  )
  local types=(
    public.plain-text public.text public.utf8-plain-text public.unix-executable
    public.shell-script net.daringfireball.markdown public.json public.yaml public.xml
    public.html public.css public.javascript public.comma-separated-values-text
    public.tab-separated-values-text public.source-code
  )
  for type in "${extensions[@]}"; do
    vscode::_set-handler "${bundle}" ".${type}" || return "$?"
  done
  for type in "${types[@]}"; do
    vscode::_set-handler "${bundle}" "${type}" || return "$?"
  done
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -kill -r -domain local -domain system -domain user >/dev/null 2>&1
  killall Finder >/dev/null 2>&1 || true
}

# @description Set IINA as the default application for video file extensions on macOS.
#
# duti is installed with Homebrew when it is missing.
#
# @noargs
# @exitcode 0 IINA opens the listed video types.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS.
# @exitcode other The status of brew or duti.
# @example
#   iina::set-default-app
iina::set-default-app() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  local bundle='com.colliderli.iina' extension=''
  local extensions=(
    mp4 mkv mov avi wmv flv webm m4v mpg mpeg 3gp ts m2ts mts ogv vob asf f4v rmvb divx
  )
  if ! command -v duti >/dev/null 2>&1; then
    package::_install duti || return "$?"
  fi
  for extension in "${extensions[@]}"; do
    duti -s "${bundle}" "${extension}" all || return "$?"
  done
}

# @description Write UTM release versions.
#
# @noargs
# @stdout Stable UTM release versions, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 Perl is unavailable.
# @exitcode 74 The GitHub release list could not be downloaded or read.
# @example
#   utm::versions | tail -n 1
utm::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_github-release-versions utmapp/UTM
}

# @description Install UTM from its release disk image on macOS.
#
# @arg $1 string Optional UTM release version. Defaults to the newest stable release.
# @arg $2 string Optional destination directory. Defaults to /Applications.
# @exitcode 0 UTM.app was copied to the destination.
# @exitcode 64 The argument count is wrong.
# @exitcode 66 The destination directory does not exist.
# @exitcode 69 The system is not macOS, or hdiutil is unavailable.
# @exitcode 74 The disk image could not be downloaded, mounted, or copied.
# @example
#   utm::install 4.6.4
utm::install() {
  [[ "$#" -le 2 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require hdiutil || return "$?"
  local version="${1:-}" applications="${2:-/Applications}" directory='' mount='' status=0
  [[ -d "${applications}" ]] || return 66
  if [[ -z "${version}" ]]; then
    version="$(utm::versions | package::_latest-stable-version)" || return "$?"
  fi
  directory="$(package::_temporary-directory)" || return "$?"
  mount="${directory}/mount"
  package::_download "https://github.com/utmapp/UTM/releases/download/v${version}/UTM.dmg" \
    "${directory}/UTM.dmg" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    mkdir -p -- "${mount}" && hdiutil attach -nobrowse -readonly -mountpoint "${mount}" \
      "${directory}/UTM.dmg" >/dev/null || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    utm::_copy-application "${mount}/UTM.app" "${applications}" || status="$?"
    hdiutil detach "${mount}" >/dev/null 2>&1 || status=74
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

# @description Replace an application bundle in a destination directory.
#
# The new bundle is copied beside the old one first, and the old bundle is
# removed only after the new one is in place; on failure the old one stays.
#
# @internal
utm::_copy-application() {
  [[ "$#" -eq 2 && -d "$1" && -d "$2" ]] || return 64
  local runner=() name='' target='' staged='' previous=''
  name="$(path::base-name "$1")" || return 64
  target="$2/${name}"
  staged="$2/.${name}.bashstock-new"
  previous="$2/.${name}.bashstock-old"
  [[ -w "$2" ]] || runner=(command::run-as-root)
  ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}" "${previous}" || return 74
  if ! ${runner[@]+"${runner[@]}"} cp -R -- "$1" "${staged}"; then
    ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}"
    return 74
  fi
  if [[ -e "${target}" ]] && ! ${runner[@]+"${runner[@]}"} mv -- "${target}" "${previous}"; then
    ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}"
    return 74
  fi
  if ! ${runner[@]+"${runner[@]}"} mv -- "${staged}" "${target}"; then
    [[ ! -e "${previous}" ]] || ${runner[@]+"${runner[@]}"} mv -- "${previous}" "${target}"
    ${runner[@]+"${runner[@]}"} rm -rf -- "${staged}"
    return 74
  fi
  ${runner[@]+"${runner[@]}"} rm -rf -- "${previous}" || return 74
}

# @description Write supported Ubuntu LTS versions from the Ubuntu release metadata.
#
# Releases newer than the last upgrade-supported release are included because
# Write the Ubuntu Server ISO architecture for the current machine, or validate one.
# @internal
ubuntu::_server-iso-architecture() {
  [[ "$#" -le 1 ]] || return 64
  local architecture="${1:-}"
  if [[ -z "${architecture}" ]]; then
    case "$(uname -m)" in
      x86_64 | amd64) architecture='amd64' ;;
      arm64 | aarch64) architecture='arm64' ;;
      *) return 69 ;;
    esac
  fi
  [[ "${architecture}" == amd64 || "${architecture}" == arm64 ]] || return 64
  printf '%s\n' "${architecture}"
}

# @description Write the directory URL that publishes Ubuntu Server ISOs of one LTS series.
# @internal
ubuntu::_server-iso-directory() {
  ( [[ "$#" -eq 2 && "$1" =~ ^[0-9]+\.[0-9]+$ ]] ) || return 64
  case "$2" in
    amd64) printf 'https://releases.ubuntu.com/%s/\n' "$1" ;;
    arm64) printf 'https://cdimage.ubuntu.com/releases/%s/release/\n' "$1" ;;
    *) return 64 ;;
  esac
}

# @description Write SHA-256 and file name pairs of the live server ISOs that one LTS series publishes.
# @internal
ubuntu::_server-iso-checksums() {
  [[ "$#" -eq 2 ]] || return 64
  local directory='' sums=''
  directory="$(ubuntu::_server-iso-directory "$1" "$2")" || return "$?"
  sums="$(package::_fetch "${directory}SHA256SUMS" 2>/dev/null)" || return 0
  printf '%s\n' "${sums}" |
    awk -v arch="$2" '$2 ~ ("^\\*?ubuntu-[0-9.]+-live-server-" arch "\\.iso$") { sub(/^\*/, "", $2); print $1 "\t" $2 }'
}

# @description Write the Ubuntu Server LTS versions whose live server ISO is published for an architecture.
#
# The LTS series come from the Ubuntu release metadata, and each version is
# taken from the official SHA256SUMS of its series, so every listed version
# can be downloaded.
#
# @arg $1 string Optional architecture: amd64 or arm64. Defaults to the current machine.
# @stdout Ubuntu Server versions such as 24.04.3, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 The architecture is not amd64 or arm64.
# @exitcode 69 No image is published for the architecture.
# @exitcode 74 The release metadata could not be downloaded.
# @example
#   ubuntu::server-iso-versions arm64
ubuntu::server-iso-versions() {
  [[ "$#" -le 1 ]] || return 64
  local architecture='' metadata='' series='' versions=''
  architecture="$(ubuntu::_server-iso-architecture "${1:-}")" || return "$?"
  metadata="$(package::_fetch https://changelogs.ubuntu.com/meta-release-lts)" || return "$?"
  while IFS= read -r series; do
    [[ -n "${series}" ]] || continue
    versions+="$(ubuntu::_server-iso-checksums "${series}" "${architecture}" |
      sed -E 's/^[^\t]*\tubuntu-([0-9.]+)-live-server-.*/\1/')"$'\n'
  done < <(printf '%s\n' "${metadata}" | sed -nE 's/^Version:[[:space:]]*([0-9]+\.[0-9]+).*/\1/p' | sort -u)
  versions="$(printf '%s' "${versions}" | package::_sort-versions)"
  [[ -n "${versions}" ]] || return 69
  printf '%s\n' "${versions}"
}

# @description Download an Ubuntu Server live ISO and check it against the official SHA256SUMS.
#
# The image is written to a temporary file next to OUTPUT_PATH and moved into
# place only after its checksum matches, so a failed download or a corrupted
# image leaves an existing file unchanged.
#
# @arg $1 string Optional version from ubuntu::server-iso-versions. Defaults to the newest one.
# @arg $2 string Optional architecture: amd64 or arm64. Defaults to the current machine.
# @arg $3 string Optional destination file. Defaults to the official file name in the current directory.
# @exitcode 0 The verified image is at the destination.
# @exitcode 64 The architecture is invalid, or the argument count is wrong.
# @exitcode 69 The version is not published for the architecture.
# @exitcode 74 The download failed, the checksum does not match, or the file could not be moved.
# @example
#   ubuntu::download-server-iso 24.04.3 amd64 "${HOME}/iso/ubuntu.iso"
ubuntu::download-server-iso() {
  [[ "$#" -le 3 ]] || return 64
  local version="${1:-}" architecture='' output="${3:-}" versions='' series='' name='' directory=''
  local checksum='' temporary='' status=0
  architecture="$(ubuntu::_server-iso-architecture "${2:-}")" || return "$?"
  versions="$(ubuntu::server-iso-versions "${architecture}")" || return "$?"
  version="$(package::_select-listed-version "${versions}" "${version}" 'Ubuntu Server ISO')" || return "$?"
  series="$(printf '%s' "${version}" | cut -d . -f 1-2)"
  name="ubuntu-${version}-live-server-${architecture}.iso"
  checksum="$(ubuntu::_server-iso-checksums "${series}" "${architecture}" | awk -F '\t' -v name="${name}" '$2 == name {print $1}')"
  ( [[ "${checksum}" =~ ^[0-9a-f]{64}$ ]] ) || return 74
  directory="$(ubuntu::_server-iso-directory "${series}" "${architecture}")" || return "$?"
  [[ -n "${output}" ]] || output="./${name}"
  temporary="$(mktemp "${output}.XXXXXX")" || return 74
  package::_download "${directory}${name}" "${temporary}" || status="$?"
  if [[ "${status}" -eq 0 ]] && ! file::verify-sha256 "${temporary}" "${checksum}"; then
    console::_write-error "The downloaded ${name} does not match the official SHA256SUMS."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    mv -f -- "${temporary}" "${output}" || status=74
  fi
  rm -f -- "${temporary}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  printf '%s\n' "${output}"
}

# @description Write Rancher Desktop versions available to the current platform.
#
# @noargs
# @stdout Rancher Desktop versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   rancher-desktop::versions
rancher-desktop::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' index_entries=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions rancher
      ;;
    ubuntu)
      index_entries="$(package::_deb-index-entries \
        https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Packages rancher-desktop)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | package::_sort-versions
      ;;
    fedora)
      package::_rpm-repository-versions \
        https://download.opensuse.org/repositories/isv:/Rancher:/stable/rpm/ rancher-desktop
      ;;
  esac
}

# @description Install Rancher Desktop and start it.
#
# Rosetta and Colima are installed separately with rosetta::install and colima::install.
#
# @arg $1 string Optional version from rancher-desktop::versions; on macOS only the current version.
# @stderr On Linux, a reminder to log in again when the user was added to the kvm group.
# @exitcode 0 Rancher Desktop is installed and was started.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   rancher-desktop::install
rancher-desktop::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_install-cask rancher "${version}" || return "$?"
      rancher-desktop::_start-darwin
      ;;
    ubuntu | fedora)
      rancher-desktop::_install-linux "${platform}" "${version}" || return "$?"
      rancher-desktop::_start-linux
      ;;
  esac
}

# @description Register the Rancher Desktop repository and install the package on Linux.
# @internal
rancher-desktop::_install-linux() {
  [[ "$#" -eq 2 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    package::_apt-register-repository isv-rancher-stable \
      https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key \
      https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./ '' || return "$?"
  else
    package::_dnf-register-repository isv-rancher-stable \
      "[isv-rancher-stable]
name=Rancher Desktop
baseurl=https://download.opensuse.org/repositories/isv:/Rancher:/stable/rpm/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/Rancher:/stable/rpm/repodata/repomd.xml.key
" || return "$?"
  fi
  package::_install-version rancher-desktop "$2" || return "$?"
  if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    package::_add-current-user-to-group kvm || return "$?"
    console::_write-error 'Log in again so that the kvm group membership takes effect.'
  fi
}

# @description Start Rancher Desktop in the background on macOS.
#
# The path works before LaunchServices has registered the new application.
# open waits while macOS shows a first-launch confirmation, so it runs in the
# background and the setup continues, as on Linux.
# @internal
rancher-desktop::_start-darwin() {
  [[ "$#" -eq 0 ]] || return 64
  local application='/Applications/Rancher Desktop.app'
  if [[ -d "${application}" ]]; then
    (open "${application}" >/dev/null 2>&1 &)
  else
    (open -a 'Rancher Desktop' >/dev/null 2>&1 &)
  fi
}

# @description Start Rancher Desktop in the background on Linux.
# @internal
rancher-desktop::_start-linux() {
  [[ "$#" -eq 0 ]] || return 64
  command::require rancher-desktop || return "$?"
  (rancher-desktop >/dev/null 2>&1 &)
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
#   key-binding::disable-option-t
key-binding::disable-option-t() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  plist::set "${HOME}/Library/KeyBindings/DefaultKeyBinding.dict" '~t' 'noop:'
}

# @description Write pass versions available to the current platform.
#
# @noargs
# @stdout pass versions from the platform package manager, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   pass::versions
pass::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions pass
}

# @description Install pass from the platform package manager.
#
# @arg $1 string Optional version from pass::versions. Defaults to the newest one.
# @exitcode 0 pass is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   pass::install
#   pass init "$(gpg::secret-key::fingerprints | head -n 1)"
pass::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version pass "${1:-}"
}

# @description Write PlantUML versions available to the current platform.
#
# @noargs
# @stdout PlantUML versions from the platform package manager, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   plantuml::versions
plantuml::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions plantuml
}

# @description Install PlantUML from the platform package manager.
#
# @arg $1 string Optional version from plantuml::versions. Defaults to the newest one.
# @exitcode 0 PlantUML is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   plantuml::install
#   plantuml -tsvg diagram.puml
plantuml::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version plantuml "${1:-}"
}

# @description Write Graphviz versions available to the current platform.
#
# @noargs
# @stdout Graphviz versions from the platform package manager, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   graphviz::versions
graphviz::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions graphviz
}

# @description Install Graphviz from the platform package manager.
#
# @arg $1 string Optional version from graphviz::versions. Defaults to the newest one.
# @exitcode 0 Graphviz is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   graphviz::install
#   dot -Tpng graph.dot -o graph.png
graphviz::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version graphviz "${1:-}"
}

# @description Write stable Flutter SDK versions for the current platform.
#
# @noargs
# @stdout Stable Flutter versions such as 3.35.7, one per line, oldest first.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 Perl is unavailable, or the platform is unsupported.
# @exitcode 74 The release index could not be downloaded or read.
# @example
#   flutter::versions | tail -n 1
flutter::versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local platform='' index='linux' json='' versions=''
  platform="$(package::_platform)" || return "$?"
  [[ "${platform}" != 'darwin' ]] || index='macos'
  json="$(package::_fetch "https://storage.googleapis.com/flutter_infra_release/releases/releases_${index}.json")" || return "$?"
  versions="$(printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    for my $release (@{$data->{releases} || []}) {
      print "$release->{version}\n"
        if $release->{channel} eq "stable" && $release->{version} =~ /^[0-9]+\.[0-9]+\.[0-9]+$/;
    }
  ')" || return "$?"
  printf '%s\n' "${versions}" | package::_sort-stable-versions
}

# @description Install packages required to build Flutter applications.
#
# @noargs
# @exitcode 0 The build dependencies are installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or git or curl is missing on macOS.
# @exitcode 74 The C++ development package could not be determined.
# @exitcode other The status of the package manager.
# @example
#   flutter::dependencies::install
flutter::dependencies::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' library=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      command::require git || return "$?"
      command::require curl
      ;;
    ubuntu)
      package::_refresh || return "$?"
      command::require apt-cache || return "$?"
      library="$(apt-cache pkgnames 'libstdc++-' |
        awk '/^libstdc\+\+-[0-9]+-dev$/ {name=$0; sub(/^libstdc\+\+-/, "", $0); sub(/-dev$/, "", $0); print $0, name}' |
        sort -n | tail -n 1 | awk '{print $2}')" || return 74
      [[ -n "${library}" ]] || return 69
      package::_install curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build \
        pkg-config libgtk-3-dev "${library}"
      ;;
    fedora)
      package::_install curl git unzip xz zip mesa-libGLU clang cmake ninja-build \
        pkgconf-pkg-config gtk3-devel libstdc++-devel
      ;;
  esac
}

# @description Install dependencies and select a stable Flutter SDK version.
#
# An existing Flutter repository retains its stash and ignored files.
#
# Limitation: Flutter builds Linux desktop applications on Ubuntu 20.04 and
# later only. Ubuntu 18.04 installs the SDK and runs Dart code and tests,
# but `flutter build linux` stops there because it needs CMake 3.13 and the
# release provides 3.10.
#
# @arg $1 string Optional stable Flutter version. Defaults to the newest stable release.
# @arg $2 string Optional SDK directory. Defaults to $HOME/.local/flutter.
# @stderr A message when the directory holds something other than a Flutter SDK.
# @exitcode 0 The SDK is at the version and its bin directory is on PATH.
# @exitcode 64 The version is not major.minor.patch.
# @exitcode 69 The platform is unsupported.
# @exitcode 73 The directory is neither empty nor a Flutter SDK.
# @exitcode other The status of the dependency installation, git, or flutter.
# @example
#   flutter::install 3.35.7
#   flutter doctor
flutter::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" directory="${2:-${HOME}/.local/flutter}"
  ( [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ) || return 64
  flutter::dependencies::install || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(flutter::versions | package::_latest-stable-version)" || return "$?"
  fi
  if [[ -e "${directory}" ]]; then
    if [[ -x "${directory}/bin/flutter" && -d "${directory}/.git" ]]; then
      flutter::use-version "${version}" "${directory}" || return "$?"
    elif ! path::is-empty-directory "${directory}"; then
      console::_write-error "Directory is not a Flutter SDK: ${directory}"
      return 73
    fi
  fi
  mkdir -p -- "$(path::directory-name "${directory}")" || return 74
  if [[ ! -d "${directory}/.git" ]]; then
    git clone --branch "${version}" https://github.com/flutter/flutter.git "${directory}" ||
      return "$?"
  fi
  [[ -x "${directory}/bin/flutter" ]] || return 69
  env::add-path "${directory}/bin" || return "$?"
  "${directory}/bin/flutter" --version
}

# @description Set VLC as the default application for every MIME type it declares.
#
# @noargs
# @exitcode 0 VLC opens every MIME type it declares.
# @exitcode 64 An argument was given.
# @exitcode 66 VLC's desktop file was not found or declares no MIME type.
# @exitcode 69 xdg-mime is unavailable.
# @exitcode other The status of xdg-mime.
# @example
#   vlc::set-default-app
#   xdg-mime query default video/mp4
vlc::set-default-app() {
  [[ "$#" -eq 0 ]] || return 64
  command::require xdg-mime || return "$?"
  local desktop='' candidate='' declared='' mime_type=''
  local mime_types=()
  for candidate in /usr/share/applications/vlc.desktop /usr/share/applications/org.videolan.VLC.desktop; do
    [[ -f "${candidate}" ]] && desktop="${candidate}" && break
  done
  [[ -n "${desktop}" ]] || return 66
  declared="$(awk -F= '$1 == "MimeType" {print $2; exit}' "${desktop}")"
  [[ -n "${declared}" ]] || return 66
  IFS=';' read -r -a mime_types <<<"${declared}"
  for mime_type in "${mime_types[@]}"; do
    [[ -n "${mime_type}" ]] || continue
    xdg-mime default "$(path::base-name "${desktop}")" "${mime_type}" || return "$?"
  done
}

# @description Write the platform package name for a Mozc component.
# @internal
mozc::_package-name() {
  [[ "$#" -eq 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}:$1" in
    ubuntu:server) printf 'mozc-server\n' ;;
    ubuntu:ibus) printf 'ibus-mozc\n' ;;
    ubuntu:tool) printf 'mozc-utils-gui\n' ;;
    fedora:server) printf 'mozc\n' ;;
    fedora:ibus) printf 'ibus-mozc\n' ;;
    fedora:tool) printf 'mozc\n' ;;
    *)
      console::_write-error "Mozc packages are unavailable on ${platform}."
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
#   mozc::server::versions
mozc::server::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(mozc::_package-name server)" || return "$?"
  package::_versions "${package}"
}

# @description Install the Mozc server, defaulting to the newest version for the running release.
#
# @arg $1 string Optional version from mozc::server::versions. Defaults to the newest one.
# @exitcode 0 The Mozc server is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   mozc::server::install
mozc::server::install() {
  [[ "$#" -le 1 ]] || return 64
  local package='' version="${1:-}"
  package="$(mozc::_package-name server)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(package::_latest-version "${package}")" || return "$?"
  fi
  package::_install "${package}=${version}"
}

# @description Write IBus Mozc versions provided for the running operating-system release.
#
# @noargs
# @stdout IBus Mozc package versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   mozc::ibus::versions
mozc::ibus::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(mozc::_package-name ibus)" || return "$?"
  package::_versions "${package}"
}

# @description Install IBus Mozc and the Mozc server of the same version.
#
# @arg $1 string Optional version from mozc::ibus::versions. Defaults to the newest one.
# @exitcode 0 IBus Mozc, and the server of the same version when provided, are installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   mozc::ibus::install
mozc::ibus::install() {
  [[ "$#" -le 1 ]] || return 64
  local package='' server='' version="${1:-}"
  package="$(mozc::_package-name ibus)" || return "$?"
  server="$(mozc::_package-name server)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(package::_latest-version "${package}")" || return "$?"
  fi
  if package::_versions "${server}" 2>/dev/null | grep -Fqx -- "${version}"; then
    package::_install "${package}=${version}" "${server}=${version}"
  else
    package::_install "${package}=${version}"
  fi
}

# @description Write Mozc GUI tool versions provided for the running operating-system release.
#
# @noargs
# @stdout Mozc GUI tool package versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   mozc::tool::versions
mozc::tool::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(mozc::_package-name tool)" || return "$?"
  package::_versions "${package}"
}

# @description Install the Mozc GUI tools.
#
# @arg $1 string Optional version from mozc::tool::versions. Defaults to the newest one.
# @exitcode 0 The Mozc GUI tools are installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager.
# @example
#   mozc::tool::install
#   mozc::config::open
mozc::tool::install() {
  [[ "$#" -le 1 ]] || return 64
  local package=''
  package="$(mozc::_package-name tool)" || return "$?"
  package::_install-version "${package}" "${1:-}"
}

# @description Write the OpenSSH server package and service names for the current platform.
# @internal
ssh-server::_names() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu) printf 'openssh-server ssh\n' ;;
    fedora) printf 'openssh-server sshd\n' ;;
    *)
      console::_write-error 'Install the OpenSSH server on Ubuntu or Fedora.'
      return 69
      ;;
  esac
}

# @description Write OpenSSH server versions available to the current platform.
#
# @noargs
# @stdout OpenSSH server package versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   ssh-server::versions
ssh-server::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local server_names=''
  server_names="$(ssh-server::_names)" || return "$?"
  package::_versions "${server_names%% *}"
}

# @description Install the OpenSSH server, enable it at boot, and start it.
#
# @arg $1 string Optional version from ssh-server::versions. Defaults to the newest one.
# @exitcode 0 The server is installed, enabled at boot, and running.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager or systemctl.
# @example
#   ssh-server::install
ssh-server::install() {
  [[ "$#" -le 1 ]] || return 64
  local server_names=''
  server_names="$(ssh-server::_names)" || return "$?"
  package::_install-version "${server_names%% *}" "${1:-}" || return "$?"
  package::_enable-service "${server_names#* }"
}

# @description Register the Microsoft VS Code repository for the current Linux platform.
# @internal
vscode::_register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local architecture=''
    architecture="$(package::_deb-architecture)" || return "$?"
    # The code package adds its own definition of this repository. Current
    # packages honor the debconf answer; older ones, such as the 1.85 series for
    # Ubuntu 18.04, keep an existing vscode.list. That file therefore holds only
    # comments, which also replaces an earlier entry that would duplicate ours.
    printf 'code code/add-microsoft-repo boolean false\n' |
      command::run-as-root debconf-set-selections || return 74
    file::write-text /etc/apt/sources.list.d/vscode.list \
      '# BashStock defines the VS Code repository in vscode.sources.'$'\n''# This file stops the code package from adding a second definition.'$'\n' || return "$?"
    package::_apt-register-repository vscode https://packages.microsoft.com/keys/microsoft.asc \
      https://packages.microsoft.com/repos/code stable main "${architecture}"
  else
    package::_dnf-register-repository vscode "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"
  fi
}

# @description Write VS Code versions available to the current platform.
#
# @noargs
# @stdout VS Code versions, one per line; on Ubuntu only builds that the installed C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   vscode::versions | tail -n 1
vscode::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions visual-studio-code
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      package::_deb-runnable-versions \
        "https://packages.microsoft.com/repos/code/dists/stable/main/binary-${architecture}/Packages.gz" \
        code
      ;;
    fedora)
      package::_rpm-repository-versions https://packages.microsoft.com/yumrepos/vscode code
      ;;
  esac
}

# @description Install VS Code from the Microsoft repository or Homebrew.
#
# On Ubuntu, a version is accepted only when the installed C library can run it,
# and an omitted version selects the newest such build.
#
# @arg $1 string Optional version from vscode::versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 VS Code is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable or cannot run here.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   vscode::install
#   code --version
vscode::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask visual-studio-code "${1:-}"
    return
  fi
  local version="${1:-}" versions=''
  if [[ "${platform}" == 'ubuntu' ]]; then
    # APT would pick the newest build even when the installed C library cannot run it.
    versions="$(vscode::versions)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" 'VS Code')" || return "$?"
  fi
  vscode::_register-repository "${platform}" || return "$?"
  package::_install-version code "${version}"
}

# @description Register GitHub CLI's official Ubuntu APT repository after checking its key.
# @internal
gh::_register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  command::require gpg || return "$?"
  local directory='' status=0 fingerprints='' architecture=''
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "${directory}/githubcli-archive-keyring.gpg" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    mkdir -m 0700 -- "${directory}/gnupg" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    GNUPGHOME="${directory}/gnupg" gpg --batch --with-colons --show-keys \
      "${directory}/githubcli-archive-keyring.gpg" >"${directory}/key-info" 2>/dev/null || status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    fingerprints="$(awk -F: '$1 == "pub" { primary = 1; next } primary && $1 == "fpr" { print $10; primary = 0 }' \
      "${directory}/key-info")" || status=65
  fi
  if [[ "${status}" -eq 0 && "${fingerprints}" != $'2C6106201985B60E6C7AC87323F3D4EA75716059\n7F38BBB59D064DBCB3D84D725612B36462313325' ]]; then
    console::_write-error "The GitHub CLI repository key does not match GitHub's published fingerprints."
    status=65
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /etc/apt/keyrings || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0644 "${directory}/githubcli-archive-keyring.gpg" \
      /etc/apt/keyrings/githubcli-archive-keyring.gpg || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  architecture="$(package::_deb-architecture)" || return "$?"
  file::write-text /etc/apt/sources.list.d/github-cli.sources \
    $'Types: deb\nURIs: https://cli.github.com/packages\nSuites: stable\nComponents: main\nArchitectures: '"${architecture}"$'\nSigned-By: /etc/apt/keyrings/githubcli-archive-keyring.gpg\n' || return "$?"
  package::_refresh
}

# @description Install GitHub CLI from its official Ubuntu APT repository.
#
# The downloaded keyring must contain both fingerprints published by GitHub.
# The keyring is installed in /etc/apt/keyrings and referenced from a deb822
# source file before APT indexes are refreshed and gh is installed.
#
# @noargs
# @exitcode 0 GitHub CLI is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key does not match GitHub's fingerprints.
# @exitcode 69 The system is not Ubuntu, or gpg is missing.
# @exitcode 74 The key download or repository configuration failed.
# @exitcode 77 sudo refused the credentials.
# @exitcode other The status of APT.
# @example
#   gh::install
gh::install() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  gh::_register-repository || return "$?"
  package::_install gh
}

# @description Register Brave's official repository for the current Linux platform.
# @internal
brave::_register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local directory='' status=0
    directory="$(package::_temporary-directory)" || return "$?"
    package::_download \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
      "${directory}/brave-browser-archive-keyring.gpg" || status="$?"
    if [[ "${status}" -eq 0 ]]; then
      command::run-as-root install -d -m 0755 /usr/share/keyrings || status=74
    fi
    if [[ "${status}" -eq 0 ]]; then
      command::run-as-root install -m 0644 "${directory}/brave-browser-archive-keyring.gpg" \
        /usr/share/keyrings/brave-browser-archive-keyring.gpg || status=74
    fi
    rm -rf -- "${directory}"
    [[ "${status}" -eq 0 ]] || return "${status}"
    file::write-text /etc/apt/sources.list.d/brave-browser-release.sources \
      $'Types: deb\nURIs: https://brave-browser-apt-release.s3.brave.com\nSuites: stable\nComponents: main\nArchitectures: amd64 arm64\nSigned-By: /usr/share/keyrings/brave-browser-archive-keyring.gpg\n' || return "$?"
    package::_refresh
  else
    package::_dnf-register-repository brave-browser \
      $'[brave-browser]\nname=Brave Browser\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/$basearch\n'
  fi
}

# @description Write Brave versions available to the current platform.
#
# @noargs
# @stdout Brave versions, one per line; on Ubuntu only builds that the installed C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   brave::versions | tail -n 1
brave::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions brave-browser
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      package::_deb-runnable-versions \
        "https://brave-browser-apt-release.s3.brave.com/dists/stable/main/binary-${architecture}/Packages" \
        brave-browser
      ;;
    fedora)
      architecture="$(package::_rpm-architecture)" || return "$?"
      package::_rpm-repository-versions \
        "https://brave-browser-rpm-release.s3.brave.com/${architecture}" brave-browser
      ;;
  esac
}

# @description Install Brave from its official repository or Homebrew.
#
# On Ubuntu, a version is accepted only when the installed C library can run it,
# and an omitted version selects the newest such build.
#
# @arg $1 string Optional version from brave::versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 Brave is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable or cannot run here.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   brave::install
brave::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask brave-browser "${1:-}"
    return
  fi
  local version="${1:-}" versions=''
  if [[ "${platform}" == 'ubuntu' ]]; then
    versions="$(brave::versions)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" 'Brave')" || return "$?"
  fi
  brave::_register-repository "${platform}" || return "$?"
  package::_install-version brave-browser "${version}"
}

# @description Register the Google Chrome repository for the current Linux platform.
# @internal
chrome::_register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local architecture=''
    architecture="$(package::_deb-architecture)" || return "$?"
    package::_apt-register-repository google-chrome https://dl.google.com/linux/linux_signing_key.pub \
      https://dl.google.com/linux/chrome/deb/ stable main "${architecture}"
  else
    local architecture=''
    architecture="$(package::_rpm-architecture)" || return "$?"
    package::_dnf-register-repository google-chrome "[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/${architecture}
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
"
  fi
}

# @description Write Google Chrome versions available to the current platform.
#
# @noargs
# @stdout Google Chrome versions, one per line; on Ubuntu only builds that the installed C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @exitcode 74 The repository index could not be downloaded.
# @example
#   chrome::versions | tail -n 1
chrome::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions google-chrome
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      package::_deb-runnable-versions \
        "https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-${architecture}/Packages" \
        google-chrome-stable
      ;;
    fedora)
      architecture="$(package::_rpm-architecture)" || return "$?"
      package::_rpm-repository-versions \
        "https://dl.google.com/linux/chrome/rpm/stable/${architecture}" google-chrome-stable
      ;;
  esac
}

# @description Install Google Chrome from the Google repository or Homebrew.
#
# On Ubuntu, a version is accepted only when the installed C library can run it,
# and an omitted version selects the newest such build.
#
# @arg $1 string Optional version from chrome::versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 Google Chrome is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable or cannot run here.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   chrome::install
chrome::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask google-chrome "${1:-}"
    return
  fi
  local version="${1:-}" versions=''
  if [[ "${platform}" == 'ubuntu' ]]; then
    # APT would pick the newest build even when the installed C library cannot run it.
    versions="$(chrome::versions)" || return "$?"
    version="$(package::_select-listed-version "${versions}" "${version}" 'Google Chrome')" || return "$?"
  fi
  chrome::_register-repository "${platform}" || return "$?"
  package::_install-version google-chrome-stable "${version}"
}

# @description Download Anthropic's package signing key and verify its published fingerprint.
# @internal
anthropic::_download-signing-key() {
  [[ "$#" -eq 2 && "$1" == https://* && -n "$2" ]] || return 64
  package::_download-signing-key "$1" 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE "$2"
}

# @description Require an Ubuntu release that Claude Desktop supports.
# @internal
claude-desktop::_require-release() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" != 'ubuntu' ]]; then
    console::_write-error "Claude Desktop does not support ${platform}; it runs on macOS and Ubuntu 22.04 or later."
    return 69
  fi
  package::_require-release ubuntu 22 'Claude Desktop'
}

# @description Require a CPU that Claude Desktop publishes Debian packages for.
# @internal
claude-desktop::_require-architecture() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture=''
  architecture="$(package::_deb-architecture)" || return "$?"
  case "${architecture}" in
    amd64 | arm64) ;;
    *)
      console::_write-error "Claude Desktop does not provide packages for ${architecture}."
      return 69
      ;;
  esac
}

# @description Register Anthropic's APT repository as the Claude Desktop documentation describes.
#
# The signing key must have the published fingerprint. The key and source
# paths match the ones the claude-desktop package uses, so the package keeps
# this source file instead of adding a second entry with another key path.
# @internal
claude-desktop::_register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  local keyring='/usr/share/keyrings/claude-desktop-archive-keyring.asc'
  local directory='' status=0
  directory="$(package::_temporary-directory)" || return "$?"
  anthropic::_download-signing-key https://downloads.claude.ai/claude-desktop/key.asc "${directory}/key.asc" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /usr/share/keyrings || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0644 "${directory}/key.asc" "${keyring}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  file::write-text /etc/apt/sources.list.d/claude-desktop.list \
    "deb [arch=amd64,arm64 signed-by=${keyring}] https://downloads.claude.ai/claude-desktop/apt/stable stable main"$'\n' ||
    return "$?"
  package::_refresh
}

# @description Install the newest Claude Desktop, the app that also runs Claude Code sessions.
#
# macOS installs the Homebrew cask claude, which updates itself. Ubuntu 22.04
# or later installs from Anthropic's APT repository, and later releases
# arrive through the system's regular APT upgrades. Anthropic does not
# publish Claude Desktop for Fedora; use claude-code::install there.
#
# @noargs
# @exitcode 0 Claude Desktop is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key is not Anthropic's published key.
# @exitcode 69 The system is neither macOS nor Ubuntu 22.04 or later, or the CPU is unsupported.
# @exitcode 74 The repository key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   claude-desktop::install
claude-desktop::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask claude
    return
  fi
  claude-desktop::_require-release || return "$?"
  claude-desktop::_require-architecture || return "$?"
  package::_refresh || return "$?"
  package::_install ca-certificates curl gnupg || return "$?"
  claude-desktop::_register-repository || return "$?"
  package::_install claude-desktop
}

# @description Require a Linux release and CPU that Claude Code publishes packages for.
# @internal
claude-code::_require-system() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_require-release ubuntu 20 'Claude Code' || return "$?"
      architecture="$(package::_deb-architecture)" || return "$?"
      [[ "${architecture}" == amd64 || "${architecture}" == arm64 ]] || architecture=''
      ;;
    fedora)
      architecture="$(package::_rpm-architecture)" || return "$?"
      [[ "${architecture}" == x86_64 || "${architecture}" == aarch64 ]] || architecture=''
      ;;
    *) return 64 ;;
  esac
  if [[ -z "${architecture}" ]]; then
    console::_write-error 'Claude Code provides Linux packages only for x86_64 and arm64.'
    return 69
  fi
}

# @description Register Anthropic's Claude Code repository on the stable channel.
#
# The signing key must have the published fingerprint. On Fedora the
# verified key is stored locally, so DNF imports it without downloading
# another copy.
# @internal
claude-code::_register-repository() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' directory='' status=0 keyring=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu) keyring='/etc/apt/keyrings/claude-code.asc' ;;
    fedora) keyring='/etc/pki/rpm-gpg/RPM-GPG-KEY-claude-code' ;;
    *) return 64 ;;
  esac
  directory="$(package::_temporary-directory)" || return "$?"
  anthropic::_download-signing-key https://downloads.claude.ai/keys/claude-code.asc "${directory}/claude-code.asc" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 "${keyring%/*}" || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0644 "${directory}/claude-code.asc" "${keyring}" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  if [[ "${platform}" == 'ubuntu' ]]; then
    file::write-text /etc/apt/sources.list.d/claude-code.list \
      "deb [signed-by=${keyring}] https://downloads.claude.ai/claude-code/apt/stable stable main"$'\n' || return "$?"
    package::_refresh
  else
    package::_dnf-register-repository claude-code "[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/stable
enabled=1
gpgcheck=1
gpgkey=file://${keyring}
"
  fi
}

# @description Install the newest Claude Code CLI.
#
# macOS installs the Homebrew cask claude-code. Ubuntu 20.04 or later and
# Fedora install from Anthropic's signed stable repository, so later
# releases arrive with the system's package upgrades. Signing in is left to
# the first run of claude.
#
# @noargs
# @exitcode 0 Claude Code is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded signing key is not Anthropic's published key.
# @exitcode 69 The platform is unsupported, Ubuntu is older than 20.04, or the CPU is unsupported.
# @exitcode 74 The repository key could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   claude-code::install && claude --version
claude-code::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_install-cask claude-code
      return
      ;;
    ubuntu)
      claude-code::_require-system || return "$?"
      package::_refresh || return "$?"
      package::_install ca-certificates curl gnupg || return "$?"
      ;;
    fedora)
      claude-code::_require-system || return "$?"
      package::_install ca-certificates curl gnupg2 || return "$?"
      ;;
  esac
  claude-code::_register-repository || return "$?"
  package::_install claude-code
}

# @description Install the newest OpenAI Codex CLI.
#
# macOS installs the Homebrew cask codex. Linux runs OpenAI's standalone
# installer, which verifies the release checksum, installs the static musl
# build into $HOME/.local, and keeps it updated. $HOME/.local/bin is added
# to PATH through env::add-path, so the installer leaves the shell startup
# files alone. Signing in is left to the first run of codex.
#
# @noargs
# @stdout The installer's progress and the installed version.
# @exitcode 0 Codex is installed.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform or CPU is unsupported, or tar is missing.
# @exitcode 74 The installer could not be downloaded or $HOME/.local/bin could not be created.
# @exitcode other The status of the installer or of Homebrew.
# @example
#   codex::install && codex --version
codex::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' directory='' status=0
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask codex
    return
  fi
  case "$(uname -m)" in
    x86_64 | amd64 | aarch64 | arm64) ;;
    *)
      console::_write-error 'Codex provides Linux builds only for x86_64 and arm64.'
      return 69
      ;;
  esac
  # The installer unpacks the release with tar.
  command::require tar || return "$?"
  mkdir -p -- "${HOME}/.local/bin" || return 74
  env::add-path "${HOME}/.local/bin" || return "$?"
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://chatgpt.com/codex/install.sh "${directory}/install.sh" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    CODEX_NON_INTERACTIVE=1 sh "${directory}/install.sh" </dev/null || status="$?"
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  "${HOME}/.local/bin/codex" --version
}

# @description Write the package architecture for the ChatGPT desktop app on Linux after checking the release.
# @internal
chatgpt::_architecture() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu)
      package::_require-release ubuntu 24 'The ChatGPT desktop app' || return "$?"
      architecture="$(package::_deb-architecture)" || return "$?"
      [[ "${architecture}" == amd64 || "${architecture}" == arm64 ]] || architecture=''
      ;;
    fedora)
      package::_require-release fedora 43 'The ChatGPT desktop app' || return "$?"
      architecture="$(package::_rpm-architecture)" || return "$?"
      [[ "${architecture}" == x86_64 || "${architecture}" == aarch64 ]] || architecture=''
      ;;
    *) return 64 ;;
  esac
  if [[ -z "${architecture}" ]]; then
    console::_write-error 'The ChatGPT desktop app provides Linux packages only for x86_64 and arm64.'
    return 69
  fi
  printf '%s\n' "${architecture}"
}

# @description Install the newest ChatGPT desktop app, which also runs Codex.
#
# macOS installs the Homebrew cask chatgpt. Ubuntu 24.04 or later and
# Fedora 43 or later install OpenAI's newest package, which registers
# OpenAI's signed repository so later releases arrive with the system's
# package upgrades.
#
# @noargs
# @exitcode 0 The ChatGPT desktop app is installed.
# @exitcode 64 An argument was given.
# @exitcode 65 The downloaded package is for another CPU or is not a valid package.
# @exitcode 69 The platform, release, or CPU is unsupported.
# @exitcode 74 The package could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   chatgpt::install
chatgpt::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture='' directory='' file='' status=0
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask chatgpt
    return
  fi
  architecture="$(chatgpt::_architecture)" || return "$?"
  if [[ "${platform}" == 'ubuntu' ]]; then
    deb::install-from-url \
      "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_${architecture}.deb" "${architecture}"
    return
  fi
  command::require dnf || return "$?"
  directory="$(package::_temporary-directory)" || return "$?"
  file="${directory}/chatgpt.${architecture}.rpm"
  package::_download "https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.${architecture}.rpm" \
    "${file}" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root dnf install -y "${file}" || status="$?"
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

# @description Write GIMP versions available to the current platform.
#
# @noargs
# @stdout GIMP versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported.
# @example
#   gimp::versions
gimp::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_cask-versions gimp
  else
    package::_versions gimp
  fi
}

# @description Install GIMP, and on Linux the G'MIC plugin from the selected source.
#
# @arg $1 string Optional GIMP version from gimp::versions; on macOS only the current version.
# @arg $2 string Optional G'MIC source on Linux: os (default) or official; see gimp::gmic::install.
# @exitcode 0 GIMP, and on Linux the G'MIC plugin, are installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, the version is unavailable, or the G'MIC source cannot provide the plugin.
# @exitcode other The status of the package manager.
# @example
#   gimp::install '' official
gimp::install() {
  [[ "$#" -le 2 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask gimp "${1:-}"
    return
  fi
  package::_install-version gimp "${1:-}" || return "$?"
  gimp::gmic::install '' "${2:-os}"
}

# @description Write the G'MIC GIMP plugin package name for the current platform.
# @internal
gimp::gmic::_package-name() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    ubuntu) printf 'gimp-gmic\n' ;;
    fedora) printf 'gmic-gimp\n' ;;
    *)
      console::_write-error "The G'MIC GIMP plugin package is unavailable on ${platform}."
      return 69
      ;;
  esac
}

# @description Write version and URL pairs of the official G'MIC packages for this Ubuntu release and CPU.
# @internal
gimp::gmic::_official-entries() {
  [[ "$#" -eq 0 ]] || return 64
  local release='' codename='' architecture='' listing=''
  package::_require-platform ubuntu || return "$?"
  release="$(platform::_os-release-value VERSION_ID)" || return 69
  codename="$(platform::_os-release-value UBUNTU_CODENAME 2>/dev/null ||
    platform::_os-release-value VERSION_CODENAME)" || return 69
  architecture="$(package::_deb-architecture)" || return "$?"
  listing="$(package::_fetch https://gmic.eu/files/linux/)" || return "$?"
  # A release or CPU without a package leaves the list empty.
  { printf '%s\n' "${listing}" |
    grep -oE "gmic_[0-9.]+_ubuntu${release//./-}_${codename}_${architecture}\.deb" || true; } |
    sort -u |
    sed -E 's|^gmic_([0-9.]+)_.*$|\1\thttps://gmic.eu/files/linux/&|'
}

# @description Write G'MIC GIMP plugin versions available from the selected source.
#
# @arg $1 string Optional source: os (default) or official.
# @stdout G'MIC plugin versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The platform or CPU is unsupported by the source.
# @exitcode 74 The official package list could not be downloaded.
# @example
#   gimp::gmic::versions official
gimp::gmic::versions() {
  [[ "$#" -le 1 ]] || return 64
  local source="${1:-os}" package='' official_entries=''
  case "${source}" in
    os)
      package="$(gimp::gmic::_package-name)" || return "$?"
      package::_versions "${package}"
      ;;
    official)
      official_entries="$(gimp::gmic::_official-entries)" || return "$?"
      printf '%s\n' "${official_entries}" | cut -f 1 | package::_sort-versions
      ;;
    *) return 64 ;;
  esac
}

# @description Install the G'MIC GIMP plugin.
#
# The os source installs the plugin package of the system package manager.
# Ubuntu 26.04 ships GIMP 3 without one, so the official source installs the
# G'MIC project's package for the running Ubuntu release, which contains the
# GIMP 3 plugin. A source that cannot provide the plugin returns 69 instead
# of switching to the other source.
#
# @arg $1 string Optional version from gimp::gmic::versions for the same source.
# @arg $2 string Optional source: os (default) or official. The official source supports Ubuntu on amd64, the only CPU the G'MIC project builds packages for.
# @stderr A message when the source cannot provide the plugin.
# @exitcode 0 The G'MIC plugin is installed.
# @exitcode 64 The source is not os or official.
# @exitcode 69 The source cannot provide the plugin for this system, or the version is unavailable.
# @exitcode 74 The official package could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   gimp::gmic::install '' official
gimp::gmic::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" source="${2:-os}" package='' versions='' official_entries='' url=''
  case "${source}" in
    os)
      package="$(gimp::gmic::_package-name)" || return "$?"
      versions="$(package::_versions "${package}")" || return "$?"
      if [[ -z "${versions}" ]]; then
        console::_write-error "The system packages do not provide the G'MIC GIMP plugin; use the official source."
        return 69
      fi
      package::_install-version "${package}" "${version}"
      ;;
    official)
      official_entries="$(gimp::gmic::_official-entries)" || return "$?"
      if [[ -z "${official_entries}" ]]; then
        console::_write-error "The G'MIC project publishes no package for this Ubuntu release and CPU."
        return 69
      fi
      versions="$(printf '%s\n' "${official_entries}" | cut -f 1)"
      version="$(package::_select-listed-version "${versions}" "${version}" "G'MIC")" || return "$?"
      url="$(printf '%s\n' "${official_entries}" | awk -F '\t' -v version="${version}" '$1 == version {print $2; exit}')"
      deb::install-from-url "${url}"
      ;;
    *) return 64 ;;
  esac
}

# @description Write the Microsoft Edge Debian package index URL for the current architecture.
# @internal
microsoft-edge::_index-url() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture=''
  architecture="$(package::_deb-architecture)" || return "$?"
  printf 'https://packages.microsoft.com/repos/edge/dists/stable/main/binary-%s/Packages.gz\n' "${architecture}"
}

# @description Write the Microsoft Edge package URL for a version from the vendor package metadata.
# @internal
# @arg $1 string VERSION Package version. Defaults to the newest stable version.
microsoft-edge::_artifact-url() {
  [[ "$#" -le 1 ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local version="${1:-}" index='' index_entries='' entry=''
  index="$(microsoft-edge::_index-url)" || return "$?"
  index_entries="$(package::_deb-index-entries "${index}" microsoft-edge-stable)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(printf '%s\n' "${index_entries}" | cut -f 1 | package::_latest-stable-version)" || return "$?"
  fi
  while IFS=$'\t' read -r entry index; do
    if [[ "${entry}" == "${version}" ]]; then
      printf 'https://packages.microsoft.com/repos/edge/%s\n' "${index}"
      return 0
    fi
  done <<<"${index_entries}"
  return 1
}

# @description Write Microsoft Edge versions available to the current platform.
#
# @noargs
# @stdout Microsoft Edge versions, one per line; on Linux only builds for this CPU, and on Ubuntu only builds the C library can run.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform or CPU is unsupported.
# @exitcode 74 The vendor metadata could not be downloaded.
# @example
#   microsoft-edge::versions | tail -n 1
microsoft-edge::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' index=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions microsoft-edge
      ;;
    ubuntu)
      index="$(microsoft-edge::_index-url)" || return "$?"
      package::_deb-runnable-versions "${index}" microsoft-edge-stable
      ;;
    fedora)
      package::_rpm-repository-versions https://packages.microsoft.com/yumrepos/edge microsoft-edge-stable
      ;;
  esac
}

# @description Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew.
#
# On Linux, a version is accepted only when Microsoft publishes it for the
# running CPU, and on Ubuntu only when the installed C library can run it.
# Microsoft builds Edge for Linux on amd64 only, so arm64 returns 69.
#
# @arg $1 string Optional version from microsoft-edge::versions; on macOS only the current version. Defaults to the newest runnable one.
# @exitcode 0 Microsoft Edge is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or CPU is unsupported, or the version is unavailable.
# @exitcode 74 The package or repository could not be downloaded.
# @exitcode other The status of the package manager.
# @example
#   microsoft-edge::install
microsoft-edge::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform='' url='' versions='' version="${1:-}"
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask microsoft-edge "${version}"
    return
  fi
  versions="$(microsoft-edge::versions)" || return "$?"
  version="$(package::_select-listed-version "${versions}" "${version}" 'Microsoft Edge')" || return "$?"
  case "${platform}" in
    ubuntu)
      url="$(microsoft-edge::_artifact-url "${version}")" || return "$?"
      deb::install-from-url "${url}"
      ;;
    fedora)
      package::_dnf-register-repository microsoft-edge "[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
" || return "$?"
      package::_install-version microsoft-edge-stable "${version}"
      ;;
  esac
}

# @description Write the newest Command Line Tools label offered by softwareupdate.
# @internal
xcode::command-line-tools::_latest-label() {
  [[ "$#" -eq 0 ]] || return 64
  command::require softwareupdate || return "$?"
  local labels=''
  labels="$(softwareupdate --list 2>&1 |
    sed -n 's/^[[:space:]]*\*[[:space:]]*Label:[[:space:]]*\(Command Line Tools.*\)$/\1/p')" || return 74
  [[ -n "${labels}" ]] || return 1
  printf '%s\n' "${labels}" | awk '{print $NF "\t" $0}' | package::_sort-by-first-field | tail -n 1
}

# @description Update Xcode Command Line Tools without removing the installed tools.
#
# When softwareupdate offers no Command Line Tools update, nothing changes.
#
# @noargs
# @stdout The package information of the updated tools.
# @stderr A message when no update is available.
# @exitcode 0 The tools were updated, or no update is available.
# @exitcode 64 An argument was given.
# @exitcode 69 The system is not macOS, or softwareupdate or xcode-select is unavailable.
# @exitcode 74 softwareupdate could not list updates, or xcode-select finds no tools after the update.
# @exitcode other The status of softwareupdate or pkgutil.
# @example
#   xcode::command-line-tools::upgrade
#   clang --version
xcode::command-line-tools::upgrade() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require xcode-select || return "$?"
  local label='' status=0
  label="$(xcode::command-line-tools::_latest-label)" || status="$?"
  if [[ "${status}" -eq 1 ]]; then
    console::_write-error 'No Command Line Tools update is available.'
    return 0
  fi
  [[ "${status}" -eq 0 ]] || return "${status}"
  command::run-as-root softwareupdate --install "${label}" || return "$?"
  xcode-select -p >/dev/null || return 74
  pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
}

# @description Install QMK Toolbox with Homebrew on macOS.
#
# @arg $1 string Optional QMK Toolbox version; only the current Homebrew version is accepted.
# @exitcode 0 QMK Toolbox is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The system is not macOS, or the version is not the current one.
# @exitcode other The status of brew.
# @example
#   qmk::toolbox::install
qmk::toolbox::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-cask qmk-toolbox "${1:-}"
}

# @description Install the QMK CLI with the official installer and diagnose the environment.
#
# `qmk --version` always confirms the installation. The CLI offers
# `qmk doctor` only after `qmk setup` has prepared the firmware tree, so the
# diagnosis also runs when that tree exists. Warnings from the diagnosis are
# reported without failing; errors return its status.
#
# @arg $1 string Optional QMK CLI version; only the newest stable version from PyPI is accepted.
# @stdout The output of qmk --version, and of qmk doctor when the firmware tree exists.
# @exitcode 0 The QMK CLI is installed and starts; doctor found at most warnings.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The version is not the newest one, or sh is unavailable.
# @exitcode 74 The installer could not be downloaded.
# @exitcode other The status of the installer, qmk --version, or qmk doctor.
# @example
#   qmk::cli::install
#   qmk setup -y
qmk::cli::install() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' status=0
  if [[ -n "${1:-}" ]]; then
    local latest=''
    latest="$(qmk::cli::_latest-version)" || return "$?"
    if [[ "$1" != "${latest}" ]]; then
      console::_write-error "The QMK installer provides only version ${latest}."
      return 69
    fi
  fi
  command::require sh || return "$?"
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download https://install.qmk.fm "${directory}/install.sh" || status="$?"
  [[ "${status}" -ne 0 ]] || sh "${directory}/install.sh" || status="$?"
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  # The installer puts qmk in $HOME/.local/bin and asks for a new shell otherwise.
  env::add-path "${HOME}/.local/bin" || return "$?"
  command::require qmk || return "$?"
  qmk --version || return "$?"
  # qmk doctor exists only once `qmk setup` has prepared the firmware tree.
  if qmk doctor --help >/dev/null 2>&1; then
    # doctor exits 1 when it found only warnings, such as missing udev rules.
    qmk doctor || [[ "$?" -eq 1 ]]
  fi
}

# @description Write the newest QMK CLI version published on PyPI.
# @internal
qmk::cli::_latest-version() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local json=''
  json="$(package::_fetch https://pypi.org/pypi/qmk/json)" || return "$?"
  printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    print "$data->{info}{version}\n";
  '
}

# @description Write Supabase CLI versions available to the current platform.
#
# @noargs
# @stdout Supabase CLI versions, one per line.
# @exitcode 0 The versions were written.
# @exitcode 64 An argument was given.
# @exitcode 69 The platform is unsupported, or Perl is missing.
# @exitcode 74 The release list could not be downloaded.
# @example
#   supabase::versions | tail -n 1
supabase::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_versions supabase/tap/supabase
  else
    package::_github-release-versions supabase/cli
  fi
}

# @description Install the Supabase CLI from its Homebrew tap or release packages.
#
# @arg $1 string Optional version from supabase::versions; on macOS only the current tap version. Defaults to the newest one.
# @exitcode 0 The Supabase CLI is installed.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or CPU is unsupported, or the version is unavailable.
# @exitcode 74 The release package could not be downloaded.
# @exitcode other The status of brew or the package manager.
# @example
#   supabase::install
#   supabase --version
supabase::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' architecture='' url=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    if [[ -n "${version}" ]]; then
      local current=''
      current="$(package::_brew-formula-stable-version supabase/tap/supabase)" || return "$?"
      if [[ "${version}" != "${current}" ]]; then
        console::_write-error "The Supabase tap provides only version ${current}."
        return 69
      fi
    fi
    brew install supabase/tap/supabase
    return
  fi
  if [[ -z "${version}" ]]; then
    version="$(supabase::versions | package::_latest-stable-version)" || return "$?"
  fi
  if [[ "${platform}" == 'ubuntu' ]]; then
    architecture="$(package::_deb-architecture)" || return "$?"
    url="$(package::_github-release-asset-url supabase/cli "${version}" "_linux_${architecture}\\.deb\$")" || return "$?"
    deb::install-from-url "${url}"
  else
    architecture="$(package::_rpm-architecture)" || return "$?"
    case "${architecture}" in
      x86_64) architecture='amd64' ;;
      aarch64) architecture='arm64' ;;
    esac
    url="$(package::_github-release-asset-url supabase/cli "${version}" "_linux_${architecture}\\.rpm\$")" || return "$?"
    command::run-as-root dnf install -y "${url}"
  fi
}
