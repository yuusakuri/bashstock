# i2c

I2C bus and device inspection.

## Overview

Buses and devices are listed with i2cdetect.

## Index

* [i2c::bus::list](#i2cbuslist)
* [i2c::device::list](#i2cdevicelist)

### i2c::bus::list

Write the I2C buses with i2cdetect -l.

#### Example

```bash
i2c::bus::list
```

_Function has no arguments._

#### Exit codes

* **0**: The buses were written.
* **64**: An argument was given.
* **69**: i2cdetect is unavailable.
* other The status of i2cdetect.

#### Output on stdout

* The output of i2cdetect -l.

### i2c::device::list

Write the devices on one I2C bus with i2cdetect -y.

#### Example

```bash
i2c::device::list 1
```

#### Arguments

* **$1** (integer): I2C bus number.

#### Exit codes

* **0**: The devices were written.
* **64**: The argument is not one bus number.
* **69**: i2cdetect is unavailable.
* other The status of i2cdetect.

#### Output on stdout

* The address map that i2cdetect writes.

