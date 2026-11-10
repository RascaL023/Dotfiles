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
| `feel <profil>` | Rasa dari `core/feel/blueprint/<profil>.json`, lalu aktifkan dan reload |
| `reload [konsumen ...]` | Reload tanpa render; tanpa argumen = semua konsumen |
| `list` | Palet + varian, profil rasa, daftar konsumen |
| `status` | Palet dan rasa yang sedang aktif; exit `1` bila salah satunya kosong |

`palette` meneruskan opsi ke `script/palette.sh`, jadi `--dry-run` dan `--list`
tetap sah. `THEME_ROOT` dan `FEEL_ROOT` mengarahkan kedua store ke tempat lain.

Exit: `0` berhasil, `1` render/reload gagal, `2` salah pakai, `127` matugen tidak
ada di `PATH`.

## Warna dan rasa

Dua sumbu terpisah; jangan mencampurnya dalam satu config matugen.

| | A — wallpaper | B — palet tetap | C — rasa |
|---|---|---|---|
| Config | `core/palette/wallpaper-based/config.toml` | `core/palette/<tema>/config.toml` | `core/feel/config.toml` |
| Sumber | gambar | `blueprint/<varian>.json` tulis tangan | `blueprint/<profil>.json` |
| Kosakata template | `{{ colors.<role>.<scheme>.<format> }}` | `{{ accent.primary }}`, `{{ syntax.keyword }}`, … | `{{ font.* }}`, `{{ chrome.* }}`, … |
| Output | `~/.myenv/theme/generated/wallpaper-based/` | `~/.myenv/theme/generated/<tema>/` | `~/.myenv/feel/generated/<profil>/` |

Template alur B gagal di `matugen image` (tidak ada `accent.*`), dan `colors.*`
tidak ada di `matugen json`. Karena itu config dan templatenya dipisah per alur.

## Struktur

```text
matugen/
├── matugen-ctl                 # palette | feel | reload | list | status
├── script/
│   ├── palette.sh              # render palet, validasi, flip theme/current, reload
│   └── feel.sh                 # render profil rasa, flip feel/current, reload CSS
├── core/
│   ├── palette/
│   │   ├── wallpaper-based/    # alur A: config.toml + template/
│   │   └── kanagawa-dragon-lotus/
│   │       ├── blueprint/      # dark.json, light.json (+ README key)
│   │       └── template/
│   └── feel/                   # blueprint/ + template/ + config.toml
├── docs/                       # dokumen rinci (lihat daftar di bawah)
└── tests/test_matugen_ctl.py   # kontrak perintah, status, dan passthrough
```

## Cara satu render menjadi aktif

Config palet dan rasa menulis `output_path` **relatif** (`/kitty/theme.conf`).
`palette.sh`/`feel.sh` yang menyuplai `-p` ke folder store, merender ke
`generated/.<nama>.tmp`, menolak hasil kosong atau placeholder tersisa, baru
memindahkannya ke `generated/<nama>` dan membalik `current`. Render gagal tidak
pernah mengganti tema yang sedang dipakai.

Reload berjalan sesudah aktivasi: hanya proses yang benar-benar hidup yang
disentuh, setiap panggilan dibungkus `timeout`, dan `hyprctl reload` hanya
dijalankan di sesi Hyprland. `~/.myenv/theme/current-status.json` bukan milik
folder ini; itu ditulis `theme-switcher.sh` di luar repo.

## Konsumen

| Konsumen | Membaca |
|---|---|
| `kitty/kitty.conf` | `theme/current/kitty/theme.conf` + `feel/current/kitty/feel.conf` |
| `alacritty/alacritty.toml` | `theme/current/alacritty/theme.toml` + `feel/current/alacritty/feel.toml` |
| `foot/foot.ini` | `theme/current/foot/theme.ini` + `feel/current/foot/feel.ini` |
| `rofi/themes/shared/palette.rasi` | `theme/current/rasi/theme.rasi` + `feel/current/rasi/feel.rasi` |
| `waybar/style.css`, `wlogout/style.css`, `swaync/style.css` | `theme/current/css/theme.css` |
| `eww/eww.scss` | `theme/current/scss/theme` |
| `nvim/lua/core/theme.lua` | `theme/current/nvim/theme.lua` |
| `yazi/flavors/matugen.yazi/*` | `theme/current/yazi/` |
| `hypr/config/core/theme/palette.lua` | `theme/current/hypr/theme.lua` |
| `lazygit`, `herdr` | `theme/current/lazygit/config.yml`, `theme/current/herdr/config.toml` |

## Pemeriksaan

```bash
bash -n ~/.config/matugen/matugen-ctl
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
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | EN | Cakupan template per tool, per alur |
| [`docs/CHEATSHEETS.md`](docs/CHEATSHEETS.md) | ID | Kosakata *role* Material You → pekerjaan UI |
| [`docs/VOCABULARY.md`](docs/VOCABULARY.md) | ID | Contoh `matugen --show-colors` dan cara membacanya |
| [`docs/FEEL.md`](docs/FEEL.md) | ID | Token rasa, pemetaan per WM, konsumen non-shell, rencana Noctalia |
| [`docs/WM_FEEL_MATRIX.md`](docs/WM_FEEL_MATRIX.md) | ID | Fitur rasa Hyprland 0.56 vs niri 26.04 |
| [`docs/THEME_ENGINE.md`](docs/THEME_ENGINE.md) | ID | Reload per sesi, kontrak engine, abstraksi matugen vs Noctalia |
| [`docs/NVIM_MAPPING.md`](docs/NVIM_MAPPING.md) | ID | Key palet → highlight group Neovim |
| [`core/palette/kanagawa-dragon-lotus/blueprint/README.md`](core/palette/kanagawa-dragon-lotus/blueprint/README.md) | ID | Referensi setiap key JSON blueprint (alur B) |

Gambaran repo menyeluruh (sync config, daftar tool, setup mesin baru):
[`../README.md`](../README.md) dan [`../AGENTS.md`](../AGENTS.md).
