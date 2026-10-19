#!/usr/bin/env bash
# @file aws
# @brief Amazon EC2 instance metadata.
# @description The functions read the instance metadata service with IMDSv2 tokens.

# shellcheck disable=SC2119,SC2120

# @description Require one non-empty, single-line AWS argument.
# @internal
aws::_require-value() {
  if [[ "$#" -ne 1 || -z "$1" ]] || ! string::_require-one-line "$1"; then
    return 64
  fi
}

# @description Run the AWS CLI and normalize authentication and service failures.
# @internal
aws::_cli() {
  if [[ "$#" -lt 1 ]]; then
    return 64
  fi
  command -v aws >/dev/null 2>&1 || return 69
  command -v mktemp >/dev/null 2>&1 || return 69

  local output=''
  local error=''
  local status=''
  output="$(mktemp "${TMPDIR:-/tmp}/bashstock-aws-output.XXXXXX")" || return 74
  error="$(mktemp "${TMPDIR:-/tmp}/bashstock-aws-error.XXXXXX")" || {
    rm -f -- "${output}"
    return 74
  }

  if command aws "$@" >"${output}" 2>"${error}"; then
    cat "${output}"
    rm -f -- "${output}" "${error}"
    return 0
  else
    status="$?"
  fi

  if grep -Eiq \
    'AccessDenied|Unauthorized|ExpiredToken|InvalidClientTokenId|Unable to locate credentials|NoCredentialProviders' \
    "${error}"; then
    status='77'
  else
    status='75'
  fi
  rm -f -- "${output}" "${error}"
  return "${status}"
}

# @description Request one IMDSv2 session token.
# @internal
aws::_imds-token() {
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

# @description Read one metadata path with an IMDSv2 token.
# @internal
aws::_imds-get() {
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
  output="$(mktemp "${TMPDIR:-/tmp}/bashstock-imds.XXXXXX")" || return 74
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

# @description Read the EC2 instance identity document with an IMDSv2 token.
# @internal
aws::_imds-document() {
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

# @description Test whether IMDSv2 is available for the current instance.
#
# A token request to the instance metadata service decides it, with a
# two-second limit, so the test is fast outside EC2.
#
# @noargs
# @exitcode 0 The process runs on an EC2 instance with IMDSv2.
# @exitcode 1 The metadata service did not answer.
# @exitcode 64 An argument was given.
# @example
#   aws::is-ec2-instance && region="$(aws::instance-region)"
aws::is-ec2-instance() {
  if [[ "$#" -ne 0 ]]; then
    return 64
  fi
  aws::_imds-token >/dev/null 2>&1 || return 1
}

# @description Write one validated EC2 instance metadata value.
#
# @arg $1 string Relative metadata path below latest/meta-data, such as placement/region.
# @stdout The metadata value.
# @exitcode 0 The value was written.
# @exitcode 64 The path is absolute, has empty, . or .. components, or contains ?, #, or control characters.
# @exitcode 69 curl is unavailable.
# @exitcode 75 The metadata service did not answer or returned an invalid value.
# @example
#   aws::instance-metadata placement/availability-zone
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

  token="$(aws::_imds-token)" || return "$?"
  aws::_imds-get "$1" "${token}"
}

# @description Write the current EC2 instance identifier.
#
# @noargs
# @stdout An instance ID such as i-0123456789abcdef0.
# @exitcode 0 The ID was written.
# @exitcode 64 An argument was given.
# @exitcode 69 curl is unavailable.
# @exitcode 75 The metadata service did not answer.
# @example
#   instance_id="$(aws::instance-id)"
aws::instance-id() {
  [[ "$#" -eq 0 ]] || return 64
  aws::instance-metadata instance-id
}

# @description Write the current EC2 instance region.
#
# The region is read from the instance identity document.
#
# @noargs
# @stdout A region such as ap-northeast-1.
# @exitcode 0 The region was written.
# @exitcode 64 An argument was given.
# @exitcode 69 curl or Perl is unavailable.
# @exitcode 75 The metadata service did not answer or the document is invalid.
# @example
#   aws::instance-tags "$(aws::instance-id)" "$(aws::instance-region)"
aws::instance-region() {
  [[ "$#" -eq 0 ]] || return 64

  local token=''
  local document=''
  token="$(aws::_imds-token)" || return "$?"
  document="$(aws::_imds-document "${token}")" || return "$?"
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

# @description Write the current EC2 instance availability zone.
#
# @noargs
# @stdout An availability zone such as ap-northeast-1a.
# @exitcode 0 The zone was written.
# @exitcode 64 An argument was given.
# @exitcode 69 curl is unavailable.
# @exitcode 75 The metadata service did not answer.
# @example
#   aws::instance-availability-zone
aws::instance-availability-zone() {
  [[ "$#" -eq 0 ]] || return 64
  aws::instance-metadata placement/availability-zone
}

# @description Write the current EC2 instance private IPv4 address.
#
# @noargs
# @stdout The private IPv4 address.
# @exitcode 0 The address was written.
# @exitcode 64 An argument was given.
# @exitcode 69 curl is unavailable.
# @exitcode 75 The metadata service did not answer.
# @example
#   printf 'listen %s:8080\n' "$(aws::instance-private-ip)"
aws::instance-private-ip() {
  [[ "$#" -eq 0 ]] || return 64
  aws::instance-metadata local-ipv4
}

# @description Write all tags for one EC2 instance.
#
# @arg $1 string Instance ID.
# @arg $2 string Region of the instance.
# @stdout The describe-tags response as JSON.
# @exitcode 0 The tags were written.
# @exitcode 64 An argument is empty or contains a newline.
# @exitcode 69 The AWS CLI is unavailable.
# @exitcode 75 The AWS CLI failed for a reason other than credentials.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::instance-tags i-0123456789abcdef0 ap-northeast-1
aws::instance-tags() {
  if [[ "$#" -ne 2 ]] || ! aws::_require-value "$1" || ! aws::_require-value "$2"; then
    return 64
  fi
  aws::_cli ec2 describe-tags \
    --filters "Name=resource-id,Values=$1" \
    --region "$2" --output json
}

# @description Write one EC2 instance tag value.
#
# @arg $1 string Instance ID.
# @arg $2 string Region of the instance.
# @arg $3 string Tag key.
# @stdout The tag value.
# @exitcode 0 The value was written.
# @exitcode 1 The instance has no tag with that key.
# @exitcode 64 An argument is empty or contains a newline.
# @exitcode 69 The AWS CLI or Perl is unavailable.
# @exitcode 75 The AWS CLI failed or returned invalid JSON.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::instance-tag i-0123456789abcdef0 ap-northeast-1 Name
aws::instance-tag() {
  if [[ "$#" -ne 3 ]] ||
    ! aws::_require-value "$1" ||
    ! aws::_require-value "$2" ||
    ! aws::_require-value "$3"; then
    return 64
  fi

  local tags=''
  command -v perl >/dev/null 2>&1 || return 69
  tags="$(aws::instance-tags "$1" "$2")" || return "$?"
  printf '%s' "${tags}" |
    perl -MJSON::PP -0777 -e '
      my $key = shift;
      my $data = eval { decode_json(<STDIN>) };
      exit 75 if $@ || ref($data) ne "HASH" || ref($data->{Tags}) ne "ARRAY";
      for my $tag (@{$data->{Tags}}) {
        next unless ref($tag) eq "HASH";
        if (defined($tag->{Key}) && $tag->{Key} eq $key) {
          exit 75 if !defined($tag->{Value}) || ref($tag->{Value});
          print $tag->{Value}, "\n";
          exit 0;
        }
      }
      exit 1;
    ' -- "$3" 2>/dev/null
}

# @description Wait for one EC2 instance tag to become available.
#
# Tags are applied shortly after an instance starts, so the tag is polled
# until it appears or the timeout passes.
#
# @arg $1 string Instance ID.
# @arg $2 string Region of the instance.
# @arg $3 string Tag key.
# @arg $4 integer Timeout in seconds.
# @arg $5 integer Seconds between attempts.
# @stdout The tag value.
# @exitcode 0 The value was written.
# @exitcode 64 An argument is invalid.
# @exitcode 69 The AWS CLI, Perl, or the clock provider is unavailable.
# @exitcode 75 The tag did not appear before the timeout, or the AWS CLI failed.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::wait-for-instance-tag "$(aws::instance-id)" "$(aws::instance-region)" Role 120 5
aws::wait-for-instance-tag() {
  if [[ "$#" -ne 5 ]] ||
    ! aws::_require-value "$1" ||
    ! aws::_require-value "$2" ||
    ! aws::_require-value "$3" ||
    ! number::_is-positive-integer-at-most "$4" 2147483647 ||
    ! number::_is-positive-integer-at-most "$5" 2147483647; then
    return 64
  fi

  local instance_id="$1"
  local region="$2"
  local key="$3"
  local timeout_milliseconds="$(($4 * 1000))"
  local interval_seconds="$5"
  local start=''
  local current=''
  local value=''
  local status=''

  start="$(time::boot-time-milliseconds)" || return "$?"
  number::_is-non-negative-integer-at-most "${start}" 9223372036854775807 ||
    return 69
  while :; do
    if value="$(aws::instance-tag "${instance_id}" "${region}" "${key}")"; then
      printf '%s\n' "${value}"
      return 0
    else
      status="$?"
    fi
    if [[ "${status}" -ne 1 ]]; then
      return "${status}"
    fi

    current="$(time::boot-time-milliseconds)" || return "$?"
    number::_is-non-negative-integer-at-most "${current}" 9223372036854775807 ||
      return 69
    if ((current - start >= timeout_milliseconds)); then
      return 75
    fi
    sleep "${interval_seconds}" || return 75
  done
}

# @description Write EC2 instances that have a requested tag.
#
# Only pending and running instances are included.
#
# @arg $1 string Tag key.
# @arg $2 string Tag value.
# @arg $3 string Region.
# @stdout The describe-instances response as JSON.
# @exitcode 0 The instances were written.
# @exitcode 64 An argument is empty or contains a newline.
# @exitcode 69 The AWS CLI is unavailable.
# @exitcode 75 The AWS CLI failed for a reason other than credentials.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::instances-with-tag Role web ap-northeast-1
aws::instances-with-tag() {
  if [[ "$#" -ne 3 ]] ||
    ! aws::_require-value "$1" ||
    ! aws::_require-value "$2" ||
    ! aws::_require-value "$3"; then
    return 64
  fi

  aws::_cli ec2 describe-instances \
    --filters "Name=tag:$1,Values=$2" \
    'Name=instance-state-name,Values=pending,running' \
    --region "$3" --output json
}

# @description Write the Auto Scaling group that contains an EC2 instance.
#
# @arg $1 string Auto Scaling group name.
# @arg $2 string Region.
# @stdout The group description as JSON.
# @exitcode 0 The group was written.
# @exitcode 1 No group has that name.
# @exitcode 64 An argument is empty or contains a newline.
# @exitcode 69 The AWS CLI is unavailable.
# @exitcode 75 The AWS CLI failed for a reason other than credentials.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::auto-scaling-group web-asg ap-northeast-1
aws::auto-scaling-group() {
  if [[ "$#" -ne 2 ]] || ! aws::_require-value "$1" || ! aws::_require-value "$2"; then
    return 64
  fi

  local result=''
  result="$(
    aws::_cli autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$1" \
      --region "$2" \
      --query 'AutoScalingGroups[0]' \
      --output json
  )" || return "$?"
  if [[ -z "${result}" || "${result}" == 'null' || "${result}" == 'None' ]]; then
    return 1
  fi
  printf '%s\n' "${result}"
}

# @description Write running or pending instances in an Auto Scaling group.
#
# @arg $1 string Auto Scaling group name.
# @arg $2 string Region.
# @stdout The describe-instances response as JSON; {"Reservations":[]} for an empty group.
# @exitcode 0 The instances were written.
# @exitcode 1 No group has that name.
# @exitcode 64 An argument is empty or contains a newline.
# @exitcode 69 The AWS CLI or Perl is unavailable.
# @exitcode 75 The AWS CLI failed or returned invalid JSON.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::instances-in-auto-scaling-group web-asg ap-northeast-1
aws::instances-in-auto-scaling-group() {
  if [[ "$#" -ne 2 ]] || ! aws::_require-value "$1" || ! aws::_require-value "$2"; then
    return 64
  fi

  local group=''
  local instance_ids=''
  local ids=()
  local id=''
  command -v perl >/dev/null 2>&1 || return 69
  group="$(aws::auto-scaling-group "$1" "$2")" || return "$?"
  instance_ids="$(
    printf '%s' "${group}" |
      perl -MJSON::PP -0777 -e '
        my $data = eval { decode_json(<STDIN>) };
        exit 75 if $@ || ref($data) ne "HASH";
        my $instances = $data->{Instances};
        exit 75 unless ref($instances) eq "ARRAY";
        for my $instance (@$instances) {
          next unless ref($instance) eq "HASH";
          my $id = $instance->{InstanceId};
          exit 75 unless defined($id) && !ref($id) && $id !~ /\n/;
          print $id, "\n";
        }
      ' 2>/dev/null
  )" || return "$?"

  if [[ -z "${instance_ids}" ]]; then
    printf '{"Reservations":[]}\n'
    return 0
  fi
  while IFS= read -r id; do
    ids[${#ids[@]}]="${id}"
  done <<<"${instance_ids}"

  aws::_cli ec2 describe-instances \
    --instance-ids "${ids[@]}" \
    --filters 'Name=instance-state-name,Values=pending,running' \
    --region "$2" --output json
}

# @description Write the current instance's Auto Scaling group name.
#
# The name is read from the aws:autoscaling:groupName tag of this instance,
# waiting until the tag appears.
#
# @arg $1 integer Timeout in seconds.
# @arg $2 integer Seconds between attempts.
# @stdout The Auto Scaling group name.
# @exitcode 0 The name was written.
# @exitcode 64 The timeout or interval is not a positive integer.
# @exitcode 69 curl, the AWS CLI, or Perl is unavailable.
# @exitcode 75 The metadata service did not answer, or the tag did not appear in time.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   group="$(aws::auto-scaling-group-name 300 10)"
aws::auto-scaling-group-name() {
  if [[ "$#" -ne 2 ]] ||
    ! number::_is-positive-integer-at-most "$1" 2147483647 ||
    ! number::_is-positive-integer-at-most "$2" 2147483647; then
    return 64
  fi

  local instance_id=''
  local region=''
  instance_id="$(aws::instance-id)" || return "$?"
  region="$(aws::instance-region)" || return "$?"
  aws::wait-for-instance-tag \
    "${instance_id}" "${region}" 'aws:autoscaling:groupName' "$1" "$2"
}

# @description Write the desired capacity of an Auto Scaling group.
#
# @arg $1 string Auto Scaling group name.
# @arg $2 string Region.
# @stdout The desired capacity as a number.
# @exitcode 0 The capacity was written.
# @exitcode 1 No group has that name.
# @exitcode 64 An argument is empty or contains a newline.
# @exitcode 69 The AWS CLI or Perl is unavailable.
# @exitcode 75 The AWS CLI failed or returned invalid JSON.
# @exitcode 77 The credentials were missing, expired, or not allowed.
# @example
#   aws::auto-scaling-group-size web-asg ap-northeast-1
aws::auto-scaling-group-size() {
  if [[ "$#" -ne 2 ]] || ! aws::_require-value "$1" || ! aws::_require-value "$2"; then
    return 64
  fi

  local group=''
  command -v perl >/dev/null 2>&1 || return 69
  group="$(aws::auto-scaling-group "$1" "$2")" || return "$?"
  printf '%s' "${group}" |
    perl -MJSON::PP -0777 -e '
      my $data = eval { decode_json(<STDIN>) };
      exit 75 if $@ || ref($data) ne "HASH";
      my $size = $data->{DesiredCapacity};
      exit 75 unless defined($size) && !ref($size) && $size =~ /\A[0-9]+\z/;
      print $size, "\n";
    ' 2>/dev/null
}
