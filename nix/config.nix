{ pkgs }:
let
  # Copy the config directory to the Nix store
  configDir = pkgs.stdenv.mkDerivation {
    name = "nvim-config";
    src = ../.;
    installPhase = ''
      mkdir -p $out/
      cp -r ./config/* $out/
    '';
  };

  # Create a simple init.lua that loads everything
  initLua = pkgs.writeText "init.lua" ''
    -- Add the config directory to the runtime path
    vim.opt.runtimepath:prepend("${configDir}")

    -- Load init.lua from the config directory
    dofile("${configDir}/init.lua")
  '';

in
"luafile ${initLua}"
