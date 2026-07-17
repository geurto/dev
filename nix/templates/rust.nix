{
  description = "Minimal Rust development environment flake template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Apply rust-overlay to nixpkgs
        overlays = [ rust-overlay.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default;

        rustTools = [
          rustToolchain
          pkgs.rust-analyzer
        ];

        # === System Build Dependencies ===
        # Add C/C++ libraries your *specific* Rust project depends on here.
        # This list is empty by default in the template.
        # Examples: pkgs.openssl, pkgs.sqlite, pkgs.udev, pkgs.libpq, pkgs.zeromq
        systemBuildDeps = with pkgs; [
          # Add system libraries required by crates with "-sys" or build.rs here
          # e.g., openssl
        ];

        # === Native Build Tools ===
        # Tools often needed for crates that link against C libraries or have C build steps
        nativeBuildTools = with pkgs; [
          pkg-config 
          gcc        
          clang
          llvmPackages.libclang # Needed by some binding generators
        ];

      in
      {
        # === Development Shell ===
        devShells.default = pkgs.mkShell {
          packages = rustTools ++ systemBuildDeps ++ nativeBuildTools;

          shellHook = ''
            # Set RUST_SRC_PATH for rust-analyzer to find std library sources
            export RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library"
            # export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "lib" "pkgconfig" systemBuildDeps}${PKG_CONFIG_PATH:+:}$PKG_CONFIG_PATH"
            # export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath systemBuildDeps}${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"

          '';

          # Uncomment this if pkg-config fails to find libraries automatically when they are added to systemBuildDeps.
          # PKG_CONFIG_PATH = pkgs.lib.makeSearchPathOutput "lib" "pkgconfig" systemBuildDeps;
        };

        templates.rust = {
          path = ./.;
          description = "A minimal Nix flake for Rust development";
        };
        templates.default = self.templates.rust;
      }
    );
}
