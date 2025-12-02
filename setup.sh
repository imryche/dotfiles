#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fonts
install_fonts() {
    echo "Installing fonts..."
    sudo dnf install -y jetbrains-mono-fonts cascadia-mono-fonts rsms-inter-fonts
    echo "Fonts installed"
}

configure_fonts() {
    echo "Configuring system fonts..."
    gsettings set org.gnome.desktop.interface font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface document-font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Bold 10'
    gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'
    gsettings set org.gnome.desktop.interface font-hinting 'slight'
    echo "System fonts configured"
}

configure_gnome() {
    echo "Configuring GNOME..."
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:'
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Alt>1']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Alt>2']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Alt>3']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Alt>4']"
    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
    gsettings set org.gnome.desktop.interface scaling-factor 2
    gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 20
    gsettings set org.gnome.desktop.peripherals.keyboard delay 200
    gsettings set org.gnome.desktop.interface enable-hot-corners false
    echo "GNOME configured"
}

install_gnome_extensions() {
    echo "Installing GNOME extensions..."
    flatpak install -y flathub com.mattjakeman.ExtensionManager
    uv tool install gnome-extensions-cli

    # Install extensions (gext install is idempotent)
    gext install just-perfection-desktop@just-perfection
    gext install tactile@lundal.io

    # Compile local schemas
    glib-compile-schemas ~/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas/
    glib-compile-schemas ~/.local/share/gnome-shell/extensions/tactile@lundal.io/schemas/

    # Copy schemas to system and compile
    sudo cp ~/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas/org.gnome.shell.extensions.just-perfection.gschema.xml /usr/share/glib-2.0/schemas/
    sudo cp ~/.local/share/gnome-shell/extensions/tactile@lundal.io/schemas/org.gnome.shell.extensions.tactile.gschema.xml /usr/share/glib-2.0/schemas/
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

    # Configure Just Perfection
    gsettings set org.gnome.shell.extensions.just-perfection animation 4
    gsettings set org.gnome.shell.extensions.just-perfection workspace-popup false

    # Configure Tactile
    gsettings set org.gnome.shell.extensions.tactile show-tiles "['<Super>Return']"
    gsettings set org.gnome.shell.extensions.tactile grid-rows 2
    gsettings set org.gnome.shell.extensions.tactile grid-cols 4
    gsettings set org.gnome.shell.extensions.tactile row-0 0
    gsettings set org.gnome.shell.extensions.tactile row-1 1
    gsettings set org.gnome.shell.extensions.tactile col-0 1
    gsettings set org.gnome.shell.extensions.tactile col-1 3
    gsettings set org.gnome.shell.extensions.tactile col-2 3
    gsettings set org.gnome.shell.extensions.tactile col-3 1

    echo "GNOME extensions installed and configured"
}

# Gradia screen annotation tool
install_gradia() {
    echo "Installing Gradia..."
    flatpak install -y flathub be.alexandervanhee.gradia
    echo "Gradia installed"
}

configure_gradia_shortcut() {
    echo "Configuring Gradia keyboard shortcut..."
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gradia/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "Gradia Screenshot"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "<Super><Shift>s"
    echo "Gradia shortcut configured"
}

# Chromium browser
install_chromium() {
    if command -v chromium-browser &>/dev/null; then
        echo "Chromium already installed, skipping"
        return
    fi

    echo "Installing Chromium..."
    sudo dnf install -y chromium
    echo "Chromium installed"
}

configure_chromium() {
    local target="$HOME/.local/share/applications/chromium-browser.desktop"

    if [[ -f "$target" ]]; then
        echo "Chromium already configured, skipping"
        return
    fi

    echo "Configuring Chromium touchpad gestures..."
    mkdir -p "$HOME/.local/share/applications"
    sed 's|Exec=\(.*chromium-browser\)|Exec=\1 --enable-features=TouchpadOverscrollHistoryNavigation|' \
        /usr/share/applications/chromium-browser.desktop > "$target"
    echo "Chromium configured"
}

# Ghostty terminal
install_ghostty() {
    if ! command -v ghostty &>/dev/null; then
        echo "Installing Ghostty..."
        sudo dnf copr enable -y scottames/ghostty
        sudo dnf install -y ghostty
        echo "Ghostty installed"
    fi

    stow -d "$DOTFILES_DIR" -t "$HOME" ghostty
}

# CLI tools (zoxide, ripgrep, fzf)
install_cli_tools() {
    echo "Installing CLI tools..."
    sudo dnf install -y zoxide ripgrep fzf
    echo "CLI tools installed"
}

# Helix text editor
install_helix() {
    if command -v hx &>/dev/null; then
        echo "Helix already installed, skipping"
        return
    fi

    echo "Installing Helix..."
    sudo dnf install -y helix
    stow -d "$DOTFILES_DIR" -t "$HOME" helix
    echo "Helix installed"
}

# Git
configure_git() {
    if [[ -e "$HOME/.gitconfig" ]]; then
        echo "Git already configured, skipping"
        return
    fi

    echo "Configuring git..."
    stow -d "$DOTFILES_DIR" -t "$HOME" gitconfig
    echo "Git configured"
}

# Tailscale VPN
install_tailscale() {
    if command -v tailscale &>/dev/null; then
        echo "Tailscale already installed, skipping"
        return
    fi

    echo "Installing Tailscale..."
    sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    sudo dnf install -y tailscale
    sudo systemctl enable --now tailscaled
    echo "Tailscale installed (run 'sudo tailscale up' to authenticate)"
}

# mise runtime manager
install_mise() {
    if command -v mise &>/dev/null; then
        echo "mise already installed, skipping"
        return
    fi

    echo "Installing mise..."
    sudo dnf copr enable -y jdxcode/mise
    sudo dnf install -y mise
    stow -d "$DOTFILES_DIR" -t "$HOME" mise
    mise install
    echo "mise installed"
}

# Fish shell
install_fish() {
    if [[ "$SHELL" == *"fish"* ]]; then
        echo "Fish already default shell, skipping"
        return
    fi

    echo "Installing fish shell..."
    sudo dnf install -y fish
    stow -d "$DOTFILES_DIR" -t "$HOME" fish
    echo "Setting fish as default shell..."
    sudo chsh -s "$(which fish)" "$USER"
    echo "Fish installed (re-login to activate)"
}

# Disable NetworkManager-wait-online (faster boot)
disable_nm_wait() {
    if ! systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
        echo "NetworkManager-wait-online already disabled, skipping"
        return
    fi

    echo "Disabling NetworkManager-wait-online..."
    sudo systemctl disable NetworkManager-wait-online.service
    echo "NetworkManager-wait-online disabled"
}

# Faster DNF downloads
configure_dnf() {
    if grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "DNF already configured, skipping"
        return
    fi

    echo "Configuring DNF for faster downloads..."
    echo -e "max_parallel_downloads=10\nfastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "DNF configured"
}

# uv package manager
install_uv() {
    if command -v uv &>/dev/null; then
        echo "uv already installed, skipping"
        return
    fi

    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed"
}

# Python versions via uv
install_python() {
    echo "Installing Python versions..."
    uv python install 3.11 3.12 3.13
    echo "Python installed (3.11, 3.12, 3.13)"
}

# Flathub repository
configure_flathub() {
    if flatpak remotes | grep -q flathub; then
        echo "Flathub already configured, skipping"
        return
    fi

    echo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flathub configured"
}

# RPM Fusion repositories (free + nonfree)
install_rpmfusion() {
    if dnf repolist | grep -q rpmfusion; then
        echo "RPM Fusion already enabled, skipping"
        return
    fi

    echo "Enabling RPM Fusion repositories..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf group upgrade -y core
    echo "RPM Fusion enabled"
}

# Full multimedia support (FFmpeg, GStreamer, codecs)
install_multimedia() {
    echo "Installing multimedia packages..."
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    sudo dnf group install -y multimedia
    echo "Multimedia packages installed"
}

# Intel hardware video acceleration (VA-API)
install_intel_vaapi() {
    echo "Installing Intel media driver..."
    sudo dnf install -y intel-media-driver libva-utils
    echo "Intel VA-API driver installed"
}

# WWAN access point configuration
configure_wwan_apn() {
    echo "Configuring WWAN access point..."
    
    # Remove all existing GSM connections
    nmcli -t -f NAME,TYPE connection show | { grep ':gsm$' || true; } | cut -d: -f1 | while read -r conn; do
        echo "Removing GSM connection: $conn"
        nmcli connection delete "$conn" || true
    done
    
    # Create Orange Internet connection
    nmcli connection add type gsm con-name "Orange Internet" \
        gsm.apn "internet" \
        gsm.username "internet" \
        gsm.password "internet" \
        gsm.home-only yes \
        connection.autoconnect no
    
    echo "WWAN access point configured"
}

# WWAN unlock for Lenovo ThinkPad (Quectel RM520N-GL)
install_wwan_unlock() {
    if [[ -d /opt/fcc_lenovo ]]; then
        echo "WWAN unlock already installed, skipping"
        return
    fi

    echo "Installing Lenovo WWAN unlock..."
    local tmpdir=$(mktemp -d)
    git clone --depth 1 https://github.com/lenovo/lenovo-wwan-unlock "$tmpdir"
    sudo "$tmpdir/fcc_unlock_setup.sh"
    rm -rf "$tmpdir"
    echo "WWAN unlock installed (reboot required)"
}

# WWAN dispatcher fix for MBIM over MHI
install_wwan_fix() {
    local target="/etc/NetworkManager/dispatcher.d/99-wwan-fix"
    
    if [[ -e "$target" ]]; then
        echo "WWAN fix already installed, skipping"
        return
    fi

    echo "Installing WWAN dispatcher fix..."
    sudo stow -d "$DOTFILES_DIR" -t / wwan
    sudo chmod +x "$target"
    echo "WWAN fix installed"
}

main() {
    disable_nm_wait
    configure_dnf
    configure_flathub
    install_rpmfusion
    install_multimedia
    install_intel_vaapi
    install_fonts
    configure_fonts
    configure_gnome
    install_uv
    install_python
    install_gnome_extensions
    install_gradia
    configure_gradia_shortcut
    install_chromium
    configure_chromium
    install_wwan_unlock
    install_wwan_fix
    configure_wwan_apn
    install_ghostty
    install_cli_tools
    install_helix
    configure_git
    install_tailscale
    install_mise
    install_fish
    echo ""
    echo "Done. Reboot to activate WWAN."
}

"${@:-main}"
