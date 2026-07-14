-------------------
---- AUTOSTART ----
-------------------


hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("qs -n -c shell") -- minimal from-scratch shell, see ~/.config/quickshell/shell/

    hl.exec_cmd([[bash -c 'f="$HOME/.local/state/quickshell/current_wallpaper"; [ -s "$f" ] && exec /home/spaul16/.local/bin/switchwall --preview "$(cat "$f")"']])
end)
