{ pkgs, ... }:

let
  cfg = import ./config.nix { inherit pkgs; };

  aliasLines = pkgs.lib.concatStringsSep "\n"
    (pkgs.lib.mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases);

  zshrcContent = ''
    # Completion
    autoload -Uz compinit && compinit

    # Plugins
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

    # Aliases
    ${aliasLines}

    # Starship prompt
    eval "$(${pkgs.starship}/bin/starship init zsh)"

    ${cfg.zshInitExtra}

    # Source local overrides (~/.zshrc)
    [[ -f ~/.zshrc ]] && source ~/.zshrc
  '';

  zshConfig = pkgs.writeTextFile {
    name = "zshrc";
    text = zshrcContent;
  };

  zshConfigDir = pkgs.runCommand "zsh-config" { } ''
    mkdir -p $out/etc
    cp ${zshConfig} $out/etc/zshrc

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
