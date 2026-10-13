# Blueprint JSON — `kanagawa-dragon-lotus`

> Indeks dokumen: [`matugen/docs/README.md`](../../../docs/README.md) ·
> terkait: [`NVIM_MAPPING.md`](../../../docs/NVIM_MAPPING.md),
> [`MATUGEN_SKILLS.md`](../../../docs/MATUGEN_SKILLS.md)

Dokumen ini menjelaskan **isi `kanagawa-dark.json` dan `kanagawa-light.json`**:
apa arti setiap key, nilainya dipakai untuk apa, dan di file mana nilainya
mendarat. Ditulis supaya bisa dibaca tanpa hafal matugen.

---

## 1. Apa itu "blueprint"?

Blueprint = **palet warna yang ditulis tangan**, bukan hasil matugen. Ini
kebalikannya dari alur wallpaper:

| | Alur wallpaper (`general`) | Blueprint (`kanagawa-dragon-lotus`) |
|---|---|---|
| Sumber warna | gambar wallpaper | JSON yang ditulis manusia |
| Warna ditentukan oleh | matugen (Material You) | kamu, di editor |
| Perintah | `matugen image <gambar> -c matugen/config.toml` | `matugen json <blueprint.json> -c .../config.toml` |
| Kosakata template | `{{ colors.<role>.default.hex }}` | `{{ accent.primary }}`, `{{ syntax.keyword }}`, dst. |
| Output | `~/.myenv/theme/generated/live.bak/<tool>/…` | `~/.myenv/theme/generated/kanagawa-dragon-lotus/<tool>/…` |

Karena warnanya sudah pasti, blueprint dipakai untuk tema **bernama** yang tidak
mau berubah-ubah tiap ganti wallpaper (di sini: Kanagawa).

### Dua berkas = dua varian

| Berkas | `meta.variant` | Palet asal |
|---|---|---|
| `kanagawa-dark.json` | `dark` | Kanagawa **Dragon** |
| `kanagawa-light.json` | `light` | Kanagawa **Lotus** |

Berbeda dari palet lama yang menaruh `dark` **dan** `light` dalam satu berkas,
sekarang **satu berkas = satu varian**. Template tidak memilih varian; kamu
memilihnya di perintah render (mana JSON yang dikasih).

---

## 2. Alur render

```
blueprint/kanagawa-dark.json
        │  (matugen json …)
        ▼
template/nvim.lua          ← "{{ accent.primary }}"  →  "#8ba4b0"
template/alacritty.toml
template/gtk3.css
template/herdr.toml
template/lazygit.yml
template/source.scss
        │
        ▼
~/.myenv/theme/generated/kanagawa-dragon-lotus/<tool>/…
        │  (theme-switcher.sh — di luar repo ini)
        ▼
~/.myenv/theme/current  →  dipakai semua aplikasi
```

Isi JSON di-ekspos matugen **di akar data template**. Jadi `{{ accent.primary }}`
membaca key `accent.primary` dari JSON ini secara langsung — tanpa lapisan
`colors.<role>.<scheme>` seperti alur wallpaper.

### Perintah

```bash
# render tema penuh (output ke ~/.myenv/theme/generated/…)
matugen json ~/.dotfile/matugen/templates/kanagawa-dragon-lotus/blueprint/kanagawa-dark.json \
  -c ~/.dotfile/matugen/templates/kanagawa-dragon-lotus/config.toml

# varian terang
matugen json ~/.dotfile/matugen/templates/kanagawa-dragon-lotus/blueprint/kanagawa-light.json \
  -c ~/.dotfile/matugen/templates/kanagawa-dragon-lotus/config.toml
```

⚠️ **Jangan** tambahkan template blueprint ini ke `matugen/config.toml`
(config wallpaper). Setiap `matugen image` akan gagal karena `accent.*` /
`syntax.*` tidak ada di palet Material You.

### Uji dulu tanpa menyentuh `~/.myenv`

```bash
mkdir -p /tmp/bpcheck/out
cat > /tmp/bpcheck/config.toml <<EOF
[config]

[templates.t]
input_path  = "$HOME/.dotfile/matugen/templates/kanagawa-dragon-lotus/template/nvim.lua"
output_path = "/tmp/bpcheck/out/theme.lua"
EOF

matugen json "$HOME/.dotfile/matugen/templates/kanagawa-dragon-lotus/blueprint/kanagawa-dark.json" \
  -c /tmp/bpcheck/config.toml
grep -nE '\{\{|\}\}|<\*|\*>' /tmp/bpcheck/out/theme.lua   # harus tidak mencetak apa pun
luac -p /tmp/bpcheck/out/theme.lua                         # template Lua harus lolos parse
```

---

## 3. Referensi key

Kolom **Dipakai di** = template di `template/` yang membaca key tersebut
(diverifikasi dengan menyalin daftar placeholder semua template).

### 3.1 `meta` — kartu identitas

| Key | Contoh (dark) | Arti | Dipakai di |
|---|---|---|---|
| `meta.name` | `kanagawa-dragon-lotus` | Nama tema; dipakai untuk nama folder output `~/.myenv/theme/generated/<name>/` | —ⁱ |
| `meta.variant` | `dark` / `light` | Varian berkas ini | —ⁱ |
| `meta.palette` | `rebelot/kanagawa.nvim#dragon` | Sumber palet | —ⁱ |
| `meta.origin` | `Kanagawa Dark Dragon GTK CSS + kanagawa.nvim palette` | Asal-usul nilai | —ⁱ |

ⁱ **Tidak ada template yang membacanya.** Ini metadata untuk manusia: penanda
varian dan jejak asal warna. Aman diubah, tidak berpengaruh ke hasil render.

### 3.2 Akar: warna dasar terminal

| Key | Contoh (dark) | Arti | Dipakai di |
|---|---|---|---|
| `background` | `#181616` | Latar utama | `alacritty.toml`, `source.scss`, `nvim.lua` |
| `foreground` | `#c5c9c5` | Teks utama | sama seperti `background` |
| `cursor` | `#C8C093` | Warna kursor terminal | `alacritty.toml`, `nvim.lua` |

Tiga key ini sengaja diduplikasi di akar supaya template yang cuma butuh "latar
dan teks" tidak perlu tahu soal `surface.*` / `text.*`.

### 3.3 `colors[]` dan `color0`–`color15` — palet ANSI

`colors` = array 16 warna **dalam urutan ANSI** (indeks 0 = hitam, 15 = putih
terang). `color0`…`color15` adalah nilai yang sama, tapi diberi nama satu-satu.

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

- Dipakai di: `alacritty.toml` & `source.scss` (16 key eksplisit), `nvim.lua`
  (lewat loop `<* for c in colors *>`).
- **Kenapa dobel?** Template berbasis loop butuh array; template yang menyebut
  slot satu per satu (alacritty) butuh nama key. Keduanya harus tetap sinkron.
- Array **tidak bisa diindeks** (`colors[0]` = error parse), hanya bisa
  di-loop. Karena itu `color0`…`color15` tetap ada.

### 3.4 `accent.*` — warna aksen & seleksi

| Key | Arti | Dipakai di |
|---|---|---|
| `accent.primary` | Aksen utama (fokus, tombol, border aktif) | semua template |
| `accent.secondary` | Aksen kedua | `alacritty.toml`, `gtk3.css`, `herdr.toml`, `source.scss` |
| `accent.tertiary` | Aksen ketiga | `gtk3.css` |
| `accent.on_primary` | Teks **di atas** `accent.primary` | `alacritty.toml`, `gtk3.css`, `lazygit.yml`, `nvim.lua`, `source.scss` |
| `accent.on_secondary` | Teks di atas `accent.secondary` | `alacritty.toml`, `source.scss` |
| `accent.on_tertiary` | Teks di atas `accent.tertiary` | `nvim.lua` |
| `accent.primary_container` | Latar "berisi" aksen (badge, item terpilih) | `gtk3.css`, `nvim.lua` |
| `accent.on_primary_container` | Teks di atas `primary_container` | `gtk3.css`, `nvim.lua` |
| `accent.secondary_container` | Latar berisi aksen kedua | `nvim.lua` |
| `accent.on_secondary_container` | Teks di atasnya | `nvim.lua` |
| `accent.tertiary_container` | Latar berisi aksen ketiga | `nvim.lua` |
| `accent.on_tertiary_container` | Teks di atasnya | `nvim.lua` |

Pola `X` + `on_X` selalu berpasangan: `X` untuk latar, `on_X` untuk teks di
atasnya. Ini yang menjaga kontras tetap terbaca.

### 3.5 `text.*` — teks & tautan

| Key | Arti | Dipakai di |
|---|---|---|
| `text.primary` | Teks utama | `gtk3.css`, `herdr.toml`, `nvim.lua` |
| `text.secondary` | Teks kedua (judul, aksen teks) | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `text.muted` | Teks redup | `gtk3.css`, `nvim.lua`, `source.scss` |
| `text.subtle` | Lebih redup lagi (→ `extra.fg.dim` nvim) | `gtk3.css`, `nvim.lua`, `source.scss` |
| `text.faint` | Paling redup (→ `extra.fg.dim_muted` nvim) | sama seperti `text.subtle` |
| `text.disabled` | Teks nonaktif | sama seperti `text.subtle` |
| `text.link` | Tautan | `gtk3.css`, `nvim.lua` |
| `text.visited` | Tautan sudah dikunjungi | `gtk3.css`, `nvim.lua`, `source.scss` |
| `text.on_inverse` | Teks di atas permukaan terbalik | —ⁱ |

### 3.6 `surface.*` — tangga ketinggian latar

| Key | Arti | Padanan umum | Dipakai di |
|---|---|---|---|
| `surface.lowest` | Paling bawah/gelap | `mantle` | `gtk3.css`, `nvim.lua`, `source.scss` |
| `surface.low` | Satu tingkat di atasnya | `crust` | `gtk3.css`, `nvim.lua`, `source.scss` |
| `surface.base` | Latar utama (window) | `base` | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `surface.medium` | Panel | `surface` | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss` |
| `surface.high` | Panel menonjol / statusline | `surface_raised` | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss` |
| `surface.highest` | Paling menonjol / gutter | `surface_overlay` | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `surface.track` | Jalur progres (disk usage) | — | `gtk3.css`, `nvim.lua`, `source.scss` |
| `surface.inverse` | Permukaan terbalik (tooltip) | — | —ⁱ |

### 3.7 `border.*`

| Key | Arti | Dipakai di |
|---|---|---|
| `border.default` | Garis/tepi biasa | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss` |
| `border.medium` | Garis pemisah (split) | sama seperti `border.default` |
| `border.active` | Garis saat fokus | sama seperti `border.default` |

### 3.8 `status.*`

| Key | Arti | Dipakai di |
|---|---|---|
| `status.info` | Informasi | `gtk3.css`, `nvim.lua`, `source.scss` |
| `status.success` | Sukses (git add, dsb.) | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `status.warning` | Peringatan | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `status.error` | Galat | `gtk3.css`, `herdr.toml`, `lazygit.yml`, `nvim.lua`, `source.scss` |
| `status.critical` | Galat berat | `gtk3.css`, `nvim.lua`, `source.scss` |
| `status.warning_container` | Latar peringatan | `gtk3.css`, `herdr.toml`, `nvim.lua`, `source.scss` |
| `status.error_container` | Latar galat | —ⁱ |

### 3.9 `effect.*`

| Key | Contoh | Arti | Dipakai di |
|---|---|---|---|
| `effect.shadow` | `#0d0c0c` | Warna bayangan jendela/menu | —ⁱ |
| `effect.scrim` | `#0d0c0c` | Lapisan gelap di belakang dialog | —ⁱ |

Disediakan untuk tool yang butuh (mis. compositor/hyprlock bila nanti
ditambahkan). Belum ada template yang memakainya.

### 3.10 `syntax.*` — kosakata kode (27 token)

Nama token sengaja **universal** (bukan nama plugin) supaya semua tool
memetakan dari kosakata yang sama. Semua 27 key di bawah dipakai oleh
`nvim.lua`; `herdr.toml` membaca `string` & `type`, sementara `lazygit.yml`
membaca `keyword`.

| Kelompok | Key |
|---|---|
| Komentar | `comment` |
| Kata kunci & alur | `keyword`, `statement`, `return`, `import`, `decorator` |
| Fungsi | `function`, `method`, `builtin` |
| Literal | `string`, `number`, `boolean`, `constant`, `regex` |
| Tipe & nama | `type`, `class`, `variable`, `parameter`, `property`, `identifier` |
| Lain-lain | `operator`, `punctuation`, `special`, `exception`, `builtin_variable`, `tag`, `attribute` |

Contoh nilai (dark): `comment` `#625E5A` (redup), `keyword` `#938AA9` (ungu),
`function` `#7FB4CA` (biru), `string` `#87A987` (hijau), `constant` `#E6C384`
(kuning).

> Di `template/nvim.lua`, key yang namanya bentrok dengan kata kunci Lua harus
> ditulis berkurung: `["function"]` dan `["return"]`. Di JSON tidak perlu apa-apa
> — JSON tidak punya kata kunci.

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

---

## 5. Aturan & jebakan

1. **Satu berkas satu varian.** Kalau mengubah dark, tanyakan apakah light ikut
   berubah — dua berkas ini tidak saling menyinkron otomatis.
2. **Jangan mengubah nama key** tanpa mengubah template; key yang hilang membuat
   placeholder tidak terisi (atau render gagal), bukan sekadar warna default.
3. **`colors[]` dan `color0`…`color15` harus sama isinya.** `alacritty.toml` dan
   `source.scss` membaca yang bernama; `nvim.lua` membaca array-nya.
4. **Kapitalisasi hex tidak konsisten** di berkas ini (`#c5c9c5` vs `#C8C093`) —
   tidak berpengaruh ke hasil render (nilai diteruskan apa adanya), tapi jangan
   jadikan pembanding string.
5. **Nilai = string hex polos.** Semua turunan (alpha, dipermudah/digelapkan)
   dikerjakan template lewat filter matugen, mis.
   `{{ accent.primary | to_color | set_alpha: 0.2 | format: rgba }}` di
   `gtk3.css`. Blueprint tidak menyimpan `rgba()` sendiri.
6. **Key yang belum dipakai bukan sampah.** `effect.*`, `surface.inverse`,
   `text.on_inverse`, `status.error_container`, dan `meta.*` adalah slot siap
   pakai untuk template berikutnya.
7. **Menambah tool baru:** buat `template/<tool>.<ext>` lalu daftarkan di
   `config.toml` folder ini:
   ```toml
   [config]

   [templates.tool]
   input_path  = "~/.dotfile/matugen/templates/kanagawa-dragon-lotus/template/tool.conf"
   output_path = "~/.myenv/theme/generated/kanagawa-dragon-lotus/tool/theme.conf"
   ```
   Config matugen **wajib** diawali `[config]`. Selalu uji ke `/tmp` dulu
   (bagian 2), baru render ke jalur sebenarnya.
8. **Kontras tetap tanggung jawabmu.** Blueprint tidak mengoreksi kontras;
   pastikan pasangan `X` / `on_X` benar-benar terbaca.

---

## 6. Checklist sebelum menyimpan perubahan

- [ ] `dark` dan `light` sama-sama valid JSON (`python3 -m json.tool`).
- [ ] `colors[]` ↔ `color0…color15` sinkron.
- [ ] Render uji ke `/tmp` untuk **setiap** template di `template/`.
- [ ] Tidak ada sisa `{{ }}`, `<* *>` di hasil render.
- [ ] `luac -p` untuk template Lua.
- [ ] Baru setelah itu: render ke `~/.myenv/theme/generated/kanagawa-dragon-lotus/`.
