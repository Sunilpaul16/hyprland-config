---------------------
---- MY PROGRAMS ----
---------------------

local M = {}

M.terminal    = "kitty"
M.fileManager = "nautilus"
M.browser    = "google-chrome-stable"
M.codeEditor      = "code"

M.home = os.getenv("HOME")

---------------------
---- KEYBINDINGS ----
---------------------

-- Apps / launcher
M.kbTerminal          = "SUPER + Grave"
M.kbFileManager       = "SUPER + E"
M.kbBrowser           = "SUPER + W"
M.kbCodeEditor        = "SUPER + C"
M.kbLauncher          = "SUPER + Space" -- quickshell app launcher
M.kbClipboardHistory  = "SUPER + V"
M.kbWallpaperPicker   = "SUPER + T"
M.kbRandomWallpaper   = "SUPER + SHIFT + T"
M.kbCheatsheet        = "SUPER + Slash"
M.kbOverview          = "SUPER + Tab" -- quickshell workspace overview
M.kbSettings          = "SUPER + I" -- quickshell settings panel

-- Window actions
M.kbCloseWindow           = "SUPER + Q"
M.kbToggleWindowFloating  = "SUPER + ALT + Space"
M.kbTogglePseudotile      = "SUPER + ALT + P"
M.kbToggleSplit           = "SUPER + J"
M.kbToggleFullscreen      = "SUPER + F"
M.kbTogglePin             = "SUPER + P"
M.kbFocusLeft             = "SUPER + left"
M.kbFocusRight            = "SUPER + right"
M.kbFocusUp               = "SUPER + up"
M.kbFocusDown             = "SUPER + down"
M.kbMoveWindow            = "SUPER + mouse:272"
M.kbResizeWindow          = "SUPER + mouse:273"

-- Workspaces
M.kbGoToWs                = "SUPER"       -- + <N> in keybinds.lua's loop
M.kbMoveWinToWs            = "SUPER + SHIFT" -- + <N> in keybinds.lua's loop
M.kbSpecialWs              = "SUPER + S"
M.kbMoveWinToScratchpad    = "SUPER + SHIFT + S"
M.kbWorkspaceNext          = "SUPER + mouse_down"
M.kbWorkspacePrev          = "SUPER + mouse_up"

-- System
M.kbExit  = "SUPER + M"
M.kbLock  = "SUPER + L"
M.kbRestartShell = "SUPER + CTRL + R"
M.kbReloadHyprland = "SUPER + CTRL + ALT + R"

M.kbOcrRegion             = "SUPER + SHIFT + O"

-- Screenshots / recording
M.kbScreenshotFull        = "Print"
M.kbScreenshotRegion      = "SUPER + Print"
M.kbScreenshotRegionEdit  = "SUPER + SHIFT + Print"
M.kbRecordRegion          = "SUPER + ALT + R"
M.kbRecordFull            = "SUPER + ALT + SHIFT + R"

-- Media / hardware keys
M.kbVolumeUp        = "XF86AudioRaiseVolume"
M.kbVolumeDown      = "XF86AudioLowerVolume"
M.kbMute            = "XF86AudioMute"
M.kbMicMute         = "XF86AudioMicMute"
M.kbBrightnessUp    = "XF86MonBrightnessUp"
M.kbBrightnessDown  = "XF86MonBrightnessDown"
M.kbMediaNext       = "XF86AudioNext"
M.kbMediaPause      = "XF86AudioPause"
M.kbMediaPlay       = "XF86AudioPlay"
M.kbMediaPrev       = "XF86AudioPrev"

-- Screen
M.kbZoomOut = "SUPER + Minus"
M.kbZoomIn  = "SUPER + Equal"

return M
