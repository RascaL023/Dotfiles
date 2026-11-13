-- Render layer for motion: the curve is registered first because every
-- animation below references it by name. All inputs are feel data — base speed
-- x motion.speed, layers x motion.layers_speed — so one multiplier shifts the
-- whole motion feel.
--
-- Layer surfaces have their own animation through layer rules; per-namespace
-- runtime overrides live in config/lib/animation_override.lua.

local feel   = require("config.appearance.feel")
local motion = feel.motion
local curve  = motion.curve

hl.curve("theme", {
    type   = "bezier",
    points = { { curve[1], curve[2] }, { curve[3], curve[4] } },
})

local animations = {
    { leaf = "global", enabled = true, speed = 10 * motion.speed, bezier = "default" },

    { leaf = "windows",     enabled = true, speed = 7 * motion.speed, bezier = "theme" },
    { leaf = "windowsMove", enabled = true, speed = 3 * motion.speed, bezier = "theme" },
    { leaf = "windowsOut",  enabled = true, speed = 7 * motion.speed, bezier = "theme", style = motion.style_out },
    { leaf = "windowsIn",   enabled = true, speed = 5 * motion.speed, bezier = "theme", style = motion.style_in },

    { leaf = "border",      enabled = true, speed = 10 * motion.speed, bezier = "default" },
    { leaf = "borderangle", enabled = true, speed = 50 * motion.speed, bezier = "default" },

    { leaf = "layers", enabled = true, speed = 4 * motion.layers_speed, bezier = "theme" },

    { leaf = "workspacesIn",  enabled = true, speed = 6 * motion.speed, bezier = "theme",   style = motion.style_ws_in },
    { leaf = "workspacesOut", enabled = true, speed = 3 * motion.speed, bezier = "default", style = motion.style_ws_out },
}

for _, animation in ipairs(animations) do
    hl.animation(animation)
end
