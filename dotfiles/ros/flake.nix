{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nix-ros-overlay,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-ros-overlay.overlays.default ];
        };

        # Customize this section based on your ROS2 needs
        rosDistro = "humble"; # Change to your ROS2 distribution
        rosPackages = pkgs.rosPackages.${rosDistro};

        pythonWithDeps = pkgs.python310.withPackages (
          ps: with ps; [
            empy
            # Add other Python packages you might need
          ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          name = "ros2-workspace";

          packages = [
            pkgs.colcon
            pkgs.python310Packages.rosdep
            pythonWithDeps

            # ROS2 packages
            (
              with rosPackages;
              buildEnv {
                paths = [
                  ros-core
                ];
              }
            )
          ];

          # Shell hook to set up ROS2 environment variables
          shellHook = ''
            export ROS_DOMAIN_ID=420  # Customize as needed
            export ROS_LOCALHOST_ONLY=1  # Restrict to localhost

            export PYTHONPATH=${pythonWithDeps}/${pythonWithDeps.sitePackages}:$PYTHONPATH

            # Source ROS2 setup scripts
            if [ -f "${rosPackages.ros-core}/setup.bash" ]; then
              source "${rosPackages.ros-core}/setup.bash"
            fi

            # Source local workspace if it exists
            if [ -f "$PWD/install/setup.bash" ]; then
              source "$PWD/install/setup.bash"
            fi

            echo "ROS2 ${rosDistro} development environment activated!"
          '';
        };
      }
    );

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
