# Noctalia × matugen

> Indeks: [`README.md`](../README.md) · terkait: [`WM_FEEL_MATRIX.md`](WM_FEEL_MATRIX.md)
>
> Dua bagian: **§1–§4** pembagian pemilik warna + fakta config shell;
> **§5–§9** = *palette engine* Noctalia (hasil uji pada **noctalia 5.4.1**,
> 2026-11-16) dan pemetaannya ke kosakata template repo ini.
> Bagian §5–§9 menjawab "bisa tidak Noctalia jadi sumber warna seperti matugen",
> bukan "bagaimana keduanya disandingkan" — mekanisme penyandingan adalah scope
> terpisah.

**Status: catatan fakta, bukan rancangan.** §1–§4 diambil dari docs resmi
Noctalia v5 dan file repo; §5–§9 dari docs resmi **plus** uji CLI di mesin ini.
Setiap klaim di §5–§9 ditandai: **[V]** = diverifikasi di sini, **[D]** = hanya
dari dokumentasi, **[?]** = belum diuji.

---

## 1. Pembagian yang sudah berlaku

- **Warna punya satu pemilik per WM.** Saat Noctalia hidup, `palette.sh`
  melewati gtk/swaync/waybar (`if running noctalia; then skip …`). Kalau suatu
  saat template compositor Noctalia dipakai, include warna kita untuk WM itu
  harus dimatikan — jangan dua include aktif bersamaan. Keputusan pemilik
  diambil sekali saat integrasi, bukan dideteksi otomatis.
- **Rasa selalu milik flow kita.** Template Noctalia membawa token warna,
  `mode`, `image`, `closest_color`; tidak ada jalur terdokumentasi untuk skalar
  bebas (angka/string) maupun aritmetika. Karena itu `~/.myenv/theme/feel/current/*`
  tetap dirender `matugen/json` dari profil kita. Noctalia hanya bisa mengatur
  rasa untuk dirinya sendiri lewat config TOML-nya.

## 2. Fakta Noctalia v5

- **Config:** semua `*.toml` di `~/.config/noctalia/` dibaca urut alfabet lalu
  digabung. `[include] files = [...]` menerima file atau direktori,
  `autoload = false` untuk memilih profil. File yang meng-include menang atas
  isi include.
- **Load order:** `*.toml` di `~/.config/noctalia/` dimuat dulu, lalu
  `~/.local/state/noctalia/settings.toml` (tulisan GUI) yang menang saat key-nya
  sama. Di mesin ini layer itu sengaja dikosongkan (`config_version = 14` saja),
  jadi `config.toml` yang menentukan.
- **Hot reload:** kedua layer di-watch, perubahan berlaku ~150 ms setelah
  disimpan.
- **Validasi/inspeksi:** `noctalia config validate` (exit 1 hanya untuk error;
  warning key usang tidak menggagalkan) dan `noctalia config export` /
  `export full`.
- **Template:** context = 48 role Material + `hover`/`on_hover` + token
  terminal + `palettes.*`, plus `mode`, `image`, `closest_color`. Mendukung blok
  `<* *>`, filter warna/string, loop/conditional, `[config.custom_colors]`
  (menambah **role warna**, bukan variabel), hook, dan `output_path_dynamic`.
  Template tidak menulis ulang file yang isinya tidak berubah.
- **Template compositor bawaan:** Niri → `niri/noctalia.kdl` (plus include ke
  `niri/config.kdl`); Hyprland Lua → `hypr/noctalia.lua` (plus
  `dofile(...).apply_theme()`).
- **Batasnya:** karena context hanya token warna + tiga kunci di atas, rasa
  (radius, gap, blur, motion) tidak bisa dirender lewat template Noctalia.

## 3. Di repo ini

- `noctalia/config.toml` adalah **satu-satunya sumber kebenaran**: isinya hasil
  `noctalia config export` dari state lama, dan state itu sudah dikosongkan
  (`config_version = 14`) supaya tidak ada key yang menimpa. Backup state lama:
  `~/.local/state/noctalia/settings.toml.bak-20261111` (di luar repo).
- JSON v4 (`settings.json`, `plugins.json`) dan direktori kosong sisa v4 sudah
  dibuang — v5 hanya membaca TOML dan tidak memigrasikan JSON lama.
- Kalau suatu saat ada yang diubah lewat GUI Settings, override akan muncul lagi
  di `settings.toml` dan menang; ekspor ulang ke `config.toml` lalu kosongkan
  state lagi kalau ingin tetap deklaratif.
- `noctalia/palettes/*.json` tetap format 1 (`dark`/`light` + `mPrimary`…); v5
  masih menerimanya lewat `[theme] source = "custom"` +
  `custom_palette = "<nama file tanpa .json>"`.
- `matugen/script/palette.sh` sudah melewati gtk/swaync/waybar selama proses
  Noctalia hidup.

## 4. Wajib dicek saat integrasi

1. Apakah `[include]` benar-benar ada di versi terpasang (bukan hanya di docs)?
2. Apakah template compositor Noctalia menambah include sendiri ke
   `niri/config.kdl` / `hypr/*.lua`; kalau ya, matikan include warna kita untuk
   WM itu.
3. Apakah template bawaan menulis ke `~/.config/kitty`, `foot`, `alacritty`,
   dsb. — bisa dobel dengan `include` kita ke `theme/palette/current/`.
4. `noctalia config validate` harus exit 0 sebelum file hasil render dipakai.

---

# Bagian II — palette engine Noctalia

## 5. Bentuk engine

Engine punya **dua tahap yang terpisah**, dan itu penting untuk dipakai seperti
matugen:

| Tahap | Yang dilakukan | Bisa dipanggil tanpa shell hidup? |
|---|---|---|
| **Resolver** | memilih/menghasilkan palet dari `[theme]` (builtin, community, custom, wallpaper) menjadi *token map* per mode | ya, lewat CLI — **[V]** |
| **TemplateEngine** | merender file dari token map itu (`{{ … }}`, `<* … *>`, filter, hook) | ya, lewat CLI — **[V]** |

Dokumentasi resmi menegaskan TemplateEngine **tidak** memuat gambar atau
mengekstrak palet. Konsekuensinya: warna dan render bisa dipanggil terpisah,
persis pola `matugen image` → `matugen` render.

### 5.1 Sumber palet `[theme].source` **[D]**

| `source` | Perilaku |
|---|---|
| `builtin` | palet yang dikompilasi ke binary (Ayu, Catppuccin, Dracula, Eldritch, Gruvbox, Kanagawa, Noctalia, Nord, Rosé Pine, Tokyo-Night) |
| `wallpaper` | palet Material You dibuat dari wallpaper aktif setiap kali wallpaper berubah; generator dipilih `wallpaper_scheme` |
| `community` | diambil dari `api.noctalia.dev/palette/<name>` lalu di-cache |
| `custom` | membaca `~/.config/noctalia/palettes/<custom_palette>.json` |

Key lain yang relevan: `mode` (`dark`/`light`/`auto`), `shell_mode`,
`pure_black_dark`, `sync_color_scheme`, `builtin`, `community_palette`,
`custom_palette`, `wallpaper_scheme`.

Nilai `wallpaper_scheme` **[D]**: `m3-tonal-spot`, `m3-content`,
`m3-fruit-salad`, `m3-rainbow`, `m3-monochrome`, `vibrant`, `faithful`,
`dysfunctional`, `muted`. Konfigurasi mesin ini memakai `m3-content`, mode
`dark`, `pure_black_dark = true`, `source = "community"` +
`community_palette = "Kanagawa Dragon"` — jadi `noctalia/palettes/*.json` di
repo **belum** aktif jadi sumber (`custom_palette` hanya dibaca saat
`source = "custom"`).

### 5.2 Berkas palet custom **[D] + [V]**

- Lokasi: `~/.config/noctalia/palettes/<nama>.json` (v4: `colorschemes/`).
- **Format 1** (tanpa `version`): key `mPrimary`, `mOnPrimary`, …, plus objek
  `terminal` (`normal`/`bright`/`foreground`/`background`/`cursor`/`cursorText`/
  `selectionFg`/`selectionBg`). Ini format `noctalia/palettes/*.json` di repo.
- **Format 2** (`"version": 2`): key = nama role snake_case (`primary`,
  `on_primary`, `surface_container`, `outline_variant`, …) + `terminal`.
- Palet hanya menetapkan 16 role + terminal; sisanya **diturunkan** (container,
  `surface_container_high/highest`, `on_*` container) atau diambil dari skema
  Material saat palet digenerate dari wallpaper.
- Nama role baru: `surface_container` (dulu `mSurfaceVariant`) dan
  `outline_variant` (dulu `mOutline`).
- Kedua format diterima `--theme-json` **[V]** (lihat §6.2).

### 5.3 Konteks template **[D] + [V]**

Token diakses `colors.<token>.<mode>.<format>`:

- `<mode>`: `default` (= mode aktif), `dark`, `light`. Ketiganya bisa dipakai
  dalam satu render **[V]**.
- Token: 48 role Material (`primary`, `on_primary`, `primary_container`,
  `primary_fixed`, `on_primary_fixed_variant`, `surface`, `surface_dim`,
  `surface_bright`, `surface_container_lowest`, `surface_container_low`,
  `surface_container`, `surface_container_high`, `surface_container_highest`,
  `on_surface`, `on_surface_variant`, `surface_variant`, `outline`,
  `outline_variant`, `shadow`, `scrim`, `inverse_surface`, `background`,
  `error*`, `secondary*`, `tertiary*`, …), `hover`/`on_hover`, dan 22 token
  terminal:
  `terminal_{foreground,background,cursor,cursor_text,selection_fg,selection_bg}`,
  `terminal_{normal,bright}_{black,red,green,yellow,blue,magenta,cyan,white}`.
- Nilai langsung: `mode`, `image`, `closest_color`, `config_dir`, `config_file`.
- Tonal: `palettes.<primary|secondary|tertiary|error|neutral|neutral_variant>.<tone>.<format>`
  — tone 0–100 bebas, plus bentuk `_99` yang kompatibel matugen.

**Format keluaran [D] + [V]**

| Format | Hasil terukur |
|---|---|
| `hex` | `#88d1ec` |
| `hex_stripped` | `0f1416` |
| `rgb` | `rgb(r, g, b)` |
| `rgb_csv` | `136,209,236` |
| `rgba` | `rgba(136, 209, 236, 1)` |
| `hsla` | `hsla(196, 72%, 72%, 1)` |
| `hsl` | `hsl(h, s%, l%)` |
| `red`/`green`/`blue` | kanal 0–255 |
| `alpha` | `1` |
| `hue`/`saturation`/`lightness` | integer |

**Filter [D] + [V]**: `grayscale`, `invert`, `set_alpha`, `set_lightness`,
`set_hue`, `rotate_hue`, `set_saturation`, `set_red/green/blue`, `lighten`,
`darken`, `saturate`, `desaturate`, `auto_lightness`; filter berargumen warna
`blend`, `harmonize`, `to_color`; filter string `replace`, `lower_case`,
`camel_case`, `pascal_case`, `snake_case`, `kebab_case`. Argumen boleh
`filter arg` maupun `filter: arg` **[V]** (`lighten: -10` = `lighten -10` =
`#5cc0e5`).

**Blok**: `<* for … *>`, `<* if {{ expr }} *>`, `<* else *>`, `<* endif *>`,
`<* endfor *>`; `loop.index/first/last`; tag blok yang berdiri sendiri di satu
baris ikut terhapus (trimming). Catatan resmi: ini **bukan** Tera — template
matugen harus diadaptasi.

### 5.4 Antarmuka CLI **[V]**

`noctalia theme` bisa dipakai tanpa shell berjalan:

| Perintah | Guna |
|---|---|
| `noctalia theme <gambar> --both -o out.json` | palet dari gambar → JSON token (74 key per mode) |
| `noctalia theme <gambar> --scheme m3-content --dark --pure-black -o out.json` | varian/skema/OLED |
| `noctalia theme --theme-json out.json -r in.txt:out.txt` | render satu template dari JSON, tanpa gambar |
| `noctalia theme --theme-json <file> -c cfg.toml` | batch render; `[templates.*]` dengan `input_path`/`output_path`/hook |
| `noctalia theme --list-templates` | daftar template builtin + community cache + user |
| `noctalia theme <gambar> --builtin-config` | jalankan katalog builtin |
| `noctalia theme --default-mode light` | `default` mengikuti mode terang |

`-o` menghasilkan **token map datar** per mode: **74 key** = 50 token Material
(48 role + `hover`/`on_hover`) + `source_color` + `surface_tint` + 22 token
terminal. Jadi Noctalia punya padanan `matugen image --json`: palet bisa
di-*dump* tanpa menyentuh config aplikasi.

Template builtin **[V]** (20 entri): `cava`, `hyprland`, `labwc`, `mango`,
`niri`, `scroll`, `sway`, `umbriel`, `emacs`, `helix`, `btop`, `gtk3`, `gtk4`,
`kcolorscheme`, `qt`, `alacritty`, `foot`, `ghostty`, `kitty`, `wezterm` —
artinya terminal & GTK sudah punya template bawaan; yang tidak ada bawaan:
rofi, yazi, lazygit, herdr, waybar/swaync, nvim, scss.

### 5.5 Alur pakai sebagai engine (padanan `matugen image`) **[V]**

Bentuknya sama dengan matugen; bedanya palet dan render dipanggil oleh
perintah yang sama, dan palet harus sudah berbentuk JSON:

| Langkah | matugen | Noctalia |
|---|---|---|
| 1. palet | implisit di `matugen image` | `noctalia theme <gambar> --both -o palet.json`, **atau** pakai file palet yang sudah ada |
| 2. daftar template | `[templates.x]` + `input_path`/`output_path` di `config.toml` | `[templates.x]` + `input_path`/`output_path` — sintaks TOML yang sama |
| 3. render | `matugen image … -c config.toml` | `noctalia theme --theme-json palet.json -c config.toml` |

Contoh minimal (terverifikasi berjalan):

```toml
# /tmp/noc-demo/cfg.toml
[templates.kitty]
input_path = "in.txt"          # relatif → relatif ke cwd, bukan ke file config [V]
output_path = "out.txt"
post_hook = "echo HOOK_RAN > /tmp/noc-demo/hook.txt"
hook_async = false             # hook selesai sebelum perintah keluar [V]
```

```bash
noctalia theme --theme-json palet.json -c /tmp/noc-demo/cfg.toml   # batch
noctalia theme --theme-json palet.json -r in.txt:/tmp/out.txt      # satu file
```

Fakta pendamping **[V]**:

- `-r` dan `-c` menghasilkan byte identik untuk template + palet yang sama.
- Satu pemanggilan `-c` memakai **satu** palet JSON untuk semua template di
  dalamnya.
- `post_hook` jalan setelah file ditulis; tanpa `hook_async = false` hook
  berjalan asinkron (§6 baris 8).
- `[config]` tidak wajib; `[templates.*]` saja sudah cukup (§6 baris 7).
- Tidak ada `-p <store>`, tidak ada validasi hasil: render ke `/tmp`, cek sisa
  `{{`/`<*`, lalu pindahkan ke store dan flip `current` — itu tugas pemanggil
  (`palette.sh`), bukan engine.

Sumber `palet.json` yang tersedia tanpa menyalakan shell:

| Sumber | Cara |
|---|---|
| wallpaper | `noctalia theme "<gambar>" --both -o palet.json` |
| palet repo (`noctalia/palettes/*.json`) | langsung, format 1 diterima (§6 baris 4) |
| palet community | `~/.local/state/noctalia/community-palettes/<Nama>.json` (§7.5) |

## 6. Jebakan terverifikasi (semua **[V]**, noctalia 5.4.1)

| # | Gejala | Penyebab / aturan |
|---|---|---|
| 1 | Seluruh file gagal, pesan cuma `1 template error(s); output not written`; `post_hook` **tidak** jalan | satu token tak dikenal (`colors.nonexistent…`) menggagalkan render — tidak ada output parsial, tidak ada nilai default |
| 2 | `{{ colors.primary.default.hex \| format: rgba }}` menghasilkan hex apa adanya | filter tak dikenal **diabaikan diam-diam** (bukan error) — idiom matugen `\| format: …` tidak berlaku |
| 3 | `{{ … .hex \| set_alpha 0.5 }}` tetap `#88d1ec` | `set_alpha` pada format `hex` tidak berpengaruh; alpha hanya terlihat di `rgba` → `rgba(136, 209, 236, 0.5)` |
| 4 | `{{ … .hex_alpha }}` jadi `#88d1ec` | `hex_alpha` bukan format Noctalia; alpha hilang diam-diam (di matugen ini format sah) |
| 5 | `<* if {{ colors.warning }} *>` → template error | conditional hanya menerima skalar/string/angka/bool; objek warna tidak bisa diuji. `if {{ mode }}` aman |
| 6 | `{{ config_dir }}` kosong | terisi hanya saat render lewat `-c` (nilainya relatif terhadap cwd/config), kosong pada `-r` |
| 7 | `[templates.x]` tanpa `[config]` tetap jalan | `[config]` tidak wajib di config CLI (beda dengan config matugen yang wajib) |
| 8 | `post_hook` tidak selesai sebelum perintah lain | hook default **async** (`hook_async = true`); set `false` untuk hook yang harus selesai/berurutan |
| 9 | File tidak berubah mtime-nya | engine melewati penulisan bila isi identik — reload berbasis inotify bisa tak terpicu |
| 10 | Warna custom tidak persis hex aslinya | `custom_colors` default `blend = true` → diharmonkan ke palet (`#f97316` → `#ffb878`); `blend = false` untuk mempertahankan hue |

## 7. Pemetaan ke kosakata repo

### 7.1 Role & format

Kabar baiknya: **role Material Noctalia = role Material matugen**, jadi template
alur wallpaper (`wallpaper-based`) bisa dipindah dengan penamaan ulang saja.

| matugen | Noctalia | Catatan |
|---|---|---|
| `{{ colors.<role>.default.hex }}` | `{{ colors.<role>.default.hex }}` | identik |
| `{{ colors.<role>.dark.hex }}` / `.light.hex` | sama | `.dark`/`.light` selalu tersedia, bukan hanya mode aktif **[V]** |
| `hex_stripped` | `hex_stripped` | foot butuh ini — aman |
| `rgba` | `rgba` | Noctalia menulis `rgba(r, g, b, a)` |
| `hex_alpha` | **tidak ada** | pakai `rgba`, atau bungkus alpha lain di sisi konsumen |
| `\| lighten: -10`, `\| set_alpha: 0.7`, `\| blend: "#f00", 0.5` | sama (titik dua opsional) | **[V]** |
| `\| format: …` | **tidak ada** | filter tak dikenal = no-op diam-diam |
| `{% if %}` / `{% for %}` | `<* if {{ x }} *>` / `<* for x in … *>` | warna tidak bisa jadi kondisi |
| `<* for c in colors *>` (iterasi role) | `<* for name, value in colors *>` | sama-sama map; Noctalia butuh dua variabel untuk key+value |
| `palettes.<family>.<tone>` | sama, tone `0`–`100`; `_99` diterima | kompatibel matugen |

### 7.2 Template alur wallpaper (Flow A)

Token yang benar-benar dipakai template Flow A di repo ini (union, 33 token):

`primary`, `secondary`, `tertiary`, `on_primary`, `on_secondary_container`,
`on_primary_container`, `on_tertiary`, `on_tertiary_container`,
`primary_container`, `secondary_container`, `secondary_fixed`,
`secondary_fixed_dim`, `tertiary_container`, `tertiary_fixed`,
`tertiary_fixed_dim`, `error`, `error_container`, `surface`, `surface_dim`,
`surface_variant`, `surface_container`, `surface_container_low`,
`surface_container_lowest`, `surface_container_high`,
`surface_container_highest`, `on_surface`, `on_surface_variant`, `outline`,
`outline_variant`, `shadow`, `scrim`, `background`, `source_color`.

Semua ada di token Noctalia **[V/S]** — kecuali tiga hal: `hex_alpha` (→ `rgba`),
`| format:` (dihapus), dan `source_color` yang di Noctalia hanya muncul di JSON
`-o`, bukan sebagai `colors.*` di template **[?]** (belum diuji sebagai token).
Jadi port Flow A = **cari-ganti token + tiga perbaikan format**, bukan desain
ulang.

### 7.3 Kosakata alur blueprint (`accent.*`, `surface.*`, `syntax.*`, …)

Template `kanagawa-dragon-lotus` memakai kosakata semantik sendiri. Noctalia
tidak punya token itu, jadi harus dipetakan ke role/terminal/custom color.
Usulan (belum diputuskan, bukan fakta):

| Key repo | Ekspresi Noctalia | Status |
|---|---|---|
| `background` | `colors.surface_container_lowest.default.hex` (atau `colors.background…`) | pilihan desain |
| `foreground` | `colors.on_surface.default.hex` | kuat |
| `cursor` | `colors.terminal_cursor.default.hex` (atau `primary`) | kuat |
| `color0`…`color15` | `colors.terminal_normal_<c>` / `colors.terminal_bright_<c>` | **1:1**, ANSI sudah benar |
| `accent.primary` / `on_primary` | `primary` / `on_primary` | 1:1 |
| `accent.secondary` / `tertiary` | `secondary` / `tertiary` | 1:1 |
| `accent.*_container` / `on_*_container` | role `*_container` yang sama | 1:1 |
| `accent.on_secondary` / `on_tertiary` | `on_secondary` / `on_tertiary` | 1:1 |
| `text.primary` | `colors.on_surface…` | 1:1 |
| `text.secondary` | `colors.on_surface_variant…` | 1:1 |
| `text.muted` | `on_surface_variant.rgba \| set_alpha 0.7` | sama seperti `source.rasi` sekarang |
| `text.subtle`/`faint`/`disabled` | `on_surface_variant` + `darken/lighten` atau alpha | perlu keputusan |
| `text.link` / `text.visited` | `primary` / `tertiary` | perlu keputusan |
| `surface.lowest` | `surface_container_lowest` | 1:1 |
| `surface.low` | `surface_container_low` | 1:1 |
| `surface.base` | `surface` | 1:1 |
| `surface.medium` | `surface_container` | 1:1 |
| `surface.high` | `surface_container_high` | 1:1 |
| `surface.highest` | `surface_container_highest` | 1:1 |
| `surface.track` | `surface_container_high` (atau `outline_variant`) | perlu keputusan |
| `border.default` | `outline_variant` | 1:1 |
| `border.medium` | `outline` | 1:1 |
| `border.active` | `primary` | 1:1 |
| `status.error` / `error_container` | `error` / `error_container` | 1:1 |
| `status.critical` | `error` + `darken` | perlu keputusan |
| `status.warning` / `warning_container` | `custom_colors.warning` → `warning` / `warning_container` | **[V]** (lihat §6.10) |
| `status.success` / `status.info` | `custom_colors.success` / `.info` | **[V]** mekanismenya sama |
| `effect.shadow` | `shadow` | 1:1 |
| `effect.scrim` | `scrim` + alpha di template (`rgba \| set_alpha`) | format harus diganti |
| `syntax.*` (27 token) | **tidak ada padanan** | lihat §7.4 |

`[config.custom_colors]` menghasilkan, per mode: `{name}_source`, `{name}_value`,
`{name}`, `on_{name}`, `{name}_container`, `on_{name}_container` — jadi
`status.*` bisa direproduksi tanpa menambah template.

### 7.4 Yang tidak punya padanan

1. **`syntax.*` / rasa.** Engine hanya punya warna. Pilihan: (a) tabel tetap
   role→syntax di dalam template (pola Flow A `nvim.lua` sekarang), atau
   (b) pindahkan pemetaan ke konsumen (`nvim/lua/core/theme.lua`, tempat
   `blend()` tinggal). Ini keputusan desain, bukan kemampuan engine.
2. **`hex_alpha` / `format:`.** Tidak ada; alpha hanya lewat `rgba` atau dihitung
   konsumen. `source.rasi` memakai `effect-scrim` ber-alpha → template itu perlu
   ditulis ulang, dan perlu diuji apakah rofi menerima `rgba(...)` di variabel
   `*` **[?]**.
3. **Skalar bebas / aritmetika.** Tidak ada `{{ feel.shape.radius }}`.
4. **Pemilihan `--source-color-index`.** matugen memilih warna sumber dari
   gambar; Noctalia memilih sendiri (skema `wallpaper_scheme`). Tidak ada
   padanan flag **[?]**.
5. **Store/`-p` + flip `current`.** Engine menulis ke `output_path` (string atau
   array, absolut atau relatif ke config), bukan ke satu prefiks store. Pola
   render-ke-tmp → validasi → flip `current` (seperti `palette.sh`) harus
   dilakukan pemanggil, bukan engine.
6. **Blueprint sebagai input template engine.** `--theme-json` menerima format 1
   dan 2 **[V]**, tapi hanya 16 role + terminal; key bebas blueprint
   (`accent.*`, `syntax.*`) tidak ikut jadi konteks.

### 7.5 Palet community (contoh: Kanagawa Dragon) **[V]**

Kata "community" di Noctalia menunjuk dua hal berbeda — jangan tertukar:

| Istilah | Isinya | Lokasi cache |
|---|---|---|
| **palette** community | 16 role + `terminal` (format 1 `mPrimary…`) | `~/.local/state/noctalia/community-palettes/<Nama>.json` (+ `.catalog/palettes.json`) |
| **template** community | paket config aplikasi (bukan palet) | `~/.local/state/noctalia/community-templates/<id>/template.toml` |

Palet community bisa langsung jadi sumber engine, tanpa konversi — file
cache-nya sudah format 1:

```bash
noctalia theme --theme-json \
  "$HOME/.local/state/noctalia/community-palettes/Kanagawa%20Dragon.json" \
  -r in.txt:out.txt
```

Nilai terukur dari file itu (`dark`/`light`), dipakai template:

| Token | dark | light |
|---|---|---|
| `surface` | `#181616` | `#c5c9c5` |
| `on_surface` | `#c5c9c5` | `#181616` |
| `surface_variant` | `#282727` | `#c8c093` |
| `primary` | `#8a9a7b` | `#606d54` |
| `tertiary` | `#c4746e` | `#ae4e47` |
| `outline` | `#625e5a` | `#8a9a7b` |
| `terminal.red` / `.green` / `.blue` | `#c4746e` / `#8a9a7b` / `#8ba4b0` | sama |

Pemetaannya **tidak berubah**: token yang dibaca template tetap §7.1–§7.3,
yang berbeda hanya asal angkanya. Jadi template yang sudah jalan dengan palet
wallpaper langsung jalan dengan Kanagawa Dragon.

Yang perlu diketahui:

- Palet community hanya menetapkan **17 key per mode** (16 role + `terminal`).
  Container dan `on_*_container` **diturunkan engine**, bukan angka penulis
  palet: diuji `surface_container_lowest` `#1b1919`, `surface_container`
  `#282727`, `surface_container_high` `#323131`, `primary_container` `#3a3d34`,
  `on_primary_container` `#9aab8b`, `outline_variant` `#625e5a`,
  `surface_tint` `#8a9a7b`.
- Konsekuensinya urutan ramp tidak selalu seperti M3: di palet ini
  `surface_container_lowest` (`#1b1919`) justru **lebih terang** dari `surface`
  (`#181616`). Jangan mengandalkan "lowest = paling gelap" pada palet custom/
  community; pilih role sesuai hasil render (§6 baris 1: satu token hilang =
  satu file gagal).
- `.dark`/`.light` terbaca benar termasuk saat mode aktif `dark`:
  `colors.surface.light.hex` = `#c5c9c5`.
- Nama file memakai spasi ter-encode (`Kanagawa%20Dragon.json`) — kutip path-nya.
- **Template community tidak bisa dirender lewat `-c` offline.** Cache hanya
  menyimpan `template.toml` + `.noctalia-cache.json`; `input_path`-nya
  (`tele-colors.yml`, `noctalia.lua`, …) tidak ikut ter-cache, sehingga perintah
  keluar tanpa error **dan tanpa file output**. Itu paket untuk renderer shell,
  bukan template palet untuk repo ini — template kita tetap file sendiri yang
  didaftarkan di config `-c` (§5.5).

## 8. Resep mem-port satu template

1. Ganti sintaks blok: `{% %}` → `<* *>`, `{{#if}}` → `<* if {{ … }} *>`.
2. Ganti `hex_alpha` → `rgba`; buang `| format:`; pastikan `set_alpha` hanya
   dipakai pada `rgba`.
3. Petakan token (§7.2 bila template Flow A, §7.3 bila blueprint).
4. Uji ke `/tmp` dulu, **satu ekspresi per file** — pesan error hanya
   `1 template error(s)`, jadi bisect per baris:

   ```bash
   noctalia theme --theme-json /tmp/noc-theme.json -r /tmp/t.txt:/tmp/o.txt
   ```

   Palet acuan bisa dibuat tanpa menyentuh config:
   `noctalia theme "<wallpaper>" --both -o /tmp/noc-theme.json`.
5. Periksa hasil: tidak ada `{{`, `<*`, dan tidak ada hex yang "aneh" (tanda
   filter no-op seperti §6.2).
6. Baru daftarkan ke config render yang sebenarnya (`[templates.*]` dengan
   `input_path`/`output_path`/`post_hook`), plus `hook_async = false` untuk hook
   yang harus selesai berurutan (mis. reload yang menyentuh file yang sama).

## 9. Pertanyaan terbuka

- Apakah `source_color` tersedia sebagai `colors.source_color.*` di template
  (di JSON `-o` ada)?
- Apakah user template di config shell (`[theme.templates.user.*]`) dan config
  CLI (`-c`) bisa berbagi file config yang sama tanpa saling mengganggu?
- Bagaimana `output_path_dynamic` dan `post_action` berperilaku di CLI (belum
  diuji; hanya `output_path` array yang terbukti)?
- Apakah `output_path` menerima `~` dan `$XDG_CONFIG_HOME` di CLI `-c`
  (template komunitas memakainya, belum diuji langsung)?
- Apakah rofi menerima `rgba(r, g, b, a)` sebagai nilai variabel `*` (pengganti
  `hex_alpha` di `source.rasi`)?
- Apakah `--theme-json` menerima JSON yang hanya punya satu mode (bukan
  `dark`+`light`)?
