#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

### Write the platform that package operations support: darwin, ubuntu, or fedora.
package::_platform() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(platform::_identifier)" || return "$?"
  case "${platform}" in
    darwin | ubuntu | fedora)
      printf '%s\n' "${platform}"
      ;;
    *)
      console::_write-error "Unsupported platform: ${platform}"
      return 69
      ;;
  esac
}

### Require the current platform to be one of the given identifiers.
package::_require-platform() {
  [[ "$#" -ge 1 ]] || return 64
  local platform='' candidate=''
  platform="$(package::_platform)" || return "$?"
  for candidate in "$@"; do
    [[ "${platform}" == "${candidate}" ]] && return 0
  done
  console::_write-error "This operation does not support ${platform}."
  return 69
}

### Test whether a version is a stable release rather than a preview.
package::_is-stable-version() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local lower=''
  lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  [[ ! "${lower}" =~ (alpha|beta|preview|nightly|canary|snapshot|dev|[0-9.]rc|-rc|~rc) ]]
}

### Read versions from standard input and write unique values in ascending version order.
package::_sort-versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  perl -e '
    sub compare_versions {
      my ($left, $right) = @_;
      my $left_epoch = $left =~ s/^([0-9]+):// ? $1 : 0;
      my $right_epoch = $right =~ s/^([0-9]+):// ? $1 : 0;
      return $left_epoch <=> $right_epoch if $left_epoch != $right_epoch;
      my @left = split /([0-9]+)/, $left;
      my @right = split /([0-9]+)/, $right;
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
    my %seen;
    my @versions = grep { length && !$seen{$_}++ } map { s/^\s+|\s+$//gr } <STDIN>;
    print "$_\n" for sort { compare_versions($a, $b) } @versions;
  '
}

### Read versions from standard input and write stable values in ascending version order.
package::_sort-stable-versions() {
  [[ "$#" -eq 0 ]] || return 64
  local version=''
  while IFS= read -r version; do
    [[ -n "${version}" ]] || continue
    package::_is-stable-version "${version}" && printf '%s\n' "${version}"
  done | package::_sort-versions
}

### Read versions from standard input and write the newest stable value.
package::_latest-stable-version() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(package::_sort-stable-versions)" || return "$?"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions##*$'\n'}"
}

### Create a private temporary directory and write its path.
package::_temporary-directory() {
  [[ "$#" -eq 0 ]] || return 64
  command::require mktemp || return "$?"
  mktemp -d "${TMPDIR:-/tmp}/bashstock.XXXXXX" 2>/dev/null || return 74
}

### Write the body of one HTTPS URL to standard output.
package::_fetch() {
  [[ "$#" -eq 1 && "$1" == https://* ]] || return 64
  command::require curl || return "$?"
  curl -fsSL --retry 3 "$1" || return 74
}

### Download one HTTPS URL to a nonempty file.
package::_download() {
  [[ "$#" -eq 2 && "$1" == https://* && -n "$2" ]] || return 64
  command::require curl || return "$?"
  curl -fsSL --retry 3 -o "$2" "$1" || return 74
  [[ -f "$2" && -s "$2" ]] || return 74
}

### Write the Debian architecture name of the current system.
package::_deb-architecture() {
  [[ "$#" -eq 0 ]] || return 64
  command::require dpkg || return "$?"
  dpkg --print-architecture || return 74
}

### Write the RPM base architecture of the current system.
package::_rpm-architecture() {
  [[ "$#" -eq 0 ]] || return 64
  command::require uname || return "$?"
  uname -m || return 74
}

### Write available versions of a Homebrew formula and its versioned formulae.
package::_brew-formula-versions() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  command::require brew || return "$?"
  command::require perl || return "$?"
  local json=''
  json="$(brew info --json=v2 --formula "$1")" || return 1
  printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    for my $formula (@{$data->{formulae} || []}) {
      print "$formula->{versions}{stable}\n" if defined $formula->{versions}{stable};
      for my $name (@{$formula->{versioned_formulae} || []}) {
        print "$1\n" if $name =~ /\@(.+)$/;
      }
    }
  '
}

### Write the stable version of a Homebrew formula.
package::_brew-formula-stable-version() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  command::require brew || return "$?"
  command::require perl || return "$?"
  local json=''
  json="$(brew info --json=v2 --formula "$1")" || return 1
  printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    my $formula = $data->{formulae}[0] or exit 1;
    print "$formula->{versions}{stable}\n";
  '
}

### Write the version of a Homebrew cask.
package::_brew-cask-version() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  command::require brew || return "$?"
  command::require perl || return "$?"
  local json=''
  json="$(brew info --json=v2 --cask "$1")" || return 1
  printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    my $cask = $data->{casks}[0] or exit 1;
    my $version = $cask->{version};
    $version =~ s/,.*$//;
    print "$version\n";
  '
}

### Write available versions of one system package in ascending version order.
###
### macOS uses a Homebrew formula, Ubuntu uses APT, and Fedora uses DNF.
package::_versions() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin)
      local versions=''
      versions="$(package::_brew-formula-versions "$1")" || return "$?"
      printf '%s\n' "${versions}" | package::_sort-versions
      ;;
    ubuntu)
      command::require apt-cache || return "$?"
      local versions=''
      versions="$(apt-cache madison "$1" 2>/dev/null |
        awk -F'|' '$3 ~ /Packages/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')" || return 74
      printf '%s\n' "${versions}" | package::_sort-versions
      ;;
    fedora)
      command::require dnf || return "$?"
      local versions=''
      versions="$(dnf repoquery --quiet --queryformat $'%{evr}\n' "$1" 2>/dev/null)" || return 74
      printf '%s\n' "${versions}" | package::_sort-versions
      ;;
  esac
}

### Write the newest stable version of one system package.
package::_latest-version() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local versions=''
  versions="$(package::_versions "$1")" || return "$?"
  printf '%s\n' "${versions}" | package::_latest-stable-version
}

### Refresh package indexes after changing package sources.
package::_refresh() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(package::_platform)" || return "$?"
  case "${platform}" in
    darwin) command::require brew || return "$?"; brew update ;;
    ubuntu) command::run-as-root apt-get update ;;
    fedora) command::run-as-root dnf makecache ;;
  esac
}

### Install system packages, each written as NAME or NAME=VERSION.
###
### A Homebrew version that differs from the stable formula version selects
### the versioned formula NAME@VERSION.
### APT permits downgrades only when a version is explicitly requested.
package::_install() {
  [[ "$#" -ge 1 ]] || return 64
  local platform='' specification='' name='' version='' stable=''
  local packages=()
  local install_options=()
  platform="$(package::_platform)" || return "$?"
  for specification in "$@"; do
    name="${specification%%=*}"
    version=''
    [[ "${specification}" == *=* ]] && version="${specification#*=}"
    [[ "${name}" =~ ^[A-Za-z0-9][A-Za-z0-9._+/@-]*$ ]] || return 64
    [[ -z "${version}" || "${version}" =~ ^[A-Za-z0-9][A-Za-z0-9.:~+_-]*$ ]] || return 64
    case "${platform}" in
      darwin)
        if [[ -n "${version}" ]]; then
          stable="$(package::_brew-formula-stable-version "${name}")" || return "$?"
          [[ "${version}" == "${stable}" ]] || name="${name}@${version}"
        fi
        packages+=("${name}")
        ;;
      ubuntu)
        packages+=("${name}${version:+=${version}}")
        [[ -z "${version}" ]] || install_options=(--allow-downgrades)
        ;;
      fedora) packages+=("${name}${version:+-${version}}") ;;
    esac
  done
  case "${platform}" in
    darwin)
      command::require brew || return "$?"
      brew install "${packages[@]}"
      ;;
    ubuntu)
      command::require apt-get || return "$?"
      command::run-as-root env DEBIAN_FRONTEND=noninteractive apt-get install -y ${install_options[@]+"${install_options[@]}"} "${packages[@]}"
      ;;
    fedora)
      command::require dnf || return "$?"
      command::run-as-root dnf install -y "${packages[@]}"
      ;;
  esac
}

### Install one system package whose optional version is selected by the caller.
package::_install-version() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  if [[ -n "${2:-}" ]]; then
    package::_install "$1=$2"
  else
    package::_install "$1"
  fi
}

### Install a Homebrew cask, accepting only its current version when one is given.
package::_install-cask() {
  [[ "$#" -ge 1 && "$#" -le 2 && "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._/@-]*$ ]] || return 64
  package::_require-platform darwin || return "$?"
  command::require brew || return "$?"
  if [[ -n "${2:-}" ]]; then
    local current=''
    current="$(package::_brew-cask-version "$1")" || return "$?"
    if [[ "$2" != "${current}" ]]; then
      console::_write-error "Homebrew provides only version ${current} of $1."
      return 69
    fi
  fi
  brew install --cask "$1"
}

### Write versions of a Homebrew cask.
package::_cask-versions() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  package::_require-platform darwin || return "$?"
  package::_brew-cask-version "$1"
}

### Write stable release versions of a GitHub repository without a leading v.
package::_github-release-versions() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || return 64
  command::require perl || return "$?"
  local json='' versions=''
  json="$(package::_fetch "https://api.github.com/repos/$1/releases?per_page=100")" || return "$?"
  versions="$(printf '%s' "${json}" | perl -MJSON::PP -e '
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    for my $release (@$data) {
      next if $release->{draft} || $release->{prerelease};
      my $tag = $release->{tag_name};
      $tag =~ s/^v(?=[0-9])//;
      print "$tag\n";
    }
  ')" || return "$?"
  printf '%s\n' "${versions}" | package::_sort-stable-versions
}

### Write the download URL of a GitHub release asset whose name matches a Perl expression.
package::_github-release-asset-url() {
  [[ "$#" -eq 3 && "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && -n "$2" && -n "$3" ]] || return 64
  command::require perl || return "$?"
  local json=''
  json="$(package::_fetch "https://api.github.com/repos/$1/releases?per_page=100")" || return "$?"
  printf '%s' "${json}" | perl -MJSON::PP -e '
    my ($version, $expression) = @ARGV;
    local $/;
    my $data = eval { decode_json(<STDIN>) } or exit 74;
    my $pattern = eval { qr/$expression/ } or exit 64;
    for my $release (@$data) {
      next unless $release->{tag_name} eq $version || $release->{tag_name} eq "v$version";
      for my $asset (@{$release->{assets} || []}) {
        if ($asset->{name} =~ $pattern) {
          print "$asset->{browser_download_url}\n";
          exit 0;
        }
      }
    }
    exit 1;
  ' "$2" "$3"
}

### Write VERSION and FILENAME pairs of one package from an APT Packages index URL.
package::_deb-index-entries() {
  [[ "$#" -eq 2 && "$1" == https://* && -n "$2" ]] || return 64
  command::require perl || return "$?"
  local directory='' index='' status=0
  directory="$(package::_temporary-directory)" || return "$?"
  index="${directory}/Packages"
  if [[ "$1" == *.gz ]]; then
    package::_download "$1" "${index}.gz" || status="$?"
    if [[ "${status}" -eq 0 ]]; then
      command::require gzip || status="$?"
      [[ "${status}" -ne 0 ]] || gzip -dc -- "${index}.gz" >"${index}" || status=74
    fi
  else
    package::_download "$1" "${index}" || status="$?"
  fi
  if [[ "${status}" -eq 0 ]]; then
    perl -e '
      my $name = shift;
      local $/ = "";
      while (my $stanza = <STDIN>) {
        my %field;
        $field{lc $1} = $2 while $stanza =~ /^([A-Za-z-]+):\s*(.*)$/mg;
        next unless defined $field{package} && $field{package} eq $name;
        print "$field{version}\t$field{filename}\n";
      }
    ' "$2" <"${index}" || status=74
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

### Write versions of one package from an RPM repository without registering it.
package::_rpm-repository-versions() {
  [[ "$#" -eq 2 && "$1" == https://* && -n "$2" ]] || return 64
  command::require dnf || return "$?"
  local versions=''
  versions="$(dnf repoquery --quiet --disablerepo='*' --repofrompath="bashstock-query,$1" \
    --enablerepo=bashstock-query --queryformat $'%{evr}\n' "$2" 2>/dev/null)" || return 74
  printf '%s\n' "${versions}" | package::_sort-versions
}

### Register an APT repository with a dedicated key and a deb822 source file.
###
### Arguments
###
### * NAME - File name stem for the key and source files.
### * KEY_URL - HTTPS URL of the armored signing key.
### * URI - Repository URI.
### * SUITE - Suite name, or ./ for a flat repository.
### * COMPONENTS - Space-separated components, or an empty value for a flat repository.
### * ARCHITECTURE - Optional architecture restriction.
package::_apt-register-repository() {
  [[ "$#" -ge 5 && "$#" -le 6 && "$1" =~ ^[a-z0-9][a-z0-9.-]*$ && "$2" == https://* && "$3" == https://* && -n "$4" ]] || return 64
  package::_require-platform ubuntu || return "$?"
  local name="$1" key_url="$2" uri="$3" suite="$4" components="$5" architecture="${6:-}"
  local directory='' content='' status=0
  directory="$(package::_temporary-directory)" || return "$?"
  package::_download "${key_url}" "${directory}/${name}.asc" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -d -m 0755 /etc/apt/keyrings || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command::run-as-root install -m 0644 "${directory}/${name}.asc" "/etc/apt/keyrings/${name}.asc" || status=74
  fi
  rm -rf -- "${directory}"
  [[ "${status}" -eq 0 ]] || return "${status}"

  content="Types: deb"$'\n'"URIs: ${uri}"$'\n'"Suites: ${suite}"$'\n'
  [[ -z "${components}" ]] || content+="Components: ${components}"$'\n'
  [[ -z "${architecture}" ]] || content+="Architectures: ${architecture}"$'\n'
  content+="Signed-By: /etc/apt/keyrings/${name}.asc"$'\n'
  file::write-text "/etc/apt/sources.list.d/${name}.sources" "${content}" || return "$?"
  package::_refresh
}

### Register a DNF repository by writing one repository file.
package::_dnf-register-repository() {
  [[ "$#" -eq 2 && "$1" =~ ^[a-z0-9][a-z0-9.-]*$ && -n "$2" ]] || return 64
  package::_require-platform fedora || return "$?"
  file::write-text "/etc/yum.repos.d/$1.repo" "$2" || return "$?"
  package::_refresh
}

### Enable and start one systemd service.
package::_enable-service() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9@._-]+$ ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl enable --now "$1"
}

### Add the current user to a group through administrator execution.
package::_add-current-user-to-group() {
  [[ "$#" -eq 1 && "$1" =~ ^[a-z_][a-z0-9_-]*$ ]] || return 64
  local user=''
  user="$(user::name)" || return "$?"
  case "$(system::operating-system)" in
    darwin)
      command::require dseditgroup || return "$?"
      command::run-as-root dseditgroup -o edit -a "${user}" -t user "$1"
      ;;
    linux)
      command::require usermod || return "$?"
      command::run-as-root usermod -a -G "$1" "${user}"
      ;;
    *)
      return 69
      ;;
  esac
}
