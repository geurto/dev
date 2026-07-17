#!/bin/bash
# Basic installations for a new system
echo "---------- Installing basic packages ----------"
sudo apt update && sudo apt upgrade -y && sudo apt install -y \
	apt-transport-https \
	build-essential \
	ca-certificates \
	clang \
	cmake \
	curl \
	gdb \
	git \
	python3 \
	python3-pip \
	python3-venv \
	software-properties-common

# Install nix
if ! command -v nix &> /dev/null; then
  echo "---------- Installing Nix ----------"
  sh <(curl -L https://nixos.org/nix/install) --daemon
fi

# Install Docker
if ! command -v docker &> /dev/null; then
  sudo apt update
  sudo apt install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt update

  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo groupadd docker
  sudo usermod -aG docker $USER
fi 

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
  echo "---------- Installing GitHub CLI ----------"
  (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	  && sudo mkdir -p -m 755 /etc/apt/keyrings \
	  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	  && sudo apt update \
	  && sudo apt install gh -y
  gh auth login
fi

# Install ghostty
if ! command -v ghostty &> /dev/null; then
  echo "---------- Installing Ghostty ----------"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
  ln -s $SCRIPT_DIR/ghostty/config.ghostty ~/.config/ghostty/config.ghostty

  echo "---------- Setting Ghostty as default terminal ----------"
  sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/ghostty 50
  sudo update-alternatives --config x-terminal-emulator
fi

# Update symlinks, shortcuts, wallpaper
sudo mkdir -p /opt/bin/
sudo ln -s ~/.nix-profile/bin/zsh /opt/bin/zsh

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# TO UPDATE SHORTCUTS:
# rm gnome_shortcuts.ini
# dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > gnome_shortcuts.ini
# dconf dump /org/gnome/desktop/wm/keybindings/ >> gnome_shortcuts.ini

# Import custom shortcuts
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < $SCRIPT_DIR/ubuntu/gnome_shortcuts.ini

# Import window management shortcuts
dconf load /org/gnome/desktop/wm/keybindings/ < $SCRIPT_DIR/ubuntu/gnome_shortcuts.ini

(rm ~/Pictures/wallpaper.png) || true 
ln -s $SCRIPT_DIR/../assets/wallpaper.png ~/Pictures/wallpaper.png
