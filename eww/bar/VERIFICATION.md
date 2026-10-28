# Hasil verifikasi

## Pembaruan Right — 28 Oktober 2026

- Bagian kanan kini terdiri dari tiga widget dalam satu jendela: kontrol
  volume/brightness, status jaringan/baterai, serta aksi notifikasi/daya.
  Pulau berjarak 8 px; ikon berada di kotak 16×16 px dengan area 28×24 px.
  Tray dihapus, baterai hanya menampilkan ikon dan tooltip persentase/status.
- Font Monocraft 11 px, ikon 13 px, padding atas 4 px dan bawah 0 px mengikuti
  pengaturan pengguna. Layer Hyprland tetap 1366×34 px; pulau setinggi 30 px.
- Volume dan brightness memiliki `revealer` masing-masing, di kiri ikon
  terkait. Hover memakai `defvar` + `eww update`; animasi native Eww 200 ms,
  tanpa status hover atau timer tutup tambahan di Python.
- Uji pointer asli pada Hyprland memastikan ikon volume → slider volume
  tetap membuka volume, dan ikon brightness → slider brightness tetap
  membuka brightness. Meninggalkan kontrol menutup slider. Screenshot
  memastikan slider brightness berada di antara ikon volume dan brightness.
- Callback slider dari Yuck diuji sampai ke `wpctl` dan `brightnessctl`.
  Perubahan brightness dari luar bar diterima melalui udev, tanpa polling.
  Volume dan brightness dikembalikan ke nilai sebelum tes.
- **25 tes otomatis lolos**, termasuk deteksi backlight, validasi persentase,
  penggabungan drag, FIFO callback, serta cleanup. Tes status hover Python
  dihapus karena hover kini milik Eww; interaksi tersebut diperiksa langsung.
- Tiga siklus start → reload → stop setelah pembaruan lolos tanpa proses lama
  yang tertinggal, termasuk listener brightness. Bar ditinggalkan berjalan.
- Callback perangkat menggunakan builtin `printf` ke FIFO privat. Collector
  memakai nilai terakhir per kontrol dalam jendela 50 ms, tanpa interpreter
  baru pada setiap perubahan slider. Startup Python di callback hover pernah
  melampaui timeout Eww; pengelolaan hover tersebut telah dihapus.
- Pemeriksaan visual/interaksi pembaruan ini dilakukan pada Hyprland 0.56.2
  dan Eww 0.6.0. Sesi Niri belum diuji ulang untuk perubahan Right ini.

Pengukuran idle 60,511 detik pada Hyprland, semua modul diaktifkan dan musik
tidak tersedia saat sampel. Pengukuran mencakup pohon proses bar dari `/proc`:

| Komponen | CPU rata-rata, satu core | RSS rata-rata |
|---|---:|---:|
| Seluruh bar dan listener | 0,297% | 109,95 MiB |
| Collector Python, termasuk CPU child yang di-reap | 0,182% | 25,87 MiB |

Collector termasuk dalam total bar. Listener brightness `udevadm` memiliki
RSS 7,04 MiB pada akhir pengukuran. Tidak ada proses Python tambahan untuk
hover. RSS menjumlahkan memori proses sehingga shared pages dapat terhitung
lebih dari sekali. Ini pengukuran idle versi saat ini; belum merupakan
perbandingan A/B terhadap versi tanpa collector atau pengukuran peak saat drag.

## Lingkungan implementasi awal — 27 Oktober 2026

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

## Middle — kalender, 28 Oktober 2026

- **30 tes unit lulus**, termasuk lima tes kalender: grid Senin, Februari
  kabisat, bulan enam minggu, batas tahun, navigasi, pergantian tanggal/bulan,
  pemulihan pembukaan gagal, dan pembatalan penutupan saat toggle cepat.
  Tes socket dijalankan dengan izin socket Unix lokal.
- Desktop **Hyprland**, LVDS-1 **1366×768**: bar tetap 1366×34 px. Panel
  kalender 441×298 px, posisi **(463, 42)**, terpusat dengan jarak 8 px dari
  bawah bar. Screenshot diperiksa: jam saja di tengah, tanggal besar di kiri,
  kalender mulai Senin di kanan, penanda hari ini, dan panah navigasi.
- Navigasi sebelumnya/berikutnya, melintasi pergantian tahun, dan Today
  diperiksa melalui aksi collector. Tanggal kiri tetap menunjukkan hari ini
  ketika bulan kanan berubah. Membuka ulang kembali ke bulan saat ini.
- **10 siklus buka/tutup normal dan 10 siklus buka ulang cepat lulus**.
  Tidak ada popup tersisa setelah menutup; jendela terakhir hanya `islands`.
  PID daemon dan collector tetap sama sepanjang pengujian. Fokus serta posisi/
  ukuran aplikasi aktif tidak berubah ketika popup dibuka.
- Log setelah reload final dan pengujian tidak menunjukkan kesalahan Yuck,
  SCSS, atau ekspresi kalender. Popup menggunakan instance Eww yang sama,
  `exclusive false`, `focusable false`, dan animasi revealer 240 ms.
- Menutup memakai klik jam lagi. Tidak ada listener keyboard, penangkap klik
  selayar penuh, proses latar tambahan, atau polling kalender. Penutupan memakai
  satu delay yang dapat dibatalkan agar animasi selesai sebelum window ditutup.
- Pengujian desktop Middle pada **Niri belum diulang** dalam sesi ini;
  implementasi popup memakai Eww Wayland dan tidak menggunakan dispatcher
  compositor. Tes adapter Niri yang ada tetap lulus.
