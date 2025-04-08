{ pkgs }:
let
  customRC = import ./config { inherit pkgs; };
  plugins = import ./plugins { inherit pkgs; };
  dependencies = import ../dependencies { inherit pkgs; };

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

  # Extract the OpenSSL paths
  openssl_dev = pkgs.openssl.dev;
  openssl_out = pkgs.openssl.out;
in
pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = [ neovimRuntimeDependencies ];
  text = ''
    # Set OpenSSL environment variables
    export OPENSSL_ROOT_DIR=${openssl_dev}
    export OPENSSL_LIBRARIES=${openssl_out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl_dev}/include
    export PKG_CONFIG_PATH=${openssl_dev}/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=${pkgs.spdlog}/lib:$LD_LIBRARY_PATH
    ${NeovimUnwrapped}/bin/nvim "$@"
  '';
}
