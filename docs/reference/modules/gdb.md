# gdb

Debugging with GDB and gdbserver.

## Overview

Functions start, attach, or connect GDB in batch or interactive mode.

## Index

* [gdb::attach-pid](#gdbattach-pid)
* [gdb::server::start](#gdbserverstart)
* [gdb::connect](#gdbconnect)
* [gdb::run-until](#gdbrun-until)
* [gdb::core::open](#gdbcoreopen)
* [gdb::attach-by-name](#gdbattach-by-name)

### gdb::attach-pid

Attach GDB in batch mode to a process and write the backtrace of every thread.

#### Example

```bash
gdb::attach-pid 4242 > backtrace.txt
```

#### Arguments

* **$1** (integer): Process ID.

#### Exit codes

* **0**: The backtrace was written.
* **64**: The argument is not one process ID.
* **69**: gdb is unavailable.
* other The status of gdb.

#### Output on stdout

* The backtrace of every thread.

### gdb::server::start

Start COMMAND with its arguments under gdbserver listening on PORT.

#### Example

```bash
gdb::server::start 2345 ./build/app --verbose
```

#### Arguments

* **$1** (integer): TCP port to listen on.
* **$2** (string): Command to run.
* **...** (string): Optional arguments of the command.

#### Exit codes

* **0**: gdbserver ended successfully.
* **64**: The port or command is invalid.
* **69**: gdbserver is unavailable.
* other The status of gdbserver.

### gdb::connect

Load ELF in GDB and connect to the GDB server at HOST and PORT.

#### Example

```bash
gdb::connect ./build/app 192.168.1.50 2345
```

#### Arguments

* **$1** (string): ELF file with symbols.
* **$2** (string): Host of the GDB server.
* **$3** (integer): Port of the GDB server.

#### Exit codes

* **0**: GDB ended successfully.
* **64**: The arguments are invalid or the ELF file does not exist.
* **69**: gdb is unavailable.
* other The status of gdb.

### gdb::run-until

Run ELF in GDB with optional program arguments and stop at SYMBOL.

#### Example

```bash
gdb::run-until ./build/app parse_config --config test.ini
```

#### Arguments

* **$1** (string): ELF file to run.
* **$2** (string): Symbol or location to break at.
* **...** (string): Optional program arguments.

#### Exit codes

* **0**: GDB ended successfully.
* **64**: The ELF file does not exist or no symbol was given.
* **69**: gdb is unavailable.
* other The status of gdb.

### gdb::core::open

Open ELF and a core dump in GDB.

#### Example

```bash
gdb::core::open ./build/app core.4242
```

#### Arguments

* **$1** (string): ELF file that produced the core dump.
* **$2** (string): Core dump file.

#### Exit codes

* **0**: GDB ended successfully.
* **64**: The argument count is not two or a file does not exist.
* **69**: gdb is unavailable.
* other The status of gdb.

### gdb::attach-by-name

Attach GDB to the first process whose executable name is NAME.

#### Example

```bash
gdb::attach-by-name myapp > backtrace.txt
```

#### Arguments

* **$1** (string): Executable name.

#### Exit codes

* **0**: The backtrace was written.
* **1**: No process has the name.
* **64**: The argument count is not one.
* other The status of gdb::attach-pid.

#### Output on stdout

* The backtrace of every thread.

