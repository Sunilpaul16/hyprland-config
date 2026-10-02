-- Laptop touchpad: native Hyprland/libinput support, no gesture daemon.
-- Two-finger pinch is left to applications (e.g. browser zoom).
hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.7,
            tap_to_click = true,
            tap_button_map = "lrm",
            clickfinger_behavior = false,
            tap_and_drag = true,
            drag_lock = 0,
            disable_while_typing = true,
        },
    },
})

-- Three- and four-finger horizontal swipes navigate workspaces.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- Three-finger up/down are intentionally unassigned.
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- Swipe four fingers up to enter fullscreen; down to leave it.
hl.gesture({ fingers = 4, direction = "up", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
end })
hl.gesture({ fingers = 4, direction = "down", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset" }))
end })
