{
  description = "NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The dev flake that provides the neovim package and shared terminal config.
    # When working from a local checkout, override with:
    #   --override-input dev path:..
    dev.url = "github:geurto/dev";
  };

  outputs = { self, nixpkgs, home-manager, dev, ... }@inputs:
  let
    system = "x86_64-linux"; # Change to "aarch64-linux" if on ARM / Jetson
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs system; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs system; };
          home-manager.users.peter = import ./home.nix;
        }
      ];
    };
  };
}
