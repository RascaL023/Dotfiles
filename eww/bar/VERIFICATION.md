# Hasil verifikasi — 27 Oktober 2026

Pengujian dilakukan pada Eww **0.6.0**, Python 3.12, output **LVDS-1
1366×768 @ scale 1**. Implementasi awal diuji pada Hyprland 0.56.2 dengan
konfigurasi Lua dan Niri 26.04; penyesuaian ukuran berikutnya diperiksa di
Hyprland. Konfigurasi lama, Waybar, autostart, dan Matugen
tidak diubah oleh implementasi bar ini.

## Penyesuaian ukuran dan ikon

- Pulau diperkecil dari 36 menjadi **30 px**, dengan padding atas/bawah tetap
  3/0 px. `hyprctl -j layers` mengonfirmasi layer `eww-islands` pada
  `x=0, y=0, w=1366, h=33`. Margin kiri/kanan menjadi **4 px**.
- Teks 11 px, ikon 14 px, radius 10 px, dan spacing lebih rapat. Pil workspace
  menjadi 6 px dan memanjang menjadi 22 px saat aktif; area klik 24 px tinggi.
- Screenshot langsung memverifikasi ikon NixOS, teks dan ikon yang tidak
  terpotong, serta jam tetap di tengah. Log Eww setelah reload tidak memuat
  kesalahan konfigurasi. Font lokal menyediakan seluruh glyph yang digunakan.
- **21 tes otomatis lolos**. Volume membedakan mute, 0%, 1–33%, 34–66%, dan
  ≥67%; baterai mengikuti tingkat kapasitas per 10% dan varian pengisian.
  Pengujian mencakup batas tingkat, pengisian, kapasitas penuh, dan multi-baterai.
- Ikon baru memakai snapshot yang sudah tersedia. Tidak ada listener, timer,
  scan Wi-Fi, atau dependensi tambahan. Wi-Fi tetap mengikuti status koneksi.
- Penyesuaian visual ini belum diperiksa ulang dalam sesi Niri. Data performa
  dan pengujian lifecycle di bawah berasal dari implementasi awal.

## Tampilan dan lifecycle implementasi awal

- Eww memuat Yuck, ekspresi, atribut widget, dan SCSS tanpa kesalahan konfigurasi.
- Pada Niri, iterasi awal memiliki pulau 36 px, padding atas 3 px dan bawah
  0 px, total 39 px. Layer `eww-islands` berada di `Top` dengan
  `keyboard_interactivity: None`. Aplikasi berada di bawah bar; gap tambahan
  tetap mengikuti konfigurasi compositor.
- Jam tetap berada di tengah layar (x = 683). Workspace memakai pil 8 px yang
  melebar menjadi 26 px saat aktif, tanpa angka; identitas tersedia di tooltip.
- Uji tampilan dengan 30 workspace, judul 24 karakter lebar, tray terbuka,
  volume/baterai 100% tidak menabrak pulau tengah. Workspace tambahan dapat
  digulir dan teks musik dipotong.
- Hyprland telah diuji langsung untuk layer, ruang eksklusif, fokus, workspace,
  dan kontrol pada iterasi awal. Perubahan margin 3/0 px dan pil terakhir
  diperiksa secara visual di Niri; belum diperiksa kembali dalam sesi Hyprland.
- **20 siklus start → reload → stop pada masing-masing compositor** lolos:
  satu daemon Eww, satu collector, dan seluruh listener lama berhenti setiap
  siklus. Bar ditinggalkan dalam keadaan berjalan.

Eww 0.6.0 kadang mencatat `sending response from main thread: channel closed`
ketika pembukaan jendela melewati timeout IPC klien 100 ms. Controller memakai
`--no-daemonize`, memeriksa jendela yang benar-benar terbuka, dan menyimpan
identitas proses. Ini mencegah daemon ganda yang ditemukan pada pengujian awal.
Pesan tersebut bukan kesalahan parser Yuck/SCSS.

## Data dan interaksi implementasi awal

**20 tes otomatis lolos**, termasuk metadata kutip/backslash/Unicode/newline,
layanan kosong, deduplikasi bridge MPD, pemutar aktif dan pilihan yang tetap,
kontrol ke pemutar yang ditampilkan, reconnect socket/stream, penggabungan
event, pembatalan proses, serta konfirmasi daya melalui pengganti perintah.

Uji desktop langsung pada Niri dan Hyprland mencakup:

- Klik workspace; Niri menggunakan ID stabil, Hyprland memakai dispatcher Lua.
- Perubahan volume dari luar bar, mute, dan pembatasan kenaikan pada 100%.
- DND SwayNC dan buka/tutup tray.
- MPD play/pause, lagu berikutnya/sebelumnya, serta kontrol melalui bridge MPRIS.
- Pemulihan workspace, volume/mute, DND, lagu dan posisi playback setelah tes.

MPD/bridge sempat tidak tersedia setelah pergantian sesi. Modul musik kemudian
pulih setelah layanan dinyalakan kembali, tanpa restart collector. Status
jaringan dan baterai asli terbaca. Pergantian koneksi jaringan dan status
pengisian diuji melalui data parser, bukan dengan memutus jaringan atau
mencabut pengisi daya. Menu daya diuji menggunakan perintah pengganti; sesi
tidak diakhiri. Launcher, nmtui, dan layar kunci belum diuji interaktif.

## Resource pada Niri

Semua modul aktif, tray terlipat, MPD dan mpd-mpris tersedia. Musik menggunakan
lagu pengguna dengan sink sementara di-mute; setelah pengukuran, playback
paused, lagu, posisi, dan mute dipulihkan.

| Kondisi | Durasi | CPU rata-rata, satu core | RSS rata-rata | RSS maksimum |
|---|---:|---:|---:|---:|
| Idle, MPD paused | 60,553 dtk | 0,446% | 110,83 MiB | 110,83 MiB |
| MPD Playing | 60,507 dtk | 0,694% | 113,67 MiB | 113,71 MiB |

Pengukuran `/proc` mencakup daemon Eww, collector Python, `pw-dump`, `nmcli
monitor`, `swaync-client -s`, `dbus-monitor`, dan `mpc idleloop`, termasuk CPU
child yang telah di-reap. MPD, bridge, dan compositor yang berjalan terpisah
tidak termasuk. RSS menjumlahkan tiap proses sehingga shared pages bisa
terhitung lebih dari sekali. Sampel RSS diambil setiap lima detik.
Sesi desktop tetap aktif; angka ini bukan batas maksimum atau benchmark
mesin yang sepenuhnya terisolasi.

Loop refresh audio yang ditemukan pada implementasi awal telah diperbaiki:
event klien `wpctl` tidak lagi memicu pembacaan `wpctl` berikutnya. Parser
PipeWire hanya meneruskan perubahan sink/default/volume yang relevan.
Probe 15 detik saat musik berjalan tidak menemukan refresh musik atau audio
berulang setelah snapshot awal. Tidak ada polling posisi lagu tiap detik.

## Mengulang pengujian

Dari direktori `eww/`:

```sh
python3 -m unittest discover -s bar/tests -v
./bar/barctl doctor
python3 bar/tests/live_checks.py cycles --count 20
python3 bar/tests/live_checks.py workspaces
python3 bar/tests/live_checks.py controls
python3 bar/tests/live_checks.py measure --seconds 60 --label idle
python3 bar/tests/live_checks.py music-measure --seconds 60
```

`controls` dan `music-measure` memerlukan MPD paused; `controls` juga memerlukan
minimal dua workspace, dua lagu dalam playlist, dan bridge MPRIS aktif.
Perintah ini mengubah keadaan desktop sementara dan memulihkannya. Jalankan
ketika tidak sedang mengubah playback/volume/workspace secara bersamaan.
