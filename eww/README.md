# Eww

Satu daemon memuat satu config root (`eww.yuck`, `eww.scss`): jendela utama
(profil, distro, depth clock) dan modul island di `bar/island/` yang di-`include`
dari root. Semua start/stop lewat `eww-ctl`; halaman ini hanya peta cepat.

Semua dokumen ditulis agar bisa dibaca tanpa memahami pipeline tema: warna dan
font datang dari tema aktif, dan cara tema dibuat berada di luar cakupan
dokumentasi Eww.

## Dokumen

| Dokumen | Untuk |
|---|---|
| [`docs/depth-clock/README.md`](docs/depth-clock/README.md) | referensi jam wallpaper berlapis: cara kerja, setelan, pemakaian `depth-ctl`, catatan Niri |
| [`docs/depth-clock/GUIDE.md`](docs/depth-clock/GUIDE.md) | resep langkah demi langkah membuat depth clock untuk wallpaper baru |
| [`docs/depth-clock/VERIFICATION.md`](docs/depth-clock/VERIFICATION.md) | rekaman pengujian depth clock (historis) |
| [`docs/bar/README.md`](docs/bar/README.md) | manual modul island: `eww-ctl bar island`, setelan, adapter, troubleshooting |
| [`docs/bar/VERIFICATION.md`](docs/bar/VERIFICATION.md) | rekaman pengujian island (historis) |

## Peta konfigurasi

| Path | Isi |
|---|---|
| `eww-ctl` | satu-satunya entry point: `daemon`, `island`, `open`/`close`/`toggle`, `reload`, `status`, `validate` |
| `eww.yuck` | config root: listener musik, include window root dan modul island |
| `eww.scss` | orkestrator: impor tema, satu reset global, lalu satu partial per window/modul |
| `window/` | `defwindow` root — `profile`, `distro`, `depth-clock` |
| `widget/` | widget root (`profile`, `power-buttons`, `music`) |
| `style/` | partial SCSS per window/widget root |
| `script/` | perintah pendukung: `music-ctl`, `power-ctl`, `depth-ctl` |
| `config/` | setelan runtime, mis. `depth-clock.conf` untuk `depth-ctl` |
| `bar/island/` | modul island: `island.yuck`, `window.yuck`, `widgets/`, `styles/`, `scripts/`, `tests/`, `settings.json` |
| `docs/` | dokumentasi (halaman ini indeksnya) |

Daemon hanya dimulai `eww-ctl daemon start` (atau `island start`), dan hanya
dihentikan `eww-ctl daemon stop`. `eww-ctl bar island stop` menutup jendela island
saja; jendela root tetap hidup.

## Pasang

```sh
~/.dotfile/eww/install.sh --dry-run   # lihat rencana, tidak mengubah apa pun
~/.dotfile/eww/install.sh             # pasang symlink, aman diulang
~/.dotfile/eww/install.sh --remove    # cabut, hanya symlink milik checkout ini
```

Installer hanya membuat dua symlink: `~/.local/bin/eww-ctl` dan
`~/.config/fish/completions/eww-ctl.fish`. `eww-ctl` membaca lokasi aslinya,
jadi config tetap berada di checkout ini dan tidak ada berkas yang disalin.
`BIN_DIR` dan `FISH_COMPLETION_DIR` bisa menimpa dua tujuan itu.
