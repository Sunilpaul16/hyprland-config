-------------------
---- AUTOSTART ----
-------------------

-- Wrapped in hl.on("hyprland.start", ...) (matches upstream's
-- hyprland/execs.lua convention) so these only run once at actual Hyprland
-- startup, not on every `hyprctl reload` — bare top-level hl.exec_cmd calls
-- re-run on every reload and silently pile up duplicate processes.
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("qs -n -c bar") -- minimal from-scratch bar, see ~/.config/quickshell/bar/
end)
