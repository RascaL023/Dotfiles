# Rofi

`rofi-ctl` adalah pintu masuk untuk memilih mode, layout, dan opsi Rofi.
Pemanggil dari compositor, bar, atau skrip lain cukup menyebut jenis menu;
path konfigurasi, tema, dan PID diurus di folder ini.

## Pemanggilan

```bash
~/.config/rofi/rofi-ctl apps
~/.config/rofi/rofi-ctl apps orbit
~/.config/rofi/rofi-ctl run orbit
~/.config/rofi/rofi-ctl toggle apps
~/.config/rofi/rofi-ctl shell
~/.config/rofi/rofi-ctl wallpaper -d ~/Pictures/Wallpaper
```

Tanpa argumen, skrip membuka `apps`. Pilihan `apps` / `orbit` adalah nama style
untuk launcher aplikasi dan perintah. Opsi Rofi tambahan diletakkan setelahnya.

| Perintah | Layout / input | Hasil |
|---|---|---|
| `apps [apps\|orbit]` | Launcher aplikasi, mode `drun` | Rofi membuka aplikasi |
| `run [apps\|orbit]` | Launcher perintah, mode `run` | Rofi menjalankan perintah |
| `window` | Layout aplikasi, mode bawaan `window` | Rofi memilih jendela |
| `toggle [apps\|orbit]` | Launcher dengan style yang dipilih | Buka/tutup launcher tersebut |
| `shell` | Dua kartu: Noctalia / Native | Nama pilihan ke stdout |
| `menu` | Daftar teks dari stdin, satu kolom | Pilihan atau input bebas ke stdout |
| `wallpaper [-d DIR]` | Galeri fullscreen; baris dari stdin atau gambar di DIR | Nama pilihan, atau path absolut dengan `-d` |
| `password` | Prompt input, stdin dikosongkan | Teks yang diketik ke stdout |

Skrip meneruskan stdout dan exit status Rofi, termasuk status `1` saat pengguna
membatalkan. Bantuan lengkap: `rofi-ctl --help`.

Menu dengan pilihan tetap dapat memakai `-no-custom` agar hasil selalu berasal
dari daftar. Perintah `shell` dan `wallpaper` sudah menyertakan opsi itu.

```bash
printf '%s\n' Batal Restart Shutdown |
  rofi-ctl menu -no-custom -p Daya

rofi-ctl password -p 'Password Wi-Fi'
```

`menu` dan `wallpaper` menerima stdin langsung, termasuk metadata NUL/ikon Rofi;
wrapper tidak membaca ulang atau memodifikasi data tersebut.

## Registrasi ke PATH

```bash
ln -s ~/.dotfile/rofi/rofi-ctl ~/.local/bin/rofi-ctl
rofi-ctl apps orbit
```

Pakai symlink, bukan salinan: skrip mencari `config.rasi` dan `themes/` di
direktori aslinya, dan itu hanya benar bila dipanggil lewat symlink. Salinan
ditolak dengan exit status 2 dan pesan di stderr, bukan kegagalan Rofi.

## Struktur

```text
rofi/
├── rofi-ctl                  # pemilihan mode, layout, opsi, dan toggle
├── launch.sh                 # symlink kompatibilitas ke rofi-ctl
├── config.rasi               # pengaturan umum + layout default
├── themes/
│   ├── shared/
│   │   ├── palette.rasi      # satu path import palet Matugen aktif
│   │   └── list.rasi         # style bersama untuk daftar klasik
│   ├── default.rasi          # default untuk pemanggilan rofi langsung
│   ├── apps.rasi             # launcher klasik dua kolom, dengan ikon
│   ├── list.rasi             # menu teks satu kolom
│   ├── prompt.rasi           # input password tanpa daftar pilihan
│   ├── orbit.rasi            # launcher dengan panel samping
│   ├── shell-select.rasi     # pemilih dua shell di tengah layar
│   ├── wallpaper.rasi        # galeri fullscreen
│   └── theme.rasi            # alias kompatibilitas untuk list.rasi
└── tests/test_rofi_ctl.py    # kontrak argumen, stdin/stdout, status, dan toggle
```

`config.rasi` mengatur font default, tema ikon, label, dan mode umum. Tampilan
berada di `themes/`. Semua layout membaca palet melalui `shared/palette.rasi`;
style klasik digunakan bersama oleh default, aplikasi, menu teks, dan prompt.

Skrip menyelesaikan path relatif terhadap lokasi aslinya, sehingga bisa berjalan
dari direktori mana pun, lewat symlink direktori `~/.config/rofi`, lewat symlink
berkas di `~/.local/bin`, atau dari checkout yang path-nya mengandung spasi.
Pemanggilan memakai `exec` dan array argumen Bash, tanpa `eval`, `pgrep`, atau
`pkill`.

Toggle menggunakan PID file per style di `$XDG_RUNTIME_DIR` (fallback ke
`$TMPDIR` atau `/tmp`, dengan UID pada nama file). Sebelum menutup launcher,
wrapper memeriksa bahwa proses masih milik pengguna dan command line-nya
menyebut PID file yang sama. Menu lain dan PID yang sudah dipakai ulang tidak
ditutup oleh toggle launcher.

## Data dan backend

`rofi-ctl shell` menyediakan pilihan Noctalia / Native, lalu mencetak hasil.
Tidak ada backend pergantian shell atau indikator shell aktif.

`rofi-ctl wallpaper` menampilkan daftar yang diberikan lewat stdin. Dengan
`-d DIR` (atau `--dir`), ia membaca sendiri gambar satu level di DIR — `*.jpg`,
`*.jpeg`, `*.png`, `*.webp`, `*.gif`, tanpa rekursi — memakai nama berkas
sebagai label dan berkasnya sebagai ikon, lalu mencetak **path absolut** gambar
terpilih, sehingga pemanggil tidak perlu menyusun path lagi. Direktori kosong
atau tidak ada ditolak dengan exit `2`; batal tetap `1` dengan stdout kosong.

```bash
rofi-ctl wallpaper -d ~/Pictures/Wallpaper
```

`hypr/sources/scripts/nextwall.sh` masih menyediakan data sendiri, memasang
wallpaper, dan menyinkronkan depth clock. Logika koneksi Wi-Fi tetap dimiliki
`hypr/sources/scripts/wifi-menu.sh`; menu daya tetap dimiliki Eww.

Pemanggil yang sudah memakai wrapper:

- `hypr/sources/scripts/rofi-toggle.sh`: pintu masuk kompatibilitas untuk
  shortcut Hyprland/Niri, meneruskan ke `toggle apps`.
- `hypr/sources/scripts/nextwall.sh`: galeri wallpaper.
- `hypr/sources/scripts/wifi-menu.sh`: daftar Wi-Fi dan prompt password.
- `eww/bar/settings.json`: launcher aplikasi dan menu daya/konfirmasi.

Ketiga skrip di `hypr/` masih memanggil `launch.sh`; symlink kompatibilitas
menjaga mereka tetap berjalan. Setelah semuanya memakai `rofi-ctl`, `launch.sh`
bisa dihapus.

## Layout khusus

**Orbit** memakai panel samping, pencarian, daftar dua kolom, penghitung hasil,
dan tombol Aplikasi/Perintah. Font Inter menggunakan fallback fontconfig;
ikon aplikasi memakai Papirus. Klik tombol mode atau tekan `Ctrl+Tab` untuk
berganti mode, gunakan panah untuk memilih, `Enter` untuk membuka, dan `Esc`
untuk menutup. Layout menyediakan aturan media untuk layar sempit dan pendek.

**Shell Select** menampilkan Noctalia dan Native dalam dua kartu di tengah layar,
dengan angka urutan dan sorotan pilihan. Dialog berukuran 720 × 520 piksel.
Gunakan panah kiri/kanan, `Enter` untuk mengonfirmasi, dan `Esc` untuk membatalkan.

## Warna dan pemeriksaan

Warna antarmuka berasal dari token Matugen: `layer-*`, `text-*`, `border-*`, serta
pasangan `accent-primary` / `accent-on`. Kedua flow dan varian gelap/terang memakai
kontrak token yang sama. Setelah mengganti palet, cukup buka kembali menu.
Jangan mengedit palet hasil generate secara manual.

```bash
bash -n ~/.config/rofi/rofi-ctl
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s ~/.config/rofi/tests -v
```

Tes wrapper memakai Rofi tiruan; tidak membuka aplikasi, mengubah wallpaper,
menghubungkan jaringan, atau mengganti shell. Untuk memeriksa parser layout
melalui compositor yang sedang berjalan:

```bash
~/.config/rofi/rofi-ctl apps orbit -dump-theme
```
