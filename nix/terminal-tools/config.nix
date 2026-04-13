# Shared terminal configuration — ground truth for both Ubuntu (nix profile) and NixOS.
# Imported by nix/terminal-tools/{zsh,tmux,fzf}.nix (Ubuntu) and nixos/home.nix (NixOS).
{ pkgs }:
{
  # Extra packages bundled alongside the wrapper derivations.
  # NOTE: fzf, tmux, and zsh are intentionally absent here — on Ubuntu they are
  # provided by the wrapper derivations in default.nix; on NixOS they are managed
  # by home-manager's programs.{fzf,tmux,zsh} modules.
  extraPackages = with pkgs; [
    bat
    delta
    eza
    lazygit
    ripgrep
    starship
    zoxide
  ];

  # Shell aliases
  shellAliases = {
    ls  = "eza --icons";
    ll  = "eza -lah --icons --git";
    cat = "bat";
    cd  = "z";
    lg  = "lazygit";
  };

  # Starship prompt settings
  starshipSettings = {
    add_newline = false;
    character = {
      success_symbol = "[❯](bold green)";
      error_symbol   = "[❯](bold red)";
    };
    rust.symbol        = " ";
    python.symbol      = " ";
    git_branch.symbol  = " ";
    directory.truncation_length = 4;
  };

  # Zsh init snippet — shared across platforms.
  # Uses Nix interpolation for store paths; ''${VAR} escapes shell variables.
  zshInitExtra = ''
    # Warn if disk space is running low
    check_disk_space() {
      local threshold=95
      local usage
      usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
      if (( usage > threshold )); then
        echo "\033[1;31mWARNING: Disk space on / is critically low (''${usage}%)!\033[0m"
        echo "Consider cleaning up some files."
      fi
    }
    check_disk_space

    # Allow docker containers to use the X display (no-op on Wayland)
    xhost +local:docker >/dev/null 2>&1 || true

    # Auto-start / attach tmux
    if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
      tmux attach-session -t default || tmux new-session -s default
    fi

    # Zoxide (smarter cd — sets up 'z' command, aliased to 'cd' above)
    eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

    # FZF key bindings and tab completion
    [[ $- == *i* ]] && source "${pkgs.fzf}/share/fzf/completion.zsh" 2>/dev/null
    source "${pkgs.fzf}/share/fzf/key-bindings.zsh"

    # FZF colours (Catppuccin Mocha)
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
      --color=fg:#cdd6f4,fg+:#b4befe,bg:#1e1e2e,bg+:#262626
      --color=hl:#89b4fa,hl+:#89dceb,info:#afaf87,marker:#a6e3a1
      --color=prompt:#94e2d5,spinner:#f9e2af,pointer:#cba6f7,header:#87afaf
      --color=border:#7f849c,label:#aeaeae,query:#d9d9d9
      --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
      --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

    if command -v rg >/dev/null; then
      export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
  '';

  # Tmux configuration
  tmuxConf = ''
    # Prefix: Ctrl-a
    set -g prefix C-a
    unbind C-b
    bind C-a send-prefix

    # Mouse support
    set -g mouse on

    # Window/pane numbering from 1
    set -g base-index 1
    setw -g pane-base-index 1

    # Scrollback history
    set -g history-limit 10000

    # True colour
    set -g default-terminal "tmux-256color"
    set -as terminal-overrides ',*:Tc'
    set -as terminal-features ',*:RGB'

    # Status bar
    set -g status-style bg=black,fg=white
    set -g window-status-current-style bg=white,fg=black,bold

    # Vim-like pane navigation
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Split panes with | and -
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    unbind '"'
    unbind %

    # Reload config
    bind r source-file ~/.tmux.conf \; display "Config reloaded!"
  '';
}
