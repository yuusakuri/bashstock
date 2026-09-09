#!/bin/bash

### Keeps sudo authentication alive during long-running scripts.
###
### # Examples
###
### ```
### sudo-keep-alive
### ```
###
### The command periodically refreshes the sudo timestamp.
sudo-keep-alive() {
    sudo -v

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

env-import() {
    local env_file="$1"
    set -a
    source "$env_file"
    set +a
}

### Write content to a file with root privileges.
###
### # Arguments
###
### * file_path - Target file path.
### * content - Text to write.
###
### # Examples
###
### ```
### file-write-as-root /etc/test.conf "value=1"
### ```
file-write-as-root() {
    local file_path="$1"
    local content="$2"

    echo "$content" | sudo tee "$file_path" >/dev/null
}

### Write content to a file.
###
### # Arguments
###
### * file_path - Target file path.
### * content - Text to write.
###
### # Examples
###
### ```
### file-write ./file.txt "hello"
### ```
file-write() {
    local file_path="$1"
    local content="$2"

    echo "$content" >"$file_path"
}

### Replace lines matching a pattern or append the content (root).
###
### # Arguments
###
### * file_path - Target file.
### * pattern - Pattern to remove.
### * content - Line to append.
###
### # Examples
###
### ```
### file-replace-or-append-line-as-root /etc/sysctl.conf "vm.swappiness" "vm.swappiness=10"
### ```
file-replace-or-append-line-as-root() {
    local file_path="$1"
    local pattern="$2"
    local content="$3"

    local escaped_pattern
    escaped_pattern=$(echo "$pattern" | sed 's/|/\\|/g')

    if sudo grep -qE "$escaped_pattern" "$file_path" 2>/dev/null; then
        local new_buffer
        new_buffer=$(sudo sed "\|$escaped_pattern|d" "$file_path")

        file-write-as-root "$file_path" "$new_buffer"
    fi

    echo "$content" | sudo tee -a "$file_path" >/dev/null
}

### Replace lines matching a pattern or append the content.
###
### # Arguments
###
### * file_path - Target file.
### * pattern - Pattern to remove.
### * content - Line to append.
###
### # Examples
###
### ```
### file-replace-or-append-line ~/.bashrc "export PATH" "export PATH=\$PATH:/opt/bin"
### ```
file-replace-or-append-line() {
    local file_path="$1"
    local pattern="$2"
    local content="$3"

    local escaped_pattern
    escaped_pattern=$(echo "$pattern" | sed 's/|/\\|/g')

    if grep -qE "$escaped_pattern" "$file_path" 2>/dev/null; then
        local new_buffer
        new_buffer=$(sed "\|$escaped_pattern|d" "$file_path")

        file-write "$file_path" "$new_buffer"
    fi

    echo "$content" | tee -a "$file_path" >/dev/null
}

### Add an environment variable to shell configuration files.
###
### # Arguments
###
### * variable_name - Environment variable name.
### * variable_value - Environment variable value.
###
### # Examples
###
### ```
### env-add-variable ANDROID_HOME "$HOME/Android/Sdk"
### ```
env-add-variable() {
    local variable_name="$1"
    local variable_value="$2"
    local config_files=("$HOME/.bashrc" "$HOME/.zshrc")

    if [ -z "$variable_name" ] || [ -z "$variable_value" ]; then
        echo "Error: Variable name and value are required" >&2
        return 1
    fi

    local current_value=$(eval "echo \$$variable_name")

    if [ -n "$current_value" ]; then
        if [ "$current_value" = "$variable_value" ]; then
            return 0
        fi
    fi

    for config_file in "${config_files[@]}"; do
        echo "" >>"$config_file"
        echo "export $variable_name=\"$variable_value\"" >>"$config_file"
    done

    export "$variable_name"="$variable_value"
}

### Add a directory to PATH in shell configuration files.
###
### # Arguments
###
### * new_path - Path to add.
###
### # Examples
###
### ```
### env-add-path "$HOME/.local/bin"
### ```
env-add-path() {
    local new_path="$1"
    local config_files=("$HOME/.bashrc" "$HOME/.zshrc")

    if [ -z "$new_path" ]; then
        return 1
    fi

    if [[ ":$PATH:" == *":$new_path:"* ]]; then
        return 0
    fi

    for config_file in "${config_files[@]}"; do
        echo "" >>"$config_file"
        echo "export PATH=\$PATH:$new_path" >>"$config_file"
    done

    export PATH="$PATH:$new_path"
}

# Editor to VSCode
editor-to-vscode() {
    local pattern="export EDITOR=\"code --wait\""
    local content="export EDITOR=\"code --wait\""

    file-replace-or-append-line "$HOME/.zshrc" "$pattern" "$content"
    file-replace-or-append-line "$HOME/.bashrc" "$pattern" "$content"
}

env-register() {
    local env_file="$1"

    local pattern="env-import \"$env_file\""
    local content="env-import \"$env_file\""

    file-replace-or-append-line "$HOME/.zshrc" "$pattern" "$content"
    file-replace-or-append-line "$HOME/.bashrc" "$pattern" "$content"
}

_dict-ensure-file() {
    local file="$1"

    if [ -s "$file" ]; then
        return 0
    fi

    printf "{\n}\n" >"$file"
}

_dict-escape-key() {
    local key="$1"
    printf '%s\n' "$key" | sed 's/[.[\*^$(){}+?|]/\\&/g'
}

_dict-replace-key() {
    local file="$1"
    local key="$2"
    local value="$3"

    local escaped_key
    escaped_key=$(_dict-escape-key "$key")

    awk -v k="$key" -v v="$value" -v ek="$escaped_key" '
    BEGIN { replaced = 0 }
    {
        if ($0 ~ "^[[:space:]]*\"?" ek "\"?[[:space:]]*=") {
            printf "    \"%s\" = %s;\n", k, v
            replaced = 1
        } else {
            print $0
        }
    }
    END {
        if (replaced == 0) {
            # no-op
        }
    }
    ' "$file"
}

_dict-insert-key() {
    local file="$1"
    local key="$2"
    local value="$3"

    awk -v k="$key" -v v="$value" '
    /^[[:space:]]*\}[[:space:]]*$/ {
        printf "    \"%s\" = %s;\n", k, v
    }
    { print }
    ' "$file"
}

dict-set-value() {
    local file="$1"
    local key="$2"
    local value="$3"

    local dir
    dir=$(dirname "$file")

    mkdir -p "$dir"
    _dict-ensure-file "$file"

    local escaped_key
    escaped_key=$(_dict-escape-key "$key")

    local content

    if grep -q -E "^[[:space:]]*\"?${escaped_key}\"?[[:space:]]*=" "$file"; then
        content=$(_dict-replace-key "$file" "$key" "$value")
    else
        content=$(_dict-insert-key "$file" "$key" "$value")
    fi

    printf '%s\n' "$content" >"$file"
}

### Create a symbolic link.
###
### # Arguments
###
### * source - Source path.
### * destination - Link path.
###
### # Examples
###
### ```
### symlink-create ./script.sh ~/.local/bin/script
### ```
symlink-create() {
    local source="$1"
    local destination="${2%/}"

    if [ -d "$destination" ] && [ ! -L "$destination" ]; then
        rmdir "$destination" 2>/dev/null || return 1
    fi

    ln -sfn "$(realpath "$source")" "$destination"
}

### Remove a symbolic link.
###
### # Arguments
###
### * destination - Link path.
###
### # Examples
###
### ```
### symlink-remove ~/.local/bin/script
### ```
symlink-remove() {
    local destination="${1%/}"

    sudo unlink "$destination"
}

### Create a symbolic link inside ~/.local/bin.
###
### # Arguments
###
### * source - Source file.
### * link_name - Optional link name.
###
### # Examples
###
### ```
### symlink-create-to-local-bin ./tool.sh
### ```
symlink-create-to-local-bin() {
    local source="$1"
    local link_name="${2:-$(basename "$source")}"
    local local_bin_dir="$HOME/.local/bin"
    local destination="$local_bin_dir/$link_name"

    mkdir -p "$local_bin_dir" >/dev/null
    symlink-create "$source" "$destination"
}

### Insert or update a key-value entry in a .textproto file.
###
### # Arguments
###
### * textproto_file - Target file.
### * key - Field name.
### * value - Field value.
###
### # Examples
###
### ```
### textproto-insert config.textproto active_on_launch True
### ```
textproto-insert() {
    local textproto_file=$1
    local key=$2
    local value=$3

    grep -q "^[[:space:]]*${key}:" "$textproto_file" 2>/dev/null
    local key_exists=$?

    if [ "$key_exists" -eq 0 ]; then
        local new_buffer
        new_buffer=$(sed "s/^[[:space:]]*${key}:.*/${key}: ${value}/" "$textproto_file")

        file-write "$textproto_file" "$new_buffer"
    else
        echo "${key}: ${value}" >>"$textproto_file"
    fi
}

autocomplete-to-ignore-case() {
    zsh-autocomplete-to-ignore-case
    bash-autocomplete-to-ignore-case
}

# Configures zsh autocomplete to ignore case when completing commands and filenames.
zsh-autocomplete-to-ignore-case() {
    zshrc_file="$HOME/.zshrc"
    pattern="autoload -Uz compinit && compinit"
    content="autoload -Uz compinit && compinit"

    file-replace-or-append-line "$zshrc_file" "$pattern" "$content"

    pattern="zstyle ':completion:\*' matcher-list 'm:\{a-z\}=\{A-Z\}'"
    content="zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'"
    file-replace-or-append-line "$zshrc_file" "$pattern" "$content"
}

# Configures bash autocomplete to ignore case when completing commands and filenames.
bash-autocomplete-to-ignore-case() {
    inputrc_file="$HOME/.inputrc"
    pattern="set completion-ignore-case"
    content="set completion-ignore-case on"

    file-replace-or-append-line "$inputrc_file" "$pattern" "$content"
}

### Remove stored Git credentials.
###
### # Examples
###
### ```
### git-rm-credentials
### ```
git-rm-credentials() {
    rm -f ~/.git-credentials
}

### Configure origin to fetch all branches.
###
### # Examples
###
### ```
### git-enable-origin-all-fetch
### ```
git-enable-origin-all-fetch() {
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
}

### Configure Git to prune deleted remote branches during fetch.
###
### # Examples
###
### ```
### git-set-prune-fetch
### ```
git-set-prune-fetch() {
    git config --global fetch.prune true
}

### Configure Git default branch name to main.
###
### # Examples
###
### ```
### git-set-default-branch-to-main
### ```
git-set-default-branch-to-main() {
    git config --global init.defaultBranch main
}

### Configure Git pull to use rebase by default.
###
### # Examples
###
### ```
### git-set-rebase-on-pull
### ```
git-set-rebase-on-pull() {
    git config --global pull.rebase true
}

git-set-email() {
    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
        return
    fi

    printf "Enter your Git email address: "
    read email
    if [ -n "$email" ]; then
        git config --global user.email "$email"
    fi
}

git-set-username() {
    if [ -n "$GIT_USERNAME" ]; then
        git config --global user.name "$GIT_USERNAME"
        return
    fi

    printf "Enter your Git user name: "
    read username
    if [ -n "$username" ]; then
        git config --global user.name "$username"
    fi
}

### Configure Git HTTP post buffer size to 500MB.
###
### # Examples
###
### ```
### git-set-http-buffer-to-500-mb
### ```
git-set-http-buffer-to-500-mb() {
    git config --global http.postBuffer 524288000
}

### Store Git passwords in a plain text file.
###
### # Examples
###
### ```bash
### git-set-store-credential-with-plaintext
### ```
git-set-store-credential-with-plaintext() {
    git config --global credential.helper store
}

### Use GPG to encrypt and store Git passwords.
###
### # Examples
###
### ```bash
### git-set-store-credential-with-gpg
### ```
git-set-store-credential-with-gpg() {
    git config --global credential.credentialStore gpg
    echo "GitHubの\`SSH and GPG keys\`にGPG publicキー (\`gpg-public-key\`の出力内容) を登録してください。"
}

### Use Git Credential Manager to store passwords safely.
###
### # Examples
###
### ```bash
### git-set-store-credential-with-manager
### ```
git-set-store-credential-with-manager() {
    git config --global credential.helper manager
}

_git-setup-common() {
    git-set-email
    git-set-username
    git-set-default-branch-to-main
    git-set-rebase-on-pull
    git-set-prune-fetch
}

pass-init-gpg() {
    gpg_key="${1:-$(gpg-secret-key)}"
    file-replace-or-append-line "$HOME/.profile" "export GPG_TTY" 'export GPG_TTY=$(tty)'
    source ~/.profile

    rm -rf ~/.password-store
    pass init "$gpg_key"
}

### Generate a new GPG key pair.
###
### # Arguments
###
### * email - User email.
### * full_name - User name.
###
### # Examples
###
### ```
### gpg-generate-key user@example.com "User Name"
### ```
gpg-generate-key() {
    local email="$1"
    local full_name="$2"

    gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: EdDSA
Key-Curve: ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: cv25519
Subkey-Usage: encr
Name-Real: "$full_name"
Name-Email: "$email"
Expire-Date: 5y
%commit
EOF
}

### Decrypt a GPG encrypted file.
###
### # Arguments
###
### * gpg_file - Encrypted file.
###
### # Examples
###
### ```
### gpg-decrypt secret.gpg
### ```
gpg-decrypt() {
    local gpg_file="$1"

    gpg -d "$gpg_file"
    echo
}

### Export a GPG public key.
###
### # Arguments
###
### * key_id - Optional key ID.
###
### # Examples
###
### ```
### gpg-public-key
### ```
gpg-public-key() {
    local gpg_key="${1:-$(gpg-secret-key)}"
    gpg --armor --export "$gpg_key"
}

### Get the fingerprint of the first secret key.
###
### # Examples
###
### ```
### gpg-secret-key
### ```
gpg-secret-key() {
    gpg --with-colons --fingerprint --list-secret-keys | awk -F: '$1=="fpr"{print $10;exit}' | grep -v 'gpg: '
}

gpg-keypair() {
    gpg --list-secret-keys --keyid-format=long
}

gpg-public-key() {
    gpg_key="${1:-$(gpg-secret-key)}"
    gpg --armor --export "$gpg_key"
}

gpg-setup-new() {
    local email="$1"
    local full_name="$2"
    local gpg_key
    gpg-generate-key "$email" "$full_name"
    gpg_key=$(gpg-secret-key)
    gpg-keypair

    pass-install
    pass-init-gpg "$gpg_key"
    git-config-use-credential-manager
    git-config-use-gpg
    gpg-public-key "$gpg_key"
}

### Generate an RSA SSH key.
###
### # Arguments
###
### * comment - Key comment.
### * password - Passphrase.
###
### # Examples
###
### ```
### ssh-generate-key-rsa user@example.com
### ```
ssh-generate-key-rsa() {
    local key_type="rsa"
    local key_bit_count="4096"
    local key_comment="$1"
    local key_path="$HOME/.ssh/id_rsa"
    local key_password="$2"

    rm -f $key_path
    rm -f $key_path.pub
    ssh-keygen -q -t "$key_type" -b "$key_bit_count" -C "$key_comment" -f "$key_path" -N "$key_password"
    cat $key_path.pub
}

### Generate an ED25519 SSH key.
###
### # Arguments
###
### * comment - Key comment.
### * password - Passphrase.
###
### # Examples
###
### ```
### ssh-generate-key-ed25519 user@example.com
### ```
ssh-generate-key-ed25519() {
    local key_type="ed25519"
    local key_comment="$1"
    local key_path="$HOME/.ssh/id_ed25519"
    local key_password="$2"

    rm -f $key_path
    rm -f $key_path.pub
    ssh-keygen -q -t "$key_type" -C "$key_comment" -f "$key_path" -N "$key_password"
    cat $key_path.pub
}

ssh-kill-all() {
    pkill -u $(whoami) ssh
}

### Update ssh config content
###
### # Arguments
###
### * file - config file
### * host - target host
### * key - key
### * val - value
ssh-update-config() {
    local file="$1"
    local host="$2"
    local key="$3"
    local val="$4"

    local content
    content=$(awk -v thost="$host" -v tkey="$key" -v tval="$val" '
    function tolower_str(s) { return tolower(s) }

    BEGIN { in_host=0; host_found=0; key_found=0; line_count=0 }

    {
        line_count++
    }

    tolower($1) == "host" {
        if (in_host && !key_found) {
            print "  " tkey " " tval
            key_found=1
        }

        patterns=""
        for (i=2; i<=NF; i++) {
            patterns = patterns " " $i
        }

        split(patterns, arr, " ")
        found=0
        for (i in arr) {
            if (arr[i] == thost) {
                found=1
            }
        }

        in_host=found
        if (found) host_found=1

        print $0
        next
    }

    in_host && tolower_str($1) == tolower_str(tkey) {
        print "  " tkey " " tval
        key_found=1
        next
    }

    { print }

    END {
        if (in_host && !key_found) {
            print "  " tkey " " tval
        } else if (!host_found) {
            if (line_count > 0) print ""
            print "Host " thost
            print "  " tkey " " tval
        }
    }
    ' "$file")

    if [ -z "$content" ]; then
        echo "error"
        return 1
    fi

    printf "%s\n" "$content" >"$file"
}

### Set ssh config value
###
### # Arguments
###
### * host - host
### * key - key
### * val - value
ssh-set-config() {
    local host="$1"
    local key="$2"
    local val="$3"
    local file="${HOME}/.ssh/config"

    ssh-dir-setup
    ssh-update-config "$file" "$host" "$key" "$val"

    echo "done"
}

ssh-enable-auto-add-keys() {
    ssh-set-config "*" "AddKeysToAgent" "yes"
}

### Set SSH config to disable host key checking
###
### # Examples
###
### ```
### ssh-config-no-host-key-checking
### ```
###
### This command updates ~/.ssh/config so that host key checking is disabled for all hosts.
ssh-disable-host-key-checking() {
    ssh-set-config "*" "StrictHostKeyChecking" "no"
}

### List private key files in ~/.ssh
###
### # Examples
###
### ```
### ssh-private-key-files
### ```
###
### This command prints private key file paths if they contain the string PRIVATE KEY.
###
### ```
### /home/user/.ssh/id_rsa
### /home/user/.ssh/github_key
### ```
ssh-private-key-files() {
    local ssh_dir="$HOME/.ssh"

    if [ ! -d "$ssh_dir" ]; then
        return 1
    fi

    find "$ssh_dir" -maxdepth 1 -type f -exec grep -l "PRIVATE KEY" {} +
}

### Add all private keys to ssh-agent
###
### # Examples
###
### ```
### ssh-add-all-private-keys
### ```
###
### This command loads all detected private keys into ssh-agent.
ssh-add-all-private-keys() {
    while read -u 3 -r key; do
        if [ -n "$key" ]; then
            ssh-add "$key"
        fi
    done 3< <(ssh-private-key-files)
}

### Prepare ~/.ssh directory and permissions
###
### # Examples
###
### ```
### ssh-dir-setup
### ```
###
### This command creates ~/.ssh if missing and fixes file permissions.
ssh-dir-setup() {
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"
    local ssh_authorized_keys="$ssh_dir/authorized_keys"
    local current_user
    local current_group

    current_user=$(whoami)
    current_group=$(id -gn "$current_user")

    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
    fi

    sudo chown -R "$current_user:$current_group" "$ssh_dir"

    chmod 700 "$ssh_dir"

    if [ ! -f "$ssh_config" ]; then
        touch "$ssh_config"
    fi

    if [ ! -f "$ssh_authorized_keys" ]; then
        touch "$ssh_authorized_keys"
    fi

    find "$ssh_dir" -type f -exec chmod 644 {} +

    local private_keys
    private_keys=$(ssh-private-key-files)

    if [ -n "$private_keys" ]; then
        echo "$private_keys" | xargs chmod 600
    fi

    chmod 600 "$ssh_authorized_keys"
    chmod 600 "$ssh_config"
}

### Test DNS resolution.
###
### # Arguments
###
### * dns_name - Domain name.
###
### # Examples
###
### ```
### net-test-dns google.com
### ```
net-test-dns() {
    local dns_name="$1"
    [[ -z "$dns_name" ]] && return 1
    nslookup "$dns_name"
}

### Test TCP connection to a host and port.
###
### # Arguments
###
### * host - Target host.
### * port - Target port.
###
### # Examples
###
### ```
### net-test-connection example.com 443
### ```
net-test-connection() {
    local host="$1" port="$2"
    [[ -z "$host" || -z "$port" ]] && return 1
    nc -zv "$host" "$port"
}

### Test network connectivity using ping.
###
### # Examples
###
### ```
### net-test-google
### ```
net-test-google() {
    ping -c 3 google.com
}
### Download and run a script that converts dynamic IP to static IP.
###
### # Examples
###
### ```
### net-ip-to-static
### ```
###
### The following behavior occurs. The script is downloaded and executed.
###
net-ip-to-static() {
    url="https://raw.githubusercontent.com/projects-by-ac/dynamic-to-static-ip/main/static-ip.sh"
    file="/tmp/static-ip.sh"

    curl -fsSL "$url" -o "$file"
    chmod +x "$file"
    "$file"
}

### Get Android command line tools download URL.
###
### # Arguments
###
### * os_type - OS type such as linux or mac.
###
### # Examples
###
### ```
### _android-commandlinetools-url linux
### ```
###
### The function prints the download URL.
###
### ```
### https://dl.google.com/android/repository/commandlinetools-linux-xxxx_latest.zip
### ```
###
_android-commandlinetools-url() {
    local os_type=$1

    local repository_url="https://dl.google.com/android/repository"
    local download_page_content=$(curl -sL "https://developer.android.com/studio")
    local filename=$(echo "$download_page_content" | grep -o "commandlinetools-${os_type}-[0-9]*_latest.zip" | head -n 1)

    if [[ -n "$filename" ]]; then
        echo "${repository_url}/${filename}"
    else
        echo "Error: Could not find the download URL on the page." >&2
        return 1
    fi
}

### Get latest Android build-tools version from sdkmanager.
###
### # Examples
###
### ```
### _android-build-tools-latest-version
### ```
###
### The function prints the latest version number.
###
### ```
### 34.0.0
### ```
###
_android-build-tools-latest-version() {
    local sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

    local latest_package=$("$sdkmanager" --list 2>/dev/null |
        grep -o "build-tools;[0-9.]\+" |
        sort -V |
        tail -n 1)

    if [[ -z "$latest_package" ]]; then
        echo "Error: Could not find any build-tools package." >&2
        return 1
    fi

    echo "${latest_package#*;}"
}

### Install Android command line tools and required packages.
###
### This function installs commandlinetools, platform-tools,
### and the latest build-tools using sdkmanager.
###
### # Examples
###
### ```
### android-commandlinetools-install
### ```
###
### The Android SDK is installed under ANDROID_HOME.
###
android-commandlinetools-install() {
    local sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    local build_tools_dir="$ANDROID_HOME/build-tools"

    if [[ -z "$ANDROID_HOME" ]]; then
        echo "Error: ANDROID_HOME is not set." >&2
        return 1
    fi

    rm -rf "$ANDROID_HOME"
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    pushd "$ANDROID_HOME" >/dev/null || return

    local url
    url=$(android-commandlinetools-url)

    curl -o "commandlinetools.zip" "$url"
    unzip -q commandlinetools.zip -d "$ANDROID_HOME/cmdline-tools"
    rm "./commandlinetools.zip"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"

    yes | "$sdkmanager" "platform-tools" >/dev/null

    local build_tools_latest_version=$(_android-build-tools-latest-version "$sdkmanager")
    yes | "$sdkmanager" "build-tools;$build_tools_latest_version" >/dev/null

    mkdir -p "$build_tools_dir"
    ln -sfn "$build_tools_latest_version" "$build_tools_dir/latest"

    popd >/dev/null || return

    env-add-path "$ANDROID_HOME/cmdline-tools/latest/bin"
    env-add-path "$ANDROID_HOME/platform-tools"
    env-add-path "$ANDROID_HOME/build-tools/latest"
}

### List installable Golang versions.
###
### # Examples
###
### ```
### golang-installable-versions
### ```
###
### The following output is printed.
###
### ```
### golang-1.21/
### golang-1.22/
### ```
###
golang-installable-versions() {
    apt search "golang-" | grep -iE "golang-[0-9]+\.[0-9]+/"
}

### Install Golang from apt repository.
###
### # Arguments
###
### * version - Optional version such as 1.21. If empty, default golang package is used.
###
### # Examples
###
### ```
### golang-install
### ```
###
### ```
### golang-install 1.21
### ```
###
golang-install() {
    local version="$1"
    local package_name

    if [ -z "$version" ]; then
        package_name="golang"
    else
        package_name="golang-$version"
    fi

    sudo add-apt-repository -y ppa:longsleep/golang-backports
    sudo apt update
    sudo apt install -y "$package_name"
}

### Install Rust using rustup.
###
### # Examples
###
### ```
### rust-install
### ```
###
### Rust toolchain is installed and cargo environment is loaded.
###
rust-install() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
}

### Change Flutter SDK version.
###
### # Arguments
###
### * version - Git tag or branch. If empty, stable channel is used.
###
### # Examples
###
### ```
### flutter-set-version
### ```
###
### ```
### flutter-set-version 3.16.0
### ```
###
flutter-set-version() {
    local version="$1"
    local flutter_root
    flutter_file="$(realpath "$(which flutter)")"
    flutter_root="$(dirname "$(dirname "$flutter_file")")"

    pushd "$flutter_root" >&2 || return 1

    if [[ -z "$version" ]]; then
        flutter channel stable
        flutter upgrade
    else
        git fetch
        git checkout "$version"
    fi

    popd || return 1

    flutter doctor
}

### Clear JFrog CLI configuration.
###
### # Examples
###
### ```
### jfrog-config-clear
### ```
###
jfrog-config-clear() {
    jfrog config clear
}

### Configure JFrog CLI authentication.
###
### # Arguments
###
### * jfrog_email - User email.
### * jfrog_token - Reference token.
### * url - Artifactory URL.
### * server_id - Optional server id.
###
### # Examples
###
### ```
### jfrog-setup user@example.com TOKEN https://example.jfrog.io
### ```
###
jfrog-setup() {
    local jfrog_email="$1"
    local jfrog_token="$2"
    local url="$3"
    local server_id="${4:-1}"

    if [[ -z "$jfrog_email" || -z "$jfrog_token" || -z "$url" ]]; then
        echo "Error: ユーザー名とパスワード(トークン)は必須です。"
        echo "Usage: jfrog-setup <EMAIL> <TOKEN> [URL] [SERVER_ID]"
        return 1
    fi

    JFROG_CLI_LOG_LEVEL=INFO jfrog config add "${server_id}" \
        --url="${url}" \
        --user="${jfrog_email}" \
        --password="${jfrog_token}" \
        --interactive=false \
        --overwrite

    echo "Testing connection to ${server_id}..."
    if jfrog rt ping --server-id="${server_id}"; then
        echo "Success: JFrog connection established."
    else
        echo "Failed: 接続に失敗しました。ネットワークやトークンを確認してください。"
        return 1
    fi
}

antigravity-cli-install() {
    curl -fsSL https://antigravity.google/cli/install.sh | bash
    agy auth login
}

codex-install() {
    npm i -g @openai/codex
    codex login
}

claude-code-install() {
    npm install -g @anthropic-ai/claude-code
    claude
}

opencode-install() {
    npm install -g opencode-ai
}

### Login to Docker registry hosted on Artifactory.
###
### # Arguments
###
### * jfrog_email - User email.
### * jfrog_token - Access token.
### * artifactory_url - Registry URL.
###
### # Examples
###
### ```
### docker-login-artifactory user@example.com TOKEN registry.example.com
### ```
###
docker-login-artifactory() {
    local jfrog_email=$1
    local jfrog_token=$2
    local artifactory_url=$3

    if [ -z "$jfrog_email" ] || [ -z "$jfrog_token" ] || [ -z "$artifactory_url" ]; then
        echo "Usage: tmc-docker-login <EMAIL> <TOKEN> <URL>"
        return 1
    fi

    echo "$jfrog_token" | docker "$artifactory_url" -u "$jfrog_email" --password-stdin
}

### Export Google Chrome bookmarks from a profile directory.
###
### # Arguments
###
### * profile_dir - Chrome profile directory path.
### * output_file - Optional destination file path.
###
### # Examples
###
### ```
### chrome-export-bookmarks "$HOME/.config/google-chrome/Default"
### ```
###
### The following file is created.
###
### ```
### ./bookmarks.json
### ```
###
chrome-export-bookmarks() {
    local profile_dir="$1"
    local output_file=${2:-./bookmarks.json}

    local source_file="$profile_dir/Bookmarks"

    if [ -z "$profile_dir" ]; then
        echo "Error: Profile directory not specified." >&2
        return 1
    fi

    if [ ! -f "$source_file" ]; then
        echo "Error: Bookmarks file not found at ${source_file}" >&2
        return 1
    fi

    local output_dir
    output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    cp "$source_file" "$output_file"

    echo "Bookmarks exported successfully to: ${output_file}" >&2
}

### Export Google Chrome preferences from a profile directory.
###
### # Arguments
###
### * profile_dir - Chrome profile directory path.
### * output_file - Optional destination file path.
###
### # Examples
###
### ```
### chrome-export-preferences "$HOME/.config/google-chrome/Default"
### ```
###
### The following file is created.
###
### ```
### ./preferences.json
### ```
###
chrome-export-preferences() {
    local profile_dir="$1"
    local output_file=${2:-./preferences.json}
    local source_file="${profile_dir}/Preferences"

    if [ -z "$profile_dir" ]; then
        echo "Error: Profile directory not specified." >&2
        return 1
    fi

    if [ ! -f "$source_file" ]; then
        echo "Error: Preferences file not found at ${source_file}" >&2
        return 1
    fi

    local output_dir
    output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    cp "$source_file" "$output_file"

    echo "Preferences exported successfully to: ${output_file}" >&2
}

### Get the primary email from a Chrome profile.
###
### # Arguments
###
### * profile_dir - Chrome profile directory path.
###
### # Examples
###
### ```
### chrome-get-profile-email "$HOME/.config/google-chrome/Default"
### ```
###
### The following email address is printed.
###
### ```
### user@example.com
### ```
###
chrome-get-profile-email() {
    local profile_dir="$1"
    local source_file="${profile_dir}/Preferences"

    if [ ! -f "$source_file" ]; then
        echo "Error: Preferences file not found at ${source_file}" >&2
        return 1
    fi

    local email
    email=$(grep -o '"email":[[:space:]]*"[^"]*"' "$source_file" | head -n 1 | sed -e 's/"email":[[:space:]]*"//' -e 's/"//')

    if [ -z "$email" ]; then
        echo "Error: Could not find an email address in the preferences '${source_file}'." >&2
        return 1
    fi

    echo "$email"
}

### Find Chrome profile directory by email.
###
### # Arguments
###
### * email_pattern - Email pattern to search.
###
### # Examples
###
### ```
### chrome-find-profile-by-email example@gmail.com
### ```
###
### The following directory path is printed.
###
### ```
### /home/user/.config/google-chrome/Profile 1
### ```
###
chrome-find-profile-by-email() {
    local email_pattern="$1"

    if [ -z "$email_pattern" ]; then
        echo "Error: No email pattern specified." >&2
        return 1
    fi

    for profile_dir in "${CHROME_CONFIG_DIR}/Default" "${CHROME_CONFIG_DIR}/Profile"*; do
        if [ ! -d "$profile_dir" ]; then
            continue
        fi

        if chrome-get-profile-email "$profile_dir" | grep -iE "$email_pattern"; then
            echo "$profile_dir"
            return 0
        fi
    done

    echo "Error: No profile found containing the email address '${email_pattern}'." >&2
    return 1
}

### Export Chrome bookmarks and preferences by email.
###
### # Arguments
###
### * email_pattern - Email pattern to search.
### * output_dir - Optional output directory.
###
### # Examples
###
### ```
### chrome-export-user-data-by-email example@gmail.com ./backup
### ```
###
### The following files are created.
###　```text
###　Profile 1_preferences.json
###　Profile 1_bookmarks.json
### ```
chrome-export-user-data-by-email() {
    local email_pattern="$1"
    local output_dir=${2:-.}
    local profile_dir

    if ! profile_dir=$(chrome-find-profile-by-email "$email_pattern"); then
        return 1
    fi

    echo "Found profile at $profile_dir. Exporting data to $output_dir..." >&2

    local profile_name
    profile_name=$(basename "$profile_dir")

    mkdir -p "$output_dir"

    chrome-export-preferences "$profile_dir" "${output_dir}/${profile_name}_preferences.json"
    chrome-export-bookmarks "$profile_dir" "${output_dir}/${profile_name}_bookmarks.json"
}

### Detect the Linux distribution name.
###
### The function inspects `/etc/os-release` or package manager commands.
###
### # Examples
###
### ```
### distro-name
### ```
distro-name() {
    local kernel
    kernel="$(uname -s)"

    case "$kernel" in
    Linux)
        if [[ -f /etc/os-release ]]; then
            (
                source /etc/os-release
                echo "${ID:-unknown}"
            )
        else
            if command -v apt-get >/dev/null 2>&1; then
                echo "debian"
            elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
                echo "fedora"
            elif command -v apk >/dev/null 2>&1; then
                echo "alpine"
            elif command -v pacman >/dev/null 2>&1; then
                echo "arch"
            else
                echo "unknown"
            fi
        fi
        ;;
    *)
        echo "unknown"
        ;;
    esac
}

KERNEL_NAME="$(uname -s)"
DISTRO_NAME="$(distro-name)"

if [[ "$KERNEL_NAME" == "Linux" ]]; then
    export ANDROID_HOME="$HOME/Android/Sdk"

    user-add-to-group() {
        local group_name="$1"
        local user_name="${2:-$USER}"

        if [[ -z "$group_name" ]]; then
            return 1
        fi

        if id -nG "$user_name" | tr ' ' '\n' | grep -Fxq "$group_name"; then
            return 0
        fi

        sudo usermod -a -G "$group_name" "$user_name"
    }

    git-setup() {
        _git-setup-common
        git-set-store-credential-with-manager
    }

    net-active-interface() {
        ip -o route show to default | awk '{print $5; exit}'
    }

    net-ipv4() {
        iface="$(net-active-interface)"
        ip addr show "$iface" | awk '/inet / {print $2}' | cut -d/ -f1
    }

    net-ipv6() {
        iface="$(net-active-interface)"
        ip addr show "$iface" |
            grep "inet6" |
            grep -v "fe80" |
            grep -v "fda6" |
            awk '{print $2}' |
            cut -d/ -f1
    }

    net-netmask() {
        iface="$(net-active-interface)"
        ip addr show "$iface" | awk '/inet / {print $2}' | cut -d/ -f2
    }

    net-gateway() {
        ip route show default | awk '/default/ {print $3; exit}'
    }

    net-dns() {
        resolvectl status |
            grep "DNS Servers" |
            awk '{for (i=3; i<=NF; i++) if ($i ~ /^[0-9.]+$/) print $i}'
    }

    net-fix-resolv-from-systemd() {
        if [ -s /etc/resolv.conf ]; then
            echo "resolv.conf は既に存在し、空ではありません。"
            return 0
        fi

        echo "resolv.conf が存在しないか空です。"
        sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        sudo systemctl restart systemd-resolved
        echo "resolv.confを/run/systemd/resolve/stub-resolv.confから復旧しました。"
    }

    net-fix-resolv-from-network-manager() {
        if [ -s /etc/resolv.conf ]; then
            echo "resolv.conf は既に存在し、空ではありません。"
            return 0
        fi

        echo "resolv.conf が存在しないか空です。"
        sudo ln -sf /run/NetworkManager/resolv.conf /etc/resolv.conf
        sudo systemctl restart NetworkManager
        echo "resolv.confを/run/NetworkManager/resolv.conから復旧しました。"
    }

    net-fix-resolv-from-google() {
        if [ -s /etc/resolv.conf ]; then
            echo "resolv.conf は既に存在し、空ではありません。"
            return 0
        fi

        echo "resolv.conf が存在しないか空です。"
        printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" | sudo tee /etc/resolv.conf >/dev/null
        echo "resolv.confをGoogle DNSに設定して復旧しました。"
    }

    swap-show() {
        swapon --show
    }

    swap-disable-all() {
        sudo swapoff -a
    }

    # Deactivates and removes all swap files and their fstab entries.
    swap-remove-all-files() {
        swapon --show | awk 'NR>1 && $2=="file" {print $1}' | while read -r swapfile; do
            if [ -n "$swapfile" ]; then
                if sudo swapoff "$swapfile" && sudo rm "$swapfile"; then
                    echo "Successfully removed swap file '$swapfile'." >&2
                else
                    echo "Failed to remove swap file '$swapfile'." >&2
                fi
            fi
        done
    }

    swap-create() {
        local size_gb=$1
        local swap_path=${2:-/swapfile}

        sudo fallocate -l "${size_gb}G" "$swap_path"
        sudo chmod 600 "$swap_path"
        sudo mkswap "$swap_path"
        sudo swapon "$swap_path"
        file-replace-or-append-line-as-root "/etc/fstab" "$swap_path" "$swap_path none swap sw 0 0"
    }

    swap-ensure-total-size() {
        local min_total_gb=${1:-64}
        local total_gb

        total_gb=$(memory-total-gb)

        if ((total_gb >= min_total_gb)); then
            return 0
        fi

        local size_to_add_gb=$((min_total_gb - total_gb))
        swap-create "$size_to_add_gb" "/swapfile_additional"
    }

    # Calculates the total size of physical memory and swap space in gigabytes.
    memory-total-gb() {
        # Get total memory and swap in kilobytes from /proc/meminfo
        local mem_total_kb=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
        local swap_total_kb=$(grep "SwapTotal:" /proc/meminfo | awk '{print $2}')

        # Calculate the sum in kilobytes
        local total_kb=$((mem_total_kb + swap_total_kb))

        # Convert total kilobytes to gigabytes
        local total_gb=$((total_kb / 1024 / 1024))

        echo "$total_gb"
    }

    keyboard-setup-lang-keys() {
        local target_path="/etc/udev/hwdb.d/90-custom-keyboard.hwdb"

        if [ -e "$target_path" ]; then
            echo "Warning: File '$target_path' already exists. If you want to overwrite it, please delete it first with 'sudo rm $target_path'." >&2
            return 1
        fi

        local config_content="evdev:input:b0003v*p*e*"
        config_content+="\n KEYBOARD_KEY_70090=henkan"
        config_content+="\n KEYBOARD_KEY_70091=muhenkan"
        config_content+="\n"
        config_content="$(printf "%b" "$config_content")"

        file-write-as-root "$target_path" "$config_content"

        sudo systemd-hwdb update
        sudo udevadm trigger
        echo "Keyboard language keys have been successfully configured."
    }

    android-commandlinetools-url() {
        _android-commandlinetools-url linux
    }

    vscode-remove-user-data() {
        rm -rf $HOME/.config/Code
    }

    aws-vpn-client-log-files() {
        find $HOME/.config/AWSVPNClient/logs | grep 'aws_vpn_client_' | grep -v 'ovpn_aws_vpn_client'
    }

    aws-vpn-client-log-clear() {
        rm $HOME/.config/AWSVPNClient/logs/* -f
    }

    aws-vpn-client-log-open() {
        aws-vpn-client-log-files | while read -r file; do
            code "$file"
        done
    }
elif [[ "$KERNEL_NAME" == "Darwin" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"

    sleep-disable() {
        sudo pmset disablesleep 1
    }

    sleep-enable() {
        sudo pmset disablesleep 0
    }

    node-install() {
        brew install node
        corepack enable
        pnpm config set store-dir ~/.pnpm-store
    }

    docker-install() {
        brew install colima
        brew install docker
        brew install docker-credential-helper
        brew install docker-compose

        brew install docker-buildx
        mkdir -p ~/.docker/cli-plugins
        ln -sfn $(brew --prefix)/opt/docker-buildx/bin/docker-buildx ~/.docker/cli-plugins/docker-buildx
        docker buildx install

        mkdir -p ~/.docker/cli-plugins
        ln -sfn $(brew --prefix)/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose

        colima start
    }

    command-line-tools-upgrade() {
        sudo rm -rf /Library/Developer/CommandLineTools
        xcode-select --install
    }

    git-set-store-credential-with-osxkeychain() {
        git config --global credential.helper osxkeychain
    }

    android-commandlinetools-url() {
        _android-commandlinetools-url mac
    }

    ruby-latest-version() {
        rbenv install -l | grep -v -E '[a-z]' | tail -1
    }

    ruby-install() {
        local version=$1

        brew install rbenv ruby-build
        brew upgrade rbenv ruby-build

        file-replace-or-append-line ~/.zshrc 'rbenv init' 'eval "$(rbenv init -)"'
        eval "$(rbenv init -)"

        if [ -z "$version" ]; then
            version=$(ruby-latest-version)
        fi

        if [ -z "$version" ]; then
            echo "Error: Could not find the latest Ruby version."
            return 1
        fi

        rbenv install "$version"

        rbenv global "$version"
        rbenv rehash
    }

    java-ensure-path() {
        sudo ln -sfn "$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk" "/Library/Java/JavaVirtualMachines/openjdk.jdk"

        env-add-variable "JAVA_HOME" "$(/usr/libexec/java_home)"
        env-add-path "$JAVA_HOME/bin"
    }

    golang-install() {
        brew install go
        echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >>~/.bashrc
    }

    pipx-install() {
        brew install pipx
        pipx ensurepath
    }

    qmk-install() {
        brew install --cask qmk-toolbox
        curl -fsSL https://install.qmk.fm | sh
        qmk doctor
    }

    supabase-install() {
        brew install supabase/tap/supabase
    }

    vscode-remove-user-data() {
        rm -rf ~/Library/Application Support/Code
    }

    vscode-to-default-app() {
        local vscode_bundle_id="com.microsoft.VSCode"

        local extensions=(
            txt
            text
            md
            markdown
            mdown
            mkd
            json
            jsonc
            yaml
            yml
            toml
            ini
            conf
            config
            env
            log
            csv
            tsv
            xml
            html
            htm
            css
            scss
            sass
            js
            jsx
            ts
            tsx
            mjs
            cjs
            sh
            bash
            zsh
            fish
            py
            rb
            php
            java
            c
            h
            cpp
            hpp
            cs
            go
            rs
            sql
            graphql
            gql
            Dockerfile
            gitignore
        )

        local utis=(
            public.plain-text
            public.text
            public.utf8-plain-text
            public.unix-executable
            public.shell-script
            net.daringfireball.markdown
            public.json
            public.yaml
            public.xml
            public.html
            public.css
            public.javascript
            public.comma-separated-values-text
            public.tab-separated-values-text
            public.source-code
        )

        for ext in "${extensions[@]}"; do
            duti -s "$vscode_bundle_id" ".$ext" all
        done

        for uti in "${utis[@]}"; do
            duti -s "$vscode_bundle_id" "$uti" all
        done

        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
            -kill -r -domain local -domain system -domain user >/dev/null 2>&1

        killall Finder >/dev/null 2>&1 || true

        echo "テキスト系ファイルを VSCode で開く設定にしました。"
    }

    ### Set IINA as the default player for all video files.
    ###
    ### # Examples
    ###
    ### ```bash
    ### iina-to-default-app
    ### ```
    ###
    ### The following message shows the completion of the setup.
    ###
    ### ```text
    ### ✅ IINA is now the default video player for all formats!
    ### ```
    iina-to-default-app() {
        local bundle_id="com.colliderli.iina"
        local extensions=(
            "mp4" "mkv" "mov" "avi" "wmv" "flv" "webm" "m4v" "mpg" "mpeg"
            "3gp" "ts" "m2ts" "mts" "ogv" "vob" "asf" "f4v" "rmvb" "divx"
        )

        if ! command -v duti &>/dev/null; then
            echo "Installing duti via Homebrew..."
            brew install duti
        fi

        for ext in "${extensions[@]}"; do
            duti -s "$bundle_id" "$ext" all
        done

        echo "✅ IINA is now the default video player for all formats!"
    }

    utm-install() {
        cd ~/Downloads
        curl -L -o UTM.dmg https://github.com/utmapp/UTM/releases/latest/download/UTM.dmg
        hdiutil attach UTM.dmg
        cp -R /Volumes/UTM/UTM.app /Applications/
        hdiutil detach /Volumes/UTM
        ls /Applications | grep UTM
    }

    utm-download-ubuntu-server-24-arm() {
        cd ~/Downloads
        curl -LO https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.4-live-server-arm64.iso
        ls -lh ubuntu-24.04-live-server-arm64.iso
        echo 'RAM：2048MB以上'
        echo 'CPU：2コア以上'
        echo 'Storage：20GB以上'
        echo 'Settings > Network > Mode > Bridged (Advanced) > 実際のMacのインターフェースを選択（Wi-Fi等）'
    }

    utm-open() {
        open -a UTM
    }

    rosetta-install() {
        softwareupdate --install-rosetta --agree-to-license
    }

    docker-desktop-install() {
        rosetta-install
        curl -L -o Docker.dmg "https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64"
        sudo hdiutil attach Docker.dmg
        sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
        sudo hdiutil detach /Volumes/Docker
    }

    rancher-desktop-install() {
        brew install --cask rancher
    }

    key-binding-disable-option-t() {
        local file="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
        local key="~t"
        local value='("noop:")'

        dict-set-value "$file" "$key" "$value"

        echo "done"
    }

    git-setup() {
        _git-setup-common
        git-set-store-credential-with-osxkeychain
    }

    mac-setup() {
        sudo-keep-alive
        env-register "$HOME/.env"
        editor-to-vscode
        local zshrc_file="$HOME/.zshrc"
        local pattern="setopt interactivecomments"
        local content="setopt interactivecomments"
        file-replace-or-append-line "$zshrc_file" "$pattern" "$content"

        env-add-variable "HOMEBREW_CASK_OPTS" "--no-quarantine"
        env-add-path "$HOME/.local/bin"

        autocomplete-to-ignore-case

        # Wake on LANを有効化 （ネットワーク経由でのスリープ解除）
        sudo pmset -a womp 1

        # fnキーを押さなくてもF1〜F12をファンクションキーとして動作させる
        defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

        key-binding-disable-option-t

        # リピート入力認識までの待機時間を短縮（押し始めてから連打が始まるまでの時間）
        defaults write NSGlobalDomain InitialKeyRepeat -int 30

        # キーのリピート速度を爆速化（連打の速さ）
        defaults write NSGlobalDomain KeyRepeat -int 1

        # 表示/非表示のアニメーション時間を削除（一瞬で切り替わる）
        defaults write com.apple.dock autohide-time-modifier -float 0

        # 隠れるまでの待機時間を削除
        defaults write com.apple.dock autohide-delay -float 0

        # スマートズームを無効化（外部・内蔵・グローバル設定）
        default write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 0
        defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 0
        defaults write NSGlobalDomain com.apple.trackpad.twoFingerDoubleTapGesture -int 0

        # 2. 「最近使ったアプリ」を非表示にする
        defaults write com.apple.dock show-recents -bool false

        # 3. ウィンドウ収納時の「ジニーエフェクト」を「スケール」にする
        defaults write com.apple.dock mineffect -string scale

        # 2. Dockの位置そのものを「画面の左端」にする場合
        defaults write com.apple.dock orientation -string left

        # 反映
        killall Dock

        # Remove iMovie
        sudo rm -rf /Applications/iMovie.app

        # Remove Pages
        sudo rm -rf /Applications/Pages.app

        # Remove GarageBand
        sudo rm -rf /Applications/GarageBand.app
        sudo rm -rf /Library/Application\ Support/GarageBand
        sudo rm -rf /Library/Audio/Apple\ Loops/Apple/Apple\ Loops\ for\ GarageBand
        sudo rm -rf ~/Library/Application\ Support/GarageBand
        sudo rm -rf /Library/Audio/Apple\ Loops

        # Remove Keynote
        sudo rm -rf /Applications/Keynote.app

        # Remove Numbers container
        sudo rm -rf /Applications/Numbers.app

        if ! command -v brew &>/dev/null; then
            echo "Install Homebrew."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            (
                echo
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
            ) >>"$HOME/.zshrc"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        brew update
        brew upgrade
        brew install duti
        brew install sqlite
        brew install postgresql
        brew install rustup
        brew install ffmpeg
        brew install pnpm
        brew install tree
        brew install ripgrep
        brew install fd
        brew install gh
        brew install python
        pipx-install
        node-install
        brew install openjdk
        java-ensure-path
        ruby-install
        docker-install
        rancher-desktop-install
        brew install shellcheck
        brew install shfmt
        brew install font-udev-gothic
        brew install --cask google-chrome
        brew install --cask brave-browser
        brew install --cask obs
        brew install --cask zoom
        brew install --cask webex
        brew install --cask visual-studio-code
        brew install --cask android-studio
        brew install --cask thunderbird
        brew install --cask discord
        brew install --cask slack
        brew install --cask google-drive
        brew install --cask dropbox
        brew install --cask megasync
        brew install --cask onedrive
        brew install --cask gimp
        brew install --cask adobe-acrobat-reader
        brew install --cask iina
        brew install --cask karabiner-elements
        brew install --cask marta

        # AI
        codex-install
        claude-code-install
        antigravity-cli-install
        brew install --cask antigravity
        brew install --cask antigravity-ide

        opencode-install

        # Personal apps
        qmk-install
        supabase-install

        # Remove quarantine attribute from Applications to prevent "App is damaged" error
        sudo xattr -r -d com.apple.quarantine /Applications 2>/dev/null

        # Gatekeeperを無効化（「すべてのアプリケーションを許可」を可能にする）
        sudo spctl --master-disable

        # Gatekeeper無効化手動設定手順を案内
        echo "1. 「プライバシーとセキュリティ」>「すべてのAppを許可」を選択してください。"
        echo "2. 「プライバシーとセキュリティ」>「フルディスクアクセス」>リストにある「Visual Studio Code」と「ターミナル」のスイッチをオンにしてください。"

        killall "System Settings"
        sleep 1
        open "x-apple.systempreferences:com.apple.settings.PrivacySecurity"

        git-setup

        echo "Enable VSCode @builtin extensions"
        code --command workbench.view.extensions

        vscode-to-default-app
        iina-to-default-app
    }
fi

case "$DISTRO_NAME" in
ubuntu | debian | pop | mint)
    # Ubuntu / Debian (apt)
    alias sysupdate="sudo apt update && sudo apt upgrade -y"

    CHROME_CONFIG_DIR="$HOME/.config/google-chrome"

    # Searches for the latest version of a package in apt-cache
    apt-search-latest() {
        local pkg_name="$1"

        apt-cache search "$pkg_name" |
            awk '{print $1}' |
            grep -E "^${pkg_name}[0-9]+" |
            sort -V |
            tail -n 1
    }

    ### Download and install a .deb package from a given URL
    ###
    ### # Arguments
    ###
    ### * `package_url` - The URL of the .deb package to download and install.
    dpkg-install-from-url() {
        local package_url="$1"
        local package_file
        package_file=$(basename "$package_url")

        pushd "/tmp" >/dev/null || return 1

        curl -L -o "$package_file" "$package_url"

        sudo dpkg -i "$package_file"

        sudo apt --fix-broken install -y

        popd >/dev/null || return 1
    }

    user-dirs-create-english-link() {
        env LANGUAGE=ja_JP.UTF-8 LC_MESSAGES=ja_JP.UTF-8 xdg-user-dirs-update --force

        dir-merge "$HOME/Desktop" "$HOME/デスクトップ"
        dir-merge "$HOME/Downloads" "$HOME/ダウンロード"
        dir-merge "$HOME/Templates" "$HOME/テンプレート"
        dir-merge "$HOME/Public" "$HOME/公開"
        dir-merge "$HOME/Documents" "$HOME/ドキュメント"
        dir-merge "$HOME/Music" "$HOME/ミュージック"
        dir-merge "$HOME/Pictures" "$HOME/ピクチャ"
        dir-merge "$HOME/Videos" "$HOME/ビデオ"

        symlink-create "$HOME/デスクトップ" "$HOME/Desktop"
        symlink-create "$HOME/ダウンロード" "$HOME/Downloads"
        symlink-create "$HOME/テンプレート" "$HOME/Templates"
        symlink-create "$HOME/公開" "$HOME/Public"
        symlink-create "$HOME/ドキュメント" "$HOME/Documents"
        symlink-create "$HOME/ミュージック" "$HOME/Music"
        symlink-create "$HOME/ピクチャ" "$HOME/Pictures"
        symlink-create "$HOME/ビデオ" "$HOME/Videos"
    }

    pass-install() {
        sudo apt install -y pass
    }

    git-credential-manager-latest-url() {
        curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest |
            grep "browser_download_url.*gcm-linux_amd64.*\.deb" |
            cut -d '"' -f 4
    }

    git-credential-manager-install() {
        local url=$(git-credential-manager-latest-url)
        dpkg-install-from-url $url
    }

    plantuml-install() {
        sudo apt install -y graphviz
        sudo apt install -y default-jdk
    }

    # Install flutter SDK and dependences
    # https://docs.flutter.dev/install/manual
    flutter-sdk-install() {
        local flutetr_root_dir="$HOME/.local/flutter"

        sudo apt update
        sudo apt install -y curl git unzip xz-utils zip libglu1-mesa

        # Install Linux dependences
        # https://docs.flutter.dev/platform-integration/linux/setup
        sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev

        mkdir -p "$HOME/.local"

        if [ -d "$flutetr_root_dir" ]; then
            rm -rf "$flutetr_root_dir"
        fi

        git clone https://github.com/flutter/flutter.git -b stable "$flutetr_root_dir"

        symlink-create-to-local-bin "$flutetr_root_dir/bin/flutter"

        flutter doctor
    }

    vlc-set-to-default-app() {
        vlc_desktop=$(ls /usr/share/applications/ | grep vlc)

        # VLCが対応しているMIMEタイプを抽出して、それぞれに対してデフォルト設定を適用
        grep "MimeType=" /usr/share/applications/${vlc_desktop} | sed 's/MimeType=//' | tr ';' ' ' | xargs -n 1 xdg-mime default ${vlc_desktop}
    }

    # Install mozc-server 2.28.4715 for Ubuntu 22
    # https://take6shin-tech-diary.com/ibusmozc_hiragana/#google_vignette
    mozc-server-2-28-4715-install() {
        local MOZC_SERVER_URL="https://launchpad.net/ubuntu/+source/mozc/2.28.4715.102+dfsg-2.2~bpo22.04.1/+build/26677818/+files/mozc-server_2.28.4715.102+dfsg-2.2~bpo22.04.1_amd64.deb"
        dpkg-install-from-url "$MOZC_SERVER_URL"
    }

    # Install ibus-mozc 2.28.4715 for Ubuntu 22
    ibus-mozc-2-28-4715-install() {
        local IBUS_MOZC_URL="https://launchpad.net/ubuntu/+source/mozc/2.28.4715.102+dfsg-2.2~bpo22.04.1/+build/26677818/+files/ibus-mozc_2.28.4715.102+dfsg-2.2~bpo22.04.1_amd64.deb"
        dpkg-install-from-url "$IBUS_MOZC_URL"
    }

    # Set Mozc to Hiragana as default input mode
    mozc-set-hiragana-as-default() {
        MOZC_IBUS_CONFIG_FILE="$HOME/.config/mozc/ibus_config.textproto"
        textproto-insert "$MOZC_IBUS_CONFIG_FILE" "active_on_launch" "True"
        ibus-daemon -rd
    }

    GSET_INPUT_SOURCES_SCHEMA="org.gnome.desktop.input-sources"
    GSET_INPUT_SOURCES_KEY="sources"
    GSET_MEDIA_KEYS_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    GSET_MEDIA_KEYS_KEY="custom-keybindings"
    GSET_CUSTOM_KEYBINDING_BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
    GSET_WM_KEYBINDINGS_SCHEMA="org.gnome.desktop.wm.keybindings"

    # Removes a value from a GSettings key that holds a string array.
    #
    # # Arguments
    #
    # * `schema` - The GSettings schema.
    # * `key` - The GSettings key.
    # * `value_to_remove` - The string value to remove from the array.
    gnome-remove-settings() {
        local schema="$1"
        local key="$2"
        local value_to_remove="'$3'"

        local current_list
        current_list=$(gsettings get "$schema" "$key")

        # Use sed to remove the value and handle surrounding commas and spaces.
        local new_list
        new_list=$(echo "$current_list" | sed "s|, ${value_to_remove}||g" | sed "s|${value_to_remove}, ||g" | sed "s|${value_to_remove}||g")

        gsettings set "$schema" "$key" "$new_list"
    }

    # Adds a value to a GSettings key that holds a string array.
    # Checks for duplicates before adding the value.
    #
    # # Arguments
    #
    # * `schema` - The GSettings schema.
    # * `key` - The GSettings key.
    # * `value_to_add` - The string value to add to the array.
    gnome-set-settings() {
        local schema="$1"
        local key="$2"
        local value_to_add="'$3'"

        local current_list
        current_list=$(gsettings get "$schema" "$key")

        if [[ "$current_list" =~ "$value_to_add" ]]; then
            echo "Value ${value_to_add} already exists in ${key}. Skipping."
            return
        fi

        local new_list
        new_list=$(echo "$current_list" | sed "s|]$|, ${value_to_add}]|" | sed "s|\[, |[|")

        gsettings set "$schema" "$key" "$new_list"
    }

    # Sets a custom keyboard shortcut in GNOME.
    # It automatically finds and removes conflicting old shortcuts before adding the new one.
    # A conflict is defined as having the same name, OR the same command and binding.
    #
    # # Arguments
    #
    # * `id` - A unique identifier for the shortcut (e.g., 'custom100').
    # * `name` - The descriptive name of the shortcut.
    # * `command` - The command to execute.
    # * `binding` - The key combination (e.g., '<Alt>a').
    gnome-set-custom-keybinding() {
        local id="$1"
        local new_name="$2"
        local new_command="$3"
        local new_binding="$4"

        local existing_paths
        existing_paths=$(gsettings get "$GSET_MEDIA_KEYS_SCHEMA" "$GSET_MEDIA_KEYS_KEY" | grep -o "/[^']*")

        for path in $existing_paths; do
            local key_prefix="${GSET_MEDIA_KEYS_SCHEMA}.custom-keybinding:${path}"
            local old_name
            old_name=$(gsettings get "$key_prefix" name)
            local old_command
            old_command=$(gsettings get "$key_prefix" command)
            local old_binding
            old_binding=$(gsettings get "$key_prefix" binding)

            if [[ "'$new_name'" == "$old_name" ]] ||
                ([[ "'$new_command'" == "$old_command" ]] && [[ "'$new_binding'" == "$old_binding" ]]); then
                gnome-remove-settings "$GSET_MEDIA_KEYS_SCHEMA" "$GSET_MEDIA_KEYS_KEY" "$path"
            fi
        done

        local new_path="${GSET_CUSTOM_KEYBINDING_BASE_PATH}${id}/"
        local new_key_prefix="${GSET_MEDIA_KEYS_SCHEMA}.custom-keybinding:${new_path}"

        gsettings set "$new_key_prefix" name "$new_name"
        gsettings set "$new_key_prefix" command "$new_command"
        gsettings set "$new_key_prefix" binding "$new_binding"

        gnome-set-settings "$GSET_MEDIA_KEYS_SCHEMA" "$GSET_MEDIA_KEYS_KEY" "$new_path"
    }

    # Sets the system keyboard layout to Japanese (JP) and configures GNOME to use Mozc as the primary input method.
    gnome-keyboard-layout-to-us() {
        gsettings set "$GSET_INPUT_SOURCES_SCHEMA" "$GSET_INPUT_SOURCES_KEY" "[('ibus', 'mozc-jp'), ('xkb', 'us')]"

        sudo sed -i 's/XKBLAYOUT="[^"]*"/XKBLAYOUT="us"/' /etc/default/keyboard
    }

    # Sets the system keyboard layout to Japanese (JP) and configures GNOME to use Mozc as the primary input method.
    gnome-keyboard-layout-to-jp() {
        gsettings set "$GSET_INPUT_SOURCES_SCHEMA" "$GSET_INPUT_SOURCES_KEY" "[('ibus', 'mozc-jp'), ('xkb', 'jp')]"

        sudo sed -i 's/XKBLAYOUT="[^"]*"/XKBLAYOUT="jp"/' /etc/default/keyboard
    }

    # Sets GNOME's input source switcher shortcuts to Alt + ` and Shift + Alt + `.
    # Also sets custom shortcuts to switch between English (US) and Japanese (Mozc) input methods.
    gnome-setup-input-source-switcher-shortcut() {
        gsettings set "$GSET_WM_KEYBINDINGS_SCHEMA" switch-input-source "['<Alt>grave']"
        gsettings set "$GSET_WM_KEYBINDINGS_SCHEMA" switch-input-source-backward "['<Shift><Alt>grave']"

        echo "Shortcuts have been set successfully." >&2
        echo "- <Alt> + <\`>: Switch to next GNOME's input source" >&2
        echo "- <Shift> + <Alt> + <\`>: Switch to previous GNOME's input source" >&2

        gnome-set-custom-keybinding \
            "custom100" \
            "Disable IME (US Layout)" \
            "ibus engine 'xkb:us::eng'" \
            "<Alt>semicolon"

        gnome-set-custom-keybinding \
            "custom101" \
            "Enable IME (Mozc)" \
            "ibus engine 'mozc-jp'" \
            "<Alt>a"

        echo "Shortcuts have been set successfully." >&2
        echo "- <Alt> + <;>: Switch to English (US)" >&2
        echo "- <Alt> + <a>: Switch to Japanese (Mozc)" >&2
    }

    # Set Mozc as the highest priority input source.
    # It preserves the currently active keyboard layout.
    gnome-set-mozc-priority() {
        local current_sources
        current_sources=$(gsettings get "$GSET_INPUT_SOURCES_SCHEMA" "$GSET_INPUT_SOURCES_KEY")

        # Extract the active 'xkb' keyboard layout from the current sources.
        local keyboard_layout
        keyboard_layout=$(echo "$current_sources" | grep -oE "\('xkb', '[^']+'\)")

        if [ -z "$keyboard_layout" ]; then
            echo "Error: No active 'xkb' keyboard layout found. Cannot set priority." >&2
            return 1
        fi

        local new_sources="[('ibus', 'mozc-jp'), $keyboard_layout]"

        gsettings set "$GSET_INPUT_SOURCES_SCHEMA" "$GSET_INPUT_SOURCES_KEY" "$new_sources"
    }

    mozc-tool-install() {
        sudo apt install -y mozc-utils-gui
        symlink-create-to-local-bin "/usr/lib/mozc/mozc_tool"
    }

    # Open mozc_tool config
    mozc-config() {
        mozc_tool --mode=config_dialog
    }

    ssh-server-install() {
        sudo apt install -y openssh-server
        sudo systemctl enable ssh
    }

    vscode-install() {
        sudo apt install software-properties-common apt-transport-https wget gpg -y
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
        sudo apt update
        sudo apt install code
    }

    vscode-remove-user-data() {
        rm -rf $HOME/.config/Code
    }

    _slack-url() {
        local version="$1"
        local SLACK_PAGE_URL="https://slack.com/intl/ja-jp/downloads/linux"

        if [ -z "$version" ]; then
            version = curl -sL "$SLACK_PAGE_URL" |
                grep -o 'バージョン [0-9.]*' |
                sed 's/バージョン //g'
        fi

        local base_url="https://downloads.slack-edge.com/desktop-releases/linux/x64"

        echo "${base_url}/${version}/slack-desktop-${version}-amd64.deb"
    }

    slack-install() {
        local url=$(_slack-url)
        dpkg-install-from-url $url
    }

    chrome-install() {
        dpkg-install-from-url https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    }

    gimp-install() {
        sudo apt install -y gimp gimp-gmic
    }

    _microsoft-edge-latest-url() {
        curl -s https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/ | grep -oP 'microsoft-edge-stable_[\d\.\-]+_amd64\.deb' | sort -V | tail -n 1
    }

    microsoft-edge-install() {
        pushd /tmp
        wget "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/$(_microsoft-edge-latest-url)" -O microsoft-edge-stable.deb
        sudo apt install -y ./microsoft-edge-stable.deb
        popd
    }

    ubuntu-setup() {
        env-register "$HOME/.env"
        editor-to-vscode
        autocomplete-to-ignore-case
        user-dirs-create-english-link
        user-add-to-group dialout
        git-setup
        ssh-dir-setup
    }

    ubuntu-setup-for-desktop() {
        ubuntu-setup
        keyboard-setup-lang-keys
        gnome-set-mozc-priority
        gnome-keyboard-layout-to-us
        mozc-set-hiragana-as-default
        vlc-set-to-default-app
    }

    ubuntu-22-setup-for-desktop() {
        ubuntu-setup-for-desktop
        mozc-server-2-28-4715-install
        ibus-mozc-2-28-4715-install
        gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    }
    ;;

fedora | rhel | centos | almalinux | rocky)
    # Fedora / RHEL (dnf)
    alias sysupdate="sudo dnf update -y"

    ;;

alpine)
    # Alpine Linux (apk)
    alias sysupdate="apk update && apk upgrade"

    ;;
esac
