#!/bin/bash

function installed() {
	command -v $1 &>/dev/null
}

function skipping() {
	echo "Skipping: $(which $1) is already installed"
}

function install_basics() {
	echo "[Installing basic system packages]"
	sudo apt update
	sudo apt install -y \
		software-properties-common \
		build-essential \
		gcc \
		g++ \
		make \
		htop \
		tmux \
		git \
		fonts-jetbrains-mono \
		tmux \
		fzf \
		stow \
		gnome-tweaks \
		xclip
	printf "\n"
}

function install_zsh() {
	echo "[Installing Zsh]"
	if ! installed zsh; then
		sudo apt update && sudo apt install -y zsh
		chsh -s $(which zsh)
		echo "Shell was changed to zsh. Please logout and login to see changes"
		exit
	else
		skipping zsh
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

function apply_dotfiles() {
	echo "[Applying dotfiles]"
	if [ ! -d ~/dotfiles ]; then
		git clone https://github.com/imryche/dotfiles
	else
		git pull
	fi
	rm ~/.zshrc
	(
		cd ~/dotfiles
		stow wezterm zsh tmux nvim sqlite touchegg --verbose=2
	)
	source ~/.zshrc
	printf "\n"
}


function install_tpm() {
	echo "[Installing tpm]"
	if [ ! -d ~/.tmux/plugins/tpm ]; then
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	else
		echo "Skipping: ~/.tmux/plugins/tpm is already installed"
	fi
	printf "\n"
}

function install_python() {
	echo "[Installing Python]"
	if ! grep -q "^deb .*deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
		sudo add-apt-repository ppa:deadsnakes/ppa
	fi
	sudo apt update && sudo apt install -y \
		python3-pip \
		python3-dev \
		python3-venv \
		python-is-python3 \
		python3.11 \
		python3.11-dev \
		python3.11-venv
	printf "\n"
}

function install_pyright() {
	echo "[Installing pyright]"
	if ! installed pyright; then
		sudo pip install pyright
	else
		skipping pyright
	fi
	printf "\n"
}

function install_black() {
	echo "[Installing black]"
	if ! installed black; then
		pip install black
	else
		skipping black
	fi
	printf "\n"
}

function install_isort() {
	echo "[Installing isort]"
	if ! installed isort; then
		pip install isort
	else
		skipping isort
	fi
	printf "\n"
}

function install_go() {
	echo "[Installing Go]"
	if ! installed go; then
		(
			cd ~
			wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
			sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz
			rm go1.19.4.linux-amd64.tar.gz
		)
	else
		skipping go
	fi
	printf "\n"
}

function install_gopls() {
	echo "[Installing gopls]"
	if ! installed gopls; then
		go install golang.org/x/tools/gopls@latest
	else
		skipping gopls
	fi
	printf "\n"
}

function install_nodejs() {
	echo "[Installing NodeJS]"
	if ! installed node; then
		(
			curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
			sudo bash nodesource_setup.sh
			sudo apt install -y nodejs
			rm nodesource_setup.sh
		)
	else
		skipping node
	fi
	printf "\n"
}

function install_deno() {
	echo "[Installing Deno]"
	if ! installed deno; then
		curl -fsSL https://deno.land/x/install/install.sh | sh
	else
		skipping deno
	fi
	printf "\n"
}

function install_rust() {
	echo "[Installing Rust]"
	if ! installed rustc; then
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	else
		skipping rustc
	fi
	printf "\n"
}

function install_stylua() {
	echo "[Installing stylua]"
	if ! installed stylua; then
		cargo install stylua
	else
		skipping stylua
	fi
	printf "\n"
}

function install_lua_lsp() {
	echo "[Installing Lua LSP]"
	if ! installed lua-language-server; then
		mkdir -p ~/.config/lsp/lua-language-server
		(
			cd ~/.config/lsp/lua-language-server
			wget https://github.com/sumneko/lua-language-server/releases/download/3.6.4/lua-language-server-3.6.4-linux-x64.tar.gz
			tar -xvf lua-language-server-3.6.4-linux-x64.tar.gz
			rm lua-language-server-3.6.4-linux-x64.tar.gz
		)
	else
		skipping lua-language-server
	fi
	printf "\n"

}

function install_docker() {
	echo "[Installing Docker]"
	if ! installed docker; then
		sudo apt update && sudo apt install -y \
			ca-certificates \
			curl \
			gnupg \
			lsb-release
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

		echo "------------------------------------------------------------------"
		sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
		sudo groupadd docker
		sudo usermod -aG docker $USER
	else
		skipping docker
	fi
	printf "\n"
}

function install_chrome() {
	echo "[Installing Chrome]"
	if ! installed google-chrome-stable; then
		(
			cd ~
			wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
			sudo dpkg -i google-chrome-stable_current_amd64.deb
			rm google-chrome-stable_current_amd64.deb
		)
	else
		skipping google-chrome-stable
	fi
	printf "\n"
}

function remove_firefox() {
	echo "[Removing Firefox]"
	if installed firefox; then
		sudo apt remove firefox
	else
		echo "Skipping: firefox is already removed"
	fi
	printf "\n"
}

function install_1password() {
	echo "[Installing 1password]"
	if ! installed 1password; then
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
		echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
		sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
		curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
		sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
		sudo apt update && sudo apt install -y 1password
	else
		skipping 1password
	fi
	printf "\n"
}

function add_flatpak_remote() {
	echo "[Adding flathub as flatpak remote]"
	sudo flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	printf "\n"
}

function install_wezterm() {
	echo "[Installing WezTerm]"
	sudo flatpak install -y flathub org.wezfurlong.wezterm
	printf "\n"
}

function install_telegram() {
	echo "[Installing Telegram]"
	sudo flatpak install -y flathub org.telegram.desktop
	printf "\n"
}

function install_spotify() {
	echo "[Installing Spotify]"
	sudo flatpak install -y flathub com.spotify.Client
	printf "\n"
}

function install_todoist() {
	echo "[Installing Todoist]"
	sudo flatpak install -y flathub com.todoist.Todoist
	printf "\n"
}

function install_obsidian() {
	echo "[Installing Obsidian]"
	sudo flatpak install -y flathub md.obsidian.Obsidian
	printf "\n"
}

function install_dejadup() {
	echo "[Installing DejaDup]"
	sudo flatpak install -y flathub org.gnome.DejaDup
	printf "\n"
}

install_basics
install_zsh
install_ohmyzsh
apply_dotfiles
install_tpm
install_python
install_pyright
install_black
install_isort
install_go
install_gopls
install_nodejs
install_deno
install_rust
install_stylua
install_lua_lsp
install_docker
install_chrome
remove_firefox
install_1password
add_flatpak_remote
install_wezterm
install_telegram
install_spotify
install_todoist
install_obsidian
install_dejadup
