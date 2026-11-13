require("config.core")
require("config.rule")

local theme = require("config.appearance").palette -- Tambalan sementara sebelum integrasi theme penuh

-------------------------------------------------------------- LOOK & FEEL --
hl.config(theme.hypr)

hl.config({
    general = {
        layout = "dwindle",
    },

    input = {
        kb_layout = "us",
        sensitivity = 0.1,
        follow_mouse = 1,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        column_width             = 0.5,
        fullscreen_on_one_column = true,
        explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",
        focus_fit_method         = 1,
        follow_focus             = true,
        follow_min_visible       = 0.4,
        wrap_focus               = false,
        wrap_swapcol             = false,
        direction                = "right",
    },

    binds = {
        movefocus_cycles_fullscreen = true,
        window_direction_monitor_fallback = true,
    },
})

------------------------------------------------------------ ANIMATIONS ----
hl.curve("theme", theme.curves.theme)

for _, animation in ipairs(theme.animations) do
    hl.animation(animation)
end


---------------------------------------------------------- CONFIG IMPORT -----
require("config.input") -- Must here for rofi override animations
