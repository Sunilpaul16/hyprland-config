---------------------
---- KEYBINDINGS ----
---------------------



local v = require("my-shortcut-vars")

hl.bind(v.kbTerminal, hl.dsp.exec_cmd(v.terminal), { description = "App: terminal" })
hl.bind(v.kbCloseWindow, hl.dsp.window.close(), { description = "Window: close" })
hl.bind(v.kbFileManager, hl.dsp.exec_cmd(v.fileManager), { description = "App: file manager" })
hl.bind(v.kbToggleWindowFloating, hl.dsp.window.float({ action = "toggle" }), { description = "Window: toggle floating" })
hl.bind(v.kbTogglePseudotile, hl.dsp.window.pseudo(), { description = "Window: toggle pseudotile" })
hl.bind(v.kbToggleSplit, hl.dsp.layout("togglesplit"), { description = "Window: toggle split direction" })
hl.bind(v.kbToggleFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Window: Fullscreen" })
hl.bind(v.kbTogglePin, hl.dsp.window.pin(), { description = "Window: Pin" })

hl.bind(v.kbBrowser, hl.dsp.exec_cmd(v.browser), { description = "App: browser" })
hl.bind(v.kbClipboardHistory, hl.dsp.exec_cmd("caelestia clipboard"), { description = "Launcher: clipboard history" })
hl.bind(v.kbLock, hl.dsp.exec_cmd("qs -c caelestia ipc call lock lock"), { description = "System: lock screen" })
hl.bind(v.kbRestartShell, hl.dsp.exec_cmd("caelestia shell -r -d"), { description = "System: restart Caelestia" })
hl.bind(v.kbReloadHyprland, hl.dsp.exec_cmd([[bash -c 'hyprctl reload && notify-send -a hyprland "Hyprland" "Config reloaded"']]), { description = "System: reload Hyprland config" })
hl.bind(v.kbLauncher, hl.dsp.exec_cmd("qs -c caelestia ipc call drawers toggle launcher"), { description = "Launcher: apps" })
hl.bind(v.kbWallpaperPicker, hl.dsp.exec_cmd("python3 ~/.config/caelestia/animated-wallpaper.py picker"), { description = "Launcher: wallpaper picker" })
hl.bind(v.kbRandomWallpaper, hl.dsp.exec_cmd("python3 ~/.config/caelestia/animated-wallpaper.py random"), { description = "Launcher: random wallpaper" })
hl.bind(v.kbCodeEditor, hl.dsp.exec_cmd(v.codeEditor), { description = "App: code editor" })
hl.bind(v.kbDashboard, hl.dsp.exec_cmd("qs -c caelestia ipc call drawers toggle dashboard"), { description = "Launcher: dashboard" })
hl.bind(v.kbSettings, hl.dsp.exec_cmd("qs -c caelestia ipc call nexus open"), { description = "Launcher: Caelestia settings" })
hl.bind(v.kbToggleBar, hl.dsp.exec_cmd("python3 ~/.config/caelestia/toggle-bar.py"), { description = "Shell: toggle bar" })


-- Screenshots
hl.bind(v.kbScreenshotFull, hl.dsp.exec_cmd("python3 ~/.config/caelestia/screenshot-save.py"), { description = "Screenshot: fullscreen" })
hl.bind(v.kbScreenshotRegion, hl.dsp.exec_cmd("caelestia screenshot -r"), { description = "Screenshot: region" })

-- Screen recording
hl.bind(v.kbRecordRegion, hl.dsp.exec_cmd("caelestia record -r"), { description = "Record: region (toggle)" })
hl.bind(v.kbRecordFull, hl.dsp.exec_cmd("caelestia record"), { description = "Record: fullscreen (toggle)" })

-- Move focus
hl.bind(v.kbFocusLeft,  hl.dsp.focus({ direction = "left" }),  { description = "Window: focus left" })
hl.bind(v.kbFocusRight, hl.dsp.focus({ direction = "right" }), { description = "Window: focus right" })
hl.bind(v.kbFocusUp,    hl.dsp.focus({ direction = "up" }),    { description = "Window: focus up" })
hl.bind(v.kbFocusDown,  hl.dsp.focus({ direction = "down" }),  { description = "Window: focus down" })

-- Switch workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(v.kbGoToWs .. " + " .. key,        hl.dsp.focus({ workspace = i}), { description = "Workspace: switch <N>" })
    hl.bind(v.kbMoveWinToWs .. " + " .. key,   hl.dsp.window.move({ workspace = i }), { description = "Workspace: move window to <N>" })
end

-- Scratchpad
hl.bind("SUPER + SHIFT + F23", hl.dsp.workspace.toggle_special("magic"), { description = "Workspace: Copilot toggle scratchpad" })
hl.bind(v.kbSpecialWs,             hl.dsp.workspace.toggle_special("magic"), { description = "Workspace: toggle scratchpad" })
hl.bind(v.kbMoveWinToScratchpad,   hl.dsp.window.move({ workspace = "special:magic" }), { description = "Workspace: move window to scratchpad" })

-- Scroll workspaces
hl.bind(v.kbWorkspaceNext, hl.dsp.focus({ workspace = "+1" }), { description = "Workspace: next" })
hl.bind(v.kbWorkspacePrev, hl.dsp.focus({ workspace = "-1" }), { description = "Workspace: previous" })

-- Mouse move/resize
hl.bind(v.kbMoveWindow,   hl.dsp.window.drag(),   { mouse = true, description = "Window: drag with mouse" })
hl.bind(v.kbResizeWindow, hl.dsp.window.resize(), { mouse = true, description = "Window: resize with mouse" })

hl.bind(v.kbBrightnessUp,   hl.dsp.exec_cmd("qs -c caelestia ipc call brightness set +5%"),   { locked = true, repeating = true, description = "Screen: brightness up" })
hl.bind(v.kbBrightnessDown, hl.dsp.exec_cmd("qs -c caelestia ipc call brightness set 5%-"), { locked = true, repeating = true, description = "Screen: brightness down" })

hl.bind(v.kbVolumeUp,       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Media: volume up" })
hl.bind(v.kbVolumeDown,     hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Media: volume down" })
hl.bind(v.kbMute,           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "Media: mute" })
hl.bind(v.kbMicMute,        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "Media: mic mute" })

-- Media playback
hl.bind(v.kbMediaNext,  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Media: next track" })
hl.bind(v.kbMediaPause, hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: play/pause" })
hl.bind(v.kbMediaPlay,  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: play/pause" })
hl.bind(v.kbMediaPrev,  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Media: previous track" })

--# Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(v.kbZoomOut, function() zoomfunction(-0.3) end, { repeating = true, description = "Screen: zoom out" })
hl.bind(v.kbZoomIn, function() zoomfunction(0.3) end, { repeating = true, description = "Screen: zoom in" })

-- Graphical shortcut reference.
hl.bind("SUPER + Slash", hl.dsp.exec_cmd("sh ~/.config/quickshell/caelestia-cheatsheet/toggle"), { description = "Help: shortcut cheatsheet" })


hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("python3 ~/.config/caelestia/screenshot-save.py"), { description = "Screenshot: Lenovo key fullscreen" })

hl.bind("SUPER + CTRL + SHIFT + S", hl.dsp.exec_cmd("caelestia screenshot -r"), { description = "Screenshot: Lenovo key region" })



-- AltGr is Mod5 on the GB keyboard; Copilot sends Super + Shift + F23.
hl.bind("SUPER + SHIFT + MOD5 + F23", function()
    local win = hl.get_active_window()
    if not win then return end
    local workspace = win.workspace
    local is_special = workspace and ((workspace.name and workspace.name:match("^special:")) or (workspace.id and workspace.id < 0))
    hl.dispatch(hl.dsp.window.move({ workspace = is_special and "e+0" or "special:magic" }))
end, { description = "Workspace: AltGr + Copilot move window into/out of scratchpad" })
