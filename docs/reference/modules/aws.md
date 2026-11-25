# aws

Amazon EC2 instance metadata and AWS VPN Client logs.

## Overview

Metadata functions read the instance metadata service with IMDSv2 tokens; VPN Client functions manage its local log files.

## Index

* [aws__is-ec2-instance](#aws__is-ec2-instance)
* [aws__instance-metadata](#aws__instance-metadata)
* [aws__instance-id](#aws__instance-id)
* [aws__instance-region](#aws__instance-region)
* [aws__instance-availability-zone](#aws__instance-availability-zone)
* [aws__instance-private-ip](#aws__instance-private-ip)
* [aws__instance-tags](#aws__instance-tags)
* [aws__instance-tag](#aws__instance-tag)
* [aws__wait-for-instance-tag](#aws__wait-for-instance-tag)
* [aws__instances-with-tag](#aws__instances-with-tag)
* [aws__auto-scaling-group](#aws__auto-scaling-group)
* [aws__instances-in-auto-scaling-group](#aws__instances-in-auto-scaling-group)
* [aws__auto-scaling-group-name](#aws__auto-scaling-group-name)
* [aws__auto-scaling-group-size](#aws__auto-scaling-group-size)
* [aws__vpn-client__log__files](#aws__vpn-client__log__files)
* [aws__vpn-client__log__clear](#aws__vpn-client__log__clear)
* [aws__vpn-client__log__open](#aws__vpn-client__log__open)

### aws__is-ec2-instance

Test whether IMDSv2 is available for the current instance.

A token request to the instance metadata service decides it, with a
two-second limit, so the test is fast outside EC2.

#### Example

```bash
aws__is-ec2-instance && region="$(aws__instance-region)"
```

_Function has no arguments._

#### Exit codes

* **0**: The process runs on an EC2 instance with IMDSv2.
* **1**: The metadata service did not answer.
* **64**: An argument was given.

### aws__instance-metadata

Write one validated EC2 instance metadata value.

#### Example

```bash
aws__instance-metadata placement/availability-zone
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

### aws__instance-id

Write the current EC2 instance identifier.

#### Example

```bash
instance_id="$(aws__instance-id)"
```

_Function has no arguments._

#### Exit codes

* **0**: The ID was written.
* **64**: An argument was given.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer.

#### Output on stdout

* An instance ID such as i-0123456789abcdef0.

### aws__instance-region

Write the current EC2 instance region.

The region is read from the instance identity document.

#### Example

```bash
aws__instance-tags "$(aws__instance-id)" "$(aws__instance-region)"
```

_Function has no arguments._

#### Exit codes

* **0**: The region was written.
* **64**: An argument was given.
* **69**: curl or Python 3 is unavailable.
* **75**: The metadata service did not answer or the document is invalid.

#### Output on stdout

* A region such as ap-northeast-1.

### aws__instance-availability-zone

Write the current EC2 instance availability zone.

#### Example

```bash
aws__instance-availability-zone
```

_Function has no arguments._

#### Exit codes

* **0**: The zone was written.
* **64**: An argument was given.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer.

#### Output on stdout

* An availability zone such as ap-northeast-1a.

### aws__instance-private-ip

Write the current EC2 instance private IPv4 address.

#### Example

```bash
printf 'listen %s:8080\n' "$(aws__instance-private-ip)"
```

_Function has no arguments._

#### Exit codes

* **0**: The address was written.
* **64**: An argument was given.
* **69**: curl is unavailable.
* **75**: The metadata service did not answer.

#### Output on stdout

* The private IPv4 address.

### aws__instance-tags

Write all tags for one EC2 instance.

#### Example

```bash
aws__instance-tags i-0123456789abcdef0 ap-northeast-1
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

### aws__instance-tag

Write one EC2 instance tag value.

#### Example

```bash
aws__instance-tag i-0123456789abcdef0 ap-northeast-1 Name
```

#### Arguments

* **$1** (string): Instance ID.
* **$2** (string): Region of the instance.
* **$3** (string): Tag key.

#### Exit codes

* **0**: The value was written.
* **1**: The instance has no tag with that key.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI or Python 3 is unavailable.
* **75**: The AWS CLI failed or returned invalid JSON.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The tag value.

### aws__wait-for-instance-tag

Wait for one EC2 instance tag to become available.

Tags are applied shortly after an instance starts, so the tag is polled
until it appears or the timeout passes.

#### Example

```bash
aws__wait-for-instance-tag "$(aws__instance-id)" "$(aws__instance-region)" Role 120 5
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
* **69**: The AWS CLI, Python 3, or the clock provider is unavailable.
* **75**: The tag did not appear before the timeout, or the AWS CLI failed.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The tag value.

### aws__instances-with-tag

Write EC2 instances that have a requested tag.

Only pending and running instances are included.

#### Example

```bash
aws__instances-with-tag Role web ap-northeast-1
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

### aws__auto-scaling-group

Write the Auto Scaling group that contains an EC2 instance.

#### Example

```bash
aws__auto-scaling-group web-asg ap-northeast-1
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

### aws__instances-in-auto-scaling-group

Write running or pending instances in an Auto Scaling group.

#### Example

```bash
aws__instances-in-auto-scaling-group web-asg ap-northeast-1
```

#### Arguments

* **$1** (string): Auto Scaling group name.
* **$2** (string): Region.

#### Exit codes

* **0**: The instances were written.
* **1**: No group has that name.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI or Python 3 is unavailable.
* **75**: The AWS CLI failed or returned invalid JSON.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The describe-instances response as JSON; {"Reservations":[]} for an empty group.

### aws__auto-scaling-group-name

Write the current instance's Auto Scaling group name.

The name is read from the aws:autoscaling:groupName tag of this instance,
waiting until the tag appears.

#### Example

```bash
group="$(aws__auto-scaling-group-name 300 10)"
```

#### Arguments

* **$1** (integer): Timeout in seconds.
* **$2** (integer): Seconds between attempts.

#### Exit codes

* **0**: The name was written.
* **64**: The timeout or interval is not a positive integer.
* **69**: curl, the AWS CLI, or Python 3 is unavailable.
* **75**: The metadata service did not answer, or the tag did not appear in time.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The Auto Scaling group name.

### aws__auto-scaling-group-size

Write the desired capacity of an Auto Scaling group.

#### Example

```bash
aws__auto-scaling-group-size web-asg ap-northeast-1
```

#### Arguments

* **$1** (string): Auto Scaling group name.
* **$2** (string): Region.

#### Exit codes

* **0**: The capacity was written.
* **1**: No group has that name.
* **64**: An argument is empty or contains a newline.
* **69**: The AWS CLI or Python 3 is unavailable.
* **75**: The AWS CLI failed or returned invalid JSON.
* **77**: The credentials were missing, expired, or not allowed.

#### Output on stdout

* The desired capacity as a number.

### aws__vpn-client__log__files

Write AWS VPN Client log files as NUL-separated paths.

Files whose names contain aws_vpn_client_ and do not contain
ovpn_aws_vpn_client are selected, as in the reference script.

#### Example

```bash
aws__vpn-client__log__files | xargs -0 tail -n 50
```

#### Arguments

* **$1** (string): Optional log directory. Defaults to the AWS VPN Client log directory of this OS.

#### Exit codes

* **0**: The paths were written.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: find is unavailable.

#### Output on stdout

* NUL-separated paths of the log files.

### aws__vpn-client__log__clear

Remove regular log files below the AWS VPN Client log directory.

#### Example

```bash
aws__vpn-client__log__clear
```

#### Arguments

* **$1** (string): Optional log directory. Defaults to the AWS VPN Client log directory of this OS.

#### Exit codes

* **0**: Every regular file below the directory was removed.
* **64**: More than one argument was given.
* **66**: The directory does not exist or is a symbolic link.
* **69**: find is unavailable.
* **74**: A file could not be removed.

### aws__vpn-client__log__open

Open log files with an editor command, passing each path as one argument.

#### Example

```bash
files=()
while IFS= read -r -d '' file; do files+=("${file}"); done < <(aws__vpn-client__log__files)
aws__vpn-client__log__open code "${files[@]}"
```

#### Arguments

* **$1** (string): Editor command, such as code.
* **...** (string): Log files; at least one.

#### Exit codes

* **0**: The editor was started.
* **64**: The editor is empty, or no file was given.
* **66**: A path is not a regular file.
* **69**: The editor command is unavailable.
* other The status of the editor.

