# Feel — Rasa di Luar Warna

> Indeks: [`README.md`](README.md) · terkait:
> [`PROGRESS.md`](PROGRESS.md), [`MATUGEN_SKILLS.md`](MATUGEN_SKILLS.md),
> [`WM_FEEL_MATRIX.md`](WM_FEEL_MATRIX.md) (matriks fitur per WM),
> [`THEME_ENGINE.md`](THEME_ENGINE.md) (reload & abstraksi engine),
> [`../core/palette/kanagawa-dragon-lotus/blueprint/README.md`](../core/palette/kanagawa-dragon-lotus/blueprint/README.md)

**Status: rancangan.** Dokumen ini menjelaskan kondisi yang ada sekarang,
perbedaan Hyprland vs niri, dan rancangan pemisahan **warna** dari **rasa**.
Belum ada satu pun perubahan kode yang dijelaskan di sini yang sudah diterapkan.
Kalau nanti dieksekusi, perbarui dokumen ini di commit yang sama — bagian
"Kondisi saat ini" harus selalu cocok dengan repo.

---

## 1. Ringkasan keputusan

1. **Rasa adalah sumbu kedua, bukan bagian dari palet.** Warna tetap milik
   `~/.myenv/theme/current`; rasa pindah ke `~/.myenv/feel/current`. Memilih
   wallpaper tidak lagi memaksa rasa default, dan mengganti rasa tidak
   menyentuh warna.
2. **Profil rasa berisi niat, bukan knob WM.** Contoh: `gaps`, `radius`,
   `blur_strength`, `motion.character` — bukan `blur.passes` atau `style_in`
   yang hanya ada di Hyprland. Tiap WM menerjemahkan niat itu ke grammarnya.
3. **Tidak perlu assembler baru.** Matugen sudah bisa merender template dari
   JSON sembarang (`matugen json`), jadi profil rasa menjadi flow kedua yang
   bebas palet. Satu renderer, nol dependensi baru.
4. **Konsumen dibagi empat kelas** menurut cara menerima data: runtime merge
   (Lua), include/variabel, CSS tanpa variabel (dipecah), dan file utuh hasil
   generate.
5. **Noctalia tidak butuh sistem tema kedua.** Profil rasa yang sama menjadi
   kontrak; toggle shell hanya menentukan siapa yang jalan (Noctalia vs
   waybar/eww/swaync), bukan bagaimana rasa didefinisikan.

---

## 2. Kondisi saat ini (terverifikasi di repo)

### 2.1 Hyprland

| Bagian | Tempat | Isi |
|---|---|---|
| Default + clamp + pemetaan | `hypr/config/core/theme.lua` | `shape`, `surface`, `material`, `motion`, `chrome` → `theme.hypr`, `theme.curves`, `theme.animations`, `theme.layer_blur` |
| Nilai dari tema | `~/.myenv/theme/current/hypr/theme.lua` | digabung di atas default, dimuat dengan `load(..., "t", {})` |
| Penerapan | `hypr/hyprland.lua` | `hl.config(theme.hypr)`, `hl.curve`, `hl.animation`, layer rule (`blur = theme.layer_blur`) |

- **Flow A (wallpaper)** menulis warna saja (`matugen/core/palette/wallpaper-based/template/hypr.lua`),
  jadi tema wallpaper **selalu memakai feel default**.
- **Flow B (blueprint)** menulis warna **dan** `feel` ke file yang sama
  (`matugen/core/palette/kanagawa-dragon-lotus/template/hypr.lua`) karena objek
  `feel` tinggal di dalam blueprint.
- Akibatnya warna dan rasa berbagi satu file, satu render, dan satu pilihan
  tema. Ini yang mau dipisah.
- `chrome.rofi_radius` sudah ditulis template Flow B dan dipakai
  `template/source.rasi` (`window-radius`), tetapi **belum dipetakan** di
  `hypr/config/core/theme.lua` — hanya lewat rofi, bukan Hyprland.

### 2.2 niri

- `niri/config.kdl` masih config tangan: `include` dua file statis
  (`conf/keybinds/keybind.kdl`, `conf/layouts/layout.kdl`), lalu `layout`,
  `window-rule`, `animations` ditulis langsung di file utama.
- Warna masih hardcoded: `layout { border { active-color "#ffc87f" … } }`,
  `overview { backdrop-color "#4c566a90" }`, `layout { background-color "00000020" }`.
- Belum ada integrasi matugen sama sekali untuk niri.

### 2.3 Konsumen non-shell

| Konsumen | Cara menerima warna | Punya variabel? |
|---|---|---|
| `kitty` | `include ~/.myenv/theme/current/kitty/theme.conf` | ya (conf) |
| `foot` | `include=…/current/foot/theme.ini` | ya (ini) |
| `rofi` | `@import palette.rasi` → `current/rasi/theme.rasi` | ya (variabel rasi) |
| `swaync` | `@import …/current/css/theme.css` + `:root { --radius: … }` | ya (GTK4 CSS custom property) |
| `waybar` | `@import …/current/css/theme.css` | **tidak** (GTK3, tanpa `var()`) |
| `wlogout` | pola sama dengan waybar | tidak |
| `eww` | `@import …/current/scss/theme` | ya (variabel SCSS) |
| `gtk3.css` | file utuh hasil matugen | tidak (nilai dibakar) |
| Neovim | `require("theme")` | ya (Lua) |

### 2.4 Font (sudah jalan sebagian)

Sumbu pertama yang pindah keluar palet **bukan** geometry, tapi font — karena
font hari ini ikut ditulis template warna. Yang sudah berjalan:

| Bagian | Berkas |
|---|---|
| Profil (nilai) | `matugen/core/feel/blueprint/<profil>.json` — sekarang baru `default.json` |
| Template per konsumen | `matugen/core/feel/template/{source.scss, kitty.conf, foot.ini, gtk3.css, gtk4.css}` |
| Mapping (template → output) | `matugen/core/feel/config.toml`, satu untuk semua profil |
| Renderer | `matugen/feel.sh <profil>` → `~/.myenv/feel/generated/<profil>`, lalu flip `feel/current` |

Bentuk foldernya:

```text
matugen/core/feel/
├── blueprint/   # isi profil rasa: satu JSON per rasa
├── template/    # template per konsumen, dipakai semua profil
└── config.toml  # config render, satu untuk semua profil
```

Menambah rasa = menambah satu berkas di `blueprint/`; `config.toml` dan
`template/` tidak disentuh. Nama berkas profil = nama rasa yang dipakai
`feel.sh` (`feel.sh default` membaca `blueprint/default.json`).

> Catatan jujur: `blueprint/default.json` dan `template/*` **belum sinkron**.
> Profil memakai `font.{ui.text, ui.tooltip, ui.title, icon, system, terminal, weight}`,
> sedangkan template masih membaca key lama (`font.ui.system`, `font.display`,
> …). Skema font masih dibahas, jadi template sengaja tidak diubah; render akan
> gagal (`ResolveError`) sampai keduanya disamakan.

Konsumen yang sudah membaca hasilnya:

- `eww` (popup/profile/OSD): `eww/eww.scss` meng-`@import`
  `~/.myenv/feel/current/scss/feel` **setelah** partial tema. Template
  `source.scss` merender tujuh variabel (`$font-ui-text`, `$font-ui-system`,
  `$font-ui-icon`, `$font-terminal`, `$font-display`, `$font-weight`,
  `$font-weight-strong`); `eww.scss` baru memakai `$font-ui-text` dan
  `$font-weight`.
- `kitty`: `include ~/.myenv/feel/current/kitty/feel.conf`.
- `foot`: `include=…/feel/current/foot/feel.ini`.
- `alacritty`: `import` `~/.myenv/feel/current/alacritty/feel.toml`
  (opacity, padding, cursor, ukuran & family font); warnanya tetap dari
  `theme/current/alacritty/theme.toml`.
- `waybar`: `@import` `~/myenv/feel/current/css/waybar-font.css` di baris atas
  `waybar/style.css`. GTK 3 tidak punya `var()`, jadi berkas itu berisi aturan
  `* { font-family: … }` siap pakai; `font-family` literal dihapus dari
  `style.css`. Ukuran (9.2px), bobot `bold`, dan warna tetap milik waybar.
- `swaync`: `@import` `…/css/swaync-font.css` sesudah import tema, lalu
  `style.css` memakai `font-family: var(--font-family-ui)`. Berkas feel hanya
  mendefinisikan variabel; `--font-size-*` tetap milik swaync.

Konsekuensinya: `matugen/core/palette/*/source.scss` **tidak lagi** menulis
`$font-system`/`$font-widget`/`$font-terminal`. Mengganti font sekarang berarti
mengubah satu profil rasa, tidak menyentuh palet sama sekali.

Yang **belum** ikut (masih hardcoded, jangan diklaim sudah): `wlogout`,
`hyprlock`, `rofi`, bar `eww` (`eww/bar/styles/_tokens.scss` masih menyimpan font
lokal karena bar sengaja bisa jalan tanpa theme store), dan font display depth
clock.

---

## 3. niri vs Hyprland: apa yang bisa dan tidak bisa disamakan

Terverifikasi pada **niri 26.04** (docs resmi + `niri validate` lokal) dan
**Hyprland 0.56** (config di repo ini).

| Aspek | Hyprland 0.56 | niri 26.04 | Konsekuensi untuk profil rasa |
|---|---|---|---|
| Gap | `gaps_in` + `gaps_out` | satu `gaps`; gap luar ditiru `struts` negatif | simpan `gaps`; `outer_gaps` opsional |
| Radius jendela | global `decoration.rounding` | per-rule `geometry-corner-radius` | niri perlu satu `window-rule` global |
| Border | `border_size` + gradien 2 warna + `border_angle` | `border { width; active-gradient from to angle }` | paritas, token gradien bisa dipakai berdua |
| Shadow | `range`, `power`, `sharp`, `color` | `softness`, `spread`, `offset`, `color`; tanpa `sharp` | `sharp` ditandai hypr-only |
| Blur | `size`, `passes`, `noise`, `contrast`, `brightness`, `vibrancy`, `xray`, `popups`, `ignore_opacity` | `blur` on/off, `xray`, `noise`, `saturation` **per window/layer rule** | ekspos `blur_strength` 0–1, bukan `passes` |
| Opacity jendela | global active/inactive/fullscreen + rule | hanya rule (`opacity`, bisa `match is-focused=false`) | token inactive → rule di niri |
| Dim inactive | `dim_inactive`, `dim_strength`, `dim_around` | tidak ada | hypr-only |
| Layer (bar/launcher) | blur, `ignorealpha`, animasi; **tanpa opacity** | `opacity`, `geometry-corner-radius`, `shadow`, `background-effect`, `popups {}` | niri bisa menegakkan translucency layer; hypr lewat CSS app |
| Animasi | bezier bebas + named style (`popin`, `gnomed`, `slide`, …) | spring (`damping-ratio`, `stiffness`) atau `cubic-bezier` 4 angka; `custom-shader` | `character` → spring / bezier |
| Groupbar / tab | `groupbar` | `tab-indicator` | konsep mirip, field beda |
| Reload | `hyprctl reload` (post-hook) | live-reload; **include ikut di-watch** | niri tak perlu hook |

**Implikasi:** rasa yang sama tidak akan pixel-identik antar WM, dan tidak perlu.
Yang dijaga adalah karakternya (rapat/lega, lembut/tajam, tenang/energik).
Profil yang berisi knob spesifik WM akan membuat niri jadi warga kelas dua.

Daftar lengkap per fitur — termasuk yang **hanya** boleh dirender ke salah satu
WM — ada di [`WM_FEEL_MATRIX.md`](WM_FEEL_MATRIX.md). Jangan menambah field ke
profil tanpa mengecek verdict di sana.

---

## 4. Dua sumbu, dua pointer

```text
~/.myenv/theme/current   → palet warna (sudah ada, tetap)
~/.myenv/feel/current    → profil rasa (baru, independen)
```

Efek yang diharapkan:

- Flow A (wallpaper) akhirnya punya rasa; sekarang selalu jatuh ke default.
- Ganti warna tanpa mengubah rasa, dan sebaliknya.
- `feel` keluar dari blueprint. Nilai yang sekarang ada di
  `blueprint/dark.json` / `blueprint/light.json` cukup menjadi isi awal salah
  satu profil, lalu dihapus dari blueprint dan dari template warnanya.
- `hypr/theme.lua` (warna) dan `hypr/feel.lua` (rasa) menjadi dua file. Ini juga
  menghilangkan risiko dua flow saling menimpa.

---

## 5. Skema profil rasa

Satu profil = satu JSON kecil. Contoh (angka hanya ilustrasi):

```jsonc
{
  "meta": { "name": "default", "version": 1 },

  // Sumbu font — sudah jalan (lihat §2.4). Isi key masih dibahas; yang sudah
  // tetap: profil = data, `template/` = konsumen, `config.toml` = pemetaan.
  // Nama key mengikuti peran, bukan nama alat: satu font bisa dipakai beberapa
  // konsumen.
  "font": {
    "ui": {
      "text": "MapleMono NF",               // teks widget (eww, bar)
      "tooltip": "FiraCodeNerdFontMono",    // tooltip bar
      "title": "Monocraft Nerd Font"        // judul/elemen menonjol
    },
    "icon": "JetBrainsMono Nerd Font",      // glyph/ikon
    "system": "Cantarell Regular",          // app GTK/notifikasi
    "terminal": "MapleMono NF",
    "weight": { "normal": 500, "strong": 600 }
  },

  "geometry": {
    "radius": 8,
    "border": 2,
    "gaps": 7,
    "outer_gaps": 0
  },

  "elevation": {
    "shadow": true,
    "softness": 20,
    "spread": 2,
    "opacity": 0.55
  },

  "surface": {
    "window_opacity": 1.0,
    "inactive_opacity": 1.0,
    "terminal_opacity": 0.9,
    "layer_opacity": 0.92,
    "dim_inactive": false,
    "dim_strength": 0.0
  },

  "material": {
    "blur": true,
    "blur_strength": 0.55,
    "blur_noise": 0.0,
    "blur_saturation": 1.0,
    "layer_blur": true
  },

  "motion": {
    "enabled": true,
    "speed": 1.0,
    "character": "smooth",
    "easing": { "x1": 0.05, "y1": 0.9, "x2": 0.1, "y2": 1.05 }
  },

  "chrome": {
    "bar_radius": 30,
    "menu_radius": 10,
    "layer_opacity": 0.92
  }
}
```

Aturan:

1. **Lengkap by default.** Semua key wajib ada; render divalidasi sebelum
   dipakai. Perilaku matugen 4.2 (terverifikasi): key hilang → render **gagal**
   (`ResolveError`), `null` → tercetak `Null`, string kosong → tercetak kosong,
   dan tidak ada filter `default` maupun `{% if %}` (blok `if` malah lolos
   sebagai teks). Jadi "kosong berarti pakai nilai lain" tidak mungkin di dalam
   template: itu tugas konsumen (contoh `hypr/config/core/theme.lua:340`) atau
   `matugen/feel.sh`, yang menolak render bila ada placeholder tersisa.
   Ukuran font **tidak** masuk profil: tiap konsumen punya tuning sendiri.
   Pola validasi palet: `check_palette` di `nvim/lua/core/theme.lua`.
2. **Angka dijepit** ke rentang aman, alasan penolakan ditulis ke stderr.
3. **`motion.character`** adalah satu-satunya cara menyebut “rasa gerak”:
   - `snappy` → bezier pendek/cepat; niri: spring stiffness tinggi.
   - `smooth` → bezier panjang, tanpa overshoot; niri: `damping-ratio` 1.0.
   - `bouncy` → overshoot; niri: `damping-ratio` < 1.0.
4. **Tandai yang tidak universal.** `dim_inactive`, `sharp`, `motion.style_*`
   adalah hypr-only. niri mengabaikannya secara eksplisit (bukan diam-diam).
5. **Jangan masukkan knob tool.** Kalau sebuah konsumen butuh nilai tambahan,
   nilai itu turunan di adapter-nya, bukan key baru di profil.

---

## 6. Mekanisme per konsumen

Empat kelas. Sebagian besar tidak butuh render sama sekali.

### Kelas A — runtime merge (Lua)

| Konsumen | Mekanisme |
|---|---|
| Hyprland | `hypr/config/core/theme.lua` memuat `~/.myenv/feel/current/hypr.lua` (data murni, `load(..., "t", {})`) dan menggabungkannya di atas default, lalu memetakan ke payload `hl.*` seperti sekarang. Cukup `hyprctl reload`. |
| Neovim | opsional; bisa menyusul (`winblend`, `pumblend`, dsb.) |

Kelas ini **tidak perlu file hasil render**: profil rasa sudah berupa Lua.

### Kelas B — include/variabel

| Konsumen | Mekanisme |
|---|---|
| niri | `include optional=true "~/.myenv/feel/current/niri.kdl"` (lihat §8) |
| rofi | `feel.rasi` berisi variabel (`window-radius`, `element-radius`, …), di-`@import` dari `shared/list.rasi`; hapus radius literal |
| swaync | `feel.css` berisi blok `:root { --radius: …; --hover-transition: … }`; `style.css` meng-`@import` paling atas dan **tidak lagi** mendefinisikan `:root` sendiri |
| eww | `_feel.scss` berisi variabel; `eww.scss` meng-import setelah `theme`; aturan memakai `$radius-bar` dsb. |
| kitty / foot / alacritty | include kedua untuk padding/opacity bila diperlukan; **opacity tetap di WM** agar tidak dobel |

### Kelas C — CSS tanpa variabel (GTK3)

`waybar`, `wlogout`. GTK3 tidak mendukung `var()`, tetapi mendukung `@import`.
Solusi: pecah stylesheet.

```text
waybar/
├── style.css     → @import "base.css"; @import "/home/…/feel/current/waybar.css";
├── base.css      → struktur, warna, semua yang tidak terasa
└── (generated)   → feel/current/waybar.css: hanya aturan yang butuh rasa
```

Aturan penting: `@import` harus di baris paling atas. `feel.css` diimpor
**setelah** `base.css` supaya menang di kaskade. Kalau dibalik, tidak ada efek.

### Kelas D — file utuh hasil generate

`gtk3.css` (app GTK). Tidak ada include yang bisa memparameterkan radius di
GTK3. Untuk sekarang rasa GTK **tetap** (tetap digenerate oleh flow warna).
Ini batas yang disengaja: memaksanya ikut rasa berarti men-generate ulang
seluruh stylesheet GTK setiap kali rasa berganti.

### Terminal dan layer

- **Opacity terminal** sudah ditegakkan WM (`hl.window_rule` di Hyprland,
  `window-rule` di niri). Jangan menambahkan opacity terminal di config
  terminal, atau hasilnya dobel.
- **Translucency layer**: niri bisa `layer-rule { opacity 0.92 }`; Hyprland
  tidak punya opacity di layer rule, jadi harus dari CSS app (`@define-color
  cc-bg alpha(…, 0.80)`). Asimetri ini wajar dan didokumentasikan, bukan dilawan.

---

## 7. Perlu assembler?

**Tidak.** Matugen sudah menjadi renderer untuk warna; ia juga bisa merender
template dari JSON sembarang. Jadi flow rasa:

```bash
matugen json ~/.dotfile/matugen/core/feel/blueprint/default.json \
  -c ~/.dotfile/matugen/core/feel/config.toml
```

```text
matugen/core/feel/
├── blueprint/<profil>.json  ← satu-satunya sumber rasa
├── template/<konsumen>      ← template per konsumen
└── config.toml              ← config render rasa
→ ~/.myenv/feel/current/{scss/_feel.scss, kitty/feel.conf, foot/feel.ini,
                         css/waybar-font.css, css/swaync-font.css}
```

- Dijalankan sekali saat profil dipilih, bukan saat login → tanpa biaya runtime.
- **Render tidak menulis lewat symlink.** Output selalu ke folder konkret
  `~/.myenv/feel/generated/<profil>/`; `feel/current` baru dibalik setelah
  render dan validasi lolos. Pola ini sama dengan `theme/current` dan mencegah
  konsumen membaca profil setengah jadi.
- Warna dan rasa tidak pernah menulis file yang sama, kecuali
  `hypr/theme.lua` yang dipecah.
- Entry point-nya `matugen/feel.sh <profil>` (bukan perintah matugen manual):
  render → cek berkas kosong/placeholder sisa → `sassc` untuk partial SCSS →
  baru flip `feel/current`.

Pemisahan folder template mengikuti keputusan struktur repo: template **warna**
tinggal di `matugen/core/palette/<sumber>/`, template **rasa** di
`matugen/core/feel/template/<konsumen>`, profil rasa di
`matugen/core/feel/blueprint/<profil>.json`, dan satu config render
`matugen/core/feel/config.toml` dipakai bersama semua profil. Jadi satu render
warna dan satu render rasa tidak pernah berbagi folder template maupun berkas
hasil.

Kenapa bukan assembler bash/jq sendiri: itu bahasa template kedua yang harus
dirawat, sementara matugen sudah punya filter yang dibutuhkan
(`set_alpha`, `lighten`, `blend`, `format`). Kenapa bukan “rasa tetap di config
tangan”: berpindah rasa berarti mengedit 6–8 file, dan Hyprland/niri akan
drift.

---

## 8. Integrasi niri

niri 26.04 mendukung include positional yang **merge per-field**, jadi warna
dan rasa bisa dua file terpisah tanpa assembler. Yang sudah diuji dengan
`niri validate`:

```kdl
// niri/config.kdl — paling atas
include optional=true "~/.myenv/theme/current/niri/colors.kdl"
include optional=true "~/.myenv/feel/current/niri.kdl"
```

### 8.1 Fragmen warna (`colors.kdl`)

Hanya warna, tidak menyentuh geometri:

```kdl
layout {
    background-color "00000020"
    border {
        on
        active-gradient from="#8ba4b0" to="#a292a3" angle=45
        inactive-color "#0d0c0cee"
    }
    focus-ring {
        off
    }
}

overview {
    backdrop-color "#4c566a90"
}
```

### 8.2 Fragmen rasa (`niri.kdl`)

```kdl
layout {
    gaps 7
    border {
        width 2
    }
    shadow {
        on
        softness 20
        spread 4
        offset x=0 y=0
        color "#0d0c0cee"
    }
}

// Satu rule global untuk radius; rule spesifik menyusul di bawahnya.
window-rule {
    geometry-corner-radius 8
}

window-rule {
    match app-id="foot"
    opacity 0.9
    background-effect {
        blur true
        xray true
    }
}

layer-rule {
    match namespace="waybar"
    opacity 0.92
    geometry-corner-radius 12
    background-effect {
        blur true
    }
}

animations {
    window-open {
        duration-ms 200
        curve "cubic-bezier" 0.05 0.9 0.1 1.05
    }
}
```

### 8.3 Yang harus dipindah dari config tangan

| Sekarang di | Pindah ke | Alasan |
|---|---|---|
| `niri/config.kdl` → `animations {}` | fragmen rasa | sub-bagian `animations` **tidak di-merge**; dua sumber = salah satu menang diam-diam |
| `conf/layouts/layout.kdl` → warna border/focus | fragmen warna | warna milik palet |
| `conf/layouts/layout.kdl` → `gaps`, `border width`, `shadow` | fragmen rasa | geometri milik rasa |
| `conf/layouts/layout.kdl` → `window-rule` foot/kitty opacity+blur | fragmen rasa | opacity/blur milik rasa |
| `layout { background-color … }`, `overview { backdrop-color … }` | fragmen warna | warna milik palet |

Yang **tetap** di config tangan: `default-column-width`,
`preset-column-widths`, `center-focused-column`, `struts`,
`prefer-no-csd`, monitor/output, input, binds, `window-rule` perilaku
(float/size/center).

### 8.4 Jebakan niri

1. **Section singleton.** Docs menyatakan sebagian besar section tidak boleh
   berulang; jangan mengandalkan dua `layout {}` di file yang sama meskipun
   `validate` diam. Yang resmi adalah `include`.
2. **`border {}` di file included butuh `on` eksplisit**, kalau tidak border
   tidak aktif (special case documented).
3. **`struts`, `preset-column-widths`, tiap sub-bagian `animations` tidak
   di-merge** — jangan dipecah antar file.
4. **Tidak ada saklar blur global** di 26.04: blur dinyalakan per window/layer
   rule. “Blur off” berarti berhenti meng-emit rule blur, bukan menulis satu
   nilai `false`.
5. **Include `optional=true`** (sejak 26.04) wajib dipakai agar boot pertama
   sebelum render tidak gagal.
6. **Reload gratis**: niri me-watch file include dan live-reload. Cukup
   `niri validate -c niri/config.kdl` setelah render.

---

## 9. Noctalia dan toggle shell

Kunci: **profil rasa adalah kontrak**, bukan milik salah satu shell.

```text
~/.myenv/feel/current/          ← sumber rasa (sama untuk semua mode)
~/.myenv/shell/current          ← mode: "rice" | "noctalia"
```

- Mode menentukan **siapa yang jalan**, bukan bagaimana rasa didefinisikan:
  bar (`waybar`/`eww` vs Noctalia), notifikasi (`swaync` vs Noctalia),
  wallpaper, idle/lock, OSD.
- Tabel pemilik fitur disimpan sebagai data di profil shell, bukan `pkill`
  yang tersebar di script.
- Adapter Noctalia nanti membaca profil yang sama (Noctalia punya mekanisme
  `[include]` di config-nya — **perlu diverifikasi saat integrasi**, jangan
  diasumsikan).
- Karena itu jaga jumlah token tetap kecil: `radius`, `gaps`, `opacity`,
  `blur` on/off + strength, `motion.speed`/`character`. Kalau Noctalia tidak
  punya padanan untuk sebuah token, token itu tidak boleh jadi alasan
  memecah sistem.

---

## 10. Risiko dan gotcha

1. **Matugen gagal diam-diam pada key hilang** → validasi profil sebelum
   render; jangan andalkan default template.
2. **`@import` CSS harus di baris pertama**; kalau tidak, waybar/swaync tidak
   berubah sama sekali.
3. **Blur off di niri** harus juga menghapus rule blur statis yang sudah ada
   (foot/kitty/waybar), bukan hanya tidak menambah rule baru.
4. **`hyprctl reload` hanya membaca `theme.lua` + `feel.lua`**; pastikan tidak
   ada nilai rasa yang masih tertinggal di `theme.lua`.
5. **Jangan dokumentasikan perilaku yang belum ada.** Setelah tiap fase,
   perbarui §2 dokumen ini.
6. **GTK3 tanpa `var()`** → satu-satunya konsumen yang butuh refactor
   stylesheet; jangan mengira `@define-color` bisa menyimpan angka.
7. **Opacity ganda** (WM + terminal/CSS app) membuat hasil lebih transparan
   dari yang dirancang. Satu pemilik per nilai.

---

## 11. Fase implementasi

> Fase 0 sudah dimulai dari sumbu **font** (bukan geometry): lihat §2.4. Sisa
> Fase 0 (geometry/material/motion keluar dari blueprint) belum dikerjakan.

| Fase | Isi | Kriteria selesai |
|---|---|---|
| 0 | Angkat `feel` dari blueprint ke `matugen/core/feel/blueprint/<profil>.json` + `matugen/core/feel/config.toml`; pecah `current/hypr/` jadi `theme.lua` + `feel.lua`; `hypr/config/core/theme.lua` memuat keduanya | Tampilan Hyprland identik dengan sebelum perubahan; `luac -p` lolos; Flow A tetap jalan |
| 1 | `colors.kdl` + `niri.kdl`; pindahkan warna/animasi/opacity dari config tangan; `include optional=true` | `niri validate -c niri/config.kdl` exit 0; tampilan niri sama + warna dari palet |
| 2 | swaync `:root`, eww `_feel.scss`, rofi `feel.rasi`, waybar `base.css` + `feel.css` | Ganti profil → radius/translucency bar, menu, notifikasi ikut berubah tanpa edit file |
| 3 | Profil kedua yang kontras (flat: radius 0, blur off, shadow off, speed 1.4) | Dua profil bisa ditukar bolak-balik; warna tidak berubah |
| 4 | Mode shell (`rice` / `noctalia`) + adapter Noctalia | Toggle mematikan/menyalakan daemon sesuai tabel pemilik; rasa tetap sama |

Urutan reload, pemilihan sesi, dan abstraksi engine (matugen vs Noctalia)
dibahas terpisah di [`THEME_ENGINE.md`](THEME_ENGINE.md).

Urutan ini sengaja: Fase 0 dan 1 sudah menyelesaikan keluhan utama (rasa tidak
lagi hanya milik Hyprland), sedangkan konsumen non-shell bisa menyusul tanpa
memblokir integrasi niri.

---

## 12. Verifikasi yang sudah dilakukan untuk rancangan ini

- `niri --version` → `niri 26.04 (Nixpkgs)`.
- `niri validate` pada config uji (`/tmp`, bukan config aktif) dengan:
  `include optional=true` fragmen warna (`layout { border { active-gradient … } }`),
  fragmen rasa (`layout { gaps … }`, `window-rule`, `layer-rule`, `animations`),
  dan config utama berisi `layout { gaps 12; default-column-width … }`
  → **config is valid**, exit 0.
- `layer-rule` dengan `opacity`, `geometry-corner-radius`, `background-effect
  { blur true; xray true }`, dan `shadow { on; softness 20; spread 2 }`
  → valid.
- Key asing (`nope 1`) → gagal dengan `unexpected node`, jadi `validate`
  memang memeriksa skema, bukan hanya sintaks.
- Docs resmi niri (Layout, Layer Rules, Animations, Include) dibaca untuk
  semantik merge, non-merging section, dan special case `border`.
- Sisi Hyprland diverifikasi dari `hypr/config/core/theme.lua` dan
  `hypr/hyprland.lua` di repo ini (default, clamp, pemetaan, layer blur).

---

## 13. Referensi

- niri — Configuration: Include (merge positional, `optional=true`, batas
  include di top-level, special case `border`).
- niri — Configuration: Layout (`gaps`, `border`/`focus-ring` + gradient,
  `shadow`, `tab-indicator`, `struts`).
- niri — Configuration: Layer Rules (`opacity`, `geometry-corner-radius`,
  `background-effect`, `popups`).
- niri — Configuration: Animations (spring vs easing, `cubic-bezier` 4 angka,
  `custom-shader`).
- Repo: `hypr/config/core/theme.lua`, `hypr/hyprland.lua`,
  `matugen/core/palette/wallpaper-based/template/hypr.lua`,
  `matugen/core/palette/kanagawa-dragon-lotus/template/hypr.lua`,
  `matugen/core/palette/kanagawa-dragon-lotus/blueprint/README.md` §3.11.
