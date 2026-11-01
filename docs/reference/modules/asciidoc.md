# asciidoc

AsciiDoc conversion.

## Overview

Documents are converted with Asciidoctor and its diagram extension.

## Index

* [asciidoc::html](#asciidochtml)

### asciidoc::html

Convert AsciiDoc to HTML with diagram support.

#### Example

```bash
asciidoc::html docs/design.adoc build/html
```

#### Arguments

* **$1** (string): AsciiDoc file.
* **$2** (string): Optional directory for the HTML. Defaults to the current directory.

#### Exit codes

* **0**: The HTML was written.
* **64**: The arguments are invalid or the file does not exist.
* **69**: asciidoctor is unavailable.
* other The status of asciidoctor.

