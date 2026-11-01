# gsettings

GSettings string-array values.

## Overview

Values are parsed as GVariant text, so quoted commas and escapes are kept.

## Index

* [gsettings::string-array::add](#gsettingsstring-arrayadd)
* [gsettings::string-array::remove](#gsettingsstring-arrayremove)

### gsettings::string-array::add

Add a literal value to a GSettings string array when it is absent.

#### Example

```bash
gsettings::string-array::add org.gnome.shell favorite-apps code.desktop
```

#### Arguments

* **$1** (string): GSettings schema, such as org.gnome.shell.
* **$2** (string): Key that holds a string array.
* **$3** (string): Value to add; it must not be empty or contain a newline.

#### Exit codes

* **0**: The value is in the array.
* **64**: The value is empty or contains a newline, or the argument count is not three.
* other The status of gsettings.

### gsettings::string-array::remove

Remove every element equal to a literal value from a GSettings string array.

#### Example

```bash
gsettings::string-array::remove org.gnome.shell favorite-apps firefox.desktop
```

#### Arguments

* **$1** (string): GSettings schema.
* **$2** (string): Key that holds a string array.
* **$3** (string): Value to remove.

#### Exit codes

* **0**: The value is no longer in the array.
* **64**: The value is empty or contains a newline, or the argument count is not three.
* other The status of gsettings.

