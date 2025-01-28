#!/usr/bin/env bash

INSTALL_DIR="/goinfre/$USER/nix"
BINARY="$INSTALL_DIR/nix_bin"
VERSION="2.20"

# if version is provided as an argument,
# use it
if [[ -n "$1" ]]; then
    VERSION="$1"
fi

# TODO: validate version
URL="https://hydra.nixos.org/job/nix/maintenance-$VERSION/buildStatic.x86_64-linux/latest/download-by-type/file/binary-dist"

# if nix is already installed,
# ask if user wants to reinstall
# TODO: check if nix is already in PATH
if [[ -d "$INSTALL_DIR" ]]; then
    WHILE_FLAG=true
    while $WHILE_FLAG; do
        read -r --prompt-str "reinstall nix binary [y/N]: " INPUT
        if [[ -z "$INPUT" ]]; then
            INPUT="N"
        fi
        case "$INPUT" in
        "y" | "Y")
            WHILE_FLAG=false
            ;;
        "n" | "N")
            echo "ok. bye!"
            exit 0
            ;;
        *)
            echo -e "invalid input\n" >&2
            ;;
        esac
    done
fi

# download nix binary
echo "downloading nix static binary into $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
curl -L "$URL" >"$BINARY"
chmod u+x "$BINARY"
echo "downloaded nix static binary"

# install wrapper
WRAPPER="$INSTALL_DIR/nix"
MY_NIX_PATH="/goinfre/$USER/nix"
mkdir -p "$MY_NIX_PATH"
cp ./wrapper.sh "$WRAPPER"
chmod u+x "$WRAPPER"

# config file
NIX_CONFIG_FILE="$HOME/.config/nix/nix.conf"
if [[ -d "$NIX_CONFIG_FILE" ]]; then
    echo "writing $NIX_CONFIG_FILE ..."
    mkdir -p "$HOME/.config/nix"
    cat <<EOF >"$NIX_CONFIG_FILE"
store = /goinfre/$USER
extra-experimental-features = flakes nix-command
EOF
    echo "wrote $NIX_CONFIG_FILE"
else
    echo "skipped writing $NIX_CONFIG_FILE as it already exists"
fi

PATH_LINE="PATH=$HOME/.nix-profile/bin:$INSTALL_DIR:\$PATH"
# update PATH
SHELL_CONFIG_FILE="$HOME/.bashrc"
case "$(basename "$SHELL")" in
"zsh")
    SHELL_CONFIG_FILE="$HOME/.zshrc"
    ;;
"fish")
    PATH_LINE="fish_add_path $HOME/.nix-profile/bin $INSTALL_DIR"
    SHELL_CONFIG_FILE="$HOME/.config/fish/config.fish"
    ;;
*)
    echo "this install script only works with zsh, bash and fish." >&2
    exit 1
    ;;
esac
if grep "$PATH_LINE" "$SHELL_CONFIG_FILE" 1>/dev/null; then
    echo "skipped updating $SHELL_CONFIG_FILE as nix is already in your PATH"
else
    echo "updating $SHELL_CONFIG_FILE ..."
    echo "$PATH_LINE" | tee --append "$SHELL_CONFIG_FILE"
    echo "updated $SHELL_CONFIG_FILE"
    echo ""
    echo "please restart your shell"
fi
echo "nix installation finished"
