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
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "magic" })
hl.gesture({ fingers = 3, direction = "down", action = function()
    local active = hl.get_active_special_workspace()
    local name = active and active.name:gsub("^special:", "") or "magic"
    hl.dispatch(hl.dsp.workspace.toggle_special(name))
end })
hl.gesture({ fingers = 4, direction = "up", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
end })
hl.gesture({ fingers = 4, direction = "down", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset" }))
end })

-- Cycle populated scratchpads using Caelestia's native workspace controller.
hl.gesture({ fingers = 4, direction = "left", action = function()
    hl.exec_cmd("qs -c caelestia ipc call hypr cycleSpecialWorkspace next")
end })
hl.gesture({ fingers = 4, direction = "right", action = function()
    hl.exec_cmd("qs -c caelestia ipc call hypr cycleSpecialWorkspace previous")
end })
