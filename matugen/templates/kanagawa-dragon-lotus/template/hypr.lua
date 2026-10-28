-- ############################
-- ## Generated with Matugen ##
-- ############################
-- ## Manual edit is not recomended,
-- ## Except for testing.

-- Dibaca oleh hypr/config/core/theme.lua lewat
-- ~/.myenv/theme/current/hypr/theme.lua. Berkas ini murni data: hanya boleh
-- `return { ... }`, tanpa panggilan fungsi.
--
-- Warna berasal dari palet blueprint; angka "rasa" berasal dari objek `feel`
-- di blueprint yang sama, jadi tema baru cukup menambah satu blueprint.

return {
    shape = {
        radius                = {{ feel.shape.radius }},
        rounding_power        = {{ feel.shape.rounding_power }},
        border                = {{ feel.shape.border }},
        gaps_in               = {{ feel.shape.gaps_in }},
        gaps_out              = {{ feel.shape.gaps_out }},
        border_angle          = {{ feel.shape.border_angle }},
        border_part_of_window = {{ feel.shape.border_part_of_window }},

        border_active   = "rgba({{ accent.primary | to_color | format: hex_stripped }}ee)",
        border_active2  = "rgba({{ accent.secondary | to_color | format: hex_stripped }}ee)",
        border_inactive = "rgba({{ surface.lowest | to_color | format: hex_stripped }}ee)",
    },

    surface = {
        active_opacity     = {{ feel.surface.active_opacity }},
        inactive_opacity   = {{ feel.surface.inactive_opacity }},
        fullscreen_opacity = {{ feel.surface.fullscreen_opacity }},
        dim_inactive       = {{ feel.surface.dim_inactive }},
        dim_strength       = {{ feel.surface.dim_strength }},
        dim_around         = {{ feel.surface.dim_around }},
        terminal_opacity   = {{ feel.surface.terminal_opacity }},
    },

    material = {
        blur = {
            enabled           = {{ feel.material.blur.enabled }},
            size              = {{ feel.material.blur.size }},
            passes            = {{ feel.material.blur.passes }},
            noise             = {{ feel.material.blur.noise }},
            contrast          = {{ feel.material.blur.contrast }},
            brightness        = {{ feel.material.blur.brightness }},
            vibrancy          = {{ feel.material.blur.vibrancy }},
            vibrancy_darkness = {{ feel.material.blur.vibrancy_darkness }},
            xray              = {{ feel.material.blur.xray }},
            popups            = {{ feel.material.blur.popups }},
            ignore_opacity    = {{ feel.material.blur.ignore_opacity }},
            new_optimizations = {{ feel.material.blur.new_optimizations }},
        },
        shadow = {
            enabled = {{ feel.material.shadow.enabled }},
            range   = {{ feel.material.shadow.range }},
            power   = {{ feel.material.shadow.power }},
            color   = "rgba({{ effect.shadow | to_color | format: hex_stripped }}ee)",
            sharp   = {{ feel.material.shadow.sharp }},
        },
    },

    motion = {
        speed        = {{ feel.motion.speed }},
        curve        = { {{ feel.motion.curve.x1 }}, {{ feel.motion.curve.y1 }}, {{ feel.motion.curve.x2 }}, {{ feel.motion.curve.y2 }} },
        style_in     = "{{ feel.motion.style_in }}",
        style_out    = "{{ feel.motion.style_out }}",
        style_ws_in  = "{{ feel.motion.style_ws_in }}",
        style_ws_out = "{{ feel.motion.style_ws_out }}",
        layers_speed = {{ feel.motion.layers_speed }},
    },

    chrome = {
        layer_blur     = {{ feel.chrome.layer_blur }},
        nogroup_border = "rgba({{ border.medium | to_color | format: hex_stripped }}99)",
        font_family    = "{{ feel.chrome.font_family }}",

        groupbar = {
            enabled    = {{ feel.chrome.groupbar.enabled }},
            gradient   = {{ feel.chrome.groupbar.gradient }},
            height     = {{ feel.chrome.groupbar.height }},
            radius     = {{ feel.chrome.groupbar.radius }},
            text_color = "rgba({{ accent.on_primary | to_color | format: hex_stripped }}ee)",
        },
    },
}
