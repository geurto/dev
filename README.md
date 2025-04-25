# Personal Nix configuration
This is a self-contained development environment that can be run on any Linux machine. 

## Dependencies
First install nix:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```
Then, move `nix/nix.conf` to `/etc/nix/nix.conf`.

## Installation
If using nix-profile, run this command:
```bash
nix profile install dev terminal-tools
```
This will ensure all the binaries are available as normal user commands.

## Running neovim
To run neovim separately in your terminal, you can do:
```bash
nix run --extra-experimental-features "nix-command flakes"  github:geurto/dev
```

### Running neovim in a Docker container
In order to run neovim in a Docker container for debugging, you can mount the `nvim` directory (assuming the docker image has neovim installed):
```bash
docker run -it --privileged --net host -v <DEV_ROOT>/nvim/:/root/.config/nvim/ -v /usr/bin/nvim:/usr/bin/nvim <DOCKER_IMAGE> bash
```

## Terminal tools
The `terminal-tools` directory holds a configuration for zsh and tmux. This can be used in parallel with your favourite terminal, which you should install on your system. Previously, I've tried (a) packaging the terminal as a standalone Nix executable using nixGL, and (b) having the terminal managed by home-manager.

In the case of (a), nixGL caused issues when launching GUI applications from the terminal. In the case of (b), home-manager clashed with system dependencies, making it difficult to work on projects. Therefore, if you have some system dependencies already installed, it is best to go for this hybrid setup. Of course, this only matters when running on Ubuntu or some other non-NixOS operating system.

## System
The `system` directory holds all system dependencies, i.e. anything not managed by Nix. When I next do a clean Ubuntu install, I might swap this part out for home-manager. 

The `install.sh` script installs basic system dependencies, i3 window manager with polybar, and alacritty as a terminal emulator. Finally, it copies the configurations for these applications to `~/.config/`. Note that `alacritty.toml` assumes that `zsh` is installed by Nix.
