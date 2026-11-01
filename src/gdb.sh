#!/usr/bin/env bash
# @file gdb
# @brief Debugging with GDB and gdbserver.
# @description Functions start, attach, or connect GDB in batch or interactive mode.

# shellcheck disable=SC2015,SC2034,SC2046,SC2119,SC2120,SC2155,SC2163,SC2317,SC2319,SC2329

# @description Attach GDB in batch mode to a process and write the backtrace of every thread.
#
# @arg $1 integer Process ID.
# @stdout The backtrace of every thread.
# @exitcode 0 The backtrace was written.
# @exitcode 64 The argument is not one process ID.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::attach-pid 4242 > backtrace.txt
gdb::attach-pid() {
  ( [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] ) || return 64
  command::require gdb || return "$?"
  gdb -q -batch -p "$1" -ex 'thread apply all bt'
}

# @description Start COMMAND with its arguments under gdbserver listening on PORT.
#
# @arg $1 integer TCP port to listen on.
# @arg $2 string Command to run.
# @arg $@ string Optional arguments of the command.
# @exitcode 0 gdbserver ended successfully.
# @exitcode 64 The port or command is invalid.
# @exitcode 69 gdbserver is unavailable.
# @exitcode other The status of gdbserver.
# @example
#   gdb::server::start 2345 ./build/app --verbose
gdb::server::start() { ( [[ "$#" -ge 2 && "$1" =~ ^[0-9]+$ && -n "$2" ]] ) || return 64; docker::_run-command gdbserver ":$1" "${@:2}"; }

# @description Load ELF in GDB and connect to the GDB server at HOST and PORT.
#
# @arg $1 string ELF file with symbols.
# @arg $2 string Host of the GDB server.
# @arg $3 integer Port of the GDB server.
# @exitcode 0 GDB ended successfully.
# @exitcode 64 The arguments are invalid or the ELF file does not exist.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::connect ./build/app 192.168.1.50 2345
gdb::connect() { ( [[ "$#" -eq 3 && -f "$1" && "$3" =~ ^[0-9]+$ ]] ) || return 64; docker::_run-command gdb "$1" -ex "target remote $2:$3"; }

# @description Run ELF in GDB with optional program arguments and stop at SYMBOL.
#
# @arg $1 string ELF file to run.
# @arg $2 string Symbol or location to break at.
# @arg $@ string Optional program arguments.
# @exitcode 0 GDB ended successfully.
# @exitcode 64 The ELF file does not exist or no symbol was given.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::run-until ./build/app parse_config --config test.ini
gdb::run-until() { [[ "$#" -ge 2 && -f "$1" && -n "$2" ]] || return 64; docker::_run-command gdb -ex "break $2" -ex run --args "$1" "${@:3}"; }

# @description Open ELF and a core dump in GDB.
#
# @arg $1 string ELF file that produced the core dump.
# @arg $2 string Core dump file.
# @exitcode 0 GDB ended successfully.
# @exitcode 64 The argument count is not two or a file does not exist.
# @exitcode 69 gdb is unavailable.
# @exitcode other The status of gdb.
# @example
#   gdb::core::open ./build/app core.4242
gdb::core::open() { [[ "$#" -eq 2 && -f "$1" && -f "$2" ]] || return 64; docker::_run-command gdb "$1" "$2"; }

# @description Attach GDB to the first process whose executable name is NAME.
#
# @arg $1 string Executable name.
# @stdout The backtrace of every thread.
# @exitcode 0 The backtrace was written.
# @exitcode 1 No process has the name.
# @exitcode 64 The argument count is not one.
# @exitcode other The status of gdb::attach-pid.
# @example
#   gdb::attach-by-name myapp > backtrace.txt
gdb::attach-by-name() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  local id=''
  id="$(process::_first-id-by-name "$1")" || return "$?"
  gdb::attach-pid "${id}"
}
