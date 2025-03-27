{
  pkgs ? import <nixpkgs> { },
}:

let
  # Import your dependencies module
  deps = import ./packages/dependencies { inherit pkgs; };

  # Import your terminal configuration
  terminal = import ./packages/terminal { inherit pkgs; };
in
pkgs.mkShell {
  # Combine all packages
  buildInputs =
    with pkgs;
    [
      # Basic tools needed for the flake
      git
      nix
    ]
    ++ deps.packages
    ++ terminal.terminalPackages;

  # Combine shell hooks
  shellHook = ''
    echo "Loading development environment..."

    # Apply the shell hooks from dependencies
    ${deps.shellHook}

    # Apply the terminal configuration
    ${terminal.terminalHook}
  '';
}
