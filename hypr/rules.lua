--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local function shell_transparency_enabled()
    local home = os.getenv("HOME")
    if not home then return false end
    local file = io.open(home .. "/.config/quickshell/config.json", "r")
    if not file then return false end
    local contents = file:read("*a")
    file:close()
    return contents:match('"transparency"%s*:%s*true') ~= nil
end

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "float-blueman-manager",
    match = { class = "blueman-manager" },

    tag   = "+float",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Shell layer blur
hl.layer_rule({
    name  = "blur-quickshell",
    match = { namespace = "^quickshell-.*$" },

    -- Avoid compositor blur work when every shell surface is opaque.
    blur = shell_transparency_enabled(),
    ignore_alpha = 0.2,
    -- Quickshell owns its panel motion; compositor animation here would move
    -- and fade the same surface a second time.
    no_anim = true,
})
