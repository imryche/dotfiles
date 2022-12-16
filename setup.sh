#!/bin/bash

echo "Removing Firefox..."
if command -v firefox; then
	sudo apt remove firefox
else
	echo "Skipping..."
fi

echo "Installing basic system packages..."
sudo apt update
sudo apt install \
	software-properties-common \
	build-essential \
	htop \
	git \
	fonts-jetbrains-mono \
	tmux \
	stow \
	gnome-tweaks \
	xclip

echo "Installing WezTerm..."
if flatpak list --app | grep -q org.wezfurlong.wezterm; then
	echo "Skipping..."
else
	flatpak install flathub org.wezfurlong.wezterm
fi

echo "Installing Spotify..."
if flatpak list --app | grep -q com.spotify.Client; then
	echo "Skipping..."
else
	flatpak install flathub com.spotify.Client
fi
