FROM nixos/nix:2.23.0pre20240501_5279e1f

COPY ./nix /home/42tokyo/.nix
COPY ./etc/sudoers /etc

# user権限系のものをインストールする
# RUN nix-env -iA nixpkgs.su.out
RUN nix-env -iA nixpkgs.sudo

# ユーザが管理するディレクトリ
RUN mkdir -p /home/42tokyo
# ユーザの追加
RUN echo "42tokyo:x:1000:1000:42tokyo:/home/42tokyo:/bin/bash" >> /etc/passwd
# グループの追加
RUN echo "42tokyo:x:1000" >> /etc/group
# 権限を付与する
RUN chown -R 42tokyo:42tokyo /home/42tokyo

WORKDIR /home/42tokyo

ENTRYPOINT ["bash", "-c", "sleep infinity"]
