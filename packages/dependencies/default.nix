{ pkgs }:
with pkgs;
let
  # Setup shell hook to configure paths for pkg-config
  opensslEnv = pkgs.symlinkJoin {
    name = "openssl-with-paths";
    paths = [
      openssl
      openssl.dev
      openssl.out
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/openssl \
        --set PKG_CONFIG_PATH "${openssl.dev}/lib/pkgconfig"
    '';
  };

  opensslHook = ''
    export OPENSSL_ROOT_DIR=${openssl.dev}
    export OPENSSL_LIBRARIES=${openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${openssl.dev}/lib/pkgconfig
  '';

  cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
    mkdir -p $out/bin
    cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
    chmod +x $out/bin/*
  '';

  pythonWithPkgs = python310.withPackages (
    ps: with ps; [
      debugpy
      # for neovim to run
      sphinx
    ]
  );

  # Hook to ensure spdlog shared libraries are available
  spdlogHook = ''
    export CMAKE_PREFIX_PATH=${spdlog}:$CMAKE_PREFIX_PATH
    # For older CMake versions that don't use CMAKE_PREFIX_PATH
    export spdlog_DIR=${spdlog}/lib  
    export LD_LIBRARY_PATH=${spdlog}/lib:$LD_LIBRARY_PATH
  '';

  # Hook for dev languages (Rust, Go, C++, Python, TypeScript)
  devHook = ''
    # Go
    export GOPATH=$HOME/go
    export GOROOT="${pkgs.go}/share/go"
    export PATH=$GOPATH/bin:$PATH

    # Rust 
    export RUSTUP_HOME=$HOME/.rustup
    export CARGO_HOME=$HOME/.cargo
    export PATH=$CARGO_HOME/bin:$PATH

    # C++ configuration
    export CPLUS_INCLUDE_PATH=${pkgs.glibc.dev}/include:${pkgs.gcc}/include/c++/${pkgs.gcc.version}:$CPLUS_INCLUDE_PATH
    export LIBRARY_PATH=${pkgs.glibc}/lib:${pkgs.gcc}/lib:$LIBRARY_PATH
    export CPATH=${pkgs.glibc.dev}/include:${pkgs.gcc}/include/c++/${pkgs.gcc.version}:$CPATH

    # Python configuration
    export PYTHONPATH=${pythonWithPkgs}/${pythonWithPkgs.sitePackages}:$PYTHONPATH
    export PYTHONUSERBASE=$HOME/.local/python
    export PATH=$PYTHONUSERBASE/bin:$PATH

    # Node.js/TypeScript configuration
    export NPM_CONFIG_PREFIX=$HOME/.npm-global
    export PATH=$NPM_CONFIG_PREFIX/bin:$PATH

    # General development tools
    export PATH=${pkgs.lib.makeBinPath packages}:$PATH

    # Create necessary directories if they don't exist
    mkdir -p "$GOPATH"/bin
    mkdir -p "$CARGO_HOME"/bin
    mkdir -p "$PYTHONUSERBASE"/bin
    mkdir -p "$NPM_CONFIG_PREFIX"/bin
  '';

  packages = [
    bat
    binutils
    black
    cargo-nextest
    ccls
    clang-tools
    cmake
    cpptools
    curl
    delve
    fzf
    gcc
    gdb
    git
    glibc
    gnumake
    go
    golangci-lint
    gopls
    gotools
    isort
    lldb
    lua-language-server
    nixfmt-rfc-style
    nodejs
    nodePackages.svelte-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript
    opensslEnv
    openssh
    pkg-config
    podman-compose
    prettierd
    pyright
    pythonWithPkgs
    ripgrep
    rustup
    spdlog
    stow
    stylua
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.catppuccin
    vscode-extensions.ms-vscode.cpptools
    wget
    xclip
    xdotool
    xorg.xhost
    xsel
    zsh

  ];
in
{
  inherit
    packages
    ;
  shellHook = devHook + opensslHook + spdlogHook;
}
