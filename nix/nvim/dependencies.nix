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
  };

  cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
    mkdir -p $out/bin
    cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
    chmod +x $out/bin/*
  '';

  packages = [
    bat
    binutils
    black
    cargo-nextest
    ccls
    clang-tools
    cpptools
    curl
    delve
    fzf
    gdb
    git
    glibc
    gnumake
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
    podman-compose
    prettierd
    pyright
    ripgrep
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
