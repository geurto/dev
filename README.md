# Personal Neovim configuration
This is a self-contained development environment that can be run on any Linux machine. 

## Dependencies
First install nix:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

## Running neovim

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
## Using Neovim in a Docker container
One of Neovim's strengths is its portability. It is great to use for debugging inside a Docker container. For this, we assume that Neovim is installed inside the Docker container.
