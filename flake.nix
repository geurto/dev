{
  description = "geurto's development flake";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      neovim,
      flake-utils,
      home-manager,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlayFlakeInputs = prev: final: {
          neovim = neovim.packages.${system}.neovim;
        };

        overlayNeovim = prev: final: {
          myNeovim = import ./neovim/nix {
            pkgs = final;
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            overlayFlakeInputs
            overlayNeovim
          ];
        };

        deps = import ./dependencies.nix { inherit pkgs; };
      in
      {
        homeConfigurations.terminal = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };

        packages = {
          default = pkgs.myNeovim;
        };
        apps = {
          neovim = {
            type = "app";
            program = "${pkgs.myNeovim}/bin/nvim";
          };
          default = self.apps.${system}.neovim;
        };
      }
    );
}
