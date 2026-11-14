-- Maps palette colours and feel numbers to hl.config.

local palette = require("config.appearance.palette")
local feel    = require("config.appearance.feel")

local shape   = feel.shape
local surface = feel.surface
local blur    = feel.material.blur
local shadow  = feel.material.shadow
local chrome  = feel.chrome

hl.config({
    general = {
        gaps_in     = shape.gaps_in,
        gaps_out    = shape.gaps_out,
        border_size = shape.border,

        col = {
            active_border = {
                colors = { palette.shape.border_active, palette.shape.border_active2 },
                angle  = shape.border_angle,
            },
            inactive_border = palette.shape.border_inactive,
            nogroup_border  = palette.chrome.nogroup_border,
        },
    },

    decoration = {
        rounding              = shape.radius,
        rounding_power        = shape.rounding_power,
        border_part_of_window = shape.border_part_of_window,

        active_opacity     = surface.active_opacity,
        inactive_opacity   = surface.inactive_opacity,
        fullscreen_opacity = surface.fullscreen_opacity,
        dim_inactive       = surface.dim_inactive,
        dim_strength       = surface.dim_strength,
        dim_around         = surface.dim_around,

        blur = {
            enabled           = blur.enabled,
            size              = blur.size,
            passes            = blur.passes,
            noise             = blur.noise,
            contrast          = blur.contrast,
            brightness        = blur.brightness,
            vibrancy          = blur.vibrancy,
            vibrancy_darkness = blur.vibrancy_darkness,
            xray              = blur.xray,
            popups            = blur.popups,
            ignore_opacity    = blur.ignore_opacity,
            new_optimizations = blur.new_optimizations,
        },

        shadow = {
            enabled      = shadow.enabled,
            range        = shadow.range,
            render_power = shadow.power,
            color        = palette.material.shadow.color,
            sharp        = shadow.sharp,
        },
    },

    group = {
        col = {
            border_active   = palette.shape.border_active,
            border_inactive = palette.shape.border_inactive,
        },
        groupbar = {
            enabled    = chrome.groupbar.enabled,
            gradients  = chrome.groupbar.gradient,
            height     = chrome.groupbar.height,
            rounding   = chrome.groupbar.radius,
            text_color = palette.chrome.groupbar.text_color,
        },
    },

    misc = {
        -- An empty string means the Hyprland default font.
        font_family = chrome.font_family ~= "" and chrome.font_family or nil,
    },
})
