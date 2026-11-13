-- Look & feel numbers and booleans, never colours. The feel store renders
-- ~/.myenv/theme/feel/current/hypr/feel.lua from
-- matugen/core/feel/profiles/<profile>/hypr.json, per WM.
--
-- This module owns defaults, safe ranges and validation so a hand-made or
-- stale render cannot wreck the session. Colours come from
-- config/appearance/palette.lua; look.lua and motion.lua combine the two.

local store = require("config.appearance.store")

local Feel = {
    shape = {
        radius                = 4,
        rounding_power        = 2.0,
        border                = 2,
        gaps_in               = 4,
        gaps_out              = 7,
        border_angle          = 45,
        border_part_of_window = false,
    },

    surface = {
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,
        dim_inactive       = false,
        dim_strength       = 0.0,
        dim_around         = 0.0,
        terminal_opacity   = 0.9,
    },

    material = {
        blur = {
            enabled           = true,
            size              = 4,
            passes            = 4,
            noise             = 0.0,
            contrast          = 1.0,
            brightness        = 1.0,
            vibrancy          = 0.0,
            vibrancy_darkness = 0.0,
            xray              = false,
            popups            = false,
            ignore_opacity    = true,
            new_optimizations = true,
        },
        shadow = {
            enabled = true,
            range   = 20,
            power   = 4,
            sharp   = false,
        },
    },

    motion = {
        speed        = 1.0,
        curve        = { 0.05, 0.9, 0.1, 1.05 },
        style_in     = "gnomed",
        style_out    = "slide",
        style_ws_in  = "slidefade",
        style_ws_out = "slidevert",
        layers_speed = 1.0,
    },

    chrome = {
        layer_blur  = true,
        font_family = "",
        groupbar = {
            enabled  = false,
            gradient = true,
            height   = 14,
            radius   = 4,
        },
    },
}

-- Safe ranges: [min, max], numbers only.
local limits = {
    { "shape.radius",                0,   24  },
    { "shape.rounding_power",        1.0, 8.0 },
    { "shape.border",                0,   6   },
    { "shape.gaps_in",               0,   30  },
    { "shape.gaps_out",              0,   60  },
    { "shape.border_angle",          -360, 360 },
    { "surface.active_opacity",      0.5, 1.0 },
    { "surface.inactive_opacity",    0.5, 1.0 },
    { "surface.fullscreen_opacity",  0.5, 1.0 },
    { "surface.dim_strength",        0.0, 1.0 },
    { "surface.dim_around",          0.0, 1.0 },
    { "surface.terminal_opacity",    0.5, 1.0 },
    { "material.blur.size",          1,   16  },
    { "material.blur.passes",        1,   6   },
    { "material.blur.noise",         0.0, 0.2 },
    { "material.blur.contrast",      0.5, 2.0 },
    { "material.blur.brightness",    0.5, 2.0 },
    { "material.blur.vibrancy",      0.0, 1.0 },
    { "material.blur.vibrancy_darkness", 0.0, 1.0 },
    { "material.shadow.range",       0,   60  },
    -- Hyprland 0.57 menolak render_power > 4 (0.56 masih menerima 10).
    { "material.shadow.power",       1,   4   },
    { "motion.speed",                0.4, 2.5 },
    { "motion.layers_speed",         0.4, 2.5 },
    { "chrome.groupbar.height",      0,   40  },
    { "chrome.groupbar.radius",      0,   24  },
}

-- Animation styles known to 0.56; anything else is replaced.
local styles = {
    gnomed = true, popin = true, slide = true, slidefade = true,
    slidevert = true, fade = true, slidefadevert = true,
}

local default_curve = { 0.05, 0.9, 0.1, 1.05 }

local function clamp_field(theme, path, minimum, maximum)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end

    local node = theme
    for i = 1, #parts - 1 do
        node = node[parts[i]]
        if type(node) ~= "table" then
            return
        end
    end

    local key = parts[#parts]
    local value = node[key]
    if type(value) == "number" then
        if value < minimum then
            node[key] = minimum
        elseif value > maximum then
            node[key] = maximum
        end
    end
end

local dir = store.dir("feel")
if not dir then
    store.warn("HOME dan MYENV kosong; feel memakai default")
else
    local path = dir .. "/feel.lua"
    local feel, exists = store.load(path, "feel")

    if not feel then
        if exists then
            store.warn("memakai default rasa karena feel.lua gagal dimuat")
        else
            store.warn("feel.lua tidak ditemukan di " .. path .. "; memakai default rasa")
        end
    else
        store.merge(Feel, feel)
    end
end

for _, limit in ipairs(limits) do
    clamp_field(Feel, limit[1], limit[2], limit[3])
end

if type(Feel.shape.border_angle) ~= "number" then
    Feel.shape.border_angle = 45
end

for _, field in ipairs({ "style_in", "style_out", "style_ws_in", "style_ws_out" }) do
    local value = Feel.motion[field]
    if not (type(value) == "string" and styles[value]) then
        store.warn("motion." .. field .. " tidak dikenal; memakai 'fade'")
        Feel.motion[field] = "fade"
    end
end

if type(Feel.motion.curve) ~= "table" or #Feel.motion.curve ~= 4 then
    store.warn("motion.curve harus 4 angka; memakai default")
    Feel.motion.curve = default_curve
end

return Feel
