------------------------------------ LAYER RULES --
local feel = require("config.appearance.feel") -- rasa; tidak memuat look/motion
local layer_blur = feel.chrome.layer_blur

hl.layer_rule({
    name      = "logout_dialog",
    match     = { namespace = "logout_dialog" },
    animation = "fade",
    blur      = layer_blur,
})

hl.layer_rule({
    name      = "swaync-control-center",
    match     = { namespace = "swaync-control-center" },
    animation = "slide left",
    blur      = layer_blur,
    ignore_alpha = 0,
})

hl.layer_rule({
    name      = "waybar",
    match     = { namespace = "waybar" },
    animation = "slide up",
    blur      = layer_blur,
})
