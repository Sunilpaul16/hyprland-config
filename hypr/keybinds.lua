---------------------
---- KEYBINDINGS ----
---------------------



local mainMod = "SUPER"

hl.bind(mainMod .. " + Grave", hl.dsp.exec_cmd(terminal), { description = "App: terminal" })
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Window: close" })
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = "System: exit hyprland" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "App: file manager" })
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Window: toggle floating" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu), { description = "Launcher: application menu" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Window: toggle pseudotile" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Window: toggle split direction" })

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser), { description = "App: browser" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs -c shell ipc call launcher openClip"), { description = "Launcher: clipboard history" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"), { description = "System: lock screen" })
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("qs -c shell ipc call launcher openApps"), { description = "Launcher: apps" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs -c shell ipc call launcher openWallpaper"), { description = "Launcher: wallpaper" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(codeEditor), { description = "App: code editor" })
hl.bind(mainMod .. " + Slash", hl.dsp.exec_cmd("qs -c shell ipc call cheatsheet toggle"), { description = "Launcher: keybind cheatsheet" })


-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("/home/spaul16/.local/bin/screenshot full"), { description = "Screenshot: fullscreen" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("/home/spaul16/.local/bin/screenshot region"), { description = "Screenshot: region" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("/home/spaul16/.local/bin/screenshot region --edit"), { description = "Screenshot: region + edit" })

-- Screen recording (press again to stop, regardless of which mode started it)
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("/home/spaul16/.local/bin/record region"), { description = "Record: region (toggle)" })
hl.bind(mainMod .. " + ALT + SHIFT + R", hl.dsp.exec_cmd("/home/spaul16/.local/bin/record full"), { description = "Record: fullscreen (toggle)" })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  { description = "Window: focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Window: focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }),    { description = "Window: focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }),  { description = "Window: focus down" })

-- Switch workspaces with mainMod + [0-9]
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}), { description = "Workspace: switch <N>" })
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }), { description = "Workspace: move window to <N>" })
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { description = "Workspace: toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Workspace: move window to scratchpad" })

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace: next" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace: previous" })

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Window: drag with mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Window: resize with mouse" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Media: volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Media: volume down" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "Media: mute" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "Media: mic mute" })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true, description = "Media: brightness up" })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true, description = "Media: brightness down" })

-- Media playback
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Media: next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: play/pause" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: play/pause" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Media: previous track" })

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
hl.bind("SUPER + Minus", function() zoomfunction(-0.3) end, { repeating = true, description = "Screen: zoom out" })
hl.bind("SUPER + Equal", function() zoomfunction(0.3) end, { repeating = true, description = "Screen: zoom in" })
