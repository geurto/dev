{ pkgs }:
let
  customRC = import ./config { inherit pkgs; };
  plugins = import ./plugins { inherit pkgs; };
  dependencies = import ../dependencies { inherit pkgs; };

  # Import the shell hooks
  opensslHook = dependencies.opensslHook;
  spdlogHook = dependencies.spdlogHook;
  devHook = dependencies.devHook;

  neovimRuntimeDependencies = pkgs.symlinkJoin {
    name = "neovimRuntimeDependencies";
    paths = dependencies.packages;
    postBuild = ''
      for f in $out/lib/node_modules/.bin/*; do
         path="$(readlink --canonicalize-missing "$f")"
         ln -s "$path" "$out/bin/$(basename $f)"
      done
    '';
  };

  NeovimUnwrapped = pkgs.wrapNeovim pkgs.neovim {
    configure = {
      inherit customRC;
      packages.all.start = plugins;
    };
  };
in
pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = [ neovimRuntimeDependencies ];
  text = ''
    # Initialize variables to avoid "unbound variable" errors
    PKG_CONFIG_PATH=''${PKG_CONFIG_PATH:-}
    LD_LIBRARY_PATH=''${LD_LIBRARY_PATH:-}
    CPLUS_INCLUDE_PATH=''${CPLUS_INCLUDE_PATH:-}
    LIBRARY_PATH=''${LIBRARY_PATH:-}
    CPATH=''${CPATH:-}
    PYTHONPATH=''${PYTHONPATH:-}
    CMAKE_PREFIX_PATH=''${CMAKE_PREFIX_PATH:-}

    # Apply the shell hooks
    ${opensslHook}
    ${spdlogHook}
    ${devHook}

    # Add spdlog to CMAKE_PREFIX_PATH
    export CMAKE_PREFIX_PATH=${pkgs.spdlog}/lib:''${CMAKE_PREFIX_PATH:-}

    # Run Neovim
    ${NeovimUnwrapped}/bin/nvim "$@"
  '';
}
