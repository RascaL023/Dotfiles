-- rofi adapter: the only file that knows rofi exists. The capability module
-- that wraps it only calls `command` and `pick_wallpaper`.
--
-- Both the layer namespace and the rules that paint it are rofi facts, so they
-- live here rather than in config/rule/layer.lua. The base rule is created
-- first and anim.layer() appends a newer rule for the same namespace, so the
-- wallpaper override wins while armed; creating both here keeps that order
-- intrinsic instead of depending on which consumer loads first.

local anim  = require("config.lib.animation_override")
local theme = require("config.appearance.palette")

local home = os.getenv("HOME") or ""

local rofi = {}

-- Layer namespace rofi reports to the compositor. Matched literally; it is a
-- runtime identifier, not something the capability can rename.
rofi.namespace = "rofi"

local backend = "rofi-ctl"

-- command("toggle", "apps") -> "rofi-ctl toggle apps".
-- `nil` style is dropped; `nil` arguments are trailing only.
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
    blur         = theme.layer_blur,
    ignore_alpha = 0,
})

-- Both directions fade: Hyprland applies one style to layersIn and layersOut,
-- and animation_override.lua keeps the rule enabled through the closing
-- animation, then hands the namespace back to the base rule above.
local wallpaper = anim.layer({
    namespace = rofi.namespace,
    animation = "fade",
    name      = "launcher-wallpaper-fade",
})

function rofi.pick_wallpaper()
    wallpaper.launch(home .. "/.config/hypr/sources/scripts/nextwall.sh")
end

return rofi
