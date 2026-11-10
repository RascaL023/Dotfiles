# Matriks Feel: Hyprland 0.56 vs niri 26.04

> Indeks: [`README.md`](../README.md) · terkait: [`FEEL.md`](FEEL.md),
> [`THEME_ENGINE.md`](THEME_ENGINE.md)

**Status: rancangan + hasil verifikasi.** Dokumen ini memetakan setiap knob
“rasa” yang relevan ke dua WM yang dipakai repo ini, dengan satu tujuan:
**tidak ada fitur yang dipaksakan ke WM yang tidak punya padanannya.**

Sumber verifikasi:

- Hyprland 0.56: stub resmi `share/hypr/stubs/hl.meta.lua` (daftar opsi
  `decoration.*`, `layer_rule`, `group.*`) + config repo (`hypr/config/core/theme.lua`,
  `hypr/hyprland.lua`).
- niri 26.04: docs Configuration (Layout, Window Rules, Layer Rules, Animations,
  Include) + `niri validate` lokal dengan fragmen uji.
- Noctalia v5: docs resmi (batas template) — dibahas di `THEME_ENGINE.md`.

Legenda verdict:

| Simbol | Arti |
|---|---|
| ✅ | Ada di dua-duanya, pemetaan mendekati 1:1 |
| 🔁 | Ada di dua-duanya, **semantik beda** → butuh adaptasi, bukan rename |
| 🅗 | Hanya Hyprland → **jangan** dirender untuk niri |
| 🅝 | Hanya niri → **jangan** dirender untuk Hyprland |
| 🛠 | Tidak ada di WM → harus diatur di app (CSS/config app) |
| 🚫 | Tidak ada padanan di mana pun → jangan masuk skema |

---

## 1. Ringkasan eksekutif

1. **Yang benar-benar sama** cuma sedikit: ada/tidaknya border, warna border,
   gap (konsep), shadow (konsep), radius (konsep), opacity (konsep), blur
   (konsep), dan kecepatan animasi.
2. **Yang mirip tapi beda** justru mayoritas: gap masuk/keluar, cara radius
   diterapkan, satuan/parameter shadow, granularity blur, opacity per-window
   vs global, dan model animasi (named style vs spring/curve).
3. **Hyprland punya banyak knob yang tidak ada di niri** (dim inactive, tuning
   blur, motion blur, groupbar, layer rule animasi/order). Ini yang paling
   mudah menjadi bug kalau template feel “menyalin” field.
4. **niri punya beberapa hal yang tidak ada di Hyprland** (opacity & radius &
   shadow untuk layer-shell, `popups {}`, backdrop, struts, scroll factor,
   spring + custom shader).
5. **Aturan keras:** template per WM hanya boleh membaca token yang sudah
   dinyatakan didukung WM itu. Token yang tidak didukung **tidak ditulis sama
   sekali**, bukan ditulis dengan nilai default.

---

## 2. Matriks inti

### 2.1 Geometri

| Fitur | Hyprland 0.56 | niri 26.04 | Verdict | Catatan adaptasi |
|---|---|---|---|---|
| Gap dalam | `general.gaps_in` | `layout.gaps` | 🔁 | niri hanya satu nilai; pakai `gaps`, bukan rata-rata |
| Gap luar | `general.gaps_out` | `struts` negatif | 🔁 | niri: `struts` **tidak di-merge**; kalau dipakai, satu file harus memiliki seluruh blok |
| Gap per workspace | `workspace` rule: `gaps_in`, `gaps_out` | — | 🅗 | jangan dirender untuk niri |
| Radius jendela | `decoration.rounding` (global) | `window-rule { geometry-corner-radius }` | 🔁 | niri butuh satu rule global; radius bisa 4 nilai (niri), Hyprland tidak |
| Kelengkungan radius | `decoration.rounding_power` | — | 🅗 | niri: tidak ada; jangan disamakan dengan radius |
| Border: tebal | `general.border_size` | `layout.border.width` | ✅ | nilai sama, nama beda |
| Border: aktif | `general.col.active_border` (2 warna + angle) | `border.active-color` atau `border.active-gradient` | 🔁 | Hyprland selalu bisa gradien; niri butuh pilih color **atau** gradient |
| Border: tidak aktif | `general.col.inactive_border` | `border.inactive-color` | ✅ | — |
| Border: urgent | — | `border.urgent-color` | 🅝 | jangan dirender untuk Hyprland |
| Ruang warna gradien | — (angle saja) | `active-gradient … in="oklch"` | 🅝 | opsional, jangan dipaksakan |
| Border ikut geometri | `decoration.border_part_of_window` | `prefer-no-csd` + `draw-border-with-background` | 🔁 | konsep mirip, bukan rename |
| Border per window | — (window/workspace rule terbatas) | `window-rule { border { … } }` | 🅝 | niri bisa override warna border per window |
| Sisi border | `general.border_size` (semua sisi) | `layout.border.width` (semua sisi) | ✅ | tidak ada kontrol per sisi di dua-duanya |

### 2.2 Elevasi (shadow)

| Fitur | Hyprland | niri | Verdict | Catatan |
|---|---|---|---|---|
| Nyalakan shadow | `decoration.shadow.enabled` | `layout.shadow` (flag `on`) / `off` | 🔁 | niri: flag, bukan boolean |
| Kelembutan | `decoration.shadow.range` | `layout.shadow.softness` | 🔁 | rentang dan kurva beda; jangan salin angka mentah |
| Kekuatan | `decoration.shadow.render_power` | — | 🅗 | niri tidak punya “power” |
| Sebaran | `decoration.shadow.scale` | `layout.shadow.spread` | 🔁 | skala vs piksel logis |
| Offset | `decoration.shadow.offset` | `layout.shadow.offset x= y=` | ✅ | — |
| Warna | `decoration.shadow.color` | `layout.shadow.color` | ✅ | — |
| Warna saat tidak fokus | `decoration.shadow.color_inactive` | `layout.shadow.inactive-color` | ✅ | — |
| Shadow tajam | `decoration.shadow.sharp` | `softness 0` | 🔁 | niri: softness 0, bukan flag |
| Shadow di belakang window | — | `layout.shadow.draw-behind-window` | 🅝 | untuk artifact CSD; jangan ke Hyprland |
| Shadow per layer | — | `layer-rule { shadow { … } }` | 🅝 | Hyprland: tidak ada; app yang menggambar shadow sendiri |
| Shadow per window | — (window rule tidak punya) | `window-rule { shadow { … } }` | 🅝 | — |

### 2.3 Material (blur & efek latar)

| Fitur | Hyprland | niri | Verdict | Catatan |
|---|---|---|---|---|
| Blur on/off | `decoration.blur.enabled` | per rule `background-effect.blur` | 🔁 | niri **tidak punya saklar global**; “off” = jangan emit rule blur |
| Kekuatan blur | `blur.size`, `blur.passes` | — (kernel tetap) | 🅗 | niri tidak bisa; jangan kirim `passes` |
| Noise | `blur.noise` (0–0.2) | `background-effect.noise` | 🔁 | rentang beda; jepit per WM |
| Kontras/terang | `blur.contrast`, `blur.brightness` | — | 🅗 | — |
| Saturasi/vibrancy | `blur.vibrancy`, `blur.vibrancy_darkness` | `background-effect.saturation` | 🔁 | vibrancy ≠ saturation; map sebagai “warna latar” |
| Xray | `blur.xray` | `background-effect.xray` | ✅ | — |
| Blur popup | `blur.popups`, `blur.popups_ignorealpha` | `popups { background-effect { blur } }` | 🔁 | niri per-surface popups |
| Blur input method | `blur.input_methods*` | — | 🅗 | — |
| Ignore opacity | `blur.ignore_opacity` | — (default perilaku beda) | 🅗 | jangan diterjemahkan ke `ignore_alpha` (itu urusan layer rule) |
| Blur layer/bar | `layer_rule { blur }` | `layer-rule { background-effect { blur } }` | ✅ | — |
| `ignorealpha` layer | `layer_rule { ignore_alpha }` | — | 🅗 | niri memakai `blur` per surface; tidak ada alpha threshold |
| Blur popup layer | `layer_rule { blur_popups }` | `layer-rule { popups { background-effect } }` | ✅ | — |
| Motion blur | `decoration.motion_blur.*` | — | 🅗 | — |
| Shader blur | `render.use_shader_blur_blend` | — | 🅗 | — |

### 2.4 Transparansi & fokus

| Fitur | Hyprland | niri | Verdict | Catatan |
|---|---|---|---|---|
| Opacity window aktif | `decoration.active_opacity` | `window-rule { opacity }` | 🔁 | niri tidak punya “aktif global”; pakai rule `match is-active=true` bila perlu |
| Opacity window tidak aktif | `decoration.inactive_opacity` | `window-rule { match is-active=false; opacity }` | 🔁 | hasil mendekati, bukan setara |
| Opacity fullscreen | `decoration.fullscreen_opacity` | `window-rule { match is-fullscreen=true }` (bila ada) / `toggle-windowed-fullscreen` | 🔁 | verifikasi matcher saat implementasi |
| Dim window tidak aktif | `decoration.dim_inactive`, `dim_strength` | — | 🅗 | **jangan** dipaksakan via opacity (hasil beda: gelap vs transparan) |
| Dim sekitar layer | `decoration.dim_around` | — | 🅗 | — |
| Dim modal / special | `decoration.dim_modal`, `dim_special` | — | 🅗 | — |
| Opacity terminal | window rule `opacity` | `window-rule { opacity }` | ✅ | satu pemilik: WM, bukan config terminal |
| Opacity layer | — | `layer-rule { opacity }` | 🅝 | Hyprland: atur di CSS app |
| Radius layer | — | `layer-rule { geometry-corner-radius }` | 🅝 | Hyprland: `border-radius` di CSS app |
| `no_rounding` / `no_shadow` | window/workspace rule | `window-rule { border { off } }` / `shadow { off }` | 🔁 | beda level (rule vs section) |

### 2.5 Gerak

| Fitur | Hyprland | niri | Verdict | Catatan |
|---|---|---|---|---|
| Kurva easing | `hl.curve` bezier 4 titik | `curve "cubic-bezier" x1 y1 x2 y2` | ✅ | hanya untuk animasi berbasis durasi |
| Durasi/kecepatan | `speed` per leaf × pengali | `duration-ms` per animasi / `slowdown` | 🔁 | model beda: speed Hyprland lebih besar = lebih lambat |
| Spring | — | `spring damping-ratio stiffness epsilon` | 🅝 | Hyprland tidak punya spring |
| Nama gaya animasi | `style = gnomed/popin/slide/…` | — | 🅗 | niri tidak punya named style |
| Animasi window buka/tutup | leaf `windowsIn/windowsOut` | `window-open` / `window-close` | 🔁 | jumlah leaf beda (niri tidak memisah move/open) |
| Animasi workspace | `workspacesIn/Out` | `workspace-switch` + `horizontal-view-movement` | 🔁 | satu kejadian di Hyprland bisa jadi dua animasi di niri |
| Animasi layer/bar | leaf `layers` | — (layer animasi diatur app) | 🅗 | — |
| Border angle berputar | leaf `borderangle` | — | 🅗 | niri: gradien statis |
| Custom shader | — | `custom-shader` | 🅝 | jangan dirender untuk Hyprland |
| Matikan semua animasi | per leaf `enabled=false` | `animations { off }` | 🔁 | niri satu flag global |

### 2.6 Chrome (bar, menu, tab)

| Fitur | Hyprland | niri | Verdict | Catatan |
|---|---|---|---|---|
| Tab/group bar | `group.groupbar.*` | `layout.tab-indicator` | 🔁 | **bukan** fitur yang sama: groupbar Hyprland untuk grouping window, tab indicator niri untuk kolom tabbed |
| Blur groupbar | `group.groupbar.blur` | — | 🅗 | — |
| Radius tab | `group.groupbar.rounding`, `rounding_power` | `tab-indicator { corner-radius }` | 🔁 | — |
| Warna tab | `group.groupbar.text_color` | `tab-indicator { active/inactive/urgent-color }` | 🔁 | niri lebih kaya (gradien) |
| Font UI WM | `misc.font_family` | — (font WM tidak dapat diubah) | 🅗 | niri: jangan kirim |
| Struts (ruang bar) | — (layer margin dari bar) | `layout.struts` | 🅝 | non-merging; satu pemilik |
| Latar area kerja | — | `layout.background-color` | 🅝 | warna, bukan rasa |
| Backdrop overview | — | `overview.backdrop-color` | 🅝 | warna |
| Backdrop fullscreen | — | `layout.fullscreen-backdrop-color` | 🅝 | warna |

---

## 3. Daftar eksplisit: Hyprland-only

Jangan pernah dirender ke fragmen niri, dan jangan “diterjemahkan” menjadi
opacity/ukuran lain:

- `decoration.dim_inactive`, `dim_strength`, `dim_around`, `dim_modal`, `dim_special`
- `decoration.blur.size`, `passes`, `contrast`, `brightness`,
  `vibrancy`, `vibrancy_darkness`, `ignore_opacity`, `input_methods*`,
  `popups_ignorealpha`, `special`
- `decoration.motion_blur.{enabled,samples}`
- `decoration.shadow.render_power`, `scale`, `sharp` (niri hanya softness 0)
- `group.groupbar.*` (bukan padanan `tab-indicator`)
- `misc.font_family`, `misc.session_lock_blur`
- named `style` pada `hl.animation`
- `layer_rule` field: `animation`, `no_anim`, `order`, `dim_around`,
  `above_lock`, `no_screen_share`, `blur_popups`, `ignore_alpha`
- workspace rule: `gaps_in`, `gaps_out`, `border_size`, `no_border`,
  `no_rounding`, `no_shadow`
- `render.use_shader_blur_blend`

Alasan: semuanya tidak punya padanan struktural di niri. Memaksakannya
menghasilkan perilaku yang berbeda dari yang dimaksud (mis. “dim inactive”
menjadi transparan) — itu bug rasa, bukan fitur.

---

## 4. Daftar eksplisit: niri-only

Jangan dirender ke Hyprland:

- `layout.struts`, `preset-column-widths`, `preset-window-heights`
  (**non-merging**: satu file harus memiliki seluruh blok)
- `layout.center-focused-column`, `always-center-single-column`,
  `default-column-display`
- `tab-indicator` (warna/gradien/posisi/lebar), `insert-hint`
- `layout.background-color`, `fullscreen-backdrop-color`, `overview.backdrop-color`
- `window-rule`: `open-on-output`, `open-on-workspace`, `open-maximized*`,
  `open-fullscreen`, `open-floating`, `open-focused`, `default-floating-position`,
  `scroll-factor`, `pinch-sensitivity`, `min/max-width/height`,
  `variable-refresh-rate`, `tiled-state`, `clip-to-geometry`,
  `draw-border-with-background`, `baba-is-float`
- `window-rule` override warna `border`, `focus-ring`, `shadow`, `tab-indicator`
  per window
- `layer-rule`: `opacity`, `geometry-corner-radius`, `shadow`,
  `place-within-backdrop`, `block-out-from`, `popups {}`, matcher `layer`,
  `at-startup`
- `animations`: `spring`, `custom-shader`, `slowdown`, `exit-confirmation-*`,
  `recent-windows-close`
- `include optional=true` (bukan fitur Hyprland; Hyprland memakai Lua/Lua module)

Catatan: beberapa perilaku niri (mis. `open-floating`) bisa ditiru lewat window
rule Hyprland, tapi **jangan** memasukkannya ke template rasa — itu perilaku
window, bukan rasa. Kalau butuh, tulis di config WM masing-masing secara manual.

---

## 5. Tidak bisa di WM mana pun (harus di app)

| Yang diinginkan | Kenapa bukan urusan WM | Tempat yang benar |
|---|---|---|
| Opacity layer di Hyprland | layer rule tidak punya opacity | CSS app (`cc-bg`, `window#waybar > box`) |
| Radius layer di Hyprland | layer rule tidak punya radius | CSS app |
| Shadow layer di Hyprland | layer rule tidak punya shadow | CSS app |
| Variabel rasa di GTK3 | tidak ada `var()` | stylesheet hasil generate / pecah file |
| Radius/ukuran widget bar | milik app | CSS bar |
| Padding terminal | milik terminal | `kitty.conf`/`foot.ini` (include kedua) |
| Font UI Noctalia | milik Noctalia | config TOML Noctalia |

Aturan: **satu nilai satu pemilik.** Kalau WM bisa, WM yang pegang; kalau tidak,
app. Jangan dua-duanya.

---

## 6. Guardrail implementasi

1. **Template per WM, bukan template dengan `if wm == …`.** Fragmen niri hanya
   berisi key niri; fragmen Hyprland hanya key Hyprland. Tidak ada percabangan
   yang bisa salah.
2. **Skema rasa menandai dukungan.** Setiap token punya `support = { hypr, niri }`.
   Token dengan `niri = false` tidak pernah masuk template niri.
3. **Jangan rename untuk hal yang beda semantik.** `gaps_in → gaps` hanya boleh
   kalau memang setuju membuang gap luar; `dim_inactive → opacity` dilarang.
4. **Jepit per WM.** Batas aman Hyprland (`gaps_out` 0–60, `passes` 1–6) tidak
   sama dengan niri (`gaps` 0–30, `softness` 0–60). Satu tabel clamp per WM.
5. **Validasi sebelum aktif.** Hyprland: `luac -p` + `hyprctl reload` (config
   salah tidak membuat sesi mati, tetapi bisa menolak sebagian). niri:
   `niri validate -c niri/config.kdl` (exit 1 = jangan aktifkan).
6. **Angka yang tidak didukung jangan dikirim sebagai 0/false.** Nol bisa berarti
   “mati”, bukan “tidak berlaku”.
7. **Token “rasa” tidak boleh mengandung perilaku.** `open-floating`, `struts`,
   `preset widths` bukan rasa.
8. **Uji dua sesi.** Perubahan dianggap selesai hanya kalau sudah dicek di
   Hyprland **dan** niri (atau minimal `niri validate` + `luac -p` bila sesi
   satunya tidak tersedia).

---

## 7. Smoke test per WM

Hyprland (sesi aktif):

```bash
luac -p ~/.myenv/theme/current/hypr/theme.lua
luac -p ~/.myenv/feel/current/hypr.lua
hyprctl reload
hyprctl getoption decoration:rounding
hyprctl getoption decoration:blur:enabled
```

niri (tanpa mengganggu sesi):

```bash
niri validate -c ~/.dotfile/niri/config.kdl
niri msg layers            # namespace bar/launcher untuk layer-rule
niri msg windows           # app-id untuk window-rule
```

Yang harus terlihat saat feel diganti:

| Cek | Hyprland | niri |
|---|---|---|
| Gap berubah | `hyprctl getoption general:gaps_in` | tidak ada query; lihat layar |
| Radius berubah | `hyprctl getoption decoration:rounding` | `niri msg windows` tidak menunjukkan radius; lihat layar |
| Blur mati | `getoption decoration:blur:enabled` | lihat layar; pastikan tidak ada rule blur aktif |
| Shadow mati | `getoption decoration:shadow:enabled` | lihat layar |

---

## 8. Titik konflik dengan Noctalia

Noctalia v5 punya **template compositor bawaan** yang menulis
`niri/noctalia.kdl` (plus `include` ke `niri/config.kdl`) dan
`hypr/noctalia.lua` (plus `dofile(...).apply_theme()`). Kalau keduanya aktif
bersamaan dengan include warna kita, akan ada dua pemilik warna di WM yang sama.
Aturannya ada di [`THEME_ENGINE.md`](THEME_ENGINE.md) §6: **satu pemilik warna
per WM**, dipilih lewat manifest — bukan dideteksi otomatis.

Yang tetap aman: rasa (fragmen niri/`feel.lua`) selalu milik kita, karena
Noctalia tidak bisa merender angka/string bebas (lihat §8 dokumen itu).
