{
  pkgs,
  ghostty,
  neovim ? null,
}:

let
  # Get nixGL from pkgs
  nixGL = pkgs.nixgl.nixGLDefault;

  # Optional: Create a config file
  configFile = pkgs.writeText "ghostty.conf" ''
    # Ghostty configuration
    font-family = "JetBrainsMono Nerd Font"
    font-size = 12

    # Set default editor if neovim is provided
    ${
      if neovim != null then "shell-integration-features = no-cursor\nshell = ${neovim}/bin/nvim" else ""
    }

    # Add any other configuration options here
    background = #282c34
    foreground = #abb2bf
  '';

  # Create the wrapper script
  wrapper = pkgs.writeShellScriptBin "ghostty-wrapper" ''
    #!/usr/bin/env bash

    # Set TERM for proper terminal behavior
    export TERM=xterm-256color

    # Check if nixGL is available in PATH
    if command -v nixGL >/dev/null 2>&1; then
      # Use nixGL from PATH
      exec nixGL ${ghostty}/bin/ghostty "$@"
    else
      # Try to run with nix run
      echo "nixGL not found in PATH, trying to run with nix run..."
      NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:nix-community/nixGL -- ${ghostty}/bin/ghostty "$@"
    fi
  '';
in
wrapper
