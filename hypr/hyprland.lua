-- =========================================================================
-- Hyprland 0.56 -- config Lua
-- =========================================================================
-- Peta migrasi dari config hyprlang lama (sudah dipindah ke hypr/old/):
--
--   old/hyprland.conf          -> MONITOR / ENV / INPUT / plugin di bawah
--   old/conf/ui.conf           -> general+decoration, ANIMATIONS, RULES
--   old/conf/source.conf       -> nilai warna/ukuran dari theme.lua
--   old/conf/autostart.conf    -> blok AUTOSTART
--   old/conf/binds.conf        -> keybinding.lua
--   old/conf/hyprscroll.conf   -> keybinding.lua bagian "SCROLLING (ala niri)"
--
-- Catatan breaking change v53 -> v56 yang berpengaruh ke config ini:
--   * hyprlang digantikan Lua. Tidak ada lagi `source = ...`, `$variable`,
--     `bind = ...`, atau blok `general { }`; semuanya jadi pemanggilan hl.*.
--   * Plugin `hyprscrolling` sekarang jadi layout bawaan bernama "scrolling"
--     (opsi `scrolling.*`, pesan lewat hl.dsp.layout()), jadi tidak perlu
--     `hyprctl plugin load` lagi.
--   * Plugin `hyprexpo` tidak ada di build ini (tidak ada libhyprexpo.so di
--     /run/current-system/sw/lib), jadi bind expo dihapus.
--   * `gestures { gesture = ... }` digantikan hl.gesture().
-- =========================================================================

local theme = require("config.core.theme")

------------------------------------------------------------------ MONITORS --
-- Dulu: monitor=,preferred,auto,1
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
-- Nilai look & feel (general.col, decoration, group, misc) dipetakan di
-- config/core/theme.lua; di sini hanya diterapkan.
hl.config(theme.hypr)

-- Sisa config yang bukan milik tema. `general.layout` aman dipisah dari
-- nilai tema di atas karena kuncinya tidak bertabrakan.
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
        -- Catatan: `dwindle.pseudotile` dari config lama sudah tidak ada di
        -- 0.56 (pseudo kini properti per-jendela, di-toggle lewat SUPER + P).
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    -- Bekas `plugin { hyprscrolling { ... } }` di old/hyprland.conf, kini
    -- layout bawaan. Nilai di bawah = default 0.56 kecuali yang ditandai;
    -- ditulis eksplisit supaya tidak ikut berubah kalau default Hyprland
    -- bergeser. Yang bertanda (niri) disamakan dengan niri/conf/layouts.
    scrolling = {
        column_width             = 0.5,     -- (niri) default-column-width proportion 0.5
        fullscreen_on_one_column = true,    -- dari config lama
        explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",  -- (niri) preset-column-widths + lebar penuh
        focus_fit_method         = 1,       -- 1 = fit (kolom digeser seperlunya, seperti niri), 0 = center
        follow_focus             = true,
        follow_min_visible       = 0.4,
        wrap_focus               = false,   -- (niri) fokus tidak memutar dari ujung ke ujung
        wrap_swapcol             = false,   -- (niri) swapcol tidak memutar
        direction                = "right",
    },

    binds = {
        -- Dulu: plugin hyprexpo yang menyembunyikan jendela fullscreen.
        -- Layout scrolling punya fullscreen-nya sendiri: tanpa opsi ini,
        -- `hl.dsp.focus({direction})` akan mencari monitor lain saat jendela
        -- fullscreen terfokus, bukan menggulir tape (lihat wiki: Scrolling
        -- layout -> Layout-Handled Fullscreen).
        movefocus_cycles_fullscreen = true,
        -- Jendela yang digeser ke atas/bawah saat sudah di ujung kolom pindah
        -- ke monitor di arah itu (niri: move-window-...-or-to-workspace-...).
        window_direction_monitor_fallback = true,
    },
})

------------------------------------------------------------ ANIMATIONS ----
-- Dulu: blok `animations { bezier = ... animation = ... }` di ui.conf.
-- Kurva, pengali kecepatan, dan gaya tiap leaf dibangun di theme.lua
-- (theme.curves + theme.animations); di sini hanya diterapkan.
hl.curve("theme", theme.curves.theme)

for _, animation in ipairs(theme.animations) do
    hl.animation(animation)
end

------------------------------------------------------------ AUTOSTART ----
-- `hl.exec_cmd()` sudah asinkron, jadi tidak perlu `& disown`.
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("eww daemon --force-wayland")
    hl.exec_cmd("swaync")
    hl.exec_cmd("$HOME/.config/hypr/sources/scripts/waybar-toggle.sh")
end)

------------------------------------------------------------- GESTURES ----
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Tambahan ala niri: geser 3 jari vertikal menggulir tape layout scrolling.
hl.gesture({ fingers = 3, direction = "vertical", action = "scroll_move" })

---------------------------------------------------- WINDOW / LAYER RULES --
-- Opacity terminal dari tema (surface.terminal_opacity).
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

-- `theme.layer_blur` memutuskan apakah layer ikut diburamkan: tema "flat"
-- mematikan ini supaya bar/launcher tampil solid.
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
require("config.core.keybinding")
