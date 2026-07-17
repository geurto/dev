# FZF binary for the Ubuntu terminal-tools bundle.
# The shell integration (key bindings, completion, colours) lives in config.nix's
# zshInitExtra and is sourced directly from the Nix store — no runtime setup script needed.
{ pkgs, ... }: pkgs.fzf
