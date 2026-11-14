# Rencana: fitur Hyprland 0.57 & migrasi dari 0.56

> Index repo: [`../../README.md`](../../README.md) · aturan kerja:
> [`../../AGENTS.md`](../../AGENTS.md)
>
> **Status: RENCANA / BACKLOG.** Tidak ada satu pun fitur di dokumen ini yang
> aktif di config sekarang. Semuanya opsional, ditulis lengkap supaya bisa
> dipasang kapan saja tanpa riset ulang.

Diverifikasi terhadap **Hyprland 0.57.1** (branch `v0.57.1-b`, commit `acc1aa0b`,
build 2026-11-03, NixOS). Terakhir diverifikasi: **2026-11-13**.

---

## 0. Migrasi 0.56 → 0.57 (breaking changes + yang sudah diterapkan)

0.57 menghapus dukungan `hyprland.conf` (PR #15539 *config: remove legacy
config support*): konfigurasi wajib Lua. Repo ini sudah Lua, jadi tidak ada
konversi — tapi jangan menambah contoh `.conf` di dokumen atau skrip.

| Perubahan | Bukti di mesin ini (0.57.1) | Status di repo |
|---|---|---|
| `hyprland.conf` dihapus | — | aman: `hypr/hyprland.lua` |
| `decoration:shadow:render_power` dibatasi **1–4** (PR #15682 *fixup shadow limits*); 0.56 menerima 10 | `getoption` → default 3, current 4, min 1, **max 4**; nilai 10 dulu membuat seluruh config ditolak (`maximum of 4`) | sudah: clamp default 4 + limit 1–4 di `config/appearance/feel.lua` |
| `misc` → kategori `layers` untuk 2 opsi (#16617) | `layers:layers_hog_keyboard_focus`, `layers:allow_new_top_layers_over_existing_fullscreen` (default `true`) | belum dipakai; jangan tulis lewat `misc:` |
| event `created` dipisah: `created_early` (sebelum setup) dan `created` (sesudahnya) (#16221) | stub memuat `workspace.created_early` **dan** `workspace.created` | nanti saat memakai event workspace |
| `misc:special_scale_factor` deprecated (#15832) | — | jangan dipakai |
| `skip_non_kms_dmabuf_formats` default `true` di 0.57.0, kembali opt-in di 0.57.1 | catatan rilis 0.57.1: *restore opt-in KMS dmabuf filtering* | tidak di-set; kalau klien EGL gagal di GPU lama, set `false` |
| `hl.bind` menolak key duplikat / argumen berlebih | `hyprctl configerrors` kosong setelah reload | bind tetap unik (sudah) |
| `hyprctl` shell completion dihapus (#16419) | — | jangan andalkan completion bawaan |
| `input:scroll_factor` batas atas 100 (default 1) | `getoption` → min 0, max 100 | tidak di-set |

Yang **tidak** berubah walau sering dikira berubah: `hyprctl layerrules` masih
`unknown request`, `hyprctl getoption animations:layers` masih `no such option`,
dan `hyprctl dispatch workspace 9` masih gagal (`')' expected near '9'`) —
dispatcher tetap harus bentuk Lua (`hl.dsp.*`). Semua diuji ulang di 0.57.1.

---

## 1. Apa yang sudah dipakai vs belum

| Area | Sudah dipakai | Belum dipakai (isi dokumen ini) |
|---|---|---|
| Bind | `hl.bind`, submap, `locked`/`repeating`, layout message scrolling | `non_consuming`, `transparent`, `ignore_mods`, `long_press`, `submap_universal`, `click`/`drag`, `device`, `binds.drag_center_window` |
| Rule | `window_rule` statis (foot/codium/ttyper/kitty-float), `layer_rule` (animation/blur) | rule **dinamis**, rule **bernama** + handle `set_enabled`, tag, `scrolling_width`, `no_screen_share`, `stay_focused`, `idle_inhibit`, `no_glow`, `no_wobble`, `no_xdg_drags` |
| Dekorasi | warna/gap/rounding/border/shadow dari palet + feel | `decoration.blur.variant` (0–10), `decoration.blur.proportional`, `decoration.glow.*`, `decoration.wobble.*` |
| Event | `hl.on("hyprland.start")` untuk autostart | 35 event lain (36 total di stub 0.57.1) + `hl.timer` |
| Layout | `dwindle` + `scrolling` bawaan | layout **buatan sendiri** via `hl.layout.register` |
| Gesture | 3 jari horizontal (workspace), 3 jari vertikal (`scroll_move`) | `cursor_zoom` (pinch), swipe `close`/`float`/`fullscreen`/`move`/`resize`/`special`, gesture **live Lua** |
| Workspace | hanya bind pindah workspace | `hl.workspace_rule` (termasuk `layout_opts.direction` per workspace) |
| Input | `kb_layout`, `sensitivity`, `follow_mouse` | per-device (`hl.device`), `scroll_method`, `emulate_discrete_scroll`, `natural_scroll`, `accel_profile`, `cursor.*`, `cursor.warp_on_monitor_change` |
| Monitor/render | `mode`, `position`, `scale` | `reserved`, `cm`, `icc`, `sdr_eotf`, `render.*`, `layers.*` |

## 2. Sumber kebenaran (kalau nanti mengimplementasikan)

1. **Stub resmi versi yang terpasang** — daftar API & key paling akurat:

   ```bash
   STUB="$(dirname "$(readlink -f "$(command -v Hyprland)")")/../share/hypr/stubs/hl.meta.lua"
   grep -nE "^---@field \['(scrolling|binds|group)\." "$STUB"
   ```

   Di NixOS `share/hypr/stubs/` tidak ada di `/run/current-system/sw`, tapi
   `readlink -f` di atas menyelesaikannya ke
   `/nix/store/…-hyprland-0.57.1/share/hypr/stubs/hl.meta.lua` (terbukti di mesin ini).

2. **Wiki v57** (`hyprwm/hyprland-wiki`, folder `content/`) — prosa + contoh:
   - `configuring/layouts/scrolling-layout.md`, `.../dwindle-layout.md`
   - `configuring/core/dispatchers.md`, `.../binds/gestures.md`, `.../binds/flags.md`
   - `configuring/core/rules/window-rules.md`, `.../rules/layer-rules.md`, `.../rules/workspace-rules.md`
   - `configuring/core/advanced-configuration/events.md`, `.../notifications.md`, `.../permissions.md`

   ⚠️ Wiki itu branch `main`, jadi bisa **lebih baru** dari 0.57.1. Tiga contoh
   yang dulu absen di 0.56.2 kini **ada** di 0.57.1: `config.unload`,
   `window.bell`, `window.minimize` (event), begitu juga `hl.dsp.reload_config`
   (dispatcher) dan `hl.get_devices()`. Sebaliknya `hl.reload_config` (fungsi
   biasa) **tidak ada** — diuji `hyprctl eval`: `nil`. Selalu cek nama ke stub
   dulu sebelum dipakai.

3. **Source C++** untuk perilaku layout: `src/layout/algorithm/tiled/scrolling/ScrollingAlgorithm.cpp`
   (di situ daftar pesan `layoutMsg` yang sah untuk layout scrolling).

## 3. Resep verifikasi (pakai ini setiap kali menambah fitur)

```bash
cd ~/.dotfile
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)

find hypr -name '*.lua' -exec luac -p {} +              # 1. syntax Lua
hyprctl reload                                    # 2. terapkan
hyprctl configerrors                              # 3. harus kosong
hyprctl binds -j | python3 -c 'import sys,json;print(len(json.load(sys.stdin)))'   # 4. jumlah bind
hyprctl getoption decoration:shadow:render_power   # 5. 0.57: min 1, maks 4
hyprctl descriptions | grep -A3 'wobble'           # 6. nama opsi + rentang resmi
```

Aturan pengujian yang sudah terbukti penting:

- **Jangan mengandalkan `configerrors` untuk menguji bind.** Pesan layout yang
  salah (mis. `togglesplit` di layout scrolling) hanya muncul sebagai
  `warning:` di output `hyprctl dispatch`, **tidak** tercatat di `configerrors`.
  Uji dispatcher-nya langsung: `hyprctl dispatch 'hl.dsp.layout("…")'`.
- Bind dengan key sama + modmask sama bisa diam-diam saling menimpa. Cek
  duplikat dari `hyprctl binds -j` (unik per `modmask` + `key` + `submap`).
- Uji perilaku di workspace khusus (mis. `11`) dengan jendela uji
  (`kitty --class vtest --title V1 -e sleep 3600`), lalu bersihkan dan
  kembalikan workspace + layout.
- Eksperimen cepat tanpa reload: `hyprctl eval 'hl.config({ … })'` dan
  `hyprctl eval 'error(tostring(hl.get_active_workspace().tiled_layout))'`
  (trik `error()` untuk melihat nilai balik).

---

## 4. Layout sendiri pakai Lua

**Apa:** mendaftarkan algoritma layout tiling buatan sendiri. Register →
dipakai lewat `general:layout = "<nama>"`.

**API:** `hl.layout.register(nama, { recalculate = fn, layout_msg = fn })`.
`ctx` berisi `targets`, `column(i, n)`, `row(i, n)`, `grid_cell(i, cols, rows)`,
`split(box, side, ratio)`; tiap target punya `set_box(box)` / `place(box)`.

```lua
hl.layout.register("tape", {
    recalculate = function(ctx)
        local n = #ctx.targets
        for i, target in ipairs(ctx.targets) do
            target:set_box(ctx.column(i - 1, n))
        end
    end,
    layout_msg = function(_, msg)
        if msg == "sapu" then
            return nil -- dianggap sukses
        end
        return "pesan tidak dikenal: " .. msg
    end,
})
```

**Catatan:** yang belum diuji adalah jalur aktivasi (`general:layout = "tape"`).
Uji dulu dengan `hyprctl eval` sebelum menaruhnya di config. Bisa dipakai untuk
menghilangkan perilaku scrolling bawaan yang mengganggu (mis. fokus hilang saat
`move +col` di kolom terakhir) tanpa menunggu upstream.

**Tempat implementasi:** file baru `hypr/layout.lua`, di-`require` dari
`hyprland.lua`.

## 5. Gesture trackpad lanjutan + callback Lua live

**Apa:** selain `workspace` dan `scroll_move` (yang sudah dipakai), ada 7 aksi
lain dan mode callback yang menerima data jari secara real-time.

**Action:** `close`, `cursor_zoom`, `float`, `fullscreen`, `move`, `resize`,
`scroll_move`, `special`, `workspace`, `unset`, atau fungsi Lua.
**Direction:** `swipe`, `horizontal`, `vertical`, `left`, `right`, `up`, `down`,
`pinch`, `pinchin`, `pinchout`.
**Field:** `fingers` (2–9), `mods`, `scale` (0.1–10), `disable_inhibit`,
`workspace_name`, `zoom_level`, `mode`.

```lua
-- Pinch = zoom ke kursor (padanan "zoom" di viewer)
hl.gesture({ fingers = 2, direction = "pinch", action = "cursor_zoom", zoom_level = 2 })

-- Gesture live: tiap update menerima delta.x/delta.y, scale, rotation, time_ms
local function volume(delta)
    hl.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " .. string.format("%.0f%%", math.abs(delta)) .. (delta < 0 and "-" or "+"))
end

hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = {
        update = function(e)
            volume(-0.25 * e.delta.y)
        end,
    },
})
```

**Risiko:** butuh hardware trackpad untuk verifikasi; `hl.gesture` didaftarkan
ulang tiap reload, jadi jangan menaruh gesture duplikat dengan arah/fingers sama.

## 6. Window rule: dinamis, bernama, dan tag

**Apa:** tiga kemampuan yang belum dipakai — padahal ini yang membuat rule
terasa pintar.

1. **Rule bernama punya handle** (bisa dinyalakan/dimatikan saat runtime):

```lua
local blurOff = hl.window_rule({
    name  = "no-blur-firefox",
    match = { class = "^firefox$" },
    no_blur = true,
})
blurOff:set_enabled(false)
```

2. **Rule statis tidak reaktif terhadap perubahan `title`** (efek statis
   dievaluasi sekali saat jendela dibuka). Untuk keputusan yang bergantung
   kondisi yang berubah, pakai event + dispatch:

```lua
hl.on("window.title", function(w)
    if w ~= nil and w.title == "foo" then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
    end
end)
```

3. **Tag**: `hl.dsp.window.tag({ tag = "+code" })` menaruh tag statis; rule
   `tag = "+code"` menaruh tag dinamis (diakhiri `*`). Tag bisa dipakai sebagai
   pintu masuk rule lain:

```lua
hl.bind("SUPER + CTRL + 2", hl.dsp.window.tag({ tag = "alpha_0.2" }))
hl.window_rule({ match = { tag = "alpha_0.2" }, opacity = "0.2 override" })
```

**Efek yang belum dipakai dan relevan untuk repo ini:**

| Efek | Kegunaan di setup ini |
|---|---|
| `no_screen_share` | sembunyikan jendela (mis. profil eww/waybar) saat screenshare |
| `stay_focused` | pinentry/password prompt tidak kehilangan fokus |
| `idle_inhibit` | mode `"none"`/`"always"`/`"focus"`/`"fullscreen"` — mis. video player |
| `immediate` | izinkan tearing khusus game (butuh `general.allow_tearing`) |
| `persistent_size` | jendela floating `kitty-float` mengingat ukuran terakhir |
| `border_color` + prop `focus` | warna border aktif/non-aktif per jendela — jawaban kalau nanti mau gradien `$colActiveBorder2` |
| `group` | opsi `barred`/`deny`/`invade`/`lock`/`new`/`set`/`unset` (+ `always`) |
| memakai `move`/`size` + ekspresi | `move = { "cursor_x - (window_w * 0.5)", … }` untuk menu/popup |

**Layer rule** yang belum dipakai: `no_screen_share`, `xray`, `dim_around`,
`above_lock`, `blur_popups`, `order`. `ignore_alpha` sudah dipakai: rofi (dan
swaync) memerlukannya agar blur mengikuti piksel transparan, bukan seluruh rect
layer.

## 7. Event bus + timer

**Apa:** 36 event resmi (stub 0.57.1) + `hl.timer({ timeout, type = "oneshot"|"repeat" })`.
Ini pengganti pola "socket2 + skrip polling".

**Event yang paling berguna:** `window.open` / `window.open_early` /
`window.active` (Window, alasan fokus) / `window.title` / `window.urgent` /
`window.fullscreen` / `window.close` / `window.destroy` / `window.move_to_workspace` /
`window.minimize` / `window.update_state` / `window.bell`,
`workspace.active` / `workspace.created` / `workspace.created_early` /
`workspace.removed` / `workspace.move_to_monitor` (Workspace, Monitor) /
`workspace.special_active`,
`monitor.added` / `monitor.focused` / `monitor.removed` / `monitor.layout_changed`,
`config.reloaded` / `config.props_refreshed` / `config.unload`,
`layer.opened` / `layer.closed`,
`screenshare.state` (bool, tipe, nama), `input.keyboard.key` (keycode, timestamp, status),
`keybinds.submap`, `hyprland.start` / `hyprland.shutdown`.

```lua
hl.on("workspace.active", function(ws)
    if ws ~= nil and ws.name == "6" then
        hl.dispatch(hl.dsp.layout("inhibit_scroll"))
    end
end)

hl.on("screenshare.state", function(active)
    hl.notification.create({
        text    = active and "Screenshare mulai" or "Screenshare selesai",
        timeout = 3000,
        icon    = "ok",
    })
end)
```

**Catatan:** empat event yang dulu absen kini terdaftar di stub 0.57.1:
`config.unload`, `window.bell`, `window.minimize`, `window.update_state`.
`workspace.created` juga dipisah: `created_early` jalan sebelum setup selesai,
`created` sesudahnya (PR #16221).

## 8. Workspace rule (termasuk arah scroll per workspace)

```lua
-- Workspace 2 menggulir VERTIKAL (kolom turun, bukan menyamping)
hl.workspace_rule({ workspace = "2", layout_opts = { direction = "down" } })
```

Field lain di `HL.WorkspaceRuleSpec`: `layout`, `monitor`, `persistent`,
`default`, `default_name`, `gaps_in`, `gaps_out`, `float_gaps`, `border_size`,
`no_border`, `no_rounding`, `no_shadow`, `decorate`, `animation`,
`on_created_empty`.

**Kenapa menarik:** `scrolling.direction` di config itu global; dengan rule ini
tiap workspace bisa punya gaya sendiri (mis. 1–3 horizontal, 4–6 vertikal).

## 9. Group / tabbed yang lebih pintar

Config sekarang hanya `group.toggle()`. Yang tersedia:

- Config: `group.auto_group` (jendela sejenis otomatis bergabung),
  `group.insert_after_current`, `group.drag_into_group`,
  `group.merge_groups_on_drag`, `group.merge_groups_on_groupbar`,
  `group.group_on_movetoworkspace`, `group.focus_removed_window`,
  `group.merge_floated_into_tiled_on_groupbar`.
- Dispatcher: `hl.dsp.group.toggle/next/prev/active({ index })/lock/move_window`.
  `active({ index })` cocok di-bind ke `SUPER + 1..6` saat berada di dalam grup
  (lompat tab langsung, pengganti `focus-workspace`).

## 10. Input per-device & kursor

```lua
-- Touchpad sesuai niri/config.kdl: natural-scroll + two-finger + tap
hl.device({
    name           = "elan*",
    natural_scroll = true,
    clickfinger_behavior = false,
})
```

- `HL.DeviceSpec` juga punya `kb_layout`/`kb_variant`/`kb_options`/`kb_file`
  (keyboard eksternal beda layout), `keybinds` (matikan bind khusus device),
  `accel_profile`, `left_handed`, `flip_x`/`flip_y`, `disable_while_typing`,
  `drag_lock`, `drag_3fg`, `active_area_*`.
- Global: `input.scroll_method`, `input.emulate_discrete_scroll`,
  `input.scroll_factor`, `input.force_no_accel`, `input.mouse_refocus`.
- Kursor: `cursor.inactive_timeout`, `cursor.invisible`, `cursor.hide_on_key_press`,
  `cursor.warp_on_change_workspace`, `cursor.zoom_factor` (+ `zoom_rigid`,
  `zoom_detached_camera`, `zoom_disable_aa`).

## 11. Monitor, render, misc

- **Monitor** (`HL.MonitorSpec`): `reserved`/`reserved_area` (sisakan ruang bar),
  `mirror`, `transform`, `bitdepth`, `cm`, `icc`, `sdr_eotf`, `sdrbrightness`,
  `sdrsaturation`, `sdr_min/max_luminance`, `max_luminance`, `min_luminance`.
- **Render**: `render.cm_enabled` + `render.cm_sdr_eotf` (color management),
  `render.send_content_type`, `render.direct_scanout`,
  `render.new_render_scheduling`, `render.ctm_animation`,
  `render.expand_undersized_textures`.
- **Misc**: `misc.close_special_on_empty`, `misc.disable_autoreload` (matikan
  auto-reload saat sedang mengoprek config), `misc.background_color`,
  `misc.animate_mouse_windowdragging`, `misc.allow_session_lock_restore`,
  `misc.disable_scale_notification`.
- **Layout global**: `layout.single_window_aspect_ratio` +
  `_tolerance` — jendela tunggal tidak melar penuh (mis. 4:3).
- **Binds**: `binds.scroll_event_delay` (padanan `cooldown-ms=180` niri untuk
  wheel), `binds.movefocus_cycles_groupfirst`, `binds.workspace_back_and_forth`,
  `binds.allow_workspace_cycles`, `binds.pass_mouse_when_bound`,
  `binds.focus_preferred_method`, `binds.workspace_center_on`.
- **Group layar penuh (scrolling)**: `hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "set" })`
  — tampak fullscreen untuk Hyprland, tapi klien tidak diberi tahu (mencegah
  browser masuk mode presentasi); `hl.dsp.window.fullscreen()` punya opsi
  `layout_aware`.

## 12. Eksekusi ber-rule & API kecil yang berguna

```lua
-- Ganti pola "--class kitty-float" + window rule
hl.bind("SUPER + ALT + RETURN", hl.dsp.exec_cmd("kitty", { float = true, move = { 0, 0 } }))

-- Aksi ke jendela tertentu tanpa memfokuskannya
hl.bind("SUPER + SHIFT + W", hl.dsp.window.close({ window = "class:firefox" }))

-- Query jendela (filter: class/title/workspace/monitor/tag/float/mapped)
local farben = hl.get_windows({ class = "firefox", mapped = true })
```

- `hl.dsp.window.set_prop({ prop = "opacity", value = "0.8" })` — semua efek
  dinamis bisa diubah saat itu juga.
- `hl.notification.create({ text = …, timeout = …, icon = … })` — notifikasi
  asli Hyprland (pengganti `notify-send` di skrip).
- `hl.plugin.load("…so")` — plugin dari Lua, tak perlu `exec-once hyprctl plugin load`.
- `hl.is_key_down()` (bind kondisional), `hl.get_layers()`,
  `hl.permission({ binary = …, type = …, mode = … })` +
  `ecosystem.enforce_permissions` (nilai `type`/`mode` lihat halaman Permissions).
  (`hl.env()` sendiri **sudah** dipakai di `hyprland.lua`.)
- Reload config dari dalam Lua: 0.57 punya dispatcher `hl.dsp.reload_config()`
  (`---@field reload_config fun(...): HL.Dispatcher` di stub 0.57.1). Nama
  `hl.reload_config` **tidak ada** (diuji `hyprctl eval` → `nil`), jangan tertukar.
- `hl.get_devices()` mengembalikan `HL.Device[]` (padanan `hyprctl devices -j`)
  tanpa parsing JSON.

## 13. Backlog prioritas

| # | Fitur | Dampak | Usaha | Butuh HW | Tempat |
|---|---|---|---|---|---|
| 1 | Rule `no_screen_share` untuk waybar/eww | sedang | kecil | tidak | `hyprland.lua` |
| 2 | `stay_focused` untuk pinentry, `persistent_size` untuk kitty-float | sedang | kecil | tidak | `hyprland.lua` |
| 3 | `binds.scroll_event_delay` + tuning `scrolling.*` lanjutan | sedang | kecil | tidak | `hyprland.lua` |
| 4 | Workspace rule arah scroll per workspace | tinggi | kecil | tidak | `hyprland.lua` |
| 5 | Rule bernama + tag (opacity per tag, toggle runtime) | sedang | sedang | tidak | `hyprland.lua` |
| 6 | Event bus: OSD/notifikasi saat fullscreen & screenshare | sedang | sedang | tidak | file baru `hypr/events.lua` |
| 7 | `group.auto_group` + `group.active({ index })` di `SUPER+1..6` | sedang | sedang | tidak | `binding.lua` |
| 8 | `hl.device` per-device (touchpad natural scroll, keyboard eksternal) | tinggi | kecil | ya (device) | `hyprland.lua` |
| 9 | Rule mengambang dinamis lewat event `window.title` | sedang | sedang | tidak | `hypr/events.lua` |
| 10 | Gesture `cursor_zoom` + swipe `close`/`float`/`fullscreen` | sedang | kecil | ya (trackpad) | `hyprland.lua` |
| 11 | Gesture live untuk volume/brightness (+ notify-send sekali di akhir gesture) | tinggi | sedang | ya (trackpad) | `hyprland.lua` |
| 12 | `render.cm_*`, tuning monitor (`reserved`, `icc`) | kecil | sedang | tidak | `hyprland.lua` |
| 13 | Layout sendiri via `hl.layout.register` | tinggi (eksperimen) | besar | tidak | `hypr/layout.lua` |
| 14 | `decoration.wobble.*` (default `enabled = false`, `intensity` 0–2) | kosmetik | kecil | tidak | template feel |
| 15 | Blur variant `decoration.blur.variant` (0–10) + `blur.proportional` | sedang | kecil | tidak | template feel |
| 16 | `no_glow` / `no_xdg_drags` / `no_wobble` per jendela | kecil | kecil | tidak | `hyprland.lua` |
| 17 | `cursor.warp_on_monitor_change` (default `-1`, rentang -1..2) | kecil | kecil | tidak | `hyprland.lua` |
| 18 | `hl.get_devices()` + `hl.dsp.reload_config()` (pengganti `hyprctl`) | kecil | kecil | tidak | `hypr/events.lua` |

## 14. Jebakan yang sudah terbukti (jangan diulang)

- `{ mouse = true }` pada bind mouse **bukan** opsi yang dipakai lapisan Lua di
  0.56.2 (bind tetap terdaftar `mouse = false`). Jangan ditambahkan — kalau suatu
  saat diaktifkan, Hyprland akan mencari dispatcher `mouse` ala `bindm` lama.
- Pesan layout itu spesifik per layout. Untuk scrolling: `togglesplit`,
  `preselect`, `movetoroot`, `splitratio`, `swapsplit` **tidak ada** (itu milik
  dwindle). Pesan yang dipakai config ini ada di
  [`../config/input/keybinding/layout.lua`](../config/input/keybinding/layout.lua).
- `move +col` di 0.56 = **menggulir tape satu kolom**, bukan memindahkan kolom.
  Memindahkan kolom = `swapcol l` / `swapcol r`. Di kolom terakhir `move +col`
  menghilangkan fokus jendela.
- `dwindle.pseudotile` sudah tidak ada (pseudo kini properti per-jendela).
- Pesan layout yang salah tidak muncul di `hyprctl configerrors`.
- Layer rule **hanya** bisa `match = { namespace = … }`; tidak ada properti
  match lain, dan `hyprctl layerrules` (subcommand untuk melihat/menghapus
  rule) tidak ada. Semua varian rofi melaporkan namespace `rofi` — sudah diuji
  `-dmenu`, `-name`, `-window-title`, `-normal-window`, dan `-theme
  wallpaper.rasi`; `-normal-window` pun tetap layer, bukan jendela biasa.
- Untuk gaya per-varian, **jangan** pakai `hl.on("layer.opened")` + membuat rule
  di dalamnya: event-nya jalan (terbukti), tapi rule-nya terlambat — animasi
  tetap memakai rule lama (diukur dari tangkapan frame: kurva tepi kotak masih
  slide). Yang dipakai: rule bernama yang dibuat sekali dengan
  `set_enabled(false)` dan dinyalakan dari bind sebelum prosesnya diluncurkan.
  Nol proses tambahan, dan rule yang menang = yang **terakhir dibuat**.
- Layer rule hanya bisa menyetel **style** animasi, dan style itu dipakai untuk
  `layersIn` **dan** `layersOut`; tidak ada cara menyetel style masuk/keluar
  secara terpisah (`layersIn`/`layersOut` hanya ada di blok `animation` global,
  bukan di rule — [hyprwm/Hyprland#9894](https://github.com/hyprwm/Hyprland/issues/9894)).
  Konsekuensinya: mematikan rule tepat di `layer.closed` membuat animasi keluar
  kembali memakai rule dasar (rofi: `slide bottom`). Karena itu rule override
  harus tetap aktif selama animasi keluar; helper yang dipakai:
  [`../config/lib/animation_override.lua`](../config/lib/animation_override.lua) —
  `anim.layer{ namespace, animation, hold_ms }` lalu `handle.launch(cmd)`.
  Helper menunda `set_enabled(false)` selama `hold_ms` (default 700 ms, dihitung
  dari `layers` 4 ds + margin) lewat `hl.timer(callback, { timeout, type =
  "oneshot" })` (bentuk ini yang ada di stub 0.57.1), dengan pengaman generasi
  agar hold dari penutupan lama tidak mematikan peluncuran baru. Tool lain
  cukup memakai helper ini; tidak perlu menulis ulang logika rule + event.
- `hyprctl eval` tidak memvalidasi string style animasi: nama style yang salah
  tetap dijawab `ok` dan diam-diam tidak berefek (jangan andalkan pesan error).
- `hyprctl dispatch` menerjemahkan argumennya sebagai Lua (0.56 dan masih di
  0.57.1 — diuji ulang), jadi `hyprctl dispatch workspace 9` gagal dengan
  `')' expected near '9'`. Pakai
  `hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = 9 }))'` (gagal ini
  sunyi kalau output-nya dibuang ke `/dev/null`, sudah pernah menipu saat uji).

- **0.57 membatasi `decoration:shadow:render_power` 1–4.** 0.56 menerima 10;
  nilai lama membuat seluruh config ditolak (`error setting … maximum of 4`).
  Default sekarang 3, dan `config/appearance/feel.lua` meng-clamp ke 4.
  Efek baru `decoration.glow.render_power` juga 1–4 (default 3, glow default mati).
- Rule baru 0.57 diuji lewat `hl.window_rule` di 0.57.1: `no_glow = true`,
  `no_wobble = true`, `no_xdg_drags = true` → `ok`. Tetapi `active_border` /
  `inactive_border` **sebagai field rule** ditolak (`unknown field`), meski
  release note menyebut "rules"; yang ada hanya config `general.col.*` (atau
  `border_color` + prop seperti §6). `no_wobble` sebagai field
  `hl.workspace_rule` juga `unknown field`. Cek stub/`eval` sebelum dipakai.
- `hyprctl descriptions` memberi nama + `min`/`max`/`default` resmi semua opsi
  (407 entri di mesin ini), tapi **tanpa flag `-j`** — dengan `-j` outputnya kosong.
- Repo ini dulu menyebut "`animations:layers` tidak bisa di-query"; di 0.57.1
  tetap begitu, dan `hyprctl layerrules` masih `unknown request`. Bukti animasi
  layer harus dari perilaku (rekaman frame), bukan introspeksi rule.

## 15. Batasan pengujian

- Tidak ada alat injeksi input (`wtype`, `ydotool`, `dotool`, `xdotool`) di
  sistem ini, jadi bind hanya bisa diverifikasi sampai level **dispatcher +
  pendaftaran bind**, bukan penekanan tombol fisik.
- Gesture dan `hl.device` butuh hardware untuk dibuktikan.
- `hl.on("hyprland.start")` hanya jalan saat compositor mulai (bukan saat
  reload), jadi efek autostart baru terlihat setelah logout/login.
- Config di repo ini simlink dari `~/.config/<tool>`; setelah mengubah file di
  `~/.dotfile` cukup `hyprctl reload` (lihat juga aturan sync di
  [`../../AGENTS.md`](../../AGENTS.md)).
