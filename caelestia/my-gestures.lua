-- Personal gestures; uses Hyprland's native gesture support.
hl.config({ gestures = {
    workspace_swipe_distance = 700,
    workspace_swipe_cancel_ratio = 0.15,
    workspace_swipe_min_speed_to_force = 5,
    workspace_swipe_direction_lock = true,
    workspace_swipe_direction_lock_threshold = 10,
    workspace_swipe_create_new = true,
    workspace_swipe_use_r = true,
} })
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = function()
    hl.exec_cmd("qs -c caelestia ipc call hypr openLastSpecialWorkspace")
end })
hl.gesture({ fingers = 3, direction = "down", action = function()
    hl.exec_cmd("qs -c caelestia ipc call hypr toggleLastSpecialWorkspace")
end })
hl.gesture({ fingers = 4, direction = "up", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
end })
hl.gesture({ fingers = 4, direction = "down", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset" }))
end })

-- Step through scratchpads, creating empty ones via Caelestia's controller.
hl.gesture({ fingers = 4, direction = "left", action = function()
    hl.exec_cmd("qs -c caelestia ipc call hypr cycleSpecialWorkspace next")
end })
hl.gesture({ fingers = 4, direction = "right", action = function()
    hl.exec_cmd("qs -c caelestia ipc call hypr cycleSpecialWorkspace previous")
end })
