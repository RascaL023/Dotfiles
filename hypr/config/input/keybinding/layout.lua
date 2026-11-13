-- Layout model bindings: switching between dwindle and scrolling, column
-- sizing, consuming/expelling columns, and fitting the active window.

local kb     = require("config.input.keybinding.helpers")
local mod    = kb.mod
local layout = kb.layout

-- ------------------------------------------------------------- model switch --
hl.bind(mod .. " + S", function()
    local current = hl.get_config("general.layout")
    hl.config({ ["general.layout"] = current == "dwindle" and "scrolling" or "dwindle" })
end)

hl.bind(mod .. " + SHIFT + P", kb.layout_switch(
    function() return hl.dsp.no_op() end,
    function() return layout("togglesplit") end))

-- ------------------------------------------------------------------ columns --
hl.bind(mod .. " + R",         layout("colresize +conf"))
hl.bind(mod .. " + SHIFT + R", layout("colresize -conf"))

hl.bind(mod .. " + MINUS",     layout("colresize -0.05"))
hl.bind(mod .. " + EQUAL",     layout("colresize +0.1"))

hl.bind(mod .. " + COMMA",        layout("consume"))
hl.bind(mod .. " + PERIOD",       layout("expel"))
hl.bind(mod .. " + BRACKETLEFT",  layout("consume_or_expel prev"))
hl.bind(mod .. " + BRACKETRIGHT", layout("consume_or_expel next"))

hl.bind(mod .. " + CTRL + SHIFT + mouse_up",   layout("swapcol l"))
hl.bind(mod .. " + CTRL + SHIFT + mouse_down", layout("swapcol r"))

-- -------------------------------------------------------------------- fit ----
-- F is a scrolling-layout fit; a dwindle workspace toggles maximized instead.
hl.bind(mod .. " + F", kb.layout_switch(
    function() return layout("fit active") end,
    function() return hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }) end))

hl.bind(mod .. " + BACKSLASH",         layout("center"))
hl.bind(mod .. " + SHIFT + BACKSLASH", layout("fit_into_view"))
hl.bind(mod .. " + ALT + BACKSLASH",   layout("fit expand"))
