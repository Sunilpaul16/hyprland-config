-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

local v = require("variables")

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")

-- Wayland / Electron app hints
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Flatpak app data (no-op if flatpak isn't installed). Guarded so repeated
-- `hyprctl reload`s don't keep re-prepending onto their own prior output.
local flatpak_share = v.home .. "/.local/share/flatpak/exports/share"
local xdg_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
if not xdg_data_dirs:find(flatpak_share, 1, true) then
    hl.env("XDG_DATA_DIRS", flatpak_share .. ":/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs)
end
