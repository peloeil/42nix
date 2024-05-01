{ pkgs }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    zsh
    git
    clang
  ];
  shellHook = "";
}
