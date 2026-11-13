-- Motion: the bezier curve is registered first because every animation below
-- references it by name. Leaf list and speeds come from the theme (base speed
-- x motion.speed, layers x motion.layers_speed).
--
-- Layer surfaces have their own animation through layer rules; per-namespace
-- runtime overrides live in `config/lib/animation_override.lua`.

local theme = require("config.appearance.palette")

hl.curve("theme", theme.curves.theme)

for _, animation in ipairs(theme.animations) do
    hl.animation(animation)
end
