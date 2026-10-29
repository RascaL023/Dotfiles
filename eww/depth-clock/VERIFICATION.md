# Hasil verifikasi — depth clock

Sesi: 29 Oktober 2026. Hyprland 0.56.2 (config Lua), Eww 0.6.0, awww 0.12.1,
ImageMagick 7, matugen 4.2.0. Output terfokus `LVDS-1` 1366×768, skala 1, bar
Eww aktif dengan area eksklusif 34 px. Tema aktif: `kanagawa-dragon-lotus`
(Flow B).

## Yang dijalankan

| # | Pemeriksaan | Hasil |
|---|---|---|
| 1 | `bash -n eww/scripts/depthctl`, `bash -n hypr/sources/scripts/nextwall.sh` | lolos |
| 2 | `eww reload` pada config utama; log Eww | config termuat, tidak ada error Yuck/SCSS/CSS |
| 3 | Jendela: `hyprctl -j layers` | level 0 (background), `x=0 y=0 1366×580` |
| 4 | Ruang eksklusif: `hyprctl -j monitors` | `reserved [0,34,0,0]` tetap milik bar; depth clock menambah 0 |
| 5 | Jam = waktu lokal: `eww get depth-clock-time` vs `date +%H:%M` | `18:14` = `18:14` |
| 6 | Jam berubah pada batas menit | `18:04` → `18:05` dalam 65 detik, tanpa interaksi |
| 7 | Foreground tidak dibuat ulang saat jam berubah | mtime + ukuran `foreground.png` identik, `awww query` identik |
| 8 | Aset foreground | 484×580 px, 395.551 byte, RGBA, pojok transparan, cakupan masker ±19% |
| 9 | Keselarasan piksel dengan wallpaper | komposit PNG di offset hasil hitungan vs wallpaper: `AE=0`, `RMSE=0` (1366×768 dan 1920×1080); setelah font/band baru, di dalam subjek opaque `mean=2,6e-05` |
| 10 | `stop` / `toggle` / `start` | jendela tertutup/terbuka; daemon Eww dan bar (`islands`) tetap hidup |
| 11 | Ganti wallpaper: bermasker vs tidak | `wallpaper "Nyx Bright.png"` → tampil; `wallpaper "Kitty Dark.png"` → tersembunyi, exit 0 |
| 12 | Flow A (wallpaper) dan Flow B (palet tetap) | Flow B aktif di daemon utama; config uji terpisah yang mengimpor `live.bak/scss/theme` + `styles/_depth-clock` terbuka tanpa error → token kedua flow cocok |
| 13 | Perilaku pointer (rekaman `WAYLAND_DEBUG=1`) | `get_layer_surface(layer=0)`, `set_keyboard_interactivity(0)`, `set_exclusive_zone(0)`, `set_input_region(nil)` |
| 14 | Overhead | daemon Eww: 60.412 KiB (tertutup) → 63.508 KiB (terbuka), +3 MiB; 2 tick CPU / 30 detik ≈ 0,07%; satu child proses (`bash` + `sleep` pencetak jam) |
| 15 | Niri | **tidak diuji** — sesi Niri tidak tersedia di mesin ini; jalur deteksi memakai `niri msg -j outputs` dan offset bar 0 |

## Pemeriksaan visual (screenshot langsung)

Diambil dengan `grim -o LVDS-1` pada workspace kosong, setelah sesi dibuka.
Jam menampilkan `18:38`, sama dengan `date +%H:%M` pada saat capture.

| # | Pemeriksaan | Hasil |
|---|---|---|
| 16 | Warna angka | histogram area jam: `#8BA4B0` persis — sama dengan `$primary-accent` tema aktif, bukan putih/hex hardcoded |
| 17 | Latar transparan | area dalam jendela tanpa glyph identik dengan wallpaper: RMSE 0,019% (x 0–190), 0,021% (x 1196–1366), 0,1% (y 500–570); selisih hanya noise resampling awww vs ImageMagick, tanpa panel/tint |
| 18 | Subjek menutupi jam | di dalam area opaque foreground, selisih live vs wallpaper `mean=2,7e-05` dan piksel berwarna aksen hanya 0,06%; titik di wajah/rambut sama persis dengan wallpaper walau digit lewat di belakangnya |
| 19 | Bayangan | piksel 10–12 px di bawah digit lebih gelap dari wallpaper (232,228,210 vs 240,235,217) — `text-shadow` `$layer-lowest` 55% ter-render |
| 20 | Bar di atas jam | bar tetap terlihat di baris 0–34 (`(57,56,50)` di y=20) dan tidak tertutup jendela depth clock |
| 21 | Jendela aplikasi di atas efek | `foot` selebar layar di workspace yang sama menutupi seluruh area jam; piksel (240,200) dan (1120,300) menjadi latar terminal (24,22,22), angka tidak terlihat |
| 22 | Kecocokan dengan acuan `~/Downloads/Wallpaper-Depth-Example.webp` | font display serif Noto Serif Display, lebar jam ±70% layar (acuan 69%), tepi atas ±23% tinggi layar (acuan 23,5%), bayangan offset di bawah-kanan; komposisi berdampingan diperiksa manual |

Screenshot: `/tmp/depth/final.png` (desktop, versi font serif), `/tmp/depth/live2.png`
(versi yang sama sebelum toggle), dan `/tmp/depth/above.png` (jendela aplikasi di
atas jam). Semua file sementara, bukan aset repo.

## Tidak dapat dijalankan

- **Click-through pointer dengan input asli.** Tidak ada alat injeksi pointer
  (`ydotool`, `wlrctl`) di mesin ini. Kesimpulan pada #13 berasal dari rekaman
  protokol: region input tidak dibentuk, jadi persegi jendela menerima pointer.

## Temuan selama implementasi

- **Offset bar 34 px.** Hyprland menempatkan layer surface di dalam *usable
  area*: dengan bar memesan 34 px, jendela `y=0` mendarat di `y=34` dan seluruh
  foreground bergeser 34 px dari wallpaper. `depthctl` kini membaca
  `reserved[1]` dan membuka dengan `--pos 0x-<reserved>`; `hyprctl -j layers`
  melaporkan `y=0` dan uji keselarasan (#9) lolos. Tanpa kompensasi ini,
  kesalahan baru terlihat saat bar aktif.
- **SCSS non-ASCII.** Satu em dash di komentar `.scss` membuat libsass
  menambahkan `@charset "UTF-8";`, yang ditolak GTK (`error: unknown @ rule`)
  dan menggagalkan seluruh stylesheet. Semua komentar SCSS sekarang ASCII.
- **`eww reload` membuka ulang jendela dari geometri Yuck**, sehingga ukuran
  dan offset dari `depthctl` hilang. `depthctl refresh` memulihkannya dan
  dipanggil otomatis oleh hook `[templates.scss]` di kedua flow Matugen.
- **Tinggi jendela mengikuti minimum label** (line box 520 px untuk font
  380 px + 49 px padding), jadi `DEPTH_BAND_HEIGHT` disetel ke 580 agar
  foreground menutupi seluruh line box, bukan hanya glyph.
- **Bintik kertas berskala.** Filter luas komponen dihitung dalam piksel
  wallpaper asli lalu diskala ke output; tanpa itu, pada 1920×1080 satu bintik
  kecil ikut lolos dan kanvas foreground melebar ke seluruh layar.
- **Sesi terkunci sempat memblokir verifikasi visual.** `hyprlock` menutupi
  semua layer (termasuk output headless yang dibuat untuk isolasi), jadi tiga
  percobaan capture pertama hanya menangkap layar kunci. Pemeriksaan #16–#21
  baru bisa dijalankan setelah sesi dibuka.
- **Komposisi.** Kepala subjek (x 441–925) mencakup ±50% lebar jam, jadi titik
dua tertutup rambut dan sebagian digit tengah ikut hilang. Ini efek yang
diinginkan (acuan juga menutupi sebagian digit), tetapi pada wallpaper ini
pemisah `:` tidak terlihat; kalau ingin titik dua tetap terbaca, geser jam
secara horizontal atau pilih wallpaper dengan subjek di tepi. Parameter ada di
`styles/_depth-clock.scss` dan README.
- **Font.** Acuan memakai serif display kontras tinggi; implementasi memakai
  Noto Serif Display (regular) yang tersedia di sistem. Roboto Thin sempat
  dipakai lebih dulu, tetapi bentuknya jauh dari acuan.
