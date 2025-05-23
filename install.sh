#!/bin/bash

set -e

echo "==> Updating system packages..."
sudo pacman -Syu --noconfirm

# Function to install a package only if it's not already installed
install_pkg() {
    for pkg in "$@"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            echo "==> Installing $pkg"
            yay -S --noconfirm "$pkg"
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
  fish foot starship kvantum kvantum-qt5

echo "==> Installing GNOME support..."
install_pkg polkit-gnome gnome-keyring gnome-control-center networkmanager

echo "==> Installing GTK dependencies..."
install_pkg webp-pixbuf-loader gtk-layer-shell gtk3 gtksourceview3 gobject-introspection upower yad ydotool xdg-user-dirs-gtk

echo "==> Installing Hyprland..."
install_pkg hyprutils hyprpicker hyprlang hypridle hyprland-qt-support hyprland-qtutils \
  hyprlock xdg-desktop-portal-hyprland hyprcursor hyprwayland-scanner hyprland

echo "==> Installing Widgets..."
install_pkg dart-sass hypridle hyprutils hyprlock wlogout wl-clipboard hyprpicker \
  nm-connection-editor better-control-git

echo "==> Installing Screen Capture tools..."
install_pkg swappy wf-recorder grim tesseract tesseract-data-eng slurp

echo "==> Installing Python-related tools..."
install_pkg clang uv gtk4 libadwaita libsoup3 libportal-gtk4 gobject-introspection sassc

echo "==> Installing Portal support..."
install_pkg xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland

echo "✅ All dependencies installed."
