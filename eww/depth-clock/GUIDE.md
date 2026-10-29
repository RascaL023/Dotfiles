# Cara membuat wallpaper depth clock (Eww + awww + ImageMagick)

Panduan konkret dari nol sampai jam berjalan. Semua langkah sudah dieksekusi di
mesin ini (Hyprland 0.56.2, Eww 0.6.0, awww 0.12.1, ImageMagick 7,
1366×768 skala 1, bar Eww 34 px). Referensi hasil akhir:
`~/Downloads/Wallpaper-Depth-Example.webp`.

Referensi pemakaian sehari-hari ada di [`README.md`](README.md); hasil
pengujian ada di [`VERIFICATION.md`](VERIFICATION.md).

---

## 0. Prasyarat

```sh
eww --version          # 0.6.0, dukungan Wayland
awww query             # wallpaper aktif terbaca
magick -version        # ImageMagick 7 (`magick`, bukan `convert`)
fc-match 'Noto Serif Display'
```

Yang dipakai: Eww (jam + jendela transparan), awww (wallpaper), ImageMagick
(potong foreground sekali saja), satu font display. Tidak ada Quickshell,
daemon baru, ffmpeg, atau AI.

Konsepnya tiga lapisan:

```text
awww            wallpaper asli
Eww bg layer    label jam live + PNG foreground transparan (statis)
jendela biasa   terminal/browser di atas jam
```

---

## 1. Tentukan wallpaper dan susun masker

Subjek harus bisa dipisahkan dari latar. Latar rata (ilustrasi, kertas, studio)
berhasil; foto ramai tidak.

```sh
WP="$HOME/Pictures/Wallpaper/Nyx Bright.png"
magick "$WP" -format '%wx%h\n' info:                 # 1920x1080
magick "$WP" -format %c histogram:info:- | sort -rn | head -3
```

Histogram Nyx: `(240,235,217)` mendominasi → itulah warna latar `#F0EBD9`.

Daftarkan di [`settings.conf`](settings.conf):

```sh
DEPTH_MASKS=(
  "Nyx Bright.png|#F0EBD9|5|1000"
)
```

| Kolom | Arti | Cara menebak |
|---|---|---|
| nama berkas | `basename` wallpaper | harus sama persis, termasuk spasi |
| warna latar | warna dominan di belakang subjek | histogram di atas |
| toleransi | 0–100, jarak warna yang masih dianggap latar | mulai 5; naik kalau sisa latar ikut, turun kalau rambut/objek terang terpotong |
| luas bintik | komponen < N piksel wallpaper asli dibuang | mulai 1000; `0` mematikan |

Latar tidak rata? Jangan paksakan. Tanpa entri di sini, jam tidak muncul untuk
wallpaper itu (lebih baik daripada foreground salah posisi).

---

## 2. Bangun foreground (sekali per wallpaper + resolusi)

```sh
~/.dotfile/eww/scripts/depthctl generate
# foreground: /home/rascal/.cache/eww-depth-clock/foreground.png (484x580, 388K)
```

Skrip menjalankan pipeline ini (bisa dicoba manual untuk debugging):

```sh
cd /tmp && W=1366 H=768 BAND=580
magick "$WP" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" +repage wp.png
magick wp.png -crop "${W}x${BAND}+0+0" +repage band.png

# 1) silhouette dari selisih warna latar
magick band.png \( +clone -fill '#F0EBD9' -colorize 100 \) \
  -compose difference -composite -colorspace gray -threshold 5% raw.png
# 2) isi lubang latar yang tertutup subjek (floodfill dari pojok)
magick raw.png -negate bg.png
magick bg.png -fill black -draw 'color 0,0 floodfill' pockets.png
magick raw.png pockets.png -compose lighten -composite solid.png
# 3) buang debu kertas
magick solid.png -define connected-components:area-threshold=500 \
  -define connected-components:mean-color=true -connected-components 8 large.png
# 4) erode 1px (hilangkan rim latar) lalu feather
magick large.png -morphology Erode Disk:1 -blur 0x0.8 mask.png
# 5) jadikan alpha pada potongan wallpaper, crop simetris ke tengah layar
magick band.png mask.png -alpha off -compose CopyOpacity -composite fg.png
```

Cek hasilnya di atas warna kontras (bukan di atas wallpaper):

```sh
magick -size 484x580 xc:'#c02020' fg.png -compose over -composite /tmp/cek.png
```

Harus terlihat subjek dengan tepi bersih, tanpa kotak atau rim krem. Kalau ada
sisa latar besar, naikkan toleransi; kalau rambut hilang, turunkan.

`depthctl` menolak hasil yang gagal: cakupan masker harus 2–60%, corner
transparan, dan kanal alpha harus ada. Kalau keluar `[ERR]`, perbaiki warna
latar/toleransi, jangan lanjutkan.

---

## 3. Pasang widget Eww

Tambah include di `eww/eww.yuck` dan import SCSS di `eww/eww.scss`:

```lisp
(include "windows/depth-clock.yuck")
```

```scss
@import "styles/depth-clock";
```

Isi `eww/windows/depth-clock.yuck` (ringkas):

```lisp
(deflisten depth-clock-time
  :initial "00:00"
  `bash -c 'while :; do date +%H:%M; sleep $((60 - 10#$(date +%S))); done'`)

(defwidget depth-clock-layer []
  (overlay
    (label :class "depth-clock" :text depth-clock-time
      :halign "center" :valign "start")
    (image :class "depth-clock-fg"
      :path "/home/rascal/.cache/eww-depth-clock/foreground.png"
      :halign "center" :valign "start" :preserve-aspect-ratio false)))

(defwindow depth-clock
  :monitor 0 :stacking "bg" :focusable "none" :exclusive false
  :geometry (geometry :x "0" :y "0" :width "100%" :height "580px" :anchor "top left")
  (depth-clock-layer))
```

Kunci-kunci yang penting:

- `:stacking "bg"` → layer background Wayland (di bawah jendela biasa).
- `:exclusive false` → tidak memesan ruang desktop.
- `:focusable "none"` → tanpa fokus keyboard.
- `overlay` menggambar label dulu, gambar **sesudahnya**.
- `halign "center"` + PNG simetris ke tengah layar = isi PNG jatuh tepat di
  koordinat wallpaper.
- Jam dicetak sekali per batas menit, bukan polling per detik.

---

## 4. Setel tampilan di SCSS

`eww/styles/_depth-clock.scss` — semua warna dari token Matugen, bukan hex:

```scss
$depth-clock-font: "Noto Serif Display";
$depth-clock-weight: 400;
$depth-clock-size: 380px;
$depth-clock-padding-top: 49px;
$depth-clock-shadow: 10px 12px 10px rgba($layer-lowest, 0.55);

.depth-clock {
  color: $primary-accent;
  font-family: $depth-clock-font;
  font-weight: $depth-clock-weight;
  font-size: $depth-clock-size;
  padding-top: $depth-clock-padding-top;
  text-shadow: $depth-clock-shadow;
}
```

Angka awal yang dipakai (cocok dengan acuan ±70% lebar layar, tepi atas ±23%
tinggi layar):

| Parameter | Nilai | Efek |
|---|---|---|
| `font-size` | 380 px | `12:00` ≈ 960 px (70% dari 1366) |
| `padding-top` | 49 px | glyph atas di ±180 px |
| `letter-spacing` | 0 | serif tidak perlu dirapatkan |
| bayangan | 10×12 px, blur 10, `$layer-lowest` 55% | kedalaman |

**Wajib ASCII.** Satu em dash di `.scss` membuat libsass menulis
`@charset "UTF-8";` dan GTK menolaknya (`error: unknown @ rule`) → seluruh
stylesheet gagal dimuat.

Sesuaikan tinggi band supaya foreground menutupi seluruh line box label:

```sh
# padding + line box (380px font ≈ 520px) + margin
DEPTH_BAND_HEIGHT=580      # eww/depth-clock/settings.conf
:height "580px"            # eww/windows/depth-clock.yuck
```

Lalu bangun ulang aset dan muat ulang:

```sh
~/.dotfile/eww/scripts/depthctl reload
```

---

## 5. Buka jendela dan cek posisinya

`depthctl` yang membuka jendela (bukan `eww open` polos), karena ia mengukur
output dan mengompensasi ruang yang dipesan bar:

```sh
~/.dotfile/eww/scripts/depthctl start
# depth clock: open on LVDS-1 (1366x580, top offset 34px)
```

Kenapa ada "top offset": layer surface ditempatkan di dalam *usable area*.
Dengan bar memesan 34 px di atas, jendela `y=0` mendarat di `y=34` dan seluruh
foreground bergeser 34 px dari wallpaper. `depthctl` membaca `reserved` dari
`hyprctl -j monitors` dan membuka dengan `--pos 0x-34` sehingga band mulai di
`y=0`.

Verifikasi:

```sh
hyprctl -j layers | jq -c '[.[] | .levels[][] | select(.namespace=="gtk-layer-shell") | {x,y,w,h}]'
# [{"x":0,"y":0,"w":1366,"h":580}]      <- y harus 0
hyprctl -j monitors | jq -c '[.[] | {name,reserved}]'
# [{"name":"LVDS-1","reserved":[0,34,0,0]}]   <- tidak bertambah
eww --force-wayland -c ~/.dotfile/eww get depth-clock-time   # harus sama dengan `date +%H:%M`
```

Ambil screenshot di workspace kosong:

```sh
grim -o LVDS-1 /tmp/depth.png
```

Yang harus terlihat: angka besar, subjek menutupi sebagian digit, latar
sepenuhnya transparan (wallpaper terlihat di sela), bar tetap di atas, tanpa
kotak gelap.

---

## 6. Verifikasi piksel (bukan cuma "kelihatan benar")

```sh
W=1366; H=768; X=441          # X = (1366 - lebar PNG) / 2
magick /tmp/depth.png -crop 484x580+$X+0 +repage live_fg.png
magick /tmp/depth.png -format "%[pixel:p{300,400}]\n" info:   # warna angka = token tema
```

Dipilih beberapa uji yang benar-benar membuktikan efeknya:

| Uji | Cara | Hasil yang diharapkan |
|---|---|---|
| warna dari tema | histogram area jam | persis `$primary-accent` (mis. `#8BA4B0`), bukan putih |
| latar transparan | bandingkan area jendela tanpa glyph dengan wallpaper | RMSE < 0,1% (hanya noise resampling) |
| subjek menutupi jam | `compare` live vs wallpaper di dalam area opaque PNG | `mean` ≈ 0 dan hampir nol piksel berwarna aksen |
| keselarasan | komposit PNG di offset `X` di atas wallpaper | `AE=0`, `RMSE=0` |
| jam hidup | `get depth-clock-time` vs `date +%H:%M` | sama; berubah pada menit berikutnya |
| aset statis | `stat` PNG sebelum/sesudah pergantian menit | mtime + ukuran tidak berubah |

---

## 7. Sambungkan ke ganti wallpaper dan ganti tema

Wallpaper (`hypr/sources/scripts/nextwall.sh`):

```sh
depth_sync() {
    [[ -x "$HOME/.dotfile/eww/scripts/depthctl" ]] || return 0
    "$HOME/.dotfile/eww/scripts/depthctl" wallpaper "$1" >/dev/null 2>&1 || true
}
# setelah awww img ... (dan pada mode "first")
depth_sync "$CHOSEN"
```

Perilakunya: wallpaper punya masker → jam tampil; tidak punya → jam ditutup,
jadi foreground lama tidak pernah tertinggal di atas wallpaper lain.

Tema (`matugen/config.toml` dan `matugen/templates/kanagawa-dragon-lotus/config.toml`,
keduanya pada `[templates.scss]`):

```toml
post_hook = "eww reload 2>/dev/null || true; ~/.dotfile/eww/scripts/depthctl refresh 2>/dev/null || true"
```

`eww reload` wajib karena CSS hanya dibaca ulang saat reload (file tema di
`~/.myenv` berada di luar config Eww). `depthctl refresh` memulihkan ukuran dan
offset jendela yang hilang setelah reload, dan tidak melakukan apa-apa kalau
jam sedang tertutup.

---

## 8. Perintah harian

```sh
~/.dotfile/eww/scripts/depthctl start|stop|toggle|reload|status
~/.dotfile/eww/scripts/depthctl generate     # bangun ulang foreground saja
~/.dotfile/eww/scripts/depthctl refresh      # reposisi setelah `eww reload`
~/.dotfile/eww/scripts/depthctl wallpaper "<gambar>"
```

---

## 9. Kalau ada yang salah

| Gejala | Penyebab | Perbaikan |
|---|---|---|
| Jam tidak muncul | wallpaper tanpa masker / salah nama berkas | cek `depthctl status`, samakan `basename` di `settings.conf` |
| Jam bergeser turun ±34 px dari subjek | offset bar tidak dipakai | pastikan dibuka lewat `depthctl start`, bukan `eww open` |
| Angka putih dan latar hitam | stylesheet ditolak GTK | cari non-ASCII di `.scss`; cek log `~/.cache/eww/eww_<hash>.log` |
| Angka tetap jam lama | listener tidak mencetak baris baru | uji perintahnya: `bash -c 'while :; do date +%H:%M; sleep 5; done'` |
| Foreground memotong rambut | toleransi terlalu tinggi | turunkan angka toleransi, `depthctl generate` lagi |
| Ada rim/kotak krem di tepi subjek | tidak ada erode / masker mentah dipakai | pastikan langkah `-morphology Erode Disk:1 -blur 0x0.8` dipakai |
| `[ERR] mask coverage ...` | warna latar salah atau latar tidak rata | ambil warna dari histogram; kalau latar bergradasi, wallpaper ini tidak cocok untuk keying otomatis |
| Bar hilang setelah utak-atik | bar punya daemon sendiri | `~/.dotfile/eww/bar/barctl start` |

---

## 10. Kenapa ringan

- ImageMagick jalan sekali per wallpaper+resolusi; hasilnya cache di
  `~/.cache/eww-depth-clock/foreground.png` (484×580, ±390 KB).
- Saat menit berganti hanya teks label yang berubah; wallpaper, PNG, dan awww
  tidak disentuh.
- Satu daemon Eww (yang sudah ada), satu listener `bash` + `sleep` per menit,
  tanpa polling detik.
- Terukur di mesin ini: RSS daemon +3 MiB saat jendela terbuka, CPU ≈0,07%
  selama 30 detik.
