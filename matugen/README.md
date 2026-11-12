# Matugen

`matugen-ctl` adalah pintu masuk untuk warna dan rasa. Pemanggil cukup menyebut
sumber palet atau profil rasa; path config, folder store, validasi, dan reload
konsumen diurus di folder ini.

## Pemanggilan

```bash
~/.config/matugen/matugen-ctl palette ~/Pictures/Wallpaper/nyx.png
~/.config/matugen/matugen-ctl palette ~/.dotfile/matugen/core/palette/kanagawa-dragon-lotus/blueprint/dark.json
~/.config/matugen/matugen-ctl feel default
~/.config/matugen/matugen-ctl reload css
~/.config/matugen/matugen-ctl list
~/.config/matugen/matugen-ctl status
```

| Perintah | Hasil |
|---|---|
| `palette <gambar>` | Palet turunan wallpaper (alur A), lalu aktifkan dan reload |
| `palette <blueprint.json>` | Palet tetap dari `core/palette/<tema>/blueprint/<varian>.json` (alur B) |
| `feel <profil>` | Rasa dari `core/feel/profiles/<profil>/`, dirender hanya untuk WM aktif, lalu aktifkan dan reload |
| `reload [konsumen ...]` | Reload tanpa render; tanpa argumen = semua konsumen |
| `list` | Palet + varian, profil rasa, daftar konsumen |
| `status` | Palet dan rasa yang sedang aktif; exit `1` bila salah satunya kosong |

`palette` meneruskan opsi ke `script/palette.sh`, jadi `--dry-run` dan `--list`
tetap sah. `THEME_ROOT` dan `FEEL_ROOT` mengarahkan kedua store ke tempat lain.

Exit: `0` berhasil, `1` render/reload gagal, `2` salah pakai, `127` matugen tidak
ada di `PATH`.

## Registrasi ke PATH

```bash
~/.dotfile/matugen/install.sh --dry-run   # lihat rencana, tidak mengubah apa pun
~/.dotfile/matugen/install.sh             # pasang symlink, aman diulang
~/.dotfile/matugen/install.sh --remove    # cabut, hanya symlink milik checkout ini
```

Installer hanya mengurus Matugen dan membuat dua symlink:
`~/.local/bin/matugen-ctl` dan `~/.config/fish/completions/matugen-ctl.fish`.
Tidak ada render, store, atau config yang disentuh. Ia idempoten, menolak menimpa
berkas biasa atau symlink milik pihak lain (exit `1`), dan menerima `BIN_DIR` /
`FISH_COMPLETION_DIR` untuk mengarahkan tujuan saat menguji.

## Warna dan rasa

Dua sumbu terpisah; jangan mencampurnya dalam satu config matugen.

| | A — wallpaper | B — palet tetap | C — rasa |
|---|---|---|---|
| Config | `core/palette/wallpaper-based/config.toml` | `core/palette/<tema>/config.toml` | `core/feel/config.apps.toml` + `config.hypr.toml` |
| Sumber | gambar | `blueprint/<varian>.json` tulis tangan | `profiles/<profil>/{apps,hypr,niri}.json` |
| Kosakata template | `{{ colors.<role>.<scheme>.<format> }}` | `{{ accent.primary }}`, `{{ syntax.keyword }}`, … | `{{ font.* }}`, `{{ chrome.* }}`, … |
| Output | `~/.myenv/theme/palette/generated/wallpaper-based/` | `~/.myenv/theme/palette/generated/<tema>/` | `~/.myenv/theme/feel/generated/<profil>/` |

Template alur B gagal di `matugen image` (tidak ada `accent.*`), dan `colors.*`
tidak ada di `matugen json`. Karena itu config dan templatenya dipisah per alur.

Aturan profil rasa: semua key yang dipakai template wajib ada — matugen 4.2
tidak punya filter `default` maupun `{% if %}` (key hilang = `ResolveError`),
`null` tercetak `Null`, dan `feel.sh` menolak hasil yang masih menyisakan
placeholder. Nama key mengikuti peran (`font.ui.text`), bukan nama alat.

Satu profil adalah **direktori** dengan tiga pemilik yang terpisah:

| Berkas | Pemilik | Dirender saat |
|---|---|---|
| `apps.json` | kitty, foot, alacritty, rofi, waybar/swaync (font) | WM apa pun |
| `hypr.json` | Hyprland: shape, surface, material, motion, chrome | hanya sesi Hyprland |
| `niri.json` | niri (placeholder; template belum ada) | belum dirender |

`matugen-ctl feel` mendeteksi WM dari sesi (`HYPRLAND_INSTANCE_SIGNATURE`,
`NIRI_SOCKET`, lalu `XDG_CURRENT_DESKTOP`) dan hanya merender bagian WM itu
plus `apps.json`; WM lain tidak pernah ikut dirender. Di sesi niri saat ini
hanya `apps.json` yang dirender karena template niri belum dibuat. Menambah
rasa = satu direktori di `core/feel/profiles/`; `template/` dan `config.*.toml`
tidak disentuh. `--wm auto|hypr|niri` menimpa deteksi (untuk uji/cron).

## Struktur

```text
matugen/
├── matugen-ctl                 # palette | feel | reload | list | status
├── install.sh                  # symlink matugen-ctl + completion ke PATH dan fish
├── completions/matugen-ctl.fish # completion fish (profil & konsumen dinamis)
├── script/
│   ├── palette.sh              # render palet, validasi, flip palette/current, reload
│   └── feel.sh                 # render profil rasa, flip feel/current, reload CSS
├── core/
│   ├── palette/
│   │   ├── wallpaper-based/    # alur A: config.toml + template/
│   │   └── kanagawa-dragon-lotus/
│   │       ├── blueprint/      # dark.json, light.json (+ README key)
│   │       └── template/
│   └── feel/                   # profiles/<profil>/{apps,hypr,niri}.json
│                               # template/apps + template/hypr
│                               # config.apps.toml + config.hypr.toml
├── docs/                       # dokumen rinci (lihat daftar di bawah)
└── tests/test_matugen_ctl.py   # kontrak perintah, status, dan passthrough
```

Completion fish ada di `completions/matugen-ctl.fish`; fish memuatnya hanya bila
berkasnya terbaca sebagai `~/.config/fish/completions/matugen-ctl.fish`. Daftar
profil rasa dan konsumen dibaca dari checkout tempat symlink `matugen-ctl`
menunjuk, jadi tidak ikut basi saat blueprint atau konsumen ditambah.

## Cara satu render menjadi aktif

Config palet dan rasa menulis `output_path` **relatif** (`/kitty/theme.conf`).
`palette.sh`/`feel.sh` yang menyuplai `-p` ke folder store, merender ke
`generated/.<nama>.tmp`, menolak hasil kosong atau placeholder tersisa, baru
memindahkannya ke `generated/<nama>` dan membalik `current`. Render gagal tidak
pernah mengganti tema yang sedang dipakai.

Reload berjalan sesudah aktivasi: hanya proses yang benar-benar hidup yang
disentuh, setiap panggilan dibungkus `timeout`, dan `hyprctl reload` hanya
dijalankan di sesi Hyprland. `~/.myenv/theme/current-status.json` bukan milik
folder ini: itu state untuk switcher (belum ada yang menulisnya), sementara yang
benar-benar aktif adalah tujuan symlink `theme/palette/current` dan
`theme/feel/current`.

## Konsumen

| Konsumen | Membaca |
|---|---|
| `kitty/kitty.conf` | `theme/palette/current/kitty/theme.conf` + `theme/feel/current/kitty/feel.conf` |
| `alacritty/alacritty.toml` | `theme/palette/current/alacritty/theme.toml` + `theme/feel/current/alacritty/feel.toml` |
| `foot/foot.ini` | `theme/palette/current/foot/theme.ini` + `theme/feel/current/foot/feel.ini` |
| `rofi/themes/shared/theme.rasi` | `theme/palette/current/rasi/theme.rasi` + `theme/feel/current/rasi/feel.rasi` |
| `waybar/style.css`, `wlogout/style.css`, `swaync/style.css` | `theme/palette/current/css/theme.css` |
| `eww/eww.scss` | `theme/palette/current/scss/theme` |
| `nvim/lua/core/theme.lua` | `theme/palette/current/nvim/theme.lua` |
| `yazi/flavors/matugen.yazi/*` | `theme/palette/current/yazi/` |
| `hypr/config/core/theme/palette.lua` | `theme/palette/current/hypr/theme.lua` (warna) + `theme/feel/current/hypr/feel.lua` (rasa) |
| `lazygit`, `herdr` | `theme/palette/current/lazygit/config.yml`, `theme/palette/current/herdr/config.toml` |

## Pemeriksaan

```bash
bash -n ~/.config/matugen/matugen-ctl
bash -n ~/.config/matugen/install.sh
bash -n ~/.config/matugen/script/palette.sh
bash -n ~/.config/matugen/script/feel.sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s ~/.config/matugen/tests -v
```

Tes memakai perintah `--dry-run`; tidak merender, tidak membalik symlink, tidak
me-reload aplikasi. Untuk uji nyata, arahkan store ke folder sementara:

```bash
THEME_ROOT=/tmp/theme-test matugen-ctl palette --dry-run /tmp/wall.png
```

Menulis template baru: baca `docs/MATUGEN_SKILLS.md` lebih dulu, lalu uji ke
`/tmp` sebelum menyentuh `core/`.

## Dokumentasi

Semua dokumen **diverifikasi terhadap repo**; baris yang tidak cocok lagi dengan
kode adalah bug dokumentasi.

| Dokumen | Bahasa | Isi |
|---|---|---|
| [`docs/MATUGEN_SKILLS.md`](docs/MATUGEN_SKILLS.md) | EN | Menulis, mendaftarkan, menguji, dan me-reload template; fakta engine + resep per aplikasi |
| [`docs/CHEATSHEETS.md`](docs/CHEATSHEETS.md) | ID | Kosakata *role* Material You → pekerjaan UI |
| [`docs/VOCABULARY.md`](docs/VOCABULARY.md) | ID | Contoh `matugen --show-colors` dan cara membacanya |
| [`docs/WM_FEEL_MATRIX.md`](docs/WM_FEEL_MATRIX.md) | ID | Fitur rasa Hyprland 0.57 vs niri 26.04, jebakan include |
| [`docs/NOCTALIA.md`](docs/NOCTALIA.md) | ID | Fakta Noctalia v5 vs matugen: config, batas template, pemilik warna, checklist integrasi |
| [`docs/NVIM_MAPPING.md`](docs/NVIM_MAPPING.md) | ID | Key palet → highlight group Neovim |
| [`core/palette/kanagawa-dragon-lotus/blueprint/README.md`](core/palette/kanagawa-dragon-lotus/blueprint/README.md) | ID | Referensi setiap key JSON blueprint (alur B) |

Gambaran repo menyeluruh (sync config, daftar tool, setup mesin baru):
[`../README.md`](../README.md) dan [`../AGENTS.md`](../AGENTS.md).
