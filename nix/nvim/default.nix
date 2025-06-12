{ pkgs }:
let
  plugins = import ./plugins.nix { inherit pkgs; };
  dependencies = import ./dependencies.nix { inherit pkgs; };

  luaConfigDir = ../../nvim-config/lua;

  # since we need to load lua files in a specific order, define it here
  orderedLuaFiles = [
    "options.lua"
    "keymaps.lua"

    "alpha.lua"
    "catppuccin.lua"
    "conform.lua"
    "cpp.lua"
    "gitsigns.lua"
    "harpoon.lua"
    "lazygit.lua"
    "lualine.lua"
    "markview.lua"
    "mini.lua"
    "neo-tree.lua"
    "noice.lua"
    "nvim-cmp.lua"
    "nvim-dap-ui.lua"
    "nvim-dap.lua"
    "nvim-lspconfig.lua"
    "nvim-notify.lua"
    "nvim-treesitter.lua"
    "rustaceanvim.lua"
    "telescope.lua"
    "todo-comments.lua"
    "trouble.lua"
    "which-key.lua"
  ];

  customRC = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.map (name: "luafile ${luaConfigDir}/${name}") orderedLuaFiles
  );
  traceCustomRC = builtins.trace customRC customRC;

  neovimRuntimeDependencies = pkgs.symlinkJoin {
    name = "neovimRuntimeDependencies";
    paths = dependencies.packages;
    postBuild = ''
      mkdir -p $out/bin
      for f in $out/lib/node_modules/.bin/*; do
        if [ -f "$f" ]; then 
           path="$(readlink --canonicalize-missing "$f")"
           ln -s "$path" "$out/bin/$(basename "$f")"
        fi
      done
    '';
  };

  NeovimUnwrapped = pkgs.wrapNeovim pkgs.neovim {
    configure = {
      inherit customRC;
      packages.myPlugins.start = plugins;
    };
  };
in
pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = [ neovimRuntimeDependencies ];
  text = ''
    export OPENSSL_ROOT_DIR=${pkgs.openssl.dev}
    export OPENSSL_LIBRARIES=${pkgs.openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
    export fmt_DIR=${pkgs.fmt.dev}/lib/cmake/fmt

    # Run Neovim
    exec ${NeovimUnwrapped}/bin/nvim "$@"
  '';
}
