#!/usr/bin/env bash

INSTALL_DIR="/goinfre/$USER/nix"
BINARY="$INSTALL_DIR/nix_bin"

# nix version to install
VERSION="2.20"
if [[ -n "$1" ]]; then
    VERSION="$1"
fi

# TODO: validate version
URL="https://hydra.nixos.org/job/nix/maintenance-$VERSION/buildStatic.x86_64-linux/latest/download-by-type/file/binary-dist"

# if install directory exists,
# check if user really wants to reinstall the binary
if [[ -d "$INSTALL_DIR" ]]; then
    WHILE_FLAG=true
    while $WHILE_FLAG; do
        read -p "reinstall nix binary [y/N]: " INPUT
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

# install nix static binary
echo "downloading nix static binary into $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
curl -L "$URL" >"$BINARY"
chmod u+x "$BINARY"
echo "downloaded nix static binary"

# wrapper script
WRAPPER_BINARY="$INSTALL_DIR/nix"
MY_NIX_PATH="/goinfre/$USER/.nix/nix"
mkdir -p "$MY_NIX_PATH"
cat <<EOF >"$WRAPPER_BINARY"
#!/usr/bin/env bash

bwrap --unshare-user \
      --uid $(id -u) \
      --gid $(id -g) \
      --proc /proc \
      --dev /dev \
      --tmpfs /tmp \
      --ro-bind /bin /bin \
      --ro-bind /etc /etc \
      --ro-bind /lib /lib \
      --ro-bind /lib64 /lib64 \
      --ro-bind /run /run \
      --ro-bind /usr /usr \
      --ro-bind /var /var \
      --bind "$HOME" "$HOME" \
      --bind "/goinfre/$USER" "/goinfre/$USER" \
      --bind "$MY_NIX_PATH" /nix \
      $BINARY \$@
EOF
chmod u+x "$WRAPPER_BINARY"

# config file
NIX_CONFIG_FILE="$HOME/.config/nix/nix.conf"
if [[ -d "$NIX_CONFIG_FILE" ]]; then
    echo "writing $NIX_CONFIG_FILE ..."
    mkdir -p "$HOME/.config/nix" "/goinfre/$USER/.nix"
    cat <<EOF >"$NIX_CONFIG_FILE"
store = /goinfre/$USER/.nix
extra-experimental-features = flakes nix-command
EOF
    echo "wrote $NIX_CONFIG_FILE"
else
    echo "skipped writing $NIX_CONFIG_FILE as it already exists"
fi

# update path
PATH_LINE="PATH=$HOME/.nix-profile/bin:$INSTALL_DIR:\$PATH"
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
    echo "This install script only works with zsh, bash and fish." >&2
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
