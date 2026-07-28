#!/usr/bin/env bash

if ! declare -F aws::__require-value >/dev/null 2>&1; then
  source "${BASHSTOCK_ROOT}/src/aws/aws.sh"
fi

aws::instance-tags() {
  if [[ "$#" -ne 2 ]] || ! aws::__require-value "$1" || ! aws::__require-value "$2"; then
    return 64
  fi
  aws::__cli ec2 describe-tags \
    --filters "Name=resource-id,Values=$1" \
    --region "$2" --output json
}

aws::instance-tag() {
  if [[ "$#" -ne 3 ]] ||
    ! aws::__require-value "$1" ||
    ! aws::__require-value "$2" ||
    ! aws::__require-value "$3"; then
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

aws::wait-for-instance-tag() {
  if [[ "$#" -ne 5 ]] ||
    ! aws::__require-value "$1" ||
    ! aws::__require-value "$2" ||
    ! aws::__require-value "$3" ||
    ! core::__is-safe-positive-integer "$4" 2147483647 ||
    ! core::__is-safe-positive-integer "$5" 2147483647; then
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

  start="$(time::boottime-milliseconds)" || return "$?"
  core::__is-safe-non-negative-integer "${start}" 9223372036854775807 || return 69
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

    current="$(time::boottime-milliseconds)" || return "$?"
    core::__is-safe-non-negative-integer "${current}" 9223372036854775807 || return 69
    if ((current - start >= timeout_milliseconds)); then
      return 75
    fi
    sleep "${interval_seconds}" || return 75
  done
}

aws::instances-with-tag() {
  if [[ "$#" -ne 3 ]] ||
    ! aws::__require-value "$1" ||
    ! aws::__require-value "$2" ||
    ! aws::__require-value "$3"; then
    return 64
  fi

  aws::__cli ec2 describe-instances \
    --filters "Name=tag:$1,Values=$2" \
    'Name=instance-state-name,Values=pending,running' \
    --region "$3" --output json
}
