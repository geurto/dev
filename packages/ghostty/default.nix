{
  pkgs,
  ghostty,
  neovim ? null,
  deps ? [ ],
}:

let
  # Get nixGL from pkgs
  nixGL = pkgs.nixgl.nixGLDefault;

  # Custom config for Ghostty
  ghosttyConfig = pkgs.writeText "ghostty.conf" ''
    # Appearance
    theme = catppuccin-mocha
    font-family = JetBrainsMono Nerd Font
    font-size = 12
    cursor-opacity = 0.8

    # Keybindings
    keybind = alt+j=goto_split:down
    keybind = alt+k=goto_split:up
    keybind = alt+h=goto_split:left
    keybind = alt+l=goto_split:right
    keybind = alt+shift+j=resize_split:down,10
    keybind = alt+shift+k=resize_split:up,10
    keybind = alt+shift+h=resize_split:left,10
    keybind = alt+shift+l=resize_split:right,10
    keybind = alt+shift+r=equalize_splits
  '';

  zshConfig = pkgs.writeText "zshrc" ''
    # Set OpenSSL environment variables - this runs for every zsh instance
    export OPENSSL_ROOT_DIR=${pkgs.openssl.dev}
    export OPENSSL_LIBRARIES=${pkgs.openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${pkgs.openssl.dev}/lib/pkgconfig

    # Add host system libraries to search paths
    export NIX_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$NIX_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

    # Source user's zshrc if it exists
    if [[ -f ~/.zshrc ]]; then
      source ~/.zshrc
    fi
  '';

  # Create the wrapper script
  wrapper = pkgs.writeShellScriptBin "ghostty-wrapper" ''
    #!/usr/bin/env bash

    # Set locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Set TERM for proper terminal behavior
    export TERM=xterm-256color

    # Custom settings (only theme for now)
    mkdir -p ~/.config/ghostty
    cp ${ghosttyConfig} ~/.config/ghostty/config

    # Check if we're already running under nixGL
    if [ -n "$NIXGL_BYPASS" ]; then
      exec ${ghostty}/bin/ghostty "$@"
    else
      # Try to use nixGL from PATH first
      if command -v nixGL >/dev/null 2>&1; then
        NIXGL_BYPASS=1 exec nixGL "$0" "$@"
      else
        # Fall back to nix run
        echo "nixGL not found in PATH, trying to run with nix run..."
        NIXPKGS_ALLOW_UNFREE=1 NIXGL_BYPASS=1 exec nix run --impure github:nix-community/nixGL -- "$0" "$@"
      fi
    fi  '';

  ghosttyWithZsh = pkgs.buildEnv {
    name = "ghostty-with-zsh";
    paths = [
      wrapper
      pkgs.zsh
      pkgs.oh-my-zsh
      pkgs.zsh-syntax-highlighting
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zsh \
        --prefix PATH : ${pkgs.lib.makeBinPath deps} \
        --add-flags "-i" \
        --set ZDOTDIR ${
          pkgs.stdenv.mkDerivation {
            name = "zsh-dotdir";
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out
              cp ${zshConfig} $out/.zshrc
            '';
          }
        }
    '';
  };
in
ghosttyWithZsh
