-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recomended,
-- ## Except for testing.

-- Dibaca oleh hypr/config/core/theme/palette.lua lewat
-- ~/.myenv/theme/feel/current/hypr/feel.lua. Berkas ini murni data: hanya
-- boleh `return { ... }`, tanpa panggilan fungsi.
--
-- Warna tidak ada di sini: itu milik palet
-- (~/.myenv/theme/palette/current/hypr/theme.lua). Yang ditulis hanya angka
-- dan boolean "rasa" milik Hyprland, diambil dari
-- core/feel/profiles/<profil>/hypr.json.

return {
    shape = {
        radius                = {{ shape.radius }},
        rounding_power        = {{ shape.rounding_power }},
        border                = {{ shape.border }},
        gaps_in               = {{ shape.gaps_in }},
        gaps_out              = {{ shape.gaps_out }},
        border_angle          = {{ shape.border_angle }},
        border_part_of_window = {{ shape.border_part_of_window }},
    },

    surface = {
        active_opacity     = {{ surface.active_opacity }},
        inactive_opacity   = {{ surface.inactive_opacity }},
        fullscreen_opacity = {{ surface.fullscreen_opacity }},
        dim_inactive       = {{ surface.dim_inactive }},
        dim_strength       = {{ surface.dim_strength }},
        dim_around         = {{ surface.dim_around }},
        terminal_opacity   = {{ surface.terminal_opacity }},
    },

    material = {
        blur = {
            enabled           = {{ material.blur.enabled }},
            size              = {{ material.blur.size }},
            passes            = {{ material.blur.passes }},
            noise             = {{ material.blur.noise }},
            contrast          = {{ material.blur.contrast }},
            brightness        = {{ material.blur.brightness }},
            vibrancy          = {{ material.blur.vibrancy }},
            vibrancy_darkness = {{ material.blur.vibrancy_darkness }},
            xray              = {{ material.blur.xray }},
            popups            = {{ material.blur.popups }},
            ignore_opacity    = {{ material.blur.ignore_opacity }},
            new_optimizations = {{ material.blur.new_optimizations }},
        },
        shadow = {
            enabled = {{ material.shadow.enabled }},
            range   = {{ material.shadow.range }},
            power   = {{ material.shadow.power }},
            sharp   = {{ material.shadow.sharp }},
        },
    },

    motion = {
        speed        = {{ motion.speed }},
        curve        = { {{ motion.curve.x1 }}, {{ motion.curve.y1 }}, {{ motion.curve.x2 }}, {{ motion.curve.y2 }} },
        style_in     = "{{ motion.style_in }}",
        style_out    = "{{ motion.style_out }}",
        style_ws_in  = "{{ motion.style_ws_in }}",
        style_ws_out = "{{ motion.style_ws_out }}",
        layers_speed = {{ motion.layers_speed }},
    },

    chrome = {
        layer_blur  = {{ chrome.layer_blur }},
        font_family = "{{ chrome.font_family }}",

        groupbar = {
            enabled  = {{ chrome.groupbar.enabled }},
            gradient = {{ chrome.groupbar.gradient }},
            height   = {{ chrome.groupbar.height }},
            radius   = {{ chrome.groupbar.radius }},
        },
    },
}
