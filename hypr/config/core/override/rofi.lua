-- Wallpaper picker animation. Every rofi variant shares the layer namespace
-- "rofi", so a static rule cannot tell the picker apart from rofi apps.

local home = os.getenv("HOME") or ""
local rofi = {}

-- Created after the "rofi" rule in hyprland.lua: with two matching layer rules,
-- the newer one wins. Disabled until a picker is launched.
rofi.wall_fade = hl.layer_rule({
    name      = "rofi-wallpaper-fade",
    match     = { namespace = "rofi" },
    animation = "fade",
})
rofi.wall_fade:set_enabled(false)

hl.on("layer.closed", function(layer)
    if layer ~= nil and layer.namespace == "rofi" then
        rofi.wall_fade:set_enabled(false)
    end
end)

-- set_enabled applies immediately, while rofi needs ~300 ms before its layer is
-- mapped, so the rule must be flipped before the script runs.
function rofi.pick_wallpaper()
    rofi.wall_fade:set_enabled(true)
    hl.exec_cmd(home .. "/.config/hypr/sources/scripts/nextwall.sh")
end

return rofi
