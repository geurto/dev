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
  };
  outputs = { self, nixpkgs, neovim }:
    let
      overlayFlakeInputs = prev: final: {
        neovim = neovim.packages.x86_64-linux.neovim;
      };

      overlayNeovim = prev: final: {
        neovim = import ./packages/neovim {
          pkgs = final;
        };
      };

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlayFlakeInputs overlayNeovim ];
      };

    in {
      packages.x86_64-linux.default = pkgs.neovim;
      apps.x86_64-linux.default = {
        type = "app";
        program = "${pkgs.neovim}/bin/nvim";
      };
    };
}
