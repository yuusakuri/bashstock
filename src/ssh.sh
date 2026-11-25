#!/usr/bin/env bash
# @file ssh
# @brief SSH keys, configuration, connections, and server installation.
# @description Keys and host entries live in the user's ~/.ssh directory.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Create $HOME/.ssh and give it and its files the modes SSH expects.
#
# Entries owned by another user are first given back to the current user
# through administrator execution. Directories become 700 and files 644,
# except private keys, config, and authorized_keys, which become 600. A
# private key is recognized by its PEM or OpenSSH header, so no passphrase
# is ever requested.
#
# @noargs
# @exitcode 0 The directory and its files have the expected modes.
# @exitcode 64 An argument was given.
# @exitcode 74 A mode or owner could not be changed.
# @example
#   ssh__setup-directory
ssh__setup-directory() {
  [[ "$#" -eq 0 ]] || return 64
  local directory="${HOME}/.ssh" path='' header=''
  mkdir -p -- "${directory}" || return 74
  if [[ -n "$(find "${directory}" ! -user "$(id -u)" -print 2>/dev/null | head -n 1)" ]]; then
    command__run-as-root chown -R "$(id -u):$(id -g)" "${directory}" || return 74
  fi
  find "${directory}" -type d -exec chmod 700 {} + || return 74
  while IFS= read -r -d '' path; do
    header=''
    IFS= read -r header <"${path}" 2>/dev/null || true
    case "${path##*/}:${header}" in
      config:* | authorized_keys:* | *:'-----BEGIN '*'PRIVATE KEY-----') chmod 600 "${path}" || return 74 ;;
      *) chmod 644 "${path}" || return 74 ;;
    esac
  done < <(find "${directory}" -type f -print0)
}

# @description Replace one marker-managed SSH Host block and validate the resulting configuration.
#
# The block is placed first so that its options take precedence, and it ends
# with Host * so that directives after it still apply to every host. Option
# names are compared case-insensitively, as SSH does.
#
# @internal
_ssh__config__write-block() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  local file="$1" pattern="$2" host_options="$3" begin='' end='' line='' content='' preserved='' old_content='' keys='' option='' key='' validation_host='localhost' token=''
  [[ -f "$file" && ! -L "$file" ]] || return 66
  [[ "$pattern" != *$'\n'* && "$pattern" != *$'\r'* ]] || return 64
  [[ "$host_options" != *$'\r'* ]] || return 64
  command -v ssh >/dev/null 2>&1 || return 69
  old_content="$(<"$file")"
  while IFS= read -r option || [[ -n "$option" ]]; do
    [[ "$option" == '  '* ]] || continue
    key="${option#  }"
    key="$(string__lower "${key%% *}")"
    keys+="|$key|"
  done <<<"$host_options"
  begin="# bashstock: begin $pattern"
  end='# bashstock: end'
  local in_block=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$begin" ]]; then
      in_block=1
      continue
    fi
    if ((in_block)); then
      [[ "$line" == "$end" ]] && in_block=0
      if ((in_block)) && [[ "$line" == '  '* ]]; then
        key="${line#  }"
        key="$(string__lower "${key%% *}")"
        [[ "$keys" == *"|$key|"* ]] && continue
        preserved+="$line"$'\n'
      fi
      continue
    fi
    content+="$line"$'\n'
  done <"$file"
  # Without the end marker every later line would look like part of the block.
  if ((in_block)); then
    _console__write-error "$file has '$begin' without '$end'; it is not changed."
    return 65
  fi
  local block=''
  block="$begin"$'\n'"Host $pattern"$'\n'
  # Host * ends the managed context so later global directives apply to every host.
  block+="$preserved$host_options"$'\n'"Host *"$'\n'"$end"$'\n'
  file__write-text "$file" "$block$content" || return "$?"
  local pattern_parts=()
  read -r -a pattern_parts <<<"$pattern"
  for token in "${pattern_parts[@]}"; do
    [[ "$token" == '!'* ]] && continue
    validation_host="$token"
    break
  done
  if ! ssh -G -F "$file" "$validation_host" >/dev/null 2>&1; then
    file__write-text "$file" "$old_content" >/dev/null 2>&1 || true
    return 65
  fi
}

# @description Update one key in a marker-managed SSH Host block.
#
# The Host block is created when missing. Only blocks written by BashStock are changed.
#
# @arg $1 string SSH configuration file.
# @arg $2 string Host pattern.
# @arg $3 string Key, such as IdentityFile.
# @arg $4 string Value on one line.
# @exitcode 0 The key was written.
# @exitcode 64 The arguments are invalid.
# @exitcode 65 The file has a begin marker without an end marker, or ssh rejected the result; the file is unchanged.
# @exitcode other The status of the file update.
# @example
#   ssh__config__update "${HOME}/.ssh/config" github.com IdentityFile '~/.ssh/github'
ssh__config__update() {
  ( [[ "$#" -eq 4 && -n "$1" && -n "$2" && "$3" =~ ^[A-Za-z][A-Za-z0-9]*$ && -n "$4" ]] ) || return 64
  [[ "$4" != *$'\n'* && "$4" != *$'\r'* ]] || return 64
  _ssh__config__write-block "$1" "$2" "  $3 $4"
}

# @description Create an SSH configuration file when necessary and update one key.
#
# @arg $1 string SSH configuration file. It and its directory are created when missing.
# @arg $2 string Host pattern.
# @arg $3 string Key, such as User.
# @arg $4 string Value on one line.
# @exitcode 0 The key was written.
# @exitcode 64 The arguments are invalid or the file is a symbolic link.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 74 The file could not be created.
# @exitcode other The status of ssh__config__update.
# @example
#   ssh__config__set "${HOME}/.ssh/config" 'build-*' User builder
ssh__config__set() {
  [[ "$#" -eq 4 && -n "$1" ]] || return 64
  [[ ! -L "$1" ]] || return 64
  if [[ -e "$1" && ! -f "$1" ]]; then return 66; fi
  if [[ ! -e "$1" ]]; then
    mkdir -p -- "$(path__directory-name "$1")" || return 74
    : >"$1" || return 74
  fi
  ssh__config__update "$@"
}

# @description Enable AddKeysToAgent for an optional SSH Host pattern.
#
# @arg $1 string Optional SSH configuration file. Defaults to $HOME/.ssh/config.
# @arg $2 string Optional Host pattern. Defaults to *.
# @exitcode 0 AddKeysToAgent is enabled.
# @exitcode 64 More than two arguments were given.
# @exitcode other The status of ssh__config__set.
# @example
#   ssh__config__enable-auto-add-keys
ssh__config__enable-auto-add-keys() {
  [[ "$#" -le 2 ]] || return 64
  local file='' pattern=''
  if [[ "$#" -ge 1 ]]; then file="$1"; else file="$HOME/.ssh/config"; fi
  if [[ "$#" -ge 2 ]]; then pattern="$2"; else pattern='*'; fi
  ssh__config__set "$file" "$pattern" AddKeysToAgent yes
}

# @description Disable SSH host-key checks for an optional Host pattern.
#
# Normal use should register the correct host key in known_hosts instead.
#
# @arg $1 string Optional SSH configuration file. Defaults to $HOME/.ssh/config.
# @arg $2 string Optional Host pattern. Defaults to *.
# @exitcode 0 Host-key checks are disabled for the pattern.
# @exitcode 64 More than two arguments were given or the file is a symbolic link.
# @exitcode 66 The path exists but is not a regular file.
# @exitcode 74 The file could not be created.
# @exitcode other The status of the file update.
# @example
#   ssh__config__disable-host-key-checking "${HOME}/.ssh/config" '192.168.56.*'
ssh__config__disable-host-key-checking() {
  [[ "$#" -le 2 ]] || return 64
  local file='' pattern=''
  if [[ "$#" -ge 1 ]]; then file="$1"; else file="$HOME/.ssh/config"; fi
  if [[ "$#" -ge 2 ]]; then pattern="$2"; else pattern='*'; fi
  [[ ! -L "$file" ]] || return 64
  if [[ -e "$file" && ! -f "$file" ]]; then return 66; fi
  if [[ ! -e "$file" ]]; then
    mkdir -p -- "$(path__directory-name "$file")" || return 74
    : >"$file" || return 74
  fi
  _ssh__config__write-block "$file" "$pattern" $'  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null'
}

# @description List regular files that ssh-keygen can read as private keys.
#
# @arg $1 string Optional directory. Defaults to $HOME/.ssh.
# @stdout One private key path per line.
# @exitcode 0 The paths were written; none may match.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode 69 ssh-keygen is unavailable.
# @example
#   ssh__key__private-files
ssh__key__private-files() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' path=''
  if [[ "$#" -ge 1 ]]; then directory="$1"; else directory="$HOME/.ssh"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  command -v ssh-keygen >/dev/null 2>&1 || return 69
  (
    shopt -s nullglob dotglob
    for path in "$directory"/*; do
      [[ -f "$path" && ! -L "$path" ]] || continue
      ssh-keygen -y -f "$path" </dev/null >/dev/null 2>&1 && printf '%s\n' "$path"
    done
    :
  )
}

# @description Add one private key to ssh-agent.
#
# @arg $1 string Private key file.
# @exitcode 0 The key was added.
# @exitcode 64 The argument is not one regular file.
# @exitcode 69 ssh-add is unavailable.
# @exitcode other The status of ssh-add.
# @example
#   ssh__key__add "${HOME}/.ssh/id_ed25519"
ssh__key__add() {
  [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64
  command -v ssh-add >/dev/null 2>&1 || return 69
  ssh-add "$1"
}

# @description Add every detected private key in a directory to ssh-agent.
#
# @arg $1 string Optional directory. Defaults to $HOME/.ssh.
# @exitcode 0 Every key was added.
# @exitcode 64 More than one argument was given.
# @exitcode 66 The directory does not exist or is a symbolic link.
# @exitcode 69 ssh-add or ssh-keygen is unavailable.
# @exitcode other The status of the last ssh-add that failed.
# @example
#   ssh__key__add-all
ssh__key__add-all() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' path='' key_list='' status=0
  if [[ "$#" -ge 1 ]]; then directory="$1"; else directory="$HOME/.ssh"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  command -v ssh-add >/dev/null 2>&1 || return 69
  # The list is read first, so a failure to detect keys is not reported as success.
  key_list="$(ssh__key__private-files "$directory")" || return "$?"
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    ssh__key__add "$path" || status="$?"
  done <<<"$key_list"
  return "$status"
}

# @description Add every detected private key in a directory to ssh-agent.
#
# This is an alias of ssh__key__add-all.
#
# @arg $1 string Optional directory. Defaults to $HOME/.ssh.
# @exitcode 0 Every key was added.
# @exitcode other The status of ssh__key__add-all.
# @example
#   ssh__key__add-all-private-keys
ssh__key__add-all-private-keys() { ssh__key__add-all "$@"; }

# @description Generate a 4096-bit RSA SSH key and write its public key.
#
# An existing key is replaced only after confirmation on the controlling
# terminal; without a terminal it is kept and 73 is returned. The old key
# stays in place until the new key has been generated.
#
# @option --comment <COMMENT> Key comment. Defaults to an empty comment.
# @option --output <FILE> Private key path. Defaults to $HOME/.ssh/id_rsa.
# @option --passphrase-fd <FD> File descriptor to read the passphrase from. Defaults to no passphrase.
# @stdout The public key.
# @exitcode 0 The key was generated.
# @exitcode 64 An option is unknown or has an invalid value.
# @exitcode 66 The passphrase could not be read.
# @exitcode 69 ssh-keygen is unavailable.
# @exitcode 73 The key exists and was kept.
# @exitcode 74 The directory or the temporary key could not be created, or the new key could not replace the old one.
# @exitcode other The status of ssh-keygen.
# @example
#   ssh__key__generate-rsa4096 --comment 'build server' --output "${HOME}/.ssh/build_rsa"
ssh__key__generate-rsa4096() {
  _ssh__key__generate rsa id_rsa "$@"
}

# @description List the named arguments of ssh__key__generate-rsa4096.
# @internal
_ssh__key__generate-rsa4096-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --comment --output --passphrase-fd; fi
}

# @description Generate an SSH key and write its public key.
# @internal
_ssh__key__generate() {
  local type="$1" default_name="$2" comment='' output='' passphrase_fd='' passphrase=''
  local arguments=()
  shift 2
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --comment | --output | --passphrase-fd)
        arg__require-next "$#" "$1" || return "$?"
        case "$1" in
          --comment) comment="$2" ;;
          --output) output="$2" ;;
          --passphrase-fd) passphrase_fd="$2" ;;
        esac
        shift 2
        ;;
      *) arg__unknown "$1" || return "$?" ;;
    esac
  done
  ( [[ -z "${passphrase_fd}" || "${passphrase_fd}" =~ ^[0-9]+$ ]] ) || return 64
  command__require ssh-keygen || return "$?"
  output="${output:-${HOME}/.ssh/${default_name}}"
  mkdir -p -- "$(path__directory-name "${output}")" || return 74
  if [[ -e "${output}" || -e "${output}.pub" ]]; then
    if ! terminal__is-available; then
      _console__write-error "${output} exists; run in a terminal to confirm overwriting it."
      return 73
    fi
    [[ "$(shell__confirm "Overwrite ${output}?" no </dev/tty)" == yes ]] || return 73
  fi
  case "${type}" in
    rsa) arguments=(-t rsa -b 4096) ;;
    ed25519) arguments=(-t ed25519) ;;
  esac
  if [[ -n "${passphrase_fd}" ]]; then
    IFS= read -r -u "${passphrase_fd}" passphrase || [[ -n "${passphrase}" ]] || return 66
  fi
  # The pair is generated beside the destination and replaces an existing pair
  # only after ssh-keygen succeeds.
  local temporary='' status=0
  temporary="$(mktemp -d "$(path__directory-name "${output}")/.bashstock-key.XXXXXX")" || return 74
  if [[ -n "${passphrase_fd}" ]]; then
    # ssh-keygen reads the passphrase and its confirmation from a standard input that is not a terminal.
    printf '%s\n%s\n' "${passphrase}" "${passphrase}" |
      ssh-keygen "${arguments[@]}" -C "${comment}" -f "${temporary}/key" -q || status="$?"
    passphrase=''
  else
    ssh-keygen "${arguments[@]}" -C "${comment}" -f "${temporary}/key" -N '' -q </dev/null || status="$?"
  fi
  if [[ "${status}" -eq 0 ]]; then
    _ssh__key__replace-pair "${temporary}" "${output}" || status="$?"
  fi
  rm -rf -- "${temporary}"
  [[ "${status}" -eq 0 ]] || return "${status}"
  cat -- "${output}.pub"
}

# @description Move a new key pair from a directory over an existing pair, restoring the old pair on failure.
#
# The old files are moved into the directory first, so the private and public
# keys are either both new or both old when the function returns.
#
# @internal
_ssh__key__replace-pair() {
  [[ "$#" -eq 2 && -f "$1/key" && -f "$1/key.pub" ]] || return 64
  local directory="$1" output="$2" suffix=''
  for suffix in '' .pub; do
    if [[ -e "${output}${suffix}" || -L "${output}${suffix}" ]]; then
      if ! mv -f -- "${output}${suffix}" "${directory}/old${suffix}"; then
        _ssh__key__restore-pair "${directory}" "${output}"
        return 74
      fi
    fi
  done
  if mv -f -- "${directory}/key" "${output}" &&
    mv -f -- "${directory}/key.pub" "${output}.pub"; then
    return 0
  fi
  rm -f -- "${output}" "${output}.pub"
  _ssh__key__restore-pair "${directory}" "${output}"
  return 74
}

# @description Move the old key pair saved by _ssh__key__replace-pair back into place.
# @internal
_ssh__key__restore-pair() {
  [[ "$#" -eq 2 ]] || return 64
  local suffix=''
  for suffix in '' .pub; do
    if [[ -e "$1/old${suffix}" || -L "$1/old${suffix}" ]]; then
      mv -f -- "$1/old${suffix}" "$2${suffix}" || return 74
    fi
  done
}

# @description Generate an Ed25519 SSH key and write its public key.
#
# An existing key is replaced only after confirmation on the controlling
# terminal; without a terminal it is kept and 73 is returned. The old key
# stays in place until the new key has been generated.
#
# @option --comment <COMMENT> Key comment. Defaults to an empty comment.
# @option --output <FILE> Private key path. Defaults to $HOME/.ssh/id_ed25519.
# @option --passphrase-fd <FD> File descriptor to read the passphrase from. Defaults to no passphrase.
# @stdout The public key.
# @exitcode 0 The key was generated.
# @exitcode 64 An option is unknown or has an invalid value.
# @exitcode 66 The passphrase could not be read.
# @exitcode 69 ssh-keygen is unavailable.
# @exitcode 73 The key exists and was kept.
# @exitcode 74 The directory or the temporary key could not be created, or the new key could not replace the old one.
# @exitcode other The status of ssh-keygen.
# @example
#   ssh__key__generate-ed25519 --comment "$(id -un)@$(hostname)" --passphrase-fd 3 3<passphrase.txt
ssh__key__generate-ed25519() {
  _ssh__key__generate ed25519 id_ed25519 "$@"
}

# @description List the named arguments of ssh__key__generate-ed25519.
# @internal
_ssh__key__generate-ed25519-args() {
  if [[ -z "${1-}" ]]; then printf '%s\n' --comment --output --passphrase-fd; fi
}

# @description End every SSH process of the current user.
#
# @noargs
# @exitcode 0 At least one SSH process was signaled.
# @exitcode 1 No SSH process was running.
# @exitcode 64 An argument was given.
# @exitcode 69 pkill is unavailable.
# @example
#   ssh__kill-all
ssh__kill-all() {
  [[ "$#" -eq 0 ]] || return 64
  command -v pkill >/dev/null 2>&1 || return 69
  pkill -u "$(id -un)" ssh
}

# @description Write the OpenSSH server package and service names for the current platform.
# @internal
_ssh__server__names() {
  [[ "$#" -eq 0 ]] || return 64
  local platform=''
  platform="$(_package__platform)" || return "$?"
  case "${platform}" in
    ubuntu) printf 'openssh-server ssh\n' ;;
    fedora) printf 'openssh-server sshd\n' ;;
    *)
      _console__write-error 'Install the OpenSSH server on Ubuntu or Fedora.'
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
#   ssh__server__versions
ssh__server__versions() {
  [[ "$#" -eq 0 ]] || return 64
  local server_names=''
  server_names="$(_ssh__server__names)" || return "$?"
  _package__versions "${server_names%% *}"
}

# @description Install the OpenSSH server, enable it at boot, and start it.
#
# @arg $1 string Optional version from ssh__server__versions. Defaults to the newest one.
# @exitcode 0 The server is installed, enabled at boot, and running.
# @exitcode 64 The argument count is wrong.
# @exitcode 69 The platform is unsupported, or the version is unavailable.
# @exitcode other The status of the package manager or systemctl.
# @example
#   ssh__server__install
ssh__server__install() {
  [[ "$#" -le 1 ]] || return 64
  local server_names=''
  server_names="$(_ssh__server__names)" || return "$?"
  _package__install-version "${server_names%% *}" "${1:-}" || return "$?"
  _package__enable-service "${server_names#* }"
}
