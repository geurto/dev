{
  config,
  pkgs,
  inputs,
  system,
  isLaptop ? false,
  ...
}:

let
  # Neovim built by the dev flake (same config as Ubuntu)
  neovim = inputs.dev.packages.${system}.neovim;

  # Shared terminal config — ground truth lives in nix/terminal-tools/config.nix
  termConfig = inputs.dev.lib.${system}.makeTerminalConfig pkgs;

  # Per-display size tuning — laptop (1080p) uses smaller values than the
  # 1440p desktop monitor where the defaults were originally calibrated.
  fontSize = if isLaptop then 11 else 13;
  cursorSize = if isLaptop then 20 else 24;
in
{
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
    ./waybar.nix
  ];
  home.username = "peter";
  home.homeDirectory = "/home/peter";
  home.stateVersion = "25.05";

  # ── Packages ──────────────────────────────────────────────────────────────
  home.packages = [
    neovim
    pkgs.fzf
  ]
  ++ termConfig.extraPackages
  ++ (with pkgs; [
    # Networking / infra (alongside Tailscale)
    wireguard-tools

    # Build tools for Rust / C++ / Python work
    pkg-config
    gcc
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
      font-size = fontSize;
      theme = "Everforest Dark Hard";
      window-decoration = "none";
      background-opacity = 0.95;
      cursor-style = "block";
      shell-integration = "zsh";
      mouse-scroll-multiplier = 1.0;
    };
  };

  # ── Zsh (config from nix/terminal-tools/config.nix) ──────────────────────
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = termConfig.shellAliases // {
      # NixOS-specific helpers (not relevant on Ubuntu)
      # $(hostname) expands at run-time, matching the flake target name
      # (nixos-pc or nixos-laptop as set by networking.hostName).
      rebuild = "sudo nixos-rebuild switch --flake $HOME/repos/dev/nixos#$(hostname)";
      update = "sudo nixos-rebuild switch --flake $HOME/repos/dev/nixos#$(hostname) --upgrade";
      ros = "source /opt/ros/jazzy/setup.zsh";
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

  # ── Git config ──────────────────────────────────────────────────────────
  programs.git = {
    enable = true;

    signing = {
      key = "~/.ssh/signing.pub";
      signByDefault = true;
    };

    extraConfig = {
      gpg.format = "ssh";
    };
  };

  # ── SSH agent (systemd user service) ────────────────────────────────────
  services.ssh-agent.enable = true;

  # Force SSH/git to prompt in the terminal instead of spawning a GUI dialog.
  # Without this, SSH_ASKPASS may be picked up from the system (e.g. via
  # gnome-keyring started by PAM/SDDM) and open a popup that blocks paste.
  home.sessionVariables = {
    SSH_ASKPASS = "";
    GIT_TERMINAL_PROMPT = "1";
  };

  # ── SSH ───────────────────────────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      identityFile = "~/.ssh/id_ed25519";
      identitiesOnly = true;
    };
    settings."*" = {
      AddKeysToAgent = "yes";
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
    };
  };

  # ── Cursor ────────────────────────────────────────────────────────────────
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = cursorSize;
    hyprcursor = {
      enable = true;
      size = cursorSize;
    };
  };

  # ── Tofi launcher ────────────────────────────────────────────────────────
  xdg.configFile."tofi/config".text = ''
    width = 100%
    height = 100%
    border-width = 0
    outline-width = 0
    padding-left = 35%
    padding-top = 35%
    result-spacing = 25
    num-results = 5
    font = monospace
    background-color = #1e2326dd
    text-color = #859289ff
    prompt-color = #a7c080ff
    selection-color = #d3c6aaff
    selection-background = #2e383cff
    selection-match-color = #dbbc7fff
  '';

  # ── XDG ───────────────────────────────────────────────────────────────────
  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = { };
  };

  # ── Hypridle (idle / lock) ───────────────────────────────────────────────
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "hyprlock";
        }
        {
          timeout = 900;
          on-timeout = "suspend";
        }
      ];
    };
  };

  programs.home-manager.enable = true;
}
