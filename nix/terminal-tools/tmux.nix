{ pkgs, ... }:

let
  cfg = import ./config.nix { inherit pkgs; };

  tmuxConfig = pkgs.writeTextFile {
    name = "tmux.conf";
    # Append the default shell setting (Ubuntu-only; NixOS home-manager handles this itself)
    text = cfg.tmuxConf + ''

      # Default shell (set for non-NixOS environments)
      set-option -g default-shell "${pkgs.zsh}/bin/zsh"
    '';
  };

  tmuxConfigDir = pkgs.runCommand "tmux-config" { } ''
    mkdir -p $out/etc
    cp ${tmuxConfig} $out/etc/tmux.conf

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
