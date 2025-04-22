{ pkgs, ... }:

let
  # Create a wrapper script that sets up FZF
  fzfScript = pkgs.writeShellScriptBin "fzf-setup" ''
    # Create the directory for FZF configuration
    mkdir -p $HOME/.config/fzf

    # Create the FZF configuration file
    cat > $HOME/.config/fzf/fzf.zsh << 'EOF'
    # Setup fzf
    # ---------
    if [[ ! "$PATH" == *${pkgs.fzf}/bin* ]]; then
      export PATH="${pkgs.fzf}/bin:$PATH"
    fi

    # Auto-completion
    # ---------------
    [[ $- == *i* ]] && source "${pkgs.fzf}/share/fzf/completion.zsh" 2> /dev/null

    # Key bindings
    # ------------
    source "${pkgs.fzf}/share/fzf/key-bindings.zsh"

    # FZF colors matching your theme
      export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
        --color=fg:#cdd6f4,fg+:#b4befe,bg:#1e1e2e,bg+:#262626
        --color=hl:#89b4fa,hl+:#89dceb,info:#afaf87,marker:#a6e3a1
        --color=prompt:#94e2d5,spinner:#f9e2af,pointer:#cba6f7,header:#87afaf
        --color=border:#7f849c,label:#aeaeae,query:#d9d9d9
        --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
        --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

    # Use ripgrep for better performance if available
    if command -v rg >/dev/null; then
      export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
    EOF

    # Create a symlink to make it easier to source
    ln -sf $HOME/.config/fzf/fzf.zsh $HOME/.fzf.zsh

    # Run the setup script
    source $HOME/.fzf.zsh
  '';

  # Create a directory with the FZF configuration
  fzfConfigDir = pkgs.runCommand "fzf-config" { } ''
    mkdir -p $out/bin
    mkdir -p $out/share/fzf

    # Copy the FZF binary and scripts
    cp -r ${pkgs.fzf}/bin/* $out/bin/
    cp -r ${pkgs.fzf}/share/fzf/* $out/share/fzf/

    # Add our setup script
    cp ${fzfScript}/bin/fzf-setup $out/bin/
    chmod +x $out/bin/fzf-setup
  '';
in
fzfConfigDir
