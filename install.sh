#!/bin/bash

set -e

# Add at the top after set -e
echo "🚀 Setting up custom Arch Linux environment..."
echo "This will install Hyprland and dependencies, then copy dotfiles."
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

echo "==> Updating system packages..."
sudo pacman -Syu --noconfirm


# Clone the dotfiles repo if not already present
REPO_DIR="$HOME/dot-hyprland"
if [ ! -d "$REPO_DIR" ]; then
  git clone https://github.com/Sunilpaul16/dot-hyprland.git "$REPO_DIR"
fi

# Copy config folders into ~/.config
mkdir -p ~/.config
cp -r "$REPO_DIR"/{ags,hypr,Kvantum,fuzzel,kitty,wlogout} ~/.config/

# Optional: copy additional files to appropriate locations
cp "$REPO_DIR"/pavucontrol.ini ~/.config/
cp "$REPO_DIR"/code-flags.conf ~/.config/
cp "$REPO_DIR"/thorium-flags.conf ~/.config/

echo "Configs copied successfully."

# Function to install a package only if it's not already installed
install_pkg() {
    local category="$1"
    shift
    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            echo "==> Installing $pkg ($category)"
            if ! yay -S --noconfirm "$pkg"; then
                echo "❌ Failed to install $pkg"
                return 1
            fi
        else
            echo "--> $pkg is already installed. Skipping."
        fi
    done
}

echo "==> Installing Audio dependencies..."
install_pkg pavucontrol wireplumber libdbusmenu-gtk3 playerctl swww

echo "==> Installing Backlight dependencies..."
install_pkg brightnessctl ddcutil

echo "==> Installing Basic tools..."
install_pkg axel bc coreutils cliphist cmake curl fuzzel rsync wget ripgrep jq npm meson typescript gjs xdg-user-dirs

echo "==> Installing Theme/fonts..."
install_pkg adw-gtk-theme-git qt5ct qt6ct qt5-wayland fontconfig \
  ttf-readex-pro ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git \
  ttf-space-mono-nerd ttf-rubik-vf ttf-gabarito-git \
  kitty zsh kvantum kvantum-qt5

echo "==> Installing GNOME support..."
install_pkg polkit-gnome gnome-keyring gnome-control-center networkmanager

echo "==> Installing GTK dependencies..."
install_pkg webp-pixbuf-loader gtk-layer-shell gtk3 gtksourceview3 gobject-introspection upower yad ydotool xdg-user-dirs-gtk

echo "==> Installing Hyprland..."
install_pkg hyprutils hyprpicker hyprlang hypridle hyprland-qt-support hyprland-qtutils \
  hyprlock xdg-desktop-portal-hyprland hyprcursor hyprwayland-scanner hyprland

echo "==> Installing Widgets..."
install_pkg dart-sass wlogout wl-clipboard \
  nm-connection-editor better-control-git

echo "==> Installing Screen Capture tools..."
install_pkg swappy wf-recorder grim tesseract tesseract-data-eng slurp

echo "==> Installing Python-related tools..."
install_pkg clang uv gtk4 libadwaita libsoup3 libportal-gtk4 gobject-introspection sassc

echo "==> Installing Portal support..."
install_pkg xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland

echo "✅ All dependencies installed."
