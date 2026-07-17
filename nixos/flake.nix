{
  description = "NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The dev flake that provides the neovim package and shared terminal config.
    # When working from a local checkout, override with:
    #   --override-input dev path:..
    dev.url = "github:geurto/dev";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      dev,
      ...
    }@inputs:
    let
      system = "x86_64-linux"; # Change to "aarch64-linux" if on ARM / Jetson

      # Home-manager wiring — accepts per-machine args (e.g. isLaptop) so that
      # home.nix can tune sizes without duplicating the whole file.
      mkHmModule = hmArgs: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = {
          inherit inputs system;
        }
        // hmArgs;
        home-manager.users.peter = import ./home.nix;
      };

      sharedModules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
      ];

      mkSystem =
        hmArgs: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs system; };
          modules = sharedModules ++ [ (mkHmModule hmArgs) ] ++ modules;
        };
    in
    {
      # ── PC ────────────────────────────────────────────────────────────────
      # sudo nixos-rebuild switch --flake .#nixos-pc
      nixosConfigurations."nixos-pc" = mkSystem { isLaptop = false; } [
        ./hardware-configuration-pc.nix # PC hardware (committed to repo)
        ./pc-extras.nix # WoL, hostname
      ];

      # ── Laptop ───────────────────────────────────────────────────────────
      # sudo nixos-rebuild switch --flake .#nixos-laptop
      # Before first use: replace hardware-configuration-laptop.nix with
      #   sudo nixos-generate-config --show-hardware-config
      nixosConfigurations."nixos-laptop" = mkSystem { isLaptop = true; } [
        ./hardware-configuration-laptop.nix
        (
          { pkgs, ... }:
          {
            networking.hostName = "nixos-laptop";

            # Power management (improves battery life and thermals)
            services.tlp.enable = true;

            # Restore backlight to a sane level on every boot.
            # The NVIDIA driver / ACPI often resets the panel to its minimum
            # (or a firmware default) and Linux doesn't persist brightness across
            # reboots unless told to.  Adjust the percentage to taste.
            systemd.services.restore-backlight = {
              description = "Restore screen brightness on boot";
              wantedBy = [ "multi-user.target" ];
              after = [ "systemd-backlight@backlight:nvidia_0.service" ];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl set 50%";
              };
            };

          }
        )
      ];
    };
}
