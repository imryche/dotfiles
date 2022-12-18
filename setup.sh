#!/bin/bash

function install_basics() {
	echo "[Installing basic system packages]"
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
	printf "\n"
}

function install_chrome() {
	echo "[Installing Chrome]"
	if command -v google-chrome-stable &>/dev/null; then
		echo "Skipping: $(which google-chrome-stable) is already installed"
	else
		package_path=~/Downloads/google-chrome.deb
		wget -O $package_path https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
		sudo dpkg -i $package_path
		rm $package_path
	fi
	printf "\n"
}

function remove_firefox() {
	echo "[Removing Firefox]"
	if command -v firefox; then
		sudo apt remove firefox
	else
		echo "Skipping: firefox is already removed"
	fi
	printf "\n"
}

function install_zsh() {
	echo "[Installing Zsh]"
	if command -v zsh &>/dev/null; then
		echo "Skipping: $(which zsh) is already installed"
	else
		sudo apt update
		sudo apt install zsh
		chsh -s $(which zsh)
	fi
	printf "\n"
}

function install_ohmyzsh() {
	echo "[Installing Oh My Zsh]"
	if [ ! -d ~/.oh-my-zsh ]; then
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		echo "Skipping: ~/.oh-my-zsh is already installed"
	fi
	printf "\n"
}

function install_wezterm() {
	echo "[Installing WezTerm]"
	sudo flatpak install flathub org.wezfurlong.wezterm
	printf "\n"
}

function install_telegram() {
	echo "[Installing Telegram]"
	sudo flatpak install flathub org.telegram.desktop
	printf "\n"
}

function install_spotify() {
	echo "[Installing Spotify]"
	sudo flatpak install flathub com.spotify.Client
	printf "\n"
}

function install_todoist() {
	echo "[Installing Todoist]"
	sudo flatpak install flathub com.todoist.Todoist
	printf "\n"
}

install_basics
remove_firefox
install_chrome
install_zsh
install_ohmyzsh
install_wezterm
install_telegram
install_spotify
install_todoist
