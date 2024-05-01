FROM nixos/nix:2.23.0pre20240501_5279e1f

ARG USERNAME=42tokyo
ARG GROUPNAME=42tokyo
ARG UID=1000
ARG GID=1000

COPY ./nix /root/nix

WORKDIR /root/nix

ENTRYPOINT ["bash", "-c", "sleep infinity"]

