# aws

Amazon EC2 instance metadata.

## Overview

The functions read the instance metadata service with IMDSv2 tokens.

## Index

* [aws::is-ec2-instance](#awsis-ec2-instance)
* [aws::instance-metadata](#awsinstance-metadata)
* [aws::instance-id](#awsinstance-id)
* [aws::instance-region](#awsinstance-region)
* [aws::instance-availability-zone](#awsinstance-availability-zone)
* [aws::instance-private-ip](#awsinstance-private-ip)
* [aws::instance-tags](#awsinstance-tags)
* [aws::instance-tag](#awsinstance-tag)
* [aws::wait-for-instance-tag](#awswait-for-instance-tag)
* [aws::instances-with-tag](#awsinstances-with-tag)
* [aws::auto-scaling-group](#awsauto-scaling-group)
* [aws::instances-in-auto-scaling-group](#awsinstances-in-auto-scaling-group)
* [aws::auto-scaling-group-name](#awsauto-scaling-group-name)
* [aws::auto-scaling-group-size](#awsauto-scaling-group-size)

### aws::is-ec2-instance

Test whether IMDSv2 is available for the current instance.

A token request to the instance metadata service decides it, with a
two-second limit, so the test is fast outside EC2.

#### Example

```bash
aws::is-ec2-instance && region="$(aws::instance-region)"
```

_Function has no arguments._

#### Exit codes

* **0**: The process runs on an EC2 instance with IMDSv2.
* **1**: The metadata service did not answer.
* **64**: An argument was given.

### aws::instance-metadata

Write one validated EC2 instance metadata value.

#### Example

```bash
aws::instance-metadata placement/availability-zone
```

#### Arguments

* **$1** (string): Relative metadata path below latest/meta-data, such as placement/region.

#### Exit codes

* **0**: The value was written.
* **64**: The path is absolute, has empty, . or .. components, or contains ?, #, or control characters.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer or returned an invalid value.

#### Output on stdout

* The metadata value.

### aws::instance-id

Write the current EC2 instance identifier.

#### Example

```bash
instance_id="$(aws::instance-id)"
```

_Function has no arguments._

#### Exit codes

* **0**: The ID was written.
* **64**: An argument was given.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer.

#### Output on stdout

* An instance ID such as i-0123456789abcdef0.

### aws::instance-region

Write the current EC2 instance region.

The region is read from the instance identity document.

#### Example

```bash
aws::instance-tags "$(aws::instance-id)" "$(aws::instance-region)"
```

_Function has no arguments._

#### Exit codes

* **0**: The region was written.
* **64**: An argument was given.
* **69**: curl or Perl is unavailable.
* **75**: The metadata service did not answer or the document is invalid.

#### Output on stdout

* A region such as ap-northeast-1.

### aws::instance-availability-zone

Write the current EC2 instance availability zone.

#### Example

```bash
aws::instance-availability-zone
```

_Function has no arguments._

#### Exit codes

* **0**: The zone was written.
* **64**: An argument was given.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer.

#### Output on stdout

* An availability zone such as ap-northeast-1a.

### aws::instance-private-ip

Write the current EC2 instance private IPv4 address.

#### Example

```bash
printf 'listen %s:8080\n' "$(aws::instance-private-ip)"
```

_Function has no arguments._

#### Exit codes

* **0**: The address was written.
* **64**: An argument was given.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer.

#### Output on stdout

* The private IPv4 address.

### aws::instance-tags

Write all tags for one EC2 instance.

#### Example

```bash
aws::instance-tags i-0123456789abcdef0 ap-northeast-1
```

#### Arguments

* **$1** (string): Instance ID.
* **$2** (string): Region of the instance.

#### Exit codes

* **0**: The tags were written.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI is unavailable.
* **75**: The AWS CLI failed for a reason other than credentials.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The describe-tags response as JSON.

### aws::instance-tag

Write one EC2 instance tag value.

#### Example

```bash
aws::instance-tag i-0123456789abcdef0 ap-northeast-1 Name
```

#### Arguments

* **$1** (string): Instance ID.
* **$2** (string): Region of the instance.
* **$3** (string): Tag key.

#### Exit codes

* **0**: The value was written.
* **1**: The instance has no tag with that key.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI or Perl is unavailable.
* **75**: The AWS CLI failed or returned invalid JSON.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The tag value.

### aws::wait-for-instance-tag

Wait for one EC2 instance tag to become available.

Tags are applied shortly after an instance starts, so the tag is polled
until it appears or the timeout passes.

#### Example

```bash
aws::wait-for-instance-tag "$(aws::instance-id)" "$(aws::instance-region)" Role 120 5
```

#### Arguments

* **$1** (string): Instance ID.
* **$2** (string): Region of the instance.
* **$3** (string): Tag key.
* **$4** (integer): Timeout in seconds.
* **$5** (integer): Seconds between attempts.

#### Exit codes

* **0**: The value was written.
* **64**: An argument is invalid.
* **69**: The AWS CLI, Perl, or the clock provider is unavailable.
* **75**: The tag did not appear before the timeout, or the AWS CLI failed.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The tag value.

### aws::instances-with-tag

Write EC2 instances that have a requested tag.

Only pending and running instances are included.

#### Example

```bash
aws::instances-with-tag Role web ap-northeast-1
```

#### Arguments

* **$1** (string): Tag key.
* **$2** (string): Tag value.
* **$3** (string): Region.

#### Exit codes

* **0**: The instances were written.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI is unavailable.
* **75**: The AWS CLI failed for a reason other than credentials.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The describe-instances response as JSON.

### aws::auto-scaling-group

Write the Auto Scaling group that contains an EC2 instance.

#### Example

```bash
aws::auto-scaling-group web-asg ap-northeast-1
```

#### Arguments

* **$1** (string): Auto Scaling group name.
* **$2** (string): Region.

#### Exit codes

* **0**: The group was written.
* **1**: No group has that name.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI is unavailable.
* **75**: The AWS CLI failed for a reason other than credentials.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The group description as JSON.

### aws::instances-in-auto-scaling-group

Write running or pending instances in an Auto Scaling group.

#### Example

```bash
aws::instances-in-auto-scaling-group web-asg ap-northeast-1
```

#### Arguments

* **$1** (string): Auto Scaling group name.
* **$2** (string): Region.

#### Exit codes

* **0**: The instances were written.
* **1**: No group has that name.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI or Perl is unavailable.
* **75**: The AWS CLI failed or returned invalid JSON.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The describe-instances response as JSON; {"Reservations":[]} for an empty group.

### aws::auto-scaling-group-name

Write the current instance's Auto Scaling group name.

The name is read from the aws:autoscaling:groupName tag of this instance,
waiting until the tag appears.

#### Example

```bash
group="$(aws::auto-scaling-group-name 300 10)"
```

#### Arguments

* **$1** (integer): Timeout in seconds.
* **$2** (integer): Seconds between attempts.

#### Exit codes

* **0**: The name was written.
* **64**: The timeout or interval is not a positive integer.
* **69**: curl, the AWS CLI, or Perl is unavailable.
* **75**: The metadata service did not answer, or the tag did not appear in time.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The Auto Scaling group name.

### aws::auto-scaling-group-size

Write the desired capacity of an Auto Scaling group.

#### Example

```bash
aws::auto-scaling-group-size web-asg ap-northeast-1
```

#### Arguments

* **$1** (string): Auto Scaling group name.
* **$2** (string): Region.

#### Exit codes

* **0**: The capacity was written.
* **1**: No group has that name.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI or Perl is unavailable.
* **75**: The AWS CLI failed or returned invalid JSON.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The desired capacity as a number.

