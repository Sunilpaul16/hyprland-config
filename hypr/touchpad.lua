-- Laptop touchpad: native Hyprland/libinput support, no gesture daemon.
-- Two-finger pinch is left to applications (e.g. browser zoom).
hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
            scroll_factor = 1.0,
            tap_to_click = true,
            tap_button_map = "lrm",
            clickfinger_behavior = false,
            tap_and_drag = true,
            drag_lock = 0,
            disable_while_typing = true,
        },
    },
})

-- Three-finger horizontal swipe: switch workspaces with your fingers.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- Three-finger up/down: toggle fullscreen / floating for the active window.
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down", action = "float" })
