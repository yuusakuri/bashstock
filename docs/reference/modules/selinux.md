# selinux

SELinux rule generation.

## Overview

Rules are generated from audit log denials with audit2allow.

## Index

* [selinux::generate-rule](#selinuxgenerate-rule)

### selinux::generate-rule

Generate SELinux allow rules from the AVC denials of an audit log.

#### Example

```bash
selinux::generate-rule /var/log/audit/audit.log ./allow.te
```

#### Arguments

* **$1** (string): Audit log, such as /var/log/audit/audit.log.
* **$2** (string): Optional rule file. Defaults to selinux.txt next to the audit log.

#### Exit codes

* **0**: The rules were written.
* **1**: The log has no AVC denial.
* **64**: The arguments are invalid or the log does not exist.
* **69**: audit2allow is unavailable.
* other The status of audit2allow.

#### Output on stderr

* A message when the log has no AVC denial.

