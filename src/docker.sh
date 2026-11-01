#!/usr/bin/env bash
# @file docker
# @brief Docker installation, containers, and volumes.
# @description Container functions wrap one docker command each and return 69 when docker is unavailable.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Run an external command while preserving its output and status.
# @internal
docker::_run-command() { [[ "$#" -ge 1 ]] || return 64; command -v "$1" >/dev/null 2>&1 || return 69; local command_name="$1"; shift; command "$command_name" "$@"; }

# @description List running Docker containers.
#
# @noargs
# @stdout The output of docker ps.
# @exitcode 0 The containers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker ps.
# @example
#   docker::container::list-running
docker::container::list-running() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command docker ps; }

# @description List Docker containers.
#
# @noargs
# @stdout The output of docker ps -a.
# @exitcode 0 The containers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker ps.
# @example
#   docker::container::list
docker::container::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command docker ps -a; }

# @description Copy files between a Docker container and the host.
#
# @arg $1 string Container name or ID.
# @arg $2 string Path in the container.
# @arg $3 string Optional host destination. Defaults to the current directory.
# @exitcode 0 The files were copied.
# @exitcode 64 The argument count is not two or three.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker cp.
# @example
#   docker::container::pull web /var/log/nginx ./logs
docker::container::pull() { [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64; local container="$1" source="$2" destination="${3:-.}"; docker::_run-command docker cp "$container:$source" "$destination"; }

# @description Copy a host path into a container.
#
# @arg $1 string Container name or ID.
# @arg $2 string Path on the host.
# @arg $3 string Optional destination in the container. Defaults to its working directory.
# @exitcode 0 The files were copied.
# @exitcode 64 The argument count is not two or three.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker cp.
# @example
#   docker::container::push web ./nginx.conf /etc/nginx/nginx.conf
docker::container::push() {
  [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64
  docker::_run-command docker cp "$2" "$1:${3:-.}"
}

# @description Run an interactive shell or a command in a container.
#
# Without COMMAND, Bash is used when the container has it and sh otherwise,
# with a terminal attached. A COMMAND receives standard input without a
# terminal, so it also works from scripts and CI.
#
# @arg $1 string Container name or ID.
# @arg $@ string Optional command and its arguments.
# @exitcode 0 The shell or command exited successfully.
# @exitcode 64 No container was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker exec.
# @example
#   docker::container::shell web
#   docker::container::shell web nginx -t
docker::container::shell() {
  [[ "$#" -ge 1 && -n "$1" ]] || return 64
  local container="$1"
  shift
  if [[ "$#" -eq 0 ]]; then
    docker::_run-command docker exec -it "${container}" sh -c 'if command -v bash >/dev/null 2>&1; then exec bash; fi; exec sh'
  else
    docker::_run-command docker exec -i "${container}" "$@"
  fi
}

# @description Follow the log of a container.
#
# @arg $1 string Container name or ID.
# @stdout The container log, followed until interrupted.
# @exitcode 0 docker logs ended successfully.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker logs.
# @example
#   docker::container::logs web
docker::container::logs() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  docker::_run-command docker logs --follow "$1"
}

# @description Stop a container.
#
# @arg $1 string Container name or ID.
# @exitcode 0 The container stopped.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker stop.
# @example
#   docker::container::stop web
docker::container::stop() { [[ "$#" -eq 1 ]] || return 64; docker::_run-command docker stop "$1"; }

# @description Start a container.
#
# @arg $1 string Container name or ID.
# @exitcode 0 The container started.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker start.
# @example
#   docker::container::start web
docker::container::start() { [[ "$#" -eq 1 ]] || return 64; docker::_run-command docker start "$1"; }

# @description Stop every running container; having none is a success.
#
# @noargs
# @exitcode 0 No container is running.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::container::stop-all
docker::container::stop-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require docker || return "$?"
  local identifier='' identifiers=''
  identifiers="$(docker ps -q)" || return "$?"
  while IFS= read -r identifier; do
    [[ -n "${identifier}" ]] || continue
    docker stop "${identifier}" >/dev/null || return "$?"
  done <<<"${identifiers}"
}

# @description Remove every container, running or not.
#
# @noargs
# @exitcode 0 No container remains.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::container::remove-all
docker::container::remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require docker || return "$?"
  local identifier='' identifiers=''
  identifiers="$(docker ps -aq)" || return "$?"
  while IFS= read -r identifier; do
    [[ -n "${identifier}" ]] || continue
    docker rm --force "${identifier}" >/dev/null || return "$?"
  done <<<"${identifiers}"
}

# @description Remove every Docker volume.
#
# @noargs
# @exitcode 0 No volume remains.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::volume::remove-all
docker::volume::remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  command::require docker || return "$?"
  local volume='' volumes=''
  volumes="$(docker volume ls -q)" || return "$?"
  while IFS= read -r volume; do
    [[ -n "${volume}" ]] || continue
    docker volume rm --force "${volume}" >/dev/null || return "$?"
  done <<<"${volumes}"
}

# @description Remove every container and then every volume, stopping at the first failure.
#
# @noargs
# @exitcode 0 No container or volume remains.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker::remove-all
docker::remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  docker::container::remove-all || return "$?"
  docker::volume::remove-all
}

# @description Log in to an Artifactory Docker registry using a token on standard input.
#
# The token is passed to docker on standard input, never as an argument.
#
# @arg $1 string Registry host.
# @arg $2 string User name.
# @arg $3 string Access token.
# @exitcode 0 The login succeeded.
# @exitcode 64 The argument count is not three or an argument is empty.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker login.
# @example
#   docker::login-artifactory example.jfrog.io builder "$(pass show jfrog/token)"
docker::login-artifactory() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  command -v docker >/dev/null 2>&1 || return 69
  printf '%s\n' "$3" | docker login "$1" --username "$2" --password-stdin
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
