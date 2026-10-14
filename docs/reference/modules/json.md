# json

Checks for values read from JSON.

## Overview

Values read from a JSON document are checked for emptiness and null before use.

## Index

* [json::require-present](#jsonrequire-present)

### json::require-present

Require a named JSON-derived value to be neither empty nor null.

#### Example

```bash
json::require-present .tag_name "${tag}" || return "$?"
```

#### Arguments

* **$1** (string): Name of the value for the message, such as .tag_name.
* **$2** (string): Value read from the JSON document.

#### Exit codes

* **0**: The value is present.
* **64**: The value is empty or null, or the name is invalid.

#### Output on stderr

* A message naming the value when it is missing.

