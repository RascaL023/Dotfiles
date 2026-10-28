-- theme.lua -- modul tema Hyprland 0.56 (config Lua).
--
-- Sumber nilai, berurutan (yang belakangan menimpa yang sebelumnya):
--   1. tabel default di bawah
--   2. ~/.myenv/theme/current/hypr/theme.lua -> hasil matugen
--
-- Berkas hasil matugen murni data (`return { ... }`), dimuat dengan env kosong
-- sehingga tidak bisa memanggil fungsi apa pun. Field yang hilang memakai
-- default, jadi tema lama/baru tetap jalan; itulah sebabnya tema wallpaper
-- (Flow A) cukup menghasilkan warna, sedangkan tema blueprint (Flow B) juga
-- menghasilkan bagian "rasa" dari objek `feel` di blueprint-nya.
--
-- Modul ini tidak memanggil hl.* sama sekali. Semua pemetaan field -> opsi
-- Hyprland selesai di sini, hasilnya berupa data siap pakai:
--
--   theme.hypr        -> payload hl.config (general/decorations/group/misc)
--   theme.curves      -> payload hl.curve
--   theme.animations  -> daftar payload hl.animation
--   theme.layer_blur  -> dipakai layer rule di hyprland.lua
--
-- Nilai dijepit ke rentang aman supaya tema buatan tangan tidak membuat
-- desktop tak terpakai; alasan kegagalan ditulis ke stderr.

local Theme = {
    shape = {
        radius               = 4,
        rounding_power       = 2.0,
        border               = 2,
        gaps_in              = 4,
        gaps_out             = 7,
        border_angle         = 45,
        border_part_of_window = false,
        border_active        = "rgba(8ba4b0ee)",
        border_active2       = "rgba(a292a3ee)",
        border_inactive      = "rgba(0d0c0cee)",
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
            power   = 10,
            color   = "rgba(0d0c0cee)",
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
        layer_blur     = true,
        nogroup_border = "rgba(39383699)",
        font_family    = "",
        groupbar = {
            enabled    = false,
            gradient   = true,
            height     = 14,
            radius     = 4,
            text_color = "rgba(0d0c0cee)",
        },
    },
}

-- Batas aman: [min, max]. Hanya berlaku untuk nilai bertipe number.
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
    { "material.shadow.power",       1,   10  },
    { "motion.speed",                0.4, 2.5 },
    { "motion.layers_speed",         0.4, 2.5 },
    { "chrome.groupbar.height",      0,   40  },
    { "chrome.groupbar.radius",      0,   24  },
}

-- Nama gaya animasi yang dikenal Hyprland 0.56; selain ini diabaikan.
local styles = {
    gnomed = true, popin = true, slide = true, slidefade = true,
    slidevert = true, fade = true, slidefadevert = true,
}

local default_curve = { 0.05, 0.9, 0.1, 1.05 }

local function warn(message)
    if io and io.stderr then
        io.stderr:write("[theme] " .. message .. "\n")
        io.stderr:flush()
    end
end

local function merge(base, extra)
    for key, value in pairs(extra) do
        if type(value) == "table" and type(base[key]) == "table" then
            merge(base[key], value)
        else
            base[key] = value
        end
    end
end

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

-- $MYENV belum tentu sudah di-set saat modul ini di-require, jadi urutannya
-- MYENV dulu (kalau ada), lalu lokasi default berbasis $HOME.
local function base_dir()
    local myenv = os.getenv("MYENV")
    if myenv and myenv ~= "" then
        return myenv .. "/theme/current/hypr"
    end

    local home = os.getenv("HOME") or ""
    if home ~= "" then
        return home .. "/.myenv/theme/current/hypr"
    end

    return nil
end

-- Mengembalikan (data, ada). `ada` membedakan "berkas tidak ada" dari
-- "berkas ada tapi rusak", supaya pesan stderr tidak menyesatkan.
local function load_data(path, label)
    local handle = io.open(path, "r")
    if not handle then
        return nil, false
    end

    local source = handle:read("*a")
    handle:close()

    -- Mode "t" + env kosong: berkas hanya boleh mengembalikan tabel.
    local chunk = load(source, "@" .. path, "t", {})
    if not chunk then
        warn(label .. ": " .. path .. " gagal dikompilasi")
        return nil, true
    end

    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
        warn(label .. ": " .. path .. " tidak mengembalikan tabel")
        return nil, true
    end

    return data, true
end

local dir = base_dir()
if not dir then
    warn("HOME dan MYENV kosong; memakai nilai default")
else
    local path = dir .. "/theme.lua"
    local data, exists = load_data(path, "tema")

    if not data then
        if exists then
            warn("memakai nilai default karena theme.lua gagal dimuat")
        else
            warn("theme.lua tidak ditemukan di " .. dir .. "; memakai nilai default")
        end
    else
        merge(Theme, data)
    end
end

for _, limit in ipairs(limits) do
    clamp_field(Theme, limit[1], limit[2], limit[3])
end

if type(Theme.shape.border_angle) ~= "number" then
    Theme.shape.border_angle = 45
end

for _, field in ipairs({ "style_in", "style_out", "style_ws_in", "style_ws_out" }) do
    local value = Theme.motion[field]
    if not (type(value) == "string" and styles[value]) then
        warn("motion." .. field .. " tidak dikenal; memakai 'fade'")
        Theme.motion[field] = "fade"
    end
end

if type(Theme.motion.curve) ~= "table" or #Theme.motion.curve ~= 4 then
    warn("motion.curve harus 4 angka; memakai default")
    Theme.motion.curve = default_curve
end

-- ===========================================================================
-- Data siap pakai untuk hl.*
-- ===========================================================================
-- Dari sini ke bawah hanya pemetaan: nama field tema -> nama opsi Hyprland.
-- hyprland.lua tidak perlu tahu bentuk fieldnya.

local shape   = Theme.shape
local surface = Theme.surface
local blur    = Theme.material.blur
local shadow  = Theme.material.shadow
local motion  = Theme.motion
local chrome  = Theme.chrome
local curve   = motion.curve

Theme.hypr = {
    general = {
        gaps_in     = shape.gaps_in,
        gaps_out    = shape.gaps_out,
        border_size = shape.border,

        col = {
            active_border = {
                colors = { shape.border_active, shape.border_active2 },
                angle  = shape.border_angle
            },
            inactive_border = shape.border_inactive,
            nogroup_border  = chrome.nogroup_border,
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
            color        = shadow.color,
            sharp        = shadow.sharp,
        },
    },

    -- Tab/group: border & groupbar ikut tema (default: groupbar mati).
    group = {
        col = {
            border_active   = shape.border_active,
            border_inactive = shape.border_inactive,
        },
        groupbar = {
            enabled    = chrome.groupbar.enabled,
            gradients  = chrome.groupbar.gradient,
            height     = chrome.groupbar.height,
            rounding   = chrome.groupbar.radius,
            text_color = chrome.groupbar.text_color,
        },
    },

    misc = {
        -- Biarkan string kosong = pakai font default Hyprland.
        font_family = chrome.font_family ~= "" and chrome.font_family or nil,
    },
}

Theme.curves = {
    theme = {
        type   = "bezier",
        points = { { curve[1], curve[2] }, { curve[3], curve[4] } },
    },
}

-- Kecepatan = angka dasar Hyprland x pengali tema (motion.speed /
-- motion.layers_speed), jadi satu angka tema menggeser seluruh rasa animasi.
Theme.animations = {
    { leaf = "global", enabled = true, speed = 10 * motion.speed, bezier = "default" },

    { leaf = "windows",     enabled = true, speed = 7 * motion.speed, bezier = "theme" },
    { leaf = "windowsMove", enabled = true, speed = 3 * motion.speed, bezier = "theme" },
    { leaf = "windowsOut",  enabled = true, speed = 7 * motion.speed, bezier = "theme", style = motion.style_out },
    { leaf = "windowsIn",   enabled = true, speed = 5 * motion.speed, bezier = "theme", style = motion.style_in },

    { leaf = "border",      enabled = true, speed = 10 * motion.speed, bezier = "default" },
    { leaf = "borderangle", enabled = true, speed = 50 * motion.speed, bezier = "default" },

    { leaf = "layers", enabled = true, speed = 4 * motion.layers_speed, bezier = "theme" },

    { leaf = "workspacesIn",  enabled = true, speed = 6 * motion.speed, bezier = "theme",   style = motion.style_ws_in },
    { leaf = "workspacesOut", enabled = true, speed = 3 * motion.speed, bezier = "default", style = motion.style_ws_out },
}

-- Tema "flat" mematikan blur layer supaya bar/launcher tampil solid.
Theme.layer_blur = chrome.layer_blur

return Theme
