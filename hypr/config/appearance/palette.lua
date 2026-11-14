-- Colours only; numbers and booleans live in config.appearance.feel.

local store = require("config.appearance.store")

local defaults = {
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

local data

local dir = store.dir("palette")
if not dir then
    store.warn("HOME dan MYENV kosong; memakai warna default")
else
    local path = dir .. "/theme.lua"
    local exists
    data, exists = store.load(path, "tema")

    if not data then
        if exists then
            store.warn("memakai warna default karena theme.lua gagal dimuat")
        else
            store.warn("theme.lua tidak ditemukan di " .. dir .. "; memakai warna default")
        end
    end
end

return store.overlay(defaults, data)
