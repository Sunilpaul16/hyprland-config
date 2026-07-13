-------------------
---- AUTOSTART ----
-------------------


hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("qs -n -c bar") -- minimal from-scratch bar, see ~/.config/quickshell/bar/

    -- Restore last wallpaper (mpvpaper doesn't survive a session restart;
    -- theme files from the last switchwall run are already on disk, so
    -- --preview is enough — no need to re-run matugen/colorgen at login)
    hl.exec_cmd([[bash -c 'f="$HOME/.local/state/quickshell/current_wallpaper"; [ -s "$f" ] && exec /home/spaul16/.local/bin/switchwall --preview "$(cat "$f")"']])
end)
