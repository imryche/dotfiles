#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure gum is available
if ! command -v gum &>/dev/null; then
    echo "Installing gum..."
    sudo dnf install -y gum
fi

# System update
update_system() {
    gum style --foreground 212 "Updating system..."
    sudo dnf upgrade -y --refresh
    gum style --foreground 42 "✓ System updated"
}

# Fonts
install_fonts() {
    gum style --foreground 212 "Installing fonts..."
    sudo dnf install -y jetbrains-mono-fonts cascadia-mono-fonts rsms-inter-fonts
    gum style --foreground 42 "✓ Fonts installed"
}

configure_fonts() {
    gsettings set org.gnome.desktop.interface font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface document-font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Bold 10'
    gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'
    gsettings set org.gnome.desktop.interface font-hinting 'slight'
    gum style --foreground 42 "✓ System fonts configured"
}

configure_gnome() {
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
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
    gum style --foreground 42 "✓ GNOME configured"
}

install_gnome_extension() {
    local ext="$1"
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$ext"

    if [[ -d "$ext_dir" ]]; then
        gum style --foreground 214 "$ext already installed, skipping"
        return
    fi

    gdbus call --session \
        --dest org.gnome.Shell.Extensions \
        --object-path /org/gnome/Shell/Extensions \
        --method org.gnome.Shell.Extensions.InstallRemoteExtension \
        "$ext" >/dev/null 2>&1 || true
    gum style --foreground 39 "✓ $ext installed"

    local schema_dir="$ext_dir/schemas"
    if [[ -d "$schema_dir" ]]; then
        glib-compile-schemas "$schema_dir"
        sudo cp "$schema_dir"/*.gschema.xml /usr/share/glib-2.0/schemas/
        sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
    fi
}

install_gnome_extensions() {
    gum style --foreground 212 "Installing GNOME extensions..."
    flatpak install -y flathub com.mattjakeman.ExtensionManager

    install_gnome_extension just-perfection-desktop@just-perfection
    install_gnome_extension tactile@lundal.io
    install_gnome_extension disable-workspace-animation@ethnarque
    gum style --foreground 42 "✓ GNOME extensions installed"
}

configure_gnome_extensions() {
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
    gum style --foreground 42 "✓ GNOME extensions configured"
}

# Gradia screen annotation tool
install_gradia() {
    gum style --foreground 212 "Installing Gradia..."
    flatpak install -y flathub be.alexandervanhee.gradia
    gum style --foreground 42 "✓ Gradia installed"
}

configure_gradia() {
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gradia/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "Gradia Screenshot"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "<Super><Shift>s"
    gum style --foreground 42 "✓ Gradia configured"
}

# Chromium browser
install_chromium() {
    if command -v chromium-browser &>/dev/null; then
        gum style --foreground 214 "Chromium already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing Chromium..."
    sudo dnf install -y chromium
    gum style --foreground 42 "✓ Chromium installed"
}

configure_chromium() {
    local target="$HOME/.local/share/applications/chromium-browser.desktop"
    mkdir -p "$HOME/.local/share/applications"
    sed 's|Exec=\(.*chromium-browser\)|Exec=\1 --enable-features=TouchpadOverscrollHistoryNavigation|' \
        /usr/share/applications/chromium-browser.desktop > "$target"
    gum style --foreground 42 "✓ Chromium configured"
}

chromium_profile_name() {
    local chromium_dir="$HOME/.config/chromium"
    local dir_name="$1"
    jq -r --arg dir "$dir_name" '.profile.info_cache[$dir].name // $dir' "$chromium_dir/Local State"
}

chromium_choose_profile() {
    local header="$1"
    local chromium_dir="$HOME/.config/chromium"
    declare -A profile_map

    for dir in "$chromium_dir"/*/; do
        if [[ -f "$dir/Bookmarks" || -f "$dir/History" ]]; then
            local dir_name
            dir_name=$(basename "$dir")
            local display_name
            display_name=$(chromium_profile_name "$dir_name")
            profile_map["$display_name"]="$dir_name"
        fi
    done

    if [[ ${#profile_map[@]} -eq 0 ]]; then
        gum style --foreground 196 "No Chromium profiles found" >&2
        return 1
    fi

    local selection
    selection=$(printf '%s\n' "${!profile_map[@]}" | gum choose --header "$header")
    [[ -z "$selection" ]] && return 1

    echo "${profile_map[$selection]}"
}

backup_chromium() {
    local chromium_dir="$HOME/.config/chromium"

    local profile_dir_name
    profile_dir_name=$(chromium_choose_profile "Select Chromium profile:")
    [[ -z "$profile_dir_name" ]] && return 1

    local profile_dir="$chromium_dir/$profile_dir_name"
    local profile_name
    profile_name=$(chromium_profile_name "$profile_dir_name")
    local default_path="$DOTFILES_DIR/backups/chromium-$profile_name-$(date +%Y%m%d-%H%M%S).tar.gz"
    local archive
    archive=$(gum input --placeholder "$default_path" --header "Save backup to:" --value "$default_path")
    [[ -z "$archive" ]] && return 1

    mkdir -p "$(dirname "$archive")"

    local files=()
    [[ -f "$profile_dir/Bookmarks" ]] && files+=("Bookmarks")
    [[ -f "$profile_dir/History" ]] && files+=("History")
    [[ -f "$profile_dir/Favicons" ]] && files+=("Favicons")

    tar -czf "$archive" -C "$profile_dir" "${files[@]}"
    gum style --foreground 42 "✓ Chromium backup created: $archive"
}

restore_chromium() {
    local backup_dir="$DOTFILES_DIR/backups"
    local chromium_dir="$HOME/.config/chromium"

    if pgrep -x chromium &>/dev/null; then
        gum style --foreground 196 "Please close Chromium before restoring"
        return 1
    fi

    # Pick backup
    local backup
    backup=$(gum file "$backup_dir")
    [[ -z "$backup" || ! -f "$backup" ]] && return 1

    # Pick target profile
    local profile
    profile=$(chromium_choose_profile "Restore to profile:")
    [[ -z "$profile" ]] && return 1

    local profile_name
    profile_name=$(chromium_profile_name "$profile")

    # Confirm
    gum confirm "Restore $(basename "$backup") to $profile_name?" || return 1

    # Extract
    tar -xzf "$backup" -C "$chromium_dir/$profile"
    gum style --foreground 42 "✓ Restored $(basename "$backup") to $profile_name"
}

# Ghostty terminal
install_ghostty() {
    if command -v ghostty &>/dev/null; then
        gum style --foreground 214 "Ghostty already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing Ghostty..."
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf install -y ghostty
    gum style --foreground 42 "✓ Ghostty installed"
}

configure_ghostty() {
    stow -d "$DOTFILES_DIR" -t "$HOME" ghostty
    gum style --foreground 42 "✓ Ghostty configured"
}

# CLI tools (zoxide, ripgrep, fzf, gh)
install_cli_tools() {
    gum style --foreground 212 "Installing CLI tools..."
    sudo dnf install -y zoxide ripgrep fzf gh
    gum style --foreground 42 "✓ CLI tools installed"
}

# Helix text editor
install_helix() {
    if command -v hx &>/dev/null; then
        gum style --foreground 214 "Helix already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing Helix..."
    sudo dnf install -y helix
    gum style --foreground 42 "✓ Helix installed"
}

configure_helix() {
    stow -d "$DOTFILES_DIR" -t "$HOME" helix
    gum style --foreground 42 "✓ Helix configured"
}

# Git
configure_git() {
    if [[ -e "$HOME/.gitconfig" ]]; then
        gum style --foreground 214 "Git already configured, skipping"
        return
    fi

    stow -d "$DOTFILES_DIR" -t "$HOME" gitconfig
    gum style --foreground 42 "✓ Git configured"
}

# Tailscale VPN
install_tailscale() {
    if command -v tailscale &>/dev/null; then
        gum style --foreground 214 "Tailscale already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing Tailscale..."
    sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    sudo dnf install -y tailscale
    sudo systemctl enable --now tailscaled
    gum style --foreground 42 "✓ Tailscale installed (run 'sudo tailscale up' to authenticate)"
}

# mise runtime manager
install_mise() {
    if command -v mise &>/dev/null; then
        gum style --foreground 214 "mise already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing mise..."
    sudo dnf copr enable -y jdxcode/mise
    sudo dnf install -y mise
    gum style --foreground 42 "✓ mise installed"
}

configure_mise() {
    stow -d "$DOTFILES_DIR" -t "$HOME" mise
    mise install
    gum style --foreground 42 "✓ mise configured"
}

# Fish shell
install_fish() {
    if command -v fish &>/dev/null; then
        gum style --foreground 214 "Fish already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing Fish..."
    sudo dnf install -y fish
    gum style --foreground 42 "✓ Fish installed"
}

configure_fish() {
    stow -d "$DOTFILES_DIR" -t "$HOME" fish

    if [[ "$SHELL" == *"fish"* ]]; then
        gum style --foreground 42 "✓ Fish configured"
        return
    fi

    gum style --foreground 212 "Setting Fish as default shell..."
    sudo chsh -s "$(which fish)" "$USER"
    gum style --foreground 42 "✓ Fish configured (re-login to activate)"
}

# Disable NetworkManager-wait-online (faster boot)
disable_nm_wait() {
    if ! systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
        gum style --foreground 214 "NetworkManager-wait-online already disabled, skipping"
        return
    fi

    gum style --foreground 212 "Disabling NetworkManager-wait-online..."
    sudo systemctl disable NetworkManager-wait-online.service
    gum style --foreground 42 "✓ NetworkManager-wait-online disabled"
}

# Faster DNF downloads
configure_dnf() {
    if grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        gum style --foreground 214 "DNF already configured, skipping"
        return
    fi

    gum style --foreground 212 "Configuring DNF for faster downloads..."
    echo -e "max_parallel_downloads=10\nfastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    gum style --foreground 42 "✓ DNF configured"
}

# SQLite database
install_sqlite() {
    if command -v sqlite3 &>/dev/null; then
        gum style --foreground 214 "SQLite already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing SQLite..."
    sudo dnf install -y sqlite
    gum style --foreground 42 "✓ SQLite installed"
}

configure_sqlite() {
    stow -d "$DOTFILES_DIR" -t "$HOME" sqlite
    gum style --foreground 42 "✓ SQLite configured"
}

# uv package manager
install_uv() {
    if command -v uv &>/dev/null; then
        gum style --foreground 214 "uv already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    gum style --foreground 42 "✓ uv installed"
}

# Python versions via uv
install_python() {
    gum style --foreground 212 "Installing Python versions..."
    uv python install 3.11 3.12 3.13
    gum style --foreground 42 "✓ Python installed (3.11, 3.12, 3.13)"
}

# Flathub repository
configure_flathub() {
    if flatpak remotes | grep -q flathub; then
        gum style --foreground 214 "Flathub already configured, skipping"
        return
    fi

    gum style --foreground 212 "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    gum style --foreground 42 "✓ Flathub configured"
}

# RPM Fusion repositories (free + nonfree)
install_rpmfusion() {
    if dnf repolist | grep -q rpmfusion; then
        gum style --foreground 214 "RPM Fusion already enabled, skipping"
        return
    fi

    gum style --foreground 212 "Enabling RPM Fusion repositories..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf group upgrade -y core
    gum style --foreground 42 "✓ RPM Fusion enabled"
}

# Full multimedia support (FFmpeg, GStreamer, codecs)
install_multimedia() {
    gum style --foreground 212 "Installing multimedia packages..."
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    sudo dnf group install -y multimedia
    gum style --foreground 42 "✓ Multimedia packages installed"
}

# Intel hardware video acceleration (VA-API)
install_intel_vaapi() {
    gum style --foreground 212 "Installing Intel media driver..."
    sudo dnf install -y intel-media-driver libva-utils
    gum style --foreground 42 "✓ Intel VA-API driver installed"
}

# WWAN access point configuration
configure_wwan_apn() {
    gum style --foreground 212 "Configuring WWAN access point..."
    
    nmcli -t -f NAME,TYPE connection show | { grep ':gsm$' || true; } | cut -d: -f1 | while read -r conn; do
        gum style --foreground 214 "Removing GSM connection: $conn"
        nmcli connection delete "$conn" || true
    done
    
    nmcli connection add type gsm con-name "Orange Internet" \
        gsm.apn "internet" \
        gsm.username "internet" \
        gsm.password "internet" \
        gsm.home-only yes \
        connection.autoconnect no
    
    gum style --foreground 42 "✓ WWAN access point configured"
}

# WWAN unlock for Lenovo ThinkPad (Quectel RM520N-GL)
install_wwan_unlock() {
    if [[ -d /opt/fcc_lenovo ]]; then
        gum style --foreground 214 "WWAN unlock already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing Lenovo WWAN unlock..."
    local tmpdir=$(mktemp -d)
    git clone --depth 1 https://github.com/lenovo/lenovo-wwan-unlock "$tmpdir"
    sudo "$tmpdir/fcc_unlock_setup.sh"
    rm -rf "$tmpdir"
    gum style --foreground 42 "✓ WWAN unlock installed (reboot required)"
}

# WWAN dispatcher fix for MBIM over MHI
install_wwan_fix() {
    local target="/etc/NetworkManager/dispatcher.d/99-wwan-fix"
    
    if [[ -e "$target" ]]; then
        gum style --foreground 214 "WWAN fix already installed, skipping"
        return
    fi

    gum style --foreground 212 "Installing WWAN dispatcher fix..."
    sudo stow -d "$DOTFILES_DIR" -t / wwan
    sudo chmod +x "$target"
    gum style --foreground 42 "✓ WWAN fix installed"
}

main() {
    # System
    update_system
    configure_dnf
    disable_nm_wait
    configure_flathub
    install_rpmfusion

    # Multimedia
    install_multimedia
    install_intel_vaapi

    # Fonts
    install_fonts
    configure_fonts

    # GNOME
    configure_gnome
    install_gnome_extensions
    configure_gnome_extensions

    # Dev tools
    configure_git
    install_cli_tools
    install_mise
    configure_mise
    install_uv
    install_python
    install_sqlite
    configure_sqlite

    # Apps
    install_chromium
    configure_chromium
    install_ghostty
    configure_ghostty
    install_helix
    configure_helix
    install_gradia
    configure_gradia

    # Network
    install_tailscale
    install_wwan_unlock
    install_wwan_fix
    configure_wwan_apn

    # Shell (last, requires re-login)
    install_fish
    configure_fish

    echo ""
    gum style --foreground 42 "✓ Setup complete"
}

"${@:-main}"
