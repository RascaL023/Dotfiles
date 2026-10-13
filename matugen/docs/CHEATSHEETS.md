# Matugen Color Mapping Cheat Sheet

> Pegangan praktis untuk memahami **arti semantic color Matugen** dan memilih warna yang cocok untuk aplikasi seperti Alacritty, Neovim, Waybar, Kitty, dll.
> Fokus dokumen ini: **memetakan peran UI → semantic color Matugen**, bukan menghafalkan semua hex.
>
> Indeks dokumen: [`README.md`](README.md) · daftar nilai mentah:
> [`VOCABULARY.md`](VOCABULARY.md) · contoh pemakaian di repo:
> [`../templates/general/`](../templates/general/).
>
> **Cakupan:** dokumen ini hanya berlaku untuk alur **wallpaper → Material You**
> (`matugen image`). Tema berpalet tetap tidak memakai nama role di sini;
> kosakatanya ada di
> [`../templates/kanagawa-dragon-lotus/blueprint/README.md`](../templates/kanagawa-dragon-lotus/blueprint/README.md).

---

## 1. Mental Model Utama

Jangan menganggap output Matugen sebagai:

```text
red / green / blue / purple / gray
```

Anggap sebagai **kosakata semantik UI**:

```text
source_color
    ↓
Matugen color generation
    ↓
semantic roles
    ↓
application template
    ↓
actual UI color
```

Contoh:

```text
Matugen:
    primary = warna aksen utama

Alacritty:
    ANSI blue = primary

Neovim/TokyoNight:
    Function = c.blue
```

Jadi **Matugen menentukan peran**, sedangkan template aplikasi menentukan **bagaimana peran tersebut dipetakan ke aplikasi**.

---

## 2. Cara Membaca Syntax Template

Syntax warna Matugen saat ini:

```text
{{ colors.<color>.<scheme>.<format> }}
```

Contoh:

```toml
background = "{{ colors.surface.default.hex }}"
```

Artinya:

```text
colors
  └── surface       → semantic role
      └── default   → scheme
          └── hex   → format output
```

Format umum:

```text
hex   → #RRGGBB
rgb   → rgb(...)
rgba  → rgba(...)
hsl   → hsl(...)
hsla  → hsla(...)
strip → RRGGBB tanpa '#'
```

Matugen juga mendukung scheme eksplisit seperti:

```text
{{ colors.primary.dark.hex }}
{{ colors.primary.light.hex }}
```

Untuk template yang harus selalu mengikuti mode tertentu, gunakan scheme eksplisit daripada mengandalkan `default`.

> Catatan: `default` adalah **nama scheme**, bukan arti "nilai default". Jangan membaca `default` sebagai "warna bawaan yang paling dasar".

---

## 3. Kelompok Warna Utama

### `primary`

**Peran:** aksen utama / identitas utama UI.

Gunakan untuk:

- active item
- focused item
- tombol utama
- selected tab
- link/aksen utama
- accent border

Contoh:

```toml
active_border_color = "{{ colors.primary.default.hex }}"
```

Cara berpikir:

```text
primary = "warna utama yang ingin paling terlihat"
```

`primary` **tidak berarti biru**. Pada satu wallpaper bisa ungu, hijau, oranye, dll.

---

### `on_primary`

**Peran:** foreground/text/icon yang diletakkan **di atas `primary`**.

Pasangan:

```text
primary
on_primary
```

Contoh:

```css
background: primary;
color: on_primary;
```

Mental model:

```text
[ primary background ]
[   on_primary text  ]
```

---

## 4. `secondary`

**Peran:** aksen pendamping primary.

Gunakan untuk:

- secondary button
- filter/badge
- metadata yang tetap ingin berwarna
- aksen kedua
- elemen aktif yang tidak sepenting primary

Pasangan utama:

```text
secondary
on_secondary
```

---

## 5. `tertiary`

**Peran:** aksen ketiga yang memberi variasi dari primary dan secondary.

Gunakan untuk:

- kategori ketiga
- dekorasi
- status/komponen tambahan
- elemen yang perlu berbeda dari primary/secondary

Pasangan:

```text
tertiary
on_tertiary
```

**Jangan** mengartikan `tertiary` sebagai "warna pink" atau warna tertentu. Warnanya bergantung pada source color dan color-scheme yang dipakai.

---

## 6. `error`

**Peran:** kondisi error/danger.

Gunakan untuk:

- error message
- invalid input
- destructive action
- failure state
- diagnostic error
- ANSI red

Pasangan:

```text
error
on_error
```

Untuk terminal, mapping yang masuk akal adalah:

```toml
red = "{{ colors.error.default.hex }}"
```

---

## 7. `*_container`

Contoh:

```text
primary_container
secondary_container
tertiary_container
error_container
```

`container` biasanya dipakai sebagai **surface/background sebuah komponen**, bukan sebagai aksen paling kuat.

Contoh:

```text
primary
    → aksen kuat / button / active state

primary_container
    → background selected item / panel / highlighted surface
```

Contoh mapping:

```text
selected item background
    → primary_container

selected item text
    → on_primary_container
```

---

## 8. `on_*_container`

Ini adalah foreground yang diletakkan di atas corresponding container.

Pasangan penting:

```text
primary_container
on_primary_container

secondary_container
on_secondary_container

tertiary_container
on_tertiary_container

error_container
on_error_container
```

Mental model:

```text
container = background/surface
on_container = text/icon di atasnya
```

---

## 9. `surface` — Keluarga Background UI

Ini salah satu kelompok **paling penting** untuk desktop/editor/terminal.

### `surface`

Peran:

> background/surface utama.

Contoh Alacritty:

```toml
[colors.primary]
background = "{{ colors.surface.default.hex }}"
```

---

### `on_surface`

Foreground/text utama yang berada di atas `surface`.

Contoh:

```toml
foreground = "{{ colors.on_surface.default.hex }}"
```

Pasangan:

```text
surface
on_surface
```

Ini adalah pasangan yang sangat aman untuk:

```text
background + foreground
```

---

## 10. `surface_container_*`

Matugen menyediakan beberapa tingkat surface untuk membangun **hierarchy / kedalaman UI** tanpa harus membuat warna background manual sendiri.

Urutan mental sederhana:

```text
surface_container_lowest
        ↓
surface_container_low
        ↓
surface_container
        ↓
surface_container_high
        ↓
surface_container_highest
```

Semakin tinggi levelnya, biasanya dipakai untuk surface yang ingin lebih menonjol dari surface dasar.

Contoh penggunaan:

```text
main background
    → surface

subtle panel
    → surface_container_low

panel/dialog
    → surface_container

stronger popup
    → surface_container_high
```

Jangan menganggap urutan tersebut sebagai aturan wajib untuk setiap aplikasi. Ini adalah **starting point**.

---

## 11. `surface_variant`

**Peran:** surface yang memiliki karakter/kontras tambahan dibanding surface utama.

Bisa digunakan untuk:

- panel sekunder
- area UI yang perlu dibedakan dari background
- border-like surface
- scrollbar/secondary region

Matugen template resmi untuk terminal/tmux juga menggunakan berbagai `surface_*` dan `surface_variant` untuk membangun hierarchy UI. 

---

## 12. `outline` dan `outline_variant`

### `outline`

Peran utama:

```text
border
separator
divider
stroke
```

Contoh:

```text
panel border → outline
```

### `outline_variant`

Versi yang lebih subtle/secondary.

Cocok untuk:

- border tidak aktif
- divider yang tidak ingin terlalu mencolok
- garis UI sekunder

Contoh:

```text
active border
    → outline

inactive border
    → outline_variant
```

---

## 13. `inverse_*`

Kelompok ini digunakan ketika sebuah komponen membutuhkan **kombinasi permukaan dan teks dengan hubungan kontras terbalik**.

Contoh:

```text
inverse_surface
inverse_on_surface
inverse_primary
```

Mental model sederhana:

```text
Normal UI:
    surface + on_surface

Inverse UI:
    inverse_surface + inverse_on_surface
```

Tidak perlu memakai kelompok ini hanya karena tersedia. Gunakan ketika komponen/target memang membutuhkan inverse treatment.

---

## 14. `*_fixed`

Contoh:

```text
primary_fixed
primary_fixed_dim
on_primary_fixed
on_primary_fixed_variant
```

Ciri penting:

> Beberapa `fixed` roles sengaja mempertahankan warna yang sama antar light/dark scheme.

Contoh dari output Matugen:

```text
primary
    LIGHT ≠ DARK

primary_fixed
    LIGHT = DARK
```

Cocok ketika sebuah komponen ingin mempertahankan identitas aksen yang konsisten ketika mode berubah.

---

## 15. `shadow` dan `scrim`

### `shadow`

Untuk konsep bayangan.

Biasanya tidak terlalu penting untuk terminal.

### `scrim`

Untuk lapisan yang menutupi UI, misalnya overlay/modal backdrop.

Jangan memaksakan kedua role ini ke aplikasi yang tidak memiliki konsep tersebut.

---

## 16. `background` dan `on_background`

Ada juga:

```text
background
on_background
```

Secara semantik:

```text
background
    = background keseluruhan

on_background
    = text/foreground di atasnya
```

Tetapi untuk banyak UI modern, `surface` + `on_surface` lebih nyaman digunakan ketika membangun hierarchy beberapa layer.

Untuk terminal, keduanya bisa sama atau hampir sama secara visual, tetapi jangan menganggapnya selalu identik.

---

## 17. `source_color`

Ini bukan warna UI yang perlu dipetakan ke tombol/panel.

```text
source_color = warna sumber yang menjadi input generator
```

Contoh dari wallpaper kamu:

```text
#51455E
```

Kemudian Matugen menghasilkan seluruh semantic palette dari source tersebut.

Mental model:

```text
wallpaper
   ↓
selected/source color
   ↓
source_color
   ↓
Matugen
   ↓
primary / secondary / surface / ...
```

---

## 18. Base16 `base00`–`base0F`

Ini perlu dipisahkan dari semantic Material colors.

```text
base00
base01
base02
...
base0F
```

adalah **Base16-oriented palette**.

Mental modelnya lebih dekat dengan:

```text
editor syntax
terminal ANSI
classic colorscheme format
```

daripada:

```text
UI surface / primary / container
```

Untuk Base16, mapping umum yang sering ditemui adalah:

```text
base00 → background
base05 → foreground
base08 → red-ish
base09 → orange-ish
base0A → yellow-ish
base0B → green-ish
base0C → cyan-ish
base0D → blue-ish
base0E → purple-ish
base0F → special
```

**Jangan mencampur Base16 dengan semantic Material roles.** Pilih sistem yang paling cocok untuk target.

---

## 19. Practical Mapping untuk Terminal / Alacritty

Sebagai titik awal, kamu bisa memakai mapping berikut.

| Alacritty | Matugen role | Alasan |
|---|---|---|
| background | `surface` | background utama |
| foreground | `on_surface` | text utama |
| cursor | `primary` | accent/focus |
| cursor text | `on_primary` | foreground di atas cursor |
| selection background | `secondary_container` | highlighted surface |
| selection text | `on_secondary_container` | contrast pair |
| red | `error` | semantic error |
| bright red | `error_container` | stronger error surface |
| green | `tertiary` | accent alternatif |
| bright green | `tertiary_container` | tertiary surface |
| yellow | `secondary` | secondary accent |
| bright yellow | `secondary_container` | secondary surface |
| blue | `primary` | primary accent |
| bright blue | `primary_container` | primary surface |
| cyan | `secondary_fixed_dim` | fixed secondary accent |
| magenta | `tertiary_fixed_dim` | fixed tertiary accent |
| white | `on_surface` | foreground |
| bright white | `on_surface_variant` atau `on_surface` | secondary/bright foreground |
| border | `outline` | border/divider |
| inactive border | `outline_variant` | subtle border |

Ini **bukan hukum Matugen**. Ini adalah mapping awal yang bisa kamu ubah berdasarkan tampilan target.

Repository template resmi Matugen untuk Kitty menggunakan prinsip yang sangat mirip: background → `surface`, foreground → `on_surface`, ANSI red → `error`, ANSI blue → `primary`, selection → `secondary_container`, active border → `primary`, inactive border → `outline`. citeturn757757search2

---

## 20. Practical Mapping untuk Editor / IDE

Untuk editor seperti Neovim, pikirkan berdasarkan fungsi UI:

| Fungsi UI/editor | Kandidat Matugen |
|---|---|
| editor background | `surface` |
| editor text | `on_surface` |
| active accent | `primary` |
| secondary accent | `secondary` |
| third accent | `tertiary` |
| error | `error` |
| warning-like accent | `secondary` / `tertiary` sesuai kebutuhan |
| panel background | `surface_container` |
| popup background | `surface_container_high` |
| selected item | `primary_container` |
| selected item text | `on_primary_container` |
| subtle border | `outline_variant` |
| strong border | `outline` |
| muted text | `on_surface_variant` |

Kemudian **editor-specific theme framework** tetap menentukan mapping detail seperti:

```text
Function
String
Comment
Keyword
Type
Variable
LSP diagnostic
Treesitter capture
```

Matugen sebaiknya memasok warna semantic; TokyoNight/Catppuccin/custom theme layer yang menentukan bagaimana semantic tersebut dipakai oleh Neovim.

---

## 21. Cara Memilih Warna: Decision Tree

Kalau kamu sedang melihat sebuah elemen UI dan bingung memilih warna, gunakan urutan ini.

### "Ini background utama?"

```text
→ surface
```

### "Ini text yang berada di background utama?"

```text
→ on_surface
```

### "Ini accent utama / active / focused?"

```text
→ primary
```

### "Ini text/icon di atas primary?"

```text
→ on_primary
```

### "Ini accent kedua?"

```text
→ secondary
```

### "Ini accent ketiga / variasi?"

```text
→ tertiary
```

### "Ini background sebuah selected/colored component?"

```text
→ *_container
```

### "Ini text/icon di atas container?"

```text
→ on_*_container
```

### "Ini error/destructive/failure?"

```text
→ error
```

### "Ini text/icon di atas error?"

```text
→ on_error
```

### "Ini panel/background bertingkat?"

```text
→ surface_container_*
```

### "Ini border/divider?"

```text
→ outline
```

### "Ini subtle/inactive border?"

```text
→ outline_variant
```

---

## 22. Jangan Memaksa Semantic Role

Contoh buruk:

```toml
# hanya karena warnanya terlihat cocok
blue = "{{ colors.error.default.hex }}"
```

Itu mungkin benar secara visual untuk satu wallpaper, tetapi semantiknya aneh.

Lebih baik:

```toml
blue = "{{ colors.primary.default.hex }}"
red  = "{{ colors.error.default.hex }}"
```

Karena:

```text
blue → primary accent
red  → error semantic
```

Dengan begitu ketika wallpaper berubah, hubungan semantic-nya tetap konsisten.

---

## 23. Kalau Warna Hasil Generator Tidak Cocok

Jangan langsung hardcode:

```toml
red = "#ff0000"
```

Cek dulu apakah masalahnya adalah **mapping**.

Contoh:

```text
error → terlalu pastel untuk ANSI red
```

Mungkin yang lebih cocok:

```text
error_container
```

atau role lain yang lebih sesuai dengan target.

Jadi bedakan:

```text
A. Semantic role tidak cocok
B. Mapping role → aplikasi tidak cocok
```

Sering kali masalah sebenarnya adalah **B**.

---

## 24. `default` vs `dark` vs `light`

Untuk template:

```text
{{ colors.primary.default.hex }}
```

`default` adalah scheme yang disediakan Matugen untuk context tersebut.

Kalau kamu ingin eksplisit:

```text
{{ colors.primary.dark.hex }}
{{ colors.primary.light.hex }}
```

Gunakan explicit scheme jika target selalu dark/light.

Misalnya Alacritty kamu selalu dark:

```toml
background = "{{ colors.surface.dark.hex }}"
foreground = "{{ colors.on_surface.dark.hex }}"
```

Ini membuat niat template lebih jelas.

---

## 25. Cara Melihat Data Matugen yang Sebenarnya

Jangan hanya mengandalkan tabel `--show-colors` saat menganalisis struktur data.

Gunakan JSON:

```bash
matugen image ~/Pictures/Wallpaper/Toothless.png --json hex
```

atau:

```bash
matugen color hex "#51455E" --json hex
```

Ini berguna untuk melihat struktur warna yang benar-benar diberikan ke template.

Untuk memeriksa field tertentu, kamu juga bisa menggunakan generator sederhana di template:

```text
<* for name, value in colors *>
{{ name }} = {{ value.default.hex }}
<* endfor *>
```

Matugen mendukung dot notation, looping, conditional, arithmetic, dan color filters di template. citeturn757757search0turn757757search4

---

## 26. Contoh Alacritty Minimal

Template awal yang cukup aman:

```toml
[colors.primary]
background = "{{ colors.surface.default.hex }}"
foreground = "{{ colors.on_surface.default.hex }}"

[colors.cursor]
text = "{{ colors.on_primary.default.hex }}"
cursor = "{{ colors.primary.default.hex }}"

[colors.selection]
text = "{{ colors.on_secondary_container.default.hex }}"
background = "{{ colors.secondary_container.default.hex }}"

[colors.normal]
black = "{{ colors.surface.default.hex }}"
red = "{{ colors.error.default.hex }}"
green = "{{ colors.tertiary.default.hex }}"
yellow = "{{ colors.secondary.default.hex }}"
blue = "{{ colors.primary.default.hex }}"
magenta = "{{ colors.tertiary_fixed_dim.default.hex }}"
cyan = "{{ colors.secondary_fixed_dim.default.hex }}"
white = "{{ colors.on_surface.default.hex }}"

[colors.bright]
black = "{{ colors.surface_variant.default.hex }}"
red = "{{ colors.error_container.default.hex }}"
green = "{{ colors.tertiary_container.default.hex }}"
yellow = "{{ colors.secondary_container.default.hex }}"
blue = "{{ colors.primary_container.default.hex }}"
magenta = "{{ colors.tertiary_fixed.default.hex }}"
cyan = "{{ colors.secondary_fixed.default.hex }}"
white = "{{ colors.on_surface_variant.default.hex }}"
```

Gunakan ini sebagai **starting point**, lalu koreksi mapping berdasarkan tampilan yang benar-benar kamu inginkan.

---

## 27. Prinsip Utama yang Perlu Diingat

```text
Matugen color
     ↓
semantic meaning
     ↓
application mapping
     ↓
actual color
```

Bukan:

```text
Matugen punya 50 warna
     ↓
Saya harus menggunakan semua 50
```

Dan bukan:

```text
primary = biru
error   = merah
tertiary = pink
```

Tetapi:

```text
primary = aksen utama
secondary = aksen pendamping
tertiary = aksen ketiga
error = error/danger
surface = surface/background
on_* = foreground di atas role tersebut
*_container = colored surface/container
outline = border/divider
```

---

## 28. Sumber

- Matugen Templates: https://github.com/InioX/matugen/wiki/Templates
- Matugen Configuration: https://github.com/InioX/matugen/wiki/Configuration
- Matugen Usage / JSON output: https://github.com/InioX/matugen/wiki/Usage
- Official Matugen themes — Kitty mapping: https://github.com/InioX/matugen-themes/blob/main/templates/kitty-colors.conf
- Official Matugen themes — tmux mapping: https://github.com/InioX/matugen-themes/blob/main/templates/tmux-colors.conf

---

## TL;DR

Kalau melihat sebuah config target, tanyakan:

```text
"Elemen ini secara SEMANTIK apa?"
```

bukan:

```text
"Warna hex mana yang kelihatan cocok?"
```

Lalu pilih:

```text
background      → surface
foreground      → on_surface
main accent     → primary
secondary       → secondary
third accent    → tertiary
error           → error
selected panel  → primary_container
text on panel   → on_primary_container
border          → outline
subtle border   → outline_variant
```

Setelah itu baru lakukan tuning visual khusus untuk aplikasi target.
