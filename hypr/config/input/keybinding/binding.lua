-- Hyprland 0.57 keybinds. Binds that only exist in the scrolling layout are
-- guarded so a dwindle session falls back to its own dispatcher.

local mod  = "SUPER"
local home = os.getenv("HOME") or ""

local rofi = require("config.integration.rofi")

local function exec(cmd)      return hl.dsp.exec_cmd(cmd) end
local function layout(msg)    return hl.dsp.layout(msg) end
local function script(name)   return hl.dsp.exec_cmd(home .. "/.config/hypr/sources/scripts/" .. name) end

-- The canonical-private-synchronous hint makes swaync replace the previous
-- notification, so held keys update one bubble instead of stacking.
local function volume(step)
    return exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. step .. " -l 1.0 && " ..
        "notify-send -h string:x-canonical-private-synchronous:volume " ..
        "\"Volume: $(pamixer --get-volume)%\" -t 800")
end

local function brightness(step)
    return exec("brightnessctl -q set " .. step .. " && " ..
        "notify-send -h string:x-canonical-private-synchronous:brightness " ..
        "\"Brightness: $((100 * $(brightnessctl g) / $(brightnessctl m)))%\" -t 800")
end

local function mute(source, label)
    return exec("wpctl set-mute " .. source .. " toggle && notify-send \"" .. label .. "\" -t 1000")
end

-- ------------------------------------------------------------------ layout --
local function tiled_layout()
    local ws = hl.get_active_workspace()
    return ws and ws.tiled_layout or "dwindle"
end

local function layout_switch(in_scrolling, otherwise)
    return function()
        hl.dispatch(tiled_layout() == "scrolling" and in_scrolling() or otherwise())
    end
end

-- =========================================================================
-- BASIC
-- =========================================================================

hl.bind(mod .. " + Q",              hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + SPACE",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mod .. " + CTRL + L",       exec("hyprlock"))

hl.bind(mod .. " + SHIFT + P", layout_switch(
    function() return hl.dsp.no_op() end,
    function() return layout("togglesplit") end))

-- =========================================================================
-- TOOLS
-- =========================================================================

hl.bind(mod .. " + B",              exec("firefox"))
hl.bind(mod .. " + RETURN",         exec("kitty"))
hl.bind(mod .. " + SHIFT + RETURN", exec("foot"))
hl.bind(mod .. " + ALT + RETURN",   exec("kitty --class kitty-float"))
hl.bind(mod .. " + CTRL + RETURN",  exec("alacritty"))
hl.bind(mod .. " + CTRL + T",       exec("kitty --class ttyper -e ttyper"))
hl.bind(mod .. " + E",              exec("nemo"))
hl.bind(mod .. " + SHIFT + E",      exec("kitty -e yazi"))

hl.bind(mod .. " + C",              script("wifi-menu.sh"))
hl.bind(mod .. " + O",              script("waybar-toggle.sh"))
hl.bind(mod .. " + ESCAPE",         script("wlogout-toggle.sh"))
hl.bind(mod .. " + SPACE",          exec("rofi-ctl toggle apps"))
hl.bind(mod .. " + I",              script("idle-toggle.sh"))
hl.bind(mod .. " + W",              function() rofi.pick_wallpaper() end)
hl.bind(mod .. " + T",              exec(home .. "/.myenv/script/theme/theme-picker.sh"))
hl.bind(mod .. " + SHIFT + N",      script("bluelight-toggle.sh"))

hl.bind(mod .. " + X",              exec("eww open --toggle profile"))
hl.bind(mod .. " + D",              exec("eww open --toggle distro"))
-- hl.bind(mod .. " + A",              exec(home .. "/.config/eww/script/ctl.sh toggle"))
hl.bind(mod .. " + CTRL + X",       exec("pkill eww; eww daemon --force-wayland"))

hl.bind(mod .. " + CTRL + P", exec([[hyprpicker -a | wl-copy && notify-send "Color picked!" "$(wl-paste)"]]))
hl.bind(mod .. " + N",              exec("swaync-client -t"))

-- =========================================================================
-- SCREENSHOTS
-- =========================================================================

hl.bind("SUPER + ALT + PRINT", exec([[grim -o LVDS-1 "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" && notify-send -t 2000 "Screenshot" "Successfully took fullscreen screenshot!"]]))
hl.bind("SUPER + PRINT",       exec([[grim -g "$(slurp)" "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" && notify-send -t 2000 "Screenshot" "Successfully took partial screenshot!"]]))

-- =========================================================================
-- WORKSPACES
-- =========================================================================

for i = 1, 6 do
    hl.bind(mod .. " + " .. i,          hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i, follow = false }))
    hl.bind("ALT + SHIFT + " .. i,      hl.dsp.window.move({ workspace = i, follow = true }))
end

local workspace_keys = { J = 1, K = 2, L = 3, U = 4, I = 5, O = 6 }

for key, workspace in pairs(workspace_keys) do
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = false }))
    hl.bind("ALT + SHIFT + " .. key,     hl.dsp.window.move({ workspace = workspace, follow = true }))
end

hl.bind("CTRL + ALT + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + LEFT",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + L",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + H",     hl.dsp.focus({ workspace = "e-1" }))

hl.bind("ALT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- =========================================================================
-- FOCUS
-- =========================================================================

local focus_keys = {
    H = "left",  L = "right", K = "up",  J = "down",
    LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
}

for key, direction in pairs(focus_keys) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

-- =========================================================================
-- MOVE WINDOW (ala niri: Mod+Ctrl+arah)
-- =========================================================================

hl.bind(mod .. " + CTRL + LEFT",  layout_switch(
    function() return layout("swapcol l") end,
    function() return hl.dsp.window.move({ direction = "left" }) end))
hl.bind(mod .. " + CTRL + RIGHT", layout_switch(
    function() return layout("swapcol r") end,
    function() return hl.dsp.window.move({ direction = "right" }) end))
hl.bind(mod .. " + CTRL + UP",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- =========================================================================
-- SCROLLING (ala niri)
-- =========================================================================

hl.bind(mod .. " + R",         layout("colresize +conf"))
hl.bind(mod .. " + SHIFT + R", layout("colresize -conf"))

hl.bind(mod .. " + MINUS", layout("colresize -0.05"))
hl.bind(mod .. " + EQUAL", layout("colresize +0.1"))

hl.bind(mod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y =  50, relative = true }))
hl.bind(mod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))

hl.bind(mod .. " + COMMA",        layout("consume"))
hl.bind(mod .. " + PERIOD",       layout("expel"))
hl.bind(mod .. " + BRACKETLEFT",  layout("consume_or_expel prev"))
hl.bind(mod .. " + BRACKETRIGHT", layout("consume_or_expel next"))

hl.bind(mod .. " + F", layout_switch(
    function() return layout("fit active") end,
    function() return hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }) end))
hl.bind(mod .. " + SHIFT + F",     hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + M",             hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))

hl.bind(mod .. " + BACKSLASH",        layout("center"))
hl.bind(mod .. " + SHIFT + BACKSLASH", layout("fit_into_view"))
hl.bind(mod .. " + ALT + BACKSLASH",   layout("fit expand"))

hl.bind(mod .. " + ALT + W", hl.dsp.group.toggle())

hl.bind(mod .. " + mouse_up",           hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_down",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + CTRL + mouse_up",           hl.dsp.window.move({ workspace = "e-1", follow = true }))
hl.bind(mod .. " + CTRL + mouse_down",         hl.dsp.window.move({ workspace = "e+1", follow = true }))
hl.bind(mod .. " + CTRL + SHIFT + mouse_up",   layout("swapcol l"))
hl.bind(mod .. " + CTRL + SHIFT + mouse_down", layout("swapcol r"))

-- =========================================================================
-- MOUSE
-- =========================================================================

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- =========================================================================
-- RESIZE (submap, SUPER + ALT + R)
-- =========================================================================

hl.bind(mod .. " + ALT + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
    hl.bind("L",     hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
    hl.bind("H",     hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
    hl.bind("K",     hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })
    hl.bind("J",     hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- =========================================================================
-- VOLUME / BRIGHTNESS
-- =========================================================================

hl.bind("XF86AudioRaiseVolume",  volume("0.05+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  volume("0.05-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         mute("@DEFAULT_AUDIO_SINK@",   "Volume toggled"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      mute("@DEFAULT_AUDIO_SOURCE@", "Mic toggled"),    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   brightness("+5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", brightness("5%-"), { locked = true, repeating = true })

-- =========================================================================
-- MUSIC
-- =========================================================================

hl.bind(mod .. " + SHIFT + M", exec("mpc toggle"))
hl.bind(mod .. " + ALT + P",   exec("pkill mpd"))

-- =========================================================================
-- TOGGLE LAYOUT (dwindle <-> scrolling)
-- =========================================================================

hl.bind(mod .. " + S", function()
    local current = hl.get_config("general.layout")
    hl.config({ ["general.layout"] = current == "dwindle" and "scrolling" or "dwindle" })
end)
