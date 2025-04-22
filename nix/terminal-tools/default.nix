{ pkgs }:

let
  fzfConfig = import ./fzf.nix { inherit pkgs; };
  tmuxConfig = import ./tmux.nix { inherit pkgs; };
  zshConfig = import ./zsh.nix { inherit pkgs; };
  batPackage = pkgs.bat;
  ripgrepPackage = pkgs.ripgrep;
in
pkgs.symlinkJoin {
  name = "terminal-tools";
  paths = [
    fzfConfig
    tmuxConfig
    zshConfig
    batPackage
    ripgrepPackage
  ];
}
