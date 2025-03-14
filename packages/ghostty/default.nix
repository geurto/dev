{
  pkgs,
  ghostty,
  neovim ? null,
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
  '';

  zshConfig = pkgs.writeText "zshrc" ''
    # Path to oh-my-zsh installation
    export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh

    # Set theme
    ZSH_THEME="robbyrussell"

    # Add plugins
    plugins=(git z)

    # Sources 
    source $ZSH/oh-my-zsh.sh

    # Alias for neovim
    alias nv='nix run --extra-experimental-features "nix-command flakes"  github:geurto/nix'

    # Personal additions
    # -- fzf
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
      --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
      --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
      --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
      --color=border:#262626,label:#aeaeae,query:#d9d9d9
      --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
      --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

    # -- nvm
    export NVM_DIR="$HOME/.nvm"
    # Lazy load nvm using a function
    nvm() {
      unset -f nvm
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      nvm "$@"
    }

    export PATH="$PATH:/opt/nvim-linux64/bin"
    export CUDA_HOME=/usr/local/cuda
    export PATH=$PATH:/usr/local/cuda/bin
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-12.6/lib64
    export RUST_LOG=info

    source ~/.config/*/cmd.sh

    # -- aliases
    alias s='source /opt/ros/*/setup.zsh && source ~/repos/*/install/setup.zsh'
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
  };
in
ghosttyWithZsh
