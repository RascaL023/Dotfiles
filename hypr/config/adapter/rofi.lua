-- Only this file knows rofi exists. The base rule must exist before
-- anim.layer() adds the wallpaper override.

local anim = require("config.lib.animation_override")
local feel = require("config.appearance.feel")

local home = os.getenv("HOME") or ""

local backend = "rofi-ctl"
local rofi = {}
rofi.namespace = "rofi"

function rofi.command(subcommand, style)
    local parts = { backend, subcommand }
    if style ~= nil then
        parts[#parts + 1] = style
    end
    return table.concat(parts, " ")
end

hl.layer_rule({
    name         = "launcher",
    match        = { namespace = rofi.namespace },
    animation    = "slide bottom",
    blur         = feel.chrome.layer_blur,
    ignore_alpha = 0,
})

local wallpaper = anim.layer({
    namespace = rofi.namespace,
    animation = "fade",
    name      = "launcher-wallpaper-fade",
})

function rofi.pick_wallpaper()
    wallpaper.launch(home .. "/.config/hypr/sources/scripts/nextwall.sh")
end

return rofi
