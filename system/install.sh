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

# Install rust
echo "---------- Installing Rust ----------"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install nix
if ! command -v nix &> /dev/null; then
  echo "---------- Installing Nix ----------"
  sh <(curl -L https://nixos.org/nix/install) --daemon
fi

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "---------- Installing Docker ----------"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
	  tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update
fi 

# Install GitHub CLI and Zen
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
echo "---------- Installing Zen Browser ----------"
gh release download --repo zen-browser/desktop --pattern 'zen.linux-x86_64.tar.xz' --clobber \
  && sudo tar -xf zen.linux-x86_64.tar.xz -C /opt \
  && sudo ln -s /opt/zen/zen /usr/bin/zen
  && rm zen.linux-x86_64.tar.xz

# Install i3-wm and polybar -- use TOUCHPAD_NAME in case I get a different laptop
echo "---------- Installing window manager ----------"
TOUCHPAD_NAME=$(xinput | grep -i touchpad | awk -F'↳|id=' '{print $2}' | xargs)
sudo apt install -y \
  i3 \
  polybar \
  feh \
  arandr \
  autorandr \
  maim \
  xclip \
  xdotool \
  rofi \
  light-locker \
  lightdm \
  xautolock

echo "---------- Installing i3lock-color ----------"
sudo apt install -y \
  autoconf \
  pkg-config \
  libpam0g-dev \
  libcairo2-dev \
  libfontconfig1-dev \
  libxcb-composite0-dev \
  libev-dev \
  libx11-xcb-dev \
  libxcb-xkb-dev \
  libxcb-xinerama0-dev \
  libxcb-randr0-dev \
  libxcb-image0-dev \
  libxcb-util-dev \
  libxcb-xrm-dev \
  libxkbcommon-dev \
  libxkbcommon-x11-dev \
  libjpeg-dev \
  libgif-dev
git clone https://github.com/Raymo111/i3lock-color.git \
  && cd i3lock-color \
  && ./install-i3lock-color.sh \
  && cd ../ \
  && rm -rf i3lock-color

# Install alacritty, stylua, and zellij
echo "---------- Installing alacritty ----------"
cargo install alacritty

echo "---------- Installing stylua ----------"
cargo install stylua

# Copy configs to ~/.config
echo "---------- Copying configurations ----------"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

(mkdir -p ~/.config/i3 && rm ~/.config/i3/*) || true
ln -s $SCRIPT_DIR/i3/config ~/.config/i3/config
ln -s $SCRIPT_DIR/i3/lock.sh ~/.config/i3/lock.sh
sudo cp $SCRIPT_DIR/i3/lock-on-suspend.service /etc/systemd/system/lock-on-suspend.service
sudo systemctl enable /etc/systemd/system/lock-on-suspend.service

(mkdir -p ~/.config/polybar && rm ~/.config/polybar/*) || true
ln -s $SCRIPT_DIR/polybar/config.ini ~/.config/polybar/config.ini
ln -s $SCRIPT_DIR/polybar/launch.sh ~/.config/polybar/launch.sh

(mkdir -p ~/.config/alacritty && rm ~/.config/alacritty/*) || true
ln -s $SCRIPT_DIR/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
ln -s $SCRIPT_DIR/alacritty/catppuccin-mocha.toml ~/.config/alacritty/catppuccin-mocha.toml

(rm ~/Pictures/wallpaper.png) || true 
ln -s $SCRIPT_DIR/assets/wallpaper.png ~/Pictures/wallpaper.png

echo "---------- Setting alacritty as default terminal... ----------"
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/alacritty 50
update-alternatives --config x-terminal-emulator
