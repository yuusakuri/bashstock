#!/usr/bin/env bash

if ! declare -F aws::__require-value >/dev/null 2>&1; then
  source "${BASHSTOCK_ROOT}/src/aws/aws.sh"
fi
if ! declare -F aws::instance-id >/dev/null 2>&1; then
  source "${BASHSTOCK_ROOT}/src/aws/imds.sh"
fi
if ! declare -F aws::instance-tag >/dev/null 2>&1; then
  source "${BASHSTOCK_ROOT}/src/aws/ec2.sh"
fi

### Write the Auto Scaling group that contains an EC2 instance.
aws::auto-scaling-group() {
  if [[ "$#" -ne 2 ]] || ! aws::__require-value "$1" || ! aws::__require-value "$2"; then
    return 64
  fi

  local result=''
  result="$(
    aws::__cli autoscaling describe-auto-scaling-groups \
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

### Write running or pending instances in an Auto Scaling group.
aws::instances-in-auto-scaling-group() {
  if [[ "$#" -ne 2 ]] || ! aws::__require-value "$1" || ! aws::__require-value "$2"; then
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

  aws::__cli ec2 describe-instances \
    --instance-ids "${ids[@]}" \
    --filters 'Name=instance-state-name,Values=pending,running' \
    --region "$2" --output json
}

### Write the current instance's Auto Scaling group name.
aws::auto-scaling-group-name() {
  if [[ "$#" -ne 2 ]] ||
    ! number::__is-positive-integer-at-most "$1" 2147483647 ||
    ! number::__is-positive-integer-at-most "$2" 2147483647; then
    return 64
  fi

  local instance_id=''
  local region=''
  instance_id="$(aws::instance-id)" || return "$?"
  region="$(aws::instance-region)" || return "$?"
  aws::wait-for-instance-tag \
    "${instance_id}" "${region}" 'aws:autoscaling:groupName' "$1" "$2"
}

### Write the desired capacity of an Auto Scaling group.
aws::auto-scaling-group-size() {
  if [[ "$#" -ne 2 ]] || ! aws::__require-value "$1" || ! aws::__require-value "$2"; then
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
