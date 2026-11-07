# electron

Electron desktop settings.

## Overview

Configure the rendering platform used by Electron applications.

## Index

* [electron::wayland::enable](#electronwaylandenable)
* [electron::wayland::disable](#electronwaylanddisable)

### electron::wayland::enable

Prefer native Wayland rendering for Electron applications in a Wayland session.

The setting is stored in systemd's per-user environment directory and
imported into the running systemd user manager when available. Applications
that are already running must be restarted. The function is a no-op outside
a supported Linux Wayland session.

#### Example

```bash
electron::wayland::enable
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written, or the current session is not Wayland.
* **64**: An argument was given.
* **69**: The operating system is not Linux or mkdir is unavailable.
* **74**: The setting could not be written.

### electron::wayland::disable

Remove BashStock's native Wayland preference for Electron applications.

The BashStock-owned environment file is removed and the variable is unset in
the running systemd user manager when available. Already-running
applications are unchanged; start them again to use their default backend.

#### Example

```bash
electron::wayland::disable
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was removed, or there was no setting to remove.
* **64**: An argument was given.
* **69**: The operating system is not Linux.
* **66**: The setting path exists but is not a regular file or a symlink.
* **74**: The setting could not be removed.

