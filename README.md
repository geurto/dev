# Personal Nix configuration
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

### Running neovim in a Docker container
In order to run neovim in a Docker container for debugging, you will have to mount your entire `/nix/store` directory:
```bash
docker run -it --privileged --net host -v /nix/store:/nix/store -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY <DOCKER_IMAGE> zsh
```
Now you can run neovim by specifying the nix store path. If you installed neovim to your nix profile, you can make things easier for yourself by also mounting your nix profile:
```bash

docker run -it --privileged --net host -v ~/.nix-profile:/nix-profile -v /nix/store:/nix/store -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY <DOCKER_IMAGE> zsh
```
This way, you can run neovim with `/nix-profile/bin/nvim`.

## Home-manager
The home.nix file provides configuration files for zsh (including oh-my-zsh) and tmux.
Furthermore, a whole lot of dependencies are installed to develop with.

To use this home configuration, you have to enable home-manager:

```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

This should allow you to run `home-manager` commands.

Now, to enable the configuration in *home.nix*, run `home-manager switch --file home.nix` while in this repository's root directory. If you already have a `~/.zshrc` or `~/.config/tmux/tmux.conf`, you will get asked to rename these.

## Dotfiles
The `dotfiles` directory holds .envrc files to be used when developing specific applications. Currently, only a ROS2 environment is supported. To use this, put `flake.nix` and `.envrc` in your ROS2 workspace.
