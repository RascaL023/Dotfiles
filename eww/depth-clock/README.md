# Depth clock — jam wallpaper berlapis

Jam besar `HH:MM` di atas wallpaper, dengan subjek wallpaper yang tampil **di
depan** angka sehingga sebagian digit tertutup. Efek kedalamannya bukan trik
compositor: hanya tiga lapisan biasa.

```text
awww            wallpaper asli                       (lapisan paling bawah)
  ↓
Eww (bg layer)  label jam hidup + PNG foreground     (jendela transparan)
  ↓
jendela biasa   terminal, browser, …                 (menutupi jam saat dipakai)
```

Foreground adalah **PNG transparan statis** hasil potongan wallpaper. Jam hanya
mengganti teks label sekali per menit; PNG tidak pernah dibuat ulang saat waktu
berubah. Tidak ada polling cepat, tidak ada proses ffmpeg, tidak ada
Quickshell.

> Membangun dari nol untuk wallpaper lain? Ikuti
> [`GUIDE.md`](GUIDE.md) — langkah konkret beserta perintah dan angka yang
> dipakai.

Satu-satunya sumber warna tetap Matugen: `eww/eww.scss` mengimpor
`~/.myenv/theme/current/scss/theme`, dan [`../styles/_depth-clock.scss`](../styles/_depth-clock.scss)
hanya memakai token semantik (`$primary-accent` untuk angka, `$layer-lowest`
untuk bayangan). Tidak ada hex literal di stylesheet jam.

## Berkas

| Berkas | Isi |
|---|---|
| [`../windows/depth-clock.yuck`](../windows/depth-clock.yuck) | `deflisten` jam, `overlay` jam + gambar, `defwindow` |
| [`../styles/_depth-clock.scss`](../styles/_depth-clock.scss) | warna, font, ukuran, bayangan |
| [`settings.conf`](settings.conf) | tinggi band + daftar wallpaper yang punya mask |
| [`../scripts/depthctl`](../scripts/depthctl) | generate foreground dan kendali jendela |
| `~/.cache/eww-depth-clock/foreground.png` | artefak hasil (di luar repo, git-ignored by nature) |

Jam memakai daemon Eww utama (`eww daemon --force-wayland`) — tidak ada daemon
kedua dan tidak ada konflik dengan [`../bar/barctl`](../bar/barctl).

`depth-clock.yuck` menulis path PNG sebagai `/home/rascal/.cache/...`, sama
seperti `eww.scss` yang menulis path theme absolut; sesuaikan keduanya pada
mesin lain. `depthctl` sendiri selalu memakai `$XDG_CACHE_HOME` atau
`~/.cache` sesuai lingkungannya.

## Menjalankan

```sh
~/.dotfile/eww/scripts/depthctl start      # buka untuk wallpaper aktif
~/.dotfile/eww/scripts/depthctl stop       # tutup jendela, daemon tetap hidup
~/.dotfile/eww/scripts/depthctl toggle
~/.dotfile/eww/scripts/depthctl reload     # bangun ulang aset lalu buka lagi
~/.dotfile/eww/scripts/depthctl status
~/.dotfile/eww/scripts/depthctl generate   # hanya bangun ulang foreground
~/.dotfile/eww/scripts/depthctl refresh    # reposisi jendela yang sudah terbuka
~/.dotfile/eww/scripts/depthctl wallpaper "<path gambar>"
```

`start` membaca wallpaper yang sedang ditampilkan `awww query`, mengukur output
yang fokus (`hyprctl -j monitors` atau `niri msg -j outputs`), membangun
foreground bila cache-nya basi, lalu membuka jendela dengan ukuran yang tepat
untuk output itu. `stop` hanya menutup jendela; daemon, widget profil, dan bar
tetap hidup.

Jangan memakai `eww open depth-clock` langsung untuk pemakaian normal: geometri
di Yuck adalah fallback (1366×768) dan tidak membawa ukuran band dari
`settings.conf` maupun offset bar. `refresh` dipakai setelah `eww reload`
(reload Eww membuka ulang jendela dari geometri Yuck), dan hook tema Matugen
memanggilnya otomatis.

## Bagaimana jam dan foreground bekerja bersama

1. `deflisten depth-clock-time` menjalankan satu loop `bash` yang mencetak
   `date +%H:%M` lalu tidur sampai batas menit berikutnya. Jadi satu
   bangun per menit, bukan polling satu detik.
2. `overlay` menggambar label jam lebih dulu, lalu PNG foreground.
3. PNG berada di `halign "center"`, `valign "start"`, ukuran aslinya. Karena
   jendela mulai di `0,0` selebar layar, isi PNG jatuh persis di koordinat
   wallpaper — potongan kanvasnya dibuat simetris terhadap titik tengah layar
   supaya `halign "center"` tidak menggeser apa pun.
4. Waktu berubah → hanya teks label yang berubah. Gambar, wallpaper, dan
   pipeline ImageMagick tidak disentuh.

## Mengatur tampilan

| Parameter | Lokasi | Catatan |
|---|---|---|
| Warna angka | `../styles/_depth-clock.scss` (`$primary-accent`) | ikut tema aktif |
| Bayangan | `$depth-clock-shadow` | `rgba($layer-lowest, 0.55)`, offset 10×12 px |
| Font | `$depth-clock-font` / `$depth-clock-weight` | Noto Serif Display regular (serif display, kontras tinggi) |
| Ukuran | `$depth-clock-size: 380px` | 380 px ≈ 960 px lebar untuk `12:00` (70% layar 1366) |
| Posisi vertikal | `$depth-clock-padding-top: 49px` | glyph atas jatuh di ±180 px (23% tinggi 768) |
| Tinggi band | `DEPTH_BAND_HEIGHT` di `settings.conf` | harus ≥ padding + line box label (49 + 520 = 569 px) |
| Ukuran jendela | `:height`/`:width` di `depth-clock.yuck` + `--size` dari `depthctl` | GTK menaikkan tinggi ke minimum label, jadi nilainya bisa tumbuh |

Kalau `$depth-clock-size` atau `$depth-clock-padding-top` diubah, sesuaikan
`DEPTH_BAND_HEIGHT` dan `:height` (padding + tinggi line box, ditambah sedikit
margin) lalu `depthctl reload`. Band harus menutupi seluruh line box label,
kalau tidak PNG berhenti sebelum dasar angka dan digit bawah akan tergambar di
atas subjek. Komposisi awal mengikuti acuan visual: jam selebar ±70% layar
dengan tepi atas di ±23% tinggi layar.

Jendela memakai `:stacking "bg"` (layer background Wayland), `:exclusive false`
(tidak memesan ruang; `hyprctl` tetap melaporkan `reserved [0,34,0,0]` milik
bar), dan `:focusable "none"` (tanpa fokus keyboard).

**Offset bar.** Layer surface ditempatkan di dalam *usable area*, jadi selama
bar memesan 34 px di atas, jendela dengan `y=0` mendarat di `y=34` dan seluruh
foreground ikut turun 34 px dari wallpaper. `depthctl` membaca field `reserved`
dari `hyprctl -j monitors` dan membuka jendela dengan `--pos 0x-<reserved>`,
sehingga band tetap mulai di `y=0` layar. Kalau tinggi bar berubah, jalankan
`depthctl refresh` supaya offset baru dipakai.

## Foreground: cara membuatnya

Semua langkah berjalan sekali per kombinasi wallpaper + ukuran layar, di
`depthctl generate`, memakai ImageMagick (`magick`):

1. Wallpaper di-resize dan di-crop persis seperti `awww` (`--resize crop`,
   gravity center), lalu diambil band atas setinggi `DEPTH_BAND_HEIGHT`.
2. Selisih warna terhadap warna latar → threshold → silhouette awal.
3. Lubang latar yang tertutup subjek diisi (`floodfill` dari pojok).
4. Bintik debu kertas dibuang lewat filter luas komponen
   (`area-threshold`).
5. Masker di-erode 1 px lalu di-blur 0.8 px: tepi lembut tanpa garis latar.
6. Masker dipakai sebagai alpha kanal pada potongan wallpaper, lalu di-crop
   simetris terhadap tengah layar.
7. Hasil divalidasi: cakupan masker harus 2–60% (kalau tidak, keying gagal dan
   skrip berhenti dengan `[ERR]`), kanal alpha harus ada, pojok harus transparan.

Hasilnya PNG kecil (484×580, ±390 KB), bukan wallpaper penuh.

### Menambah wallpaper baru

Tambahkan satu baris ke `DEPTH_MASKS` di [`settings.conf`](settings.conf):

```sh
DEPTH_MASKS=(
  "Nyx Bright.png|#F0EBD9|5|500"
)
```

Format: `nama berkas|warna latar|toleransi %|luas bintik px`.

- **Warna latar**: warna dominan di belakang subjek. Ambil dengan
  `magick "<wallpaper>" -format %c histogram:info:- | sort -rn | head -3`.
- **Toleransi**: 5 berhasil untuk latar kertas Nyx. Naikkan bila sisa latar
  masih ikut; turunkan bila rambut/objek terang ikut terpotong.
- **Luas bintik**: komponen lebih kecil dari ini dibuang, dihitung dalam
  piksel wallpaper **asli** lalu diskala ke resolusi layar. `0` mematikan
  filter.

Wallpaper dengan latar ramai (foto, gradien, banyak objek) **tidak** akan
ter-key dengan baik. Skrip akan menolak bila cakupan masker di luar 2–60%, dan
lapisan jam tetap tersembunyi untuk wallpaper itu (tidak ada masker = tidak ada
foreground yang salah posisi).

### Koreksi manual

Kalau keying otomatis hampir benar, cara tercepat adalah mengedit masker hasil
sekali dan menyimpannya sebagai masker manual:

```sh
# hasil antara ada di direktori sementara; untuk koreksi, jalankan langkah
# yang sama secara manual ke /tmp, edit dengan editor gambar (GIMP/Krita),
# lalu simpan sebagai PNG grayscale selebar band.
magick "<wallpaper>" -resize '1366x768^' -gravity center -extent '1366x768' \
  -crop 1366x580+0+0 +repage /tmp/depth-band.png
```

Selama masker manual belum didukung sebagai input, ubah `toleransi` dan
`luas bintik` lebih dulu; keduanya cukup untuk wallpaper bergaya ilustrasi
dengan latar rata seperti Nyx.

## Ganti wallpaper

`hypr/sources/scripts/nextwall.sh` memanggil
`depthctl wallpaper "$CHOSEN"` setelah `awww img` selesai (dan juga pada mode
`first`). Perilakunya:

- wallpaper punya masker → foreground dibangun/dipakai ulang, jam dibuka;
- wallpaper tanpa masker → jam ditutup, jadi PNG lama tidak pernah tertinggal
  di atas wallpaper lain;
- transisi `awww` tidak diubah; panggilan berjalan setelahnya dan tidak pernah
  menggagalkan skrip (`|| true`).

Kalau wallpaper diganti dengan cara lain, panggil `depthctl wallpaper "<path>"`
atau `depthctl stop` sendiri.

## Tema

- Flow A (wallpaper) dan Flow B (palet tetap) sama-sama menghasilkan
  `$primary-accent` dan `$layer-lowest`, jadi satu stylesheet bekerja untuk
  keduanya — tidak ada palet kedua, tidak ada template matugen baru.
- Ganti tema berarti symlink `~/.myenv/theme/current` berubah; stylesheet Eww
  baru terbaca setelah reload. Kedua `[templates.scss]` di
  `matugen/config.toml` dan `matugen/templates/kanagawa-dragon-lotus/config.toml`
  sekarang berakhir dengan `eww reload`, jadi render ulang tema langsung
  mewarnai ulang jam (dan jendela Eww lain).
- Mengganti wallpaper **tidak** memicu render ulang palet; wallpaper pilihan
  dan tema warna tetap independen.

## Catatan penting

- **Stylesheet SCSS harus ASCII.** Satu karakter non-ASCII (mis. em dash) di
  file `.scss` membuat libsass menambahkan `@charset "UTF-8";` di awal CSS, dan
  GTK menolaknya (`error: unknown @ rule`) sehingga seluruh stylesheet gagal
  dimuat. Pakai `-` di komentar SCSS.
- `:focusable "none"` hanya mematikan fokus keyboard. Rekaman protokol Wayland
  menunjukkan Eww tetap mengirim `wl_surface.set_input_region(nil)`, artinya
  seluruh persegi jendela menerima pointer. Klik di area desktop kosong pada
  band 1366×580 akan diserap lapisan ini. Jendela aplikasi tetap di atasnya
  karena layer background berada di bawah jendela biasa. Kalau perlu
  click-through total, Hyprland menyediakan `layerrule = ignorezero` (khusus
  Hyprland, jadi tidak dipakai di sini).
- Skala output 1× adalah target yang diverifikasi. Pada skala 2× PNG akan
  diperbesar GTK dan ketajaman/presisinya menurun.
- Satu output (yang fokus). Multi-monitor butuh `depthctl start` per output
  dengan `--screen`, belum diotomatiskan.
- GTK menaikkan tinggi jendela ke minimum label, jadi tinggi nyata bisa lebih
  besar dari nilai `--size`; `depth-clock.yuck` dan `DEPTH_BAND_HEIGHT` sudah
  disetel ke padding + tinggi line box (49 + 520 px) plus margin.

## Pemeriksaan

```sh
~/.dotfile/eww/scripts/depthctl status
hyprctl -j layers | jq '.[] | .levels[][] | select(.namespace=="gtk-layer-shell")'
hyprctl -j monitors | jq '.[] | {name, reserved}'     # harus tetap [0,34,0,0]
timeout 5 eww --force-wayland -c ~/.dotfile/eww active-windows
timeout 5 eww --force-wayland -c ~/.dotfile/eww get depth-clock-time
```

Hasil pengujian sesi implementasi ada di [`VERIFICATION.md`](VERIFICATION.md).
