# Eww

Eww dipakai untuk dua hal yang terpisah: jendela utama (profil, distro, depth
clock) di root folder ini, dan bar mandiri di `bar/`. Dokumen rinci keduanya ada
di `docs/`; halaman ini hanya peta cepat.

Semua dokumen ditulis agar bisa dibaca tanpa memahami pipeline tema: warna dan
font datang dari tema aktif, dan cara tema dibuat berada di luar cakupan
dokumentasi Eww.

## Dokumen

| Dokumen | Untuk |
|---|---|
| [`docs/depth-clock/README.md`](docs/depth-clock/README.md) | referensi jam wallpaper berlapis: cara kerja, setelan, pemakaian `depth-ctl`, catatan Niri |
| [`docs/depth-clock/GUIDE.md`](docs/depth-clock/GUIDE.md) | resep langkah demi langkah membuat depth clock untuk wallpaper baru |
| [`docs/depth-clock/VERIFICATION.md`](docs/depth-clock/VERIFICATION.md) | rekaman pengujian depth clock (historis) |
| [`docs/bar/README.md`](docs/bar/README.md) | manual bar Eww: `barctl`, setelan, adapter, troubleshooting |
| [`docs/bar/VERIFICATION.md`](docs/bar/VERIFICATION.md) | rekaman pengujian bar (historis) |
| [`docs/bar/TODO.md`](docs/bar/TODO.md) | backlog bar |

## Peta konfigurasi

| Path | Isi |
|---|---|
| `eww.yuck` | include seluruh window |
| `eww.scss` | orkestrator: impor tema, reset global, lalu satu partial per window/widget |
| `window/` | `defwindow` — `profile`, `distro`, `depth-clock` |
| `widget/` | widget yang dipakai window (`profile`, `power-buttons`, `music`) |
| `style/` | partial SCSS per window/widget |
| `script/` | perintah pendukung: `music-ctl`, `power-ctl`, `depth-ctl` |
| `config/` | setelan runtime, mis. `depth-clock.conf` untuk `depth-ctl` |
| `docs/` | dokumentasi (halaman ini indeksnya) |

`bar/` adalah konfigurasi Eww terpisah (bar) dengan daemon dan asetnya sendiri;
manualnya ada di [`docs/bar/README.md`](docs/bar/README.md).
