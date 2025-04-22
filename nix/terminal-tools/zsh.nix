{ pkgs, ... }:

let
  zshConfig = pkgs.writeTextFile {
    name = "zshrc";
    text = ''
      # Oh-My-Zsh setup
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
      ZSH_THEME="robbyrussell"
      plugins=(git z)
      source $ZSH/oh-my-zsh.sh

      # Enable syntax highlighting and autosuggestions
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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

      # Create necessary directories if they don't exist
      mkdir -p "$GOPATH"/bin
      mkdir -p "$CARGO_HOME"/bin
      mkdir -p "$PYTHONUSERBASE"/bin
      mkdir -p "$NPM_CONFIG_PREFIX"/bin

      # Aliases
      alias ll="ls -la"
      alias vim="nvim"
      alias nv="nix run --extra-experimental-features 'nix-command flakes'  github:geurto/nix"
      alias s="source /opt/ros/*/setup.zsh"
    '';
  };

  # Create a directory with the zsh configuration
  zshConfigDir = pkgs.runCommand "zsh-config" { } ''
    mkdir -p $out/etc
    cp ${zshConfig} $out/etc/zshrc

    # Create a wrapper script that uses our config
    mkdir -p $out/bin
    cat > $out/bin/zsh << EOF
    #!${pkgs.bash}/bin/bash
    ZDOTDIR=\$HOME/.zsh
    mkdir -p \$ZDOTDIR
    export ZDOTDIR
    ln -sf $out/etc/zshrc \$ZDOTDIR/.zshrc
    exec ${pkgs.zsh}/bin/zsh "\$@"
    EOF

    chmod +x $out/bin/zsh
  '';
in
zshConfigDir
