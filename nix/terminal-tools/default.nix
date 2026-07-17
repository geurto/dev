{ pkgs }:

let
  cfg        = import ./config.nix { inherit pkgs; };
  fzfPkg     = import ./fzf.nix   { inherit pkgs; };
  tmuxConfig = import ./tmux.nix  { inherit pkgs; };
  zshConfig  = import ./zsh.nix   { inherit pkgs; };
in
pkgs.symlinkJoin {
  name  = "terminal-tools";
  paths = [ fzfPkg tmuxConfig zshConfig ] ++ cfg.extraPackages;
}
