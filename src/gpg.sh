#!/usr/bin/env bash
# @file gpg
# @brief GPG keys.
# @description Keys are generated, listed, exported, and removed with gpg.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Decrypt a GPG file to standard output without adding a newline.
#
# @arg $1 string Encrypted file.
# @stdout The decrypted content.
# @exitcode 0 The file was decrypted.
# @exitcode 64 The argument is not one existing file.
# @exitcode 69 gpg is unavailable.
# @exitcode other The status of gpg.
# @example
#   gpg::decrypt secrets.env.gpg > .env
gpg::decrypt() { [[ "$#" -eq 1 && -f "$1" ]] || return 64; docker::_run-command gpg --decrypt "$1"; }

# @description Write a public GPG key in ASCII armor.
#
# @arg $1 string Optional key fingerprint. Defaults to the first secret key.
# @stdout The ASCII-armored public key.
# @exitcode 0 The key was written.
# @exitcode 1 No fingerprint was given and no secret key exists.
# @exitcode 64 More than one argument was given.
# @exitcode 69 gpg is unavailable.
# @exitcode other The status of gpg.
# @example
#   gpg::public-key::armor > public.asc
gpg::public-key::armor() {
  [[ "$#" -le 1 ]] || return 64
  local fingerprint="${1:-}" fingerprints=''
  command::require gpg || return "$?"
  if [[ -z "${fingerprint}" ]]; then
    fingerprints="$(gpg::secret-key::fingerprints)" || return "$?"
    fingerprint="${fingerprints%%$'\n'*}"
  fi
  gpg --armor --export -- "${fingerprint}"
}

# @description Write the fingerprints of every primary secret GPG key, one per line.
#
# @noargs
# @stdout One fingerprint per line.
# @exitcode 0 The fingerprints were written.
# @exitcode 1 No secret key exists.
# @exitcode 64 An argument was given.
# @exitcode 69 gpg is unavailable.
# @example
#   gpg::secret-key::fingerprints
gpg::secret-key::fingerprints() {
  [[ "$#" -eq 0 ]] || return 64
  command::require gpg || return "$?"
  local listing='' fingerprints=''
  listing="$(gpg --batch --list-secret-keys --with-colons 2>/dev/null)" || return 1
  # Each sec record is followed by the fpr record of the primary key.
  fingerprints="$(printf '%s\n' "${listing}" | awk -F: '$1 == "sec" {primary = 1; next} $1 == "fpr" && primary {print $10; primary = 0}')"
  [[ -n "${fingerprints}" ]] || return 1
  printf '%s\n' "${fingerprints}"
}

# @description Write the secret GPG keys in the human-readable GPG format.
#
# @noargs
# @stdout The output of gpg --list-secret-keys.
# @exitcode 0 The keys were written.
# @exitcode 64 An argument was given.
# @exitcode 69 gpg is unavailable.
# @exitcode other The status of gpg.
# @example
#   gpg::secret-key::list
gpg::secret-key::list() { [[ "$#" -eq 0 ]] || return 64; docker::_run-command gpg --list-secret-keys; }

# @description Create a GPG key and use it for pass, Git credentials, and Git commit signing.
#
# The options are passed to gpg::key::generate. pass is installed and its
# store initialized with the new key, Git Credential Manager stores
# credentials with GPG, Git signs commits with the key, and the public key is
# written in ASCII armor. The first failing step stops the setup.
#
# @arg $@ string Options of gpg::key::generate, such as --user-id and --passphrase-fd.
# @stdout The ASCII-armored public key of the new key.
# @exitcode 0 Every step finished.
# @exitcode 74 The new key could not be identified.
# @exitcode other The status of the step that failed.
# @example
#   gpg::setup --user-id 'Alex Example <developer@example.com>' --passphrase-fd 3 3<passphrase.txt
gpg::setup() {
  local before='' after='' fingerprint='' candidate=''
  before="$(gpg::secret-key::fingerprints 2>/dev/null)" || before=''
  gpg::key::generate "$@" || return "$?"
  after="$(gpg::secret-key::fingerprints)" || return "$?"
  while IFS= read -r candidate; do
    grep -Fqx -- "${candidate}" <<<"${before}" || fingerprint="${candidate}"
  done <<<"${after}"
  [[ -n "${fingerprint}" ]] || return 74
  pass::install || return "$?"
  pass::store::init "${fingerprint}" || return "$?"
  git::config::use-gpg-credential-store || return "$?"
  git config --global user.signingkey "${fingerprint}" || return "$?"
  git config --global commit.gpgsign true || return "$?"
  gpg::public-key::armor "${fingerprint}"
}

# @description List the named arguments and value candidates for gpg::key::generate.
# @internal
gpg::key::_generate-args() {
  case "${1-}" in
    --usage)
      printf '%s\n' sign cert auth sign,auth
      ;;
    --algorithm)
      printf '%s\n' ed25519 rsa3072 rsa4096
      ;;
    '')
      printf '%s\n' --usage --algorithm --expires --user-id --pinentry --passphrase-fd
      ;;
  esac
}

# @description Generate a GPG primary key and an encryption subkey in one operation.
#
# @option --usage <USAGE> Primary key usage: sign, cert, auth, or a comma-separated combination. Defaults to sign.
# @option --algorithm <ALGORITHM> ed25519, rsa3072, or rsa4096. Defaults to ed25519, which pairs an Ed25519 primary key with a Curve25519 encryption subkey.
# @option --expires <EXPIRES> GnuPG expiration such as 5y, 12m, or 0. Defaults to 5y.
# @option --user-id <USER_ID> "Name <email>". Defaults to the Git user name and email.
# @option --pinentry Ask for the passphrase through pinentry.
# @option --passphrase-fd <FD> Read the passphrase from a file descriptor.
# @exitcode 0 The key was generated.
# @exitcode 64 An option is unknown or invalid, or no user ID is available.
# @exitcode 69 gpg is unavailable.
# @exitcode 74 The parameter file could not be written.
# @exitcode other The status of gpg.
# @example
#   gpg::key::generate --user-id 'Alex Example <developer@example.com>' --pinentry
#   gpg::key::generate --algorithm rsa4096 --expires 2y --passphrase-fd 3 3<passphrase.txt
gpg::key::generate() {
  local usage='sign' algorithm='ed25519' expires='5y' user_id='' pinentry='false' passphrase_fd=''
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --usage | --algorithm | --expires | --user-id | --passphrase-fd)
        arg::require-next "$#" "$1" || return "$?"
        case "$1" in
          --usage) usage="$2" ;;
          --algorithm) algorithm="$2" ;;
          --expires) expires="$2" ;;
          --user-id) user_id="$2" ;;
          --passphrase-fd) passphrase_fd="$2" ;;
        esac
        shift 2
        ;;
      --pinentry)
        pinentry='true'
        shift
        ;;
      *)
        arg::unknown "$1" || return "$?"
        ;;
    esac
  done
  ( [[ "${usage}" =~ ^(sign|cert|auth)(,(sign|cert|auth))*$ ]] ) || return 64
  arg::one-of --algorithm "${algorithm}" ed25519 rsa3072 rsa4096 || return "$?"
  ( [[ "${expires}" =~ ^(0|[1-9][0-9]*[dwmy]?)$ ]] ) || return 64
  ( [[ -z "${passphrase_fd}" || "${passphrase_fd}" =~ ^[0-9]+$ ]] ) || return 64
  [[ "${pinentry}" == 'false' || -z "${passphrase_fd}" ]] || return 64
  command::require gpg || return "$?"
  if [[ -z "${user_id}" ]]; then
    local name='' email=''
    name="$(git config --get user.name 2>/dev/null)"
    email="$(git config --get user.email 2>/dev/null)"
    [[ -n "${name}" && -n "${email}" ]] || return 64
    user_id="${name} <${email}>"
  fi
  # A control character such as a newline would add a directive, for example
  # %no-protection, to the GnuPG parameter file.
  [[ "${user_id}" != *[[:cntrl:]]* ]] || return 64
  local user_id_pattern='^([^<>]+) <([^<>@[:space:]]+@[^<>[:space:]]+)>$'
  ( [[ "${user_id}" =~ ${user_id_pattern} ]] ) || return 64
  # The name and the address hold no < or >, so the first " <" separates them.
  local real_name="${user_id%% <*}" email_address="${user_id#* <}" parameters='' directory='' status=0
  email_address="${email_address%>}"
  case "${algorithm}" in
    ed25519)
      parameters="Key-Type: eddsa"$'\n'"Key-Curve: ed25519"$'\n'
      parameters+="Subkey-Type: ecdh"$'\n'"Subkey-Curve: cv25519"$'\n'
      ;;
    rsa*)
      parameters="Key-Type: RSA"$'\n'"Key-Length: ${algorithm#rsa}"$'\n'
      parameters+="Subkey-Type: RSA"$'\n'"Subkey-Length: ${algorithm#rsa}"$'\n'
      ;;
  esac
  parameters+="Key-Usage: ${usage//,/ }"$'\n'"Subkey-Usage: encrypt"$'\n'
  parameters+="Name-Real: ${real_name}"$'\n'"Name-Email: ${email_address}"$'\n'
  parameters+="Expire-Date: ${expires}"$'\n'
  [[ "${pinentry}" == 'true' || -n "${passphrase_fd}" ]] || parameters+='%no-protection'$'\n'
  parameters+='%commit'$'\n'
  directory="$(package::_temporary-directory)" || return "$?"
  chmod 0700 "${directory}" || status=74
  if [[ "${status}" -eq 0 ]]; then
    (umask 077 && printf '%s' "${parameters}" >"${directory}/parameters") || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    if [[ -n "${passphrase_fd}" ]]; then
      gpg --batch --pinentry-mode loopback --passphrase-fd "${passphrase_fd}" \
        --generate-key "${directory}/parameters" || status="$?"
    elif [[ "${pinentry}" == 'true' ]]; then
      gpg --generate-key "${directory}/parameters" || status="$?"
    else
      gpg --batch --generate-key "${directory}/parameters" || status="$?"
    fi
  fi
  rm -rf -- "${directory}"
  return "${status}"
}
