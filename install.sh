#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/goinfre/$USER/bin"
NIX_BINARY="$INSTALL_DIR/nix_bin"
VERSION="2.20"

# Use provided version if specified
[[ -n "${1:-}" ]] && VERSION="$1"

# Validate version format
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Version should be in format 'X.Y' (e.g. 2.20)" >&2
    exit 1
fi

URL="https://hydra.nixos.org/job/nix/maintenance-$VERSION/buildStatic.x86_64-linux/latest/download-by-type/file/binary-dist"

# Verify version exists
if ! curl --output /dev/null --silent --head --fail "$URL"; then
    echo "Error: Version $VERSION does not exist or is not accessible" >&2
    exit 1
fi

prompt_yn() {
    local prompt="$1"
    local default="${2:-N}"
    while true; do
        read -r -p "$prompt [$([[ $default == Y ]] && echo "Y/n" || echo "y/N")]: " input
        input="${input:-$default}"
        case "${input,,}" in
        y | yes) return 0 ;;
        n | no) return 1 ;;
        *) echo -e "invalid input\n" >&2 ;;
        esac
    done
}

# Check for existing installation
[[ -f "$NIX_BINARY" ]] && ! prompt_yn "reinstall nix binary" && {
    echo "ok. bye!"
    exit 0
}

# Download nix binary
echo "downloading nix static binary into $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
curl -L "$URL" >"$NIX_BINARY"
chmod u+x "$NIX_BINARY"
echo "downloaded nix static binary"

# Install wrapper
WRAPPER="$INSTALL_DIR/nix"
MY_NIX_PATH="/goinfre/$USER/nix"
mkdir -p "$MY_NIX_PATH"

[[ -f "$WRAPPER" ]] && ! prompt_yn "overwrite $WRAPPER" && {
    echo "ok. bye!"
    exit 0
}
[[ -f "$WRAPPER" ]] && rm "$WRAPPER"
cp ./wrapper.sh "$WRAPPER"
chmod u+x "$WRAPPER"

# Setup config
NIX_CONFIG_FILE="$HOME/.config/nix/nix.conf"
if [[ -f "$NIX_CONFIG_FILE" ]]; then
    echo "skipped writing $NIX_CONFIG_FILE as it already exists"
else
    echo "writing $NIX_CONFIG_FILE ..."
    mkdir -p "$HOME/.config/nix"
    cat >"$NIX_CONFIG_FILE" <<EOF
store = /goinfre/$USER
extra-experimental-features = flakes nix-command
EOF
    echo "wrote $NIX_CONFIG_FILE"
fi

# Update PATH
PATH_LINE="export PATH=$HOME/.nix-profile/bin:$INSTALL_DIR:\$PATH"
SHELL_CONFIG_FILE="$HOME/.bashrc"

case "$(basename "$SHELL")" in
"zsh") SHELL_CONFIG_FILE="$HOME/.zshrc" ;;
*)
    echo "this install script only works with zsh or bash" >&2
    echo "please add the following line to your shell config file manually:" >&2
    echo "$PATH_LINE" >&2
    exit 1
    ;;
esac

dir_in_path() {
    local dir="$1"
    [[ ":$PATH:" == *":$dir:"* ]]
}

if dir_in_path "$HOME/.nix-profile/bin" && dir_in_path "$INSTALL_DIR"; then
    echo "skipped updating $SHELL_CONFIG_FILE as nix is already in your PATH"
else
    echo "updating $SHELL_CONFIG_FILE ..."
    echo "$PATH_LINE" >>"$SHELL_CONFIG_FILE"
    echo "updated $SHELL_CONFIG_FILE"
    echo -e "\nplease restart your shell"
fi

echo "nix installation finished"
