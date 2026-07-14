---------------------
---- MY PROGRAMS ----
---------------------

terminal    = "kitty"
fileManager = "nautilus"
menu        = "fuzzel"
browser    = "google-chrome-stable"
codeEditor      = "code"

---------------------
---- KEYBINDINGS ----
---------------------
-- Named combos referenced by keybinds.lua, one variable per bind (pattern
-- borrowed from caelestia-dots/caelestia's hypr/variables.lua). Naming:
-- `kb` + PascalCase action name, derived from each bind's description with
-- the "Category:" prefix dropped (matches caelestia's kbLock/kbTerminal/
-- kbShowSidebar style). kbGoToWs/kbMoveWinToWs are mod-only prefixes
-- combined with a workspace number in keybinds.lua's loop, same as
-- caelestia's own kbGoToWs/kbMoveWinToWs.

-- Apps / launcher
kbTerminal          = "SUPER + Grave"
kbFileManager       = "SUPER + E"
kbAppMenu           = "SUPER + R" -- fuzzel (fallback launcher)
kbBrowser           = "SUPER + W"
kbCodeEditor        = "SUPER + C"
kbLauncher          = "SUPER + Space" -- quickshell app launcher
kbClipboardHistory  = "SUPER + V"
kbWallpaperPicker   = "SUPER + T"
kbCheatsheet        = "SUPER + Slash"

-- Window actions
kbCloseWindow           = "SUPER + Q"
kbToggleWindowFloating  = "SUPER + ALT + Space"
kbTogglePseudotile      = "SUPER + P"
kbToggleSplit           = "SUPER + J"
kbFocusLeft             = "SUPER + left"
kbFocusRight            = "SUPER + right"
kbFocusUp               = "SUPER + up"
kbFocusDown             = "SUPER + down"
kbMoveWindow            = "SUPER + mouse:272"
kbResizeWindow          = "SUPER + mouse:273"

-- Workspaces
kbGoToWs                = "SUPER"       -- + <N> in keybinds.lua's loop
kbMoveWinToWs            = "SUPER + SHIFT" -- + <N> in keybinds.lua's loop
kbSpecialWs              = "SUPER + S"
kbMoveWinToScratchpad    = "SUPER + SHIFT + S"
kbWorkspaceNext          = "SUPER + mouse_down"
kbWorkspacePrev          = "SUPER + mouse_up"

-- System
kbExit  = "SUPER + M"
kbLock  = "SUPER + L"

-- Screenshots / recording
kbScreenshotFull        = "Print"
kbScreenshotRegion      = "SUPER + Print"
kbScreenshotRegionEdit  = "SUPER + SHIFT + Print"
kbRecordRegion          = "SUPER + ALT + R"
kbRecordFull            = "SUPER + ALT + SHIFT + R"

-- Media / hardware keys
kbVolumeUp        = "XF86AudioRaiseVolume"
kbVolumeDown      = "XF86AudioLowerVolume"
kbMute            = "XF86AudioMute"
kbMicMute         = "XF86AudioMicMute"
kbBrightnessUp    = "XF86MonBrightnessUp"
kbBrightnessDown  = "XF86MonBrightnessDown"
kbMediaNext       = "XF86AudioNext"
kbMediaPause      = "XF86AudioPause"
kbMediaPlay       = "XF86AudioPlay"
kbMediaPrev       = "XF86AudioPrev"

-- Screen
kbZoomOut = "SUPER + Minus"
kbZoomIn  = "SUPER + Equal"
