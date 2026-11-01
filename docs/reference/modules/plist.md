# plist

macOS property lists.

## Overview

Values are written with PlistBuddy.

## Index

* [plist::set](#plistset)

### plist::set

Set a string value for one top-level key in a macOS property list.

The file is created as an empty dictionary when it does not exist and is
validated with plutil before and after the change.

#### Example

```bash
plist::set "${HOME}/Library/Preferences/com.example.app.plist" Theme dark
```

#### Arguments

* **$1** (string): Property list file. A symbolic link is refused.
* **$2** (string): Top-level key without a dot.
* **$3** (string): String value.

#### Exit codes

* **0**: The value was written.
* **64**: The arguments are invalid.
* **65**: The file is not a valid property list.
* **66**: The path is not a regular file.
* **69**: plutil is unavailable.
* **74**: The file could not be created or changed.

