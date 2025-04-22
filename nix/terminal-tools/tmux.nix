{ pkgs, ... }:

let
  tmuxConfig = pkgs.writeTextFile {
    name = "tmux.conf";
    text = ''
      # Set prefix key to Ctrl-a
      set -g prefix C-a
      unbind C-b
      bind C-a send-prefix

      # Enable mouse support
      set -g mouse on

      # Start window numbering at 1
      set -g base-index 1
      setw -g pane-base-index 1

      # Set history limit
      set -g history-limit 10000

      # Set terminal
      set -g default-terminal "tmux-256color"
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

      # Set default shell to zsh
      set-option -g default-shell "${pkgs.zsh}/bin/zsh"
    '';
  };

  # Create a directory with the tmux configuration
  tmuxConfigDir = pkgs.runCommand "tmux-config" { } ''
    mkdir -p $out/etc
    cp ${tmuxConfig} $out/etc/tmux.conf

    # Create a wrapper script that uses our config
    mkdir -p $out/bin
    cat > $out/bin/tmux << EOF
    #!${pkgs.bash}/bin/bash
    TMUX_TMPDIR=\$HOME/.tmux/tmp
    mkdir -p \$TMUX_TMPDIR
    exec ${pkgs.tmux}/bin/tmux -f $out/etc/tmux.conf "\$@"
    EOF

    chmod +x $out/bin/tmux
  '';
in
tmuxConfigDir
