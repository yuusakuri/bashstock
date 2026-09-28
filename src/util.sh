#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2046,SC2119,SC2120,SC2317,SC2319,SC2015,SC2155,SC2163,SC2329

### Wait for one line from the controlling terminal.
prompt::pause() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local message="${1:-Press Enter to continue.}"
  terminal::is-available || return 69
  local line=''
  IFS= read -r -p "${message}" line </dev/tty || return 74
}

### Sleep for a non-negative integer number of hours.
time::sleep-hours() {
  if [[ "$#" -ne 1 || ! "$1" =~ ^(0|[1-9][0-9]*)$ ]]; then return 64; fi
  command -v sleep >/dev/null 2>&1 || return 69
  sleep "$((10#$1 * 3600))"
}

### Show human-readable filesystem usage for a path.
storage::usage() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local path="${1:-.}"
  [[ -e "$path" || -d "$path" ]] || return 66
  command -v df >/dev/null 2>&1 || return 69
  df -h "$path"
}

### Show the largest direct entries in a directory.
storage::largest-entries() {
  if [[ "$#" -gt 2 ]]; then return 64; fi
  local directory="${1:-.}" max="${2:-10}"
  [[ -d "$directory" && "$max" =~ ^[1-9][0-9]*$ ]] || return 64
  command -v du >/dev/null 2>&1 || return 69
  command -v sort >/dev/null 2>&1 || return 69
  command -v head >/dev/null 2>&1 || return 69
  du -sk "$directory"/* 2>/dev/null | sort -nr | head -n "$max"
}

### Write the total physical memory in bytes.
mem::physical-total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
    darwin) command -v sysctl >/dev/null 2>&1 || return 69; sysctl -n hw.memsize || return 74 ;;
    linux) awk '/^MemTotal:/ {print $2 * 1024; exit}' /proc/meminfo 2>/dev/null || return 74 ;;
    *) return 69 ;;
  esac
}

### Write the total physical memory in gibibytes.
mem::physical-total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem::physical-total-bytes)" || return "$?"
  awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

### Write the total swap capacity in bytes.
mem::swap-total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  case "$(system::operating-system)" in
    darwin) command -v sysctl >/dev/null 2>&1 || return 69; sysctl -n vm.swapusage 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="total") {gsub("M","",$(i+1)); print $(i+1)*1048576; exit}}' ;;
    linux) awk '/^SwapTotal:/ {print $2 * 1024; exit}' /proc/meminfo 2>/dev/null || return 74 ;;
    *) return 69 ;;
  esac
}

### Write the total swap capacity in gibibytes.
mem::swap-total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem::swap-total-bytes)" || return "$?"
  awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

### Write the total memory and swap capacity in bytes.
mem::total-bytes() {
  [[ "$#" -eq 0 ]] || return 64
  local a='' b=''; a="$(mem::physical-total-bytes)" || return "$?"; b="$(mem::swap-total-bytes)" || return "$?"; printf '%s\n' "$((a+b))"
}

### Write the total memory and swap capacity in gibibytes.
mem::total-gibibytes() {
  [[ "$#" -eq 0 ]] || return 64
  local bytes=''; bytes="$(mem::total-bytes)" || return "$?"; awk -v b="$bytes" 'BEGIN {printf "%.2f\n", b / 1073741824}'
}

### Write text to a regular file using an atomic replacement.
### New files use 0666 filtered by the caller's umask; existing metadata is preserved.
file::write-text() {
  if [[ "$#" -ne 2 || -z "$1" || -L "$1" ]]; then return 64; fi
  local file="$1" text="$2" temporary='' mode='' mask=''
  if [[ -e "$file" && ! -f "$file" ]]; then return 66; fi
  mask="$(umask)"
  if file::_requires-root "$file"; then
    bashstock::_run-as-root write-text "$@" "${mask}"
    return
  fi
  temporary="$(umask 077 && file::_temporary-path "$file")" || return "$?"
  if [[ -e "$file" ]]; then
    file::_copy-metadata-and-content "$file" "$temporary" || { rm -f -- "$temporary"; return 74; }
  else
    printf -v mode '%04o' "$((0666 & ~8#${mask}))"
  fi
  if ! printf '%s' "$text" >"$temporary"; then rm -f -- "$temporary"; return 74; fi
  if [[ -n "${mode}" ]] && ! chmod "${mode}" "${temporary}"; then
    rm -f -- "${temporary}"
    return 74
  fi
  if ! mv -f -- "$temporary" "$file"; then rm -f -- "$temporary"; return 74; fi
}

### Find regular files whose contents match a Perl expression.
file::find-by-content() {
  if [[ "$#" -lt 1 || "$#" -gt 4 ]]; then return 64; fi
  local expression="$1" directory="${2:-.}" max="${3:-1}" binary="${4:-0}"
  [[ -d "$directory" && "$max" =~ ^[1-9][0-9]*$ && "$binary" =~ ^[01]$ ]] || return 64
  command -v find >/dev/null 2>&1 || return 69
  command -v perl >/dev/null 2>&1 || return 69
  local path=''
  while IFS= read -r -d '' path; do
    if [[ "$binary" -eq 0 ]] && ! file::_require-no-nul "$path"; then continue; fi
    perl -e 'my($p,$e)=@ARGV; open my $f,"<",$p or exit 2; local $/; my $s=<$f>; my $r=eval{qr/$e/}; exit 2 if $@; exit($s =~ $r ? 0 : 1)' -- "$path" "$expression" 2>/dev/null && printf '%s\n' "$path"
  done < <(find "$directory" -type f -print0)
}

### Print the newest regular file whose name matches an expression.
file::latest-by-name() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then return 64; fi
  local expression="$1" directory="${2:-.}" path='' newest='' newest_time=0 current_time=''
  [[ -d "$directory" ]] || return 66
  while IFS= read -r -d '' path; do
    [[ "$(basename -- "$path")" =~ $expression ]] || continue
    current_time="$(file::modified-time-unix-seconds "$path" 2>/dev/null)" || continue
    if [[ -z "$newest" || "$current_time" -gt "$newest_time" ]]; then newest="$path"; newest_time="$current_time"; fi
  done < <(find "$directory" -type f -print0)
  [[ -n "$newest" ]] || return 1; printf '%s\n' "$newest"
}

### Create a symbolic link after validating both paths.
symlink::create() {
  if [[ "$#" -ne 2 || -z "$1" || -z "$2" || -e "$2" || -L "$2" ]]; then return 64; fi
  command -v ln >/dev/null 2>&1 || return 69
  ln -s -- "$1" "$2" || return 74
}

### Remove one symbolic link.
symlink::remove() {
  if [[ "$#" -ne 1 || ! -L "$1" ]]; then return 64; fi
  command -v rm >/dev/null 2>&1 || return 69
  rm -f -- "$1" || return 74
}

### Write the first default-route interface.
net::interface::default() { [[ "$#" -eq 0 ]] || return 64; net::_default-interface; }

### Write the first default-route gateway.
net::gateway::default() { [[ "$#" -eq 0 ]] || return 64; net::_default-gateway; }

### Write the primary private IPv4 address.
net::ip::private-v4() {
  if [[ "$#" -gt 1 ]]; then return 64; fi
  local interface="${1:-}" cidr='' address=''
  if [[ -z "$interface" ]]; then
    if [[ "$(system::operating-system)" == darwin ]]; then interface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"; else interface="$(net::_default-interface)"; fi
  fi
  [[ -n "$interface" ]] || return 69
  if [[ "$(system::operating-system)" == darwin ]]; then address="$(ifconfig "$interface" 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {print $2; exit}')"; else cidr="$(net::_interface-ipv4-cidr "$interface")" || return 69; address="${cidr%/*}"; fi
  [[ -n "$address" ]] || return 1; printf '%s\n' "$address"
}

### Write the primary private IPv6 address.
net::ip::private-v6() {
  if [[ "$#" -gt 2 ]]; then return 64; fi
  local interface="${1:-$(net::_default-interface)}" excluded="${2:-}" address=''
  [[ -n "$interface" ]] || return 69
  if [[ "$(system::operating-system)" == darwin ]]; then
    address="$(ifconfig "$interface" 2>/dev/null | awk -v excluded="$excluded" '/inet6 / && $2 !~ /^fe80/ && $2 != excluded {print $2; exit}')"
  else
    address="$(ip -o -6 addr show dev "$interface" scope global 2>/dev/null | awk -v excluded="$excluded" '{sub(/\/.*/,"",$4); if ($4 != excluded) {print $4; exit}}')"
  fi
  [[ -n "$address" ]] || return 1; printf '%s\n' "$address"
}

### Write the public IP address discovered through the configured service.
net::ip::public() { [[ "$#" -eq 0 ]] || return 64; command -v curl >/dev/null 2>&1 || return 69; curl -fsS https://api.ipify.org || return 74; printf '\n'; }

### Test whether a DNS name resolves.
net::dns::test() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  if command -v getent >/dev/null 2>&1; then
    getent ahosts "$1" >/dev/null 2>&1
    return
  fi
  command -v dscacheutil >/dev/null 2>&1 || return 69
  dscacheutil -q host -a name "$1" >/dev/null 2>&1
}

### Add a user to a supplementary group through administrator execution.
user::add-to-group() {
  if [[ "$#" -lt 1 || "$#" -gt 2 || ! "$1" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]]; then return 64; fi
  local user="${2:-}"
  [[ -n "${user}" ]] || user="$(user::name)" || return "$?"
  case "$(system::operating-system)" in
    darwin) command::require dseditgroup || return "$?"; command::run-as-root dseditgroup -o edit -a "${user}" -t user "$1" ;;
    linux) command::require usermod || return "$?"; command::run-as-root usermod -a -G "$1" "${user}" ;;
    *) return 69 ;;
  esac
}

### Write the kernel name.
system::kernel-name() { [[ "$#" -eq 0 ]] || return 64; command -v uname >/dev/null 2>&1 || return 69; uname -s; }

### Write the distribution name.
system::distribution-name() { [[ "$#" -eq 0 ]] || return 64; platform::_identifier; }

### Enable system sleep.
system::enable-sleep() { [[ "$#" -eq 0 ]] || return 64; case "$(system::operating-system)" in darwin) sudo pmset -a sleep 1 ;; linux) command -v systemctl >/dev/null 2>&1 || return 69; sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target ;; *) return 69 ;; esac; }

### Disable system sleep.
system::disable-sleep() { [[ "$#" -eq 0 ]] || return 64; case "$(system::operating-system)" in darwin) sudo pmset -a sleep 0 ;; linux) command -v systemctl >/dev/null 2>&1 || return 69; sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target ;; *) return 69 ;; esac; }

### Write a POSIX TZ string for an offset in seconds.
time::posix-timezone() { [[ "$#" -eq 1 && "$1" =~ ^-?[0-9]+$ ]] || return 64; local offset="$1" sign='+' abs='' hours='' minutes=''; if ((offset < 0)); then sign='-'; abs=$((-offset)); else abs="$offset"; fi; hours=$((abs/3600)); minutes=$(((abs%3600)/60)); printf 'UTC%s%d:%02d\n' "$sign" "$hours" "$minutes"; }

### Merge the contents of one directory into another directory.
directory::merge() { [[ "$#" -eq 2 && -d "$1" ]] || return 64; command -v cp >/dev/null 2>&1 || return 69; mkdir -p -- "$2" || return 74; cp -R "$1"/. "$2"/ || return 74; }

### Create a directory named with the current date and time.
directory::create-with-date-time() { if [[ "$#" -gt 1 ]]; then return 64; fi; local dir="${1:-.}" name=''; [[ -d "$dir" ]] || return 66; name="$(time::local-date-time-seconds-basic)" || return "$?"; mkdir -- "$dir/$name" || return 74; printf '%s\n' "$dir/$name"; }

### Remove directory contents while preserving the directory itself.
directory::clear() { if [[ "$#" -gt 1 || ! -d "${1:-.}" ]]; then return 64; fi; local dir="${1:-.}" entry=''; for entry in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do [[ -e "$entry" || -L "$entry" ]] || continue; rm -rf -- "$entry" || return 74; done; }

### Write the configured POSIX timezone continuously with the current time.
time::status-continuous() { [[ "$#" -eq 0 ]] || return 64; while :; do time::local-date-time-seconds-extended || return "$?"; sleep 1 || return 74; done; }

### Open an editor for a file, using sudoedit only when required.
file::edit() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; if [[ -e "$1" && ! -f "$1" ]]; then return 66; fi; if [[ -w "$1" || (! -e "$1" && -w "$(path::directory-name "$1")") ]]; then "${EDITOR:-vi}" "$1"; else command -v sudoedit >/dev/null 2>&1 || return 69; sudoedit "$1"; fi; }

### Release a file held by another process.
file::release() {
  [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64
  command -v lsof >/dev/null 2>&1 || return 69
  local timeout="${2:-2}" start='' pid=''
  start="$(date +%s)" || return 74
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    kill -TERM "$pid" 2>/dev/null || true
  done < <(lsof -t -- "$1" 2>/dev/null)
  while (( $(date +%s) - start < timeout )); do
    lsof -t -- "$1" >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  while read -r pid; do
    kill -KILL "$pid" 2>/dev/null || true
  done < <(lsof -t -- "$1" 2>/dev/null)
  lsof -t -- "$1" >/dev/null 2>&1 && return 75
}

### Open a GNU Screen session.
screen::open() { if [[ "$#" -gt 1 ]]; then return 64; fi; command -v screen >/dev/null 2>&1 || return 69; screen "${1:-default}"; }

### Verify all recognized archives below a path.
archive::verify() { if [[ "$#" -gt 1 ]]; then return 64; fi; local path="${1:-.}" file=''; local status=0; while IFS= read -r -d '' file; do case "$file" in *.tar.gz|*.tgz) tar -tzf "$file" >/dev/null 2>&1 || { printf '%s\n' "$file" >&2; status=1; } ;; *.zip) command -v unzip >/dev/null 2>&1 || return 69; unzip -tqq "$file" >/dev/null 2>&1 || { printf '%s\n' "$file" >&2; status=1; } ;; esac; done < <(find "$path" -type f \( -name '*.tar.gz' -o -name '*.tgz' -o -name '*.zip' \) -print0); return "$status"; }

### Remove archives that fail verification.
archive::remove-broken() { [[ "$#" -le 1 ]] || return 64; local path="${1:-.}" file='' status=0; while IFS= read -r -d '' file; do if ! archive::_remove-broken-file "$file"; then rm -f -- "$file" || return 74; status=1; fi; done < <(archive::_find "$path"); return "$status"; }

### List recognized archive files below a directory as NUL-separated paths.
archive::_find() { [[ "$#" -le 1 ]] || return 64; find "${1:-.}" -type f \( -name '*.tar.gz' -o -name '*.tgz' -o -name '*.zip' \) -print0; }

### Verify and remove one archive file when it is invalid.
archive::_remove-broken-file() { [[ "$#" -eq 1 && -f "$1" ]] || return 64; archive::verify "$1" >/dev/null 2>&1 || { rm -f -- "$1"; return 1; }; }

### Extract one archive into a destination directory.
archive::extract-file() { [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64; local file="$1" dest="${2:-${1%.tar.gz}}" entry=''; mkdir -p -- "$dest" || return 74; case "$file" in *.tar.gz|*.tgz) while IFS= read -r entry; do [[ "$entry" != /* && "$entry" != ../* && "$entry" != */../* ]] || return 65; done < <(tar -tzf "$file" 2>/dev/null) || return 65; tar -xzf "$file" -C "$dest" ;; *.zip) command -v unzip >/dev/null 2>&1 || return 69; while IFS= read -r entry; do [[ "$entry" != /* && "$entry" != ../* && "$entry" != */../* ]] || return 65; done < <(unzip -Z1 "$file" 2>/dev/null) || return 65; unzip -o "$file" -d "$dest" ;; *) return 64 ;; esac; }

### Compress paths into a gzip-compressed tar archive.
archive::compress-tar-gzip() { [[ "$#" -ge 1 ]] || return 64; local output='' paths=() path=''; while [[ "$#" -gt 0 ]]; do if [[ "$1" == '-Output' ]]; then [[ "$#" -ge 2 ]] || return 64; output="$2"; shift 2; else paths+=("$1"); shift; fi; done; [[ "${#paths[@]}" -gt 0 ]] || return 64; [[ -n "$output" ]] || output="${paths[0]}.tar.gz"; command -v tar >/dev/null 2>&1 || return 69; tar -czf "$output" "${paths[@]}"; }

### Run diff for two directories.
diff::directories() { [[ "$#" -eq 2 && -d "$1" && -d "$2" ]] || return 64; command -v diff >/dev/null 2>&1 || return 69; diff -uprN -- "$1" "$2"; }

### Run a Git command in a working directory.
git::_run-in-directory() { [[ "$#" -ge 2 && -d "$1" ]] || return 64; local directory="$1"; shift; command git -C "$directory" "$@"; }

### Clone a repository with depth one.
git::clone-shallow() { [[ "$#" -ge 1 && "$#" -le 4 ]] || return 64; local url="$1" dir='' branch='' args=(); shift; while [[ "$#" -gt 0 ]]; do case "$1" in -Branch) [[ "$#" -ge 2 ]] || return 64; branch="$2"; shift 2 ;; *) [[ -z "$dir" ]] || return 64; dir="$1"; shift ;; esac; done; args=(clone --depth 1); [[ -n "$branch" ]] && args+=(--branch "$branch"); args+=("$url"); [[ -n "$dir" ]] && args+=("$dir"); command git "${args[@]}"; }

### Abort an in-progress rebase.
git::rebase-abort() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" rebase --abort; }

### Continue an in-progress rebase.
git::rebase-continue() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" rebase --continue; }

### Amend the last commit without changing its message.
git::commit::amend() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" commit --amend --no-edit; }

### Create a commit with a message.
git::commit::create() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" commit -m "$1"; }

### Remove the last commit while keeping its changes staged.
git::commit::uncommit() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" reset --soft HEAD^; }

### Write the current branch name.
git::branch::current() { [[ "$#" -le 1 ]] || return 64; local branch=''; branch="$(git::_run-in-directory "${1:-.}" symbolic-ref --quiet --short HEAD 2>/dev/null)" || return 1; [[ -n "$branch" ]] && printf '%s\n' "$branch"; }

### Create a branch at a starting revision.
git::branch::create() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" branch "$1" "${2:-HEAD}"; }

### List local and remote-tracking branches.
git::branch::list() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" branch -a; }

### Show file names changed between two revisions.
git::diff::files() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" diff --name-only "$1" "${2:-HEAD}"; }

### Show a patch between two revisions.
git::diff::patch() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" diff "$1" "${2:-HEAD}"; }

### Show the patch for uncommitted tracked changes.
git::diff::uncommitted-patch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" diff HEAD; }

### Show file names changed by uncommitted tracked changes.
git::diff::uncommitted-files() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" diff --name-only HEAD; }

### Show the patch introduced by the latest commit.
git::diff::latest-patch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" show --format= --patch HEAD; }

### Show file names changed by the latest commit.
git::diff::latest-files() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" show --format= --name-only HEAD; }

### Show the unified patch introduced by a commit.
git::commit::patch() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; local revision="$1" remote="${2:-origin}" directory="${3:-.}"; git::_run-in-directory "$directory" cat-file -e "${revision}^{commit}" 2>/dev/null || git::_run-in-directory "$directory" fetch "$remote" "$revision" || return 69; local parent='' empty_tree=''; parent="$(git::_run-in-directory "$directory" rev-list --parents -n 1 "$revision" | awk '{print $2}')"; if [[ -n "$parent" ]]; then git::_run-in-directory "$directory" diff "$parent" "$revision"; else empty_tree="$(git::_run-in-directory "$directory" mktree </dev/null)" || return 75; git::_run-in-directory "$directory" diff "$empty_tree" "$revision"; fi; }

### Revert a commit without creating a commit.
git::commit::revert-without-commit() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" revert --no-commit "${1:-HEAD}"; }

### Revert a commit and create the revert commit.
git::commit::revert() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" revert "${1:-HEAD}"; }

### Fetch one remote or all remotes.
git::fetch() { [[ "$#" -le 2 ]] || return 64; local remote="${1:-}" directory="${2:-.}"; if [[ -n "$remote" ]]; then git::_run-in-directory "$directory" fetch "$remote"; else git::_run-in-directory "$directory" fetch --all; fi; }

### Convert a shallow clone to a complete clone.
git::fetch-unshallow() { [[ "$#" -le 2 ]] || return 64; local remote="${1:-origin}" directory="${2:-.}"; git::_run-in-directory "$directory" fetch "$remote" --unshallow; }

### Show a stash patch.
git::stash::patch() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash show --patch "${1:-stash@{0}}"; }

### Stash working-tree changes with an optional message.
git::stash::push() { [[ "$#" -le 2 ]] || return 64; local directory="${2:-.}"; if [[ -n "${1:-}" ]]; then git::_run-in-directory "$directory" stash push -m "$1"; else git::_run-in-directory "$directory" stash push; fi; }

### Apply and remove a stash.
git::stash::pop() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash pop "${1:-stash@{0}}"; }

### Delete a stash.
git::stash::drop() { [[ "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" stash drop "${1:-stash@{0}}"; }

### Reset a working tree to a revision.
git::reset() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; git::_run-in-directory "${2:-.}" reset "$1"; }

### Pull a branch using rebase.
git::pull-rebase() { [[ "$#" -le 3 ]] || return 64; local branch="${1:-}" remote="${2:-}" directory="${3:-.}" args=(pull --rebase); [[ -n "$remote" ]] && args+=("$remote"); [[ -n "$branch" ]] && args+=("$branch"); git::_run-in-directory "$directory" "${args[@]}"; }

### Cherry-pick a revision, fetching it when necessary.
git::cherry-pick() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; local revision="$1" remote="${2:-origin}" directory="${3:-.}"; git::_run-in-directory "$directory" cat-file -e "${revision}^{commit}" 2>/dev/null || git::_run-in-directory "$directory" fetch "$remote" "$revision" || return 69; git::_run-in-directory "$directory" cherry-pick "$revision"; }

### Continue an in-progress cherry-pick.
git::cherry-pick-continue() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" cherry-pick --continue; }

### Abort an in-progress cherry-pick.
git::cherry-pick-abort() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" cherry-pick --abort; }

### Push a branch to a remote.
git::push() { [[ "$#" -le 3 ]] || return 64; local branch="${1:-}" remote="${2:-}" directory="${3:-.}" args=(push); [[ -n "$remote" ]] && args+=("$remote"); [[ -n "$branch" ]] && args+=("$branch"); git::_run-in-directory "$directory" "${args[@]}"; }

### Push a branch for review.
gerrit::push-review() { [[ "$#" -le 3 ]] || return 64; git::push "${1:-HEAD:refs/for/main}" "${2:-origin}" "${3:-.}"; }

### Push a work-in-progress branch for review.
gerrit::push-review-wip() { [[ "$#" -le 3 ]] || return 64; local branch="${1:-HEAD:refs/for/main%wip}"; git::push "$branch" "${2:-origin}" "${3:-.}"; }

### Delete a branch from a remote.
git::remote::delete-branch() { [[ "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" push "${2:-origin}" --delete "$1"; }

### Update all submodules recursively.
git::submodule::update-all() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" submodule update --init --recursive; }

### Discard all changes in a working tree.
git::commit::discard() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" reset --hard HEAD; git::_run-in-directory "${1:-.}" clean -fd; }

### Fetch a remote and reset its remote-tracking branch.
git::reset-remote() { [[ "$#" -le 2 ]] || return 64; local remote="${1:-origin}" directory="${2:-.}"; git::_run-in-directory "$directory" fetch "$remote"; git::_run-in-directory "$directory" reset --hard "$remote/$(git::branch::current "$directory")"; }

### Pull the configured base branch with fast-forward-only semantics.
git::pull-base-branch() { [[ "$#" -le 2 ]] || return 64; local base="${1:-main}" directory="${2:-.}" current=''; current="$(git::branch::current "$directory")" || return 65; git::_run-in-directory "$directory" switch "$base" || return "$?"; if ! git::_run-in-directory "$directory" pull --ff-only origin "$base"; then git::_run-in-directory "$directory" switch "$current" >/dev/null 2>&1 || true; return 75; fi; git::_run-in-directory "$directory" switch "$current" || return 75; git::_run-in-directory "$directory" rebase "$base"; }

### Import simple KEY=VALUE entries from a dotenv file.
env::dotenv::import() { [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64; local line key value; while IFS= read -r line || [[ -n "$line" ]]; do [[ -z "$line" || "$line" == \#* ]] && continue; [[ "$line" == *=* ]] || return 64; key="${line%%=*}"; value="${line#*=}"; [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 64; if [[ "$value" == \"*\" && "$value" == *\" ]]; then value="${value:1:${#value}-2}"; fi; export "${key}=${value}"; done <"$1"; }

### Set an environment variable for the current shell.
env::set-variable() { [[ "$#" -ge 2 && "$#" -le 3 && "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 64; local name="$1" value="$2" shells="${3:-bash,zsh}" shell rc escaped; export "${name}=${value}"; escaped="${value//\'/\'\\\'\'}"; IFS=',' read -r -a _util_shells <<<"$shells"; for shell in "${_util_shells[@]}"; do case "$shell" in bash) rc="$HOME/.bashrc" ;; zsh) rc="$HOME/.zshrc" ;; *) return 64 ;; esac; file::replace-text-or-append "$rc" "^export ${name}=" "export ${name}='${escaped}'" 2>/dev/null || file::append-text "$rc" "export ${name}='${escaped}'\n" || return "$?"; done; }

### Add a directory to PATH without creating duplicates.
env::add-path() { [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" ]] || return 64; local path="$1" shells="${2:-bash,zsh}" shell rc line; case ":${PATH:-}:" in *":$path:"*) ;; *) PATH="${PATH:+${PATH}:}${path}"; export PATH ;; esac; IFS=',' read -r -a _util_shells <<<"$shells"; for shell in "${_util_shells[@]}"; do case "$shell" in bash) rc="$HOME/.bashrc" ;; zsh) rc="$HOME/.zshrc" ;; *) return 64 ;; esac; line="export PATH=\"\${PATH:+\${PATH}:}${path}\""; file::contains-match "$rc" "^export PATH=.*${path//./\\.}.*$" 2>/dev/null || file::append-text "$rc" "${line}\n" || return "$?"; done; }

### Register a dotenv file in selected shell startup files.
env::dotenv::register() { [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" && ! -L "$1" ]] || return 64; local file="$1" shells="${2:-bash,zsh}" shell rc line; IFS=',' read -r -a _util_shells <<<"$shells"; for shell in "${_util_shells[@]}"; do case "$shell" in bash) rc="$HOME/.bashrc" ;; zsh) rc="$HOME/.zshrc" ;; *) return 64 ;; esac; line="env::dotenv::import '$file'"; file::contains-match "$rc" "^${line//./\\.}$" 2>/dev/null || file::append-text "$rc" "${line}\n" || return "$?"; done; }

### Create a symbolic link in a user's local bin directory.
symlink::create-in-local-bin() { [[ "$#" -ge 1 && "$#" -le 3 && -e "$1" ]] || return 64; local source="$1" name="${2:-$(basename -- "$1")}" directory="${3:-$HOME/.local/bin}"; mkdir -p -- "$directory" || return 74; symlink::create "$source" "$directory/$name"; }

### Prepare an SSH directory with restrictive permissions.
ssh::setup-directory() { [[ "$#" -eq 0 ]] || return 64; mkdir -p -- "$HOME/.ssh" || return 74; chmod 700 -- "$HOME/.ssh" || return 74; }

### Replace one marker-managed SSH Host block and validate the resulting configuration.
ssh::config::_write-block() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  local file="$1" pattern="$2" options="$3" begin='' end='' line='' content='' preserved='' old_content='' keys='' option='' key='' validation_host='localhost' token=''
  [[ -f "$file" && ! -L "$file" ]] || return 66
  [[ "$pattern" != *$'\n'* && "$pattern" != *$'\r'* ]] || return 64
  [[ "$options" != *$'\r'* ]] || return 64
  command -v ssh >/dev/null 2>&1 || return 69
  old_content="$(<"$file")"
  while IFS= read -r option || [[ -n "$option" ]]; do
    [[ "$option" == '  '* ]] || continue
    key="${option#  }"
    key="${key%% *}"
    keys+="|$key|"
  done <<<"$options"
  begin="# bashstock: begin $pattern"
  end='# bashstock: end'
  local in_block=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$begin" ]]; then
      in_block=1
      continue
    fi
    if ((in_block)); then
      [[ "$line" == "$end" ]] && in_block=0
      if ((in_block)) && [[ "$line" == '  '* ]]; then
        key="${line#  }"
        key="${key%% *}"
        [[ "$keys" == *"|$key|"* ]] && continue
        preserved+="$line"$'\n'
      fi
      continue
    fi
    content+="$line"$'\n'
  done <"$file"
  local block=''
  block="$begin"$'\n'"Host $pattern"$'\n'
  block+="$preserved$options"$'\n'"$end"$'\n'
  file::write-text "$file" "$block$content" || return "$?"
  local pattern_parts=()
  read -r -a pattern_parts <<<"$pattern"
  for token in "${pattern_parts[@]}"; do
    [[ "$token" == '!'* ]] && continue
    validation_host="$token"
    break
  done
  if ! ssh -G -F "$file" "$validation_host" >/dev/null 2>&1; then
    file::write-text "$file" "$old_content" >/dev/null 2>&1 || true
    return 65
  fi
}

### Update one key in a marker-managed SSH Host block.
ssh::config::update() {
  [[ "$#" -eq 4 && -n "$1" && -n "$2" && "$3" =~ ^[A-Za-z][A-Za-z0-9]*$ && -n "$4" ]] || return 64
  [[ "$4" != *$'\n'* && "$4" != *$'\r'* ]] || return 64
  ssh::config::_write-block "$1" "$2" "  $3 $4"
}

### Create an SSH configuration file when necessary and update one key.
ssh::config::set() {
  [[ "$#" -eq 4 && -n "$1" ]] || return 64
  [[ ! -L "$1" ]] || return 64
  if [[ -e "$1" && ! -f "$1" ]]; then return 66; fi
  if [[ ! -e "$1" ]]; then
    mkdir -p -- "$(path::directory-name "$1")" || return 74
    : >"$1" || return 74
  fi
  ssh::config::update "$@"
}

### Enable AddKeysToAgent for an optional SSH Host pattern.
ssh::config::enable-auto-add-keys() {
  [[ "$#" -le 2 ]] || return 64
  local file='' pattern=''
  if [[ "$#" -ge 1 ]]; then file="$1"; else file="$HOME/.ssh/config"; fi
  if [[ "$#" -ge 2 ]]; then pattern="$2"; else pattern='*'; fi
  ssh::config::set "$file" "$pattern" AddKeysToAgent yes
}

### Disable SSH host-key checks for an optional Host pattern.
###
### Normal use should register the correct host key in known_hosts instead.
ssh::config::disable-host-key-checking() {
  [[ "$#" -le 2 ]] || return 64
  local file='' pattern=''
  if [[ "$#" -ge 1 ]]; then file="$1"; else file="$HOME/.ssh/config"; fi
  if [[ "$#" -ge 2 ]]; then pattern="$2"; else pattern='*'; fi
  [[ ! -L "$file" ]] || return 64
  if [[ -e "$file" && ! -f "$file" ]]; then return 66; fi
  if [[ ! -e "$file" ]]; then
    mkdir -p -- "$(path::directory-name "$file")" || return 74
    : >"$file" || return 74
  fi
  ssh::config::_write-block "$file" "$pattern" $'  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null'
}

### List regular files that ssh-keygen can read as private keys.
ssh::key::private-files() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' path=''
  if [[ "$#" -ge 1 ]]; then directory="$1"; else directory="$HOME/.ssh"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  command -v ssh-keygen >/dev/null 2>&1 || return 69
  (
    shopt -s nullglob dotglob
    for path in "$directory"/*; do
      [[ -f "$path" && ! -L "$path" ]] || continue
      ssh-keygen -y -f "$path" </dev/null >/dev/null 2>&1 && printf '%s\n' "$path"
    done
    :
  )
}

### Add one private key to ssh-agent.
ssh::key::add() {
  [[ "$#" -eq 1 && -f "$1" && ! -L "$1" ]] || return 64
  command -v ssh-add >/dev/null 2>&1 || return 69
  ssh-add "$1"
}

### Add every detected private key in a directory to ssh-agent.
ssh::key::add-all() {
  [[ "$#" -le 1 ]] || return 64
  local directory='' path='' status=0
  if [[ "$#" -ge 1 ]]; then directory="$1"; else directory="$HOME/.ssh"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  command -v ssh-add >/dev/null 2>&1 || return 69
  while IFS= read -r path; do
    ssh::key::add "$path" || status="$?"
  done < <(ssh::key::private-files "$directory") || return "$?"
  return "$status"
}

### Add every detected private key in a directory to ssh-agent.
ssh::key::add-all-private-keys() { ssh::key::add-all "$@"; }

### Ping a host a bounded number of times.
net::ping() { [[ "$#" -ge 0 && "$#" -le 3 ]] || return 64; local host="${1:-127.0.0.1}" attempts="${2:-1}" timeout="${3:-1}"; [[ "$attempts" =~ ^[1-9][0-9]*$ && "$timeout" =~ ^[1-9][0-9]*$ ]] || return 64; command -v ping >/dev/null 2>&1 || return 69; case "$(system::operating-system)" in darwin) ping -c "$attempts" -W $((timeout*1000)) "$host" ;; *) ping -c "$attempts" -W "$timeout" "$host" ;; esac; }

### Disable all active swap devices.
swap::disable-all() { [[ "$#" -eq 0 ]] || return 64; command -v swapoff >/dev/null 2>&1 || return 69; swapoff -a; }

### Remove swap files below a directory.
swap::remove-all-files() { [[ "$#" -le 1 ]] || return 64; local directory="${1:-/}" path=''; while IFS= read -r -d '' path; do rm -f -- "$path" || return 74; done < <(find "$directory" -type f -name '*.swap' -print0 2>/dev/null); }

### Create a swap file of a requested size.
swap::create() { [[ "$#" -ge 1 && "$#" -le 2 && "$1" =~ ^[1-9][0-9]*$ ]] || return 64; local size="$1" path="${2:-/swapfile}"; command -v fallocate >/dev/null 2>&1 || return 69; fallocate -l "$size" "$path" || return 74; chmod 600 -- "$path" || return 74; command -v mkswap >/dev/null 2>&1 || return 69; mkswap "$path" >/dev/null || return 74; swapon "$path"; }

### List active swap devices.
swap::list() { [[ "$#" -eq 0 ]] || return 64; command -v swapon >/dev/null 2>&1 || return 69; swapon --show; }

### Find paths whose basename matches an expression.
path::find() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; local expression="$1" directory="${2:-.}"; [[ -d "$directory" ]] || return 66; find "$directory" -name "$expression" -print; }

### Print a directory tree with the contents of text files.
file::tree-with-contents() { [[ "$#" -le 3 ]] || return 64; local path="${1:-.}" min="${2:-0}" max="${3:-}" file=''; local tree_args=("$path"); [[ -e "$path" && "$min" =~ ^[0-9]+$ ]] || return 64; tree_args+=(-mindepth "$min"); [[ -z "$max" || "$max" =~ ^[0-9]+$ ]] || return 64; [[ -z "$max" ]] || tree_args+=(-maxdepth "$max"); find "${tree_args[@]}" -print; while IFS= read -r -d '' file; do file::_require-no-nul "$file" 2>/dev/null || continue; printf '\n--- %s ---\n' "$file"; cat -- "$file"; done < <(find "$path" -type f -print0); }

### Print a text file without changing its contents.
file::_print-text() { [[ "$#" -eq 1 ]] || return 64; file::_require-existing "$1" || return "$?"; cat -- "$1"; }

# shellcheck disable=SC2329
### Test whether a TCP endpoint accepts a connection.
net::tcp::test() {
  [[ "$#" -ge 2 && "$#" -le 3 && -n "$1" && "$2" =~ ^[0-9]+$ ]] || return 64
  local timeout="${3:-5}"
  [[ "${timeout}" =~ ^[1-9][0-9]*$ ]] || return 64
  command -v nc >/dev/null 2>&1 || return 69
  nc -z -w "${timeout}" "$1" "$2"
}

### Open a serial device with a configured baud rate.
serial::configure() { [[ "$#" -ge 1 && "$#" -le 2 && -e "$1" ]] || return 64; local device="$1" baud="${2:-115200}"; command -v stty >/dev/null 2>&1 || return 69; stty -F "$device" "$baud" 2>/dev/null || stty -f "$device" "$baud"; }

### Write literal data to a serial device.
serial::write() { [[ "$#" -eq 2 && -e "$1" ]] || return 64; printf '%s' "$2" >"$1"; }

### Write a command and terminator to a serial device.
serial::write-command() { [[ "$#" -ge 2 && "$#" -le 4 && -e "$1" ]] || return 64; local device="$1" data="$2" terminator="${3:-cr}" wait="${4:-0}" suffix=''; case "$terminator" in none) suffix='' ;; cr) suffix=$'\r' ;; lf) suffix=$'\n' ;; crlf) suffix=$'\r\n' ;; *) return 64 ;; esac; printf '%s%s' "$data" "$suffix" >"$device" || return 74; [[ "$wait" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 64; [[ "$wait" == 0 ]] || sleep "$wait"; }

### Open a named screen session attached to a serial device.
screen::open-serial() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; local device="$1" baud="${2:-115200}" log="${3:-}"; serial::configure "$device" "$baud" || return "$?"; command -v screen >/dev/null 2>&1 || return 69; if [[ -n "$log" ]]; then screen -L -Logfile "$log" "$device" "$baud"; else screen "$device" "$baud"; fi; }

### Terminate every GNU Screen session.
screen::kill-all() { [[ "$#" -eq 0 ]] || return 64; command -v screen >/dev/null 2>&1 || return 69; screen -ls 2>/dev/null | awk '/[0-9]+\./ {print $1}' | while IFS= read -r session; do screen -S "$session" -X quit; done; }

### Run an external command while preserving its output and status.
util::_run-command() { [[ "$#" -ge 1 ]] || return 64; command -v "$1" >/dev/null 2>&1 || return 69; local command_name="$1"; shift; command "$command_name" "$@"; }

### Capture packets addressed to a host.
net::capture-host() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; local host="$1" interface="${2:-any}"; if tcpdump -i "$interface" host "$host" 2>/dev/null; then return 0; fi; command -v sudo >/dev/null 2>&1 || return 69; sudo tcpdump -i "$interface" host "$host"; }

### Write a TCP port selected by the operating system.
net::unused-port() { [[ "$#" -eq 0 ]] || return 64; command -v perl >/dev/null 2>&1 || return 69; perl -MSocket -e 'socket(my $s,PF_INET,SOCK_STREAM,getprotobyname("tcp")) or exit 69; bind($s,sockaddr_in(0,inet_aton("127.0.0.1"))) or exit 69; print (sockaddr_in(getsockname($s)))[0],"\n";' 2>/dev/null; }

### Release processes holding a serial device.
serial::release() { [[ "$#" -ge 1 && "$#" -le 2 && -e "$1" ]] || return 64; file::release "$@"; }

### Initialize a repo manifest checkout.
repo::init() { [[ "$#" -ge 3 && "$#" -le 4 ]] || return 64; util::_run-command repo init -u "$1" -b "$2" -m "$3" "${4:+--repo-url="$4"}"; }

### Synchronize a repo checkout.
repo::sync() { [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64; local path="$1" jobs="${2:-}" directory="${3:-.}"; (cd "$directory" && if [[ -n "$jobs" ]]; then util::_run-command repo sync "$path" -j "$jobs"; else util::_run-command repo sync "$path"; fi); }

### Write a repository manifest.
repo::write-manifest() { [[ "$#" -le 2 ]] || return 64; local output="${1:-}" directory="${2:-.}"; (cd "$directory" && if [[ -n "$output" ]]; then util::_run-command repo manifest -r -o "$output"; else util::_run-command repo manifest -r; fi); }

### Check a repository checkout.
repo::check() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && util::_run-command repo status); }

### List running Docker containers.
docker::container::list-running() { [[ "$#" -eq 0 ]] || return 64; util::_run-command docker ps; }

### List Docker containers.
docker::container::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command docker ps -a; }

### Copy files between a Docker container and the host.
docker::container::pull() { [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64; local container="$1" source="$2" destination="${3:-.}"; util::_run-command docker cp "$container:$source" "$destination"; }
### Execute the utility function.
docker::container::push() { [[ "$#" -ge 2 && "$#" -le 3 ]] || return 64; local container="$1" source="$2" destination="${3:-/}"; util::_run-command docker cp "$source" "$container:$destination"; }

### Open a shell or command in a Docker container.
docker::container::shell() { [[ "$#" -ge 1 ]] || return 64; local container="$1"; shift; if [[ "$#" -eq 0 ]]; then util::_run-command docker exec -it "$container" sh; else util::_run-command docker exec -it "$container" "$@"; fi; }

### Show Docker container logs.
docker::container::logs() { [[ "$#" -eq 1 ]] || return 64; util::_run-command docker logs "$1"; }
### Execute the utility function.
docker::container::stop() { [[ "$#" -eq 1 ]] || return 64; util::_run-command docker stop "$1"; }
### Execute the utility function.
docker::container::start() { [[ "$#" -eq 1 ]] || return 64; util::_run-command docker start "$1"; }
### Execute the utility function.
docker::container::stop-all() { [[ "$#" -eq 0 ]] || return 64; local ids=(); read -r -a ids <<<"$(docker ps -q)"; [[ "${#ids[@]}" -eq 0 ]] || util::_run-command docker stop "${ids[@]}"; }
### Execute the utility function.
docker::container::remove-all() { [[ "$#" -eq 0 ]] || return 64; local ids=(); read -r -a ids <<<"$(docker ps -aq)"; [[ "${#ids[@]}" -eq 0 ]] || util::_run-command docker rm "${ids[@]}"; }
### Execute the utility function.
docker::volume::remove-all() { [[ "$#" -eq 0 ]] || return 64; util::_run-command docker volume prune -f; }
### Execute the utility function.
docker::remove-all() { [[ "$#" -eq 0 ]] || return 64; docker::container::stop-all; docker::container::remove-all; docker::volume::remove-all; }

### Run an ADB command with an optional serial number.
adb::_run() { [[ "$#" -ge 1 ]] || return 64; local serial='' args=() value=''; while [[ "$#" -gt 0 ]]; do if [[ "$1" == '-Serial' ]]; then [[ "$#" -ge 2 ]] || return 64; serial="$2"; shift 2; else args+=("$1"); shift; fi; done; [[ -n "$serial" ]] && args=(-s "$serial" "${args[@]}"); util::_run-command adb "${args[@]}"; }
### Wait for an ADB device to connect, optionally selected with -Serial.
adb::device::wait() { adb::_run wait-for-device "$@"; }
### Copy files from an ADB device to the host.
adb::device::pull() { [[ "$#" -ge 1 ]] || return 64; adb::_run pull "$@"; }
### Copy files from the host to an ADB device.
adb::device::push() { [[ "$#" -ge 1 ]] || return 64; adb::_run push "$@"; }
### Clear the selected device log buffers.
adb::logcat::clear() { adb::_run logcat -c "$@"; }
### Write the selected device log buffers once.
adb::logcat::once() { adb::_run logcat -d "$@"; }
### Stream logs from the selected device.
adb::logcat::continuous() { adb::_run logcat "$@"; }
### Reboot the selected device.
adb::device::reboot() { adb::_run reboot "$@"; }
### Write the first connected ADB device serial.
adb::device::first() { [[ "$#" -eq 0 ]] || return 64; adb devices | awk 'NR>1 && $2=="device" {print $1; exit}'; }
### List ADB devices and their connection details.
adb::device::list() { [[ "$#" -eq 0 ]] || return 64; adb::_run devices -l; }
### Wait up to TIMEOUT_SECONDS for a path on the device; return 75 on timeout.
adb::device::wait-for-path() {
  [[ "$#" -ge 1 && "$#" -le 3 ]] || return 64
  local path="$1" timeout="${2:-30}" start=''
  start="$(date +%s)" || return 74
  while (( $(date +%s) - start < timeout )); do
    adb::_run shell test -e "$path" >/dev/null 2>&1 && return 0
    sleep 1 || return 74
  done
  return 75
}
### Save a device screenshot to OUTPUT_PATH, which defaults to screen.png.
adb::device::screen::capture-once() { [[ "$#" -le 2 ]] || return 64; local output="${1:-screen.png}"; adb::_run exec-out screencap -p >"$output"; }
### Copy the requested device path to the host.
adb::device::select-and-pull() { [[ "$#" -ge 1 ]] || return 64; adb::_run pull "$@"; }
### Request bootloader unlocking through ADB.
adb::device::bootloader::unlock() { adb::_run oem unlock "$@"; }
### Disable dm-verity on the selected device.
adb::device::verity::disable() { adb::_run disable-verity "$@"; }
### Remount the selected device partitions.
adb::device::partition::remount() { adb::_run remount "$@"; }
### Write the selected device build fingerprint.
adb::device::build::fingerprint() { adb::_run shell getprop ro.build.fingerprint "$@"; }
### Write the selected device build timestamp as Unix seconds.
adb::device::build::date() { adb::_run shell getprop ro.build.date.utc "$@"; }
### Write the selected device active slot suffix.
adb::device::slot::suffix() { adb::_run shell getprop ro.boot.slot_suffix "$@"; }
### Write the selected device kernel release.
adb::device::build::kernel-version() { adb::_run shell uname -r "$@"; }
### Save repeated screenshots; MAX_COUNT of zero runs until interrupted.
adb::device::screen::capture-continuous() { [[ "$#" -le 4 ]] || return 64; local directory="${1:-.}" interval="${2:-1}" max="${3:-0}" index=0; mkdir -p -- "$directory" || return 74; while [[ "$max" -eq 0 || "$index" -lt "$max" ]]; do adb::device::screen::capture-once "$directory/screen-${index}.png" "${4:-}" || return "$?"; index=$((index+1)); sleep "$interval" || return 74; done; }
### Write a device partition SHA-256 checksum.
adb::device::partition::sha256() { [[ "$#" -ge 1 ]] || return 64; adb::_run shell sha256sum "$1"; }
### Keep the selected device awake while charging.
adb::wake::lock() { adb::_run shell svc power stayon true "$@"; }
### Restore the selected device normal sleep behavior.
adb::wake::unlock() { adb::_run shell svc power stayon false "$@"; }
### Show the selected device power and wake lock state.
adb::wake::list() { adb::_run shell dumpsys power "$@"; }

### Execute the process::ids-by-name utility.
process::ids-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; util::_run-command pgrep -x "$1"; }

### Execute the process::ids-by-name-regex utility.
process::ids-by-name-regex() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; util::_run-command pgrep -f "$1"; }

### Execute the process::threads-by-pid utility.
process::threads-by-pid() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; util::_run-command ps -M "$1"; }

### Execute the process::threads-by-name utility.
process::threads-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; local pids=''; pids="$(process::ids-by-name "$1")" || return "$?"; local id; while IFS= read -r id; do process::threads-by-pid "$id"; done <<<"$pids"; }

### Execute the syscall::trace-by-pid utility.
syscall::trace-by-pid() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; if command -v strace >/dev/null 2>&1; then strace -p "$1"; elif command -v dtruss >/dev/null 2>&1; then sudo dtruss -p "$1"; else return 69; fi; }

### Execute the lib::trace-by-pid utility.
lib::trace-by-pid() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; if command -v ltrace >/dev/null 2>&1; then ltrace -p "$1"; else return 69; fi; }

### Execute the gdb::attach-pid utility.
gdb::attach-pid() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; util::_run-command gdb -q -p "$1"; }

### Execute the gdb::server::start utility.
gdb::server::start() { [[ "$#" -ge 2 && "$2" =~ ^[0-9]+$ ]] || return 64; util::_run-command gdbserver ":$1" "$2" "${@:3}"; }

### Execute the gdb::connect utility.
gdb::connect() { [[ "$#" -eq 3 && -f "$1" && "$3" =~ ^[0-9]+$ ]] || return 64; util::_run-command gdb "$1" -ex "target remote $2:$3"; }

### Execute the gdb::run-until utility.
gdb::run-until() { [[ "$#" -ge 2 ]] || return 64; util::_run-command gdb "$1" -ex "break $2" -ex run "${@:3}"; }

### Execute the gdb::core::open utility.
gdb::core::open() { [[ "$#" -eq 2 && -f "$1" && -f "$2" ]] || return 64; util::_run-command gdb "$1" "$2"; }

### Execute the device-tree::node::list utility.
device-tree::node::list() { [[ "$#" -eq 0 ]] || return 64; [[ -d /sys/firmware/devicetree/base ]] || return 66; find /sys/firmware/devicetree/base -mindepth 1 -print; }

### Execute the i2c::bus::list utility.
i2c::bus::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command i2cdetect -l; }

### Execute the i2c::device::list utility.
i2c::device::list() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; util::_run-command i2cdetect -y "$1"; }

### Execute the gpio::chip::list utility.
gpio::chip::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command gpiochip list; }

### Execute the gpio::line::list utility.
gpio::line::list() { [[ "$#" -le 1 ]] || return 64; local args=(line); [[ -n "${1:-}" ]] && args+=("${1}"); util::_run-command gpioinfo "${args[@]}"; }

### Execute the usb::device::list utility.
usb::device::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command lsusb; }

### Execute the pci::device::list utility.
pci::device::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command lspci; }

### Execute the asciidoc::html utility.
asciidoc::html() { [[ "$#" -ge 1 && "$#" -le 2 ]] || return 64; local input="$1" output="${2:-}"; local args=(-b html5); [[ -n "$output" ]] && args+=(-D "$output"); args+=("$input"); util::_run-command asciidoctor "${args[@]}"; }

### Execute the flutter::run-chrome-release utility.
flutter::run-chrome-release() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && util::_run-command flutter run --release -d chrome); }

### Execute the flutter::run-linux-release utility.
flutter::run-linux-release() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && util::_run-command flutter run --release -d linux); }

### Execute the flutter::test utility.
flutter::test() { [[ "$#" -ge 0 ]] || return 64; local directory='.'; [[ "$#" -gt 0 && -d "$1" ]] && { directory="$1"; shift; }; (cd "$directory" && util::_run-command flutter test "$@"); }

### Execute the flutter::coverage utility.
flutter::coverage() { [[ "$#" -le 2 ]] || return 64; local output="${1:-coverage/lcov.info}" directory="${2:-.}"; (cd "$directory" && util::_run-command flutter test --coverage); [[ -f "$directory/coverage/lcov.info" ]] && cp "$directory/coverage/lcov.info" "$output"; }

### Execute the systemd::file utility.
systemd::file() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl cat "$1"; }

### Execute the systemd::dependencies utility.
systemd::dependencies() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl list-dependencies "$1"; }

### Execute the systemd::restart utility.
systemd::restart() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl restart "$1"; }

### Execute the systemd::start utility.
systemd::start() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl start "$1"; }

### Execute the systemd::stop utility.
systemd::stop() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl stop "$1"; }

### Execute the systemd::enable utility.
systemd::enable() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl enable "$1"; }

### Execute the systemd::disable utility.
systemd::disable() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl disable "$1"; }

### Execute the systemd::status utility.
systemd::status() { [[ "$#" -eq 1 ]] || return 64; util::_run-command systemctl status "$1"; }

### Execute the systemd::service::list utility.
systemd::service::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-units --type=service; }

### Execute the systemd::service::list-running utility.
systemd::service::list-running() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-units --type=service --state=running; }

### Execute the systemd::service::list-failed utility.
systemd::service::list-failed() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-units --type=service --state=failed; }

### Execute the systemd::service::list-files utility.
systemd::service::list-files() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl list-unit-files --type=service; }

### Execute the gpg::decrypt utility.
gpg::decrypt() { [[ "$#" -eq 1 && -f "$1" ]] || return 64; util::_run-command gpg --decrypt "$1"; }

### Execute the gpg::public-key::armor utility.
gpg::public-key::armor() { [[ "$#" -le 1 ]] || return 64; local args=(--armor --export); [[ -n "${1:-}" ]] && args+=("$1"); util::_run-command gpg "${args[@]}"; }

### Execute the gpg::secret-key::fingerprints utility.
gpg::secret-key::fingerprints() { [[ "$#" -eq 0 ]] || return 64; util::_run-command gpg --list-secret-keys --with-colons; }

### Execute the gpg::secret-key::list utility.
gpg::secret-key::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command gpg --list-secret-keys; }

### Execute the user::directory::create-english-links utility.
user::directory::create-english-links() { [[ "$#" -le 1 ]] || return 64; local directory="${1:-$HOME}"; [[ -d "$directory" ]] || return 66; local name target; for name in Desktop Documents Downloads Music Pictures Videos; do target="$directory/$name"; [[ -e "$target" ]] || ln -s "$directory/$name" "$target" 2>/dev/null || true; done; }

### Write available stable Android Build Tools versions in ascending order.
### Use Android CLI when available, otherwise use sdkmanager.
android::build-tools::versions() {
  [[ "$#" -eq 0 ]] || return 64
  command::require perl || return "$?"
  local listing='' versions=''
  local arguments=(--no-metrics)
  if command -v android >/dev/null 2>&1; then
    [[ -z "${ANDROID_HOME:-}" ]] || arguments+=("--sdk=${ANDROID_HOME}")
    listing="$(android "${arguments[@]}" sdk list 'build-tools/*' --all --all-versions)" || return "$?"
  else
    command::require sdkmanager || return "$?"
    listing="$(sdkmanager --list --channel=0)" || return "$?"
  fi
  versions="$(printf '%s\n' "${listing}" | perl -ne '
    print "$1\n" if /^\s*build-tools;([0-9]+\.[0-9]+\.[0-9]+)\s*\|/
      || /^\s*build-tools\/([0-9]+\.[0-9]+\.[0-9]+)\s+[0-9]+\.[0-9]+\.[0-9]+(?=\s|$)/;
  ' | package::_sort-versions)" || return "$?"
  [[ -n "${versions}" ]] || return 1
  printf '%s\n' "${versions}"
}

### Write the newest available stable Android Build Tools version.
android::build-tools::latest-version() {
  [[ "$#" -eq 0 ]] || return 64
  local versions=''
  versions="$(android::build-tools::versions)" || return "$?"
  printf '%s\n' "${versions##*$'\n'}"
}

### Execute the go::version::list utility.
go::version::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command go version; }

### Execute the go::version::latest utility.
go::version::latest() { [[ "$#" -eq 0 ]] || return 64; go::version::list; }

### Write stable Ruby versions that rbenv can install in ascending order.
ruby::version::list() {
  [[ "$#" -eq 0 ]] || return 64
  local rbenv='' versions='' version=''
  rbenv="$(ruby::_rbenv-command)" || return "$?"
  versions="$("${rbenv}" install --list-all 2>/dev/null)" || return 74
  while IFS= read -r version; do
    version="${version#"${version%%[![:space:]]*}"}"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && printf '%s\n' "${version}"
  done <<<"${versions}" | package::_sort-versions
}

### Write the newest stable Ruby version that rbenv can install.
ruby::version::latest() {
  [[ "$#" -eq 0 ]] || return 64
  ruby::version::list | package::_latest-stable-version
}

### Install Rosetta on macOS and accept its license.
rosetta::install() { [[ "$#" -eq 0 ]] || return 64; [[ "$(system::operating-system)" == darwin ]] || return 69; util::_run-command softwareupdate --install-rosetta --agree-to-license; }

### Execute the net::dns::servers utility.
net::dns::servers() { [[ "$#" -eq 0 ]] || return 64; awk '$1=="nameserver" {print $2}' /etc/resolv.conf; }

### Execute the utm::open utility.
utm::open() { [[ "$#" -le 1 ]] || return 64; if [[ "$(system::operating-system)" == darwin ]]; then open -a UTM "${1:-}"; else util::_run-command utm "${1:-}"; fi; }

### Execute the mozc::config::open utility.
mozc::config::open() { [[ "$#" -eq 0 ]] || return 64; util::_run-command mozc_tool; }

### Execute the archive::extract utility.
archive::extract() { [[ "$#" -le 1 ]] || return 64; local path="${1:-.}" file; if [[ -f "$path" ]]; then archive::extract-file "$path"; else while IFS= read -r -d '' file; do archive::extract-file "$file" || return "$?"; done < <(archive::_find "$path"); fi; }

### Execute the syscall::trace-by-name utility.
syscall::trace-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; local pids=''; pids="$(process::ids-by-name "$1")" || return "$?"; local id; while IFS= read -r id; do syscall::trace-by-pid "$id"; done <<<"$pids"; }

### Execute the lib::trace-by-name utility.
lib::trace-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; local pids=''; pids="$(process::ids-by-name "$1")" || return "$?"; local id; while IFS= read -r id; do lib::trace-by-pid "$id"; done <<<"$pids"; }

### Execute the gdb::attach-by-name utility.
gdb::attach-by-name() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; local pid=''; pid="$(process::ids-by-name "$1" | head -n 1)"; [[ -n "$pid" ]] || return 1; gdb::attach-pid "$pid"; }

### Execute the jenkins::restart utility.
jenkins::restart() { [[ "$#" -eq 0 ]] || return 64; util::_run-command systemctl restart jenkins; }

### Execute the sudo::start-keep-alive utility.
sudo::start-keep-alive() { [[ "$#" -eq 0 ]] || return 64; util::_run-command sudo -v; }

### Execute the storage::clear-trash utility.
storage::clear-trash() { [[ "$#" -eq 0 ]] || return 64; local trash="$HOME/.local/share/Trash"; [[ "$(system::operating-system)" == darwin ]] && trash="$HOME/.Trash"; directory::clear "$trash"; }

### Execute the usb::partition::select utility.
usb::partition::select() { [[ "$#" -eq 1 ]] || return 64; util::_run-command fdisk -l "$1"; }

### Execute the usb::filesystem::repair utility.
usb::filesystem::repair() { [[ "$#" -eq 1 ]] || return 64; util::_run-command fsck "$1"; }

### Execute the usb::filesystem::format-fat32 utility.
usb::filesystem::format-fat32() { [[ "$#" -eq 1 ]] || return 64; util::_run-command mkfs.vfat -F 32 "$1"; }

### Execute the git::rebase-base-branch utility.
git::rebase-base-branch() { [[ "$#" -le 3 ]] || return 64; git::_run-in-directory "${3:-.}" rebase "${2:-origin}" "${1:-main}"; }

### Execute the repo::reset utility.
repo::reset() { [[ "$#" -le 1 ]] || return 64; (cd "${1:-.}" && util::_run-command repo forall -c 'git reset --hard && git clean -fd'); }

### Execute the selinux::generate-rule utility.
selinux::generate-rule() { [[ "$#" -ge 1 && "$#" -le 2 && -f "$1" ]] || return 64; local output="${2:-}"; local args=(-a -i "$1"); [[ -n "$output" ]] && args+=(-o "$output"); util::_run-command audit2allow "${args[@]}"; }

### Execute the terminal::gnome-bash utility.
terminal::gnome-bash() { [[ "$#" -ge 0 ]] || return 64; util::_run-command gnome-terminal -- bash "${@}"; }

### Execute the shell::editor::set-default utility.
shell::editor::set-default() { [[ "$#" -ge 1 ]] || return 64; env::set-variable EDITOR "$1"; }

### Set a string value for one top-level key in a macOS property list.
###
### The file is created as an empty dictionary when it does not exist and is
### validated with plutil before and after the change.
plist::set() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && "$2" != *.* && ! -L "$1" ]] || return 64
  command::require plutil || return "$?"
  if [[ ! -e "$1" ]]; then
    mkdir -p -- "$(path::directory-name "$1")" || return 74
    file::write-text "$1" '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
' || return "$?"
  fi
  [[ -f "$1" ]] || return 66
  plutil -lint -s "$1" || return 65
  plutil -replace "$2" -string "$3" "$1" || return 74
  plutil -lint -s "$1" || return 65
}

### Replace or append one top-level scalar field in a textproto file.
###
### Arguments
###
### * FILE - Existing textproto file.
### * FIELD - Field name.
### * VALUE - Literal scalar value written after the field name.
textproto::set-scalar() {
  [[ "$#" -eq 3 && -f "$1" && ! -L "$1" && "$2" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && -n "$3" ]] || return 64
  string::_require-one-line "$3" || return "$?"
  file::replace-text-or-append "$1" "^$2[[:space:]]*:.*$" "$2: $3"
}

### Execute the shell::completion::enable-ignore-case utility.
shell::completion::enable-ignore-case() { [[ "$#" -le 1 ]] || return 64; env::set-variable completion_ignore_case 1; }

### Execute the git::credentials::remove utility.
git::credentials::remove() { [[ "$#" -eq 0 ]] || return 64; git config --global --unset-all credential.helper; }

### Execute the git::config::enable-origin-all-fetch utility.
git::config::enable-origin-all-fetch() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'; }

### Execute the git::config::enable-prune-fetch utility.
git::config::enable-prune-fetch() { [[ "$#" -eq 0 ]] || return 64; git config --global fetch.prune true; }

### Execute the git::config::set-default-branch utility.
git::config::set-default-branch() { [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._/-]+$ ]] || return 64; git config --global init.defaultBranch "$1"; }

### Execute the git::config::enable-rebase-on-pull utility.
git::config::enable-rebase-on-pull() { [[ "$#" -eq 0 ]] || return 64; git config --global pull.rebase true; }

### Execute the git::config::set-email utility.
git::config::set-email() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; git config --global user.email "$1"; }

### Execute the git::config::set-username utility.
git::config::set-username() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; git config --global user.name "$1"; }

### Execute the git::config::set-http-buffer utility.
git::config::set-http-buffer() { [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]] || return 64; git config --global http.postBuffer "$1"; }

### Execute the git::config::use-gpg-credential-store utility.
git::config::use-gpg-credential-store() { [[ "$#" -eq 0 ]] || return 64; git config --global credential.helper 'gpg --decrypt'; }

### Execute the git::config::use-credential-manager utility.
git::config::use-credential-manager() { [[ "$#" -eq 0 ]] || return 64; git config --global credential.helper manager; }

### Execute the pass::store::remove utility.
pass::store::remove() { [[ "$#" -le 1 ]] || return 64; local directory="${1:-$HOME/.password-store}"; [[ -d "$directory" ]] || return 66; directory::clear "$directory"; }

### Execute the pass::store::init utility.
pass::store::init() { [[ "$#" -le 2 ]] || return 64; local fingerprint="${1:-}" directory="${2:-$HOME/.password-store}"; mkdir -p -- "$directory" || return 74; [[ -n "$fingerprint" ]] && printf '%s
' "$fingerprint" >"$directory/.gpg-id" || return 64; }

### Execute the gpg::setup utility.
gpg::setup() { [[ "$#" -ge 0 ]] || return 64; command -v gpg >/dev/null 2>&1 || return 69; gpg --version >/dev/null; }

### Execute the ssh::key::generate-rsa4096 utility.
ssh::key::generate-rsa4096() { [[ "$#" -le 6 ]] || return 64; ssh-keygen -t rsa -b 4096 "$@"; }

### Execute the ssh::key::generate-ed25519 utility.
ssh::key::generate-ed25519() { [[ "$#" -le 6 ]] || return 64; ssh-keygen -t ed25519 "$@"; }

### Execute the ssh::kill-all utility.
ssh::kill-all() { [[ "$#" -eq 0 ]] || return 64; ssh-add -D; }

### Execute the git::config::use-osx-keychain utility.
git::config::use-osx-keychain() { [[ "$#" -eq 0 ]] || return 64; [[ "$(system::operating-system)" == darwin ]] || return 69; git config --global credential.helper osxkeychain; }

### Write the installed Git Credential Manager version.
git-credential-manager::version::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command git-credential-manager --version; }

### Write a Git Credential Manager asset URL from the latest release.
git-credential-manager::_artifact-url() { [[ "$#" -le 1 ]] || return 64; printf 'https://github.com/git-ecosystem/git-credential-manager/releases/latest/download/%s
' "${1:-git-credential-manager.tar.gz}"; }

### Install Git Credential Manager with Homebrew.
git-credential-manager::install() { [[ "$#" -le 1 ]] || return 64; command -v brew >/dev/null 2>&1 || return 69; if [[ -n "${1:-}" ]]; then brew install --cask git-credential-manager; else brew install --cask git-credential-manager; fi; }

### Execute the git::config::setup utility.
git::config::setup() { [[ "$#" -le 2 ]] || return 64; [[ -n "${1:-}" ]] && git::config::set-email "$1"; [[ -n "${2:-}" ]] && git::config::set-username "$2"; git::config::set-default-branch main; git::config::enable-rebase-on-pull; git::config::enable-prune-fetch; }

### Register the official Go package source for the current platform.
go::repository::register() {
  [[ "$#" -eq 0 ]] || return 64
  command -v brew >/dev/null 2>&1 || command -v apt-get >/dev/null 2>&1 || return 69
}

### Install Go from the platform package source.
go::install() {
  [[ "$#" -le 1 ]] || return 64
  go::repository::register || return "$?"
  if command -v brew >/dev/null 2>&1; then
    if [[ "$#" -eq 1 ]]; then brew install "go@$1"; else brew install go; fi
  elif [[ "$#" -eq 1 ]]; then
    sudo apt-get install -y "golang-$1"
  else
    sudo apt-get install -y golang
  fi
}

### Install Rust using rustup and an optional toolchain version.
rust::install() {
  [[ "$#" -le 1 ]] || return 64
  command -v curl >/dev/null 2>&1 || return 69
  local temporary=''
  local toolchain='stable'
  [[ "$#" -eq 1 ]] && toolchain="$1"
  temporary="$(mktemp)" || return 74
  if ! curl -fsSL https://sh.rustup.rs -o "$temporary"; then
    rm -f -- "$temporary"
    return 74
  fi
  sh "$temporary" -y --default-toolchain "$toolchain"
  local status="$?"
  rm -f -- "$temporary"
  return "$status"
}

### List installed or available Rust toolchains.
rust::versions() {
  [[ "$#" -eq 0 ]] || return 64
  if command -v rustup >/dev/null 2>&1; then rustup toolchain list; else command -v rustc >/dev/null 2>&1 || return 69; rustc --version; fi
}

### Discard Flutter SDK changes and switch to a tag or commit.
flutter::use-version() {
  [[ "$#" -le 2 ]] || return 64
  local version='' directory=''
  if [[ "$#" -ge 1 ]]; then version="$1"; else version='stable'; fi
  if [[ "$#" -ge 2 ]]; then directory="$2"; else directory="$HOME/flutter"; fi
  [[ -d "$directory/.git" ]] || return 66
  git -C "$directory" reset --hard HEAD || return 75
  git -C "$directory" clean -fdx || return 75
  git -C "$directory" switch "$version"
}

### Remove one JFrog CLI server configuration.
jfrog::config::clear() { [[ "$#" -eq 1 && -n "$1" ]] || return 64; util::_run-command jf config remove "$1"; }

### Remove every JFrog CLI server configuration.
jfrog::config::clear-all() { [[ "$#" -eq 0 ]] || return 64; util::_run-command jf config clean; }

### Display JFrog CLI server configurations.
jfrog::config::list() { [[ "$#" -eq 0 ]] || return 64; util::_run-command jf config show; }

### Register and verify a JFrog CLI server.
jfrog::setup() {
  [[ "$#" -eq 5 && -n "$1" && -n "$2" && -n "$3" && -n "$4" && -n "$5" ]] || return 64
  util::_run-command jf config add "$1" --url "$2" --user "$3" --password "$5" --interactive=false || return "$?"
  util::_run-command jf rt ping --server-id "$1"
}

### Install the OpenCode command-line application.
opencode::install() {
  [[ "$#" -le 1 ]] || return 64
  if command -v brew >/dev/null 2>&1; then if [[ "$#" -eq 1 ]]; then brew install "opencode@$1"; else brew install opencode; fi; elif command -v npm >/dev/null 2>&1; then if [[ "$#" -eq 1 ]]; then npm install --global "opencode@$1"; else npm install --global opencode; fi; else return 69; fi
}

### Log in to an Artifactory Docker registry using a token on standard input.
docker::login-artifactory() {
  [[ "$#" -eq 3 && -n "$1" && -n "$2" && -n "$3" ]] || return 64
  command -v docker >/dev/null 2>&1 || return 69
  printf '%s\n' "$3" | docker login "$1" --username "$2" --password-stdin
}

### Export a Chrome profile's Bookmarks file.
chrome::profile::export-bookmarks() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" && ! -L "$1" ]] || return 64
  local output=''
  if [[ "$#" -eq 2 ]]; then output="$2"; else output='./bookmarks.json'; fi
  [[ -f "$1/Bookmarks" && ! -L "$1/Bookmarks" ]] || return 66
  cp -- "$1/Bookmarks" "$output"
}

### Export a Chrome profile's Preferences file.
chrome::profile::export-preferences() {
  [[ "$#" -ge 1 && "$#" -le 2 && -d "$1" && ! -L "$1" ]] || return 64
  local output=''
  if [[ "$#" -eq 2 ]]; then output="$2"; else output='./preferences.json'; fi
  [[ -f "$1/Preferences" && ! -L "$1/Preferences" ]] || return 66
  cp -- "$1/Preferences" "$output"
}

### Write the first known email address from a Chrome profile.
chrome::profile::email() {
  [[ "$#" -eq 1 && -d "$1" && -f "$1/Preferences" && ! -L "$1/Preferences" ]] || return 64
  command -v jq >/dev/null 2>&1 || return 69
  local email=''
  email="$(jq -r '.. | objects | (.email? // .user_name? // empty) | select(type == "string")' "$1/Preferences" 2>/dev/null | head -n 1)" || return 74
  [[ "$email" == *@*.* ]] || return 1
  printf '%s\n' "$email"
}

### Find Chrome profiles whose known email matches literally.
chrome::profile::find-by-email() {
  [[ "$#" -ge 1 && "$#" -le 2 && -n "$1" ]] || return 64
  local email="$1" root='' path=''
  if [[ "$#" -eq 2 ]]; then root="$2"; elif [[ "$(system::operating-system)" == darwin ]]; then root="$HOME/Library/Application Support/Google/Chrome"; else root="$HOME/.config/google-chrome"; fi
  [[ -d "$root" ]] || return 66
  (
    shopt -s nullglob
    for path in "$root"/Default "$root"/Profile\ *; do
      [[ -d "$path" ]] || continue
      [[ "$(chrome::profile::email "$path" 2>/dev/null)" == "$email" ]] && printf '%s\n' "$path"
    done
  )
}

### Extend swap capacity up to a target size.
swap::ensure-total-size() {
  [[ "$#" -ge 1 && "$#" -le 3 && "$1" =~ ^[1-9][0-9]*$ ]] || return 64
  local target="$1" max='' path='' current='' add=''
  if [[ "$#" -ge 2 ]]; then max="$2"; else max="$target"; fi
  if [[ "$#" -ge 3 ]]; then path="$3"; else path='/swapfile'; fi
  [[ "$max" =~ ^[0-9]+$ ]] || return 64
  current="$(mem::swap-total-bytes)" || return "$?"
  (( current >= target )) && return 0
  add=$((target - current))
  (( add > max )) && add="$max"
  swap::create "$add" "$path"
}

### Remove VS Code user data from an optional profile directory.
vscode::remove-user-data() {
  [[ "$#" -le 1 ]] || return 64
  local directory=''
  if [[ "$#" -eq 1 ]]; then directory="$1"; elif [[ "$(system::operating-system)" == darwin ]]; then directory="$HOME/Library/Application Support/Code"; else directory="$HOME/.config/Code"; fi
  [[ -d "$directory" && ! -L "$directory" ]] || return 66
  directory::clear "$directory"
}

### Reboot a device into its bootloader.
adb::device::bootloader::enter() { adb::_run reboot bootloader "$@"; }

### Set the default ADB device for later calls in the current shell by exporting ANDROID_SERIAL.
adb::device::set-default() {
  [[ "$#" -eq 1 && "$1" =~ ^[A-Za-z0-9._:-]+$ ]] || return 64
  export ANDROID_SERIAL="$1"
}

### Start the host ADB server.
adb::server::start() { [[ "$#" -eq 0 ]] || return 64; util::_run-command adb start-server; }

### Stop the host ADB server.
adb::server::stop() { [[ "$#" -eq 0 ]] || return 64; util::_run-command adb kill-server; }

### Stop and then start the host ADB server.
adb::server::restart() { [[ "$#" -eq 0 ]] || return 64; adb::server::stop || return "$?"; adb::server::start; }

### List stashes.
git::stash::list() { [[ "$#" -le 1 ]] || return 64; git::_run-in-directory "${1:-.}" stash list; }

### Write the last modification time of a file as Unix seconds.
file::modified-time-unix-seconds() {
  [[ "$#" -eq 1 && -n "$1" ]] || return 64
  [[ -e "$1" || -L "$1" ]] || return 66
  command::require stat || return "$?"
  case "$(system::operating-system)" in
    darwin) stat -f '%m' -- "$1" || return 74 ;;
    linux) stat -c '%Y' -- "$1" || return 74 ;;
    *) return 69 ;;
  esac
}

### List the named arguments and value candidates for gpg::key::generate.
gpg::key::_generate-args() {
  case "${1-}" in
    -Usage)
      printf '%s\n' sign cert auth sign,auth
      ;;
    -Algorithm)
      printf '%s\n' ed25519 rsa3072 rsa4096
      ;;
    '')
      printf '%s\n' -Usage -Algorithm -Expires -UserId -Pinentry -PassphraseFd
      ;;
  esac
}

### Generate a GPG primary key and an encryption subkey in one operation.
###
### Options
###
### * -Usage USAGE - Primary key usage: sign, cert, auth, or a comma-separated
###   combination. Defaults to sign.
### * -Algorithm ALGORITHM - ed25519, rsa3072, or rsa4096. Defaults to ed25519,
###   which pairs an Ed25519 primary key with a Curve25519 encryption subkey.
### * -Expires EXPIRES - GnuPG expiration such as 5y, 12m, or 0. Defaults to 5y.
### * -UserId USER_ID - "Name <email>". Defaults to the Git user name and email.
### * -Pinentry - Ask for the passphrase through pinentry.
### * -PassphraseFd FD - Read the passphrase from a file descriptor.
###
### Without -Pinentry or -PassphraseFd, the key has no passphrase.
gpg::key::generate() {
  local usage='sign' algorithm='ed25519' expires='5y' user_id='' pinentry='false' passphrase_fd=''
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -Usage | -Algorithm | -Expires | -UserId | -PassphraseFd)
        arg::require-next "$#" "$1" || return "$?"
        case "$1" in
          -Usage) usage="$2" ;;
          -Algorithm) algorithm="$2" ;;
          -Expires) expires="$2" ;;
          -UserId) user_id="$2" ;;
          -PassphraseFd) passphrase_fd="$2" ;;
        esac
        shift 2
        ;;
      -Pinentry)
        pinentry='true'
        shift
        ;;
      *)
        arg::unknown "$1" || return "$?"
        ;;
    esac
  done
  [[ "${usage}" =~ ^(sign|cert|auth)(,(sign|cert|auth))*$ ]] || return 64
  arg::one-of -Algorithm "${algorithm}" ed25519 rsa3072 rsa4096 || return "$?"
  [[ "${expires}" =~ ^(0|[1-9][0-9]*[dwmy]?)$ ]] || return 64
  [[ -z "${passphrase_fd}" || "${passphrase_fd}" =~ ^[0-9]+$ ]] || return 64
  [[ "${pinentry}" == 'false' || -z "${passphrase_fd}" ]] || return 64
  command::require gpg || return "$?"
  if [[ -z "${user_id}" ]]; then
    local name='' email=''
    name="$(git config --get user.name 2>/dev/null)"
    email="$(git config --get user.email 2>/dev/null)"
    [[ -n "${name}" && -n "${email}" ]] || return 64
    user_id="${name} <${email}>"
  fi
  local user_id_pattern='^([^<>]+) <([^<>@[:space:]]+@[^<>[:space:]]+)>$'
  [[ "${user_id}" =~ ${user_id_pattern} ]] || return 64
  local real_name="${BASH_REMATCH[1]}" email_address="${BASH_REMATCH[2]}" parameters='' directory='' status=0
  case "${algorithm}" in
    ed25519)
      parameters="Key-Type: eddsa"$'\n'"Key-Curve: ed25519"$'\n'
      parameters+="Subkey-Type: ecdh"$'\n'"Subkey-Curve: cv25519"$'\n'
      ;;
    rsa*)
      parameters="Key-Type: RSA"$'\n'"Key-Length: ${algorithm#rsa}"$'\n'
      parameters+="Subkey-Type: RSA"$'\n'"Subkey-Length: ${algorithm#rsa}"$'\n'
      ;;
  esac
  parameters+="Key-Usage: ${usage//,/ }"$'\n'"Subkey-Usage: encrypt"$'\n'
  parameters+="Name-Real: ${real_name}"$'\n'"Name-Email: ${email_address}"$'\n'
  parameters+="Expire-Date: ${expires}"$'\n'
  [[ "${pinentry}" == 'true' || -n "${passphrase_fd}" ]] || parameters+='%no-protection'$'\n'
  parameters+='%commit'$'\n'
  directory="$(package::_temporary-directory)" || return "$?"
  chmod 0700 "${directory}" || status=74
  if [[ "${status}" -eq 0 ]]; then
    (umask 077 && printf '%s' "${parameters}" >"${directory}/parameters") || status=74
  fi
  if [[ "${status}" -eq 0 ]]; then
    if [[ -n "${passphrase_fd}" ]]; then
      gpg --batch --pinentry-mode loopback --passphrase-fd "${passphrase_fd}" \
        --generate-key "${directory}/parameters" || status="$?"
    elif [[ "${pinentry}" == 'true' ]]; then
      gpg --generate-key "${directory}/parameters" || status="$?"
    else
      gpg --batch --generate-key "${directory}/parameters" || status="$?"
    fi
  fi
  rm -rf -- "${directory}"
  return "${status}"
}

### Write the current DNS manager: systemd-resolved, network-manager, or unknown.
net::dns::manager() { [[ "$#" -eq 0 ]] || return 64; net::dns::_manager; }

### Write one setting from the effective NetworkManager configuration.
net::dns::_network-manager-setting() {
  [[ "$#" -eq 1 && "$1" =~ ^[a-z-]+$ ]] || return 64
  command -v NetworkManager >/dev/null 2>&1 || return 1
  NetworkManager --print-config 2>/dev/null |
    awk -F= -v key="$1" '/^\[/ {section=$0} section == "[main]" && $1 == key {print $2; exit}'
}

### Write the current DNS manager by inspecting resolv.conf and NetworkManager settings.
net::dns::_manager() {
  [[ "$#" -eq 0 ]] || return 64
  local target='' dns=''
  if [[ -L /etc/resolv.conf ]]; then
    target="$(readlink /etc/resolv.conf)" || target=''
  fi
  dns="$(net::dns::_network-manager-setting dns)" || dns=''
  case "${target}" in
    */run/NetworkManager/resolv.conf)
      printf 'network-manager\n'
      return 0
      ;;
    */run/systemd/resolve/stub-resolv.conf | */run/systemd/resolve/resolv.conf)
      printf 'systemd-resolved\n'
      return 0
      ;;
  esac
  case "${dns}" in
    systemd-resolved) printf 'systemd-resolved\n' ;;
    default | dnsmasq) printf 'network-manager\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

### Back up /etc/resolv.conf when it differs from the link that will replace it.
net::dns::_backup-resolv-conf() {
  [[ "$#" -eq 1 && "$1" == /* ]] || return 64
  [[ -e /etc/resolv.conf || -L /etc/resolv.conf ]] || return 0
  if [[ -L /etc/resolv.conf && "$(readlink /etc/resolv.conf)" == "$1" ]]; then
    return 0
  fi
  local stamp=''
  stamp="$(time::local-date-time-seconds-basic)" || return "$?"
  command::run-as-root cp -P -- /etc/resolv.conf "/etc/resolv.conf.bashstock-${stamp}" || return 74
}

### Write active NetworkManager connection UUIDs, excluding VPN connections.
net::dns::_active-network-manager-connections() {
  [[ "$#" -eq 0 ]] || return 64
  command::require nmcli || return "$?"
  nmcli -t -f UUID,TYPE connection show --active 2>/dev/null |
    awk -F: '$2 != "vpn" && $2 != "wireguard" && $2 != "loopback" && $1 != "" {print $1}'
}

### Restart systemd-resolved and confirm that it is active.
net::dns::_restart-systemd-resolved() {
  [[ "$#" -eq 0 ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl restart systemd-resolved || return 75
  systemctl is-active --quiet systemd-resolved || return 75
}

### Restart NetworkManager and wait until it writes its runtime resolv.conf.
net::dns::_restart-network-manager() {
  [[ "$#" -eq 0 ]] || return 64
  command::require systemctl || return "$?"
  command::run-as-root systemctl restart NetworkManager || return 75
  systemctl is-active --quiet NetworkManager || return 75
  local attempt=0
  while [[ ! -f /run/NetworkManager/resolv.conf ]]; do
    attempt=$((attempt + 1))
    [[ "${attempt}" -le 20 ]] || return 75
    sleep 0.5 || return 74
  done
}

### Verify the DNS manager, configured servers, resolv.conf link, and name resolution.
###
### Arguments
###
### * MANAGER - Expected DNS manager.
### * SERVER... - DNS servers that must be configured.
net::dns::_verify() {
  [[ "$#" -ge 1 ]] || return 64
  local manager="$1" actual='' configured='' server=''
  shift
  actual="$(net::dns::_manager)" || return "$?"
  if [[ "${actual}" != "${manager}" ]]; then
    console::_write-error "DNS manager is ${actual}, expected ${manager}."
    return 75
  fi
  case "${manager}" in
    systemd-resolved)
      [[ "$(readlink /etc/resolv.conf 2>/dev/null)" == */run/systemd/resolve/*resolv.conf ]] || return 75
      command::require resolvectl || return "$?"
      configured="$(resolvectl dns 2>/dev/null)"
      ;;
    network-manager)
      [[ "$(readlink /etc/resolv.conf 2>/dev/null)" == */run/NetworkManager/resolv.conf ]] || return 75
      configured="$(<"/etc/resolv.conf")"
      ;;
  esac
  for server in "$@"; do
    if [[ "${configured}" != *"${server}"* ]]; then
      console::_write-error "DNS server is not configured: ${server}"
      return 75
    fi
  done
  net::dns::test example.com || return 75
}

### Make systemd-resolved manage DNS and /etc/resolv.conf.
net::dns::use-systemd-resolved() {
  [[ "$#" -eq 0 ]] || return 64
  local link='/run/systemd/resolve/stub-resolv.conf'
  package::_enable-service systemd-resolved || return "$?"
  net::dns::_backup-resolv-conf "${link}" || return "$?"
  command::run-as-root ln -sfn "${link}" /etc/resolv.conf || return 74
  net::dns::_restart-systemd-resolved || return "$?"
  net::dns::_verify systemd-resolved
}

### Make NetworkManager manage DNS and /etc/resolv.conf directly.
net::dns::use-network-manager() {
  [[ "$#" -eq 0 ]] || return 64
  local link='/run/NetworkManager/resolv.conf'
  command::require NetworkManager || return "$?"
  command::run-as-root install -d -m 0755 /etc/NetworkManager/conf.d || return 74
  file::write-text /etc/NetworkManager/conf.d/90-bashstock-dns.conf \
    $'[main]\ndns=default\nrc-manager=symlink\n' || return "$?"
  net::dns::_restart-network-manager || return "$?"
  net::dns::_backup-resolv-conf "${link}" || return "$?"
  command::run-as-root ln -sfn "${link}" /etc/resolv.conf || return 74
  net::dns::_verify network-manager
}

### Configure Google Public DNS while keeping the current DNS manager.
net::dns::use-google() {
  [[ "$#" -eq 0 ]] || return 64
  local manager='' connection='' connections=''
  manager="$(net::dns::_manager)" || return "$?"
  case "${manager}" in
    systemd-resolved)
      command::run-as-root install -d -m 0755 /etc/systemd/resolved.conf.d || return 74
      file::write-text /etc/systemd/resolved.conf.d/90-bashstock-google.conf \
        $'[Resolve]\nDNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844\n' || return "$?"
      net::dns::_restart-systemd-resolved || return "$?"
      ;;
    network-manager)
      connections="$(net::dns::_active-network-manager-connections)" || return "$?"
      [[ -n "${connections}" ]] || return 69
      while IFS= read -r connection; do
        command::run-as-root nmcli connection modify "${connection}" \
          ipv4.dns '8.8.8.8 8.8.4.4' ipv4.ignore-auto-dns yes \
          ipv6.dns '2001:4860:4860::8888 2001:4860:4860::8844' ipv6.ignore-auto-dns yes || return 74
        command::run-as-root nmcli connection up "${connection}" >/dev/null || return 75
      done <<<"${connections}"
      ;;
    *)
      console::_write-error 'The DNS manager is unknown; no change was made.'
      return 69
      ;;
  esac
  net::dns::_verify "${manager}" 8.8.8.8 8.8.4.4
}
