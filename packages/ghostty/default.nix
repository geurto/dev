{
  pkgs,
  ghostty,
  neovim ? null,
  deps ? [ ],
}:

let
  # Get nixGL from pkgs
  nixGL = pkgs.nixgl.nixGLDefault;

  # tmux dependencies
  tmuxDeps = [
    pkgs.tmux
    pkgs.tmuxPlugins.sensible
    pkgs.tmuxPlugins.yank
  ];

  tmuxConfig = pkgs.writeText "tmux.conf" ''
    # Set prefix to Ctrl-a (or keep Ctrl-b if you prefer)
    unbind C-b
    set -g prefix C-a
    bind C-a send-prefix

    # Enable mouse support
    set -g mouse on

    # Start window numbering at 1
    set -g base-index 1
    setw -g pane-base-index 1

    # Improve colors
    set -g default-terminal "tmux-256color"
    set -ga terminal-overrides ",xterm-256color:Tc"

    # Increase scrollback buffer size
    set -g history-limit 10000

    # Customize status bar
    set -g status-style bg=black,fg=white
    set -g window-status-current-style bg=white,fg=black,bold

    # Vim-like pane navigation
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Split panes using | and -
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    unbind '"'
    unbind %

    # Reload config file
    bind r source-file ~/.tmux.conf \; display "Config reloaded!"
  '';

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

    # Start with tmux
    command = ${pkgs.tmux}/bin/tmux new-session -A -s default
  '';

  zshConfig = pkgs.writeText "zshrc" ''
    echo "Custom zshrc loaded!" > /tmp/zsh_debug.log
    # Set OpenSSL environment variables - this runs for every zsh instance
    export OPENSSL_ROOT_DIR=${pkgs.openssl.dev}
    export OPENSSL_LIBRARIES=${pkgs.openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${pkgs.openssl.dev}/lib/pkgconfig

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

    # Set up Go environment in the wrapper itself
    export GOPATH=$HOME/go
    export GOROOT="${pkgs.go}/share/go"
    export PATH=$PATH:${pkgs.lib.makeBinPath deps}:$GOPATH/bin

    # Custom ghostty settings (only theme for now)
    mkdir -p ~/.config/ghostty
    cp ${ghosttyConfig} ~/.config/ghostty/config

    # Copy tmux config
    cp ${tmuxConfig} ~/.tmux.conf

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
    ] ++ tmuxDeps;
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
