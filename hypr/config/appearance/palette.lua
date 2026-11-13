-- Colours only. The palette store renders
-- ~/.myenv/theme/palette/current/hypr/theme.lua from
-- matugen/core/palette/<palette>/template/hypr.lua.
--
-- Numbers and booleans (radius, gaps, opacity, blur, shadow, motion, layer
-- blur) are NOT palette data: they belong to the feel store and are loaded by
-- config/appearance/feel.lua. Never add a feel value here — one value, one
-- owner. A palette render that still carries old feel numbers is harmless:
-- look.lua and motion.lua read geometry from the feel module only.

local store = require("config.appearance.store")

local Palette = {
    shape = {
        border_active   = "rgba(8ba4b0ee)",
        border_active2  = "rgba(a292a3ee)",
        border_inactive = "rgba(0d0c0cee)",
    },

    material = {
        shadow = {
            color = "rgba(0d0c0cee)",
        },
    },

    chrome = {
        nogroup_border = "rgba(39383699)",
        groupbar = {
            text_color = "rgba(0d0c0cee)",
        },
    },
}

local dir = store.dir("palette")
if not dir then
    store.warn("HOME dan MYENV kosong; memakai warna default")
else
    local path = dir .. "/theme.lua"
    local data, exists = store.load(path, "tema")

    if not data then
        if exists then
            store.warn("memakai warna default karena theme.lua gagal dimuat")
        else
            store.warn("theme.lua tidak ditemukan di " .. dir .. "; memakai warna default")
        end
    else
        store.merge(Palette, data)
    end
end

return Palette
