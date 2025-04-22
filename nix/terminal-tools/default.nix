{ pkgs }:

let
  tmuxConfig = import ./tmux.nix { inherit pkgs; };
  zshConfig = import ./zsh.nix { inherit pkgs; };

in
pkgs.symlinkJoin {
  name = "terminal-tools";
  paths = [
    tmuxConfig
    zshConfig
  ];
}
