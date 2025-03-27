{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Basic tools needed for the flake
    git
    nix
  ];

  shellHook = ''
    echo "Loading development environment..."
    # You can use 'home-manager switch' to apply your configuration
    # or just use this shell for temporary access to your tools
  '';
}
