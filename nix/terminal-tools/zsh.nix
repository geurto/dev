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

      # docker container output to screen
      xhost +local:docker > /dev/null 2>&1 || true

      # auto-start tmux
      if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        tmux attach-session -t default || tmux new-session -s default
      fi

      # run FZF setup if available
      if [ -x "$(command -v fzf-setup)" ]; then
        fzf-setup >/dev/null 2>&1
      fi

      # source FZF configuration
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      # source user's .zshrc if it exists
      if [[ -f ~/.zshrc ]]; then
        source ~/.zshrc
      fi
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
