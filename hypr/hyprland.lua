require("variables") -- MY PROGRAMS
require("env")        -- ENVIRONMENT VARIABLES
require("general")    -- MONITORS, PERMISSIONS, LOOK AND FEEL, LAYOUTS, MISC, INPUT, DEVICES
local machine_path = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hyprland-config/machine.lua"
local machine_file = io.open(machine_path, "r")
if machine_file then
    machine_file:close()
    dofile(machine_path) -- UNTRACKED HARDWARE OVERRIDES WRITTEN BY setup.sh
end
require("execs")       -- AUTOSTART
require("rules")       -- WINDOW / WORKSPACE RULES
pcall(require, "colors") -- MATUGEN-GENERATED BORDER/ACCENT COLORS (wallpaper-driven, see ~/.config/matugen)
require("keybinds")    -- KEYBINDINGS
