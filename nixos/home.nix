{ config, pkgs, inputs, system, ... }:

let
  # Neovim built by the dev flake (same config as Ubuntu)
  neovim = inputs.dev.packages.${system}.neovim;

  # Shared terminal config — ground truth lives in nix/terminal-tools/config.nix
  termConfig = inputs.dev.lib.${system}.makeTerminalConfig pkgs;
in
{
  home.username = "peter";
  home.homeDirectory = "/home/peter";
  home.stateVersion = "25.05";

  # ── Packages ──────────────────────────────────────────────────────────────
  home.packages = [ neovim ] ++ termConfig.extraPackages ++ (with pkgs; [
    # Networking / infra (alongside Tailscale)
    nmap
    wireguard-tools

    # Build tools for Rust / C++ / Python work
    pkg-config
    cmake
    ninja
    python3
    python3Packages.pip
    python3Packages.virtualenv
  ]);

  # ── Ghostty terminal ──────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      theme = "catppuccin-mocha";
      window-decoration = "none";
      background-opacity = 0.95;
      cursor-style = "bar";
      shell-integration = "zsh";
    };
  };

  # ── Zsh (config from nix/terminal-tools/config.nix) ──────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = termConfig.shellAliases // {
      # NixOS-specific helpers (not relevant on Ubuntu)
      rebuild = "sudo nixos-rebuild switch --flake .#nixos";
      update  = "nix flake update && sudo nixos-rebuild switch --flake .#nixos";
      ros     = "source /opt/ros/jazzy/setup.zsh";
    };

    initContent = termConfig.zshInitExtra;
  };

  # ── Tmux (config from nix/terminal-tools/config.nix) ─────────────────────
  programs.tmux = {
    enable = true;
    # home-manager manages the shell setting; tmuxConf covers everything else.
    extraConfig = termConfig.tmuxConf;
  };

  # ── Starship prompt (settings from nix/terminal-tools/config.nix) ─────────
  programs.starship = {
    enable = true;
    settings = termConfig.starshipSettings;
  };

  # ── Git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    userName  = "Peter";
    userEmail = "your@email.com"; # fill in
    extraConfig = {
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate     = true;
        line-numbers = true;
        side-by-side = true;
      };
      merge.conflictstyle = "zdiff3";
      pull.rebase = true;
    };
  };

  # ── SSH ───────────────────────────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 3
    '';
  };

  # ── XDG ───────────────────────────────────────────────────────────────────
  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = { };
  };

  programs.home-manager.enable = true;
}
