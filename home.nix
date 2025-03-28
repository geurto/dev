{ config, pkgs, ... }:

let
  # Import nixpkgs with config
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };
  # Import your custom dependencies
  dependencies = import ./packages/dependencies/default.nix { inherit pkgs; };
in
{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "peter";
  home.homeDirectory = "/home/peter"; # or /Users/YOUR_USERNAME on macOS

  # This value determines the Home Manager release that your configuration is compatible with
  home.stateVersion = "23.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Add your custom dependencies to packages
  home.packages =
    dependencies.packages
    ++ (with pkgs; [
      # Additional packages
      fzf
      ripgrep
      bat
    ]);

  # Configure zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "z"
      ];
    };

    initExtra = ''
      # utility function to warn if disk space is running low
      check_disk_space() {
        local threshold=95
        local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

        if (( usage > threshold )); then
          echo "\033[1;31mWARNING: Disk space on / is critically low (''${usage}%)!\033[0m"
          echo "Consider cleaning up some files."
        fi
      }
      check_disk_space

      # NVM
      export NVM_DIR="$HOME/.nvm"
      nvm() {
          unset -f nvm
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm "$@"
      }

      # docker container output to screen
      xhost +local:docker > /dev/null 2>&1 || true

      # auto-start tmux
      if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        tmux attach-session -t default || tmux new-session -s default
      fi

      # exports
      export PATH=$PATH:"/home/peter/apps/balena-cli"
      export PATH=$PATH:"/opt/node/bin"
      export PATH="$PATH:/opt/nvim-linux64/bin"
      export CUDA_HOME=/usr/local/cuda
      export PATH=$PATH:/usr/local/cuda/bin
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-12.6/lib64
      export RUST_LOG=info

      # test export
      export LOADED_NIX_ENV=true

      # fzf config
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      # fzf colors
      export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
        --color=fg:#cdd6f4,fg+:#b4befe,bg:#1e1e2e,bg+:#262626
        --color=hl:#89b4fa,hl+:#89dceb,info:#afaf87,marker:#a6e3a1
        --color=prompt:#94e2d5,spinner:#f9e2af,pointer:#cba6f7,header:#87afaf
        --color=border:#7f849c,label:#aeaeae,query:#d9d9d9
        --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
        --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

      # source environments
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -f ~/.config/rancli/cmd.sh ] && source ~/.config/rancli/cmd.sh

      # aliases
    '';

    shellAliases = {
      ll = "ls -la";
      vim = "nvim";
      nv = "nix run --extra-experimental-features 'nix-command flakes'  github:geurto/nix";
      s = "source /opt/ros/*/setup.zsh";
    };
  };

  # Configure tmux
  programs.tmux = {
    enable = true;
    shortcut = "a"; # Set prefix to Ctrl-a
    mouse = true;
    baseIndex = 1;
    historyLimit = 10000;
    terminal = "tmux-256color";

    extraConfig = ''
      # Improve colors
      set -ga terminal-overrides ",xterm-256color:Tc"

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
  };
}
