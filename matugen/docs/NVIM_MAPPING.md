# Pemetaan Warna Nvim

Dokumen ini menjawab satu pertanyaan: **kunci di `matugen/templates/general/nvim.lua`
itu dipakai untuk mewarnai bagian apa saja di nvim?**

Ditulis agar bisa dibaca orang yang tidak tahu nvim. Tidak ada perubahan kode di
dokumen ini — murni penjelasan.

---

## 1. Alur warnanya (3 lapis)

```
wallpaper  ──►  matugen  ──►  template nvim.lua  ──►  theme.lua (nvim)
 (gambar)       (role MD3)     (pilih role)          (terjemah ke UI)
```

1. **matugen** mengambil warna dari wallpaper dan menghasilkan satu set *role*
   (Material Design 3): `primary`, `tertiary`, `surface`, `on_surface`, dst.
   Daftar lengkapnya ada di `VOCABULARY.md`.
2. **`matugen/templates/general/nvim.lua`** memilih role itu menjadi nama-nama
   kunci (`background`, `extra.syntax.keyword`, ...). Hasil render-nya ditulis ke
   `~/.myenv/theme/current/nvim/theme.lua`. File template **hanya menyimpan
   nilai warna** — belum tahu warna itu akan dipakai untuk apa.
3. **`nvim/lua/core/theme.lua`** membacanya, lalu memetakan tiap kunci ke
   **highlight group** — nama-nama "cat" yang dipakai nvim untuk mewarnai bagian
   tertentu di layar (teks, latar, seleksi, sidebar, dsb).

> Jadi kalau ingin **mengubah nuansa warna**, edit template matugen.
> Kalau ingin **memindahkan warna dari satu bagian ke bagian lain**, edit
> `nvim/lua/core/theme.lua`.

### Glosarium singkat

| Istilah | Arti buat orang awam |
|---|---|
| nvim (Neovim) | Editor teks di terminal |
| TokyoNight | Tema dasar nvim yang dipakai proyek ini; matugen hanya menimpanya |
| highlight group | Nama "cat" untuk satu bagian UI, mis. `Normal` = teks+latar utama |
| treesitter | Mesin yang mengenali jenis kata dalam kode (kata kunci, angka, string) |
| role MD3 | Warna hasil matugen, mis. `primary`, `tertiary` |
| ANSI 0–15 | 16 warna standar terminal |

### Catatan tentang tema transparan

Proyek ini memakai `transparent = true`. Jadi banyak latar di-set `bg = "none"`
(latar editor, float, sidebar, nomor baris) supaya wallpaper tembus. Warna
`background` tetap dipakai untuk hal lain (campuran warna, bayangan, background
markview), bukan sebagai kotak latar.

> **Jebakan:** `nvim_set_hl` **mengganti** seluruh definisi group. Menulis
> `{ bg = "none" }` saja akan ikut menghapus `fg`/`bold` bawaan TokyoNight
> (nomor baris jadi tak redup, nomor baris aktif kehilangan sorotan). Karena itu
> group yang latarnya sudah tembus dari `transparent = true` dibiarkan apa
> adanya, dan yang perlu dikosongkan manual harus menyertakan `fg`-nya.

---

## 2. Kunci kerangka (level atas)

| Kunci | Isi (role) | Dipakai jadi | Muncul di |
|---|---|---|---|
| `source` | `source_color` | — | Tidak dipakai nvim; cuma jejak warna asal wallpaper |
| `background` | `background` | `M.colors.bg` + cadangan `container_roles` + teks di atas highlight pencarian | Latar (transparan), bayangan float, `g:markview_dark_bg` |
| `foreground` | `on_surface` | `M.colors.fg`, `fg_float` | **Teks utama** di seluruh editor & popup |
| `cursor` | `primary` | `M.colors.cursor` | Belum ada konsumen (kursor asli masih pakai `fg` bawaan TokyoNight) |

---

## 3. `colors[0..15]` — palet ANSI

16 warna ini **hanya** dipakai untuk mini-terminal di dalam nvim (`:terminal`),
lewat kunci TokyoNight `terminal.*`. Terminal aplikasi (kitty, foot, alacritty)
punya file sendiri dan tidak membaca bagian ini.

Dua slot punya tugas dobel karena `theme.lua` mengambil `ansi(6)` sebagai `cyan`
dan `ansi(14)` sebagai `teal` — dua kunci itu tersebar jauh ke UI.

| # | Nama | Nilai | Jadi | Tampil di |
|---|---|---|---|---|
| 0 | black | `surface_container_lowest` | `terminal.black` | Teks terminal |
| 1 | red | `error` | `terminal.red` | Teks terminal |
| 2 | green | `tertiary` | `terminal.green` | Teks terminal |
| 3 | yellow | `secondary` | `terminal.yellow` | Teks terminal |
| 4 | blue | `primary` | `terminal.blue` | Teks terminal |
| 5 | magenta | `tertiary −10` | `terminal.magenta` | Teks terminal |
| 6 | cyan | `secondary −10` | `terminal.cyan` + kunci `cyan` | Judul/ikon/deskripsi layar sambutan (alpha & dashboard), panel `which-key` (daftar shortcut), `RainbowDelimiterCyan`, sorot `TargetWord` |
| 7 | white | `on_surface` | `terminal.white` | Teks terminal |
| 8 | bright black | `outline` | `terminal.black_bright` | Teks terminal |
| 9 | bright red | `error_container` blend `primary` 0.6 `+40` | `terminal.red_bright` | Teks terminal |
| 10 | bright green | `tertiary_container` | `terminal.green_bright` | Teks terminal |
| 11 | bright yellow | `secondary_container` | `terminal.yellow_bright` | Teks terminal |
| 12 | bright blue | `primary_container` | `terminal.blue_bright` | Teks terminal |
| 13 | bright magenta | `tertiary_fixed` | `terminal.magenta_bright` | Teks terminal |
| 14 | bright cyan | `secondary −8` | `terminal.cyan_bright` + kunci `teal` | Badge mode "Other" di statusline (`MiniStatuslineModeOther`), tautan `@markup.link`, ikon sumber AI di menu completion, badge mode "X" di cheatsheet (via `teal`) & badan kursor animasi (via `smooth_body3`) |
| 15 | bright white | `on_surface +10` | `terminal.white_bright` | Teks terminal |

`−n` / `+n` = filter matugen `lighten:` (negatif = lebih pekat, positif = lebih terang).

---

## 4. `extra.accent` — warna aksen mentah

| Kunci | Isi | Di theme.lua jadi | Muncul di |
|---|---|---|---|
| `primary` | `primary` | `git.change`, kunci `accent` | Tanda **file berubah** di gitsigns/tabline/sidebar (`NvimTreeGitDirty`) |
| `secondary` | `secondary` | `accent2` | Kepala kursor animasi (SmoothCursor) & badge mode "Terminal" |
| `tertiary` | `tertiary` | `hint` + latar highlight pencarian | Saran samar LSP (`DiagnosticHint`), **latar** `CurSearch`/`IncSearch` |
| `on_accent` | `on_primary` | — | Belum dipakai |
| `on_tertiary` | `on_tertiary` | teks di atas `CurSearch`/`IncSearch` | Huruf saat mode pencarian bertahap |

---

## 5. `extra.container` — latar seleksi & pencarian

Role "container" MD3 = versi lebih kalem dari aksen, dipakai sebagai latar blok.

| Kunci | Isi | Jadi background untuk | Muncul di |
|---|---|---|---|
| `primary` | `primary_container` | `Visual`, `PmenuSel`, `QuickFixLine`, `WildMenu` | **Blok teks yang diseleksi**, baris terpilih di menu completion, item quickfix, `MatchParen` (base) |
| `on_primary` | `on_primary_container` | Teks di atas blok itu | Huruf di dalam seleksi / baris completion terpilih |
| `secondary` | `secondary_container` | `Search` | **Kata yang sedang dicari** (`hlsearch`) |
| `on_secondary` | `on_secondary_container` | Teks di atasnya | Huruf kata hasil pencarian |
| `tertiary` | `tertiary_container` | `MatchParen` | Latar **kurung pasangan** di bawah kursor |
| `on_tertiary` | `on_tertiary_container` | Teks di atasnya | Huruf kurung pasangan |

---

## 6. `extra.text`, `extra.layer`, `extra.border`

### `extra.text`

| Kunci | Isi | Jadi | Muncul di |
|---|---|---|---|
| `primary` | `on_surface` | — | Duplikat `foreground`; tidak dipakai langsung |
| `secondary` | `on_surface_variant` | — | Belum dipakai |
| `muted` | `outline` | `fg_dark`, `fg_sidebar` | **Teks sidebar** (file tree nvim-tree), nama file non-ikon, teks `StatusLine`, `SignColumnSB` |
| `link` | `primary` | — | Belum dipakai |
| `visited` | `secondary` | — | Belum dipakai |

### `extra.layer` — tangga kedalaman latar

| Kunci | Isi | Jadi | Muncul di |
|---|---|---|---|
| `base` | `background` | `bg` | Lihat bagian 2 |
| `mantle` | `surface_container_lowest` | `bg_dark`, `bg_popup`, `bg_float`, `bg_sidebar` | Latar **float/popup** (`Pmenu`, docs completion, jendela mengambang), latar sidebar file tree, latar trouble list (transparan juga) |
| `crust` | `surface_container_low` | `bg_dark1`, `black` | `ColorColumn`, latar `TabLineFill`, bayangan float, **huruf di atas badge berwarna** (mode Replace/Command, TODO, diff) |
| `surface` | `surface` | — | Belum dipakai |
| `surface_raised` | `surface_container_high` | `bg_highlight` | **Baris kursor** (`CursorLine`/`CursorColumn`), baris hasil pencarian di picker, file yang dibuka di sidebar, blok git di Neogit, fallback background smear-cursor |
| `surface_overlay` | `surface_container_highest` | — | Belum dipakai |

### `extra.border`

| Kunci | Isi | Jadi | Muncul di |
|---|---|---|---|
| `default` | `outline_variant` | — | Belum dipakai |
| `active` | `primary` | `border_highlight` | **Tepi jendela mengambang**, judul float, border Telescope/cmp/LSP info/mini.files |
| `medium` | `outline` | `border` | **Garis pemisah antar jendela** (`WinSeparator`), border `CmpBorder`/`FloatBorder`/`SnacksInputBorder`/notifier |

---

## 7. `extra.status` & `extra.fg` — status & teks redup

Perhatikan: `success`, `warning`, `critical` masih **hardcode hex** di template
(warisan template general lain), hanya `error` & `info` yang ambil role matugen.

| Kunci | Isi | Jadi | Muncul di |
|---|---|---|---|
| `success` | `#86A361` | `green2`, `git.add` | Tanda **tambah**: gitsigns Added, `Added`, `NvimTreeGitNew`, `SidekickSignAdd`, `MiniDepsTitleUpdate`, `DiagnosticOk`, `RedrawDebugComposed` |
| `warning` | `#C6A664` | `warning` | **File berubah** di tabline/buffer, diagnostic warning + scrollbar-nya, `@comment.warning`, mini.hipatterns HACK |
| `error` | `error` | `red1`, `git.delete` | Tanda **hapus** (gitsigns Deleted, `Removed`), diagnostic error (`DiagnosticError` bawaan TokyoNight) |
| `critical` | `#D16D6D` | `red` | "Merah kuat": badge mode Replace di statusline, `Substitute`, `@module.builtin`, `@tag.tsx`/`@tag.javascript`, ikon devicons merah (`MiniIconsRed`), `RainbowDelimiterRed`, badge mode "Open" di cheatsheet, tanda `MiniTestFail` |
| `info` | `primary` | `blue2` | Tanda **header file berubah** (`Changed`), `HopNextKey1`, scrollbar info, prompt picker, sinyal buffer "info" |

| Kunci | Isi | Jadi | Muncul di |
|---|---|---|---|
| `dim` | `outline_variant` | `dark3` | Latar mode lompat (Leap/Flash), `NeoTreeTabInactive`, `NonText`/`SpecialKey`, placeholder `Conceal`, `TelescopeResultsComment`, `DiagnosticDeprecated` (teks dicoret) |
| `dim_muted` | `outline` | `dark5` | Nilai di panel `which-key`, tab non-aktif (`MiniTablineHidden`), ekor animasi kursor (`smooth_tail`) |
| `disabled` | `outline` | — | Belum dipakai |

### `extra.bg`

`conflict` dan `disk_usage` **tidak dipakai nvim** — keduanya disediakan untuk
template lain (mis. Waybar) yang kebetulan berbagi bentuk kunci yang sama.

---

## 8. `extra.syntax` — inti pewarnaan kode

Ini bagian paling kompleks, dan ada **dua jalur pemakaian**:

1. **`apply_syntax_highlights()`** — langsung mewarnai highlight group
   nvim & treesitter (`@keyword`, `@string`, `String`, ...). Ini yang paling
   terasa saat membaca kode.
2. **`build_colors()`** — beberapa token juga dijadikan kunci TokyoNight
   (`blue`, `green`, `purple`, ...) yang dipakai TokyoNight sendiri untuk
   plugin, layar sambutan, sidebar, dan statusline.

### 8a. Jalur utama — group syntax

| Kunci | Nilai | Diwarnai jadi (highlight group) | Artinya |
|---|---|---|---|
| `comment` | `outline` blend `tertiary` 0.5 | `Comment`, `@comment*`, `CmpItemMenu`, `FoldColumn`, `WhichKeySeparator`, `LspCodeLens`, `diffLine`, `helpExample` | **Komentar kode**, catatan lipatan, label menu completion |
| `punctuation` | `outline` | `Delimiter`, `@punctuation.delimiter/bracket/special`, `@tag.delimiter` | Tanda baca & kurung: `( ) [ ] { } , ;` |
| `property` | `on_surface −1` | `@property`, `@variable.member` | **Nama field/atribut** objek (mis. `.name`) |
| `parameter` | `on_surface −5` | `@variable.parameter` | **Parameter fungsi** di deklarasinya |
| `keyword` | `primary` | `Keyword`, `@keyword`, `@keyword.function` | **Kata kunci**: `if`, `while`, `class`, `local`, ... |
| `statement` | `tertiary` | `Statement`, `Conditional`, `Repeat`, `Label` | Kalimat kendali: `if/else`, loop, label |
| `return` | `primary` | `@keyword.return` | Kata `return` |
| `import` | `primary −10` | `PreProc`, `Include`, `Define`, `Macro`, `@keyword.import` | **Import/require/macro**, directive praproses |
| `decorator` | `primary −6` | `@attribute`, `@attribute.builtin` | **Decorator/anotasi** (`@override`, `@lua`) |
| `function` | `primary −10` | `Function`, `@function`, `@function.call` | **Nama fungsi yang dipanggil** |
| `method` | `primary −9` | `@function.method`, `@function.method.call` | Nama method |
| `type` | `primary −5` | `Type`, `StorageClass`, `Structure`, `@type`, `@type.builtin` | **Nama tipe** (`string`, `int`, tipe buatan sendiri) |
| `class` | `primary −13` | `@constructor` | Nama **constructor/class** |
| `builtin` | `primary −15` | `@function.builtin` | Fungsi bawaan bahasa |
| `string` | `tertiary −14` | `String`, `Character`, `@string` | **Teks string** |
| `number` | `secondary −14` | `Number`, `Float`, `@number`, `@number.float` | **Angka** |
| `boolean` | `tertiary −8` | `Boolean`, `@boolean` | `true` / `false` |
| `constant` | `secondary −20` | `Constant`, `@constant`, `@constant.builtin` | **Konstanta** (`MAX_SIZE`, `nil`, ...) |
| `variable` | `on_surface` | `@variable` | Nama variabel biasa |
| `identifier` | `on_surface` | `Identifier` | Identifier umum |
| `operator` | `secondary −4` | `Operator`, `@operator`, `@keyword.operator` | **Operator**: `+`, `=`, `->`, `and`, ... |
| `regex` | `tertiary −26` | `@string.regexp` | Pola **regex** di dalam string |
| `builtin_variable` | `secondary −8` | `@variable.builtin` | Variabel bawaan (`self`, `this`, `vim`) |
| `special` | `tertiary` blend `secondary` 0.5 `−10` | `Special`, `@string.escape` | Karakter **escape** (`\n`, `\t`) & simbol khusus |
| `exception` | `error` | `Exception`, `@keyword.exception` | **Error handling**: `try`, `catch`, `throw` |
| `tag` | `error` | `@tag` | Tag markup (mis. HTML/JSX) — sengaja merah |
| `attribute` | `primary −17` | `@tag.attribute` | Atribut di dalam tag (`class=`, `id=`) |

Contoh menjawab pertanyaan "`special` itu dipakai di mana?": ia dipakai untuk
`@string.escape` (escape di dalam string) dan `Special`, **bukan** untuk folder
sidebar. Folder sidebar diwarnai oleh `syntax.function` (lihat tabel di bawah).

### 8b. Jalur tambahan — kunci TokyoNight & plugin

Saat `theme.lua` menyusun palet untuk TokyoNight, beberapa token syntax dipakai
ulang oleh TokyoNight untuk plugin dan elemen non-kode:

| Kunci syntax | Kunci TokyoNight | Contoh pemakaian lain |
|---|---|---|
| `comment` | `comment` + `footer` | `AlphaFooter` (teks bawah layar sambutan), border & judul notifier Debug, `MiniStarterInactive` |
| `string` | `green` | Badge mode Visual di cheatsheet, `MiniStatuslineModeInsert`, `Character`, `MiniTestPass` |
| `constant` | `yellow` | Badge `Todo`, ikon `DashboardProjectIcon`, `SnacksInputBorder`/`Title`, `RainbowDelimiterYellow` |
| `import` | `orange` | **Nomor baris kursor** (`CursorLineNr`), border & judul input picker Snacks, `NeoTreeGitModified`, `ScrollbarSearch`, `AlphaShortcut`, `DashboardKey`, `MiniSurround` |
| `keyword` | `purple` | Ikon Snacks/SmoothCursor, `TelescopeResultsTitle`, file khusus di sidebar (`NvimTreeSpecialFile`, digarisbawahi), `MiniIndentscopeSymbol`, `RainbowDelimiterViolet`, ikon devicons ungu |
| `statement` | `magenta` | `Statement`/`Conditional`/`Repeat`/`Label`, `AlphaHeader`, border & judul prompt Telescope, garis indentasi tidak aktif (`MiniIndentscopeSymbolOff`), warna kursor smear, `TroubleCount`, cabang git (`NeogitBranch`, `NeoTreeGitUntracked`), `WhichKeyDesc`, `MiniStatuslineModeVisual` |
| `function` | `blue` | **Ikon folder sidebar** (`NvimTreeFolderIcon`), **folder root** (tebal), symlink, `TabLineSel` (tab aktif), `MiniStatuslineModeNormal`, ikon notifier, `DefinitionIcon`, `RainbowDelimiterBlue`, header dashboard |
| `type` | `blue1` | **Huruf yang cocok** di menu completion (`CmpItemAbbrMatch`), garis panduan indentasi aktif (`IblScope`), ikon `SnacksDashboardIcon`, border LSP float |
| `operator` | `blue5` | `@operator`/`Operator`, `@markup.list` |
| `regex` | `blue6` | `@string.regexp` |
| `special` | `magenta2` | Label lompatan Leap/Flash, baris terpilih di picker Snacks, `MiniJump`, `HopNextKey`, pointer fzf, `LazyProgressDone` |
| `property` | `green1` | `NeoTreeGitStaged`, `healthSuccess`, `@markup.list.checked`, sebagian ikon devicons (`GlyphPalette6`) |
| `punctuation` | — (langsung) | Grup tanda baca di 8a |
| `identifier`, `variable` | — (langsung) | Grup di 8a |

`blue0`/`blue7` (versi redup dari `function`) tidak muncul di tabel karena
dihitung otomatis oleh `blend()` di `theme.lua` untuk latar `diff` dan ghost text.

### 8c. Kunci turunan (dihitung `theme.lua`, bukan dari template)

`build_colors()` menurunkan beberapa kunci tambahan dari nilai di atas. Penting
diketahui supaya tidak bingung mencarinya di template:

| Kunci turunan | Dibuat dari | Muncul di |
|---|---|---|
| `git.add` / `git.change` / `git.delete` | `status.success` / `accent.primary` / `status.error` | Tanda git di sidebar, tabline, gitsigns, Neogit, Sidekick |
| `diff.add/changed/delete/text` | campuran `status.*` & `syntax.function` dengan `background` | **Latar blok diff** saat membandingkan file (`DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`) |
| `rainbow[1..8]` | `function`, `constant`, `string`, `teal`, `statement`, `keyword`, `import`, `critical` | **Kurung/label berwarna bertingkat** (rainbow brackets di treesitter & headlines.nvim) |
| `blue0`, `blue7` | `blend(syntax.function, background, …)` | Latar `diff` & ghost text saran AI |
| `terminal_black` | `blend(accent.primary, layer.crust, 0.12)` | **Latar chip kode inline (`` `...` ``)** di .md — grup `@markup.raw.markdown_inline` dan `MarkviewInlineCode` — plus ghost text AI (Copilot/Codeium/Blink) dan latar `:help` |
| teks kode inline | `on_highlights` menimpa `@markup.raw.markdown_inline` + `MarkviewInlineCode` dengan `fg = c.fg` | Huruf di dalam backtick memakai warna teks utama, bukan aksen, supaya kontrasnya ~10:1 di atas chip |
| `button` | `syntax.function` | Tombol di layar sambutan (`AlphaButtons`) |
| `footer` | `syntax.comment` | Teks kaki layar sambutan (`AlphaFooter`) |
| `smooth_body3` / `smooth_tail` | `teal` (ANSI 14) / `dim_muted` | Badan & ekor animasi kursor (SmoothCursor) |
| `accent` / `accent2` | `accent.primary` / `accent.secondary` | `accent` belum ada konsumen; `accent2` = kepala SmoothCursor & badge mode Terminal |

---

## 9. `extra.ui`

| Kunci | Isi | Jadi | Muncul di |
|---|---|---|---|
| `bg_statusline` | `surface_container` | `bg_statusline` | Latar **statusline bawah** & tab (lualine, bufferline, mini.tabline), `BufferOffset`, `BufferVisible*` |
| `gutter` | `surface_container_high` | `fg_gutter` | **Nomor baris** (`LineNr`, `LineNrAbove/Below`), teks `SignColumn`, `StatusLineNC`, tab non-aktif, garis indentasi sidebar, `IndentLine`, `CmpItemAbbrDeprecated` |

---

## 10. Kunci yang belum dipakai nvim

Bukan bug — sebagian kunci sengaja disamakan bentuknya dengan template tool lain
(Waybar, rasi, dll) supaya gampang dipelihara. Yang belum dikonsumsi
`nvim/lua/core/theme.lua`:

| Kunci | Keterangan |
|---|---|
| `source` | Jejak warna wallpaper |
| `cursor` | Kursor masih pakai `fg`/`bg` bawaan TokyoNight |
| `extra.accent.on_accent` | — |
| `extra.text.primary` | Duplikat `foreground` (nilainya tetap terpakai lewat `foreground`) |
| `extra.text.secondary`, `.link`, `.visited` | — |
| `extra.layer.surface`, `.surface_overlay` | — |
| `extra.border.default` | Tepi jendela non-aktif masih pakai `border.medium` |
| `extra.fg.disabled` | — |
| `extra.bg.conflict`, `.disk_usage` | Cadangan untuk template lain |

---

## 11. Ringkasan cepat: "mau ubah apa, sentuh yang mana?"

| Bagian UI | Kunci |
|---|---|
| Latar & float | `background`, `extra.layer.mantle` |
| Teks utama | `foreground` |
| Seleksi blok | `extra.container.primary` |
| Kata hasil pencarian | `extra.container.secondary` |
| Kurung pasangan | `extra.container.tertiary` |
| Komentar kode | `extra.syntax.comment` |
| Kata kunci | `extra.syntax.keyword` |
| String / angka | `extra.syntax.string`, `extra.syntax.number` |
| Nomor baris kursor | `extra.syntax.import` |
| Ikon folder sidebar | `extra.syntax.function` |
| Tanda git (add/change/delete) | `extra.status.success`, `extra.accent.primary`, `extra.status.error` |
| Statusline | `extra.ui.bg_statusline` |
| Judul float & border aktif | `extra.border.active` |
| Garis pemisah jendela | `extra.border.medium` |
| Kode inline markdown | `extra.border.medium` (latar) + `extra.syntax.string` (huruf) |

---

## 12. Catatan cakupan

- Dokumen ini fokus ke **`templates/general/nvim.lua`**. Template
  `templates/kanagawa-dragon-lotus/template/nvim.lua` punya **nama kunci yang
  sama persis** (hanya sumber nilainya beda + tanpa `source`), jadi tabel
  "dipakai di mana" di atas berlaku untuk keduanya.
- Ringkasnya: ubah **nilai warna** → `matugen/templates/general/nvim.lua`; ubah
  **tujuan pemakaian** → `nvim/lua/core/theme.lua`.
- Perubahan template berlaku setelah `matugen image <wallpaper>` (atau reload
  tema yang sedang jalan).
