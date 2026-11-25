#!/usr/bin/env bash
# @file docker
# @brief Docker installation, containers, and volumes.
# @description Container functions wrap one docker command each and return 69 when docker is unavailable.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Run an external command while preserving its output and status.
# @internal
_docker__run-command() { [[ "$#" -ge 1 ]] || return 64; command -v "$1" >/dev/null 2>&1 || return 69; local command_name="$1"; shift; command "$command_name" "$@"; }

# @description List running Docker containers.
#
# @noargs
# @stdout The output of docker ps.
# @exitcode 0 The containers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker ps.
# @example
#   docker__container__list-running
docker__container__list-running() { [[ "$#" -eq 0 ]] || return 64; _docker__run-command docker ps; }

# @description List Docker containers.
#
# @noargs
# @stdout The output of docker ps -a.
# @exitcode 0 The containers were written.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker ps.
# @example
#   docker__container__list
docker__container__list() { [[ "$#" -eq 0 ]] || return 64; _docker__run-command docker ps -a; }

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
#   docker__container__pull web /var/log/nginx ./logs
docker__container__pull() { [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64; local container="$1" source="$2" destination="${3:-.}"; _docker__run-command docker cp "$container:$source" "$destination"; }

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
#   docker__container__push web ./nginx.conf /etc/nginx/nginx.conf
docker__container__push() {
  [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64
  _docker__run-command docker cp "$2" "$1:${3:-.}"
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
#   docker__container__shell web
#   docker__container__shell web nginx -t
docker__container__shell() {
  [[ "$#" -ge 1 && -n "$1" ]] || return 64
  local container="$1"
  shift
  if [[ "$#" -eq 0 ]]; then
    _docker__run-command docker exec -it "${container}" sh -c 'if command -v bash >/dev/null 2>&1; then exec bash; fi; exec sh'
  else
    _docker__run-command docker exec -i "${container}" "$@"
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
#   docker__container__logs web
docker__container__logs() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  _docker__run-command docker logs --follow "$1"
}

# @description Stop a container.
#
# @arg $1 string Container name or ID.
# @exitcode 0 The container stopped.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker stop.
# @example
#   docker__container__stop web
docker__container__stop() { [[ "$#" -eq 1 ]] || return 64; _docker__run-command docker stop "$1"; }

# @description Start a container.
#
# @arg $1 string Container name or ID.
# @exitcode 0 The container started.
# @exitcode 64 The argument count is not one.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of docker start.
# @example
#   docker__container__start web
docker__container__start() { [[ "$#" -eq 1 ]] || return 64; _docker__run-command docker start "$1"; }

# @description Stop every running container; having none is a success.
#
# @noargs
# @exitcode 0 No container is running.
# @exitcode 64 An argument was given.
# @exitcode 69 docker is unavailable.
# @exitcode other The status of the docker command that failed.
# @example
#   docker__container__stop-all
docker__container__stop-all() {
  [[ "$#" -eq 0 ]] || return 64
  command__require docker || return "$?"
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
#   docker__container__remove-all
docker__container__remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  command__require docker || return "$?"
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
#   docker__volume__remove-all
docker__volume__remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  command__require docker || return "$?"
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
#   docker__remove-all
docker__remove-all() {
  [[ "$#" -eq 0 ]] || return 64
  docker__container__remove-all || return "$?"
  docker__volume__remove-all
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
#   docker__login-artifactory example.jfrog.io builder "$(pass show jfrog/token)"
docker__login-artifactory() {
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
#   docker__versions | tail -n 1
docker__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local platform='' architecture='' codename='' index_entries=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    darwin)
      _package__versions docker
      ;;
    ubuntu)
      architecture="$(_package__deb-architecture)" || return "$?"
      codename="$(_docker__ubuntu-codename)" || return "$?"
      index_entries="$(_package__deb-index-entries \
        "https://download.docker.com/linux/ubuntu/dists/${codename}/stable/binary-${architecture}/Packages" \
        docker-ce)" || return "$?"
      printf '%s\n' "${index_entries}" | cut -f 1 | _package__sort-versions
      ;;
    fedora)
      architecture="$(_package__rpm-architecture)" || return "$?"
      local release=''
      release="$(_platform__os-release-value VERSION_ID)" || return "$?"
      _package__rpm-repository-versions \
        "https://download.docker.com/linux/fedora/${release}/${architecture}/stable" docker-ce
      ;;
  esac
}

# @description Write the Ubuntu codename used by the Docker repository.
# @internal
_docker__ubuntu-codename() {
  [[ "$#" -eq 0 ]] || return 64
  _platform__os-release-value UBUNTU_CODENAME 2>/dev/null ||
    _platform__os-release-value VERSION_CODENAME
}

# @description Install the Docker CLI, and Docker Engine on Linux.
#
# On macOS, Colima or Rancher Desktop must already be installed and running.
# On Ubuntu and Fedora, the official Docker repository is registered and the
# docker service is enabled and started. Conflicting packages such as
# docker.io are removed only after the repository is ready, and are installed
# again when Docker cannot be installed.
#
# @arg $1 string Optional version from docker__versions. Defaults to the newest stable version.
# @stderr A message on macOS when no container runtime is running.
# @exitcode 0 Docker is installed, and on Linux the service is enabled and running.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform or version is unsupported, or on macOS neither Colima nor Rancher Desktop is running.
# @exitcode 74 The repository or its key could not be downloaded.
# @exitcode other The status of the package manager or systemctl.
# @example
#   docker__install
#   docker run --rm hello-world
docker__install() {
  [[ "$#" -le 1 ]] || return 64
  local version="${1:-}" platform=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    darwin) _docker__install-darwin "${version}" ;;
    ubuntu) _docker__install-ubuntu "${version}" ;;
    fedora) _docker__install-fedora "${version}" ;;
  esac
}

# @description Test whether Colima or Rancher Desktop is running on macOS.
# @internal
_docker__container-runtime-is-running() {
  [[ "$#" -eq 0 ]] || return 64
  if command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then
    return 0
  fi
  command -v pgrep >/dev/null 2>&1 && pgrep -f 'Rancher Desktop' >/dev/null 2>&1
}

# @description Install the Docker CLI plugins with Homebrew on macOS.
# @internal
_docker__install-darwin() {
  [[ "$#" -eq 1 ]] || return 64
  if ! _docker__container-runtime-is-running; then
    _console__write-error 'Install and start Colima or Rancher Desktop before installing Docker.'
    return 69
  fi
  local plugin='' prefix=''
  _package__install "docker${1:+=$1}" docker-credential-helper docker-compose docker-buildx || return "$?"
  prefix="$(brew --prefix)" || return 74
  mkdir -p -- "${HOME}/.docker/cli-plugins" || return 74
  for plugin in docker-buildx docker-compose; do
    ln -sfn "${prefix}/opt/${plugin}/bin/${plugin}" "${HOME}/.docker/cli-plugins/${plugin}" || return 74
  done
}

# @description Install Docker Engine from the official repository on Ubuntu.
# @internal
_docker__install-ubuntu() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" codename='' architecture='' package=''
  codename="$(_docker__ubuntu-codename)" || return "$?"
  architecture="$(_package__deb-architecture)" || return "$?"
  command__require curl || return "$?"
  if ! curl -fsSI "https://download.docker.com/linux/ubuntu/dists/${codename}/Release" >/dev/null 2>&1; then
    _console__write-error "The Docker repository does not provide Ubuntu ${codename}."
    return 69
  fi
  _package__refresh || return "$?"
  _package__install ca-certificates curl || return "$?"
  _package__apt-register-repository docker https://download.docker.com/linux/ubuntu/gpg \
    https://download.docker.com/linux/ubuntu "${codename}" stable "${architecture}" || return "$?"
  if [[ -n "${version}" ]] && ! apt-cache show "docker-ce=${version}" >/dev/null 2>&1; then
    _console__write-error "The Docker repository does not provide docker-ce ${version}."
    return 69
  fi
  # Conflicting runtimes are removed only once the replacement is available,
  # and they are installed again when the replacement fails.
  local status=0 removed=()
  for package in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q 'install ok installed' || continue
    if command__run-as-root env DEBIAN_FRONTEND=noninteractive apt-get remove -y "${package}" >/dev/null 2>&1; then
      removed+=("${package}")
    fi
  done
  _package__install "docker-ce${version:+=${version}}" "docker-ce-cli${version:+=${version}}" \
    containerd.io docker-buildx-plugin docker-compose-plugin || status="$?"
  if [[ "${status}" -ne 0 ]]; then
    [[ "${#removed[@]}" -eq 0 ]] || _package__install "${removed[@]}" || true
    return "${status}"
  fi
  _package__enable-service docker || return "$?"
  _package__add-current-user-to-group docker
}

# @description Install Docker Engine from the official repository on Fedora.
# @internal
_docker__install-fedora() {
  [[ "$#" -eq 1 ]] || return 64
  local version="$1" cli_version="${1#*:}" repository='' buildx_package='docker-buildx-plugin' package=''
  repository="$(_package__fetch https://download.docker.com/linux/fedora/docker-ce.repo)" || return "$?"
  _package__dnf-register-repository docker-ce "${repository}"$'\n' || return "$?"
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
    if command__run-as-root dnf remove -y "${package}" >/dev/null 2>&1; then
      removed+=("${package}")
    fi
  done
  _package__install "docker-ce${version:+=${version}}" "docker-ce-cli${cli_version:+=${cli_version}}" \
    containerd.io ${buildx_package:+"${buildx_package}"} docker-compose-plugin || status="$?"
  if [[ "${status}" -ne 0 ]]; then
    [[ "${#removed[@]}" -eq 0 ]] || _package__install "${removed[@]}" || true
    return "${status}"
  fi
  if [[ -z "${version}" ]]; then
    command__run-as-root dnf upgrade -y docker-ce docker-ce-cli containerd.io \
      ${buildx_package:+"${buildx_package}"} docker-compose-plugin || return "$?"
  fi
  if [[ -z "${buildx_package}" ]]; then
    _docker__install-buildx-plugin || return "$?"
  fi
  _package__enable-service docker || return "$?"
  _package__add-current-user-to-group docker
}

# @description Install the official Buildx CLI plugin when the Docker RPM repository does not package it.
# @internal
_docker__install-buildx-plugin() {
  [[ "$#" -eq 0 ]] || return 64
  local architecture='' directory='' status=0
  architecture="$(_package__rpm-architecture)" || return "$?"
  case "${architecture}" in
    x86_64) architecture='amd64' ;;
    aarch64) architecture='arm64' ;;
    *) return 69 ;;
  esac
  directory="$(_package__temporary-directory)" || return "$?"
  _package__download \
    "https://github.com/docker/buildx/releases/download/v0.10.5/buildx-v0.10.5.linux-${architecture}" \
    "${directory}/docker-buildx" || status="$?"
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -d -m 0755 /usr/local/lib/docker/cli-plugins || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    command__run-as-root install -m 0755 "${directory}/docker-buildx" \
      /usr/local/lib/docker/cli-plugins/docker-buildx || status=74
  fi
  rm -rf -- "${directory}"
  return "${status}"
}
