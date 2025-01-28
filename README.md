# 42nix

## 概要

42Tokyo で Nix を使えるようにするためのスクリプトを提供します。

[通常の Nix のインストーラー](https://github.com/DeterminateSystems/nix-installer)
では、ユーザーや `/nix` を作成することが必要なため、
ルート権限を持っている必要があります。
非特権ユーザーが Nix を使うためには工夫が必要です。

## 使い方
### Nix のインストール
初回のみ必要です。
```bash
./install.sh
# restart your shell
```
この後は自由に `nix` コマンドが使えます。

`nix profile install` などによってインストールしたコマンドを使うには、
Nix コマンドでシェルに入る必要があります。
### シェルに入る
```bash
nix run nixpkgs#zsh # or bash (ログインシェル)
```
このシェルの中ではインストールしたコマンドが全て使えます。

## 詳細説明

### install.sh

hydra のバイナリキャッシュから、静的リンクされた Nix を
`/goinfre/$USER/bin` にインストールし、
`/goinfre/$USER/bin` と `~/.nix-profile/bin` をパスに追加します。

### wrapper.sh

`/nix` へのアクセス権限を持たないため、Nix の使用時は
毎回 chroot する必要があります。その設定を毎度書くのは
面倒なため用意した Nix のラッパースクリプトです。
上でインストールを行うときに `nix` という名前で
`/goinfre/$USER/bin` に配置されます。

## License

This project is licensed under the MIT License.
