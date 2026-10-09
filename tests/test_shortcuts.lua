-- Exercise personal shortcut callbacks without changing the live desktop.
local base = assert(arg[1], "pass the caelestia config directory")
package.path = base .. "/?.lua;" .. package.path
local binds, gestures, dispatches, configs = {}, {}, {}, {}
local active_window, active_special, zoom = nil, nil, 1
local function namespace(prefix)
    return setmetatable({}, {__index = function(t, key)
        local value
        if key == "window" or key == "workspace" then value = namespace(prefix .. key .. ".")
        else value = function(args) return {kind = prefix .. key, args = args} end end
        rawset(t, key, value)
        return value
    end})
end
hl = {
    dsp = namespace(""),
    bind = function(key, action, options)
        assert(not binds[key], "Duplicate key: " .. key)
        binds[key] = {action = action, options = options}
    end,
    gesture = function(value) gestures[value.fingers .. ":" .. value.direction] = value end,
    config = function(value)
        configs[#configs + 1] = value
        if value.cursor then zoom = value.cursor.zoom_factor end
    end,
    get_config = function() return zoom end,
    get_active_window = function() return active_window end,
    get_active_special_workspace = function() return active_special end,
    dispatch = function(value) dispatches[#dispatches + 1] = value end,
    exec_cmd = function(value) dispatches[#dispatches + 1] = {kind="exec_cmd",args=value} end,
}
require("my-shortcuts")
require("my-gestures")
local checks = 0
local function check(condition, label)
    assert(condition, label)
    checks = checks + 1
end
check(binds["SUPER + T"].action.args:match("animated%-wallpaper.py picker"), "wallpaper picker")
check(binds["SUPER + SHIFT + T"].action.args:match("animated%-wallpaper.py random"), "random wallpaper")
check(binds["SUPER + mouse_down"].action.args.workspace == "+1", "next workspace includes empty")
check(binds["SUPER + mouse_up"].action.args.workspace == "-1", "previous workspace includes empty")
check(binds["Print"].action.args == "caelestia screenshot", "Print full capture")
check(binds["SHIFT + Print"].action.args == "caelestia screenshot -r", "Shift Print region")
check(binds["SUPER + SHIFT + S"].action.args == "caelestia screenshot", "restored full screenshot shortcut")
check(binds["SUPER + CTRL + SHIFT + S"].action.args == "caelestia screenshot -r", "restored region shortcut")
check(binds["SUPER + SHIFT + F23"] ~= nil, "Copilot toggle exists")
check(binds["SUPER + CTRL + SHIFT + F23"] == nil, "removed Ctrl Copilot")
local move = binds["SUPER + SHIFT + MOD5 + F23"].action
move();check(#dispatches == 0, "Copilot safely handles no active window")
active_window = {workspace={id=2,name="2"}};move()
check(dispatches[#dispatches].args.workspace == "special:magic", "move normal window to scratchpad")
active_window = {workspace={id=-99,name="special:communication"}};move()
check(dispatches[#dispatches].args.workspace == "e+0", "move scratchpad window to normal workspace")
zoom=1;binds["SUPER + Minus"].action();check(zoom==1, "zoom lower bound")
zoom=2.9;binds["SUPER + Equal"].action();check(zoom==3, "zoom upper bound")
zoom=1;binds["SUPER + Equal"].action();check(math.abs(zoom-1.3)<0.001, "zoom increment")
local use_r=false
for _,c in ipairs(configs) do if c.gestures then use_r=c.gestures.workspace_swipe_use_r end end
check(use_r==true,"touchpad includes empty workspaces")
check(gestures['3:horizontal'].action=='workspace','three finger workspace gesture')
check(gestures['3:up'].workspace_name=='magic','three finger up scratchpad')
active_special={name='special:communication'};gestures['3:down'].action()
check(dispatches[#dispatches].args=='communication','three finger down closes current scratchpad')
active_special=nil;gestures['3:down'].action()
check(dispatches[#dispatches].args=='magic','three finger down fallback')
gestures['4:up'].action();check(dispatches[#dispatches].args.action=='set','four finger fullscreen')
gestures['4:down'].action();check(dispatches[#dispatches].args.action=='unset','four finger exit fullscreen')
gestures['4:left'].action();check(dispatches[#dispatches].args:match('next$'),'scratchpad next')
gestures['4:right'].action();check(dispatches[#dispatches].args:match('previous$'),'scratchpad previous')
for n=1,10 do check(binds['SUPER + '..(n%10)].action.args.workspace==n,'direct workspace '..n) end
print(checks .. ' shortcut and gesture checks passed')
