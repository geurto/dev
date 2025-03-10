{
  pkgs,
  ghostty,
  neovim ? null,
}:

let
  # Get nixGL from pkgs
  nixGL = pkgs.nixgl.nixGLDefault;

  # Create the wrapper script
  wrapper = pkgs.writeShellScriptBin "ghostty-wrapper" ''
    #!/usr/bin/env bash

    # Set locale
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Set TERM for proper terminal behavior
    export TERM=xterm-256color

    # Custom settings (only theme for now)
    echo 'theme = catppuccin-mocha' > ~/.config/ghostty/config

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
in
wrapper
