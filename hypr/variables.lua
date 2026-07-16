---------------------
---- MY PROGRAMS ----
---------------------

terminal    = "kitty"
fileManager = "nautilus"
menu        = "fuzzel"
browser    = "google-chrome-stable"
codeEditor      = "code"

home = os.getenv("HOME")

---------------------
---- KEYBINDINGS ----
---------------------

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
kbOverview          = "SUPER + Tab" -- quickshell workspace overview

-- Window actions
kbCloseWindow           = "SUPER + Q"
kbToggleWindowFloating  = "SUPER + ALT + Space"
kbTogglePseudotile      = "SUPER + ALT + P"
kbToggleSplit           = "SUPER + J"
kbToggleFullscreen      = "SUPER + F"
kbTogglePin             = "SUPER + P"
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
kbRestartShell = "SUPER + CTRL + R"
kbReloadHyprland = "SUPER + CTRL + ALT + R"

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
