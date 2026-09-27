#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### Download a Debian package and install it with its dependencies through APT.
###
### Arguments
###
### * URL - HTTPS URL of the Debian package.
### * EXPECTED_ARCHITECTURE - Accepted package architecture. Defaults to the
###   system architecture; packages for all architectures are also accepted.
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

### Write APT packages whose names start with PREFIX followed by a digit, with candidate versions.
###
### Each line contains a package name and its candidate version separated by a tab.
apt::package::candidates() {
  [[ "$#" -eq 1 && "$1" =~ ^[a-z0-9][a-z0-9.+-]*$ ]] || return 64
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

### Sort tab-separated lines by the version in their first field and drop that field.
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

### Write the APT package name with the newest version suffix after PREFIX.
apt::package::latest() {
  [[ "$#" -eq 1 ]] || return 64
  local candidates='' line=''
  candidates="$(apt::package::candidates "$1")" || return "$?"
  [[ -n "${candidates}" ]] || return 1
  line="${candidates##*$'\n'}"
  printf '%s\n' "${line%%$'\t'*}"
}

### Export Chrome Preferences and Bookmarks for profiles whose email matches literally.
###
### Arguments
###
### * EMAIL - Email address to compare literally.
### * OUTPUT_DIRECTORY - Destination directory. Defaults to the current directory.
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

### Write the default AWS VPN Client log directory.
aws-vpn-client::log::_default-directory() {
  [[ "$#" -eq 0 ]] || return 64
  printf '%s\n' "${HOME}/.config/AWSVPNClient/logs"
}

### Write AWS VPN Client log files as NUL-separated paths.
###
### Files whose names contain aws_vpn_client_ and do not contain
### ovpn_aws_vpn_client are selected, as in the reference script.
aws-vpn-client::log::files() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-}"
  [[ -n "${directory}" ]] || directory="$(aws-vpn-client::log::_default-directory)"
  [[ -d "${directory}" && ! -L "${directory}" ]] || return 66
  command::require find || return "$?"
  find "${directory}" -type f -name '*aws_vpn_client_*' ! -name '*ovpn_aws_vpn_client*' -print0
}

### Remove regular log files below the AWS VPN Client log directory.
aws-vpn-client::log::clear() {
  [[ "$#" -le 1 ]] || return 64
  local directory="${1:-}"
  [[ -n "${directory}" ]] || directory="$(aws-vpn-client::log::_default-directory)"
  [[ -d "${directory}" && ! -L "${directory}" ]] || return 66
  command::require find || return "$?"
  find "${directory}" -type f -exec rm -f -- {} + || return 74
}

### Open log files with an editor command, passing each path as one argument.
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

### Write Node.js LTS major versions from the official release index in ascending order.
node::versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local json='' versions=''
  json="$(package::_fetch https://nodejs.org/dist/index.json)" || return "$?"
  versions="$(printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    for my $release (@$data) {
      next unless $release->{lts};
      print "$1\n" if $release->{version} =~ /^v([0-9]+)\./;
    }
  ')" || return "$?"
  printf '%s\n' "${versions}" | package::_sort-versions
}

### Install Node.js, enable Corepack, and set the pnpm store directory.
###
### Arguments
###
### * VERSION - Node.js major version. On macOS it defaults to the newest LTS
###   major version. On Fedora it selects the nodejsVERSION stream when one
###   exists. Otherwise Linux installs the distribution nodejs package, and a
###   given VERSION must match its major version.
node::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' stable='' formula='node' package='nodejs' available=''
  [[ -z "${version}" || "${version}" =~ ^[0-9]+$ ]] || return 64
  platform="$(package::_platform)" || return "$?"
  if [[ -z "${version}" && "${platform}" != 'ubuntu' ]]; then
    version="$(node::versions | package::_latest-stable-version)" || return "$?"
  fi
  case "${platform}" in
    darwin)
      stable="$(package::_brew-formula-stable-version node)" || return "$?"
      [[ "${stable%%.*}" == "${version}" ]] || formula="node@${version}"
      package::_install "${formula}" || return "$?"
      if [[ "${formula}" != 'node' ]]; then
        brew link --overwrite --force "${formula}" || return "$?"
      fi
      ;;
    ubuntu | fedora)
      if [[ "${platform}" == 'fedora' && -n "$(package::_versions "nodejs${version}" 2>/dev/null)" ]]; then
        package="nodejs${version}"
      elif [[ -n "${1:-}" ]]; then
        available="$(package::_latest-version nodejs)" || return "$?"
        available="${available#*:}"
        if [[ "${available%%.*}" != "${version}" ]]; then
          console::_write-error "The distribution provides Node.js ${available%%.*}, not ${version}."
          return 69
        fi
      fi
      package::_install "${package}" || return "$?"
      ;;
  esac
  node::_enable-corepack "${platform}" || return "$?"
  COREPACK_ENABLE_DOWNLOAD_PROMPT=0 pnpm config set store-dir "${HOME}/.pnpm-store"
}

### Enable Corepack, installing it through npm when the Node.js release omits it.
node::_enable-corepack() {
  [[ "$#" -eq 1 ]] || return 64
  local runner=()
  [[ "$1" == 'darwin' ]] || runner=(command::run-as-root)
  if ! command -v corepack >/dev/null 2>&1; then
    command::require npm || return "$?"
    ${runner[@]+"${runner[@]}"} npm install --global corepack || return "$?"
  fi
  ${runner[@]+"${runner[@]}"} corepack enable
}

### Write Docker Engine or Docker CLI versions available to the current platform.
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

### Write the Ubuntu codename used by the Docker repository.
docker::_ubuntu-codename() {
  [[ "$#" -eq 0 ]] || return 64
  platform::_os-release-value UBUNTU_CODENAME 2>/dev/null ||
    platform::_os-release-value VERSION_CODENAME
}

### Install the Docker CLI, and Docker Engine on Linux.
###
### On macOS, Colima or Rancher Desktop must already be installed and running.
### On Ubuntu and Fedora, the official Docker repository is registered and the
### docker service is enabled and started.
###
### Arguments
###
### * VERSION - Docker version from docker::versions. Defaults to the newest stable version.
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

### Test whether Colima or Rancher Desktop is running on macOS.
docker::_container-runtime-is-running() {
  [[ "$#" -eq 0 ]] || return 64
  if command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then
    return 0
  fi
  command -v pgrep >/dev/null 2>&1 && pgrep -f 'Rancher Desktop' >/dev/null 2>&1
}

### Install the Docker CLI plugins with Homebrew on macOS.
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

### Install Docker Engine from the official repository on Ubuntu.
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
  for package in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    command::run-as-root env DEBIAN_FRONTEND=noninteractive apt-get remove -y "${package}" >/dev/null 2>&1 || true
  done
  package::_refresh || return "$?"
  package::_install ca-certificates curl || return "$?"
  package::_apt-register-repository docker https://download.docker.com/linux/ubuntu/gpg \
    https://download.docker.com/linux/ubuntu "${codename}" stable "${architecture}" || return "$?"
  package::_install "docker-ce${version:+=${version}}" "docker-ce-cli${version:+=${version}}" \
    containerd.io docker-buildx-plugin docker-compose-plugin || return "$?"
  package::_enable-service docker || return "$?"
  package::_add-current-user-to-group docker
}

### Install Docker Engine from the official repository on Fedora.
docker::_install-fedora() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" cli_version="${1#*:}" repository=''
  command::run-as-root dnf remove -y docker docker-client docker-client-latest docker-common docker-latest \
    docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine >/dev/null 2>&1 || true
  repository="$(package::_fetch https://download.docker.com/linux/fedora/docker-ce.repo)" || return "$?"
  package::_dnf-register-repository docker-ce "${repository}"$'\n' || return "$?"
  package::_install "docker-ce${version:+=${version}}" "docker-ce-cli${cli_version:+=${cli_version}}" \
    containerd.io docker-buildx-plugin docker-compose-plugin || return "$?"
  if [[ -z "${version}" ]]; then
    command::run-as-root dnf upgrade -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin || return "$?"
  fi
  package::_enable-service docker || return "$?"
  package::_add-current-user-to-group docker
}

### Write Colima versions available from Homebrew.
colima::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_versions colima
}

### Install Colima with Homebrew on macOS and start it.
colima::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_install-version colima "${1:-}" || return "$?"
  if colima status >/dev/null 2>&1; then
    return 0
  fi
  colima start
}

### Write the rbenv root directory.
ruby::_rbenv-root() {
  [[ "$#" -eq 0 ]] || return 64
  printf '%s\n' "${RBENV_ROOT:-${HOME}/.rbenv}"
}

### Install rbenv and ruby-build.
ruby::_install-rbenv() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' root=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install rbenv ruby-build || return "$?"
    brew upgrade rbenv ruby-build || return "$?"
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

### Write the rbenv command path.
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

### Configure Bash and Zsh startup files to initialize rbenv and apply it to this shell.
ruby::_configure-shell() {
  [[ "$#" -eq 0 ]] || return 64
  local shell='' startup='' root=''
  root="$(ruby::_rbenv-root)"
  for shell in bash zsh; do
    startup="${HOME}/.${shell}rc"
    [[ -e "${startup}" ]] || : >"${startup}" || return 74
    if [[ -d "${root}/bin" ]]; then
      file::replace-text-or-append "${startup}" '^export PATH=.*\.rbenv/bin' \
        "export PATH=\"${root}/bin:\${PATH}\"" || return "$?"
    fi
    file::replace-text-or-append "${startup}" 'rbenv init' "eval \"\$(rbenv init - ${shell})\"" || return "$?"
  done
  [[ ! -d "${root}/bin" || ":${PATH}:" == *":${root}/bin:"* ]] || PATH="${root}/bin:${PATH}"
  [[ ":${PATH}:" == *":${root}/shims:"* ]] || PATH="${root}/shims:${PATH}"
  export PATH
}

### Install rbenv, configure the shell, and install a Ruby version globally.
###
### Arguments
###
### * VERSION - Ruby version. Defaults to ruby::version::latest.
ruby::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" rbenv=''
  [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 64
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

### Write JDK feature release numbers available to the current platform.
jdk::version::list() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' versions='' name=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      versions="$(package::_brew-formula-versions openjdk)" || return "$?"
      while IFS= read -r name; do
        [[ -n "${name}" ]] && printf '%s\n' "${name%%.*}"
      done <<<"${versions}" | package::_sort-versions
      ;;
    ubuntu)
      command::require apt-cache || return "$?"
      versions="$(apt-cache pkgnames openjdk- 2>/dev/null)" || return 74
      while IFS= read -r name; do
        [[ "${name}" =~ ^openjdk-([0-9]+)-jdk$ ]] && printf '%s\n' "${BASH_REMATCH[1]}"
      done <<<"${versions}" | package::_sort-versions
      ;;
    fedora)
      command::require dnf || return "$?"
      versions="$(dnf repoquery --quiet --queryformat $'%{name} %{version}\n' \
        'java-*-openjdk-devel' 2>/dev/null)" || return 74
      while IFS=' ' read -r name _; do
        [[ "${name}" =~ ^java-([0-9]+)-openjdk-devel$ ]] && printf '%s\n' "${BASH_REMATCH[1]}"
      done <<<"${versions}" | package::_sort-versions
      ;;
  esac
}

### Write the newest JDK feature release number available to the current platform.
jdk::version::latest() {
  [[ "$#" -eq 0 ]] || return 64
  jdk::version::list | package::_latest-stable-version
}

### Install a JDK, select it as the default Java, and persist JAVA_HOME and PATH.
###
### Arguments
###
### * VERSION - JDK feature release number. Defaults to jdk::version::latest.
jdk::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform='' home=''
  [[ -z "${version}" || "${version}" =~ ^[0-9]+$ ]] || return 64
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

### Install an OpenJDK formula on macOS and write its Java home.
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

### Select the Java and Java compiler alternatives below a Java home.
jdk::_select-alternatives() {
  [[ "$#" -eq 2 && -d "$2" ]] || return 64
  local tool=''
  command::require "$1" || return "$?"
  for tool in java javac; do
    [[ -x "$2/bin/${tool}" ]] || return 74
    command::run-as-root "$1" --set "${tool}" "$2/bin/${tool}" >&2 || return "$?"
  done
}

### Install an OpenJDK package on Ubuntu and write its Java home.
jdk::_install-ubuntu() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" architecture='' home=''
  package::_install "openjdk-${version}-jdk" >&2 || return "$?"
  architecture="$(package::_deb-architecture)" || return "$?"
  home="/usr/lib/jvm/java-${version}-openjdk-${architecture}"
  jdk::_select-alternatives update-alternatives "${home}" || return "$?"
  printf '%s\n' "${home}"
}

### Install an OpenJDK package on Fedora and write its Java home.
jdk::_install-fedora() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" home=''
  package::_install "java-${version}-openjdk-devel" >&2 || return "$?"
  command::require readlink || return "$?"
  home="$(readlink -f "/usr/lib/jvm/java-${version}-openjdk")" || return 74
  jdk::_select-alternatives alternatives "${home}" || return "$?"
  printf '%s\n' "${home}"
}

### Write pipx versions available to the current platform.
pipx::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions pipx
}

### Install pipx and add the pipx application directory to PATH.
pipx::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version pipx "${1:-}" || return "$?"
  mkdir -p -- "${HOME}/.local/bin" || return 74
  env::add-path "${HOME}/.local/bin"
}

### Set VS Code as the default application for text and source file types on macOS.
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
    duti -s "${bundle}" ".${type}" all || return "$?"
  done
  for type in "${types[@]}"; do
    duti -s "${bundle}" "${type}" all || return "$?"
  done
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -kill -r -domain local -domain system -domain user >/dev/null 2>&1
  killall Finder >/dev/null 2>&1 || true
}

### Set IINA as the default application for video file extensions on macOS.
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

### Write UTM release versions.
utm::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_github-release-versions utmapp/UTM
}

### Install UTM from its release disk image on macOS.
###
### Arguments
###
### * VERSION - UTM release version. Defaults to the newest stable release.
### * APPLICATION_DIRECTORY - Destination directory. Defaults to /Applications.
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

### Replace an application bundle in a destination directory.
utm::_copy-application() {
  [[ "$#" -eq 2 && -d "$1" && -d "$2" ]] || return 64
  local runner=()
  [[ -w "$2" ]] || runner=(command::run-as-root)
  ${runner[@]+"${runner[@]}"} rm -rf -- "$2/$(path::base-name "$1")" || return 74
  ${runner[@]+"${runner[@]}"} cp -R -- "$1" "$2/" || return 74
}

### Write supported Ubuntu LTS versions from the Ubuntu release metadata.
###
### Releases newer than the last upgrade-supported release are included because
### the metadata enables upgrades only after the first point release is tested.
ubuntu::server-iso-versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local metadata='' versions=''
  metadata="$(package::_fetch https://changelogs.ubuntu.com/meta-release-lts)" || return "$?"
  versions="$(printf '%s\n' "${metadata}" | perl -e '
    local $/ = "";
    my @releases;
    while (my $stanza = <STDIN>) {
      my ($version) = $stanza =~ /^Version:\s*([0-9.]+)/m or next;
      my ($supported) = $stanza =~ /^Supported:\s*([01])/m;
      push @releases, [$version, $supported // 0];
    }
    my $last_supported = -1;
    $releases[$_][1] and $last_supported = $_ for 0 .. $#releases;
    for my $index (0 .. $#releases) {
      print "$releases[$index][0]\n" if $releases[$index][1] || $index > $last_supported;
    }
  ')" || return 74
  printf '%s\n' "${versions}" | package::_sort-versions
}

### Download the Ubuntu Server live ISO image.
###
### Arguments
###
### * VERSION - Ubuntu LTS version. Defaults to the newest supported LTS version.
### * ARCHITECTURE - amd64 or arm64. Defaults to the current machine.
### * OUTPUT_PATH - Destination file. Defaults to the official file name in the current directory.
ubuntu::download-server-iso() {
  [[ "$#" -le 3 ]] || return 64
  local version="${1:-}" architecture="${2:-}" output="${3:-}" series='' name='' url=''
  if [[ -z "${version}" ]]; then
    version="$(ubuntu::server-iso-versions | package::_latest-stable-version)" || return "$?"
  fi
  [[ "${version}" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || return 64
  if [[ -z "${architecture}" ]]; then
    case "$(uname -m)" in
      x86_64 | amd64) architecture='amd64' ;;
      arm64 | aarch64) architecture='arm64' ;;
      *) return 69 ;;
    esac
  fi
  series="$(printf '%s' "${version}" | cut -d . -f 1-2)"
  name="ubuntu-${version}-live-server-${architecture}.iso"
  case "${architecture}" in
    amd64) url="https://releases.ubuntu.com/${series}/${name}" ;;
    arm64) url="https://cdimage.ubuntu.com/releases/${series}/release/${name}" ;;
    *) return 64 ;;
  esac
  [[ -n "${output}" ]] || output="./${name}"
  package::_download "${url}" "${output}" || return "$?"
  printf '%s\n' "${output}"
}

### Write Rancher Desktop versions available to the current platform.
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

### Install Rancher Desktop and start it.
###
### Rosetta and Colima are installed separately with rosetta::install and colima::install.
rancher-desktop::install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_install-cask rancher "${version}" || return "$?"
      open -a 'Rancher Desktop'
      ;;
    ubuntu | fedora)
      rancher-desktop::_install-linux "${platform}" "${version}" || return "$?"
      rancher-desktop::_start-linux
      ;;
  esac
}

### Register the Rancher Desktop repository and install the package on Linux.
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

### Start Rancher Desktop in the background on Linux.
rancher-desktop::_start-linux() {
  [[ "$#" -eq 0 ]] || return 64
  command::require rancher-desktop || return "$?"
  (rancher-desktop >/dev/null 2>&1 &)
}

### Disable the Option+T key binding on macOS.
key-binding::disable-option-t() {
  [[ "$#" -eq 0 ]] || return 64
  package::_require-platform darwin || return "$?"
  plist::set "${HOME}/Library/KeyBindings/DefaultKeyBinding.dict" '~t' 'noop:'
}

### Write pass versions available to the current platform.
pass::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions pass
}

### Install pass from the platform package manager.
pass::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version pass "${1:-}"
}

### Write PlantUML versions available to the current platform.
plantuml::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions plantuml
}

### Install PlantUML from the platform package manager.
plantuml::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version plantuml "${1:-}"
}

### Write Graphviz versions available to the current platform.
graphviz::versions() {
  [[ "$#" -eq 0 ]] || return 64
  package::_versions graphviz
}

### Install Graphviz from the platform package manager.
graphviz::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-version graphviz "${1:-}"
}

### Write stable Flutter SDK versions for the current platform.
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

### Install packages required to build Flutter applications.
flutter::dependencies::install() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      command::require git || return "$?"
      command::require curl
      ;;
    ubuntu)
      package::_refresh || return "$?"
      package::_install curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build \
        pkg-config libgtk-3-dev libstdc++-12-dev
      ;;
    fedora)
      package::_install curl git unzip xz zip mesa-libGLU clang cmake ninja-build \
        pkgconf-pkg-config gtk3-devel libstdc++-devel
      ;;
  esac
}

### Install dependencies and clone a stable Flutter SDK.
###
### An existing Flutter SDK in INSTALL_DIRECTORY is replaced. Other nonempty
### directories are rejected.
###
### Arguments
###
### * VERSION - Flutter release tag. Defaults to the newest stable release.
### * INSTALL_DIRECTORY - SDK directory. Defaults to $HOME/.local/flutter.
flutter::install() {
  [[ "$#" -le 2 ]] || return 64
  local version="${1:-}" directory="${2:-${HOME}/.local/flutter}"
  [[ -z "${version}" || "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 64
  flutter::dependencies::install || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(flutter::versions | package::_latest-stable-version)" || return "$?"
  fi
  if [[ -e "${directory}" ]]; then
    if [[ -x "${directory}/bin/flutter" && -d "${directory}/.git" ]]; then
      rm -rf -- "${directory}" || return 74
    elif ! path::is-empty-directory "${directory}"; then
      console::_write-error "Directory is not a Flutter SDK: ${directory}"
      return 73
    fi
  fi
  mkdir -p -- "$(path::directory-name "${directory}")" || return 74
  git clone --branch "${version}" https://github.com/flutter/flutter.git "${directory}"
}

### Set VLC as the default application for every MIME type it declares.
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

### Write the platform package name for a Mozc component.
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

### Write Mozc server versions provided for the running operating-system release.
mozc::server::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(mozc::_package-name server)" || return "$?"
  package::_versions "${package}"
}

### Install the Mozc server, defaulting to the newest version for the running release.
mozc::server::install() {
  [[ "$#" -le 1 ]] || return 64
  local package='' version="${1:-}"
  package="$(mozc::_package-name server)" || return "$?"
  if [[ -z "${version}" ]]; then
    version="$(package::_latest-version "${package}")" || return "$?"
  fi
  package::_install "${package}=${version}"
}

### Write IBus Mozc versions provided for the running operating-system release.
mozc::ibus::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(mozc::_package-name ibus)" || return "$?"
  package::_versions "${package}"
}

### Install IBus Mozc and the Mozc server of the same version.
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

### Write Mozc GUI tool versions provided for the running operating-system release.
mozc::tool::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(mozc::_package-name tool)" || return "$?"
  package::_versions "${package}"
}

### Install the Mozc GUI tools.
mozc::tool::install() {
  [[ "$#" -le 1 ]] || return 64
  local package=''
  package="$(mozc::_package-name tool)" || return "$?"
  package::_install-version "${package}" "${1:-}"
}

### Write the OpenSSH server package and service names for the current platform.
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

### Write OpenSSH server versions available to the current platform.
ssh-server::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local server_names=''
  server_names="$(ssh-server::_names)" || return "$?"
  package::_versions "${server_names%% *}"
}

### Install the OpenSSH server, enable it at boot, and start it.
ssh-server::install() {
  [[ "$#" -le 1 ]] || return 64
  local server_names=''
  server_names="$(ssh-server::_names)" || return "$?"
  package::_install-version "${server_names%% *}" "${1:-}" || return "$?"
  package::_enable-service "${server_names#* }"
}

### Register the Microsoft VS Code repository for the current Linux platform.
vscode::_register-repository() {
  [[ "$#" -eq 1 ]] || return 64
  if [[ "$1" == 'ubuntu' ]]; then
    local architecture=''
    architecture="$(package::_deb-architecture)" || return "$?"
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

### Write VS Code versions available to the current platform.
vscode::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture='' index_entries=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions visual-studio-code
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      index_entries="$(package::_deb-index-entries \
        "https://packages.microsoft.com/repos/code/dists/stable/main/binary-${architecture}/Packages.gz" \
        code)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | package::_sort-versions
      ;;
    fedora)
      package::_rpm-repository-versions https://packages.microsoft.com/yumrepos/vscode code
      ;;
  esac
}

### Install VS Code from the Microsoft repository or Homebrew.
vscode::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask visual-studio-code "${1:-}"
    return
  fi
  vscode::_register-repository "${platform}" || return "$?"
  package::_install-version code "${1:-}"
}

### Register the Google Chrome repository for the current Linux platform.
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

### Write Google Chrome versions available to the current platform.
chrome::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture='' index_entries=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions google-chrome
      ;;
    ubuntu)
      architecture="$(package::_deb-architecture)" || return "$?"
      index_entries="$(package::_deb-index-entries \
        "https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-${architecture}/Packages" \
        google-chrome-stable)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | package::_sort-versions
      ;;
    fedora)
      architecture="$(package::_rpm-architecture)" || return "$?"
      package::_rpm-repository-versions \
        "https://dl.google.com/linux/chrome/rpm/stable/${architecture}" google-chrome-stable
      ;;
  esac
}

### Install Google Chrome from the Google repository or Homebrew.
chrome::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask google-chrome "${1:-}"
    return
  fi
  chrome::_register-repository "${platform}" || return "$?"
  package::_install-version google-chrome-stable "${1:-}"
}

### Write GIMP versions available to the current platform.
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

### Install GIMP, and the G'MIC plugin on platforms whose package manager provides it.
gimp::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  if [[ "${platform}" == 'darwin' ]]; then
    package::_install-cask gimp "${1:-}"
    return
  fi
  package::_install-version gimp "${1:-}" || return "$?"
  gimp::gmic::install
}

### Write the G'MIC GIMP plugin package name for the current platform.
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

### Write G'MIC GIMP plugin versions available to the current platform.
gimp::gmic::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local package=''
  package="$(gimp::gmic::_package-name)" || return "$?"
  package::_versions "${package}"
}

### Install the G'MIC GIMP plugin.
gimp::gmic::install() {
  [[ "$#" -le 1 ]] || return 64
  local package=''
  package="$(gimp::gmic::_package-name)" || return "$?"
  package::_install-version "${package}" "${1:-}"
}

### Write the Microsoft Edge Debian package index URL for the current architecture.
microsoft-edge::_index-url() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture=''
  architecture="$(package::_deb-architecture)" || return "$?"
  printf 'https://packages.microsoft.com/repos/edge/dists/stable/main/binary-%s/Packages.gz\n' "${architecture}"
}

### Write the Microsoft Edge package URL for a version from the vendor package metadata.
###
### Arguments
###
### * VERSION - Package version. Defaults to the newest stable version.
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

### Write Microsoft Edge versions available to the current platform.
microsoft-edge::versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' index='' index_entries=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_cask-versions microsoft-edge
      ;;
    ubuntu)
      index="$(microsoft-edge::_index-url)" || return "$?"
      index_entries="$(package::_deb-index-entries "${index}" microsoft-edge-stable)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | package::_sort-versions
      ;;
    fedora)
      package::_rpm-repository-versions https://packages.microsoft.com/yumrepos/edge microsoft-edge-stable
      ;;
  esac
}

### Install Microsoft Edge from vendor metadata, the vendor repository, or Homebrew.
microsoft-edge::install() {
  [[ "$#" -le 1 ]] || return 64
  local platform='' url=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      package::_install-cask microsoft-edge "${1:-}"
      ;;
    ubuntu)
      url="$(microsoft-edge::_artifact-url "${1:-}")" || return "$?"
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
      package::_install-version microsoft-edge-stable "${1:-}"
      ;;
  esac
}

### Write the newest Command Line Tools label offered by softwareupdate.
xcode::command-line-tools::_latest-label() {
  [[ "$#" -eq 0 ]] || return 64
  command::require softwareupdate || return "$?"
  local labels=''
  labels="$(softwareupdate --list 2>&1 |
    sed -n 's/^[[:space:]]*\*[[:space:]]*Label:[[:space:]]*\(Command Line Tools.*\)$/\1/p')" || return 74
  [[ -n "${labels}" ]] || return 1
  printf '%s\n' "${labels}" | awk '{print $NF "\t" $0}' | package::_sort-by-first-field | tail -n 1
}

### Update Xcode Command Line Tools without removing the installed tools.
###
### When softwareupdate offers no Command Line Tools update, nothing changes.
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

### Install QMK Toolbox with Homebrew on macOS.
qmk::toolbox::install() {
  [[ "$#" -le 1 ]] || return 64
  package::_install-cask qmk-toolbox "${1:-}"
}

### Install the QMK CLI with the official installer and diagnose the environment.
###
### Arguments
###
### * VERSION - QMK CLI version. Only the newest stable version from PyPI is accepted.
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
  command::require qmk || return "$?"
  qmk doctor
}

### Write the newest QMK CLI version published on PyPI.
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

### Write Supabase CLI versions available to the current platform.
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

### Install the Supabase CLI from its Homebrew tap or release packages.
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
