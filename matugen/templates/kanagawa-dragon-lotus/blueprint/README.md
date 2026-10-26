# Blueprint JSON — `kanagawa-dragon-lotus`

> Indeks dokumen: [`matugen/docs/README.md`](../../../docs/README.md) · terkait: [`NVIM_MAPPING.md`](../../../docs/NVIM_MAPPING.md), [`MATUGEN_SKILLS.md`](../../../docs/MATUGEN_SKILLS.md)

Dokumen ini menjelaskan **isi `kanagawa-dark.json` dan `kanagawa-light.json`**: apa arti setiap key, nilainya dipakai untuk apa, dan di file mana nilainya mendarat. Ditulis supaya bisa dibaca tanpa hafal matugen.

---

## 1. Apa itu "blueprint"?

Blueprint = **palet warna yang ditulis tangan**, bukan hasil matugen. Ini kebalikannya dari alur wallpaper:

| | Alur wallpaper (`general`) | Blueprint (`kanagawa-dragon-lotus`) |
|---|---|---|
| Sumber warna | gambar wallpaper | JSON yang ditulis manusia |
| Yang menentukan warna | matugen (Material You) | kamu, di editor |
| Perintah | `matugen image <gambar> -c matugen/config.toml` | `matugen json <blueprint.json> -c .../config.toml` |
| Kosakata template | `{{ colors.<role>.default.hex }}` | `{{ accent.primary }}`, `{{ syntax.keyword }}`, dst. |
| Output | `~/.myenv/theme/generated/live.bak/<tool>/…` | `~/.myenv/theme/generated/kanagawa-dragon-lotus/<tool>/…` |

Karena warnanya sudah ditetapkan di sini, alur `matugen json …` cukup **mengirim** nilainya ke template, bukan menemukan warnanya.

---

## 2. Alur render

1. **Blueprint → matugen context:** `matugen json kanagawa-dark.json` memuat isi JSON ini ke dalam konteks render.
2. **Template → file keluaran:** setiap `[templates.<tool>]` di `config.toml` ini mengambil file template dan mengisi placeholder-nya.
3. **Post-hook:** bila ada, dijalankan setelah file tertulis (mis. `pkill -SIGUSR1 kitty`, `herdr server reload-config`). Foot tidak punya post-hook reload: foot tidak menyediakan sinyal reload, jadi warna barunya muncul di jendela foot berikutnya.
4. **Konsumen:** file yang dihasilkan lalu di-*include* oleh alat bersangkutan (atau disalin/disinlink oleh alur tema di pihak lain).

Catatan teknis penting:
- Template **tidak boleh** mengandalkan key yang tidak ada di blueprint. Jika sebuah key hilang, placeholder-nya tetap tertulis apa adanya atau render gagal — bukan warna default.
- Blueprint ini **tidak menyimpan** turunan `rgba()` atau alpha sendiri. Kalau template butuh alpha, hitungnya dilakukan di template (mis. `{{ effect.scrim | to_color | set_alpha: 0.45 | format: rgba }}`).
- Tool yang jalan dengan alur wallpaper (`general`) dan blueprint (`kanagawa-dragon-lotus`) **berbagi kosakata template yang sama**, tapi membaca dari blueprint yang berbeda.

---

## 3. Referensi key

### 3.1 `meta` — kartu identitas

| Key | Contoh (dark) | Arti | Dipakai di |
|---|---|---|---|
| `meta.name` | `kanagawa-dragon-lotus` | Nama tema; dipakai untuk nama folder output `~/.myenv/theme/generated/<name>/` | —ⁱ |
| `meta.variant` | `dark` / `light` | Varian berkas ini | —ⁱ |
| `meta.palette` | `rebelot/kanagawa.nvim#dragon` | Sumber palet | —ⁱ |
| `meta.origin` | `Kanagawa Dark Dragon GTK CSS + kanagawa.nvim palette` | Asal-usul nilai | —ⁱ |

ⁱ **Tidak ada template yang membacanya.** Ini metadata untuk manusia: penanda varian dan jejak asal warna. Aman diubah, tidak berpengaruh ke hasil render.

### 3.2 Akar: warna dasar terminal

| Key | Contoh (dark) | Arti | Dipakai di |
|---|---|---|---|
| `background` | `#181616` | Latar utama | `alacritty.toml`, `kitty.conf`, `nvim.lua`, `source.scss`, `foot.ini` |
| `foreground` | `#c5c9c5` | Teks utama | `alacritty.toml`, `kitty.conf`, `nvim.lua`, `source.scss`, `foot.ini`, `yazi-flavor.toml`, `yazi-tmtheme.xml` |
| `cursor` | `#C8C093` | Warna kursor terminal | `alacritty.toml`, `kitty.conf`, `nvim.lua` |

Tiga key ini sengaja diduplikasi di akar supaya template yang cuma butuh "latar dan teks" tidak perlu tahu soal `surface.*` / `text.*`.

### 3.3 `colors[]` dan `color0`–`color15` — palet ANSI

`colors` = array 16 warna **dalam urutan ANSI** (indeks 0 = hitam, 15 = putih terang). `color0`…`color15` adalah nilai yang sama, tapi diberi nama satu-satu.

| Indeks | Key | Warna | Dark | Light |
|---|---|---|---|---|
| 0 | `color0` | hitam | `#0d0c0c` | `#1f1f28` |
| 1 | `color1` | merah | `#c4746e` | `#c84053` |
| 2 | `color2` | hijau | `#8a9a7b` | `#6f894e` |
| 3 | `color3` | kuning | `#c4b28a` | `#77713f` |
| 4 | `color4` | biru | `#8ba4b0` | `#4d699b` |
| 5 | `color5` | magenta | `#a292a3` | `#b35b79` |
| 6 | `color6` | cyan | `#8ea4a2` | `#597b75` |
| 7 | `color7` | putih | `#C8C093` | `#545464` |
| 8 | `color8` | hitam terang | `#a6a69c` | `#8a8980` |
| 9 | `color9` | merah terang | `#E46876` | `#d7474b` |
| 10 | `color10` | hijau terang | `#87a987` | `#6e915f` |
| 11 | `color11` | kuning terang | `#E6C384` | `#836f4a` |
| 12 | `color12` | biru terang | `#7FB4CA` | `#6693bf` |
| 13 | `color13` | magenta terang | `#938AA9` | `#624c83` |
| 14 | `color14` | cyan terang | `#7AA89F` | `#5e857a` |
| 15 | `color15` | putih terang | `#c5c9c5` | `#43436c` |

- Dipakai di: `alacritty.toml`, `kitty.conf` & `source.scss` (16 key eksplisit), `nvim.lua` (lewat loop `<* for c in colors *>`), **`foot.ini`** (lewat `regular0`–`regular7` dan `bright0`–`bright7`).
- **Kenapa dobel?** Template berbasis loop butuh array; template yang menyebut slot satu per satu (alacritty) butuh nama key. Keduanya harus tetap sinkron.
- Array **tidak bisa diindeks** (`colors[0]` = error parse), hanya bisa di-loop. Karena itu `color0`…`color15` tetap ada.

### 3.4 `accent.*` — warna aksen & seleksi

| Key | Arti | Dipakai di |
|---|---|---|
| `accent.primary` | Aksen utama (fokus, tombol, border aktif) | semua template |
| `accent.secondary` | Aksen kedua | `alacritty.toml`, `gtk3.css`, `herdr.toml`, `source.scss`, `yazi-flavor.toml` |
| `accent.tertiary` | Aksen ketiga | `gtk3.css` |
| `accent.on_primary` | Teks **di atas** `accent.primary` | `alacritty.toml`, `gtk3.css`, `kitty.conf`, `lazygit.yml`, `nvim.lua`, `source.rasi`, `source.scss`, `yazi-flavor.toml` |
| `accent.on_secondary` | Teks di atas `accent.secondary` | `alacritty.toml`, `source.scss`, `yazi-flavor.toml` |
| `accent.on_tertiary` | Teks di atas `accent.tertiary` | `nvim.lua`, `yazi-flavor.toml` |
| `accent.primary_container` | Latar "berisi" aksen (badge, item terpilih) | `gtk3.css`, `nvim.lua` |
| `accent.on_primary_container` | Teks di atas `primary_container` | `gtk3.css`, `nvim.lua` |
| `accent.secondary_container` | Latar berisi aksen kedua | `nvim.lua` |
| `accent.on_secondary_container` | Teks di atasnya | `nvim.lua` |
| `accent.tertiary_container` | Latar berisi aksen ketiga | `nvim.lua` |
| `accent.on_tertiary_container` | Teks di atasnya | `nvim.lua` |

Pola `X` + `on_X` selalu berpasangan: `X` untuk latar, `on_X` untuk teks di atasnya. Ini yang menjaga kontras tetap terbaca.

### 3.5 `text.*` — teks & tautan

| Key | Arti | Dipakai di |
|---|---|---|
| `text.primary` | Teks utama | `gtk3.css`, `herdr.toml`, `kitty.conf`, `nvim.lua`, `source.rasi` |
| `text.secondary` | Teks kedua (judul, aksen teks) | `gtk3.css`, `herdr.toml`, `kitty.conf`, `nvim.lua`, `source.scss`, `yazi-flavor.toml` |
| `text.muted` | Teks redup | `gtk3.css`, `nvim.lua`, `source.scss`, `yazi-flavor.toml`, `yazi-tmtheme.xml` |
| `text.subtle` | Lebih redup lagi (→ `extra.fg.dim` nvim) | `gtk3.css`, `nvim.lua`, `source.scss` |
| `text.faint` | Paling redup (→ `extra.fg.dim_muted` nvim) | sama seperti `text.subtle` |
| `text.disabled` | Teks nonaktif | sama seperti `text.subtle` |
| `text.link` | Tautan | `gtk3.css`, `nvim.lua` |
| `text.visited` | Tautan sudah dikunjungi | `gtk3.css`, `nvim.lua`, `source.scss` |
| `text.on_inverse` | Teks di atas permukaan terbalik | —ⁱ |

### 3.6 `surface.*` — tangga ketinggian latar

| Key | Arti | Padanan umum | Dipakai di |
|---|---|---|---|
| `surface.lowest` | Paling bawah/gelap | `mantle` | `gtk3.css`, `nvim.lua`, `source.scss`, `yazi-flavor.toml` |
| `surface.low` | Satu tingkat di atasnya | `crust` | `gtk3.css`, `kitty.conf`, `nvim.lua`, `source.rasi`, `source.scss`, `yazi-flavor.toml` |
| `surface.base` | Latar utama (window) | `base` | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.rasi`, `source.scss`, `yazi-tmtheme.xml` |
| `surface.medium` | Panel | `surface` | `gtk3.css`, `herdr.toml`, `kitty.conf`, `lazygit.yml`, `nvim.lua`, `source.rasi`, `source.scss`, `yazi-tmtheme.xml` |
| `surface.high` | Panel menonjol / statusline | `surface_raised` | `gtk3.css`, `herdr.toml`, `kitty.conf`, `lazygit.yml`, `nvim.lua`, `source.scss`, `yazi-flavor.toml`, `yazi-tmtheme.xml` |
| `surface.highest` | Paling menonjol / gutter | `surface_overlay` | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss`, `yazi-flavor.toml` |
| `surface.track` | Jalur progres (disk usage) | — | `gtk3.css`, `nvim.lua`, `source.scss` |
| `surface.inverse` | Permukaan terbalik (tooltip) | — | —ⁱ |

### 3.7 `border.*`

| Key | Arti | Dipakai di |
|---|---|---|
| `border.default` | Garis/tepi biasa | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss` |
| `border.medium` | Garis pemisah (split) | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss`, `yazi-flavor.toml`, `yazi-tmtheme.xml` |
| `border.active` | Garis saat fokus | `gtk3.css`, `herdr.toml`, `kitty.conf`, `lazygit.yml`, `nvim.lua`, `source.rasi`, `source.scss` |

### 3.8 `status.*`

| Key | Arti | Dipakai di |
|---|---|---|
| `status.info` | Informasi | `gtk3.css`, `nvim.lua`, `source.scss` |
| `status.success` | Sukses (git add, dsb.) | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `status.warning` | Peringatan | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss`, `yazi-flavor.toml` |
| `status.error` | Galat | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss`, `yazi-flavor.toml` |
| `status.critical` | Galat berat | `gtk3.css`, `nvim.lua`, `source.scss` |
| `status.warning_container` | Latar peringatan | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `status.error_container` | Latar galat | —ⁱ |

### 3.9 `effect.*`

| Key | Contoh | Arti | Dipakai di |
|---|---|---|---|
| `effect.shadow` | `#0d0c0c` | Warna bayangan jendela/menu | —ⁱ |
| `effect.scrim` | `#0d0c0c` | Lapisan gelap di belakang dialog | `source.rasi` (`bg-transparent-col`, alpha 0.45) |

`effect.shadow` masih disediakan untuk tool yang butuh (mis. compositor/hyprlock bila nanti ditambahkan). `effect.scrim` dipakai oleh picker wallpaper rofi (`wallpaper.rasi`) sebagai lapisan gelap layar penuh.

### 3.10 `syntax.*` — kosakata kode (27 token)

Nama token sengaja **universal** (bukan nama plugin) supaya semua tool memetakan dari kosakata yang sama. Semua 27 key di bawah dipakai oleh `nvim.lua`; `herdr.toml` membaca `string` & `type`, `lazygit.yml` membaca `keyword`, dan `yazi-tmtheme.xml` membaca 26 key (semua kecuali `statement`).

| Kelompok | Key |
|---|---|
| Komentar | `comment` |
| Kata kunci & alur | `keyword`, `statement`, `return`, `import`, `decorator` |
| Fungsi | `function`, `method`, `builtin` |
| Literal | `string`, `number`, `boolean`, `constant`, `regex` |
| Tipe & nama | `type`, `class`, `variable`, `parameter`, `property`, `identifier` |
| Lain-lain | `operator`, `punctuation`, `special`, `exception`, `builtin_variable`, `tag`, `attribute` |

Contoh nilai (dark): `comment` `#625E5A` (redup), `keyword` `#938AA9` (ungu), `function` `#7FB4CA` (biru), `string` `#87A987` (hijau), `constant` `#E6C384` (kuning).

> Di `template/nvim.lua`, key yang namanya bentrok dengan kata kunci Lua harus ditulis berkurung: `["function"]` dan `["return"]`. Di JSON tidak perlu apa-apa — JSON tidak punya kata kunci.

---

## 4. Tabel "pekerjaan UI → key mana"

| Yang mau diwarnai | Key |
|---|---|
| Latar jendela/editor | `background` / `surface.base` |
| Teks utama | `foreground` / `text.primary` |
| Teks redup (komentar, hint) | `text.muted` / `text.subtle` / `text.faint` |
| Item terpilih / badge | `accent.primary_container` + `accent.on_primary_container` |
| Aksen fokus / border aktif | `accent.primary` / `border.active` |
| Garis pemisah panel | `border.medium` |
| Status git/sistem | `status.success`, `status.warning`, `status.error` |
| Bar progres | `surface.track` + `accent.primary` |
| Kode: kata kunci / string / fungsi | `syntax.keyword`, `syntax.string`, `syntax.function` |
| Palet terminal mentah | `color0` … `color15` |
| Bayangan & backdrop dialog | `effect.shadow`, `effect.scrim` |

Tabel ini tidak lengkap untuk semua tool (ada tool yang memakai kombinasi sendiri), tapi mewakili pola umum yang konsisten di blueprint ini.

---

## 5. Aturan & jebakan

1. **Satu berkas satu varian.** Kalau mengubah dark, tanyakan apakah light ikut berubah — dua berkas ini tidak saling menyinkron otomatis.
2. **Jangan mengubah nama key** tanpa mengubah template; key yang hilang membuat placeholder tidak terisi (atau render gagal), bukan sekadar warna default.
3. **Sinkronkan `colors[]` dengan `color0`…`color15`.** Kalau salah satu berubah, ubah yang lain juga. Cara termudah: ubah `colors[]`, lalu salin ulang ke `color0`…`color15` berurutan.
4. **Alpha / `rgba()` tidak boleh jadi sisa di blueprint.** Canvas render matugen pada template, bukan pada JSON ini.
5. **Portabilitas key masih terbatas.** `colors.surface.default.hex` adalah bentuk yang dipakai alur wallpaper (`general`). Blueprint ini **tidak punya** bentuk grouping itu — gunakan `surface.base`, `text.primary`, dst. secara langsung.
6. **Key yang belum dipakai bukan sampah.** `effect.shadow`, `surface.inverse`, `text.on_inverse`, `status.error_container`, dan `meta.*` adalah slot siap pakai untuk template berikutnya.
7. **Menambah tool baru:** buat `template/<tool>.<ext>` lalu daftarkan di `config.toml` folder ini:
   ```toml
   [config]

   [templates.tool]
   input_path  = "~/.dotfile/matugen/templates/kanagawa-dragon-lotus/template/tool.conf"
   output_path = "~/.myenv/theme/generated/kanagawa-dragon-lotus/tool/theme.conf"
   ```
   Config matugen **wajib** diawali `[config]`. Selalu uji ke `/tmp` dulu (bagian 2), baru render ke jalur sebenarnya.
8. **Kontras tetap tanggung jawabmu.** Blueprint tidak mengoreksi kontras; pastikan pasangan `X` / `on_X` benar-benar terbaca.

---

## 6. Checklist sebelum menyimpan perubahan

- [ ] `dark` dan `light` sama-sama valid JSON (`python3 -m json.tool`).
- [ ] `colors[]` ↔ `color0…color15` sinkron.
- [ ] Render uji ke `/tmp` untuk **setiap** template di `template/`.
- [ ] Tidak ada sisa `{{ }}`, `<* *>` di hasil render.
- [ ] `luac -p` untuk template Lua.
- [ ] Baru setelah itu: render ke `~/.myenv/theme/generated/kanagawa-dragon-lotus/`.

---

## 7. Catatan khusus Foot

Foot memuat hasil blueprint lewat `include`, pola yang sama dengan `kitty/kitty.conf` (`include ~/.myenv/theme/current/kitty/theme.conf`).
Jalurnya:

- Blueprint `kanagawa-dark.json`
- → template `template/foot.ini`
- → output `generated/kanagawa-dragon-lotus/foot/theme.ini`
- → dibaca lewat tema aktif: `~/.myenv/theme/current/foot/theme.ini`
- → pemuat repo: `foot/foot.ini` (`include=.../current/foot/theme.ini`)

Alur wallpaper punya pasangan yang sama: `general/foot.ini` → `generated/live.bak/foot/theme.ini`. Karena pemuatnya menunjuk ke `current`, foot ikut tema yang sedang aktif, bukan terpaku pada folder kanagawa.

Pola render Foot sederhana:
- `foreground`, `background` → `[colors]` utama.
- `color0`…`color7` → `regular0`…`regular7`.
- `color8`…`color15` → `bright0`…`bright7`.

Format yang sudah diverifikasi pada foot 1.22.3 (`foot --check-config -c ~/.dotfile/foot/foot.ini` → exit 0): section `[colors]` (bukan `[colors-dark]`/`[colors-light]`) dan nilai `RRGGBB` tanpa `#` (`hex_stripped`) diterima apa adanya.

Foot tidak punya sinyal reload: jangan memberi post-hook `pkill -SIGUSR1 foot` — SIGUSR1 tidak ditangani foot, jadi prosesnya berhenti, bukan me-reload. Warna baru muncul di jendela foot berikutnya.

Jangan menambah layout `[group]` atau key non-standar ke template Foot; Foot memuat ini sebagai konfigurasi `foot.ini`, jadi strukturnya harus tetap merupakan file `foot.ini` yang sah.

Blueprint `cursor` belum dipakai template Foot: foot menyimpan warna kursor di section `[cursor]` (`[cursor] color=fg bg`), bukan di `[colors]`. Kalau nanti dipetakan, tempatnya di template Foot, bukan di blueprint secara langsung — kecuali template memang memetakannya sendiri.

---

## 8. Cara membaca tabel warna di sini

Nilai di tabel di atas adalah **contoh**, bukan rumus. Pada dasarnya:
- Dark dan light punya nilai berbeda untuk key yang sama.
- Nomor indeks `color0`…`color15` **harus** sesuai dengan urutan ANSI.
- Warna di tabel tidak menjamin kontras; lihat aturan & jebakan di bagian 5.

Jika kamu ragu apakah sebuah key masih dipakai, cari nama key-nya di `template/` yang bersangkutan. Kalau tidak ada di template mana pun, berarti belum dipakai — dan aman untuk dipertahankan sebagai slot masa depan.
