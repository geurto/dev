# Personal Nix configuration
This is a self-contained development environment that can be run on any Linux machine. You only need to have nix installed, and nixGL set-up.

## Dependencies
First install nix:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Next, in order to use Ghostty, make sure to install nixGL:
```bash
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault   # or replace `nixGLDefault` with your desired wrapper
```

## Running

To run neovim separately in your terminal, you can do:
```bash
nix run --extra-experimental-features "nix-command flakes"  github:geurto/nix
```
It is worth creating an alias for this.

If you do not want to add the ``--extra-experimental-features`` every time, you can create a ``nix.conf`` file:
```bash
mkdir -p ~/.config/nix
nano ~/.config/nix/nix.conf
```

And put the following content in it:
```bash 
 experimental-features = nix-command flakes
```

### ghostty
To run Ghostty, which needs to use nixGL, you have to specify an extra argument:
```bash
nix run --extra-experimental-features "nix-command flakes" --impure github:nix-community/nixGL -- .#ghostty
```

It is quicker to install Ghostty to your nix profile:
```bash
NIXPKGS_ALLOW_UNFREE=1 nix profile install github:geurto/nix#ghostty
```

which then allows you to run Ghostty with ``ghostty-wrapper``. You can also create a shortcut for this (e.g. ``ALT+CTRL+G``) for easy terminal launching.
