------------------------------------ LAYER RULES --
local theme = require("config.appearance").palette -- Tambalan sementara sebelum integrasi theme penuh
local layer_blur = theme.layer_blur

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
