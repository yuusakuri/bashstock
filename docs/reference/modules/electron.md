# electron

Electron desktop settings.

## Overview

Configure the rendering platform used by Electron applications.

## Index

* [electron::wayland::enable](#electronwaylandenable)
* [electron::wayland::disable](#electronwaylanddisable)

### electron::wayland::enable

Prefer native Wayland rendering for Electron applications in a Wayland session.

The setting persists the Wayland session type for Electron versions that
select their Ozone backend from XDG_SESSION_TYPE, and keeps the legacy
ELECTRON_OZONE_PLATFORM_HINT for older versions. It is also imported into
the running systemd user manager. Applications that are already running
must be restarted. The function is a no-op outside a supported Linux
Wayland session.

#### Example

```bash
electron::wayland::enable
```

_Function has no arguments._

#### Exit codes

* **0**: The setting was written, the session is not Wayland, or systemd cannot persist it.
* **64**: An argument was given.
* **69**: The operating system is not Linux or mkdir is unavailable.
* **74**: The setting could not be written.

#### Output on stderr

* How to force Wayland for an application that overrides the shared preference.

### electron::wayland::disable

Remove BashStock's native Wayland preference for Electron applications.

The BashStock-owned environment file is removed and the legacy hint is unset
in the running systemd user manager when available. Its XDG_SESSION_TYPE is
restored to the current session's type. Already-running applications are
unchanged; start them again to use their default backend.

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

