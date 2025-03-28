# Personal Nix configuration
This is a self-contained development environment that can be run on any Linux machine. You only need to have nix installed, and nixGL set-up.

## Dependencies
First install nix:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
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

### terminal
The terminal environment includes some tools I find useful for using the terminal (tmux, zsh, oh-my-zsh), as well as dependencies needed to develop in a couple of languages (Rust, C++, Python, Go, TypeScript).

To enter this shell, go to the root directory of this repository and run `nix develop`.
In order to automatically load this shell environment when you open a terminal, add it to your terminal's start-up command. For alacritty, for instance, this is achieved by adding the following line to your *alacritty.toml* file:
