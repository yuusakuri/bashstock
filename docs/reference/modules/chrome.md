# chrome

Google Chrome installation and profiles.

## Overview

Chrome is installed from Google's package source; profiles live in the Chrome user data directory.

## Index

* [chrome__profile__export-bookmarks](#chrome__profile__export-bookmarks)
* [chrome__profile__export-preferences](#chrome__profile__export-preferences)
* [chrome__profile__email](#chrome__profile__email)
* [chrome__profile__find-by-email](#chrome__profile__find-by-email)
* [chrome__profile__export-user-data-by-email](#chrome__profile__export-user-data-by-email)
* [chrome__versions](#chrome__versions)
* [chrome__install](#chrome__install)

### chrome__profile__export-bookmarks

Export a Chrome profile's Bookmarks file.

#### Example

```bash
chrome__profile__export-bookmarks "${HOME}/.config/google-chrome/Default" backup/bookmarks.json
```

#### Arguments

* **$1** (string): Chrome profile directory.
* **$2** (string): Optional output file. Defaults to ./bookmarks.json.

#### Exit codes

* **0**: The file was copied.
* **64**: The arguments are invalid or the profile is not a directory.
* **66**: The profile has no Bookmarks file.
* other The status of cp.

### chrome__profile__export-preferences

Export a Chrome profile's Preferences file.

#### Example

```bash
chrome__profile__export-preferences "${HOME}/.config/google-chrome/Profile 1"
```

#### Arguments

* **$1** (string): Chrome profile directory.
* **$2** (string): Optional output file. Defaults to ./preferences.json.

#### Exit codes

* **0**: The file was copied.
* **64**: The arguments are invalid or the profile is not a directory.
* **66**: The profile has no Preferences file.
* other The status of cp.

### chrome__profile__email

Write the first known email address from a Chrome profile.

#### Example

```bash
chrome__profile__email "${HOME}/.config/google-chrome/Default"
```

#### Arguments

* **$1** (string): Chrome profile directory.

#### Exit codes

* **0**: The address was written.
* **1**: The profile has no email address.
* **64**: The argument is not a profile with a Preferences file.
* **69**: jq is unavailable.
* **74**: Preferences could not be read.

#### Output on stdout

* The email address.

### chrome__profile__find-by-email

Find Chrome profiles whose known email matches literally.

#### Example

```bash
chrome__profile__find-by-email developer@example.com
```

#### Arguments

* **$1** (string): Email address.
* **$2** (string): Optional Chrome user data directory. Defaults to the standard directory of the platform.

#### Exit codes

* **0**: At least one profile matches.
* **1**: No profile matches.
* **64**: The arguments are invalid.
* **66**: The user data directory does not exist.

#### Output on stdout

* One matching profile directory per line.

### chrome__profile__export-user-data-by-email

Export Chrome Preferences and Bookmarks for profiles whose email matches literally.

#### Example

```bash
chrome__profile__export-user-data-by-email alice@example.com "${HOME}/chrome-backup"
```

#### Arguments

* **$1** (string): Email address of the Chrome profile, compared literally.
* **$2** (string): Optional destination directory. Defaults to the current directory.

#### Exit codes

* **0**: Preferences and Bookmarks of every matching profile were copied as PROFILE_preferences.json and PROFILE_bookmarks.json.
* **1**: No profile has that email address.
* **64**: The email address is empty, or the argument count is wrong.
* **66**: Chrome's user data directory does not exist.
* **74**: The destination could not be created or a file could not be copied.

### chrome__versions

Write Google Chrome versions available to the current platform.

#### Example

```bash
chrome__versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported.
* **74**: The repository index could not be downloaded.

#### Output on stdout

* Google Chrome versions, one per line; on Ubuntu only builds that the installed C library can run.

### chrome__install

Install Google Chrome from the Google repository or Homebrew.

On Ubuntu, a version is accepted only when the installed C library can run it,
and an omitted version selects the newest such build.

#### Example

```bash
chrome__install
```

#### Arguments

* **$1** (string): Optional version from chrome__versions; on macOS only the current version. Defaults to the newest runnable one.

#### Exit codes

* **0**: Google Chrome is installed.
* **64**: The argument count is wrong.
* **69**: The platform is unsupported, or the version is unavailable or cannot run here.
* **74**: The repository or its key could not be downloaded.
* other The status of the package manager.

