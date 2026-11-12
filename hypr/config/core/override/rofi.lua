-- Wallpaper picker animation. Every rofi variant shares the layer namespace
-- "rofi", so a static rule cannot tell the picker apart from rofi apps; a
-- toggleable override rule is armed before launch instead.

local anim = require("config.core.override.anim")

local home = os.getenv("HOME") or ""
local rofi = {}

-- Both directions fade: Hyprland applies one style to layersIn and layersOut,
-- and override/anim.lua keeps the rule enabled through the closing animation.
local wallpaper = anim.layer({
    namespace = "rofi",
    animation = "fade",
    name      = "rofi-wallpaper-fade",
})

function rofi.pick_wallpaper()
    wallpaper.launch(home .. "/.config/hypr/sources/scripts/nextwall.sh")
end

return rofi
