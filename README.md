# Caelestia laptop setup

Current Arch Linux laptop configuration, saved on the `laptop-caelestia` branch.
This branch replaces the previous custom shell with Caelestia while keeping
personal Kitty, Zsh, keyboard shortcuts and touchpad gestures.

## Included

- Hyprland Lua configuration: eDP-1, 2560×1600 at 60 Hz, scale 1.25, GB keyboard.
- Caelestia shell 2.5.0 with local QML customizations and its upstream license.
- App names in the bar; populated special workspaces labelled as scratchpads.
- Manual Wi-Fi scan buttons; routine network updates use cached results.
- Custom cheatsheet with key badges, category icons and system window styling.
- Kitty, Zsh, Powerlevel10k configuration and fuzzy history search.
- Animated wallpapers through mpvpaper, with frame thumbnails and dynamic colours.
- Game mode stops the wallpaper process and displays its still frame; leaving
  game mode resumes the selected video.
- Autostart overrides hiding duplicate Blueman and NetworkManager tray applets.

The vendored shell is the installed 2.5.0 configuration with our edits. Compiled
Caelestia plugins and Quickshell are supplied by system packages, not this repo.
The separate development clone was at commit
`5f1c59c0665aad66e94710f67e4bebaeb65c35f4` when this snapshot was taken.

## Restore

This targets the same laptop. Review monitor names and screen settings in
`caelestia/hypr-user.lua` and the output in `caelestia/animated-wallpaper.py` when
using another machine. Hyprland must support the Lua configuration API.

1. Install Arch Linux, networking, Git, `base-devel`, and an AUR helper.
2. Install Hyprland, `caelestia-shell`, `caelestia-cli` and their dependencies.
   This setup uses `quickshell-git`; it conflicts with the stable `quickshell`
   package. The exact installed package versions are recorded under `packages/`.
3. Install `kitty`, `zsh`, `fzf`, `yazi`, `ffmpeg`, `mpvpaper`, `wl-clipboard`,
   `cliphist`, `grim`, `slurp`, `libnotify`, `nautilus`, `brightnessctl`,
   `networkmanager`, `bluez`, `bluez-utils`, `pipewire`, `wireplumber`,
   `pipewire-pulse`, `power-profiles-daemon`, `hypridle`, `hyprlock`,
   `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `gnome-keyring`,
   `polkit-gnome`, `gammastep`, `geoclue`, `ttf-jetbrains-mono-nerd`,
   `ttf-rubik-vf` and Material Symbols fonts. Personal app shortcuts also expect
   `google-chrome-stable` and `code`.
4. Clone and restore the files:

   ```sh
   git clone --branch laptop-caelestia https://github.com/Sunilpaul16/hyprland-config.git
   cd hyprland-config
   python3 install.py
   ```

   The installer saves replaced configuration in a timestamped directory under
   `~/.local/state/caelestia-config-backups/`. It installs files, not packages,
   and does not enable system services or change your login shell.

5. Install Oh My Zsh and Powerlevel10k if missing:

   ```sh
   git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.config/zsh/oh-my-zsh
   git clone https://github.com/romkatv/powerlevel10k.git ~/.config/zsh/oh-my-zsh/custom/themes/powerlevel10k
   chsh -s /usr/bin/zsh
   ```

6. Enable NetworkManager, Bluetooth and power-profiles-daemon as appropriate.
   Log into Hyprland using UWSM so user services receive the Wayland environment.
7. Put your own videos or images in `~/Pictures/Wallpapers`, then run:

   ```sh
   caelestia scheme set -n dynamic
   python3 ~/.config/caelestia/animated-wallpaper.py random
   ```

   Video frames are generated once and cached. New files appear when opening the
   wallpaper picker or choosing a random wallpaper. The original videos remain
   in your Pictures folder. The selected wallpaper restores on the next login.

## Main shortcuts

| Shortcut | Action |
|---|---|
| Super + / | Cheatsheet |
| Super + I | Settings |
| Super + T | Wallpaper picker |
| Super + Shift + T | Random wallpaper |
| Super + B | Toggle bar |
| Copilot | Toggle scratchpad |
| AltGr + Copilot | Move app into/out of scratchpad |
| Three fingers left/right | Sequential workspaces, including empty ones |
| Three fingers up/down | Scratchpad |
| Four fingers up/down | Enter/leave fullscreen |
| Four fingers left/right | Cycle populated scratchpads |

All bindings are in `caelestia/my-shortcuts.lua`; the cheatsheet intentionally
shows a smaller selection. Scroll factor is 0.8.

## Excluded

No wallpaper videos, profile photo, credentials, browser data, shell history,
notifications, screenshots or runtime state are included. Hibernate is not
configured. Package inventories document this machine; they are not an
instruction to install every listed application.

After restoring, verify startup, locking, suspend/resume, brightness and game
mode on the target machine. Restoring on a fresh system has not been tested.
