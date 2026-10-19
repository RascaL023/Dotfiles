-- theme.lua -- pembaca theme.conf untuk Hyprland 0.55+ (config Lua).
--
-- Kenapa ada file ini: sejak Hyprland 0.55 config-nya Lua, jadi `source = ...`
-- ala hyprlang sudah tidak ada. File tema di
--   ~/.myenv/theme/current/hypr/theme.conf
-- masih berformat lama (`$nama = nilai`), jadi isinya dibaca di sini lalu
-- diumpankan ke hl.config() di hyprland.lua.
--
-- Alur ganti tema tetap sama seperti dulu: theme.conf ditulis ulang oleh
-- Theme-Engine / theme-switcher, lalu `hyprctl reload` memuat nilainya.
-- Kalau file temanya tidak ada, nilai default di bawah yang dipakai.

local Theme = {
    gaps_in         = 4,
    gaps_out        = 7,
    border_size     = 1,
    border_active   = "rgba(8ba4b0ee)",
    border_active2  = "rgba(a292a3ee)",
    border_angle    = 45,
    border_inactive = "rgba(0d0c0cee)",

    blur            = true,
    blur_size       = 4,
    blur_passes     = 4,
    rounding        = 4,
    shadow          = true,
    shadow_range    = 20,
    shadow_power    = 10,
    shadow_color    = "rgba(0d0c0cee)",

    foot_opacity    = 0.9,
}

-- nama variabel di theme.conf -> nama yang dipakai di Lua.
local keys = {
    gapsIn            = "gaps_in",
    gapsOut           = "gaps_out",
    borderSize        = "border_size",
    colActiveBorder1  = "border_active",
    colActiveBorder2  = "border_active2",
    colActiveBorderDeg = "border_angle",
    colInactiveBorder = "border_inactive",

    blur              = "blur",
    blurSize          = "blur_size",
    blurPasses        = "blur_passes",
    rounding          = "rounding",
    shadow            = "shadow",
    shadowRange       = "shadow_range",
    shadowRenderPower = "shadow_power",
    shadowColor       = "shadow_color",

    footOpacity       = "foot_opacity",
}

local function read_theme()
    local home = os.getenv("HOME") or ""
    local myenv = os.getenv("MYENV") or (home .. "/.myenv")

    local candidates = { myenv .. "/theme/current/hypr/theme.conf" }
    if home ~= "" then
        candidates[#candidates + 1] = home .. "/.myenv/theme/current/hypr/theme.conf"
    end

    for _, path in ipairs(candidates) do
        local handle = io.open(path, "r")
        if handle then
            local data = handle:read("*a")
            handle:close()
            return data
        end
    end

    return nil
end

-- "true"/"false" -> bool, "45deg"/"4" -> angka, sisanya -> string apa adanya.
local function typed(value)
    local text = value:gsub("%s+#.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end

    local lowered = text:lower()
    if lowered == "true" then return true end
    if lowered == "false" then return false end

    local number = text:match("^(-?%d+%.?%d*)%s*deg$") or text:match("^(-?%d+%.?%d*)$")
    if number then return tonumber(number) end

    return text
end

local data = read_theme()
if data then
    for line in data:gmatch("[^\r\n]+") do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.+)$")
        local key = name and keys[name]
        if key then
            local parsed = typed(value)
            if parsed ~= nil then Theme[key] = parsed end
        end
    end
end

return Theme
