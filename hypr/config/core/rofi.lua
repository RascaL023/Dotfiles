-- =========================================================================
-- rofi.lua -- animasi khusus untuk rofi pemilih wallpaper
-- =========================================================================
-- Semua varian rofi memakai namespace layer yang SAMA, "rofi": sudah diuji
-- untuk `-dmenu`, `-name`, `-window-title`, `-normal-window`, dan `-theme
-- .../wallpaper.rasi`. Layer rule di 0.56 hanya bisa match `namespace` (itu
-- satu-satunya properti match), dan `hyprctl layerrules` tidak ada, jadi
-- varian tidak bisa dibedakan dari config statis.
--
-- Jalan yang dipakai di sini (semua diukur dari tangkapan frame, bukan asumsi):
--   * rule bernama dibuat sekali dalam keadaan MATI -- selama mati, rule
--     `rofi` biasa di hyprland.lua (slide bottom) yang berlaku;
--   * dinyalakan tepat sebelum rofi diluncurkan; ia menang atas rule biasa
--     karena dibuat setelahnya (yang terakhir dibuat = yang dipakai);
--   * dimatikan lagi saat layer rofi ditutup (event `layer.closed` membawa
--     namespace), jadi rofi apps kembali slide bottom.
-- Hasilnya nol proses tambahan dan tidak ada rule yang menumpuk.
--
-- Yang TIDAK dipakai karena sudah dicoba dan gagal/mahal:
--   * `hl.on("layer.opened")` + membuat rule di dalamnya: event-nya memang
--     jalan (terbukti), tapi rule-nya terlambat -- animasi tetap slide.
--   * `hyprctl eval` + `hyprctl reload` dari skrip: 2 proses tambahan per
--     buka pemilih, padahal handle rule bisa dipegang dari Lua.
--   * `-namespace` di rofi / properti match lain: tidak ada di 0.56.2.
--   * `hyprctl eval` tidak memvalidasi string style (typo tetap dijawab ok).
-- =========================================================================

local home = os.getenv("HOME") or ""
local rofi = {}

-- Sengaja dibuat setelah rule `rofi` di hyprland.lua: urutan pembuatan
-- menentukan pemenang saat dua rule cocok dengan layer yang sama.
rofi.wall_fade = hl.layer_rule({
    name      = "rofi-wallpaper-fade",
    match     = { namespace = "rofi" },
    animation = "fade",
})
rofi.wall_fade:set_enabled(false)

hl.on("layer.closed", function(layer)
    if layer ~= nil and layer.namespace == "rofi" then
        rofi.wall_fade:set_enabled(false)
    end
end)

-- Dipakai bind SUPER + W (keybinding.lua): nyalakan animasi pemilih wallpaper
-- dulu, baru jalankan skripnya. Urutannya penting -- `set_enabled` berlaku
-- seketika, sedangkan rofi butuh ~300 ms sebelum layer-nya dipetakan.
function rofi.pick_wallpaper()
    rofi.wall_fade:set_enabled(true)
    hl.exec_cmd(home .. "/.config/hypr/sources/scripts/nextwall.sh")
end

return rofi
