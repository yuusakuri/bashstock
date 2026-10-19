#!/usr/bin/env bats

load test_helper

@test "IMDS functions use one token and validate public paths" {
  aws::_imds-token() {
    printf 'token\n'
  }
  aws::_imds-get() {
    [ "$2" = 'token' ]
    case "$1" in
      instance-id)
        printf 'i-123\n'
        ;;
      placement/availability-zone)
        printf 'ap-northeast-1a\n'
        ;;
      local-ipv4)
        printf '10.0.0.10\n'
        ;;
      *)
        return 1
        ;;
    esac
  }

  aws::is-ec2-instance
  run aws::instance-id
  [ "${output}" = 'i-123' ]
  run aws::instance-availability-zone
  [ "${output}" = 'ap-northeast-1a' ]
  run aws::instance-private-ip
  [ "${output}" = '10.0.0.10' ]

  run aws::instance-metadata '../secret'
  [ "${status}" -eq 64 ]
  run aws::instance-metadata '/instance-id'
  [ "${status}" -eq 64 ]
}

@test "instance region parses the identity document" {
  aws::_imds-token() {
    printf 'token\n'
  }
  aws::_imds-document() {
    [ "$1" = 'token' ]
    printf '{"region":"ap-northeast-1"}\n'
  }

  run aws::instance-region
  [ "${status}" -eq 0 ]
  [ "${output}" = 'ap-northeast-1' ]
}

@test "EC2 tag functions keep user values outside the query expression" {
  aws::_cli() {
    [ "$1" = 'ec2' ]
    [ "$2" = 'describe-tags' ]
    printf '{"Tags":[{"Key":"Role","Value":"web"},{"Key":"Empty","Value":""}]}\n'
  }

  run aws::instance-tags 'i-123' 'ap-northeast-1'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'"Role"'* ]]

  run aws::instance-tag 'i-123' 'ap-northeast-1' Role
  [ "${status}" -eq 0 ]
  [ "${output}" = 'web' ]

  run aws::instance-tag 'i-123' 'ap-northeast-1' Missing
  [ "${status}" -eq 1 ]
}

@test "tag waiting returns an immediately available value" {
  aws::instance-tag() {
    printf 'ready\n'
  }
  time::boot-time-milliseconds() {
    printf '1\n'
  }

  run aws::wait-for-instance-tag 'i-123' 'ap-northeast-1' Role 10 1
  [ "${status}" -eq 0 ]
  [ "${output}" = 'ready' ]
}

@test "tag waiting uses boot time for its timeout" {
  local clock_marker="${BATS_TEST_TMPDIR}/clock-called"

  aws::instance-tag() {
    return 1
  }
  time::boot-time-milliseconds() {
    if [[ -e "${clock_marker}" ]]; then
      printf '1000\n'
    else
      : >"${clock_marker}"
      printf '0\n'
    fi
  }
  sleep() {
    :
  }

  run aws::wait-for-instance-tag 'i-123' 'ap-northeast-1' Role 1 1
  [ "${status}" -eq 75 ]
}

@test "tag waiting rejects a non-integer clock value" {
  local injection_marker="${BATS_TEST_TMPDIR}/clock-injection"

  time::boot-time-milliseconds() {
    printf '0+$(touch %s)\n' "${injection_marker}"
  }

  run aws::wait-for-instance-tag 'i-123' 'ap-northeast-1' Role 1 1
  [ "${status}" -eq 69 ]
  [ ! -e "${injection_marker}" ]
}

@test "instance search passes fixed state filters to AWS CLI" {
  aws::_cli() {
    printf '%s\n' "$*"
  }

  run aws::instances-with-tag Role web ap-northeast-1
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'Name=tag:Role,Values=web'* ]]
  [[ "${output}" == *'Name=instance-state-name,Values=pending,running'* ]]
}

@test "Auto Scaling functions parse group data" {
  aws::_cli() {
    if [[ "$1 $2" = 'autoscaling describe-auto-scaling-groups' ]]; then
      printf '{"AutoScalingGroupName":"group","DesiredCapacity":2,"Instances":[{"InstanceId":"i-1"},{"InstanceId":"i-2"}]}\n'
    else
      printf '{"Reservations":[{"Instances":[{"InstanceId":"i-1"}]}]}\n'
    fi
  }

  run aws::auto-scaling-group group ap-northeast-1
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'"AutoScalingGroupName":"group"'* ]]

  run aws::auto-scaling-group-size group ap-northeast-1
  [ "${status}" -eq 0 ]
  [ "${output}" = '2' ]

  run aws::instances-in-auto-scaling-group group ap-northeast-1
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'"Reservations"'* ]]
}

@test "the current instance resolves its Auto Scaling group name" {
  aws::instance-id() {
    printf 'i-123\n'
  }
  aws::instance-region() {
    printf 'ap-northeast-1\n'
  }
  aws::wait-for-instance-tag() {
    [ "$1" = 'i-123' ]
    [ "$2" = 'ap-northeast-1' ]
    [ "$3" = 'aws:autoscaling:groupName' ]
    printf 'group\n'
  }

  run aws::auto-scaling-group-name 10 1
  [ "${status}" -eq 0 ]
  [ "${output}" = 'group' ]
}

@test "AWS functions reject incomplete arguments" {
  run aws::instance-tags i-123
  [ "${status}" -eq 64 ]
  run aws::wait-for-instance-tag i-123 region key 0 1
  [ "${status}" -eq 64 ]
  run aws::wait-for-instance-tag i-123 region key 999999999999999999999 1
  [ "${status}" -eq 64 ]
  run aws::auto-scaling-group group
  [ "${status}" -eq 64 ]
}
