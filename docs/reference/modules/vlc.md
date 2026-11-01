# vlc

VLC installation.

## Overview

VLC is installed from the platform package source.

## Index

* [vlc::set-default-app](#vlcset-default-app)

### vlc::set-default-app

Set VLC as the default application for every MIME type it declares.

#### Example

```bash
vlc::set-default-app
xdg-mime query default video/mp4
```

_Function has no arguments._

#### Exit codes

* **0**: VLC opens every MIME type it declares.
* **64**: An argument was given.
* **66**: VLC's desktop file was not found or declares no MIME type.
* **69**: xdg-mime is unavailable.
* other The status of xdg-mime.

