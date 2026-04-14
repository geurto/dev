{ config, pkgs, inputs, ... }:

{
  # ── Bootloader ────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Tailscale — service + firewall wiring
  services.tailscale.enable = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    # Allow forwarding for exit-node / subnet-router use
    checkReversePath = "loose";
  };

  # ── Locale & Time ─────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw"; # adjust as needed
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Desktop (Wayland / Hyprland) ──────────────────────────────────────────
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # for running X11 apps
  };

  # ── Graphics ──────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;
  # Uncomment one of the following if you have a discrete GPU:
  hardware.nvidia.modesetting.enable = true;   # NVIDIA
  # hardware.amdgpu.enable = true;               # AMD

  # ── Audio (PipeWire) ──────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # useful for low-latency MIDI work
  };

  # ── Users ─────────────────────────────────────────────────────────────────
  users.users.peter = {
    isNormalUser = true;
    description = "Peter";
    extraGroups = [ "wheel" "networkmanager" "dialout" "docker" "plugdev" ];
    shell = pkgs.zsh;
  };

  # ── System-wide packages ──────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    curl
    wget
    ripgrep
    fd
    jq
    htop
    unzip

    # Hyprland
    waybar          # status bar
    wofi            # app launcher (or rofi-wayland)
    hyprpaper       # wallpaper
    hypridle        # idle management
    hyprlock        # screen locker
    dunst           # notifications
    wl-clipboard    # clipboard for Wayland
    grim            # screenshots
    slurp           # region selector for screenshots

    # Rust toolchain (you'll likely want rustup for project-level control)
    rustup

    # Docker (handy for your ROS2 containers)
    docker

    # Firefox
    firefox

    # GIMP
    gimp3

    # MIDI / audio tools relevant to your sequencer work
    alsa-utils
    jack2

    # Claude code
    claude-code
  ];

  # ── Docker ────────────────────────────────────────────────────────────────
  virtualisation.docker.enable = true;

  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ── Shell ─────────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # ── Nixpkgs ───────────────────────────────────────────────────────────────
  # Required for vscode-extensions.ms-vscode.cpptools used by neovim's DAP
  nixpkgs.config.allowUnfree = true;

  # ── Nix settings ──────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.05";
}
