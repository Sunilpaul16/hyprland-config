-- Laptop hardware and personal shortcuts; appearance uses Caelestia defaults.
hl.monitor({ output = "eDP-1", mode = "2560x1600@60", position = "0x0", scale = 1.25 })
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.config({
    input = {
        kb_layout = "gb",
        kb_file = "",
    },
    cursor = { default_monitor = "eDP-1" },
})
require("my-shortcuts")

require("my-gestures")

-- Keep file dialogs compact on the laptop's scaled display.
hl.window_rule({
    match = { title = "((Select|Open)( a)? (File|Folder)(s)?|Save As)" },
    float = true,
    size = { 1000, 700 },
    center = true,
})

-- Restore the selected animated wallpaper at login.
hl.on("hyprland.start", function()
    hl.exec_cmd("python3 ~/.config/caelestia/animated-wallpaper.py restore")
    hl.exec_cmd("python3 ~/.config/caelestia/load-files-gestures.py")
end)
