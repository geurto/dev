{ pkgs }:
let
  customRC = import ./config.nix { inherit pkgs; };
  plugins = import ./plugins.nix { inherit pkgs; };
  dependencies = import ./dependencies.nix { inherit pkgs; };

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
    export OPENSSL_ROOT_DIR=${pkgs.openssl.dev}
    export OPENSSL_LIBRARIES=${pkgs.openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
    export fmt_DIR=${pkgs.fmt.dev}/lib/cmake/fmt

    # Run Neovim
    ${NeovimUnwrapped}/bin/nvim "$@"
  '';
}
