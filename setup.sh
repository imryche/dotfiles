#!/bin/bash

function install_basics() {
	echo "[Installing basic system packages]"
	sudo apt update
	sudo apt install \
		software-properties-common \
		build-essential \
		gcc \
		g++ \
		make \
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
		(
			cd ~
			wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
			sudo dpkg -i google-chrome-stable_current_amd64.deb
			rm google-chrome-stable_current_amd64.deb
		)
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

function install_go() {
	echo "[Installing Go]"
	if ! command -v go &>/dev/null; then
		(
			cd ~
			wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
			sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz
			rm go1.19.4.linux-amd64.tar.gz
		)
	else
		echo "Skipping: $(which go) is already installed"
	fi
	printf "\n"
}

function install_gopls() {
	echo "[Installing gopls]"
	if ! command -v gopls &>/dev/null; then
		go install golang.org/x/tools/gopls@latest
	else
		echo "Skipping: $(which gopls) is already installed"
	fi
	printf "\n"
}

function install_nodejs() {
	echo "[Installing NodeJS]"
	if ! command -v node &>/dev/null; then
		(
			curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
			sudo bash nodesource_setup.sh
			sudo apt install nodejs
			rm nodesource_setup.sh
		)
	else
		echo "Skipping: $(which node) is already installed"
	fi
	printf "\n"
}

function install_deno() {
	echo "[Installing Deno]"
	if ! command -v deno &>/dev/null; then
		curl -fsSL https://deno.land/x/install/install.sh | sh
	else
		echo "Skipping: $(which deno) is already installed"
	fi
	printf "\n"
}

function install_rust() {
	echo "[Installing Rust]"
	if ! command -v rustc &>/dev/null; then
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	else
		echo "Skipping: $(which rustc) is already installed"
	fi
	printf "\n"
}

function install_docker() {
	echo "[Installing Docker]"
	if ! command -v docker &>/dev/null; then
		sudo apt update && sudo apt install \
			ca-certificates \
			curl \
			gnupg \
			lsb-release
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

		echo "------------------------------------------------------------------"
		sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
		sudo groupadd docker
		sudo usermod -aG docker $USER
	else
		echo "Skipping: $(which docker) is already installed"
	fi
}

function install_1password() {
	echo "[Installing 1password]"
	if ! command -v 1password &>/dev/null; then
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
		echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
		sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
		curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
		sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
		sudo apt update && sudo apt install 1password
	else
		echo "Skipping: $(which 1password) is already installed"
	fi
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
# install_go
# install_gopls
# install_nodejs
# install_deno
# install_rust
# install_docker
# install_1password
# install_lua_lsp
# apply_dotfiles
# install_wezterm
# install_telegram
# install_spotify
# install_todoist
# install_obsidian
