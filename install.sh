#!/usr/bin/env bash

INSTALL_DIR="/goinfre/$USER/nix"
BINARY="$INSTALL_DIR/nix"

# nix version to install
VERSION="2.20"
if [[ -n "$1" ]]; then
	VERSION="$1"
fi

# validate version
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
				WHILE_FLAG=false;;
			"n" | "N")
				echo "ok. bye!"
				exit 0
				;;
			*)
				echo -e "invalid input\n" >&2;;
		esac
	done
fi

# install static binary
mkdir -p "$INSTALL_DIR"
curl -L "$URL" > "$BINARY"
chmod u+x "$BINARY"

# update path
PATH_LINE="PATH=$INSTALL_DIR:\$PATH"
CONFIG_FILE="$HOME/.bashrc"
case "$(basename $SHELL)" in
	"zsh")
		CONFIG_FILE="$HOME/.zshrc";;
	"fish")
		PATH_LINE="fish_add_path $INSTALL_DIR"
		CONFIG_FILE="$HOME/.config/fish/config.fish"
		;;
	*)
		echo "This install script only works with zsh, bash and fish." >&2
		exit 1
		;;
esac

if ! grep "$PATH_LINE" "$CONFIG_FILE" 1>/dev/null; then
	echo "updating PATH ..."
	echo "$PATH_LINE" | tee --append "$CONFIG_FILE"
	echo "updated PATH"
fi
