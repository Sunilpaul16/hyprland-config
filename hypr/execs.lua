-------------------
---- AUTOSTART ----
-------------------


hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus'")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("blueman-applet")
    -- Minimal from-scratch shell, see ~/.config/quickshell/shell/. Run as a systemd
    -- user unit (systemd/quickshell.service) so a crash restarts it instead of
    -- leaving the desktop with no bar, launcher or notifications
    hl.exec_cmd("systemctl --user start quickshell.service")

    hl.exec_cmd([[bash -c 'f="$HOME/.local/state/quickshell/current_wallpaper"; [ -s "$f" ] && exec "$HOME/.local/bin/switchwall" --preview "$(cat "$f")"']])
end)
