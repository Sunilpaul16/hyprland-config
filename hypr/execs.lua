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
    -- leaving the desktop with no bar, launcher or notifications.
    -- QT_QPA_PLATFORM must be handed over first: quickshell derives an instance
    -- "display id" from it, and `qs ipc` only talks to instances whose id matches the
    -- caller's. uwsm finalizes the HYPRCURSOR/XCURSOR vars but not this one, so without
    -- the import the unit registers as "wayland,wayland-1" while every keybind calling
    -- `qs -c shell ipc call` computes "unk,wayland" and finds no running instance.
    -- QT_QPA_PLATFORMTHEME rides along so the shell's icon lookups see Papirus.
    hl.exec_cmd([[bash -c 'systemctl --user import-environment QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME; systemctl --user start quickshell.service']])

    hl.exec_cmd([[bash -c 'f="$HOME/.local/state/quickshell/current_wallpaper"; [ -s "$f" ] && exec "$HOME/.local/bin/switchwall" --preview "$(cat "$f")"']])
end)
