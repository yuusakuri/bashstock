#!/bin/bash

WORK_DIR="$HOME/work"
ARTIFACT_DIR="$HOME/artifacts"
LOG_DIR="$ARTIFACT_DIR/logs"
BUILD_LOG_DIR="$ARTIFACT_DIR/logs/build"
TTY_LOG_DIR="$ARTIFACT_DIR/logs/tty"

# Python avoid to write .pyc files
export PYTHONDONTWRITEBYTECODE=1

pause() {
    read -p "Press the ENTER key to continue"
}

### Run command for each input line.
###
### # Arguments
###
### * command - Command string. Use $LINE inside the command.
###
### # Examples
###
### ```
### echo -e "a\nb" | foreach-line 'echo "$LINE"'
### ```
###
### The following output appears.
###
### ```text
### a
### b
### ```
foreach-line() {
    local command="$*"
    local line

    if [ -z "$command" ]; then
        echo "Usage: ... | foreach-line '<command>'" >&2
        echo "  Inside the command, use \$LINE to refer to the current line." >&2
        return 1
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        (
            export LINE="$line"
            eval "$command"
        )
    done
}

### Convert timezone offset to POSIX TZ format.
###
### # Arguments
###
### * timezone_offset - Offset like +9 or -5.
###
### # Examples
###
### ```
### timezone-offset-to-posix-format "+9"
### ```
###
### The following output appears.
###
### ```
### UTC-9
### ```
timezone-offset-to-posix-format() {
    local timezone_offset="$1"

    if [[ -z "$timezone_offset" || "$timezone_offset" == "0" ]]; then
        echo "UTC0"
        return
    fi

    local sign="${timezone_offset:0:1}"
    local value=""
    local posix_sign=""

    if [[ "$sign" == "+" ]]; then
        posix_sign="-"
        value="${timezone_offset:1}"
    elif [[ "$sign" == "-" ]]; then
        posix_sign="+"
        value="${timezone_offset:1}"
    else
        posix_sign="-"
        value="$timezone_offset"
    fi

    echo "UTC${posix_sign}${value}"
}

### Print datetime string for filenames.
###
### # Examples
###
### ```
### datetime-for-filename
### ```
###
### The following output appears.
###
### ```
### 20260316T120000
### ```
datetime-for-filename() {
    date +%Y%m%dT%H%M%S
}

datetimes() {
    local uptime=$(awk '{print $1}' /proc/uptime)
    local walltime=$(date +%T)

    echo "Uptime: ${uptime}"
    echo "Wall Time: ${walltime}"
}

datetimes-continuous() {
    while true; do
        datetimes
        sleep 3
    done
}

env-import() {
    local env_file="$1"

    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
    fi
}

dir-merge() {
    local src="$1"
    local dest="$2"

    if [ ! -d "$src" ]; then
        return 0
    fi

    mkdir -p "$dest"

    mv -n "$src"/* "$dest/" 2>/dev/null
    mv -n "$src"/.* "$dest/" 2>/dev/null

    rmdir "$src" 2>/dev/null
}

### Create directory using datetime name.
###
### # Arguments
###
### * output_dir - Base directory.
###
### # Examples
###
### ```
### dir-create-with-datetime logs
### ```
###
### The following output appears.
###
### ```
### logs/20260316T120000
### ```
dir-create-with-datetime() {
    local output_dir="${1-:.}"

    local datetime=$(datetime-for-filename)
    mkdir "$output_dir/$datetime" -p >&2
    echo "$output_dir/$datetime"
}

# Delete all entries in a dir.
#
# # Arguments
#
# * target_dir - Target dir. Default is current dir.
dir-clear() {
  local target_dir="$1"

  if [[ -z "$target_dir" ]]; then
    target_dir="."
  fi

  if [[ ! -d "$target_dir" ]]; then
    printf 'error: not a dir: %s\n' "$target_dir" >&2
    return 1
  fi

  while IFS= read -u 3 -r -d '' entry_path; do
    rm -rf -- "$entry_path"
  done 3< <(find "$target_dir" -mindepth 1 -maxdepth 1 -print0)
}

### Sleep for hours.
###
### # Arguments
###
### * hours - Hour count.
###
### # Examples
###
### ```
### sleep-hour 1
### ```
sleep-hour() {
    sleep $(($1 * 60 * 60))
}

### Print regex for error log detection.
###
### # Examples
###
### ```
### log-error-regex
### ```
###
### The following output appears.
###
### ```
### exception|err|fatal|fail|out of memory|watchdog
### ```
log-error-regex() {
    echo 'exception|err|fatal|fail|out of memory|watchdog'
}

### Print regex for warning log detection.
###
### # Examples
###
### ```
### log-warn-regex
### ```
###
### The following output appears.
###
### ```
### warn|deny|denied|refuse|timeout|unreachable|no such file|cannot|null|invalid| full
### ```
log-warn-regex() {
    echo 'warn|deny|denied|refuse|timeout|unreachable|no such|cannot|null|invalid| full|expired'
}

### Clear files from trash directory.
###
### # Examples
###
### ```
### storage-clear-trash
### ```
storage-clear-trash() {
    sudo rm -rf ~/.local/share/Trash/files/*
    sudo rm -rf ~/.local/share/Trash/info/*
}

### Show filesystem disk usage.
###
### # Arguments
###
### * dir - Target dir (optional)
###
### # Examples
###
### ```
### storage-usage
### storage-usage /var
### ```
storage-usage() {
    if [ $# -eq 0 ]; then
        df -h | grep -vE '^(tmpfs|devtmpfs|devfs|map |autofs|/dev/loop)'
    else
        df -h "$1"
    fi
}

### Show top disk usage in a directory.
###
### # Arguments
###
### * dir - Target directory (optional)
###
### # Examples
###
### ```
### storage-usage-top
### storage-usage-top /var
### ```
storage-usage-top() {
    local dir="${1:-.}"

    if [ ! -d "$dir" ]; then
        echo "Directory not found: $dir" >&2
        return 1
    fi

    du -h -d 1 "$dir" 2>/dev/null |
        sort -hr |
        head -n 10
}

storage-defrag() {
    local -r mount_point="$1"

    if [ -z $mount_point ]; then
        mount | grep 'type ext4' | while read -r line; do
            local -r mount_point=$(echo "$line" | awk '{print $3}')
            storage-defrag "$mount_point"
        done
    else
        echo "Start Defragmentation. mount-point: $mount_point" >&2
        e4defrag -c "$mount_point" >&2
        e4defrag "$mount_point" >&2
        echo "Defragmentation completed. mount-point: $mount_point" >&2
    fi
}

memory-show() {
    free -h
}

### Edit file using sudo editor.
###
### # Arguments
###
### * file - Target file path.
###
### # Examples
###
### ```
### file-edit-as-root /etc/hosts
### ```
file-edit-as-root() {
    local -r file="$1"
    sudoedit "$file"
}

### Find files matching a pattern in the current directory and its subdirectories.
###
### # Arguments
###
### * `pattern` - The extended regular expression to match against file paths
###
### # Examples
###
### file-find 'config'
###
### The function prints matching file paths to stdout.
file-find() {
    local pattern="$1"
    find "$PWD" | grep -iE "$pattern"
}

### Search files in a directory for a regex and print matching file paths.
###
### # Arguments
###
### * `regex` - The extended regular expression to match
### * `dir` - The directory to search
###
### # Examples
###
### file-find-by-contents '.*' $HOME
###
### The function prints the paths of files containing matches to stdout.
file-find-by-contents() {
    local regex="$1"
    local dir="${2:-.}"
    local parallel
    if command -v nproc >/dev/null 2>&1; then
        parallel="$(nproc)"
    else
        parallel=1
    fi
    find "$dir" -type f -print0 |
        xargs -0 -r -P "$parallel" -n 100 grep -I -s -E -l -- "$regex" |
        sort -u
}

### Find the latest file matching a pattern in a directory.
###
### # Arguments
###
### * `dir` - The directory to search
### * `pattern` - The extended regular expression to match against file paths
###
### # Examples
###
### file-find-last-by-name /var/log '\.log$'
###
### The function prints the path of the latest matching file to stdout.
file-find-last-by-name() {
    local -r dir="$1"
    local -r pattern="$2"
    find "$dir" -type f | grep -iE "$pattern" | sort -n | tail -1 | awk '{print $2}'
}

file-tree-with-contents() {
    local target="${1:-.}"
    local min_depth="${2:-1}"
    local max_depth="${3:-}"

    if [ ! -e "$target" ]; then
        echo "Error: Path not found: $target" >&2
        return 1
    fi

    _print_file() {
        local file="$1"
        local filetype
        filetype="$(file --brief --mime-type -- "$file")"
        if [[ $filetype == text/* ]]; then
            printf '--- %s\n' "$file"
            cat -- "$file"
            printf '+++ %s\n\n' "$file"
        fi
    }

    if [ -f "$target" ]; then
        _print_file "$target"
        return 0
    fi

    local find_args=("$target" -mindepth "$min_depth")
    if [ -n "$max_depth" ]; then
        find_args+=(-maxdepth "$max_depth")
    fi
    find_args+=(-print0)

    while read -r -d '' entry; do
        local relative_path="${entry#./}"

        if [ -d "$entry" ]; then
            printf '--- dir %s\n+++ dir %s\n\n' "$relative_path" "$relative_path"
            continue
        fi

        _print_file "$entry"
    done < <(find "${find_args[@]}")
}

### Close a file by killing all processes that have it open.
###
### # Arguments
###
### * `file` - The path to the file to close
###
### # Examples
###
### file-close /tmp/lockfile
###
### The function returns 0 on success, 1 if the file is not found or cannot be closed.
file-close() {
    local file="$1"

    if [ ! -e "$file" ]; then
        return 1
    fi

    # 2. プロセスを強制終了(-9)し、完全に消えるまで少し待つ
    sudo fuser -k -9 "$file" >/dev/null 2>&1
    sleep 0.5

    # 3. まだ使用中ならエラー(1)、解放されていれば成功(0)
    if sudo fuser "$file" >/dev/null 2>&1; then
        echo "Failed to close '$file'."
        return 1
    fi

    return 0
}

usb-find-partition() {
    # 1. 接続方式(TRAN)が "usb" のディスク本体 (例: /dev/sda) を取得
    local usb_disks=$(lsblk -d -n -p -o NAME,TRAN | awk '$2=="usb" {print $1}')

    if [ -z "$usb_disks" ]; then
        echo "エラー: USBデバイスが検出されませんでした。" >&2
        return 1
    fi

    # 2. 検出したUSBディスク内のパーティション (例: /dev/sda1) をリスト化
    local targets=()
    for disk in $usb_disks; do
        local parts=$(lsblk -n -p -o NAME,TYPE "$disk" | awk '$2=="part" {print $1}')
        if [ -n "$parts" ]; then
            # パーティションがある場合はそれを追加
            for part in $parts; do
                targets+=("$part")
            done
        else
            # 万が一パーティションがない(スーパーフロッピー形式など)場合はディスク自体を追加
            targets+=("$disk")
        fi
    done

    local count=${#targets[@]}

    if [ $count -eq 1 ]; then
        echo "🔍 USBパーティションを1つだけ検出しました。自動選択します: ${targets[0]}" >&2
        echo "${targets[0]}"
        return 0
    elif [ $count -gt 1 ]; then
        echo "複数のUSBパーティションが検出されました。対象の詳細:" >&2
        lsblk -p -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL "${usb_disks[@]}" >&2
        echo "---------------------------------------------------" >&2

        PS3="フォーマットするパーティションの番号を入力してください: "
        select choice in "${targets[@]}"; do
            if [ -n "$choice" ]; then
                echo "$choice"
                return 0
            else
                echo "エラー: 無効な入力です。処理を中止します。" >&2
                return 1
            fi
        done
    fi
}

usb-fix() {
    local usb_part=$(usb-find-partition)

    # 見つからなかった、またはキャンセルされた場合は終了
    if [ -z "$usb_part" ] || [ $? -ne 0 ]; then
        return 1
    fi

    echo "'$usb_part' をアンマウントしています..."
    sudo umount "$usb_part" 2>/dev/null

    echo "修復を実行します..."
    local fstype=$(lsblk -n -o FSTYPE "$usb_part")

    if [[ "$fstype" == *"vfat"* || "$fstype" == *"fat"* ]]; then
        sudo fsck.fat -a "$usb_part"
    elif [[ "$fstype" == *"exfat"* ]]; then
        sudo fsck.exfat -a "$usb_part"
    else
        sudo fsck -y "$usb_part"
    fi

    local ret=$?

    if [ $ret -eq 0 ] || [ $ret -eq 1 ]; then
        echo "修復処理が完了しました。USBメモリを一度抜き、再度挿し込んで書き込みができるか確認してください。"
    else
        echo "処理が終了しましたが、エラーが残っている可能性があります (fsck終了コード: $ret)。"
    fi
}

usb-format-fat32() {
    local usb_part=$(usb-find-partition)

    # 見つからなかった、またはキャンセルされた場合は終了
    if [ -z "$usb_part" ] || [ $? -ne 0 ]; then
        return 1
    fi

    echo "'$usb_part' をアンマウントしています..."
    sudo umount "$usb_part" 2>/dev/null

    echo "'$usb_part' を FAT32 (vfat) でフォーマットしています..."
    # -F 32: FAT32を指定, -I: デバイス全体へのフォーマットを許可する場合に必要になることがあるが今回はパーティション想定
    sudo mkfs.vfat -F 32 "$usb_part"

    local ret=$?

    if [ $ret -eq 0 ]; then
        echo "フォーマットが正常に完了しました。"
        echo "必要に応じてUSBメモリを抜き差しして確認してください。"
    else
        echo "フォーマット処理が終了しましたが、エラーが発生した可能性があります (mkfs終了コード: $ret)。"
    fi
}

### Print the global IP address of this machine.
###
### # Examples
###
### ```
### net-ip-global
### ```
###
### The command prints a public IP address like below.
###
### ```
### 203.0.113.10
### ```
net-ip-global() {
    echo "If an error occurs, please access 'ifconfig.me' in your web browser."

    if command -v curl >/dev/null 2>&1; then
        curl -s ifconfig.me
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- ifconfig.me
    else
        echo "Error: Neither curl nor wget is installed." >&2
        return 1
    fi
    echo
}

net-unused-port() {
    while true; do
        port=$(shuf -i 10000-65000 -n 1)
        if ! ss -lnt | grep -q ":$port "; then
            echo "$port"
            break
        fi
    done
}

### Monitor network traffic for a specific host.
###
### # Arguments
###
### * host - Target host name or IP address.
###
### # Examples
###
### ```
### net-monitor-by-host example.com
### ```
###
### The command starts tcpdump and shows packets for example.com.
net-monitor-by-host() {
    local host="$1"
    sudo tcpdump -i any host "$host"
}

### Print the current user name.
###
### # Examples
###
### ```
### user-name
### ```
###
### The command prints the current login user.
user-name() {
    echo "$(whoami)"
}

# Configures a tty device with the specified baud rate
tty-open() {
    local device_file="$1"
    local baudrate="${2:-115200}"

    if [[ -z "$device_file" ]]; then
        echo "Error: device_file is empty." >&2
        return 1
    fi

    file-close "$device_file" 2>/dev/null || true

    case "$(uname)" in
        Linux)
            stty -F "$device_file" \
                "$baudrate" \
                cs8 \
                -cstopb \
                -parenb \
                raw \
                -echo \
                -echoe \
                -echok \
                -icanon \
                -isig \
                -iexten
            ;;
        Darwin)
            stty -f "$device_file" \
                "$baudrate" \
                cs8 \
                -cstopb \
                -parenb \
                raw \
                -echo \
                -echoe \
                -echok \
                -icanon \
                -isig \
                -iexten
            ;;
        *)
            return 1
            ;;
    esac
}

tty-close() {
    local device_file="$1"
    file-close "$device_file" 2>/dev/null
}

tty-write() {
    local device_file="$1"
    local cmd="$2"
    local delay="${3:-0}"
    local eol="${4:-\r}"

    if [[ -z "$device_file" ]]; then
        return 1
    fi

    printf '%b' "${cmd}${eol}" >"$device_file"

    if [[ "$delay" != "0" ]]; then
        sleep "$delay"
    fi
}

### Create a new screen session.
###
### # Arguments
###
### * name - Screen session name. Default is "default".
###
### # Examples
###
### ```
### screen-new dev
### ```
###
### The command creates a screen session named "dev".
screen-new() {
    local name="${1:-default}"
    screen -S "$name"
}

### Kill all running screen sessions.
###
### # Examples
###
### ```
### screen-kill-all
### ```
###
### The command stops all screen sessions.
screen-kill-all() {
    sudo pkill screen
}

### Open a screen session for a ttyUSB device and record logs.
###
### # Arguments
###
### * usb_device_index - Device index such as 0 or 1.
### * baud_rate - Serial baud rate such as 115200.
###
### # Examples
###
### ```
### screen-tty-usb 0 115200
### ```
###
### The command connects to /dev/ttyUSB0 and saves logs.
screen-tty-usb() {
    local -r usb_device_index=$1
    local baud_rate="${2:-115200}"

    ls /dev/ttyUSB*

    datetime=$(date +\%Y\%m\%dT\%H\%M%S)
    sudo screen -L -Logfile $TTY_LOG_DIR/$datetime-tty.log /dev/ttyUSB$usb_device_index $baud_rate
}

archive-compress-tar-gz() {
    tar -czf archive.tar.gz $1
}

### Check archive files recursively and remove broken archives.
###
### Supported formats are zip, tar, tar.gz, tgz, tar.xz, gz, and xz.
### The function only tests extraction ability. It does not extract files.
### If a test fails, the file is deleted.
###
### # Arguments
###
### * dir - Target directory. Default is current directory.
###
### # Examples
###
### ```
### archive-remove-broken ./downloads
### ```
###
### The command scans archives in ./downloads.
### If a broken archive is found, it prints an error and deletes the file.
archive-remove-broken() {
    local dir="${1:-.}"

    if [ -d "$dir" ]; then
        _archive-find "$dir" | while IFS= read -r -d '' file; do
            _archive-remove-broken "$file"
        done
    else
        _archive-remove-broken "$dir"
    fi
}

_archive-find() {
    find "$1" -type f \( \
        -name "*.zip" -o \
        -name "*.tar" -o \
        -name "*.tar.gz" -o \
        -name "*.tgz" -o \
        -name "*.tar.xz" -o \
        -name "*.gz" -o \
        -name "*.xz" \
    \) -print0
}

### Test whether a single archive can be extracted.
###
### If the archive is broken, an error message is printed
### and the file is deleted.
###
### # Arguments
###
### * file - Path to archive file.
###
### # Examples
###
### ```
### _archive-remove-broken data.tar.gz
### ```
###
### If the archive is broken, the following message is shown and the file is removed.
###
### ```text
### broken archive: data.tar.gz
### ```
_archive-remove-broken() {
    local file="$1"
    local ok=0

    case "$file" in
    *.tar.gz | *.tgz)
        tar -tzf "$file" >/dev/null 2>&1
        ;;
    *.tar.xz)
        tar -tJf "$file" >/dev/null 2>&1
        ;;
    *.tar)
        tar -tf "$file" >/dev/null 2>&1
        ;;
    *.zip)
        unzip -tq "$file" >/dev/null 2>&1
        ;;
    *.gz)
        gzip -t "$file" >/dev/null 2>&1
        ;;
    *.xz)
        xz -t "$file" >/dev/null 2>&1
        ;;
    *) return 0 ;;
    esac

    ok=$?

    if [ "$ok" -ne 0 ]; then
        echo "broken archive: $file" >&2
        rm -f -- "$file"
    fi
}

### Expand archive files recursively inside a directory.
###
### Supported formats are zip, tar, tar.gz, tgz, tar.xz, gz, and xz.
###
### # Arguments
###
### * dir - Target directory. Default is current directory.
###
### # Examples
###
### ```
### archive-expand ./downloads
### ```
###
### The command extracts all archive files inside ./downloads.
archive-expand() {
    local dir="${1:-.}"

    if [ -d "$dir" ]; then
        _archive-find "$dir" | while IFS= read -r -d '' file; do
            _archive-expand "$file"
        done
    else
        _archive-expand "$dir"
    fi
}

### Expand a single archive file.
###
### # Arguments
###
### * file - Path to archive file.
###
### # Examples
###
### ```
### _archive-expand archive.tar.gz
### ```
###
### The command extracts archive.tar.gz in the same directory.
_archive-expand() {
    local file="$1"

    local parent
    parent="$(dirname "$file")"

    local filename
    filename="$(basename "$file")"

    local name="$filename"
    name="${name%.tar.gz}"
    name="${name%.tgz}"
    name="${name%.tar.xz}"
    name="${name%.tar}"
    name="${name%.zip}"
    name="${name%.gz}"
    name="${name%.xz}"

    local out_dir="$parent/$name"

    mkdir -p "$out_dir"

    case "$file" in
    *.tar.gz | *.tgz)
        tar -xzf "$file" -C "$out_dir"
        ;;
    *.tar.xz)
        tar -xJf "$file" -C "$out_dir"
        ;;
    *.tar)
        tar -xf "$file" -C "$out_dir"
        ;;
    *.zip)
        unzip -o "$file" -d "$out_dir"
        ;;
    *.gz)
        gzip -dc "$file" >"$out_dir/$name"
        ;;
    *.xz)
        xz -dc "$file" >"$out_dir/$name"
        ;;
    *)
        echo "skip: $file" >&2
        return 1
        ;;
    esac
}

### Show recursive diff between two directories.
###
### # Arguments
###
### * dir1 - First directory.
### * dir2 - Second directory.
###
### # Examples
###
### ```
### diff-dir old_dir new_dir
### ```
###
### The command prints file differences.
diff-dir() {
    diff -uprN "$1" "$2"
}

git-clone() {
git clone --depth 1 "$1"
}

### Start interactive rebase and stop at a specific commit.
###
### # Arguments
###
### * commit_hash - Commit hash to edit.
###
### # Examples
###
### ```
### git-rebase-for-edit a1b2c3d
### ```
###
### The command opens interactive rebase and marks the commit as edit.
git-rebase-for-edit() {
    local -r commit_hash=$1
    if [ -z "$commit_hash" ]; then
        echo "Error: Specify commit hash." >&2
        return 1
    fi

    if ! git rev-parse "${commit_hash}^" >/dev/null 2>&1; then
        GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/edit/'" git rebase -i --root
        return $?
    fi

    local parent_hash
    parent_hash=$(git rev-parse "${commit_hash}^")

    GIT_SEQUENCE_EDITOR="sed -i 's/^pick ${commit_hash:0:7}/edit ${commit_hash:0:7}/'" git rebase -i "$parent_hash"
}

### Abort the current git rebase operation.
###
### # Examples
###
### ```
### git-rebase-abort
### ```
git-rebase-abort() {
    git rebase --abort
}

### Continue the current git rebase.
###
### # Examples
###
### ```
### git-rebase-continue
### ```
git-rebase-continue() {
    git rebase --continue
}

### Amend the latest commit without changing the message.
###
### # Examples
###
### ```
### git-commit-amend
### ```
git-commit-amend() {
    git commit --amend --no-edit
}

### Print the current git branch name.
###
### # Examples
###
### ```
### git-current-branch
### ```
git-current-branch() {
    git rev-parse --abbrev-ref HEAD
}

### Create a new branch from a base branch.
###
### # Arguments
###
### * branch - New branch name.
### * base_branch - Base branch name.
###
### # Examples
###
### ```
### git-create-branch feature-x main
### ```
git-create-branch() {
    local branch=$1
    local base_branch=$2

    if [ -z "$branch" ] || [ -z "$base_branch" ]; then
        echo "Error: Usage: git-create-branch <new-branch> <base-branch>" >&2
        return 1
    fi

    git checkout -b "$branch" "$base_branch"
}

### Show the diff introduced by the latest commit.
###
### # Examples
###
### ```
### git-diff-latest
### ```
###
### The command prints the difference between HEAD and HEAD~1.
git-diff-latest() {
    git diff HEAD~1 HEAD
}

### Show file names modified in the working directory.
###
### # Examples
###
### ```
### git-diff-current-name-only
### ```
###
### The command prints file names with unstaged changes.
git-diff-current-name-only() {
    git diff --name-only
}

### Show file names changed in the latest commit.
###
### # Examples
###
### ```
### git-diff-latest-name-only
### ```
###
### The command prints file names changed in HEAD.
git-diff-latest-name-only() {
    git diff --name-only HEAD~1 HEAD
}

### Show file names that differ between two commits.
###
### # Arguments
###
### * commit_hash_1 - First commit.
### * commit_hash_2 - Second commit.
###
### # Examples
###
### ```
### git-diff-name-only a1b2c3d d4e5f6g
### ```
###
### The command prints file names that differ.
git-diff-name-only() {
    local commit_hash_1=$1
    local commit_hash_2=$2

    if [ -z "$commit_hash_1" ] || [ -z "$commit_hash_2" ]; then
        echo "Error: Usage: git-diff-files <commit1> <commit2>" >&2
        return 1
    fi

    git diff --name-only "$commit_hash_1" "$commit_hash_2"
}

### Generate a patch for a specific commit.
###
### # Arguments
###
### * commit_hash - Commit hash.
###
### # Examples
###
### ```
### git-format-patch-by-hash a1b2c3d
### ```
###
### The command prints a patch to stdout.
git-format-patch-by-hash() {
    local commit_hash="$1"

    git fetch origin "$commit_hash" && git format-patch -1 --stdout FETCH_HEAD
}

### Revert the latest commit without committing.
###
### # Examples
###
### ```
### git-revert-latest-no-commit
### ```
git-revert-latest-no-commit() {
    git revert HEAD --no-commit
}

### Revert a specific commit.
###
### # Arguments
###
### * commit_hash - Commit hash to revert.
###
### # Examples
###
### ```
### git-revert a1b2c3d
### ```
git-revert() {
    commit_hash="$1"
    git revert "$commit_hash"
}

### Fetch all remote branches and tags.
###
### # Examples
###
### ```
### git-fetch
### ```
git-fetch() {
    git fetch --all --tags --progress
}

### Fetch full history from a shallow repository.
###
### # Examples
###
### ```
### git-fetch-unshallow
### ```
git-fetch-unshallow() {
    git fetch --all --tags --unshallow --progress
}

### Show patch of the latest stash.
###
### # Examples
###
### ```
### git-stash-show-latest
### ```
git-stash-show-latest() {
    git stash show -p stash@{0}
}

### Stash changes including untracked files.
###
### # Examples
###
### ```
### git-stash-push
### ```
git-stash-push() {
    git stash push -u
}

### Pop the latest stash entry.
###
### # Examples
###
### ```
### git-stash-pop
### ```
git-stash-pop() {
    git stash pop
}

### Drop the latest stash entry.
###
### # Examples
###
### ```
### git-stash-drop
### ```
git-stash-drop() {
    git stash drop
}

### Stash changes and reset to previous commit.
###
### # Examples
###
### ```
### git-reset-prev
### ```
git-reset-prev() {
    git-stash-push
    git reset --hard HEAD^
}

### Reset current branch to origin state.
###
### # Examples
###
### ```
### git-reset-origin
### ```
git-reset-origin() {
    git fetch
    current_branch=$(git-current-branch)
    git reset --hard "origin/$current_branch"
}

### Reset the current branch to a specific commit.
###
### # Arguments
###
### * commit_hash - Target commit.
###
### # Examples
###
### ```
### git-reset-by-hash a1b2c3d
### ```
git-reset-by-hash() {
    local commit_hash="$1"

    git reset --hard "$commit_hash"
}

### Pull and rebase from origin for the current branch.
###
### # Examples
###
### ```
### git-pull-origin
### ```
git-pull-origin() {
    local current_branch
    current_branch="$(git-current-branch)"

    git fetch
    git pull origin "$current_branch" --rebase
}

### Pull a base branch and rebase the current branch.
###
### # Arguments
###
### * base_branch - Base branch name.
###
### # Examples
###
### ```
### git-pull-base-branch main
### ```
git-pull-base-branch() {
    local base_branch=${1:-main}
    local current_branch
    current_branch=$(git-current-branch)

    if [ -z "$current_branch" ]; then
        echo "Error: Could not determine current branch. Are you in a detached HEAD state?" >&2
        return 1
    fi

    if [ "$current_branch" = "$base_branch" ]; then
        echo "Already on the base branch. Just pulling." >&2
        git pull origin "$base_branch"
        return $?
    fi

    git switch "$base_branch"
    git pull origin "$base_branch"

    git switch "$current_branch"
    git rebase "$base_branch"
}

### Fetch origin and cherry-pick a commit.
###
### # Arguments
###
### * commit_hash - Commit hash.
###
### # Examples
###
### ```
### git-cherry-pick a1b2c3d
### ```
git-cherry-pick() {
    local commit_hash=$1
    if [ -z "$commit_hash" ]; then
        echo "Error: Specify commit hash." >&2
        return 1
    fi

    git fetch --prune origin
    git cherry-pick "$commit_hash"
}

### Continue a cherry-pick operation.
###
### # Examples
###
### ```
### git-cherry-pick-continue
### ```
git-cherry-pick-continue() {
    git cherry-pick --continue
}

### Abort a cherry-pick operation.
###
### # Examples
###
### ```
### git-cherry-pick-abort
### ```
git-cherry-pick-abort() {
    git cherry-pick --abort
    git clean -fdx
}

### Push the current branch to origin.
###
### # Examples
###
### ```
### git-push-current-branch
### ```
git-push-current-branch() {
    current_branch=$(git-current-branch)
    git push origin "HEAD:$current_branch" --force-with-lease
}

### Push the current branch for Gerrit review.
###
### # Examples
###
### ```
### git-push-current-branch-for-gerrit
### ```
git-push-current-branch-for-gerrit() {
    current_branch=$(git-current-branch)
    git push origin "HEAD:refs/for/$current_branch"
}

### Push the current branch for Gerrit review as WIP.
###
### # Examples
###
### ```
### git-push-current-branch-for-gerrit-as-wip
### ```
git-push-current-branch-for-gerrit-as-wip() {
    current_branch=$(git-current-branch)
    git push origin "HEAD:refs/for/$current_branch%wip"
}

### Delete the current branch from origin.
###
### # Examples
###
### ```
### git-delete-branch
### ```
git-delete-branch() {
    current_branch=$(git-current-branch)
    git push origin -d "$current_branch"
}

### Initialize and update all submodules recursively.
###
### # Examples
###
### ```
### git-submodule-update-all
### ```
git-submodule-update-all() {
    git submodule update --init --recursive
}

### Fetch upstream and rebase the base branch.
###
### # Arguments
###
### * base_branch - Base branch name. Default is main.
###
### # Examples
###
### ```
### git-pull-upstream-base-branch main
### ```
git-pull-upstream-base-branch() {
    local base_branch=${1:-main}

    git fetch upstream
    git checkout "$base_branch"
    git rebase upstream/"$base_branch"
}

### Initialize a repo workspace with a manifest repository.
###
### # Arguments
###
### * url - Manifest repository URL.
### * branch - Manifest branch name.
### * manifest_file - Manifest XML file.
###
### # Examples
###
### ```
### repo-init https://example.com/manifest.git main default.xml
### ```
###
### The command initializes the repo workspace.
repo-init() {
    local url="$1"
    local branch="$2"
    local manifest_file="$3"
    repo init -u "$url" -b "$branch" -m "$manifest_file" --depth=1
}

### Sync projects in the repo workspace.
###
### # Arguments
###
### * path - Path to sync.
###
### # Examples
###
### ```
### repo-sync .
### ```
###
### The command downloads project sources.
repo-sync() {
    local -r path="$1"
    repo sync "$path" -c -d --force-sync -j 4
}

### Reset all projects in the repo workspace.
###
### # Examples
###
### ```
### repo-reset
### ```
###
### The command runs git reset --hard in each project.
repo-reset() {
    repo forall -c "git reset --hard"
}

### Output the current repo manifest.
###
### # Examples
###
### ```
### repo-manifest
### ```
###
### The command writes manifest.xml.
repo-manifest() {
    repo manifest -r -o ./manifest.xml
}

### Run git fsck in all repo projects.
###
### # Examples
###
### ```
### repo-check
### ```
repo-check() {
    repo forall -c "git fsck"
}

### Show running docker containers.
###
### # Examples
###
### ```
### docker-ps
### ```
docker-ps() {
    docker ps
}

### Show all docker containers including stopped ones.
###
### # Examples
###
### ```
### docker-ps-all
### ```
docker-ps-all() {
    docker ps -a
}

docker-pull() {
    local container="$1"
    local file="$2"
    local dest="${3:-.}"

    if [ -z "$container" ]; then
        return 1
    fi

    docker cp "$container:$file" "$dest"
}

### Run a command inside a container or open a shell.
###
### # Arguments
###
### * container - Container name or ID.
### * command - Optional command.
###
### # Examples
###
### ```
### docker-exec my-container
### docker-exec my-container ls /
### ```
docker-exec() {
    local container="$1"

    if [ -z "$container" ]; then
        return 1
    fi

    shift

    if [ $# -eq 0 ]; then
        docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
    else
        docker exec "$container" "$@"
    fi
}

### Follow logs of a docker container.
###
### # Arguments
###
### * container - Container name or ID.
###
### # Examples
###
### ```
### docker-logs my-container
### ```
docker-logs() {
    local container="$1"

    if [ -z "$container" ]; then
        echo "Error: "
        return 1
    fi

    docker logs -f "$container"
}

### Stop a docker container.
###
### # Arguments
###
### * container - Container name or ID.
###
### # Examples
###
### ```
### docker-stop my-container
### ```
docker-stop() {
    local container="$1"

    if [ -z "$container" ]; then
        return 1
    fi

    docker stop "$1"
}

### Start a docker container.
###
### # Arguments
###
### * container - Container name or ID.
###
### # Examples
###
### ```
### docker-start my-container
### ```
docker-start() {
    local container="$1"

    if [ -z "$container" ]; then
        return 1
    fi

    docker start "$1"
}

### Stop all running docker containers.
###
### # Examples
###
### ```
### docker-stop-all
### ```
docker-stop-all() {
    local ids=$(docker ps -q)
    if [ -z "$ids" ]; then
        return 0
    fi

    docker stop $(docker ps -q)
}

_docker-remove-all-containers() {
    local container_ids
    container_ids=$(docker ps -aq)

    if [ -z "$container_ids" ]; then
        return 0
    fi

    docker ps -aq | tr '\n' '\0' | while read -u 3 -r -d '' container_id; do
        if [ -n "$container_id" ]; then
            docker rm -f "$container_id" # todo: verify if force removal is required for all instances
        fi
    done 3<&0
}

_docker-remove-all-volumes() {
    local volume_ids

    volume_ids="$(docker volume ls -q)"

    if [ -z "$volume_ids" ]; then
        return 0
    fi

    docker volume ls -q | tr '\n' '\0' | while IFS= read -r -d '' volume_id; do
        if [ -n "$volume_id" ]; then
            docker volume rm -f "$volume_id"
        fi
    done
}

docker-remove-all() {
_docker-remove-all-containers
_docker-remove-all-volumes
}

### Prompts the user to select a file from a list and pulls it.
###
### # Arguments
###
### * file_list_text - The text containing files separated by newline.
### * output_dir - The local directory.
###
### # Examples
###
### ```bash
### _adb-pull-with-select "log1\nlog2" "."
### ```
###
### The following text shows the interaction.
### 
### ```text
### 1) log1
### 2) log2
### #? 1
### ```
_adb-pull-with-select() {
    local file_list_text="$1"
    local output_dir="${2:-.}"
    local -a file_array=()

    while read -u 3 -r line; do
        [[ -z "$line" ]] && continue
        file_array+=("$line")
    done 3<<< "$file_list_text"

    select selected_path in "${file_array[@]}"; do
        [[ -n "$selected_path" ]] && adb-pull "$selected_path" "$output_dir"
        break
    done
}

### Wait for an adb device to connect.
###
### # Examples
###
### ```
### adb-wait-for-device
### ```
adb-wait-for-device() {
    adb wait-for-device
}

### Pulls a file from an Android device to a local directory.
###
### # Arguments
###
### * target_path - The file on the device.
### * output_dir - The local directory.
###
### # Examples
###
### ```bash
### adb-pull "/var/log/dlt/0000.log" "."
### ```
###
### The following text shows an example output.
###
### ```text
### /var/log/dlt/0000.log: 1 file pulled.
### ```
adb-pull() {
    local target_path="$1"
    local output_dir="${2:-.}"

    [[ -z "$target_path" ]] && return 1

    mkdir -p "$output_dir"
    adb pull "$target_path" "$output_dir"
}

### Clear adb logcat buffer.
###
### # Examples
###
### ```
### adb-logcat-clear
### ```
adb-logcat-clear() {
    adb logcat -c
}

### Show adb logcat output.
###
### # Examples
###
### ```
### adb-logcat
### ```
adb-logcat() {
    adb logcat
}

### Acquire a wake lock on the device.
###
### # Examples
###
### ```
### adb-wake-lock
### ```
adb-wake-lock() {
    adb root
    adb shell 'echo debug > /sys/power/wake_lock'
}

### Release the wake lock on the device.
###
### # Examples
###
### ```
### adb-wake-unlock
### ```
adb-wake-unlock() {
    adb root
    adb shell 'echo debug > /sys/power/wake_unlock'
}

### Show current wake lock state.
###
### # Examples
###
### ```
### adb-cat-wake-lock
### ```
adb-cat-wake-lock() {
    adb root
    adb shell 'cat /sys/power/wake_lock'
}

### Reboot the device and restore wake lock.
###
### # Examples
###
### ```
### adb-reboot
### ```
adb-reboot() {
    adb reboot
    adb wait-for-device
    adb-wake-lock
}

### Get the first connected adb device ID.
###
### # Examples
###
### ```
### adb-first-device
### ```
###
### The command prints a device serial.
adb-first-device() {
    adb devices | grep -w device | head -1 | awk '{print $1}'
}

### Unlock the device bootloader.
###
### # Examples
###
### ```
### adb-bootloader-unlock
### ```
adb-bootloader-unlock() {
    adb reboot bootloader
    sleep 7
    fastboot flashing unlock
    fastboot reboot
    adb wait-for-device
}

### Disable dm-verity on the device.
###
### # Examples
###
### ```
### adb-disable-verity
### ```
adb-disable-verity() {
    adb root
    adb disable-verity
    adb reboot
    adb wait-for-device
}

### Remount root filesystem as read-write.
###
### # Examples
###
### ```
### adb-remount
### ```
adb-remount() {
    adb root
    adb remount
    adb shell 'mount -o rw,remount /'
}

### Wait until a file appears.
###
### # Arguments
###
### * file - Target file path.
### * timeout_sec - Timeout seconds.
###
### # Examples
###
### ```
### adb-wait-for-file /tmp/test.txt 30
### ```
adb-wait-for-file() {
    local file="$1"
    local timeout_sec="${2:-30}"
    local count=0

    while [ $count -lt $timeout_sec ]; do
        if [ -f "$file" ]; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done

    return 1
}

### Print device build and kernel information.
###
### # Examples
###
### ```
### adb-pkg-info
### ```
adb-pkg-info() {
    adb root
    adb shell "getprop | grep -E '\[ro.product.build.fingerprint\]'"
    adb shell "getprop | grep -E '\[ro.build.date\]'"
    adb shell "getprop | grep -E '\[ro.boot.slot_suffix\]'"
    adb shell 'cat /proc/version'
}

### Capture a screenshot from the device.
###
### # Examples
###
### ```
### adb-screencap
### ```
adb-screencap() {
    datetime=$(datetime-for-filename)
    mkdir "$WORK_DIR/$datetime/" -p
    adb exec-out screencap -p >"$WORK_DIR/$datetime/$datetime-adb-image.png"
}

### Run a screenshot capture loop.
###
### # Examples
###
### ```
### adb-screencap-loop
### ```
adb-screencap-loop() {
    echo "Open $HOME/projects/m6/bin/screencap-loop/screencap-result.html in Web browser"
    $HOME/projects/m6/bin/screencap-loop/screencap-loop.sh
}

adb-partition-hash() {
    local partition="$1"

    if [ -z "$partition" ]; then
        echo "Error: パーティションを指定してください。"
        return 1
    fi

    adb root
    adb shell "sha256sum ${partition}"
}

### Generate SELinux allow rules from audit log.
###
### # Arguments
###
### * log - Audit log file path.
###
### # Examples
###
### ```
### selinux-generate-rule audit.log
### ```
selinux-generate-rule() {
    local -r log_file="$1"
    local -r log_dir=$(dirname "$log_file")

    cat "$log_file" | grep avc: | audit2allow >"$log_dir/selinux.txt"
}

process-id-by-cmd() {
    local cmdline="$1"
    pidof "$cmdline"
}

process-id-by-cmd-regex() {
    local cmdline="$1"
    pgrep -f "$cmdline"
}

process-trace-by-cmd() {
    local cmdline="$1"
    local pid
    pid=$(process-id-by-cmd "$cmdline");
    process-trace-by-pid $pid
}

process-trace-by-pid() {
    local pid="$1"
    ps -T -p $pid -opid,lwp,comm,args
}

systemcall-trace-by-cmd() {
    local cmdline="$1"
    PID=$(process-id-by-cmd "$cmdline");

    systemcall-trace-by-pid "$PID"
}

systemcall-trace-by-pid() {
    local pid="$1"

    if [ -z "$pid" ]; then
        echo "Usage: systemcall-trace-by-pid <PID>"
        return 1
    fi

    strace -p "$pid" -T -tt
}

library-trace-by-cmd() {
    local cmdline="$1"
    local pid

    pid="$(process-id-by-cmd "$cmdline")"

    if [ -z "$pid" ]; then
        echo "Process not found: $cmdline"
        return 1
    fi

    library-trace-by-pid "$pid"
}

library-trace-by-pid() {
    local pid="$1"

    if [ -z "$pid" ]; then
        echo "Usage: library-trace-by-pid <PID>"
        return 1
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Invalid PID: $pid"
        return 1
    fi

    sudo ltrace \
        -p "$pid" \
        -f \
        -S \
        -tt \
        -T \
        -s 256
}

### Attach gdb to process.
###
### # Arguments
###
### * pid - Process ID
###
### # Examples
###
### ```
### gdb-attach-pid 1234
### ```
###
### The following output is displayed.
###
### ```text
### Attaching to process 1234
### ```
gdb-attach-pid() {
    local pid="$1"

    if [ -z "$pid" ]; then
        echo "usage: gdb-attach-pid <pid>" >&2
        return 1
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        echo "process not found: $pid" >&2
        return 1
    fi

    gdb \
        -q \
        -batch \
        -p "$pid" \
        -ex "thread apply all bt"
}

### Attach gdb by command line pattern.
###
### # Arguments
###
### * command_pattern - Process command pattern
###
### # Examples
###
### ```
### gdb-attach-by-cmd /path/to/my-server
### ```
gdb-attach-by-cmd() {
    local cmdline="$1"
    local pid

    pid="$(process-id-by-cmd "$cmdline")"

    if [ -z "$pid" ]; then
        echo "process not found: $command_pattern" >&2
        return 1
    fi

    gdb-attach-pid "$pid"
}

### Start gdbserver.
###
### # Arguments
###
### * port - Listen port
### * command - Target command
###
### # Examples
###
### ```
### gdb-server 1234 ./app
### ```
###
### The following output is displayed.
###
### ```text
### Listening on port 1234
### ```
gdb-server() {
    local port="$1"

    shift

    if [ -z "$port" ]; then
        echo "usage: gdb-server <port> <command> [args...]" >&2
        return 1
    fi

    if [ "$#" -eq 0 ]; then
        echo "command required" >&2
        return 1
    fi

    case "$port" in
        ''|*[!0-9]*)
            echo "invalid port: $port" >&2
            return 1
            ;;
    esac

    if ! command -v gdbserver >/dev/null 2>&1; then
        echo "gdbserver not found" >&2
        return 1
    fi

    gdbserver ":${port}" "$@"
}

### Connect remote gdb target.
###
### # Arguments
###
### * elf_file - ELF file path
### * target_host - Remote host
### * target_port - Remote port
###
### # Examples
###
### ```
### gdb-remote ./app 192.168.1.10 1234
### ```
gdb-remote() {
    local elf_file="$1"
    local target_host="$2"
    local target_port="$3"

    if [ -z "$elf_file" ]; then
        echo "usage: gdb-remote <elf-file> <host> <port>" >&2
        return 1
    fi

    if [ -z "$target_host" ]; then
        echo "host required" >&2
        return 1
    fi

    if [ -z "$target_port" ]; then
        echo "port required" >&2
        return 1
    fi

    if [ ! -f "$elf_file" ]; then
        echo "file not found: $elf_file" >&2
        return 1
    fi

    case "$target_port" in
        ''|*[!0-9]*)
            echo "invalid port: $target_port" >&2
            return 1
            ;;
    esac

    if ! command -v gdb >/dev/null 2>&1; then
        echo "gdb not found" >&2
        return 1
    fi

    gdb \
        -- "$elf_file" \
        -ex "target remote ${target_host}:${target_port}"
}

### Start gdb and break at function.
###
### # Arguments
###
### * elf_file - ELF file path
### * symbol_name - Break symbol
###
### # Examples
###
### ```
### gdb-break ./app main
### ```
gdb-break() {
    local elf_file="$1"
    local symbol_name="$2"

    if [ -z "$elf_file" ]; then
        echo "usage: gdb-break <elf-file> <symbol>" >&2
        return 1
    fi

    if [ -z "$symbol_name" ]; then
        echo "symbol required" >&2
        return 1
    fi

    if [ ! -f "$elf_file" ]; then
        echo "file not found: $elf_file" >&2
        return 1
    fi

    if ! command -v gdb >/dev/null 2>&1; then
        echo "gdb not found" >&2
        return 1
    fi

    gdb \
        -- "$elf_file" \
        -ex "break ${symbol_name}" \
        -ex run
}

### Open core dump.
###
### # Arguments
###
### * elf_file - ELF file path
### * core_file - Core dump path
###
### # Examples
###
### ```
### gdb-coredump ./app core.1234
### ```
gdb-coredump() {
    local elf_file="$1"
    local core_file="$2"

    if [ -z "$elf_file" ]; then
        echo "usage: gdb-coredump <elf-file> <core-file>" >&2
        return 1
    fi

    if [ -z "$core_file" ]; then
        echo "core file required" >&2
        return 1
    fi

    if [ ! -f "$elf_file" ]; then
        echo "file not found: $elf_file" >&2
        return 1
    fi

    if [ ! -f "$core_file" ]; then
        echo "file not found: $core_file" >&2
        return 1
    fi

    if ! command -v gdb >/dev/null 2>&1; then
        echo "gdb not found" >&2
        return 1
    fi

    gdb \
        -- "$elf_file" \
        "$core_file"
}

### Show device tree nodes.
###
### # Examples
###
### ```
### device-tree
### ```
device-tree() {
    if [ ! -d /proc/device-tree ]; then
        echo "/proc/device-tree not found" >&2
        return 1
    fi

    find /proc/device-tree -maxdepth 2 -print
}

### Show I2C buses.
###
### # Examples
###
### ```
### i2c-buses
### ```
i2c-buses() {
    if ! command -v i2cdetect >/dev/null 2>&1; then
        echo "i2cdetect not found" >&2
        return 1
    fi

    i2cdetect -l
}

### Scan I2C devices.
###
### # Arguments
###
### * bus_id - I2C bus number
###
### # Examples
###
### ```
### i2c-devices 1
### ```
i2c-devices() {
    local bus_id="$1"

    if [ -z "$bus_id" ]; then
        echo "usage: i2c-devices <bus-id>" >&2
        return 1
    fi

    case "$bus_id" in
        ''|*[!0-9]*)
            echo "invalid bus id: $bus_id" >&2
            return 1
            ;;
    esac

    if ! command -v i2cdetect >/dev/null 2>&1; then
        echo "i2cdetect not found" >&2
        return 1
    fi

    i2cdetect -y "$bus_id"
}

### Show GPIO lines.
###
### # Examples
###
### ```
### gpio-devices
### ```
gpio-devices() {
    if ! command -v gpioinfo >/dev/null 2>&1; then
        echo "gpioinfo not found" >&2
        return 1
    fi

    gpioinfo
}

### Show USB devices.
###
### # Examples
###
### ```
### usb-devices
### ```
usb-devices() {
    if ! command -v lsusb >/dev/null 2>&1; then
        echo "lsusb not found" >&2
        return 1
    fi

    lsusb
}

### Show PCI devices.
###
### # Examples
###
### ```
### pci-devices
### ```
pci-devices() {
    if ! command -v lspci >/dev/null 2>&1; then
        echo "lspci not found" >&2
        return 1
    fi

    lspci
}

### Convert an AsciiDoc file to HTML.
###
### # Arguments
###
### * adoc_file - Input AsciiDoc file.
### * output_dir - Output directory.
###
### # Examples
###
### ```
### adoc-generate-html doc.adoc output
### ```
adoc-generate-html() {
    local adoc_file="$1"
    local output_dir="${2:-.}"

    mkdir -p "$output_dir"

    asciidoctor -r asciidoctor-diagram -D "$output_dir" "$adoc_file"
}

### Restart Jenkins service.
###
### # Examples
###
### ```
### jenkins-restart
### ```
jenkins-restart() {
    sudo systemctl restart jenkins.service
}

### Run Flutter app on Chrome in release mode.
###
### # Examples
###
### ```
### flutter-run-chrome-release
### ```
flutter-run-chrome-release() {
    flutter run -d chrome --release
}

### Run Flutter app on Linux in release mode.
###
### # Examples
###
### ```
### flutter-run-linux-release
### ```
flutter-run-linux-release() {
    flutter run -d linux --release
}

### Run Flutter tests.
###
### # Examples
###
### ```
### flutter-test
### ```
flutter-test() {
    flutter test
}

### Run Flutter tests with coverage report.
###
### # Examples
###
### ```
### flutter-coverage
### ```
flutter-coverage() {
    flutter test --no-pub --coverage
    genhtml coverage/lcov.info -o coverage/html
}

### Open a new gnome-terminal and run a command.
###
### # Arguments
###
### * cmd - Command to run.
###
### # Examples
###
### ```
### gnome-terminal-bash "ls -l"
### ```
gnome-terminal-bash() {
    cmd="$1"

    gnome-terminal -- bash -c "echo '$ $cmd' >&2; $cmd; exec bash"
}

systemctl-path() {
    local name="$1"
    systemctl show "$name" -p FragmentPath
}

systemctl-depends() {
    local name="$1"
    systemctl show "$name" -p After -p Requires -p Wants | cat
}

### Restart a systemd service.
###
### # Arguments
###
### * service - Service name.
###
### # Examples
###
### ```
### systemctl-restart nginx
### ```
systemctl-restart() {
    sudo systemctl restart $1
}

### Start a systemd service.
###
### # Arguments
###
### * service - Service name.
###
### # Examples
###
### ```
### systemctl-start nginx
### ```
systemctl-start() {
    sudo systemctl start $1
}

### Stop a systemd service.
###
### # Arguments
###
### * service - Service name.
###
### # Examples
###
### ```
### systemctl-stop nginx
### ```
systemctl-stop() {
    sudo systemctl stop $1
}

### Enable a systemd service.
###
### # Arguments
###
### * service - Service name.
###
### # Examples
###
### ```
### systemctl-enable nginx
### ```
systemctl-enable() {
    sudo systemctl enable $1
}

### Disable a systemd service.
###
### # Arguments
###
### * service - Service name.
###
### # Examples
###
### ```
### systemctl-disable nginx
### ```
systemctl-disable() {
    sudo systemctl disable $1
}

### Check if a systemd service is enabled.
###
### # Arguments
###
### * service - Service name.
###
### # Examples
###
### ```
### systemctl-is-enabled nginx
### ```
systemctl-is-enabled() {
    systemctl is-enabled $1
}

### List running service units.
###
### # Examples
###
### ```
### systemctl-list-service-units
### ```
systemctl-list-service-units() {
    systemctl list-units --type=service
}

### List service unit files.
###
### # Examples
###
### ```
### systemctl-list-service-unit-files
### ```
systemctl-list-service-unit-files() {
    systemctl list-unit-files --type=service
}
