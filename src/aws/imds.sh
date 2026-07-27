#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120

if ! declare -F aws::__require-value >/dev/null 2>&1; then
  source "${MODERN_BASH_CLI_ROOT}/src/aws/aws.sh"
fi

aws::__imds-token() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  command -v curl >/dev/null 2>&1 || return 69

  local token=''
  token="$(
    curl --silent --show-error --fail --noproxy '*' \
      --connect-timeout 1 --max-time 2 \
      --request PUT \
      --header 'X-aws-ec2-metadata-token-ttl-seconds: 60' \
      'http://169.254.169.254/latest/api/token' 2>/dev/null
  )" || return 75
  if [[ -z "${token}" || "${token}" == *[[:cntrl:]]* ]]; then
    return 75
  fi
  printf '%s\n' "${token}"
}

aws::__imds-get() {
  if [[ "$#" -ne 2 ]]; then
    return 64
  fi
  command -v curl >/dev/null 2>&1 || return 69
  command -v mktemp >/dev/null 2>&1 || return 69

  local path="$1"
  local token="$2"
  local output=''
  local status=''
  local http_status=''
  output="$(mktemp "${TMPDIR:-/tmp}/modern-bash-cli-imds.XXXXXX")" || return 74
  if [[ -z "${token}" || "${token}" == *[[:cntrl:]]* ]]; then
    rm -f -- "${output}"
    return 75
  fi

  if http_status="$(
    curl --silent --show-error --noproxy '*' \
      --connect-timeout 1 --max-time 2 \
      --output "${output}" --write-out '%{http_code}' \
      --header "X-aws-ec2-metadata-token: ${token}" \
      "http://169.254.169.254/latest/meta-data/${path}" 2>/dev/null
  )"; then
    :
  else
    status="$?"
    rm -f -- "${output}"
    [[ "${status}" -eq 127 ]] && return 69
    return 75
  fi

  case "${http_status}" in
    200)
      cat "${output}"
      status='0'
      ;;
    404)
      status='1'
      ;;
    *)
      status='75'
      ;;
  esac
  rm -f -- "${output}"
  return "${status}"
}

aws::__imds-document() {
  if [[ "$#" -ne 1 ]]; then
    return 64
  fi
  command -v curl >/dev/null 2>&1 || return 69
  if [[ -z "$1" || "$1" == *[[:cntrl:]]* ]]; then
    return 75
  fi

  curl --silent --show-error --fail --noproxy '*' \
    --connect-timeout 1 --max-time 2 \
    --header "X-aws-ec2-metadata-token: $1" \
    'http://169.254.169.254/latest/dynamic/instance-identity/document' 2>/dev/null ||
    return 75
}

aws::is-ec2-instance() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  aws::__imds-token >/dev/null 2>&1 || return 1
}

aws::instance-metadata() {
  if [[ "$#" -ne 1 || -z "$1" || "$1" == /* || "$1" == */ ||
    "$1" == *'//'* || "$1" == *'?'* || "$1" == *'#'* ||
    "$1" == *[[:cntrl:]]* ]]; then
    return 64
  fi

  local remaining="$1"
  local part=''
  local token=''
  while :; do
    if [[ "${remaining}" == */* ]]; then
      part="${remaining%%/*}"
      remaining="${remaining#*/}"
    else
      part="${remaining}"
      remaining=''
    fi
    if [[ "${part}" == '.' || "${part}" == '..' || -z "${part}" ]]; then
      return 64
    fi
    [[ -z "${remaining}" ]] && break
  done

  token="$(aws::__imds-token)" || return "$?"
  aws::__imds-get "$1" "${token}"
}

aws::instance-id() {
  [[ "$#" -eq 0 ]] || return 64
  aws::instance-metadata instance-id
}

aws::instance-region() {
  [[ "$#" -eq 0 ]] || return 64

  local token=''
  local document=''
  token="$(aws::__imds-token)" || return "$?"
  document="$(aws::__imds-document "${token}")" || return "$?"
  command -v perl >/dev/null 2>&1 || return 69
  printf '%s' "${document}" |
    perl -MJSON::PP -0777 -e '
      my $data = eval { decode_json(<STDIN>) };
      exit 75 if $@ || ref($data) ne "HASH";
      my $value = $data->{region};
      exit 75 unless defined $value && !ref($value) && length($value);
      print $value, "\n";
    ' 2>/dev/null
}

aws::instance-availability-zone() {
  [[ "$#" -eq 0 ]] || return 64
  aws::instance-metadata placement/availability-zone
}

aws::instance-private-ip() {
  [[ "$#" -eq 0 ]] || return 64
  aws::instance-metadata local-ipv4
}
