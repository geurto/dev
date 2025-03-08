{
  pkgs,
  ghostty,
  neovim ? null,
  nixglPackage ? null,
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

    # Check if we're already running under nixGL
    if [ -n "$NIXGL_BYPASS" ]; then
      exec ${ghostty}/bin/ghostty "$@"
    else
      # Try to use nixGL from PATH first
      if command -v nixGL >/dev/null 2>&1; then
        NIXGL_BYPASS=1 exec nixGL "$0" "$@"
      else
        # Try to use provided nixGL package
        if [ -n "${toString nixglPackage}" ]; then
          NIXGL_BYPASS=1 exec ${nixglPackage}/bin/nixGL "$0" "$@"
        else
          # Fall back to nix run
          echo "nixGL not found, trying to run with nix run..."
          NIXPKGS_ALLOW_UNFREE=1 NIXGL_BYPASS=1 exec nix run --impure github:nix-community/nixGL -- "$0" "$@"
        fi
      fi
    fi    
  '';
in
wrapper
