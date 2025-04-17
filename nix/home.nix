{ config, pkgs, ... }:

let
  # Import nixpkgs with config
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };
  dependencies = import ./dependencies.nix { inherit pkgs; };

  # Extract the Python environment from dependencies
  pythonWithPkgs = pkgs.python310.withPackages (
    ps: with ps; [
      debugpy
      pip
    ]
  );
in
{
  home.username = "peter";
  home.homeDirectory = "/home/peter";

  # This value determines the Home Manager release that your configuration is compatible with
  home.stateVersion = "23.05";

  programs.home-manager.enable = true;

  home.packages = dependencies.packages;

  home.sessionVariables = {
    OPENSSL_ROOT_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIBRARIES = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";

    # spdlog variables
    CMAKE_PREFIX_PATH = "${pkgs.spdlog}:$CMAKE_PREFIX_PATH";
    spdlog_DIR = "${pkgs.spdlog}/lib/cmake/spdlog";
    fmt_DIR = "${pkgs.fmt.dev}/lib/cmake/fmt";

    # Development environment variables
    CARGO_HOME = "$HOME/.cargo";
    CPATH = "${pkgs.glibc.dev}/include:${pkgs.gcc}/include/c++/${pkgs.gcc.version}:$CPATH";
    CPLUS_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.gcc}/include/c++/${pkgs.gcc.version}:$CPLUS_INCLUDE_PATH";
    CUDA_HOME = "/usr/local/cuda";
    GOPATH = "$HOME/go";
    GOROOT = "${pkgs.go}/share/go";
    LD_LIBRARY_PATH = "${pkgs.openblas}/lib:${pkgs.spdlog}/lib:/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH";
    LIBRARY_PATH = "${pkgs.glibc}/lib:${pkgs.gcc}/lib:$LIBRARY_PATH";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    PYTHONPATH = "${pythonWithPkgs}/${pythonWithPkgs.sitePackages}:/usr/lib/python3/dist-packages:/usr/local/lib/python3/dist-packages:/opt/ros/humble/lib/python3.10/site-packages:$PYTHONPATH";
    PYTHONUSERBASE = "$HOME/.local/python";
    RUSTUP_HOME = "$HOME/.rustup";
  };

  # Add paths to PATH
  home.sessionPath = [
    "$GOPATH/bin"
    "$CARGO_HOME/bin"
    "$PYTHONUSERBASE/bin"
    "$NPM_CONFIG_PREFIX/bin"
    "/home/peter/apps/balena-cli"
    "/opt/node/bin"
    "/opt/nvim-linux64/bin"
    "/usr/local/cuda/bin"
    "${pkgs.lib.makeBinPath dependencies.packages}"
  ];

  # Configure alacritty
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        "TERM" = "xterm-256color";
      };

      general = {
        import = [
          "~/.config/alacritty/catppuccin-mocha.toml"
        ];
      };

      window = {
        padding = {
          x = 10;
          y = 10;
        };
        decorations = "full";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 10.5;
      };

      # Set shell to your zsh from home-manager
      terminal = {
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [ "-l" ];
        };
      };

      cursor = {
        style = "Block";
      };
    };
  };

  # Fetch the theme file
  home.file.".config/alacritty/catppuccin-mocha.toml" = {
    text = builtins.readFile (
      builtins.fetchurl {
        url = "https://raw.githubusercontent.com/catppuccin/alacritty/main/catppuccin-mocha.toml";
        sha256 = "1idjbm5jim9b36235hgwgp9ab81fmbij42y7h85l4l7cqcbyz74l";
      }
    );
  };

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
    shortcut = "a";
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
