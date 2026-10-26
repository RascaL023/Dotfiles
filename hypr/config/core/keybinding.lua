-- =========================================================================
-- keybinding.lua -- semua bind Hyprland 0.56 (format Lua)
-- =========================================================================
-- Gabungan dari config hyprlang lama (sudah dipindah ke hypr/old/):
--   * BASIC / TOOLS / WORKSPACE / WINDOW / RESIZE / MEDIA / SCREENSHOT
--       <- old/conf/binds.conf
--   * SCROLLING (ala niri) <- old/conf/hyprscroll.conf
--
-- Catatan breaking change v53 -> v56 yang berpengaruh ke file ini:
--   * Tidak ada lagi `bind = ...` ala hyprlang; semuanya hl.bind().
--   * Pesan layout tidak lagi `layoutmsg`, tapi hl.dsp.layout(teks).
--   * Plugin hyprscrolling kini jadi layout bawaan "scrolling" (opsi
--     scrolling.*, lihat hyprland.lua). Plugin hyprexpo tidak ada di build ini.
--   * Daftar pesan layout scrolling 0.56 (dari ScrollingAlgorithm.cpp,
--     semuanya sudah diuji langsung di compositor):
--       move +col | -col | <±piksel>      -- geser tape / gulir satu kolom
--       colresize <nilai> | +x | -x | +conf | -conf | all <nilai>
--       fit active | visible | all | toend | tobeg | expand
--       fit_into_view | center | inhibit_scroll [bool]
--       focus u|d|l|r                     -- u/d dalam kolom, l/r antar kolom
--       promote | expel | consume | consume_or_expel prev|next
--       swapcol l|r
--     Yang TIDAK ada di layout scrolling (jangan dipakai di sana):
--     togglesplit, preselect, movetoroot, splitratio, swapsplit (itu pesan
--     dwindle), serta focus-column-first/last & cycle-preset-window-height ala
--     niri.
--
-- Perbaikan dari config lama:
--   * SUPER + Q dulu terdaftar dua kali (killactive + window.close).
--   * SUPER + SHIFT + P dulu dipakai dua kali (togglesplit dan mpc toggle);
--     musik dipindah ke SUPER + SHIFT + M.
--   * Toggle layout dulu lewat `hyprctl getoption ... | grep`; sekarang pakai
--     hl.get_config() supaya tidak ada proses eksternal di dalam bind.
--   * Tombol volume/brightness dulu memakai `code:122`/`code:232` (keycode
--     mentah) + notify-send. Keycode mentah bermasalah di config Lua, jadi
--     sekarang memakai nama keysym XF86* dan OSD eww yang sama dengan niri.
--   * Alt+Tab dulu `hyprexpo:expo toggle`; plugin itu tidak ada di build ini,
--     jadi diganti siklus jendela.
--   * `{ mouse = true }` pada bind mouse: DIBUANG. Di 0.56.2 opsi itu belum
--     dipakai lapisan Lua (bind tetap terdaftar `mouse = false`), dan kalau
--     suatu saat diaktifkan, Hyprland akan mencarikan dispatcher "mouse" ala
--     bindm lama dan bind drag/resize-nya justru rusak. Bind `mouse:N` sudah
--     dicocokkan otomatis lewat nama tombolnya.
-- =========================================================================

local mod  = "SUPER"
local home = os.getenv("HOME") or ""

-- Pembungkus singkat supaya baris bind tetap terbaca.
local function exec(cmd)      return hl.dsp.exec_cmd(cmd) end
local function layout(msg)    return hl.dsp.layout(msg) end
local function script(name)   return hl.dsp.exec_cmd(home .. "/.config/hypr/sources/scripts/" .. name) end
local function osd(action)    return hl.dsp.exec_cmd(home .. "/.config/eww/scripts/osd.sh " .. action) end

-- ------------------------------------------------------------------ layout --
-- Bind di bawah ini banyak yang cuma berlaku di layout "scrolling". Untuk
-- yang perilakunya beda antar layout, dispatcher dipilih saat tombol ditekan
-- (bukan saat config dibaca) lewat hl.get_active_workspace().tiled_layout.
local function tiled_layout()
    local ws = hl.get_active_workspace()
    return ws and ws.tiled_layout or "dwindle"
end

local function layout_switch(in_scrolling, otherwise)
    return function()
        hl.dispatch(tiled_layout() == "scrolling" and in_scrolling() or otherwise())
    end
end

-- =========================================================
-- BASIC
-- =========================================================

hl.bind(mod .. " + Q",              hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + SPACE",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mod .. " + CTRL + L",       exec("hyprlock"))

-- togglesplit adalah pesan layout dwindle; di layout scrolling hanya memicu
-- peringatan "no such layoutmsg for scrolling", jadi dijaga.
hl.bind(mod .. " + SHIFT + P", layout_switch(
    function() return hl.dsp.no_op() end,
    function() return layout("togglesplit") end))

-- =========================================================
-- TOOLS
-- =========================================================

hl.bind(mod .. " + B",              exec("firefox"))
hl.bind(mod .. " + RETURN",         exec("kitty"))
hl.bind(mod .. " + SHIFT + RETURN", exec("foot"))
hl.bind(mod .. " + ALT + RETURN",   exec("kitty --class kitty-float"))
hl.bind(mod .. " + CTRL + RETURN",  exec("alacritty"))
hl.bind(mod .. " + CTRL + T",       exec("kitty --class ttyper -e ttyper"))
hl.bind(mod .. " + E",              exec("nemo"))
hl.bind(mod .. " + SHIFT + E",      exec("kitty -e yazi"))

-- Skrip (semuanya di hypr/sources/scripts/)
hl.bind(mod .. " + C",              script("wifi-menu.sh"))
hl.bind(mod .. " + O",              script("waybar-toggle.sh"))
hl.bind(mod .. " + ESCAPE",         script("wlogout-toggle.sh"))
hl.bind(mod .. " + SPACE",          script("rofi-toggle.sh"))
hl.bind(mod .. " + I",              script("idle-toggle.sh"))
-- Pemilih wallpaper: rofi biasa tetap slide bottom (rule `rofi` di
-- hyprland.lua), khusus yang ini memakai fade lewat rule bernama di rofi.lua.
hl.bind(mod .. " + W",              function() rofi.pick_wallpaper() end)
hl.bind(mod .. " + T",              exec(home .. "/.myenv/script/theme/theme-picker.sh"))
hl.bind(mod .. " + SHIFT + N",      script("bluelight-toggle.sh"))

-- eww
hl.bind(mod .. " + X",              exec("eww open --toggle profile"))
hl.bind(mod .. " + D",              exec("eww open --toggle distro"))
hl.bind(mod .. " + A",              exec(home .. "/.config/eww/scripts/ctl.sh toggle"))
hl.bind(mod .. " + CTRL + X",       exec("pkill eww; eww daemon --force-wayland"))

-- hyprpicker (exec_cmd sudah menjalankan lewat `sh -c`, jadi tidak perlu sh -c lagi)
hl.bind(mod .. " + CTRL + P", exec([[hyprpicker -a | wl-copy && notify-send "Color picked!" "$(wl-paste)"]]))
hl.bind(mod .. " + N",              exec("swaync-client -t"))

-- =========================================================
-- SCREENSHOTS
-- =========================================================

hl.bind("SUPER + ALT + PRINT", exec([[grim -o LVDS-1 "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" && notify-send -t 2000 "Screenshot" "Successfully took fullscreen screenshot!"]]))
hl.bind("SUPER + PRINT",       exec([[grim -g "$(slurp)" "$HOME/Pictures/Screenshots/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" && notify-send -t 2000 "Screenshot" "Successfully took partial screenshot!"]]))

-- =========================================================
-- WORKSPACES
-- =========================================================

for i = 1, 6 do
    -- Pindah workspace
    hl.bind(mod .. " + " .. i,          hl.dsp.focus({ workspace = i }))
    -- Pindah ke workspace tanpa ikut fokus
    hl.bind(mod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i, follow = false }))
    -- Pindah ke workspace sambil ikut fokus
    hl.bind("ALT + SHIFT + " .. i,      hl.dsp.window.move({ workspace = i, follow = true }))
end

local workspace_keys = { J = 1, K = 2, L = 3, U = 4, I = 5, O = 6 }

for key, workspace in pairs(workspace_keys) do
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = false }))
    hl.bind("ALT + SHIFT + " .. key,     hl.dsp.window.move({ workspace = workspace, follow = true }))
end

-- Workspace sebelum / sesudah yang sedang dipakai
hl.bind("CTRL + ALT + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + LEFT",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + L",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + H",     hl.dsp.focus({ workspace = "e-1" }))

-- Dulu Alt+Tab = hyprexpo (plugin tidak ada di build ini) -> siklus jendela.
hl.bind("ALT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- =========================================================
-- FOCUS
-- =========================================================
-- Dispatcher ini sudah sadar layout: di layout scrolling kiri/kanan berpindah
-- KOLOM dan atas/bawah berpindah jendela DI DALAM kolom; di dwindle sama
-- seperti dulu (movefocus). Sudah diuji langsung di kedua layout.

local focus_keys = {
    H = "left",  L = "right", K = "up",  J = "down",
    LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down",
}

for key, direction in pairs(focus_keys) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

-- =========================================================
-- PINDAH JENDELA (ala niri: Mod+Ctrl+arah)
-- =========================================================
-- niri:  move-column-left/right  -> geser KOLOM dalam urutan  = swapcol l/r
--        move-window-up/down     -> geser JENDELA dalam kolom = window.move
-- Di dwindle padanannya movewindow biasa.

hl.bind(mod .. " + CTRL + LEFT",  layout_switch(
    function() return layout("swapcol l") end,
    function() return hl.dsp.window.move({ direction = "left" }) end))
hl.bind(mod .. " + CTRL + RIGHT", layout_switch(
    function() return layout("swapcol r") end,
    function() return hl.dsp.window.move({ direction = "right" }) end))
hl.bind(mod .. " + CTRL + UP",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- =========================================================
-- SCROLLING (ala niri)
-- =========================================================
-- Peta tombol niri/conf/keybinds/window.kdl -> layout scrolling 0.56:
--
--   niri                              hyprland 0.56        (kolom kanan
--   --------------------------------  -------------------  semua pesan
--   focus-column-left/right           fokus direction l/r  layout di bawah
--   focus-window-up/down              fokus direction u/d
--   move-column-left/right            swapcol l / swapcol r
--   move-window-up/down               window.move direction u/d
--   switch-preset-column-width (-back) colresize +conf / -conf
--   set-column-width "(+/-)N%"        colresize "+0.1" / "-0.05"
--   set-window-height "(+/-)N%"       window.resize y relatif
--   consume-window-into-column        consume
--   expel-window-from-column          expel
--   consume-or-expel-window-left/right consume_or_expel prev / next
--   maximize-column                   fit active
--   maximize-window-to-edges          window.fullscreen maximized
--   fullscreen-window                 window.fullscreen fullscreen
--   center-visible-columns            center
--   expand-column-to-available-width  fit expand
--   toggle-column-tabbed-display      group.toggle()   (SUPER+ALT+W)
--   Mod+Wheel                         fokus workspace e-1/e+1
--   Mod+Shift+Wheel                   fokus kolom kiri/kanan
--   Mod+Ctrl+Wheel                    pindah jendela ke workspace tetangga
--   Mod+Ctrl+Shift+Wheel              swapcol l/r
--
-- Tidak ada padanannya di 0.56 (jadi tidak dibuat): focus-column-first/last,
-- move-column-to-first/last, cycle-preset-window-height, reset-window-height.
-- Bind kolom di bawah (R, SHIFT+R, MINUS, EQUAL, COMMA, PERIOD, BRACKET*,
-- BACKSLASH) cuma berefek di layout scrolling; di dwindle mereka hanya
-- memunculkan peringatan di log (tidak masuk hyprctl configerrors), jadi
-- dibiarkan apa adanya.

-- Lebar kolom: siklus preset 0.333 / 0.5 / 0.667 / 1.0 (niri: switch-preset-column-width).
hl.bind(mod .. " + R",         layout("colresize +conf"))
hl.bind(mod .. " + SHIFT + R", layout("colresize -conf"))

-- Lebar kolom: penyesuaian halus (niri: set-column-width).
hl.bind(mod .. " + MINUS", layout("colresize -0.05"))
hl.bind(mod .. " + EQUAL", layout("colresize +0.1"))

-- Tinggi jendela dalam kolom (niri: set-window-height). Ukuran dalam piksel,
-- sama seperti submap resize di bawah supaya terasa konsisten.
hl.bind(mod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y =  50, relative = true }))
hl.bind(mod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))

-- Jendela antar kolom (niri: consume / expel).
hl.bind(mod .. " + COMMA",        layout("consume"))
hl.bind(mod .. " + PERIOD",       layout("expel"))
hl.bind(mod .. " + BRACKETLEFT",  layout("consume_or_expel prev"))
hl.bind(mod .. " + BRACKETRIGHT", layout("consume_or_expel next"))

-- Ukuran / posisi jendela.
-- niri: Mod+F maximize-column, Mod+Shift+F fullscreen, Mod+M maximize ke tepi.
-- Di scrolling "maximize-column" = lebarkan kolom terfokus; di dwindle jatuh
-- kembali ke maximize seperti config lama (SUPER + F dulu fullscreen, 0).
hl.bind(mod .. " + F", layout_switch(
    function() return layout("fit active") end,
    function() return hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }) end))
hl.bind(mod .. " + SHIFT + F",     hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + M",             hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))

-- Pusatkan / muat kolom ke layar (niri: center-visible-columns, expand-column).
hl.bind(mod .. " + BACKSLASH",        layout("center"))
hl.bind(mod .. " + SHIFT + BACKSLASH", layout("fit_into_view"))
hl.bind(mod .. " + ALT + BACKSLASH",   layout("fit expand"))

-- Tabbed / stacked (niri: toggle-column-tabbed-display).
hl.bind(mod .. " + ALT + W", hl.dsp.group.toggle())

-- Mouse. niri: Mod+Wheel = workspace, Mod+Shift+Wheel = kolom,
-- Mod+Ctrl+Wheel = bawa jendela ke workspace tetangga, +Shift = geser kolom.
hl.bind(mod .. " + mouse_up",           hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_down",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + CTRL + mouse_up",           hl.dsp.window.move({ workspace = "e-1", follow = true }))
hl.bind(mod .. " + CTRL + mouse_down",         hl.dsp.window.move({ workspace = "e+1", follow = true }))
hl.bind(mod .. " + CTRL + SHIFT + mouse_up",   layout("swapcol l"))
hl.bind(mod .. " + CTRL + SHIFT + mouse_down", layout("swapcol r"))

-- =========================================================
-- MOUSE
-- =========================================================

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- =========================================================
-- RESIZE (submap)
-- =========================================================
-- Dulu SUPER + R; R sekarang dipakai untuk preset lebar kolom (ala niri),
-- jadi submap resize pindah ke SUPER + ALT + R.
hl.bind(mod .. " + ALT + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
    hl.bind("L",     hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
    hl.bind("H",     hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
    hl.bind("K",     hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })
    hl.bind("J",     hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- =========================================================
-- VOLUME / BRIGHTNESS (OSD eww, sama dengan niri)
-- =========================================================

hl.bind("XF86AudioRaiseVolume",  osd("vol-up"),      { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  osd("vol-down"),    { locked = true, repeating = true })
hl.bind("XF86AudioMute",         osd("vol-mute"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      osd("mic-mute"),    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   osd("bright-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", osd("bright-down"), { locked = true, repeating = true })

-- =========================================================
-- MUSIC
-- =========================================================

-- Dulu SUPER + SHIFT + P, tetapi tombol itu sudah dipakai togglesplit.
hl.bind(mod .. " + SHIFT + M", exec("mpc toggle"))
hl.bind(mod .. " + ALT + P",   exec("pkill mpd"))

-- =========================================================
-- TOGGLE LAYOUT (dwindle <-> scrolling)
-- =========================================================

hl.bind(mod .. " + S", function()
    local current = hl.get_config("general.layout")
    hl.config({ ["general.layout"] = current == "dwindle" and "scrolling" or "dwindle" })
end)
