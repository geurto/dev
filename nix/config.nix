{ pkgs }:
let
  scripts2ConfigFiles =
    dir:
    let
      configDir = pkgs.stdenv.mkDerivation {
        name = "nvim-${dir}-configs";
        # Update this path to point to the correct location
        src = ../config/${dir};
        installPhase = ''
          mkdir -p $out/
          cp ./* $out/
        '';
      };
    in
    builtins.map (file: "${configDir}/${file}") (builtins.attrNames (builtins.readDir configDir));

  sourceConfigFiles =
    files:
    builtins.concatStringsSep "\n" (
      builtins.map (
        file: (if pkgs.lib.strings.hasSuffix "lua" file then "luafile" else "source") + " ${file}"
      ) files
    );

  vimrc = scripts2ConfigFiles "vimrc";
  lua = scripts2ConfigFiles "lua";

in
builtins.concatStringsSep "\n" (
  builtins.map (configs: sourceConfigFiles configs) [
    vimrc
    lua
  ]
)
