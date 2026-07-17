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

  # cpptools only ships x86_64 binaries; skip on aarch64 (e.g. Jetson)
  cpptoolsPackages = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (
    let
      cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
        mkdir -p $out/bin
        cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
        chmod +x $out/bin/*
      '';
    in
    [ cpptools vscode-extensions.ms-vscode.cpptools ]
  );

  packages = [
    bat
    binutils
    black
    cargo-nextest
    ccls
    clang-tools
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
    lazygit
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
    ruff
    rust-analyzer
    sshfs
    spdlog
    stow
    stylua
    tmux
    tmuxPlugins.sensible
    wget
    xclip
    xdotool
    xorg.xhost
    xsel
    zsh
  ] ++ cpptoolsPackages;
in
{
  inherit
    packages
    ;
  shellHook = devHook + opensslHook + spdlogHook;
}
