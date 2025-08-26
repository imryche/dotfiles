#!/bin/bash

set -e

echo "Setting up Fedora with Hyprland Desktop Environment"

echo "Updating system and installing basic packages..."
sudo dnf update -y
sudo dnf install -y git vim wget curl stow

echo "Cloning dotfiles repository..."
git clone https://github.com/imryche/dotfiles.git ~/dotfiles

echo "Installing Ghostty terminal..."
sudo dnf copr enable scottames/ghostty -y
sudo dnf install -y ghostty --refresh

echo "Installing Fish shell..."
sudo dnf install -y fish

echo "Adding Hyprland COPR repository..."
sudo dnf copr enable solopasha/hyprland -y
sudo dnf update --refresh

echo "Installing Hyprland and desktop components..."
sudo dnf install -y hyprland hyprpaper
sudo dnf install -y waybar
sudo dnf install -y mako

echo "Installing fonts..."
sudo dnf install -y mozilla-fira-sans-fonts jetbrains-mono-fonts

echo "Setting default system font..."
gsettings set org.gnome.desktop.interface font-name 'Fira Sans 11'

echo "Installing Firefox..."
sudo dnf install -y firefox

echo "Installing mise version manager..."
sudo dnf copr enable jdxcode/mise -y
sudo dnf install -y mise

echo "Installing additional tools..."
sudo dnf install -y neovim fzf zoxide

echo "Applying Hyprland configuration files with stow..."
cd ~/dotfiles
stow --override=.* hypr waybar mako ghostty wallpapers fontconfig gitconfig

echo "Applying shell and editor configurations with stow..."
stow --override=.* fish nvim

echo "Setting Fish as default shell..."
chsh -s $(which fish)

echo "Installation complete!"
echo "Please reboot."
