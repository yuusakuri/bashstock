# gpio

GPIO chip and line inspection.

## Overview

Chips and lines are listed with the libgpiod tools.

## Index

* [gpio__chip__list](#gpio__chip__list)
* [gpio__line__list](#gpio__line__list)

### gpio__chip__list

Write the GPIO chips with gpiodetect.

#### Example

```bash
gpio__chip__list
```

_Function has no arguments._

#### Exit codes

* **0**: The chips were written.
* **64**: An argument was given.
* **69**: gpiodetect is unavailable.
* other The status of gpiodetect.

#### Output on stdout

* The output of gpiodetect.

### gpio__line__list

Write the GPIO lines of one chip, or of every chip, with gpioinfo.

#### Example

```bash
gpio__line__list gpiochip0
```

#### Arguments

* **$1** (string): Optional chip name or number. Defaults to every chip.

#### Exit codes

* **0**: The lines were written.
* **64**: More than one argument was given.
* **69**: gpioinfo is unavailable.
* other The status of gpioinfo.

#### Output on stdout

* The output of gpioinfo.

