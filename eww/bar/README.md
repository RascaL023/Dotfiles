# Bar Eww — tiga pulau

Bar mandiri untuk **Eww 0.6.0 + Wayland**, dengan adapter **Hyprland dan Niri**,
target awal 1366×768. Satu jendela transparan menampung tiga pulau 30 px;
padding atas 3 px dan bawah 0 px membuat area eksklusif **33 px**. Margin horizontal
4 px, radius 10 px, border 1 px; teks 11 px dan ikon 14 px. Launcher memakai ikon
NixOS. Jam tetap di tengah layar. Workspace berupa
pil tanpa angka: 6 px ketika tidak aktif, memanjang menjadi 22 px ketika aktif,
dengan transisi 160 ms. Tooltip tetap menampilkan identitas workspace.
Padding bawah bar sudah nol; jarak tambahan dari pengaturan gap compositor
tetap mengikuti konfigurasi Niri/Hyprland Anda.

## Menjalankan

```sh
~/.dotfile/eww/bar/barctl doctor
~/.dotfile/eww/bar/barctl start
~/.dotfile/eww/bar/barctl start --monitor LVDS-1
~/.dotfile/eww/bar/barctl toggle
~/.dotfile/eww/bar/barctl reload
~/.dotfile/eww/bar/barctl status
~/.dotfile/eww/bar/barctl stop
```

`--monitor` menerima nama konektor atau indeks Eww dan berlaku untuk
`start`/`toggle`. Dukungan awal satu monitor pilihan. `reload` melakukan
stop/start yang bersih, mempertahankan monitor terakhir, dan mengembalikan tray
ke keadaan terlipat. Setelah mengganti monitor default di pengaturan, gunakan
`stop` lalu `start`. Reload ketika bar berhenti tidak membuka bar.

Semua perintah menggunakan `eww --config <path absolut bar/> --force-wayland
--no-daemonize`. `barctl` memulai daemon secara eksplisit dan menyimpan identitas
PID. Ini mencegah Eww 0.6.0 membuat daemon kedua ketika respons IPC melebihi
timeout internal 100 ms. Setelah `open`, controller memeriksa jendela yang
benar-benar terbuka, termasuk bila klien lebih dulu timeout.
Tidak ada `pkill eww`, perubahan autostart, konfigurasi widget lama, Waybar,
folder referensi, atau konfigurasi Matugen. Bila bar lain aktif, compositor
dapat menjumlahkan area eksklusif keduanya. Keybinding lama yang menjalankan
`pkill eww` tetap dapat menutup semua instance; gunakan `barctl` untuk bar ini.

## Pengaturan dan dependensi

Edit **`settings.json`**, lalu jalankan `barctl reload`:

- `monitor`: konektor awal (`LVDS-1`) atau indeks.
- `compositor`: `auto` (default), `hyprland`, atau `niri`. Deteksi otomatis
  mendahulukan `XDG_CURRENT_DESKTOP`, lalu lingkungan socket sesi.
- `modules`: tampilkan/sembunyikan modul; collector tidak membuka listener untuk
  modul data yang dinonaktifkan.
- `workspaces`: workspace dasar Hyprland, awalnya 1–5. Workspace positif lain
  yang terisi atau aktif ditambahkan otomatis; special workspace tidak ditampilkan.
  Niri mengikuti workspace dinamis yang tersedia pada output bar, termasuk
  workspace kosong terakhir. Klik memakai ID stabil, bukan indeks yang bisa
  berubah. Bar tidak membuat workspace/config Niri tambahan.
- `intervals`: baterai 30 detik, penggabungan peristiwa 150 ms, batas reconnect
  30 detik, timeout per perintah 3 detik. Jam mengikuti batas menit berikutnya.
- `music`: aktifkan MPD/MPRIS, urutan preferensi, nama bridge MPD, batas judul
  1–24 karakter. MPD memakai `MPD_HOST`/`MPD_PORT` dari lingkungan `mpc`.
- `commands`: **array argv**, misalnya `["kitty", "nmtui"]`. `~` diekspansi.
  Pipe, `&&`, `$HOME`, dan substitusi shell tidak dievaluasi. Gunakan path
  executable/script jika memerlukan logika tambahan.

Sesi Hyprland yang diuji memakai 0.56.2 dengan konfigurasi Lua. Aksi workspace
memakai `hl.dsp.focus({ workspace = N })`, dengan fallback dispatcher lama
untuk konfigurasi Hyprlang. `commands.logout: null` memilih logout otomatis:
`hl.dsp.exit()` pada Hyprland, `niri msg action quit --skip-confirmation` pada
Niri. Konfirmasi tetap dilakukan terlebih dahulu oleh menu Rofi. Untuk
Hyprland dengan konfigurasi lama, override dengan `["hyprctl", "dispatch", "exit"]`.

Wajib: Eww dengan dukungan Wayland, Python **3.10+** (standard library saja),
Hyprland atau Niri. Font: Inter dan JetBrainsMono Nerd Font. Dependensi modul:

| Modul | Perintah / sumber |
|---|---|
| Workspace | `hyprctl` + socket Hyprland, atau `niri` + socket JSON `$NIRI_SOCKET` |
| Volume | `wpctl`, `pw-dump` (PipeWire/WirePlumber) |
| Jaringan | `nmcli`, NetworkManager; `kitty` + `nmtui` untuk klik |
| Musik | `playerctl` + `dbus-monitor` untuk MPRIS; `mpc` untuk MPD |
| Baterai | `/sys/class/power_supply/*` |
| Notifikasi | `swaync-client`, SwayNC |
| Launcher / daya | `rofi`, `hyprlock`, `systemctl`, perintah logout compositor aktif |
| Tray | StatusNotifierItem melalui D-Bus sesi |

`barctl doctor` memeriksa pengaturan, executable, lingkungan sesi, resolusi font,
dan ketersediaan modul pada instance berjalan. Modul yang kehilangan layanan
tetap memiliki state lengkap: musik/baterai tersembunyi, workspace tidak aktif,
volume/notifikasi tidak dapat diklik; jaringan tetap dapat membuka `nmtui`.

## Interaksi

| Area | Aksi |
|---|---|
| Launcher | Klik membuka Rofi drun |
| Workspace | Pil aktif memanjang; klik berpindah, tooltip menunjukkan nomor/nama, gulir horizontal/touchpad untuk workspace tambahan |
| Musik | Klik play/pause; gulir atas sebelumnya, bawah berikutnya; tooltip artis/judul/sumber lengkap |
| Jam | Waktu 24 jam, tanggal singkat; tooltip tanggal lengkap dan zona waktu |
| Tray | Chevron membuka/menutup; area ikon bisa digulir horizontal |
| Volume | Klik mute; gulir ±5%, maksimum 100%; ikon berbeda untuk mute, 0%, 1–33%, 34–66%, dan ≥67% |
| Jaringan | Tooltip koneksi aktif; klik membuka nmtui di Kitty |
| Baterai | Ikon kapasitas per 10% (dibulatkan ke bawah), dengan varian petir saat mengisi; tooltip tiap baterai; rendah ≤20% mendapat warna warning |
| Notifikasi | Klik panel SwayNC; klik kanan DND; tooltip jumlah dan status DND |
| Daya | Rofi: kunci, suspend, logout, restart, shutdown; tiga aksi terakhir memerlukan pilihan konfirmasi |

Bila beberapa baterai tersedia, angka ringkas adalah rata-rata persentasenya;
tooltip tetap menampilkan nilai dan status masing-masing. Nama interface,
nama baterai, UID, dan socket Hyprland tidak di-hardcode.
Ikon volume/baterai memakai data yang sudah dibaca, tanpa proses atau timer
tambahan. Wi-Fi tetap menampilkan status koneksi; tidak memantau kekuatan
sinyal atau melakukan scan berkala.

## Tema

Semua warna, font, ukuran, spacing, dan radius ada di
**`styles/_tokens.scss`**. Komponen di `_bar.scss` hanya memakai token semantik.
`$tray-icon-size` berupa bilangan tanpa unit karena diteruskan ke atribut Eww;
ukuran lain memakai px. Tinggi geometri Yuck 1 px hanya batas minimum;
tinggi sebenarnya berasal dari token SCSS, sehingga tidak ada salinan 33 px
yang perlu disinkronkan di Yuck.
Lebar area pil mengikuti jumlah workspace hingga batas `$workspace-area`;
lebih dari batas itu dapat digulir. Area klik tetap 24 px tinggi meskipun pil
hanya setinggi 6 px. Transisi hanya berjalan ketika status workspace berubah.

Palet lokal gelap hangat langsung bekerja tanpa theme store. Integrasi Matugen
bersifat opsional: kedua template yang sudah ada,
`../../matugen/templates/general/source.scss` dan
`../../matugen/templates/kanagawa-dragon-lotus/template/source.scss`, menyediakan
variabel berikut. Setelah memastikan `~/.myenv/theme/current/scss/theme.scss`
tersedia, tambahkan import **sebelum** definisi token warna dan ganti nilainya:

```scss
@import "/home/rascal/.myenv/theme/current/scss/theme";
$surface: $layer-lowest;
$text: $text-primary;
$muted: $text-secondary;
$accent: $primary-accent;
$on-accent: $on-primary;
$border: $border-default;
$warning: $status-warning;
$hover: $layer-high;
```

Biarkan token font Inter/ikon tetap lokal jika ingin mempertahankan desain.
Import memakai path absolut; sesuaikan home pada mesin lain. Jangan menulis
ulang berkas generated. Perubahan theme symlink dari switcher eksternal perlu
`barctl reload`; bar ini tidak mengelola switcher atau template Matugen.

## Adapter dan lifecycle

`eww.yuck` hanya memiliki **satu `deflisten`**:

```sh
cd ~/.dotfile/eww/bar
python3 scripts/adapter.py listen      # satu objek JSON lengkap per baris
python3 scripts/adapter.py snapshot    # baca state instance berjalan
./barctl action volume-mute
./barctl action music-scroll down
```

`scripts/common.py` mendefinisikan pengaturan dan schema state.
`sources.py` memisahkan parser, snapshot dan adapter compositor `Hyprland`/`Niri`.
`adapter.py` mengatur event loop, penggabungan peristiwa, timer, reconnect,
dan socket aksi. `actions.py` membatasi nama aksi serta menjalankan argv tanpa
shell. Yuck menggunakan `for` biasa dan `label :text`; tidak ada `literal`,
Pango markup dari metadata, atau penyisipan nama jaringan/judul ke command.
Satu-satunya nilai dinamis dalam command Yuck adalah ID workspace numerik dan
arah scroll Eww; keduanya divalidasi kembali oleh adapter.

Untuk compositor lain, implementasikan `snapshot`, `socket_path`, `subscribe`,
`relevant`, dan `focus` sebagai adapter baru; perbarui pemilihan adapter dan validasi
`compositor`. Widget serta schema JSON tidak perlu diganti. Untuk mengganti
pengumpul secara keseluruhan, pertahankan schema lengkap dan kontrak aksi IPC,
atau ubah pemanggilan `barctl action` secara bersamaan.

Alur data:

- Workspace Hyprland: snapshot awal dan setelah event relevan pada `.socket2.sock`.
- Workspace Niri: langganan JSON `EventStream`, snapshot setelah event workspace
  atau penambahan/penghapusan jendela. Event layout/animasi diabaikan. Fokus
  memakai request JSON `FocusWorkspace` dengan `Id`, tanpa evaluasi nama workspace.
- Audio: stream `pw-dump --monitor --no-colors`, snapshot `wpctl get-volume`.
  Parser incremental hanya meneruskan perubahan volume/mute sink, penambahan/
  penghapusan sink, dan metadata default sink. Event klien `wpctl` sendiri
  diabaikan agar pembacaan volume tidak membuat loop event.
- Jaringan: `nmcli monitor`, snapshot status perangkat; tidak ada scan Wi-Fi.
- MPRIS: D-Bus `PropertiesChanged` untuk Metadata/PlaybackStatus dan
  `NameOwnerChanged`. Perubahan posisi saja diabaikan. Metadata/kontrol melalui
  playerctl dengan instance spesifik.
- MPD: `mpc idleloop player options playlist`; metadata/kontrol melalui mpc.
- Notifikasi: JSON `swaync-client -s`.
- Baterai: sysfs tiap 30 detik. Jam: batas menit berikutnya. Tidak ada tick satu
  detik, cover art, unduhan, atau perhitungan progres lagu.

Pemutar Playing mengalahkan Paused. Jika beberapa Playing, pilihan saat ini
dipertahankan; preferensi dipakai saat perlu memilih pengganti. Bridge MPRIS
bernama `mpd`/`mpd-mpris` (termasuk suffix `.instance...`) disisihkan ketika
MPD asli tersedia. Tambahkan nama bridge lain ke `mpd_bridges`. Jika memakai
bridge ke **server MPD berbeda**, hapus namanya dari daftar tersebut.
Kontrol menggunakan pemutar yang dikirim pada state terakhir, tanpa memilih
ulang saat klik. Pemutar stopped tidak memenuhi syarat untuk ditampilkan.

Stream yang berhenti mencoba lagi setelah 1, 2, 4, 8, 16, lalu maksimal 30 detik;
koneksi stabil selama 30 detik mengembalikan backoff ke awal. Penggabungan event
memakai jendela waktu tetap agar stream ramai tidak menunda refresh selamanya.
State hanya dicetak ketika isinya berubah.

File runtime berada di `$XDG_RUNTIME_DIR/eww-islands-<hash path>/`, mode 0700.
Lock mencegah collector dan operasi lifecycle ganda. SIGTERM/SIGINT/SIGHUP
membatalkan tugas dan menghentikan serta me-reap child process. `stop` menutup
daemon bar dan menunggu lock collector bebas. Aplikasi yang sengaja dibuka
pengguna (Kitty/Rofi/layar kunci) boleh hidup setelah bar berhenti.

## Pemeriksaan dan troubleshooting

```sh
python3 -m unittest discover -s ~/.dotfile/eww/bar/tests -v
tail -f "$XDG_RUNTIME_DIR"/eww-islands-*/daemon.log
eww -c ~/.dotfile/eww/bar active-windows
python3 ~/.dotfile/eww/bar/scripts/adapter.py snapshot
```

Tes unit mencakup kutip/backslash/Unicode/newline, layanan kosong, deduplikasi
bridge, prioritas pemutar, argv aksi, konfirmasi daya dengan pengganti perintah,
penggabungan event, reconnect stream/socket, dan reaping child.
Tes socket membutuhkan izin socket Unix lokal.

Pemeriksaan desktop yang **secara eksplisit mengubah keadaan sementara**:

```sh
python3 bar/tests/live_checks.py cycles --count 20
python3 bar/tests/live_checks.py workspaces
python3 bar/tests/live_checks.py controls
python3 bar/tests/live_checks.py measure --seconds 60 --label idle
python3 bar/tests/live_checks.py music-measure --seconds 60
```

Jalankan dari direktori `eww/`. `cycles` meninggalkan bar berjalan. `controls`
memerlukan MPD paused dan bridge MPRIS; menguji workspace, volume/mute, DND,
tray, play/pause dan next/previous, lalu mengembalikan pengaturan serta posisi
lagu. Tidak menjalankan aksi daya.
`measure` tidak mengubah playback. `music-measure` memerlukan MPD paused,
memainkan musik dengan sink di-mute, lalu memulihkan lagu, posisi, dan mute.
CPU dihitung dari `/proc` untuk seluruh pohon proses bar,
termasuk CPU child yang sudah di-reap; RSS adalah jumlah RSS proses (shared
pages dapat terhitung lebih dari sekali). Hasil sesi implementasi ada di
[`VERIFICATION.md`](VERIFICATION.md).

- Bar tidak muncul: jalankan dari lingkungan sesi Wayland, cek monitor dengan
  `hyprctl -j monitors` atau `niri msg -j outputs`, lalu `barctl doctor` dan log Eww.
- Ikon kotak: cek `fc-match 'JetBrainsMono Nerd Font'`.
- Musik kosong: cek `playerctl -l` dan `mpc status`; periksa lingkungan MPD
  pada proses yang menjalankan bar.
- Jaringan/notifikasi kosong: cek service pengguna dan D-Bus sesi. Modul lain
  tetap berjalan; setelah service kembali, stream reconnect otomatis.
- Tray kosong: buka chevron; aplikasi harus menyediakan StatusNotifierItem.
  Kehadiran host tray lain dapat memengaruhi aplikasi tertentu.
- Setelah edit Yuck/SCSS/settings: gunakan `barctl reload`, terutama setelah
  mengganti schema atau token tray. Eww juga dapat reload otomatis saat file
  berubah; lock collector mencegah duplikasi.
- Log utama: `$XDG_RUNTIME_DIR/eww-islands-<hash>/daemon.log`. Karena daemon
  dimulai tanpa terminal, Eww 0.6.0 tidak mengalihkan stderr sendiri ke
  `eww logs`; controller mengarahkannya ke berkas ini. Pesan IPC `channel closed`
  sesekali dapat muncul jika `open` melebihi timeout klien 100 ms; controller
  memeriksa hasil aktual dan tidak membuat daemon lain.

## Referensi

- [Konfigurasi Eww v0.6.0](https://github.com/elkowar/eww/blob/v0.6.0/docs/src/configuration.md)
- [Implementasi widget Eww v0.6.0](https://github.com/elkowar/eww/blob/v0.6.0/crates/eww/src/widgets/widget_definitions.rs)
- [API dispatcher Hyprland](https://wiki.hypr.land/Configuring/Basics/Dispatchers/)
- [Protokol IPC Niri](https://github.com/YaLTeR/niri/blob/main/niri-ipc/src/lib.rs)
- [Pemetaan ikon Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/blob/master/css/nerd-fonts-generated.css) — NixOS, volume, dan tingkat baterai
- [`../monasm-config.example/`](../monasm-config.example/) — pola tray/workspace lokal
- [Arin oleh adi1090x](https://github.com/adi1090x/widgets/tree/main/eww/arin) — referensi kelompok visual

Implementasi ini memakai satu window dan adapter event sendiri; referensi
dipakai sebagai acuan desain, tanpa menyalin pola polling satu detiknya.
