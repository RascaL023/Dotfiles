-- Acting on the focused window: state (float, pseudo, fullscreen, group),
-- keyboard focus, moves between positions, and the resize submap.

local kb   = require("config.input.keybinding.helpers")
local mod  = kb.mod
local layout = kb.layout

-- -------------------------------------------------------------------- state --
hl.bind(mod .. " + Q",              hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + SPACE",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mod .. " + SHIFT + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + M",              hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind(mod .. " + ALT + W",        hl.dsp.group.toggle())

-- cycle_next only reorders the stack, bring_to_top makes the pick visible.
hl.bind("ALT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- -------------------------------------------------------------------- focus --
local focus_keys = {
    H = "left",  L = "right", K = "up",  J = "down",
    LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
}

for key, direction in pairs(focus_keys) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.focus({ direction = "right" }))

-- --------------------------------------------------------------------- move --
-- On the scrolling layout the horizontal pair swaps columns instead of
-- shifting a floating window.
hl.bind(mod .. " + CTRL + LEFT",  kb.layout_switch(
    function() return layout("swapcol l") end,
    function() return hl.dsp.window.move({ direction = "left" }) end))
hl.bind(mod .. " + CTRL + RIGHT", kb.layout_switch(
    function() return layout("swapcol r") end,
    function() return hl.dsp.window.move({ direction = "right" }) end))
hl.bind(mod .. " + CTRL + UP",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- ------------------------------------------------------------------- resize --
hl.bind(mod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y =  50, relative = true }))
hl.bind(mod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- ------------------------------------------------------------------- submap --
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
