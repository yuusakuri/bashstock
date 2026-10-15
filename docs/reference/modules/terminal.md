# terminal

Availability of the controlling terminal.

## Overview

terminal::is-available lets interactive functions fail instead of blocking when no terminal is available.

## Index

* [terminal::is-available](#terminalis-available)

### terminal::is-available

Test whether the controlling terminal is readable and writable.

#### Example

```bash
terminal::is-available && prompt::confirm 'Continue?'
```

_Function has no arguments._

#### Exit codes

* **0**: /dev/tty can be read and written.
* **1**: There is no usable controlling terminal, as in CI or cron.
* **64**: An argument was given.

