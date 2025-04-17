{ pkgs }:
let
  scripts2ConfigFiles =
    dir:
    let
      configDir = pkgs.stdenv.mkDerivation {
        name = "nvim-${dir}-configs";
        src = ../../neovim/lua/${dir};
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

  config = scripts2ConfigFiles "config";
  plugins = scripts2ConfigFiles "plugins";

in
builtins.concatStringsSep "\n" (
  builtins.map (configs: sourceConfigFiles configs) [
    config
    plugins
  ]
)
