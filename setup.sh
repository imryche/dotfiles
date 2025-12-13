#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure gum is available
if ! command -v gum &>/dev/null; then
    echo "Installing gum..."
    sudo dnf install -y gum
fi

# Helper: install flatpak app
install_flatpak() {
    flatpak install -y flathub "$@"
}

# Helper: install dnf packages
install_dnf() {
    sudo dnf install -y "$@"
}

# Helper: stow dotfiles
stow_dotfiles() {
    local pkg="$1"
    if ! command -v stow &>/dev/null; then
        gum style --foreground 33 "Installing stow..."
        install_dnf stow
    fi
    if ! command -v git &>/dev/null; then
        gum style --foreground 33 "Installing git..."
        install_dnf git
    fi
    gum style --foreground 33 "Configuring $pkg..."
    stow -d "$DOTFILES_DIR" -t "$HOME" --adopt "$pkg"
    git -C "$DOTFILES_DIR" checkout -- "$pkg"
}

# System update
update_system() {
    gum style --foreground 33 "Updating system..."
    sudo dnf upgrade -y --refresh
}

# Faster DNF downloads
configure_dnf() {
    grep -q "max_parallel_downloads" /etc/dnf/dnf.conf && return
    gum style --foreground 33 "Configuring DNF for faster downloads..."
    echo -e "max_parallel_downloads=10\nfastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
}

# Disable NetworkManager-wait-online (faster boot)
disable_nm_wait() {
    gum style --foreground 33 "Disabling NetworkManager-wait-online..."
    sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
}

# Flathub repository
configure_flathub() {
    gum style --foreground 33 "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# RPM Fusion repositories (free + nonfree)
install_rpmfusion() {
    gum style --foreground 33 "Enabling RPM Fusion repositories..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf group upgrade -y core
}

# Full multimedia support (FFmpeg, GStreamer, codecs)
install_multimedia() {
    gum style --foreground 33 "Installing multimedia packages..."
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    sudo dnf group install -y multimedia
}

# Intel hardware video acceleration (VA-API)
install_intel_vaapi() {
    gum style --foreground 33 "Installing Intel media driver..."
    install_dnf intel-media-driver libva-utils
}

# Intel compute runtime (OpenCL, Level Zero)
install_intel_compute() {
    gum style --foreground 33 "Installing Intel compute runtime..."
    install_dnf intel-compute-runtime intel-level-zero intel-igc intel-ocloc
}

# Fonts
install_fonts() {
    gum style --foreground 33 "Installing fonts..."
    install_dnf jetbrains-mono-fonts cascadia-mono-fonts rsms-inter-fonts
}

configure_fonts() {
    gum style --foreground 33 "Configuring fonts..."
    gsettings set org.gnome.desktop.interface font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface document-font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Bold 10'
    gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'
    gsettings set org.gnome.desktop.interface font-hinting 'slight'
}

# GNOME
configure_gnome() {
    gum style --foreground 33 "Configuring GNOME..."
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
    gsettings set org.gnome.GWeather4 temperature-unit 'centigrade'
}

install_gnome_extension() {
    local ext="$1"
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$ext"

    [[ -d "$ext_dir" ]] && return

    gdbus call --session \
        --dest org.gnome.Shell.Extensions \
        --object-path /org/gnome/Shell/Extensions \
        --method org.gnome.Shell.Extensions.InstallRemoteExtension \
        "$ext" >/dev/null 2>&1 || true
}

install_gnome_extensions() {
    gum style --foreground 33 "Installing GNOME extensions..."
    install_gnome_extension just-perfection-desktop@just-perfection
    install_gnome_extension tactile@lundal.io
    install_gnome_extension disable-workspace-animation@ethnarque
}

configure_gnome_extensions() {
    gum style --foreground 33 "Configuring GNOME extensions..."
    dconf write /org/gnome/shell/extensions/just-perfection/animation 4
    dconf write /org/gnome/shell/extensions/just-perfection/workspace-popup false
    dconf write /org/gnome/shell/extensions/just-perfection/startup-status 0
    dconf write /org/gnome/shell/extensions/tactile/show-tiles "['<Super>Return']"
    dconf write /org/gnome/shell/extensions/tactile/grid-rows 2
    dconf write /org/gnome/shell/extensions/tactile/grid-cols 4
    dconf write /org/gnome/shell/extensions/tactile/row-0 0
    dconf write /org/gnome/shell/extensions/tactile/row-1 1
    dconf write /org/gnome/shell/extensions/tactile/col-0 1
    dconf write /org/gnome/shell/extensions/tactile/col-1 3
    dconf write /org/gnome/shell/extensions/tactile/col-2 3
    dconf write /org/gnome/shell/extensions/tactile/col-3 1
}

# Git
configure_git() { stow_dotfiles gitconfig; }

# CLI tools (zoxide, ripgrep, fzf, gh)
install_cli_tools() {
    gum style --foreground 33 "Installing CLI tools..."
    install_dnf zoxide ripgrep fd-find fzf gh htop btop nvtop stow jq
}

# mise runtime manager
install_mise() {
    command -v mise &>/dev/null && return
    gum style --foreground 33 "Installing mise..."
    sudo dnf copr enable -y jdxcode/mise
    install_dnf mise
}

configure_mise() {
    stow_dotfiles mise
    mise install
}

# direnv
install_direnv() {
    gum style --foreground 33 "Installing direnv..."
    install_dnf direnv
}

configure_direnv() { stow_dotfiles direnv; }

# uv package manager
install_uv() {
    export PATH="$HOME/.local/bin:$PATH"
    command -v uv &>/dev/null && return
    gum style --foreground 33 "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

# Ampcode CLI
install_ampcode() {
    command -v amp &>/dev/null && return
    gum style --foreground 33 "Installing Ampcode..."
    curl -fsSL https://ampcode.com/install.sh | bash
}

# Python versions via uv
install_python() {
    gum style --foreground 33 "Installing Python versions..."
    uv python install 3.11 3.12 3.13
}

# Dev tools via uv
install_dev_tools() {
    gum style --foreground 33 "Installing dev tools..."
    uv tool install ruff
    uv tool install ty
    uv tool install taplo
}

# SQLite database
install_sqlite() {
    gum style --foreground 33 "Installing SQLite..."
    install_dnf sqlite
}

configure_sqlite() { stow_dotfiles sqlite; }

# Chromium browser
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

install_chromium() {
    gum style --foreground 33 "Installing Chromium..."
    install_dnf chromium
}

configure_chromium() {
    gum style --foreground 33 "Configuring Chromium..."
    local target="$HOME/.local/share/applications/chromium-browser.desktop"
    mkdir -p "$HOME/.local/share/applications"
    sed 's|Exec=\(.*chromium-browser\)|Exec=\1 --enable-features=TouchpadOverscrollHistoryNavigation|' \
        /usr/share/applications/chromium-browser.desktop >"$target"
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
    gum style --foreground 28 "✓ Chromium backup created: $archive"
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
    gum style --foreground 28 "✓ Restored $(basename "$backup") to $profile_name"
}

# Bitwarden password manager
install_bitwarden() {
    gum style --foreground 33 "Installing Bitwarden..."
    install_flatpak com.bitwarden.desktop
}

# Eyedropper color picker
install_eyedropper() {
    gum style --foreground 33 "Installing Eyedropper..."
    install_flatpak com.github.finefindus.eyedropper
}

# Extension Manager
install_extension_manager() {
    gum style --foreground 33 "Installing Extension Manager..."
    install_flatpak com.mattjakeman.ExtensionManager
}

# GNOME Tweaks
install_gnome_tweaks() {
    gum style --foreground 33 "Installing GNOME Tweaks..."
    install_dnf gnome-tweaks
}

# Gear Lever (AppImage manager)
install_gear_lever() {
    gum style --foreground 33 "Installing Gear Lever..."
    install_flatpak it.mijorus.gearlever
}

# Spotify
install_spotify() {
    gum style --foreground 33 "Installing Spotify..."
    install_flatpak com.spotify.Client
}

# LocalSend
install_localsend() {
    gum style --foreground 33 "Installing LocalSend..."
    install_flatpak org.localsend.localsend_app
}

# Ghostty terminal
install_ghostty() {
    command -v ghostty &>/dev/null && return
    gum style --foreground 33 "Installing Ghostty..."
    sudo dnf copr enable -y scottames/ghostty
    install_dnf ghostty
}

configure_ghostty() { stow_dotfiles ghostty; }

# Helix text editor
install_helix() {
    gum style --foreground 33 "Installing Helix..."
    install_dnf helix
}

configure_helix() { stow_dotfiles helix; }

# Gradia screen annotation tool
install_gradia() {
    gum style --foreground 33 "Installing Gradia..."
    install_flatpak be.alexandervanhee.gradia
}

configure_gradia() {
    gum style --foreground 33 "Configuring Gradia..."
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gradia/"
    local key="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

    dconf write "${path}name" "'Gradia Screenshot'"
    dconf write "${path}command" "'flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE'"
    dconf write "${path}binding" "'<Super><Shift>s'"

    local current
    current=$(dconf read "$key" 2>/dev/null || echo "@as []")
    if [[ -z "$current" || "$current" == "@as []" ]]; then
        dconf write "$key" "['$path']"
    elif [[ "$current" != *"$path"* ]]; then
        dconf write "$key" "${current%]},'$path']"
    fi
}

# Tailscale VPN
install_tailscale() {
    gum style --foreground 33 "Installing Tailscale..."
    sudo dnf config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    install_dnf tailscale
    sudo systemctl enable --now tailscaled
}

# WWAN unlock for Lenovo ThinkPad (Quectel RM520N-GL)
install_wwan_unlock() {
    [[ -d /opt/fcc_lenovo ]] && return
    gum style --foreground 33 "Installing Lenovo WWAN unlock..."
    local tmpdir=$(mktemp -d)
    git clone --depth 1 https://github.com/lenovo/lenovo-wwan-unlock "$tmpdir"
    sudo "$tmpdir/fcc_unlock_setup.sh"
    rm -rf "$tmpdir"
}

# WWAN dispatcher fix for MBIM over MHI
install_wwan_fix() {
    local target="/etc/NetworkManager/dispatcher.d/99-wwan-fix"
    [[ -e "$target" ]] && return
    gum style --foreground 33 "Installing WWAN dispatcher fix..."
    sudo stow -d "$DOTFILES_DIR" -t / wwan
    sudo chmod +x "$target"
}

# WWAN access point configuration
configure_wwan_apn() {
    nmcli -t -f NAME connection show | grep -q "^Orange Internet$" && return
    gum style --foreground 33 "Configuring WWAN access point..."
    nmcli -t -f NAME,TYPE connection show | { grep ':gsm$' || true; } | cut -d: -f1 | while read -r conn; do
        nmcli connection delete "$conn" || true
    done
    nmcli connection add type gsm con-name "Orange Internet" \
        gsm.apn "internet" \
        gsm.username "internet" \
        gsm.password "internet" \
        gsm.home-only yes \
        connection.autoconnect no
}

# Fish shell
install_fish() {
    gum style --foreground 33 "Installing Fish..."
    install_dnf fish
}

configure_fish() {
    stow_dotfiles fish
    [[ "$SHELL" == *"fish"* ]] && return
    gum style --foreground 33 "Setting Fish as default shell..."
    chsh -s "$(command -v fish)" "$USER"
}

# Remove PyCharm COPR repo
remove_pycharm_repo() {
    if ! dnf repolist --all | grep -q "phracek:PyCharm"; then
        return 0
    fi
    gum style --foreground 33 "Removing PyCharm COPR repo..."
    sudo dnf copr remove -y phracek/PyCharm
}

# Disable fingerprint for sudo
disable_sudo_fingerprint() {
    grep -q "pam_unix.so" /etc/pam.d/sudo && return
    gum style --foreground 33 "Disabling fingerprint for sudo..."
    sudo sed -i.bak 's/^auth\s*include\s*system-auth/auth       required     pam_unix.so/' /etc/pam.d/sudo
}

# Project directories
create_project_dirs() {
    gum style --foreground 33 "Creating project directories..."
    mkdir -p "$HOME/proj" "$HOME/fun"
}

main() {
    # Cleanup
    remove_pycharm_repo

    # System
    update_system
    configure_dnf
    disable_nm_wait
    disable_sudo_fingerprint
    configure_flathub
    install_rpmfusion

    # Multimedia
    install_multimedia
    install_intel_vaapi
    install_intel_compute

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
    install_direnv
    configure_direnv
    install_uv
    install_ampcode
    install_python
    install_dev_tools
    install_sqlite
    configure_sqlite

    # Apps
    install_chromium
    configure_chromium
    install_ghostty
    configure_ghostty
    install_helix
    configure_helix
    install_bitwarden
    install_gradia
    configure_gradia
    install_eyedropper
    install_extension_manager
    install_gnome_tweaks
    install_gear_lever
    install_spotify
    install_localsend

    # Network
    install_tailscale
    install_wwan_unlock
    install_wwan_fix
    configure_wwan_apn

    # Shell (last, requires re-login)
    install_fish
    configure_fish

    # Directories
    create_project_dirs

    echo ""
    gum style --foreground 28 --bold "Setup complete!"
    echo ""
    gum style --faint "Restart for all changes to take effect."
    echo ""
    if gum confirm "Restart now?" --default=false; then
        systemctl reboot
    fi
}

cmd="${1:-main}"
if declare -F "$cmd" >/dev/null; then
    "$cmd"
else
    echo "Unknown command: $cmd" >&2
    exit 1
fi
