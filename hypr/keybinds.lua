---------------------
---- KEYBINDINGS ----
---------------------



hl.bind(kbTerminal, hl.dsp.exec_cmd(terminal), { description = "App: terminal" })
local closeWindowBind = hl.bind(kbCloseWindow, hl.dsp.window.close(), { description = "Window: close" })
hl.bind(kbExit, hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = "System: exit hyprland" })
hl.bind(kbFileManager, hl.dsp.exec_cmd(fileManager), { description = "App: file manager" })
hl.bind(kbToggleWindowFloating, hl.dsp.window.float({ action = "toggle" }), { description = "Window: toggle floating" })
hl.bind(kbAppMenu, hl.dsp.exec_cmd(menu), { description = "Launcher: application menu" })
hl.bind(kbTogglePseudotile, hl.dsp.window.pseudo(), { description = "Window: toggle pseudotile" })
hl.bind(kbToggleSplit, hl.dsp.layout("togglesplit"), { description = "Window: toggle split direction" })

hl.bind(kbBrowser, hl.dsp.exec_cmd(browser), { description = "App: browser" })
hl.bind(kbClipboardHistory, hl.dsp.exec_cmd("qs -c shell ipc call launcher openClip"), { description = "Launcher: clipboard history" })
hl.bind(kbLock, hl.dsp.exec_cmd("hyprlock"), { description = "System: lock screen" })
hl.bind(kbLauncher, hl.dsp.exec_cmd("qs -c shell ipc call launcher openApps"), { description = "Launcher: apps" })
hl.bind(kbWallpaperPicker, hl.dsp.exec_cmd("qs -c shell ipc call launcher openWallpaper"), { description = "Launcher: wallpaper" })
hl.bind(kbCodeEditor, hl.dsp.exec_cmd(codeEditor), { description = "App: code editor" })
hl.bind(kbCheatsheet, hl.dsp.exec_cmd("qs -c shell ipc call cheatsheet toggle"), { description = "Launcher: keybind cheatsheet" })


-- Screenshots
hl.bind(kbScreenshotFull, hl.dsp.exec_cmd(home .. "/.local/bin/screenshot full"), { description = "Screenshot: fullscreen" })
hl.bind(kbScreenshotRegion, hl.dsp.exec_cmd(home .. "/.local/bin/screenshot region"), { description = "Screenshot: region" })
hl.bind(kbScreenshotRegionEdit, hl.dsp.exec_cmd(home .. "/.local/bin/screenshot region --edit"), { description = "Screenshot: region + edit" })

-- Screen recording (press again to stop, regardless of which mode started it)
hl.bind(kbRecordRegion, hl.dsp.exec_cmd(home .. "/.local/bin/record region"), { description = "Record: region (toggle)" })
hl.bind(kbRecordFull, hl.dsp.exec_cmd(home .. "/.local/bin/record full"), { description = "Record: fullscreen (toggle)" })

-- Move focus with arrow keys
hl.bind(kbFocusLeft,  hl.dsp.focus({ direction = "left" }),  { description = "Window: focus left" })
hl.bind(kbFocusRight, hl.dsp.focus({ direction = "right" }), { description = "Window: focus right" })
hl.bind(kbFocusUp,    hl.dsp.focus({ direction = "up" }),    { description = "Window: focus up" })
hl.bind(kbFocusDown,  hl.dsp.focus({ direction = "down" }),  { description = "Window: focus down" })

-- Switch workspaces with kbGoToWs/kbMoveWinToWs + [0-9]
for i = 1, 10 do
    local key = i % 10
    hl.bind(kbGoToWs .. " + " .. key,        hl.dsp.focus({ workspace = i}), { description = "Workspace: switch <N>" })
    hl.bind(kbMoveWinToWs .. " + " .. key,   hl.dsp.window.move({ workspace = i }), { description = "Workspace: move window to <N>" })
end

-- Special workspace (scratchpad)
hl.bind(kbSpecialWs,             hl.dsp.workspace.toggle_special("magic"), { description = "Workspace: toggle scratchpad" })
hl.bind(kbMoveWinToScratchpad,   hl.dsp.window.move({ workspace = "special:magic" }), { description = "Workspace: move window to scratchpad" })

-- Scroll through workspaces
hl.bind(kbWorkspaceNext, hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace: next" })
hl.bind(kbWorkspacePrev, hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace: previous" })

-- Move/resize windows with mouse
hl.bind(kbMoveWindow,   hl.dsp.window.drag(),   { mouse = true, description = "Window: drag with mouse" })
hl.bind(kbResizeWindow, hl.dsp.window.resize(), { mouse = true, description = "Window: resize with mouse" })

hl.bind(kbVolumeUp,       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Media: volume up" })
hl.bind(kbVolumeDown,     hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Media: volume down" })
hl.bind(kbMute,           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "Media: mute" })
hl.bind(kbMicMute,        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "Media: mic mute" })
hl.bind(kbBrightnessUp,   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true, description = "Media: brightness up" })
hl.bind(kbBrightnessDown, hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true, description = "Media: brightness down" })

-- Media playback
hl.bind(kbMediaNext,  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Media: next track" })
hl.bind(kbMediaPause, hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: play/pause" })
hl.bind(kbMediaPlay,  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: play/pause" })
hl.bind(kbMediaPrev,  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Media: previous track" })

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
hl.bind(kbZoomOut, function() zoomfunction(-0.3) end, { repeating = true, description = "Screen: zoom out" })
hl.bind(kbZoomIn, function() zoomfunction(0.3) end, { repeating = true, description = "Screen: zoom in" })
