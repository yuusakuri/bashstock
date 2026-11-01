# archive

Archive creation, extraction, and verification.

## Overview

The archive format is chosen from the file extension.

## Index

* [archive::verify](#archiveverify)
* [archive::remove-broken](#archiveremove-broken)
* [archive::extract-file](#archiveextract-file)
* [archive::compress-tar-gzip](#archivecompress-tar-gzip)
* [archive::extract](#archiveextract)

### archive::verify

Verify all recognized archives below a path.

The recognized extensions are .tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2,
.tbz2, .tbz, .tar.zst, .tzst, .zip, .7z, .gz, .xz, .bz2, and .zst.
Compressed data is tested in full, and tar archives are read to the end of
their entries; the bytes of the files inside a tar archive are covered only
by the compression checksum. An archive that cannot be verified, because
its tool is missing, it is encrypted, or it cannot be read, is reported on
standard error but not counted as broken, and does not change the status.

#### Example

```bash
archive::verify "${HOME}/Downloads"
```

#### Arguments

* **$1** (string): Optional archive file or directory to search. Defaults to the current directory.

#### Exit codes

* **0**: Every archive is valid.
* **1**: At least one archive is broken.
* **64**: More than one argument was given.
* **66**: The path does not exist or cannot be searched.
* **74**: The temporary list could not be created.

#### Output on stderr

* The path of each broken archive, and a message for each archive that cannot be verified.

### archive::remove-broken

Remove archives that fail verification.

Only archives that archive::verify reports as broken are removed. An
archive that cannot be verified is kept and does not change the status.

#### Example

```bash
archive::remove-broken "${HOME}/Downloads"
```

#### Arguments

* **$1** (string): Optional archive file or directory to search. Defaults to the current directory.

#### Exit codes

* **0**: No archive was broken.
* **1**: At least one broken archive was removed.
* **64**: More than one argument was given.
* **66**: The path does not exist or cannot be searched.
* **74**: A broken archive or the temporary list could not be removed or created.

#### Output on stderr

* The path of each removed archive, and a message for each archive that cannot be verified.

### archive::extract-file

Extract one archive or decompress one compressed file.

Archives (.tar, .tar.gz, .tgz, .tar.xz, .txz, .tar.bz2, .tbz2, .tbz,
.tar.zst, .tzst, .zip, .7z) are extracted into a directory. Entry names that
are absolute or climb with .. are refused before extraction. The archive is
extracted into a staging directory inside the destination, and a symbolic
link that points outside the destination discards the extraction with 65.
A single compressed file (.gz, .xz, .bz2, .zst) is decompressed into one
file named without the extension. Existing files are overwritten.

#### Example

```bash
archive::extract-file release.tar.xz /opt/release
archive::extract-file access.log.gz
```

#### Arguments

* **$1** (string): Archive or compressed file.
* **$2** (string): Optional output directory. Defaults to the archive path without its extension, or to the directory of a single compressed file.

#### Exit codes

* **0**: The archive was extracted.
* **64**: The arguments are invalid or the extension is not recognized.
* **65**: The archive is corrupt or contains an entry outside the destination.
* **69**: A required tool is unavailable, or the entry names of an encrypted 7z archive cannot be read.
* **73**: A single compressed file would replace a directory.
* **74**: The destination could not be written.

#### Output on stderr

* The rejected entry or symbolic link when the archive is refused.

### archive::compress-tar-gzip

Compress paths into a gzip-compressed tar archive.

#### Example

```bash
archive::compress-tar-gzip --output backup.tar.gz Documents Pictures
```

#### Options

* **--output \<FILE\>**

  Archive to write. Defaults to the first path with .tar.gz appended.

#### Arguments

* **...** (string): Paths to add to the archive.

#### Exit codes

* **0**: The archive was written.
* **64**: No path was given or --output has no value.
* **69**: tar is unavailable.
* other The status of tar.

### archive::extract

Extract one archive, or every recognized archive below a directory, next to itself.

#### Example

```bash
archive::extract "${HOME}/Downloads"
```

#### Arguments

* **$1** (string): Optional archive file or directory to search. Defaults to the current directory.

#### Exit codes

* **0**: Every archive was extracted.
* **64**: More than one argument was given.
* **66**: The directory does not exist or cannot be searched.
* **74**: The temporary list could not be created.
* other The status of archive::extract-file for the first archive that failed.

