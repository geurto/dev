{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./greetd.nix
  ];
  # ── Bootloader ────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.network.wait-online.enable = false;

  boot.kernelParams = [
    "noresume"
    "quiet"
  ];

  # ── Networking ────────────────────────────────────────────────────────────
  # Don't stall boot waiting for any interface to come online
  systemd.network.wait-online.enable = false;
  networking = {
    networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };
  };

  # Tailscale — service + firewall wiring
  services.tailscale.enable = true;

  # ── Locale & Time ─────────────────────────────────────────────────────────
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Desktop (Wayland / Hyprland) ──────────────────────────────────────────
  # xserver is kept for XKB system config (inherited by Xwayland) and for
  # the NVIDIA video driver declaration below.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "intl";
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Polkit is required for Hyprland privilege elevation (e.g. mounting drives).
  security.polkit.enable = true;

  # gnome-keyring provides the Secret Service D-Bus API used by protonvpn-cli
  # for storing credentials. Without it, protonvpn connect/signin fail.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # ── Graphics ──────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Load NVIDIA modules early so greetd can initialise DRM/KMS before it
  # starts. Without this the greeter races against module loading.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  environment.sessionVariables = {
    # NVIDIA + Wayland
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";

    # Hint Electron/Chromium apps to use Wayland; enables native Wayland in Firefox.
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # Dead keys fix: GTK 4.20+ dropped its built-in compose/dead key fallback
    # and now expects an IM framework (IBus/Fcitx). "simple" restores the old
    # naive implementation so dead keys work in GTK apps (including Ghostty,
    # which uses GTK on Linux) without needing a full IM daemon.
    GTK_IM_MODULE = "simple";
  };

  # ── Audio (PipeWire) ──────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # ── Power management ──────────────────────────────────────────────────────
  services.upower.enable = true;

  # ── Users ─────────────────────────────────────────────────────────────────
  users.users.peter = {
    isNormalUser = true;
    description = "Peter";
    extraGroups = [
      "wheel"
      "networkmanager"
      "dialout"
      "docker"
      "plugdev"
      "video"
    ];
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
    btop
    openssl
    unzip
    uv

    # Networking
    networkmanagerapplet
    proton-vpn

    # Device / network utilities
    usbutils
    arp-scan
    dnsutils
    ethtool
    net-tools
    nmap
    wireshark

    # Display stuff
    arandr
    brightnessctl

    # Hyprland ecosystem
    waybar # top bar
    tofi # launcher
    wlsunset # color temperature
    hyprpaper # wallpaper
    hypridle
    hyprlock
    wl-clipboard
    grim
    slurp

    # Notifications (configured as a systemd user service via home-manager)
    libnotify

    # Rust toolchain
    rustup

    # Docker
    docker

    # Firefox
    firefox

    # GIMP
    gimp3

    # Processing
    processing

    # MIDI / audio tools
    alsa-utils
    jack2

    # File manager
    nautilus

    # Torrent
    qbittorrent

    # Claude Code
    claude-code

    # Antigravity
    antigravity

    # Proton tools
    (pkgs.callPackage ./pkgs/protonvpn-cli/default.nix {
      python3Packages = pkgs.python3Packages;
    })

    # Debugging tools
    nix-tree

    # Boot into Windows
    grub2
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
  nixpkgs.config.allowUnfree = true;

  # ── Nix settings ──────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.05";
}
