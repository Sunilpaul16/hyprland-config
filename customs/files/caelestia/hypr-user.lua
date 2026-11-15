-- Desktop hardware and personal shortcuts; appearance uses Caelestia defaults.
hl.monitor({ output = "DP-3", mode = "2560x1440@144Hz", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@144Hz", position = "2560x-560", scale = 1, transform = 3 })
hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true })
hl.config({
    input = {
        kb_layout = "us",
        kb_file = "",
    },
    cursor = { default_monitor = "DP-3" },
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
