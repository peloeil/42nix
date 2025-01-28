#!/usr/bin/env bash

NIX_BINARY="/goinfre/$USER/nix/nix_bin"
MY_NIX_PATH="/goinfre/$USER/nix"

bwrap --unshare-user \
    --uid "$(id -u)" \
    --gid "$(id -g)" \
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
    "$NIX_BINARY" "$@"
