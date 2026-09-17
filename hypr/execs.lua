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
    -- Quickshell unit
    hl.exec_cmd([[bash -c 'uwsm finalize; systemctl --user import-environment QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME; systemctl --user start quickshell.service']])

    -- Exactly once per login: shuffle or restore according to the wallpaper
    -- setting. This intentionally does not live in Quickshell, whose service
    -- may restart several times during one session.
    hl.exec_cmd([[bash -c 'exec "$HOME/.local/bin/switchwall" --login']])
end)
