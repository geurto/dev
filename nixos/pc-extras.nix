{
  config,
  lib,
  pkgs,
  ...
}:

{
  # GTX 1070 Ti (Pascal) is not supported by NVIDIA 595.x+.
  # Use the legacy driver for this GPU. Check available variants with:
  #   nix eval 'nixpkgs#linuxPackages.nvidiaPackages' --apply builtins.attrNames
  # Update the attribute name below if nixpkgs uses a different name (e.g. legacy_570).
  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_580;

  networking = {
    hostName = "nixos-pc";
    interfaces.enp5s0.wakeOnLan.enable = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      interfaces.tailscale0.allowedTCPPorts = [ 24473 ];
      checkReversePath = "loose";
    };
  };

  # SSH server — PC only; the laptop is not intended to be SSHed into.
  services.openssh = {
    enable = true;
    ports = [ 24473 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      X11Forwarding = false;
      AllowTcpForwarding = "no";
      GatewayPorts = "no";
      PermitTunnel = false;
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "10m";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
      overalljails = true;
    };
  };

  home-manager.users.peter = {
    services.hypridle.settings.listener = lib.mkForce [
      {
        timeout = 600;
        on-timeout = "hyprlock";
      }
    ];
  };

  # Authorised key for SSH access from laptops.
  users.users.peter.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICBXZelLkNynTfESHau+zkxQjueigC4gQSYYHTayjJMf peter@laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPfp5ahbg75ZcGAQCY2L99MUhpwcpfXpctjuOZITNbq peter@nixos-laptop"
  ];
}
