local theme = require("config.core.theme.palette")

------------------------------------------------------------------ MONITORS --
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

---------------------------------------------------- ENVIRONMENT VARIABLES --
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "hyprland")
hl.env("MYENV", (os.getenv("HOME") or "") .. "/.myenv")

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

------------------------------------------------------------ AUTOSTART ----
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("eww daemon --force-wayland")
    hl.exec_cmd("swaync")
    hl.exec_cmd("$HOME/.config/waybar/waybar-ctl start")
end)

------------------------------------------------------------- GESTURES ----
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "vertical", action = "scroll_move" })

---------------------------------------------------- WINDOW / LAYER RULES --
hl.window_rule({
    name    = "foot-opacity",
    match   = { class = "^foot$" },
    opacity = tostring(theme.surface.terminal_opacity),
})

hl.window_rule({
    name    = "codium-opacity",
    match   = { class = "^(codium)$" },
    opacity = "0.9",
})

hl.window_rule({
    name  = "ttyper-float",
    match = { class = "^(ttyper)$" },
    float = true,
    size  = { 900, 500 },
    center = true,
})

hl.window_rule({
    name  = "kitty-float",
    match = { class = "^kitty-float$" },
    float = true,
    size  = { 900, 560 },
    center = true,
})

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
    -- Blur only the panel area, not the transparent pixels around it.
    ignore_alpha = 0,
})

hl.layer_rule({
    name      = "rofi",
    match     = { namespace = "rofi" },
    animation = "slide bottom",
    blur      = layer_blur,
})

hl.layer_rule({
    name      = "waybar",
    match     = { namespace = "waybar" },
    animation = "slide up",
    blur      = layer_blur,
})

---------------------------------------------------------- CONFIG IMPORT -----
require("config.core.binding") -- Must here for rofi override animations
