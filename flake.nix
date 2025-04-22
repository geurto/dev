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
  };
  outputs =
    {
      self,
      nixpkgs,
      neovim,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlayFlakeInputs = prev: final: {
          neovim = neovim.packages.${system}.neovim;
        };

        # switch to newer Python version to overcome Python 3.10 sphinx error
        overlayNeovim = prev: final: {
          myNeovim = import ./nix/nvim {
            pkgs = final // {
              python310 = final.python312;
              python310Packages = final.python312Packages;
            };
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

        deps = import ./nix/dependencies.nix { inherit pkgs; };
      in
      {
        packages = {
          default = pkgs.myNeovim;
          neovim = pkgs.myNeovim;
          terminal-tools = import ./nix/terminal-tools { inherit pkgs; };
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
