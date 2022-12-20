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
		fzf \
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

function install_python() {
	echo "[Installing Python]"
	if ! grep -q "^deb .*deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
		sudo add-apt-repository ppa:deadsnakes/ppa
	fi
	sudo apt update && sudo apt install \
		python3-pip \
		python3-dev \
		python3-venv \
		python-is-python3 \
		python3.11 \
		python3.11-dev \
		python3.11-venv
	printf "\n"
}

function install_lua_lsp() {
	echo "[Installing Lua LSP]"
	lsp_path=~/.config/nvim/lua-language-server/bin/lua-language-server
	if [ ! -f $lsp_path ]; then
		sudo apt update && sudo apt install ninja-build
		(
			mkdir ~/.config/lsp
			cd ~/.config/lsp
			git clone https://github.com/sumneko/lua-language-server
			cd lua-language-server
			git submodule update --depth 1 --init --recursive

			cd 3rd/luamake
			./compile/install.sh
			cd ../..
			./3rd/luamake/luamake rebuild
		)
	else
		echo "Skipping: $lsp_path is already installed"
	fi
	printf "\n"

}

function apply_dotfiles() {
	echo "[Applying dotfiles]"
	if [ ! -d ~/dotfiles ]; then
		git clone https://github.com/imryche/dotfiles
	else
		git pull
	fi
	(
		cd ~/dotfiles
		stow wezterm zsh tmux nvim sqlite touchegg --verbose=2
	)
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

function install_obsidian() {
	echo "[Installing Obsidian]"
	sudo flatpak install flathub md.obsidian.Obsidian
	printf "\n"
}


# install_basics
# remove_firefox
# install_chrome
# install_zsh
# install_ohmyzsh
# install_python
# install_lua_lsp
apply_dotfiles
# install_wezterm
# install_telegram
# install_spotify
# install_todoist
# install_obsidian
