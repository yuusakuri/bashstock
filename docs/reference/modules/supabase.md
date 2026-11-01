# supabase

Supabase CLI installation.

## Overview

The CLI is installed from its official releases.

## Index

* [supabase::versions](#supabaseversions)
* [supabase::install](#supabaseinstall)

### supabase::versions

Write Supabase CLI versions available to the current platform.

#### Example

```bash
supabase::versions | tail -n 1
```

_Function has no arguments._

#### Exit codes

* **0**: The versions were written.
* **64**: An argument was given.
* **69**: The platform is unsupported, or Perl is missing.
* **74**: The release list could not be downloaded.

#### Output on stdout

* Supabase CLI versions, one per line.

### supabase::install

Install the Supabase CLI from its Homebrew tap or release packages.

#### Example

```bash
supabase::install
supabase --version
```

#### Arguments

* **$1** (string): Optional version from supabase::versions; on macOS only the current tap version. Defaults to the newest one.

#### Exit codes

* **0**: The Supabase CLI is installed.
* **64**: The argument count is wrong.
* **69**: The platform or CPU is unsupported, or the version is unavailable.
* **74**: The release package could not be downloaded.
* other The status of brew or the package manager.

