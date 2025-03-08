{
  description = "My own Neovim flake";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      neovim,
      flake-utils,
      ghostty,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlayFlakeInputs = prev: final: {
          neovim = neovim.packages.${system}.neovim;
        };

        overlayNeovim = prev: final: {
          myNeovim = import ./packages/neovim {
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

        deps = import ./packages/dependencies { inherit pkgs; };

        # Import Zsh configuration
        myZsh = import ./packages/zsh {
          inherit pkgs;
          deps = deps.packages;
        };

        # Import Ghostty configuration
        ghosttyConfig = import ./packages/ghostty {
          inherit pkgs;
          ghostty = ghostty.packages.${system}.default;
          neovim = pkgs.myNeovim;
        };
      in
      {
        packages = {
          default = pkgs.myNeovim;
          ghostty = ghosttyConfig.wrapper;
          zsh = myZsh;
        };
        apps = {
          neovim = {
            type = "app";
            program = "${pkgs.myNeovim}/bin/nvim";
          };
          zsh = {
            type = "app";
            program = "${myZsh}/bin/zsh";
          };
          ghostty = {
            type = "app";
            program = "${ghosttyConfig.wrapper}/bin/ghostty-wrapper";
          };
        };
      }
    );
}
