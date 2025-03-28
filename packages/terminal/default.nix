# packages/terminal/default.nix
{ pkgs }:

let
  zshConfig = pkgs.writeText "zshrc" ''
    echo "Custom zshrc loaded!" > /tmp/zsh_debug.log

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

    # zsh and oh-my-zsh
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="robbyrussell"
    plugins=(
            git
            z
    )
    source $ZSH/oh-my-zsh.sh

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
    # fzf colors (catppuccin-mocha)
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
    alias s='source /opt/ros/humble/setup.zsh && source ~/repos/ranmarine/install/setup.zsh'
    alias nv='nix run --extra-experimental-features "nix-command flakes"  github:geurto/nix'
    alias nx='nix --extra-experimental-features "nix-command flakes"'
  '';

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

  # Create a shell hook that sets up the terminal environment
  terminalHook = ''
    # Create temporary config directory
    TEMP_CONFIG_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_CONFIG_DIR" EXIT

    # Set up zsh configuration
    cp ${zshConfig} $TEMP_CONFIG_DIR/.zshrc

    # Set up tmux configuration
    cp ${tmuxConfig} $TEMP_CONFIG_DIR/.tmux.conf

    # Set environment variables
    export ZDOTDIR=$TEMP_CONFIG_DIR
    export TMUX_TMPDIR=$TEMP_CONFIG_DIR
    export TMUX_CONFIG=$TEMP_CONFIG_DIR/.tmux.conf

    # Create aliases for tmux to use our config
    alias tmux="tmux -f $TMUX_CONFIG"

    # Set zsh as the shell
    export SHELL=${pkgs.zsh}/bin/zsh

    # Execute zsh with our config
    exec ${pkgs.zsh}/bin/zsh -c "source $TEMP_CONFIG_DIR/.zshrc; exec zsh"
  '';

  # Define the packages needed for the terminal environment
  terminalPackages = with pkgs; [
    zsh
    tmux
    fzf
    ripgrep
    bat
    xorg.xhost # For the xhost command in your zshrc
  ];
in
{
  # Export the shell hook and packages
  inherit terminalHook terminalPackages;

  # Export the config files for reference
  inherit zshConfig tmuxConfig;
}
