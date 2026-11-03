# Theme Engine: Reload Mulus & Abstraksi

> Indeks: [`README.md`](README.md) · terkait: [`FEEL.md`](FEEL.md),
> [`WM_FEEL_MATRIX.md`](WM_FEEL_MATRIX.md)

**Status: rancangan.** Yang dijelaskan di sini belum diterapkan. Fakta tentang
Noctalia diambil dari docs resmi v5 (configuration & template reference); fakta
tentang repo diambil dari file yang disebut.

Dokumen ini menjawab tiga hal:

1. Bagaimana mengganti tema tanpa me-reload/render bagian WM yang **tidak**
   sedang dipakai.
2. Bagaimana theme engine bisa punya **abstraksi**: sumber warna bisa matugen,
   bisa Noctalia.
3. Kenapa **rasa** tidak boleh bergantung pada template Noctalia, dan bagaimana
   abstraksinya dibuat menguntungkan.

---

## 1. Masalah yang diselesaikan

Sekarang:

- Tidak ada yang memilih tema secara otomatis di repo ini. `current` di-flip
  manual (atau oleh `theme-switcher.sh` di luar repo). Render Flow A/B menulis
  ke folder tema, bukan ke `current`.
- Post-hook matugen berjalan **tanpa tahu sesi**: `hyprctl reload` dipanggil
  dari template hypr meskipun sesi yang jalan niri, dan sebaliknya nanti.
- Rasa dan warna berbagi file di Hyprland (`current/hypr/theme.lua`).
- Belum ada konsep “engine mana yang memiliki warna”.

Target:

- Satu perintah `theme apply` yang: render hanya yang perlu → validasi →
  aktifkan atomik → reload hanya konsumen di sesi aktif.
- Dua engine warna yang bisa ditukar tanpa mengubah konsumen.
- Rasa tetap satu sumber, dirender oleh komponen yang memang bisa membawa
  angka/string.

---

## 2. Tiga kontrak

Semua abstraksi berdiri di atas tiga artefak. Ini yang membuat engine bisa
ditukar.

### 2.1 `palette.json` — kontrak warna

Bentuk ternormalisasi dari palet aktif. Minimal memuat key yang sudah dipakai
template repo:

```jsonc
{
  "meta": { "name": "kanagawa-dragon-lotus", "variant": "dark", "engine": "matugen" },
  "background": "#181616",
  "foreground": "#c5c9c5",
  "cursor": "#C8C093",
  "colors": ["#0d0c0c", "…16 entri…"],
  "accent": { "primary": "#8ba4b0", "on_primary": "#0d0c0c", "…": "…" },
  "text": { "primary": "…", "muted": "…", "…": "…" },
  "surface": { "lowest": "…", "base": "…", "…": "…" },
  "border": { "default": "…", "active": "…" },
  "status": { "success": "…", "warning": "…", "error": "…" },
  "syntax": { "keyword": "…", "…": "…" },
  "effect": { "shadow": "…", "scrim": "…" }
}
```

Siapa pun yang bisa menghasilkan file ini boleh menjadi engine warna. Konsumen
tidak pernah tahu engine-nya apa.

### 2.2 `feel.json` — kontrak rasa

Seperti di [`FEEL.md`](FEEL.md) §5: token semantik (`font`, `geometry`,
`elevation`, `surface`, `material`, `motion`, `chrome`). **Tidak berisi warna**,
dan tidak berisi knob WM.

`font` sudah berjalan (§2.4 FEEL.md): satu profil JSON → `templates/feel.toml` →
`~/.myenv/feel/current/{scss/_feel.scss, kitty/font.conf, foot/font.ini}`.
Sisanya (`geometry` dan seterusnya) masih menjadi payload `feel` di blueprint
Flow B sampai Fase 0 selesai.

### 2.3 `manifest.toml` — kontrak konsumen

Daftar konsumen, siapa pemiliknya, dan cara reload-nya per sesi. Dispatcher
tidak boleh punya `if tool == "hypr"` yang tersebar; semua di sini.

```toml
# matugen/manifest.toml (rancangan)
[session]
detect = { hypr = "HYPRLAND_INSTANCE_SIGNATURE", niri = "NIRI_SOCKET" }
fallback = "XDG_CURRENT_DESKTOP"   # "Hyprland" | "niri"

[[consumer]]
name = "hypr-colors"
wm = "hypr"
scope = "color"
path = "theme/current/hypr/theme.lua"
reload = { hypr = "hyprctl reload" }
validate = "luac -p {path}"

[[consumer]]
name = "hypr-feel"
wm = "hypr"
scope = "feel"
path = "feel/current/hypr.lua"
reload = { hypr = "hyprctl reload" }
validate = "luac -p {path}"

[[consumer]]
name = "niri-colors"
wm = "niri"
scope = "color"
path = "theme/current/niri/colors.kdl"
validate = "niri validate -c ~/.dotfile/niri/config.kdl"

[[consumer]]
name = "niri-feel"
wm = "niri"
scope = "feel"
path = "feel/current/niri.kdl"
validate = "niri validate -c ~/.dotfile/niri/config.kdl"

[[consumer]]
name = "swaync"
wm = "any"
scope = "any"
path = "theme/current/css/theme.css"
reload = { hypr = "swaync-client -rs", niri = "swaync-client -rs" }

[[consumer]]
name = "waybar"
wm = "any"
scope = "any"
path = "theme/current/css/theme.css"
reload = { hypr = "pkill -SIGUSR2 waybar || true", niri = "pkill -SIGUSR2 waybar || true" }

[[consumer]]
name = "rofi"
wm = "any"
scope = "any"
path = "theme/current/rasi/theme.rasi"
# rofi membaca saat dibuka: tidak ada reload

[[consumer]]
name = "kitty"
wm = "any"
scope = "any"
path = "theme/current/kitty/theme.conf"
reload = { hypr = "pkill -SIGUSR1 kitty || true", niri = "pkill -SIGUSR1 kitty || true" }

[[consumer]]
name = "foot"
wm = "any"
scope = "any"
path = "theme/current/foot/theme.ini"
# foot tidak punya sinyal reload: jendela baru saja

[[consumer]]
name = "eww"
wm = "any"
scope = "any"
path = "theme/current/scss/_theme.scss"
reload = { hypr = "eww reload || true", niri = "eww reload || true" }

[[consumer]]
name = "nvim"
wm = "any"
scope = "any"
path = "theme/current/nvim/theme.lua"
# watcher nvim yang menangani (nvim/lua/core/theme_watch.lua)

[[consumer]]
name = "noctalia-feel"
wm = "any"
scope = "feel"
path = "feel/current/noctalia.toml"
reload = { hypr = "true", niri = "true" }  # Noctalia hot-reload ~150 ms
```

Catatan: `waybar` SIGUSR2 perlu diverifikasi saat implementasi; fallback-nya
restart. Jangan panggil `waybar` telanjang: pakai `~/.config/waybar/launch.sh`,
karena modul workspace yang salah compositor membuat waybar segfault
(lihat `waybar/launch.sh`).

---

## 3. Reload per sesi

Prinsip: **render boleh lengkap, reload harus sesi-spesifik.** Render satu WM
yang tidak aktif hanya membuang waktu dan menyentuh file yang tidak dibaca.

| Konsumen | Hyprland | niri | Catatan |
|---|---|---|---|
| `hypr/theme.lua`, `feel/hypr.lua` | `hyprctl reload` | **tidak disentuh** | Lua dibaca saat config reload |
| `niri/colors.kdl`, `feel/niri.kdl` | **tidak disentuh** | tulis ulang `niri/config.kdl` (touch) | niri live-reload; include di-watch |
| `swaync` | `swaync-client -rs` | idem (kalau swaync jalan) | `-R` hanya config.json |
| `waybar` | SIGUSR2 / restart | idem | bar milik mode `rice` |
| `eww` | `eww reload` | idem | — |
| `rofi` | — | — | dibaca saat dibuka |
| `kitty` | SIGUSR1 | SIGUSR1 | — |
| `foot` | — | — | tanpa reload |
| `nvim` | watcher | watcher | `M.reload()` sudah tervalidasi |
| GTK apps | `swaync-client -rs` + trik dconf yang ada | idem | — |
| Noctalia | hot-reload config | hot-reload | `noctalia config validate` |

Kenapa niri perlu “touch config” dan bukan perintah reload: `niri msg action`
**tidak punya** aksi reload (daftar aksi diverifikasi: `quit`,
`power-off-monitors`, `spawn`, `screenshot`, `close-window`, `fullscreen-window`,
…). Reload niri terjadi karena file berubah. Saat `current` di-flip ke folder
lain, watch inotify masih menunjuk inode lama, jadi tulis ulang
`niri/config.kdl` (atau file include-nya) untuk memaksa parse ulang.

---

## 4. Alur `theme apply`

```text
plan → render (filtered) → validate → activate (atomic) → reload (dispatcher) → verify
```

1. **Plan**: baca `manifest.toml`, deteksi sesi (`HYPRLAND_INSTANCE_SIGNATURE`,
   `NIRI_SOCKET`, fallback `XDG_CURRENT_DESKTOP`). Tentukan konsumen yang
   `wm = any` atau `wm = sesi`. Konsumen WM lain masuk daftar “skip”.
2. **Render**: hanya konsumen terpilih. Tulis ke `generated/<theme>.tmp/…`,
   bukan langsung ke folder aktif.
3. **Validate**: jalankan `validate` per konsumen (`luac -p`, `niri validate`,
   `foot --check-config`, `python3 -m json.tool` untuk manifest/palet). Gagal →
   berhenti, folder lama tetap utuh.
4. **Activate**: `ln -sfn generated/<theme>.tmp current.tmp && mv -T` (atomik,
   pola yang sudah dipakai untuk `current`).
5. **Reload**: hanya perintah yang sesinya cocok. Kalau sesi tidak terdeteksi →
   lewati reload, cetak peringatan (jangan menebak).
6. **Verify**: `hyprctl getoption` untuk beberapa nilai kunci, atau
   `niri validate` + cek proses hidup (`pgrep waybar`). Gagal verify = laporan,
   bukan rollback otomatis (rollback butuh keputusan manusia).

Tambahan yang membuat mulus:

- **Hash gate.** Simpan hash `(palette.json, feel.json, manifest)` di
  `~/.myenv/state.json`. Kalau tidak berubah → tidak render, tidak reload.
  Ini mencegah reload berantai saat script dipanggil dua kali.
- **Debounce.** `feh`/wallpaper picker bisa memicu beberapa kali; tunggu
  ~300 ms setelah perubahan terakhir.
- **Idempoten.** Render ulang dengan input sama harus menghasilkan byte sama
  (matugen deterministik untuk context yang sama).
- **Tidak ada reload lintas sesi.** Guard ganda: manifest + deteksi env +
  flag `--session`. Kalau `--session=hypr` tapi env menunjukkan niri → tolak.
- **Reload tidak lagi hidup di post_hook matugen.** Kedua config tidak punya
  `post_hook`; sementara ini `matugen/reload.sh` yang menjadi dispatcher
  (sadar pemilik proses, sadar sesi, tervalidasi, ber-`timeout`). Saat switcher
  memegang aktivasi, script itu pindah ke sana dan matugen berhenti tahu soal
  reload sama sekali.

---

## 5. Deteksi sesi dan guard

```bash
session() {
  [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && { echo hypr; return; }
  [[ -n ${NIRI_SOCKET:-} ]] && { echo niri; return; }
  case ${XDG_CURRENT_DESKTOP:-} in
    Hyprland|*Hyprland*) echo hypr ;;
    niri|*niri*)         echo niri ;;
    *)                   echo unknown ;;
  esac
}
```

Aturan:

- `unknown` → render tetap boleh (konsumen `any`), reload **tidak**.
- `--session` eksplisit hanya untuk debugging; kalau bertentangan dengan env,
  tolak dengan exit 2.
- Tidak ada `pkill` berdasarkan nama proses lintas WM (mis. jangan
  `pkill -f niri`).

---

## 6. Abstraksi engine warna

Dua sumber, satu kontrak (`palette.json`), lalu renderer yang sama.

| Kapabilitas | matugen 4.x | Noctalia v5 |
|---|---|---|
| Sumber warna | gambar (Flow A), JSON (Flow B) | wallpaper / palet / color scheme |
| Template | Tera (`{{ }}`, `{% %}`), filter warna + string | `<* *>` block, filter warna + string (subset) |
| Nilai kustom angka/string | **ya**: context JSON (`matugen json`) + `[config.custom_keywords]` | **tidak terdokumentasi**: context = token warna + `mode`/`image`/`closest_color` |
| Aritmetika/derivasi angka | terbatas (filter warna; aritmetika angka bukan fitur utama) | tidak ada |
| Custom color | via config/palet | `[config.custom_colors]` → **role warna** saja |
| Output | file per template | file per template, `output_path_dynamic`, hook |
| Skip file tak berubah | tidak dijamin | ya (docs: skips rewriting unchanged files) |
| Hot reload | lewat `matugen/reload.sh` (sementara) | ya (~150 ms), state GUI menang |
| Integrasi WM otomatis | tidak (kita tulis template) | ya: `niri/noctalia.kdl`, `hypr/noctalia.lua` |

### 6.1 Tiga skenario

**Skenario A — matugen pemilik warna (status quo yang dirapikan).**
`palette.json` dihasilkan template matugen (Flow A/B), konsumen dirender dari
palet itu. Noctalia hanya shell, tidak memiliki warna. Paling sedikit
perubahan; Noctalia tidak bisa mengganti warna wallpaper sendiri.

**Skenario B — Noctalia sumber warna, adapter kita tetap dipakai.**
Noctalia merender `palette.json` (satu template user, mapping statis dari
token warna → key kita). Setelah itu renderer kita menghasilkan file konsumen
seperti biasa. Keuntungan: warna Noctalia dan app lain identik. Risiko:
Noctalia harus dipicu saat wallpaper berubah; template Noctalia tidak bisa
menghitung turunan (mis. `status.critical`)—harus dipetakan statis.

**Skenario C — Noctalia shell penuh, template bawaan Noctalia aktif.**
Noctalia menulis warna langsung ke app dan WM (`niri/noctalia.kdl`,
`hypr/noctalia.lua`), dan menambahkan include ke config WM. Kita hanya
mengurus rasa. Ini paling dekat dengan cita-cita “toggle shell”, tetapi:
- harus **mematikan** include warna kita di WM itu (kalau tidak, dua pemilik);
- template bawaan Noctalia untuk kitty/foot/alacritty menulis ke config app
  (`~/.config/...`), sementara repo ini memakai `include` ke `current/…` —
  bisa dobel;
- state GUI (`~/.local/state/noctalia/settings.toml`) menang atas config
  tertulis, jadi nilai yang kita generate bisa kalah.

**Rekomendasi:** mulai dari **A**, siapkan **B** (karena itu inti abstraksi),
dan perlakukan **C** sebagai mode eksplisit yang dinyatakan di manifest
(`color_owner = "noctalia"`) — bukan hasil deteksi.

---

## 7. Fakta Noctalia yang relevan (terverifikasi dari docs v5)

- Config: semua `*.toml` di `~/.config/noctalia/` dibaca urut alfabet lalu
  digabung. `[include] files = [...]` bisa file atau direktori, `autoload =
  false` untuk memilih profil. File yang meng-include menang atas isi include.
- **State menang**: `~/.local/state/noctalia/settings.toml` (tulisan GUI)
  di-load terakhir dan menimpa config tangan.
- Hot reload: kedua layer di-watch, perubahan berlaku ~150 ms setelah disimpan.
- Validasi: `noctalia config validate` (exit 1 hanya untuk error; warning
  seperti key usang tidak menggagalkan).
- Export: `noctalia config export` / `export full` (aman untuk inspeksi).
- Template: context = token warna (48 role Material + `hover`/`on_hover` +
  token terminal + `palettes.*`), plus `mode`, `image`, `closest_color`.
  Blok `<* *>`, filter warna/string, loop/conditional, `[config.custom_colors]`
  (menambah **role warna**), hook, `output_path_dynamic`.
- Template compositor bawaan: Niri → `niri/noctalia.kdl` (menambah include ke
  `niri/config.kdl`); Hyprland Lua → `hypr/noctalia.lua` + `dofile(...).apply_theme()`.
- Template Noctalia **tidak** menghasilkan file yang tidak berubah (hemat
  timestamp).

Catatan repo: `noctalia/` saat ini berisi `settings.json`, `plugins.json`, dan
`palettes/*.json`. Docs v5 memakai TOML. Format JSON itu **belum diverifikasi**
apakah masih dibaca v5; jangan dijadikan sumber kebenaran sampai dicek.

---

## 8. Batas Noctalia: warna vs angka (jawaban pertanyaan)

Ya, intuisinya benar, dengan satu nuansa:

- **Matugen** bisa membawa nilai bebas karena `matugen json` memakai JSON
  sebagai context: angka, string, boolean, tabel bersarang. Repo ini sudah
  membuktikannya — `template/hypr.lua` membaca `{{ feel.shape.radius }}`,
  `{{ feel.motion.style_in }}`. Matugen juga punya `[config.custom_keywords]`
  untuk nilai reusable.
- **Noctalia** mendokumentasikan context template sebagai *theme token map*:
  warna, `mode`, `image`, `closest_color`, `palettes.*`. Array/map dari TOML
  `[config]` bisa di-*loop*, tetapi **tidak ada jalur terdokumentasi** untuk
  skalar bebas (`{{ radius }}`) atau aritmetika angka. `custom_colors` hanya
  menambah role warna, bukan variabel.
- Konsekuensi desain: **rasa tidak boleh dirender lewat template Noctalia.**
  Kalau dipaksa, hasilnya hanya bisa berupa warna — dan rasa butuh angka,
  string, dan boolean.

Karena itu pembagiannya:

```text
warna  : matugen ATAU Noctalia  → palette.json / file warna per konsumen
rasa   : selalu flow feel kita  → feel/current/{hypr.lua,niri.kdl,*.css,*.scss,*.rasi}
```

Noctalia tetap bisa “mengatur rasa” untuk **dirinya sendiri**, tetapi lewat
config TOML-nya, bukan lewat template:

```toml
# feel/current/noctalia.toml — dihasilkan flow feel kita
[general]
radiusRatio = 0.8
panelBackgroundOpacity = 0.93
enableBlurBehind = true
enableShadows = true
animationSpeed = 1.0

[bar]
frameRadius = 12
backgroundOpacity = 0.93
```

Noctalia menggabungkan file ini (hot reload), jadi rasa shell ikut profil yang
sama. Kalau GUI menimpanya, `settings.toml` menang — itu harus diterima sebagai
batas, atau nilai GUI dihapus saat apply (keputusan terpisah, jangan otomatis).

---

## 9. Abstraksi rasa yang menguntungkan

Profil rasa tetap kecil dan semantik, tetapi renderer-nya boleh kaya:

```text
matugen/feel/<profil>.json                 (satu berkas per profil)
   ├── matugen (Tera) ──► scss/_feel.scss (variabel font, sudah jalan)
   │                   ├── kitty/font.conf (sudah jalan)
   │                   ├── foot/font.ini   (sudah jalan)
   │                   ├── hypr.lua        (angka + string + boolean)
   │                   ├─► niri.kdl       (angka + flag KDL)
   │                   ├── waybar.css     (angka px)
   │                   ├── swaync.css     (:root var)
   │                   ├── eww.scss       ($var)
   │                   └── rasi.rasi      (variabel)
   └── derive.lua ──────► per-WM numbers  (opsional)
```

- **Derivasi** yang tidak bisa dilakukan Tera (mis. `passes = clamp(ceil(
  blur_strength * 6), 1, 6)`, `stiffness = f(character)`) dilakukan di
  `derive.lua` — bahasa yang sudah dipakai repo (`luac` tersedia), bukan
  assembler template baru. Keluarannya JSON per WM yang tetap dirender matugen.
- **Override per WM** boleh ada di profil, tetapi hanya untuk kasus di mana
  pemetaan semantik tidak cukup:

```jsonc
"overrides": {
  "hypr": { "material.blur.passes": 5 },
  "niri": { "geometry.gaps": 6 }
}
```

  Override tidak boleh menjadi jalan utama; kalau sebuah token butuh override
  di dua profil berturut-turut, artinya token itu salah abstraksi.

---

## 10. Gotcha

1. **Dua pemilik warna** (include kita + `noctalia.kdl`) = warna tak terduga,
   tergantung urutan include.
2. **State Noctalia menang** atas config yang kita tulis; selalu cek
   `noctalia config export full` saat nilai tidak terpakai.
3. **niri tidak punya aksi reload**; flip symlink saja tidak memicu reload.
4. **Post-hook matugen bukan dispatcher**; jangan biarkan ia memanggil
   `hyprctl reload` saat sesi niri.
5. **Reload yang tidak perlu** memicu kedip/kehilangan state (waybar restart,
   eww reload). Hash gate + debounce.
6. **Gagal validasi** harus berarti “jangan aktifkan”, bukan “aktifkan lalu
   perbaiki”. Simpan folder lama.
7. **Noctalia template skip file tak berubah**: bagus untuk warna, tetapi
   jangan mengandalkannya untuk memicu hook rasa.

---

## 11. Fase

| Fase | Isi | Selesai bila |
|---|---|---|
| 0 | `manifest.toml` + `theme apply` minimal (deteksi sesi, hash gate, atomic flip, reload per sesi) | Ganti tema di Hyprland tidak menyentuh file niri; sebaliknya |
| 1 | `palette.json` sebagai kontrak; template warna membaca kontrak itu | Flow A & B menghasilkan `palette.json` yang sama bentuknya |
| 2 | Flow feel memakai `derive.lua` untuk nilai per-WM | Tidak ada knob WM di profil rasa |
| 3 | Adapter Noctalia: `feel/current/noctalia.toml` + (opsional) `palette.json` dari Noctalia | Noctalia dan tools lain memakai warna+rasa yang sama |
| 4 | Mode `color_owner = noctalia` di manifest (include warna kita dimatikan untuk WM itu) | Tidak ada dua include warna aktif bersamaan |
