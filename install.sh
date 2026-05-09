#!/usr/bin/env sh
# Copyright 2022 khanhas.
# Copyright 2023-present DT contributors.
# Edited from project Denoland install script (https://github.com/denoland/deno_install)

set -e

for arg in "$@"; do
    shift
    case "$arg" in
        "--root") override_root=1 ;;
        *)
        if echo "$arg" | grep -qv "^-"; then
            tag="$arg"
        else
            echo "Invalid option $arg" >&2
            exit 1
        fi
    esac
done

is_root() {
    [ "$(id -u)" -ne 0 ]
}

if ! is_root && [ "${override_root:-0}" -eq 0 ]; then
    echo "The script was ran under sudo or as root. The script will now exit"
    echo "If you hadn't intended to do this, please execute the script without root access to avoid problems with dt"
    echo "To override this behavior, pass the '--root' parameter to this script"
    exit
fi

# wipe existing log
> install.log :

log() {
    echo "$1"
    echo "[$(date +'%H:%M:%S %Y-%m-%d')]" "$1" >> install.log
}

case $(uname -sm) in
    "Darwin x86_64") target="darwin-amd64" ;;
    "Darwin arm64") target="darwin-arm64" ;;
    "Linux x86_64") target="linux-amd64" ;;
    "Linux aarch64") target="linux-arm64" ;;
    *) log "Unsupported platform $(uname -sm). x86_64 and arm64 binaries for Linux and Darwin are available."; exit ;;
esac

# check for dependencies
command -v curl >/dev/null || { log "curl isn't installed!" >&2; exit 1; }
command -v tar >/dev/null || { log "tar isn't installed!" >&2; exit 1; }
command -v grep >/dev/null || { log "grep isn't installed!" >&2; exit 1; }

# download uri
releases_uri=https://github.com/DT-Deville/DT/releases
if [ -z "$tag" ]; then
    tag=$(curl -LsH 'Accept: application/json' $releases_uri/latest)
    tag=${tag%\,\"update_url*}
    tag=${tag##*tag_name\":\"}
    tag=${tag%\"}
fi

tag=${tag#v}

log "FETCHING Version $tag"

download_uri=$releases_uri/download/v$tag/dt-$tag-$target.tar.gz

# locations
dt_install="$HOME/.dt"
exe="$dt_install/dt"
tar="$dt_install/dt.tar.gz"

# installing
[ ! -d "$dt_install" ] && log "CREATING $dt_install" && mkdir -p "$dt_install"

log "DOWNLOADING $download_uri"
curl --fail --location --progress-bar --output "$tar" "$download_uri"

log "EXTRACTING $tar"
tar xzf "$tar" -C "$dt_install"

log "SETTING EXECUTABLE PERMISSIONS TO $exe"
chmod +x "$exe"

log "REMOVING $tar"
rm "$tar"

notfound() {
    cat << EOINFO
Manually add the directory to your \$PATH through your shell profile
export DT_INSTALL="$dt_install"
export PATH="\$PATH:$dt_install"
EOINFO
}

endswith_newline() {
    [ "$(od -An -c "$1" | tail -1 | grep -o '.$')" = "\n" ]
}

check() {
    path="export PATH=\$PATH:$dt_install"
    shellrc=$HOME/$1

    if [ "$1" = ".zshrc" ] && [ -n "${ZDOTDIR}" ]; then
        shellrc=$ZDOTDIR/$1
    fi

    # Create shellrc if it doesn't exist
    if ! [ -f "$shellrc" ]; then
        log "CREATING $shellrc"
        touch "$shellrc"
    fi

    # Still checking again, in case touch command failed
    if [ -f "$shellrc" ]; then
        if ! grep -q "$dt_install" "$shellrc"; then
            log "APPENDING $dt_install to PATH in $shellrc"
            if ! endswith_newline "$shellrc"; then
                echo >> "$shellrc"
            fi
            echo "${2:-$path}" >> "$shellrc"
            export PATH="$dt_install:$PATH"
        else
            log "dt path already set in $shellrc, continuing..."
        fi
    else
        notfound
    fi
}

case $SHELL in
    *zsh) check ".zshrc" ;;
    *bash)
        [ -f "$HOME/.bashrc" ] && check ".bashrc"
        [ -f "$HOME/.bash_profile" ] && check ".bash_profile"
    ;;
    *fish) check ".config/fish/config.fish" "fish_add_path $dt_install" ;;
    *) notfound ;;
esac

echo
log "dt v$tag was installed successfully to $dt_install"
log "Run 'dt --help' to get started"

echo "Do you want to install dt Marketplace? (Y/n)"
read -r choice < /dev/tty
if [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
    echo "dt Marketplace installation aborted"
    exit 0
fi
echo "Starting the dt Marketplace installation script.."
curl -fsSL "https://raw.githubusercontent.com/dt/dt-marketplace/main/resources/install.sh" | sh
