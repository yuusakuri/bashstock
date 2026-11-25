# jenkins

Jenkins service control.

## Overview

The service is controlled through administrator execution.

## Index

* [jenkins__restart](#jenkins__restart)

### jenkins__restart

Restart the Jenkins service through administrator execution.

#### Example

```bash
jenkins__restart
```

_Function has no arguments._

#### Exit codes

* **0**: Jenkins was restarted.
* **64**: An argument was given.
* other The status of systemd__restart.

